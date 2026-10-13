/// LE RECALAGE SUR LE TRACE COTE INTERFACE (lot 671-03), monte sur la carte
/// pendant un trek, a cote de la calibration du pas : il publie le trace
/// reduit pour l'isolate de fond, et il tient les trois sorties de secours
/// vers le GPS continu. Invisible, sauf la phrase qui dit pourquoi le GPS
/// tourne fort.
///
/// N'OUVRE AUCUN FLUX : il lit la projection que la carte calcule deja, et
/// change de profil par le seul canal du lot 671-00.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/error/error_handler.dart';
import '../../../../core/geo/charnieres_du_trace.dart';
import '../../../../core/geo/trace_point.dart';
import '../../../../core/geo/track_projection.dart';
import '../../../../core/services/gps_cadence.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart'
    show charnieresDuSentierProvider, gpxTrackProvider, trackPositionProvider;
import '../../data/gps_service.dart';
import '../../data/repli_gps_continu.dart';
import '../../data/trace_de_fond.dart';
import '../../domain/accumulateur_de_pas.dart';
import '../../providers/gps_providers.dart';
import '../../providers/measure_bench_provider.dart';
import '../../providers/podometre_providers.dart';
import '../../providers/tracking_providers.dart';

/// Monte le recalage tant qu'un trek est en cours (enregistre ou en pause).
class TrackRecalibrationMount extends ConsumerWidget {
  /// Un montage sans parametre.
  const TrackRecalibrationMount({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final active =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    return active ? const _ActiveRecalibration() : const SizedBox.shrink();
  }
}

class _ActiveRecalibration extends ConsumerStatefulWidget {
  const _ActiveRecalibration();

  @override
  ConsumerState<_ActiveRecalibration> createState() =>
      _ActiveRecalibrationState();
}

class _ActiveRecalibrationState extends ConsumerState<_ActiveRecalibration> {
  final List<ProviderSubscription<Object?>> _subscriptions = [];
  ContinuousGpsFallback? _fallback;
  List<TrackPoint>? _publishedTrack;
  WalkDirection? _publishedDirection;

  @override
  void initState() {
    super.initState();
    unawaited(_start());
  }

  Future<void> _start() async {
    final chosen = await readChosenPositionProfile(
      ref.read(positionControllerProvider).profile,
    );
    if (!mounted) return;
    _fallback = ContinuousGpsFallback(
      apply: ref.read(positionProfileChannelProvider),
      chosen: chosen,
    );
    _subscriptions.addAll([
      ref.listenManual(
        trackPositionProvider,
        (_, _) => unawaited(_evaluate()),
        fireImmediately: true,
      ),
      ref.listenManual(podometerProvider, (_, _) => unawaited(_evaluate())),
      ref.listenManual(
        gpxTrackProvider(ref.read(trailIdProvider)),
        (_, _) => unawaited(_evaluate()),
      ),
      ref.listenManual<PositionProfile?>(chosenPositionProfileProvider, (
        _,
        profile,
      ) {
        if (profile != null) _fallback?.choose(profile);
      }),
    ]);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.close();
    }
    super.dispose();
  }

  /// Relit les trois conditions, publie le trace s'il a change, et dit
  /// pourquoi le GPS repasse en continu quand une sortie de secours tombe.
  Future<void> _evaluate() async {
    final fallback = _fallback;
    if (fallback == null || !mounted) return;
    final track = ref.read(gpxTrackProvider(ref.read(trailIdProvider)));
    final points = track.value;
    if (points != null && points.length >= 2) unawaited(_publish(points));
    final position = ref.read(trackPositionProvider).value;
    final readiness = ref.read(podometerProvider).value?.readiness;
    final reason = await fallback.observe(
      offTrack: position?.isOffTrack,
      trackLoaded: track.hasValue || track.hasError
          ? (points?.length ?? 0) >= 2
          : null,
      estimatePossible: readiness == null
          ? null
          : readiness == EstimateReadiness.possible,
    );
    if (reason != null && mounted) _say(reason);
  }

  Future<void> _publish(List<TrackPoint> points) async {
    final config = ref.read(trailConfigProvider);
    final forward = config.directions.isNotEmpty
        ? config.directions.first
        : 'NS';
    final selected = ref.read(selectedDirectionProvider) ?? forward;
    final direction = selected == forward
        ? WalkDirection.increasing
        : WalkDirection.decreasing;
    if (identical(points, _publishedTrack) &&
        direction == _publishedDirection) {
      return;
    }
    _publishedTrack = points;
    _publishedDirection = direction;
    await publishBackgroundTrace((
      trailId: config.id,
      points: points,
      direction: direction,
    ), charnieres: await _hinges(config.id));
  }

  /// Les charnieres du sentier (lot 671-04), calculees une fois avec le
  /// trace ; sans elles, pas de fenetre, et la cadence du profil reste seule.
  Future<List<Charniere>> _hinges(String trailId) async {
    try {
      return await ref.read(charnieresDuSentierProvider(trailId).future);
    } on Object catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'recalage.charnieres');
      return const [];
    }
  }

  /// UNE phrase de randonneur, la ou le lot 671-02 dit deja la sienne (la
  /// barre du bas de l'ecran) : celle du podometre quand c'est lui, sinon
  /// celle du trace. Elle remplace la phrase affichee au lieu de s'empiler.
  void _say(ContinuousGpsReason reason) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final tr = Translations.of(context).tracking.stepCounting;
    final sentence = reason == ContinuousGpsReason.noStepCounter
        ? tr.whyGps
        : tr.continuousGps;
    messenger
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(sentence)));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
