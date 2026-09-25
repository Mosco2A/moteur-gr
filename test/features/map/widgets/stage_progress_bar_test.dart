import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  Widget buildBar({
    String stageName = 'Etape 1',
    double distanceRemainingKm = 5.3,
    double progressRatio = 0.45,
    bool isOffTrack = false,
    double? totalDistanceKm,
    double? distanceCoveredKm,
    int? elevationGainM,
    int? elevationLossM,
    double? avgSpeedKmh,
    double? altitudeM,
    bool showPendingValues = false,
    Widget? footer,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: distanceRemainingKm,
          progressRatio: progressRatio,
          isOffTrack: isOffTrack,
          totalDistanceKm: totalDistanceKm,
          distanceCoveredKm: distanceCoveredKm,
          elevationGainM: elevationGainM,
          elevationLossM: elevationLossM,
          avgSpeedKmh: avgSpeedKmh,
          altitudeM: altitudeM,
          showPendingValues: showPendingValues,
          footer: footer,
        ),
      ),
    );
  }

  group('StageProgressBar', () {
    testWidgets('affiche le nom de l etape', (tester) async {
      await tester.pumpWidget(buildBar(stageName: 'Etape 3'));
      expect(find.text('Etape 3'), findsOneWidget);
    });

    testWidgets('affiche la distance restante', (tester) async {
      await tester.pumpWidget(buildBar(distanceRemainingKm: 7.2));
      expect(find.text(t.map.stageRemaining(km: '7.2')), findsOneWidget);
    });

    testWidgets('affiche le pourcentage', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 0.65));
      expect(find.text('65%'), findsOneWidget);
    });

    testWidgets('affiche indicateur hors trace', (tester) async {
      await tester.pumpWidget(buildBar(isOffTrack: true));
      expect(find.text(t.map.offTrackChip), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('cache indicateur hors trace quand sur le trace',
        (tester) async {
      await tester.pumpWidget(buildBar(isOffTrack: false));
      expect(find.text(t.map.offTrackChip), findsNothing);
    });

    testWidgets('contient un LinearProgressIndicator', (tester) async {
      await tester.pumpWidget(buildBar());
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('le pourcentage a 0 pourcent affiche 0%', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 0.0));
      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('le pourcentage a 100 pourcent affiche 100%', (tester) async {
      await tester.pumpWidget(buildBar(progressRatio: 1.0));
      expect(find.text('100%'), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Correctif L6-2 : la seconde ligne de chiffres MESURES.
  // -------------------------------------------------------------------------
  group('StageProgressBar — ligne de chiffres mesures (L6-2)', () {
    testWidgets('AUCUNE seconde ligne quand rien n est mesure', (tester) async {
      await tester.pumpWidget(buildBar());
      // Ni separateur, ni libelles de la seconde ligne.
      expect(find.byType(Divider), findsNothing);
      expect(find.text(t.tracking.dPlus), findsNothing);
      expect(find.text(t.tracking.avgSpeed), findsNothing);
      expect(find.text(t.tracking.altitude), findsNothing);
    });

    testWidgets('affiche les SIX valeurs quand elles sont disponibles',
        (tester) async {
      await tester.pumpWidget(buildBar(
        totalDistanceKm: 180.4,
        distanceCoveredKm: 42.7,
        elevationGainM: 1240,
        elevationLossM: 980,
        avgSpeedKmh: 3.4,
        altitudeM: 1465.7,
      ));

      expect(find.text('180.4 km'), findsOneWidget);
      expect(find.text('42.7 km'), findsOneWidget);
      expect(find.text('1240 m'), findsOneWidget);
      expect(find.text('980 m'), findsOneWidget);
      expect(find.text('3.4 km/h'), findsOneWidget);
      // Altitude arrondie au metre : on ne feint pas le decimetre.
      expect(find.text('1466 m'), findsOneWidget);

      expect(find.text(t.tracking.total), findsOneWidget);
      expect(find.text(t.tracking.covered), findsOneWidget);
      expect(find.text(t.tracking.dPlus), findsOneWidget);
      expect(find.text(t.tracking.dMinus), findsOneWidget);
      expect(find.text(t.tracking.avgSpeed), findsOneWidget);
      expect(find.text(t.tracking.altitude), findsOneWidget);
    });

    testWidgets('une valeur absente est MASQUEE, jamais affichee a zero',
        (tester) async {
      // Cas reel du debut de trek : le denivele est connu, la vitesse ne l est
      // pas encore (duree trop courte) et l altitude n a pas de fix.
      await tester.pumpWidget(buildBar(
        elevationGainM: 120,
        elevationLossM: 0,
      ));

      expect(find.text('120 m'), findsOneWidget);
      expect(find.text(t.tracking.dMinus), findsOneWidget);
      expect(find.text(t.tracking.avgSpeed), findsNothing);
      expect(find.text(t.tracking.altitude), findsNothing);
      expect(find.text(t.tracking.total), findsNothing);
    });

    testWidgets('la seconde ligne ne capte AUCUN geste (IgnorePointer)',
        (tester) async {
      await tester.pumpWidget(buildBar(elevationGainM: 500));
      final barrages = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.text('500 m'),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(
        barrages.any((w) => w.ignoring),
        isTrue,
        reason: 'la ligne de chiffres est informative, elle ne prend aucun tap',
      );
    });
  });

  // -------------------------------------------------------------------------
  // LOT D (tache 554) — JAMAIS D'ECRAN NU : le mode « valeur en attente ».
  //
  // Retour de Chris : « 14 navigation ne ressemble en rien a GR20 !!!!! ». Sans
  // randonnee demarree, les six chiffres valaient `null` et s'effacaient tous
  // ensemble. La navigation de reference, elle, garde ses cases et met un tiret
  // dans celles qu'elle ne sait pas remplir.
  // -------------------------------------------------------------------------
  group('StageProgressBar — valeurs en attente (LOT D)', () {
    testWidgets('AUCUNE valeur connue : les SIX cases restent, avec un tiret',
        (tester) async {
      await tester.pumpWidget(buildBar(showPendingValues: true));

      // Les six libelles sont la...
      expect(find.text(t.tracking.total), findsOneWidget);
      expect(find.text(t.tracking.covered), findsOneWidget);
      expect(find.text(t.tracking.dPlus), findsOneWidget);
      expect(find.text(t.tracking.dMinus), findsOneWidget);
      expect(find.text(t.tracking.avgSpeed), findsOneWidget);
      expect(find.text(t.tracking.altitude), findsOneWidget);
      // ... et chaque valeur porte le tiret d'attente.
      expect(
        find.text(StageProgressBar.pendingValueLabel),
        findsNWidgets(6),
      );
    });

    testWidgets('un ZERO n est jamais affiche a la place du tiret',
        (tester) async {
      await tester.pumpWidget(buildBar(showPendingValues: true));

      expect(find.text('0.0 km'), findsNothing);
      expect(find.text('0 m'), findsNothing);
      expect(find.text('0.0 km/h'), findsNothing);
    });

    testWidgets('les chiffres du PROGRAMME sont reels, seuls les mesures '
        'attendent', (tester) async {
      // Cas de l'utilisateur neuf : l etape est connue (12 km, D+ 450, D- 200)
      // et la distance totale du sentier aussi ; parcouru et vitesse non.
      await tester.pumpWidget(buildBar(
        distanceRemainingKm: 12.0,
        progressRatio: 0,
        totalDistanceKm: 96.4,
        elevationGainM: 450,
        elevationLossM: 200,
        showPendingValues: true,
      ));

      expect(find.text('96.4 km'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('200 m'), findsOneWidget);
      expect(find.text(t.map.stageRemaining(km: '12.0')), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
      // Restent en attente : parcouru, vitesse moyenne, altitude.
      expect(
        find.text(StageProgressBar.pendingValueLabel),
        findsNWidgets(3),
      );
    });

    testWidgets('le mode par defaut est INCHANGE : une valeur absente reste '
        'masquee', (tester) async {
      await tester.pumpWidget(buildBar(elevationGainM: 120));

      expect(find.text('120 m'), findsOneWidget);
      expect(find.text(t.tracking.avgSpeed), findsNothing);
      expect(find.text(StageProgressBar.pendingValueLabel), findsNothing);
    });

    testWidgets('la ligne d explication s affiche quand elle est fournie',
        (tester) async {
      await tester.pumpWidget(buildBar(
        showPendingValues: true,
        footer: const Text('ce qui demarrera avec la rando'),
      ));

      expect(find.text('ce qui demarrera avec la rando'), findsOneWidget);
    });
  });
}
