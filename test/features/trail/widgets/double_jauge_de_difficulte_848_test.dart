// GARDE — TACHE 848, RECALIBREE 852 : L'ECRAN MONTRE LA REPARTITION *ET* LE
// VERDICT, IL DIT CE QUE L'ACCUMULATION FAIT, ET IL DIT QUE LE NOMBRE DE JOURS
// EST CONSEILLE.
//
// LES DEMANDES DE CHRISTOPHE QUE CES CAS TIENNENT, verbatim.
//   17/10 11:02 : « mais le nombre de jour, c'est du conseille, apres le client
//   le fait dans le nombre de jours qu'il veut ». Le mot « CONSEILLE » doit
//   etre A L'ECRAN, pas seulement dans un commentaire.
//   17/10 11:07-11:08 : « ou alors une jauge avec le nombre d'etape facile a
//   expert et une jauge moyenne (mais qui se base aussi sur la plus
//   difficile) ». DEUX jauges, pas un mot.
//   17/10 17:25 : « facile/moyen/Difficile/tres difficile === et tu mets une
//   methode de calcul par etape et une par troncon ». QUATRE bandes, et le
//   verdict du troncon part de la pire journee puis monte si les journees dures
//   se suivent — donc l'ecran doit DIRE ce que l'accumulation a fait, sinon le
//   mot affiche contredit le chiffre affiche juste en dessous.
//
// ET LE CAS LE PLUS IMPORTANT RESTE LE MEME : la difficulte doit SE RECALCULER
// quand le client change d'allure. C'est le meilleur argument de securite du
// produit — il voit la consequence de son propre choix AVANT de payer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/features/trail/widgets/difficulte_calculee.dart';
import 'package:moteur_gr/features/trail/widgets/jauges_de_difficulte.dart';

/// Une etape de decor, reduite a ce qui compte ici : ses TROIS mesures.
StageModel etape(int numero, double km, int dPlus, int dMoins) => StageModel(
  trailId: 'decor',
  stageNumber: numero,
  name: 'Etape $numero',
  distanceKm: km,
  elevationGainM: dPlus,
  elevationLossM: dMoins,
  startLat: 0,
  startLng: 0,
  endLat: 0,
  endLng: 0,
);

/// Quatre journees, UNE PAR BANDE : 7,3 facile, 12,6 moyen, 17,9 difficile,
/// 25,2 tres difficile (en km-effort).
final decor = <StageModel>[
  etape(1, 5, 200, 100),
  etape(2, 8, 400, 200),
  etape(3, 10, 700, 300),
  etape(4, 12, 1200, 400),
];

