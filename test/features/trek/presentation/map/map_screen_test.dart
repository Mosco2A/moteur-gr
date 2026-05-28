import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';

/// Tests widget de [MapScreen].
///
/// Verifie que le MapScreen orchestrateur affiche correctement
/// les 3 etats AsyncValue (loading, error, data vide) sans crash.
///
/// Note : les tests avec FlutterMap reel ne sont pas possibles
/// en environnement de test (timers reseau pour les tuiles).
/// On teste uniquement les etats non-carte.
void main() {
  group('MapScreen', () {
    testWidgets('affiche sans crash avec donnees mock en loading',
        (tester) async {
      // Completer qui ne se resout jamais — reste en loading
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
            home: MapScreen(),
          ),
        ),
      );

      await tester.pump();

      // L'AppBar avec le nom du sentier doit etre visible
      expect(find.text('Volcans Trail'), findsOneWidget);
      // Le CircularProgressIndicator du LoadingOverlay
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Le message de chargement
      expect(find.text('Chargement du trace...'), findsOneWidget);

      // Nettoyer : resoudre le completer pour eviter les fuites
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('affiche une erreur quand le chargement echoue',
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
            home: MapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Le message d'erreur doit etre visible
      expect(
        find.text('Impossible de charger le trace'),
        findsOneWidget,
      );
    });

    testWidgets('affiche l\'etat vide quand le GPX n\'a aucun point',
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
            home: MapScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun trace disponible'), findsOneWidget);
    });

    testWidgets('AppBar affiche le nom du sentier et le bouton retour',
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
            home: MapScreen(),
          ),
        ),
      );

      await tester.pump();

      // Verifier le titre
      expect(find.text('Volcans Trail'), findsOneWidget);
      // Verifier le bouton retour
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });
}
