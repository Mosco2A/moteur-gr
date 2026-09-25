import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/map/widgets/stage_poi_checklist.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// LOT D (tache 554) — LISTE DES POINTS DE L'ETAPE, COCHABLE AU PASSAGE.
///
/// Troisieme manque reel de la carte : la navigation de reference ouvre depuis
/// sa carte une feuille titree par l'etape qui compte ses refuges et ses points
/// d'eau. StepWays n'avait que son panneau de calques, qui affiche et masque des
/// couches — une autre fonction.
void main() {
  const trailId = 'test-trail';

  final stages = [
    const StageModel(
      trailId: trailId,
      stageNumber: 1,
      name: 'Etape une',
      distanceKm: 12,
      elevationGainM: 450,
      elevationLossM: 200,
      startLat: 45.7,
      startLng: 2.9,
      endLat: 45.8,
      endLng: 3.0,
    ),
  ];

  final pois = [
    // Etape 1 : une source, un refuge.
    const PoiModel(
      id: 11,
      trailId: trailId,
      stageNumber: 1,
      name: 'Source du col',
      type: 'water',
      lat: 45.71,
      lng: 2.91,
      altitudeM: 1480,
    ),
    const PoiModel(
      id: 12,
      trailId: trailId,
      stageNumber: 1,
      name: 'Refuge de la crete',
      type: 'refuge',
      lat: 45.72,
      lng: 2.92,
    ),
    // Etape 2 : ne doit PAS apparaitre dans la liste de l'etape 1.
    const PoiModel(
      id: 21,
      trailId: trailId,
      stageNumber: 2,
      name: 'Fontaine du bas',
      type: 'water',
      lat: 45.9,
      lng: 3.1,
    ),
  ];

  Widget harness({List<PoiModel>? withPois}) {
    return ProviderScope(
      overrides: [
        stagesProvider(trailId).overrideWith((ref) => Future.value(stages)),
        poisProvider(trailId)
            .overrideWith((ref) => Future.value(withPois ?? pois)),
        // Aucune projection GPS : la liste retombe sur la premiere etape du
        // programme — exactement le cas de l'utilisateur qui n'a pas demarre.
        trackPositionProvider.overrideWithValue(const AsyncLoading()),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StagePoiChecklist(trailId: trailId),
          ),
        ),
      ),
    );
  }

  testWidgets('liste les points de l ETAPE et pas ceux des autres',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text('Source du col'), findsOneWidget);
    expect(find.text('Refuge de la crete'), findsOneWidget);
    expect(find.text('Fontaine du bas'), findsNothing);

    // Les deux familles sont titrees avec les libelles deja traduits.
    expect(find.text(t.stage.waterSources.title), findsOneWidget);
    expect(find.text(t.stage.accommodation.title), findsOneWidget);
    // Et l etape est nommee.
    expect(find.text(t.a11y.stageMarker(number: 1)), findsOneWidget);
  });

  testWidgets('le compteur suit les points coches', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // Aucun point coche au depart : 0 / 2.
    expect(find.text(t.journal.dayCounter(index: 0, total: 2)), findsOneWidget);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text(t.journal.dayCounter(index: 1, total: 2)), findsOneWidget);

    // Et la coche se retire (on s est trompe de source).
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(find.text(t.journal.dayCounter(index: 0, total: 2)), findsOneWidget);
  });

  testWidgets('etape SANS point d eau : le message d avertissement deja '
      'traduit, jamais une liste vide muette', (tester) async {
    await tester.pumpWidget(harness(withPois: const <PoiModel>[]));
    await tester.pumpAndSettle();

    expect(find.text(t.stage.waterSources.none), findsOneWidget);
    expect(find.text(t.stage.accommodation.none), findsOneWidget);
    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('l altitude n est affichee que si elle est connue',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // La source porte 1480 m en base : type traduit + altitude.
    expect(find.text('${t.poi.water} · 1480 m'), findsOneWidget);
    // Le refuge n a pas d altitude : son sous-titre est le TYPE SEUL, et non
    // un « 0 m » qui se lirait comme une mesure au niveau de la mer.
    expect(find.text(t.poi.shelter), findsOneWidget);
  });
}
