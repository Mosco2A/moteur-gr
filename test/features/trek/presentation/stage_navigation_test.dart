import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/trail_data_provider.dart';
import 'package:moteur_gr/features/trek/presentation/stage_detail_screen.dart';
import 'package:moteur_gr/features/trek/presentation/stage_list_screen.dart';
import 'package:moteur_gr/features/trek/providers/trail_providers.dart';

/// Fake TrailDataProvider pour les tests de navigation.
class _FakeTrailDataProvider implements TrailDataProvider {
  @override
  Future<List<Stage>> getStages() async => [
        const Stage(
          id: '1',
          nameFr: 'Calenzana - Ortu',
          nameEn: 'Calenzana - Ortu',
          distance: 12.5,
          elevationGain: 1500,
          elevationLoss: 200,
          estimatedDurationMinutes: 420,
          difficulty: 'hard',
          orderIndex: 0,
          startLat: 42.50,
          startLng: 8.85,
          endLat: 42.46,
          endLng: 8.93,
        ),
      ];

  @override
  Future<List<TrackPoint>> getTrackPoints(String stageId) async => [];

  @override
  Future<TrailConfigData?> getTrailConfig() async => const TrailConfigData(
        id: 'test-trail',
        name: 'Test Trail',
        totalStages: 1,
        totalDistanceKm: 12.5,
        totalElevationGain: 1500,
      );
}

void main() {
  group('Navigation /stages -> /stages/:id', () {
    testWidgets('naviguer de /stages vers /stages/1 fonctionne',
        (tester) async {
      final fake = _FakeTrailDataProvider();

      // Routeur de test avec uniquement les routes stages
      final testRouter = GoRouter(
        initialLocation: '/stages',
        routes: [
          GoRoute(
            path: '/stages',
            name: 'trek-stages',
            builder: (context, state) => const StageListScreen(),
            routes: [
              GoRoute(
                path: ':id',
                name: 'trek-stage-detail',
                builder: (context, state) {
                  final stageId = state.pathParameters['id'] ?? '';
                  return TrekStageDetailScreen(stageId: stageId);
                },
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailDataProvider.overrideWithValue(fake),
            trailConfigProvider.overrideWithValue(testTrailConfig),
          ],
          child: MaterialApp.router(routerConfig: testRouter),
        ),
      );

      // Attendre le chargement des etapes
      await tester.pumpAndSettle();

      // Verifier que la liste des etapes s'affiche
      expect(find.text('Calenzana - Ortu'), findsOneWidget);

      // Taper sur l'etape pour naviguer vers /stages/1
      await tester.tap(find.text('Calenzana - Ortu'));
      await tester.pumpAndSettle();

      // Verifier qu'on est sur l'ecran de detail
      expect(find.text('Detail etape'), findsOneWidget);
      expect(find.text('Calenzana - Ortu'), findsOneWidget);
      expect(find.text('12.5 km'), findsOneWidget);
      expect(find.text('1500 m'), findsOneWidget);
    });
  });
}
