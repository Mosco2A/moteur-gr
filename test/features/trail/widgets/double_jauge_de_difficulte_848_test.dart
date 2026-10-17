// GARDE — TACHE 848 : L'ECRAN MONTRE LA REPARTITION *ET* LE VERDICT, ET IL DIT
// QUE LE NOMBRE DE JOURS EST CONSEILLE.
//
// LES DEUX DEMANDES DE CHRISTOPHE QUE CES CAS TIENNENT, verbatim.
//   17/10 11:02 : « mais le nombre de jour, c'est du conseille, apres le client
//   le fait dans le nombre de jours qu'il veut ». Le mot « CONSEILLE » doit
//   etre A L'ECRAN, pas seulement dans un commentaire.
//   17/10 11:07-11:08 : « ou alors une jauge avec le nombre d'etape facile a
//   expert et une jauge moyenne (mais qui se base aussi sur la plus
//   difficile) ». DEUX jauges, pas un mot.
//
// ET LE TROISIEME CAS EST LE PLUS IMPORTANT : la difficulte doit SE RECALCULER
// quand le client change d'allure. C'est le meilleur argument de securite du
// produit — il voit la consequence de son propre choix AVANT de payer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/features/trail/widgets/difficulte_calculee.dart';

/// Une etape de decor, reduite a ce qui compte ici : son denivele positif.
StageModel etape(int numero, int denivelePositifM) => StageModel(
  trailId: 'decor',
  stageNumber: numero,
  name: 'Etape $numero',
  distanceKm: 10,
  elevationGainM: denivelePositifM,
  elevationLossM: 0,
  startLat: 0,
  startLng: 0,
  endLat: 0,
  endLng: 0,
);

/// Quatre journees, une par bande sauf expert : 300 facile, 500 moyen,
/// 800 difficile, 1 200 tres difficile.
final decor = <StageModel>[
  etape(1, 300),
  etape(2, 500),
  etape(3, 800),
  etape(4, 1200),
];

Widget sousTest({
  List<StageModel>? stages,
  List<int> allures = const <int>[2, 4],
  int allureParDefaut = 4,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: DifficulteCalculee(
        stages: stages ?? decor,
        allures: allures,
        allureParDefaut: allureParDefaut,
      ),
    ),
  ),
);

