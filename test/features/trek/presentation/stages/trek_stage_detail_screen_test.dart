import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/presentation/stages/trek_stage_detail_screen.dart';

/// Tests widget de TrekStageDetailScreen (Phase 2 E2.4c + PARITE GR20).
///
/// Verifie que TrekStageDetailScreen affiche sans crash avec les donnees de
/// test (nom, description, stats, profil) ET les blocs de parite GR20 alimentes
/// par les donnees du sentier : points d'eau, hebergements, conseils, ainsi que
/// la duree d'etape (fix du mapping qui l'oubliait, plus de « -- »).
void main() {
  // Etape de test avec toutes les valeurs remplies. `estimatedDurationMinutes`
  // fourni -> la fiche doit afficher la duree formatee (parite GR20).
  const testStage = StageModel(
    trailId: 'test-trail',
    stageNumber: 3,
    name: 'Col de Vergio',
    distanceKm: 14.5,
    elevationGainM: 850,
    elevationLossM: 620,
    description: 'Traversee spectaculaire avec vue panoramique.',
    startLat: 42.28,
    startLng: 9.07,
    endLat: 42.30,
    endLng: 9.10,
    difficulty: 'hard',
    estimatedDurationMinutes: 350, // 5h50
  );

  // POI de l'etape 3 : 2 points d'eau + 1 hebergement (shelter). Un POI d'une
  // autre etape et un POI viewpoint ne doivent PAS apparaitre dans ces blocs.
  final testPois = [
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Source de la Spasimata',
      description: 'Pres de la passerelle',
      type: 'water',
      lat: 42.29,
      lng: 9.08,
      altitudeM: 1400,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Robinet Haut-Asco',
      description: 'Au refuge',
      type: 'water',
      lat: 42.295,
      lng: 9.085,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Refuge de Carrozzu',
      description: '30 places, demi-pension possible',
      type: 'shelter',
      lat: 42.30,
      lng: 9.09,
      altitudeM: 1270,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Belvedere du col',
      type: 'viewpoint',
      lat: 42.301,
      lng: 9.091,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 4,
      name: 'Fontaine autre etape',
      type: 'water',
      lat: 42.31,
      lng: 9.10,
    ),
  ];

  Widget buildSubject({
    List<StageModel> stages = const [testStage],
    List<PoiModel> pois = const [],
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        stagesProvider('test-trail').overrideWith(
          (ref) => Future.value(stages),
        ),
        poisProvider('test-trail').overrideWith(
          (ref) => Future.value(pois),
        ),
      ],
      child: const MaterialApp(
        home: TrekStageDetailScreen(
          trailId: 'test-trail',
          stageId: 3,
        ),
      ),
    );
  }

  group('TrekStageDetailScreen E2.4c', () {
    testWidgets('affiche sans crash avec donnees completes', (tester) async {
      await tester.pumpWidget(buildSubject(pois: testPois));
      await tester.pumpAndSettle();

      // Nom affiche DEUX fois par design : dans le titre de l'AppBar et dans le
      // titre de l'en-tete a degrade (AppGradientHeader, SW-SKIN-L5).
      expect(find.text('Col de Vergio'), findsNWidgets(2));

      // Description affichee
      expect(
        find.text('Traversee spectaculaire avec vue panoramique.'),
        findsOneWidget,
      );

      // Stats presentes — SW-SKIN-L5 : rangee d'AppDataStat (valeur + unite
      // separees, role data tabular). Distance 14.5 km, D+ +850 m, D- -620 m.
      expect(find.text('14.5'), findsOneWidget);
      expect(find.text('+850'), findsOneWidget);
      expect(find.text('-620'), findsOneWidget);
      // Unites "km"/"m" presentes (m apparait 2x : D+ et D-).
      expect(find.text('km'), findsOneWidget);
      expect(find.text('m'), findsNWidgets(2));

      // Badge difficulte — SW-SKIN-L5 : UNE seule occurrence (chip semantique).
      expect(find.text('Difficile'), findsOneWidget);

      // Profil altimetrique section
      expect(find.text('Profil altimetrique'), findsOneWidget);

      // Statistiques section
      expect(find.text('Statistiques'), findsOneWidget);

      // CustomPaint present (profil altimetrique)
      expect(find.byType(CustomPaint), findsWidgets);
    });
  });

  group('TrekStageDetailScreen parite GR20 — duree', () {
    testWidgets('affiche la duree d\'etape (fix mapping, plus de "--")',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      // 350 min -> 5h50 (formatage parite GR20). Le bug precedent laissait 0s
      // -> « -- ». On verifie la valeur ET l'absence du placeholder vide.
      expect(find.text('5h50'), findsOneWidget);
      expect(find.text('--'), findsNothing);
    });

    testWidgets('sans duree fournie, retombe sur estimation (jamais "--")',
        (tester) async {
      const noDurationStage = StageModel(
        trailId: 'test-trail',
        stageNumber: 3,
        name: 'Col de Vergio',
        distanceKm: 14.5,
        elevationGainM: 850,
        elevationLossM: 620,
        description: 'desc',
        startLat: 42.28,
        startLng: 9.07,
        endLat: 42.30,
        endLng: 9.10,
        difficulty: 'hard',
        // estimatedDurationMinutes non fourni -> estimation Naismith.
      );
      await tester.pumpWidget(buildSubject(stages: [noDurationStage]));
      await tester.pumpAndSettle();

      // Estimation Naismith : 14.5/4 + 850/400 h = 5.75 h = 5h45.
      expect(find.text('5h45'), findsOneWidget);
      expect(find.text('--'), findsNothing);
    });
  });

  group('TrekStageDetailScreen parite GR20 — points d\'eau', () {
    testWidgets('liste les points d\'eau de l\'etape (donnees sentier)',
        (tester) async {
      await tester.pumpWidget(buildSubject(pois: testPois));
      await tester.pumpAndSettle();

      expect(find.text('Points d\'eau'), findsOneWidget);
      // Les 2 points d'eau de l'etape 3 sont listes.
      expect(find.text('Source de la Spasimata'), findsOneWidget);
      expect(find.text('Robinet Haut-Asco'), findsOneWidget);
      // Compteur "2 source(s)".
      expect(find.textContaining('2 source'), findsOneWidget);
      // Le point d'eau d'une AUTRE etape n'apparait pas.
      expect(find.text('Fontaine autre etape'), findsNothing);
    });

    testWidgets('sans point d\'eau, affiche l\'avertissement', (tester) async {
      await tester.pumpWidget(buildSubject(pois: const []));
      await tester.pumpAndSettle();

      expect(find.text('Points d\'eau'), findsOneWidget);
      // Compteur "0 source(s)".
      expect(find.textContaining('0 source'), findsOneWidget);
      // Message d'avertissement (parite GR20 : prevoir de l'eau).
      expect(find.textContaining('Prevoyez au moins 3 L'), findsOneWidget);
    });
  });

  group('TrekStageDetailScreen parite GR20 — hebergements', () {
    testWidgets('liste les hebergements de l\'etape (donnees sentier)',
        (tester) async {
      await tester.pumpWidget(buildSubject(pois: testPois));
      await tester.pumpAndSettle();

      expect(find.text('Hebergements'), findsOneWidget);
      expect(find.text('Refuge de Carrozzu'), findsOneWidget);
      // Un viewpoint n'est PAS un hebergement.
      expect(find.text('Belvedere du col'), findsNothing);
    });

    testWidgets('sans hebergement, affiche le message neutre', (tester) async {
      // Uniquement des points d'eau, aucun hebergement.
      final waterOnly = testPois.where((p) => p.type == 'water').toList();
      await tester.pumpWidget(buildSubject(pois: waterOnly));
      await tester.pumpAndSettle();

      expect(find.text('Hebergements'), findsOneWidget);
      expect(
        find.text('Aucun hebergement reference sur cette etape.'),
        findsOneWidget,
      );
    });
  });

  group('TrekStageDetailScreen parite GR20 — conseils', () {
    testWidgets('affiche des conseils derives des stats', (tester) async {
      await tester.pumpWidget(buildSubject(pois: testPois));
      await tester.pumpAndSettle();

      expect(find.text('Conseils'), findsOneWidget);
      // Etape 'hard' -> conseil "etape technique".
      expect(find.textContaining('Etape technique'), findsOneWidget);
      // 2 points d'eau -> conseil "remplissez vos gourdes".
      expect(find.textContaining('Remplissez vos gourdes'), findsOneWidget);
    });

    testWidgets('conseil eau adapte quand peu de sources', (tester) async {
      await tester.pumpWidget(buildSubject(pois: const []));
      await tester.pumpAndSettle();

      // 0 point d'eau -> conseil "peu de points d'eau".
      expect(find.textContaining('Peu de points d\'eau'), findsOneWidget);
    });
  });
}