/// Quatre journees IDENTIQUES et toutes difficiles (18,9 km-effort) : la pire
/// journee est difficile, mais elles se SUIVENT — l'accumulation doit monter le
/// verdict d'un cran.
final decorQuiSEnchaine = <StageModel>[
  etape(1, 10, 800, 300),
  etape(2, 10, 800, 300),
  etape(3, 10, 800, 300),
  etape(4, 10, 800, 300),
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

  testWidgets('LE VERDICT PART DE LA PIRE JOURNEE, ET ELLE EST CHIFFREE', (
    tester,
  ) async {
    await tester.pumpWidget(sousTest());
    // Quatre journees : 7,3 / 12,6 / 17,9 / 25,2 km-effort. La pire est 25,2
    // -> tres difficile. Une moyenne aurait donne 15,75, soit « moyen » : deux
    // crans de moins, et c'est exactement ce que Christophe refuse.
    expect(find.text(NiveauDeDifficulte.tresDifficile.libelle), findsOneWidget);
    final pire = tester.widget<Text>(
      find.byKey(const ValueKey('pire-journee')),
    );
    // LES TROIS MESURES ET L'EFFORT SONT A L'ECRAN, pas seulement le mot : le
    // randonneur doit pouvoir refaire le calcul.
    expect(pire.data, contains('12,0 km'));
    expect(pire.data, contains('1200 m de montee'));
    expect(pire.data, contains('400 m de descente'));
    expect(pire.data, contains('25,2 km-effort'));
    expect(pire.data, contains('journee 4 sur 4'));
  });

  testWidgets('LA REPARTITION COMPTE LES QUATRE BANDES, ZEROS COMPRIS', (
    tester,
  ) async {
    await tester.pumpWidget(sousTest());
    expect(find.text('Repartition des 4 journees de marche'), findsOneWidget);
    expect(find.text('1 facile'), findsOneWidget);
    expect(find.text('1 moyen'), findsOneWidget);
    expect(find.text('1 difficile'), findsOneWidget);
    expect(find.text('1 tres difficile'), findsOneWidget);
    // LE CINQUIEME MOT N'EST NULLE PART : la bande expert n'existe plus, donc
    // ni son compte ni son zero ne s'affichent.
    expect(find.text('0 expert', skipOffstage: false), findsNothing);
    expect(find.text('0 extreme', skipOffstage: false), findsNothing);
  });

  testWidgets('LE COMPTE D UN NIVEAU DIT MEME SON ZERO', (tester) async {
    // [CompteDUnNiveau] est la brique de la ligne de comptes, et c'est la
    // SEULE qui n'a pas d'appelant hors de sa bibliotheque : la jauge de
    // repartition l'assemble. Elle est donc testee directement, et sur le cas
    // qui compte — le ZERO, qui doit s'ECRIRE et non disparaitre, pour qu'on
    // voie qu'un sentier n'a AUCUNE journee facile quand c'est le cas.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              CompteDUnNiveau(niveau: NiveauDeDifficulte.facile, journees: 0),
              CompteDUnNiveau(
                niveau: NiveauDeDifficulte.difficile,
                journees: 7,
              ),
            ],
          ),
        ),
      ),
    );
    expect(find.text('0 facile'), findsOneWidget);
    expect(find.text('7 difficile'), findsOneWidget);
  });

  testWidgets('L ACCUMULATION EST DITE, ET ELLE MONTE LE VERDICT', (
    tester,
  ) async {
    // QUATRE JOURNEES DIFFICILES D AFFILEE. La pire journee est DIFFICILE
    // (18,9 km-effort), et pourtant le verdict affiche est TRES DIFFICILE :
    // c'est l'accumulation. L'ecran doit le DIRE, sinon le mot contredit le
    // chiffre de la ligne du dessous.
    await tester.pumpWidget(
      sousTest(
        stages: decorQuiSEnchaine,
        allures: const <int>[4],
        allureParDefaut: 4,
      ),
    );
    expect(find.text(NiveauDeDifficulte.tresDifficile.libelle), findsOneWidget);
    expect(find.text('4 difficile'), findsOneWidget);
    final pire = tester.widget<Text>(
      find.byKey(const ValueKey('pire-journee')),
    );
    expect(pire.data, contains('18,9 km-effort'));
    final accumulation = tester.widget<Text>(
      find.byKey(const ValueKey('accumulation')),
    );
    expect(accumulation.data, contains('4, dont 4 d\'affilee'));
    expect(accumulation.data, contains('monte le verdict d\'un cran'));
    expect(accumulation.data, contains('difficile'));
  });

  testWidgets('SANS JOURNEE DURE, L ACCUMULATION NE DIT RIEN DE PLUS', (
    tester,
  ) async {
    await tester.pumpWidget(sousTest());
    final accumulation = tester.widget<Text>(
      find.byKey(const ValueKey('accumulation')),
    );
    // Deux journees hautes, mais elles ne montent pas le verdict : le compte
    // est dit, la consequence n'est pas inventee.
    expect(accumulation.data, contains('2, dont 2 d\'affilee'));
    expect(accumulation.data, isNot(contains('monte le verdict')));
  });

  testWidgets('CHANGER D ALLURE RECALCULE LE VERDICT', (tester) async {
    await tester.pumpWidget(sousTest());
    var pire = tester.widget<Text>(find.byKey(const ValueKey('pire-journee')));
    expect(pire.data, contains('25,2 km-effort'));
    expect(find.text('Repartition des 4 journees de marche'), findsOneWidget);

    // Deux jours : les quatre etapes se regroupent, et la pire journee devient
    // bien plus lourde que la plus lourde des quatre.
    await tester.tap(find.byKey(const ValueKey('allure-2')));
    await tester.pumpAndSettle();

    expect(find.text('Repartition des 2 journees de marche'), findsOneWidget);
    pire = tester.widget<Text>(find.byKey(const ValueKey('pire-journee')));
    expect(pire.data, contains('sur 2'));
    expect(pire.data, isNot(contains('25,2 km-effort')));
    expect(find.text(NiveauDeDifficulte.tresDifficile.libelle), findsOneWidget);
  });

  testWidgets('LES DEUX REGLES SONT SOUS LE RESULTAT', (tester) async {
    await tester.pumpWidget(sousTest());
    final regleDuJour = tester.widget<Text>(
      find.byKey(const ValueKey('regle-de-difficulte')),
    );
    expect(regleDuJour.data, SeuilsDeDifficulte.regleAffichee);
    // ET LA SECONDE METHODE A SA REGLE A ELLE : un verdict de troncon qui monte
    // d'un cran sans le dire ne serait pas refaisable par le lecteur.
    final regleDuTroncon = tester.widget<Text>(
      find.byKey(const ValueKey('regle-du-troncon')),
    );
    expect(regleDuTroncon.data, SeuilsDeDifficulte.regleDuTronconAffichee);
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