void main() {
  testWidgets('LE MOT CONSEILLE EST A L ECRAN, AVEC LE NOMBRE', (tester) async {
    await tester.pumpWidget(sousTest());
    expect(find.byKey(const ValueKey('jours-conseilles')), findsOneWidget);
    expect(find.text('Nombre de jours CONSEILLE : 4 jours'), findsOneWidget);
    // Et la phrase qui dit que c'est le client qui choisit.
    final phrase = tester.widget<Text>(
      find.byKey(const ValueKey('les-jours-sont-un-conseil')),
    );
    expect(phrase.data, contains('nombre de jours que vous voulez'));
    expect(phrase.data, contains('pas une caracteristique du sentier'));
    // L'allure conseillee est MARQUEE dans le choix, les autres non.
    expect(find.text('4 jours (conseille)'), findsOneWidget);
    expect(find.text('2 jours'), findsOneWidget);
  });

  testWidgets('LES DEUX JAUGES SONT LA, PAS UN MOT SEUL', (tester) async {
    await tester.pumpWidget(sousTest());
    expect(find.byKey(const ValueKey('jauge-du-verdict')), findsOneWidget);
    expect(find.byKey(const ValueKey('jauge-de-repartition')), findsOneWidget);
    expect(find.byKey(const ValueKey('comptes-par-niveau')), findsOneWidget);
  });

  testWidgets('LE VERDICT EST CELUI DE LA PIRE JOURNEE, ET IL EST NOMME', (
    tester,
  ) async {
    await tester.pumpWidget(sousTest());
    // Quatre journees : 300, 500, 800, 1 200. La pire est 1 200 -> tres
    // difficile. Une moyenne aurait donne 700, soit « difficile » : un cran de
    // moins, et c'est exactement ce que Christophe refuse.
    expect(find.text(NiveauDeDifficulte.tresDifficile.libelle), findsOneWidget);
    final pire = tester.widget<Text>(
      find.byKey(const ValueKey('pire-journee')),
    );
    expect(pire.data, contains('1200 m de montee'));
    expect(pire.data, contains('journee 4 sur 4'));
  });

  testWidgets('LA REPARTITION COMPTE LES CINQ BANDES, ZEROS COMPRIS', (
    tester,
  ) async {
    await tester.pumpWidget(sousTest());
    expect(find.text('Repartition des 4 journees de marche'), findsOneWidget);
    expect(find.text('1 facile'), findsOneWidget);
    expect(find.text('1 moyen'), findsOneWidget);
    expect(find.text('1 difficile'), findsOneWidget);
    expect(find.text('1 tres difficile'), findsOneWidget);
    // LE ZERO EST AFFICHE : on doit voir qu'il n'y a AUCUNE journee d'expert,
    // et non deviner son absence.
    expect(find.text('0 expert'), findsOneWidget);
  });

  testWidgets('CHANGER D ALLURE RECALCULE LE VERDICT', (tester) async {
    await tester.pumpWidget(sousTest());
    expect(find.text(NiveauDeDifficulte.tresDifficile.libelle), findsOneWidget);
    expect(find.text(NiveauDeDifficulte.expert.libelle), findsNothing);

    // Deux jours : les quatre etapes se regroupent 2 + 2, soit 800 m puis
    // 2 000 m de montee. La pire journee passe a 2 000 m -> EXPERT.
    await tester.tap(find.byKey(const ValueKey('allure-2')));
    await tester.pumpAndSettle();

    expect(find.text(NiveauDeDifficulte.expert.libelle), findsOneWidget);
    final pire = tester.widget<Text>(
      find.byKey(const ValueKey('pire-journee')),
    );
    expect(pire.data, contains('2000 m de montee'));
    expect(pire.data, contains('journee 2 sur 2'));
    expect(find.text('Repartition des 2 journees de marche'), findsOneWidget);
  });

  testWidgets('LA REGLE AFFICHEE EST SOUS LE RESULTAT', (tester) async {
    await tester.pumpWidget(sousTest());
    final regle = tester.widget<Text>(
      find.byKey(const ValueKey('regle-de-difficulte')),
    );
    expect(regle.data, SeuilsDeDifficulte.regleAffichee);
  });

  testWidgets('SANS ETAPE NI NUIT, LE BLOC N OCCUPE RIEN', (tester) async {
    // LA REGLE DU TROU (tache 846, quatrieme demande) : pas de cadre vide, pas
    // de point d'interrogation, pas de hauteur reservee. Verifie sur TOUT
    // l'arbre, hors ecran compris.
    await tester.pumpWidget(sousTest(stages: const <StageModel>[]));
    expect(
      find.byKey(const ValueKey('difficulte-calculee'), skipOffstage: false),
      findsNothing,
    );
    expect(find.text('Difficulte', skipOffstage: false), findsNothing);
    expect(
      find.byKey(const ValueKey('jauge-du-verdict'), skipOffstage: false),
      findsNothing,
    );
  });

  testWidgets('UNE SEULE ALLURE : aucun choix a proposer', (tester) async {
    // Un choix a une seule option n'est pas un choix : les pastilles
    // disparaissent, mais le mot CONSEILLE reste — c'est toujours un conseil.
    await tester.pumpWidget(
      sousTest(allures: const <int>[4], allureParDefaut: 4),
    );
    expect(find.byKey(const ValueKey('allure-4')), findsNothing);
    expect(find.byKey(const ValueKey('jours-conseilles')), findsOneWidget);
  });
}
