import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/features/map/presentation/trail_map_screen.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';

/// Tests widget de l'écran TrailMapScreen.
///
/// Vérifie l'affichage correct des états loading, error et data.
/// Note : les tests avec FlutterMap réel ne sont pas possibles
/// en environnement de test (timers réseau pour les tuiles).
/// On teste donc uniquement les états non-carte (loading, error, vide).
void main() {
  group('TrailMapScreen', () {
    testWidgets('affiche le loading pendant le chargement', (tester) async {
      // Completer qui ne se résout jamais → reste en loading
      final completer = Completer<List<TrackPoint>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: TrailMapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pump();

      // L'AppBar avec le nom du sentier doit être visible
      expect(find.text('Volcans Trail'), findsOneWidget);
      // Le CircularProgressIndicator du LoadingOverlay
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Nettoyer : résoudre le completer pour éviter les fuites
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche une erreur quand le chargement échoue',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future<List<TrackPoint>>.error(
                Exception('Fichier GPX introuvable'),
              ),
            ),
          ],
          child: const MaterialApp(
            home: TrailMapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le message d'erreur doit être visible
      expect(
        find.text('Impossible de charger le tracé'),
        findsOneWidget,
      );
    });

    testWidgets('affiche l\'état vide quand le GPX n\'a aucun point',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => Future.value(<TrackPoint>[]),
            ),
          ],
          child: const MaterialApp(
            home: TrailMapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun tracé disponible'), findsOneWidget);
    });

    testWidgets('l\'AppBar affiche le nom du sentier et le bouton retour',
        (tester) async {
      final completer = Completer<List<TrackPoint>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id).overrideWith(
              (ref) => completer.future,
            ),
          ],
          child: const MaterialApp(
            home: TrailMapScreen(trailId: 'test-trail'),
          ),
        ),
      );

      await tester.pump();

      // Vérifier le titre
      expect(find.text('Volcans Trail'), findsOneWidget);
      // Vérifier le bouton retour
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });
}
