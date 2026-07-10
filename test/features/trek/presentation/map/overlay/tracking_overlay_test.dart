import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/overlay/tracking_overlay.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';

/// Tests widget du composant TrackingOverlay (Phase 2 E2.8d).
///
/// Verifie que TrackingOverlay affiche les stats et 3 boutons
/// (start, pause, stop) selon l'etat de la session.
void main() {
  group('TrackingOverlay', () {
    testWidgets('affiche stats et 3 boutons en mode recording', (tester) async {
      // Override les providers pour simuler l'etat recording.
      // La distance affichee vient de la source PROJETEE
      // (stageDistanceCoveredProvider), PAS du cumul brut distanceKm :
      // on met un cumul GONFLE (9.9) different du projete (5.2) pour
      // prouver que l'overlay ignore le cumul (correctif build 117).
      final container = ProviderContainer(
        overrides: [
          stageDistanceCoveredProvider.overrideWithValue(5200.0),
          trekSessionManagerProvider.overrideWith(() {
            return _FakeNotifier(const TrackingSessionState(
              status: TrackingSessionStatus.recording,
              distanceKm: 9.9, // cumul brut gonfle -> NE doit PAS s'afficher
              elevationGainM: 350.0,
              elapsedDuration: Duration(hours: 2, minutes: 15),
              currentSpeedKmh: 4.3,
            ));
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TrackingOverlay(trailId: 'mare-a-mare'),
            ),
          ),
        ),
      );

      // 4 stats affichees
      expect(find.text('Distance'), findsOneWidget);
      expect(find.text('Temps'), findsOneWidget);
      expect(find.text('D+'), findsOneWidget);
      expect(find.text('Vitesse'), findsOneWidget);

      // Valeurs des stats : distance = PROJETEE (5.2), pas le cumul (9.9).
      expect(find.text('5.2 km'), findsOneWidget);
      expect(find.text('9.9 km'), findsNothing);
      expect(find.text('350 m'), findsOneWidget);
      expect(find.text('4.3 km/h'), findsOneWidget);

      // 2 boutons en mode recording: Pause + Stop
      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);

      // Icones des boutons
      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      container.dispose();
    });

    testWidgets('affiche bouton Demarrer en mode idle', (tester) async {
      final container = ProviderContainer(
        overrides: [
          trekSessionManagerProvider.overrideWith(() {
            return _FakeNotifier(const TrackingSessionState(
              status: TrackingSessionStatus.idle,
            ));
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TrackingOverlay(trailId: 'mare-a-mare'),
            ),
          ),
        ),
      );

      // Bouton Demarrer visible
      expect(find.text('Demarrer'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Pas de stats en mode idle
      expect(find.text('Distance'), findsNothing);

      container.dispose();
    });

    testWidgets('affiche Reprendre + Stop en mode paused', (tester) async {
      final container = ProviderContainer(
        overrides: [
          stageDistanceCoveredProvider.overrideWithValue(3100.0),
          trekSessionManagerProvider.overrideWith(() {
            return _FakeNotifier(const TrackingSessionState(
              status: TrackingSessionStatus.paused,
              distanceKm: 3.1,
              elevationGainM: 200.0,
              elapsedDuration: Duration(hours: 1, minutes: 30),
              currentSpeedKmh: 0.0,
            ));
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: TrackingOverlay(trailId: 'mare-a-mare'),
            ),
          ),
        ),
      );

      // Stats visibles en pause
      expect(find.text('Distance'), findsOneWidget);

      // Boutons Reprendre + Stop
      expect(find.text('Reprendre'), findsOneWidget);
      expect(find.text('Stop'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      container.dispose();
    });

    test('est un StatelessWidget', () {
      const widget = TrackingOverlay(trailId: 'test');
      expect(widget, isA<StatelessWidget>());
    });
  });
}

/// Fake notifier pour les tests.
class _FakeNotifier extends TrekSessionManagerNotifier {
  _FakeNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
