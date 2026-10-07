/// LA POSITION COURANTE (lot 671-03) : la position REELLE en profil carte, la
/// position ESTIMEE le long du trace entre deux releves en profils batterie.
/// C'est elle, et non plus le flux GPS brut, que lit la projection sur le
/// trace : tout ce qui en depend suit sans etre touche.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';
import '../../trek/trek_facade.dart'
    show BgTrackPoint, estimatedTrackPointsProvider, positionControllerProvider;
import 'location_provider.dart';

/// Ou le randonneur se trouve maintenant, releve ou estime.
class CurrentPosition {
  /// Une position ; [trackDistanceM] n'est porte que par un point estime.
  const CurrentPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.accuracy,
    this.trackDistanceM,
  });

  /// Un releve reel, tel que le robinet GPS le livre.
  factory CurrentPosition.measured(Position position) => CurrentPosition(
    latitude: position.latitude,
    longitude: position.longitude,
    altitude: position.altitude,
    accuracy: position.accuracy,
  );

  /// Un point estime par l'isolate de fond, sur le trace.
  factory CurrentPosition.estimated(BgTrackPoint point) => CurrentPosition(
    latitude: point.latitude,
    longitude: point.longitude,
    altitude: point.altitude,
    trackDistanceM: point.trackDistanceM,
  );

  /// Latitude en degres.
  final double latitude;

  /// Longitude en degres.
  final double longitude;

  /// Altitude en metres : celle du recepteur, ou celle du trace pour un
  /// point estime.
  final double altitude;

  /// Precision du recepteur en metres ; nulle pour un point estime, qui n'a
  /// pas de recepteur.
  final double? accuracy;

  /// Distance du point estime depuis le depart du trace ; nulle pour un
  /// releve, qui doit etre projete.
  final double? trackDistanceM;

  /// Vrai pour un point estime le long du trace.
  bool get isEstimated => trackDistanceM != null;
}

/// Le dernier point estime recu depuis le dernier releve, ou nul.
///
/// Un releve reel l'efface : AU RELEVE SUIVANT, LA POSITION COURANTE EST
/// REMISE A LA POSITION REELLE. Un estime n'est pris qu'en profil de tir
/// (batterie d'abord, batterie basse) : en profil carte, la position courante
/// reste le releve, au metre pres, comme avant le lot.
class _LatestEstimateNotifier extends Notifier<BgTrackPoint?> {
  /// L'heure du dernier releve : un estime calcule avant lui est perime.
  DateTime? _lastFixAt;

  @override
  BgTrackPoint? build() {
    ref.listen(locationProvider, (_, next) {
      final fix = next.value;
      if (fix == null) return;
      _lastFixAt = fix.timestamp;
      state = null;
    });
    final subscription = ref
        .watch(estimatedTrackPointsProvider)
        .listen(_onEstimate);
    ref.onDispose(subscription.cancel);
    return null;
  }

  void _onEstimate(BgTrackPoint point) {
    final profile = ref.read(positionControllerProvider).profile;
    if (!GpsCadence.of(profile).isSingleShot) return;
    if (point.trackDistanceM == null) return;
    final lastFix = _lastFixAt;
    if (lastFix != null && point.timestamp.isBefore(lastFix)) return;
    state = point;
  }
}

final _latestEstimateProvider =
    NotifierProvider<_LatestEstimateNotifier, BgTrackPoint?>(
      _LatestEstimateNotifier.new,
    );

/// LA POSITION COURANTE, LE POINT D'ENTREE UNIQUE de la projection sur le
/// trace ([trackPositionProvider]), du marqueur de la carte et de son bouton
/// « centrer sur moi ».
///
/// Sans estime, c'est le releve du robinet GPS ([locationProvider]), avec son
/// etat de chargement et ses erreurs, inchanges.
final currentPositionProvider = Provider<AsyncValue<CurrentPosition>>((ref) {
  final estimate = ref.watch(_latestEstimateProvider);
  if (estimate != null) {
    return AsyncData(CurrentPosition.estimated(estimate));
  }
  return ref.watch(locationProvider).whenData(CurrentPosition.measured);
});
