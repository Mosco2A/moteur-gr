import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/finish_trek_button.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/features/treks/domain/trek_lifecycle_state.dart';
import 'package:moteur_gr/features/treks/domain/trek_summary.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du bouton « Terminer le trek » (Finitions V1, point 3).
///
/// Il ne s'affiche QUE si un trek est en cours (session recording/paused OU état
/// dérivé inProgress), et propose une fin MANUELLE avec confirmation.
class _FakeTrekNotifier extends TrekSessionManagerNotifier {
  _FakeTrekNotifier(this._state);
  final TrackingSessionState _state;
  @override
  TrackingSessionState build() => _state;
}

void main() {
  Widget wrap({required List<Override> overrides}) {
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const Scaffold(
          body: SingleChildScrollView(child: FinishTrekButton()),
        )),
        GoRoute(
          path: '/trail/:id/recap',
          builder: (_, __) => const Text('RECAP_STUB'),
        ),
      ],
    );
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  Override trekWith(TrackingSessionState s) =>
      trekSessionManagerProvider.overrideWith(() => _FakeTrekNotifier(s));

  Override summaryWith(TrekLifecycleState? state) =>
      currentTrailSummaryProvider.overrideWith((ref) async =>
          state == null ? null : _summary(state));

  testWidgets('caché quand aucun trek en cours (idle + owned)', (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      trekWith(const TrackingSessionState(status: TrackingSessionStatus.idle)),
      summaryWith(TrekLifecycleState.owned),
    ]));
    await tester.pumpAndSettle();

    expect(find.text(t.hub.finishTrek.action), findsNothing);
  });

  testWidgets('visible quand le tracking est en cours (recording)',
      (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      trekWith(
        const TrackingSessionState(status: TrackingSessionStatus.recording),
      ),
      summaryWith(null),
    ]));
    await tester.pumpAndSettle();

    expect(find.text(t.hub.finishTrek.action), findsOneWidget);
  });

  testWidgets('visible quand l\'état dérivé est inProgress (session persistée)',
      (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      trekWith(const TrackingSessionState(status: TrackingSessionStatus.idle)),
      summaryWith(TrekLifecycleState.inProgress),
    ]));
    await tester.pumpAndSettle();

    expect(find.text(t.hub.finishTrek.action), findsOneWidget);
  });

  testWidgets('tap -> dialog de confirmation (annulable)', (tester) async {
    await tester.pumpWidget(wrap(overrides: [
      trekWith(
        const TrackingSessionState(status: TrackingSessionStatus.recording),
      ),
      summaryWith(null),
    ]));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.hub.finishTrek.action));
    await tester.pumpAndSettle();

    // Le dialog de confirmation apparaît (titre + bouton confirmer/annuler).
    expect(find.text(t.hub.finishTrek.confirmTitle), findsOneWidget);
    expect(find.text(t.hub.finishTrek.confirm), findsOneWidget);

    // Annuler ferme le dialog sans terminer (on reste sur le cockpit).
    await tester.tap(find.text(t.hub.finishTrek.cancel));
    await tester.pumpAndSettle();
    expect(find.text(t.hub.finishTrek.confirmTitle), findsNothing);
    expect(find.text('RECAP_STUB'), findsNothing);
  });
}

TrekSummary _summary(TrekLifecycleState state) => TrekSummary(
      config: _config,
      state: state,
    );

/// Config minimale (FinishTrekButton ne lit que l'id du sentier au clic).
const _config = TrailConfig(
  id: 'test-trail',
  name: 'test-trail',
  displayName: 'Test Trail',
  tagline: 't',
  totalStages: 5,
  totalDistanceKm: 50,
  totalElevationGain: 2000,
  region: 'Corse',
  country: 'France',
  primaryColorValue: 0xFF2E7D32,
  secondaryColorValue: 0xFF1565C0,
  gpxAssetPath: 'assets/gpx/test.gpx',
);
