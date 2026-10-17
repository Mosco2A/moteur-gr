// GARDE — TACHE 853 : CHAQUE ALLURE PORTE UN CHIFFRE, ET PLUS UN MOT.
//
// CE QUI EST MORT, ET POURQUOI IL FAUT L'ECRIRE PLUTOT QUE DE L'EFFACER.
// Christophe annoncait une echelle de MOTS le 17/10 11:05, verbatim : « Et
// quand tu presente tu mets 7 jours= experts, 9jours = tres difficile, 12 jours
// Difficile, 16 jours = Difficile ». La mesure de la tache 852 l'a tuee en deux
// temps : la bande « expert » n'existe plus (decision du 17/10 17:25), et les
// QUATRE allures du GR20 sortent TRES DIFFICILE — de sept a trente et un jours,
// dans les deux sens. Afficher quatre fois le meme mot a cote de quatre nombres
// de jours differents ne dit RIEN au client, et lui laisse croire que les
// quatre allures se valent.
//
// CE QUI LE REMPLACE : L'EFFORT DE LA JOURNEE LA PLUS DURE DE CHAQUE ALLURE.
// Le mot ne bouge pas, le chiffre si — et le chiffre dit exactement ce que
// l'echelle de mots voulait dire : 55,3 km-effort a sept jours contre 26,5 a
// seize, soit DEUX FOIS la journee la plus dure pour le meme chemin. C'est ca
// que serrer l'allure coute.
//
// C'est la pire journee et non la moyenne, par la meme regle que le verdict
// (Christophe, 17/10 11:07 : « un sentier qui a 5 etapes a moins de 1000 metre
// et une a plus de 1500 est classe expert »).
//
// LES CHIFFRES DU GR20 NE SONT PAS ECRITS A LA MAIN ICI : ils sont RELUS dans
// `assets/data/gr20/nuits_possibles.json`, et le decoupage est celui du
// produit. Un chiffre de trace qui bouge fait rougir ce fichier.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';
import 'package:moteur_gr/features/trail/widgets/difficulte_calculee.dart';

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
/// 25,2 tres difficile (en km-effort). Le meme decor que la tache 848.
final decor = <StageModel>[
  etape(1, 5, 200, 100),
  etape(2, 8, 400, 200),
  etape(3, 10, 700, 300),
  etape(4, 12, 1200, 400),
];

Widget sousTest({
  List<int> allures = const <int>[2, 4],
  int allureParDefaut = 4,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: DifficulteCalculee(
        stages: decor,
        allures: allures,
        allureParDefaut: allureParDefaut,
      ),
    ),
  ),
);

/// Les trente et une nuits relevees du GR20 (tache 838), telles qu'embarquees.
DecoupageDeNuits lireLesNuitsDuGr20() => DecoupageDeNuits.fromJson(
  jsonDecode(File('assets/data/gr20/nuits_possibles.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// La difficulte du GR20 a [jours], decoupee sur ses nuits relevees — le meme
/// chemin que l'ecran prend.
DifficulteDuSentier surLesNuits(DecoupageDeNuits nuits, int jours) =>
    DifficulteDuSentier.calculer(
      jours: jours,
      journees: DecoupageSurLesNuits.repartir(nuits, jours)
          .map(
            (journee) => JourneeMesuree(
              km: journee.km,
              deniveleM: journee.deniveleM,
              descenteM: journee.descenteM,
            ),
          )
          .toList(growable: false),
    )!;

void main() {
  group('853 — l ecran porte le chiffre de chaque allure', () {
    testWidgets('CHAQUE ALLURE AFFICHE L EFFORT DE SA PIRE JOURNEE', (
      tester,
    ) async {
      await tester.pumpWidget(sousTest());

      // A QUATRE JOURS le decor donne une journee par etape : 7,3 / 12,6 /
      // 17,9 / 25,2 km-effort, donc 25,2 pour la pire.
      //
      // A DEUX JOURS, LE REPARTITEUR NE COUPE PAS AU MILIEU DU COMPTE, IL
      // EQUILIBRE LA CHARGE : il met les TROIS premieres etapes (les plus
      // legeres) dans la premiere journee et la quatrieme seule dans la
      // seconde. Journee 1 : 23 km / 1 300 m / 600 m = 37,8 km-effort ;
      // journee 2 : 12 km / 1 200 m / 400 m = 25,2. La pire est donc 37,8, et
      // c'est la premiere — un decoupage « deux et deux » aurait donne 43,1 sur
      // la seconde, soit une journee PLUS dure. L'equilibrage travaille, et ce
      // chiffre-la le prouve.
      final deux = tester.widget<Text>(
        find.byKey(const ValueKey('effort-de-l-allure-2')),
      );
      final quatre = tester.widget<Text>(
        find.byKey(const ValueKey('effort-de-l-allure-4')),
      );
      expect(deux.data, '37,8');
      expect(quatre.data, '25,2');

      // LE NOMBRE DE JOURS RESTE LA LIGNE DE TETE, et le conseil reste marque.
      expect(find.text('4 jours (conseille)'), findsOneWidget);
      expect(find.text('2 jours'), findsOneWidget);
    });

    testWidgets('SERRER L ALLURE MONTE LE CHIFFRE, ET C EST LE POINT', (
      tester,
    ) async {
      await tester.pumpWidget(sousTest());
      final deux = double.parse(
        tester
            .widget<Text>(find.byKey(const ValueKey('effort-de-l-allure-2')))
            .data!
            .replaceAll(',', '.'),
      );
      final quatre = double.parse(
        tester
            .widget<Text>(find.byKey(const ValueKey('effort-de-l-allure-4')))
            .data!
            .replaceAll(',', '.'),
      );
      // MOINS DE JOURS, PLUS D EFFORT PAR JOURNEE : c'est la seule chose que la
      // ligne des allures doit faire comprendre, et elle doit la faire
      // comprendre SANS commentaire.
      expect(deux, greaterThan(quatre));
    });

    testWidgets('L UNITE EST DITE UNE FOIS, SOUS LA LIGNE DES ALLURES', (
      tester,
    ) async {
      // UN NOMBRE SANS SON SENS EST PIRE QU UN MOT : il a l'air de mesurer le
      // SENTIER alors qu'il mesure une ALLURE. L'unite est nommee une seule
      // fois plutot que repetee sur chaque pastille, sinon les quatre
      // pastilles deviennent si larges que l'ecart ne se voit plus.
      await tester.pumpWidget(sousTest());
      final legende = tester.widget<Text>(
        find.byKey(const ValueKey('ce-que-l-allure-coute')),
      );
      expect(legende.data, contains('journee la plus dure'));
      expect(legende.data, contains('kilometres-effort'));
      expect(legende.data, contains('un kilometre de plat'));
    });

    testWidgets('AUCUN MOT DE NIVEAU NE S ACCROCHE A UNE ALLURE', (
      tester,
    ) async {
      // LA REGRESSION QUE CE CAS INTERDIT : recoller un mot par allure. Les
      // quatre allures du GR20 rendent le MEME mot ; une pastille « 7 jours —
      // tres difficile » a cote d'une pastille « 16 jours — tres difficile »
      // affirme que les deux se valent, ce qui est faux de moitie.
      await tester.pumpWidget(sousTest());
      for (final niveau in NiveauDeDifficulte.values) {
        expect(
          find.text('2 jours (${niveau.libelle.toLowerCase()})'),
          findsNothing,
          reason: 'aucune allure ne porte le mot ${niveau.libelle}',
        );
      }
      // Et le mot du verdict reste affiche UNE fois, pour l'allure retenue.
      expect(
        find.text(NiveauDeDifficulte.tresDifficile.libelle),
        findsOneWidget,
      );
    });

    testWidgets('UNE SEULE ALLURE : AUCUNE LIGNE DE CHOIX, AUCUN CHIFFRE', (
      tester,
    ) async {
      // Il n'y a rien a comparer, donc rien a afficher : une ligne de choix a
      // une seule case est un faux choix.
      await tester.pumpWidget(sousTest(allures: const <int>[4]));
      expect(find.byKey(const ValueKey('effort-de-l-allure-4')), findsNothing);
      expect(find.byKey(const ValueKey('ce-que-l-allure-coute')), findsNothing);
      // Le nombre de jours conseille, lui, reste dit.
      expect(find.byKey(const ValueKey('jours-conseilles')), findsOneWidget);
    });
  });

  group('853 — ce que les quatre allures du GR20 coutent vraiment', () {
    test('LES QUATRE CHIFFRES DE LA FICHE, RELUS DANS LA DONNEE', () {
      // LES MEMES QUATRE QUE LA MESURE DE LA 852, et c'est VOLONTAIREMENT une
      // redite : la 852 les figeait dans le socle, ce cas-ci verifie que ce
      // sont bien ces nombres que la LIGNE DES ALLURES va porter a l'ecran.
      final nuits = lireLesNuitsDuGr20();
      expect(gr20TrailConfig.availableDurations, <int>[7, 9, 12, 16]);

      final attendu = <int, double>{7: 55.3, 9: 43.1, 12: 35.1, 16: 26.5};
      for (final entree in attendu.entries) {
        final difficulte = surLesNuits(nuits, entree.key);
        expect(
          difficulte.pireJournee!.kmEffort,
          closeTo(entree.value, 0.05),
          reason: 'a ${entree.key} jours',
        );
        // ET LE MOT, LUI, NE BOUGE PAS : voila pourquoi il ne peut pas servir
        // d'echelle.
        expect(
          difficulte.verdict,
          NiveauDeDifficulte.tresDifficile,
          reason: 'a ${entree.key} jours le mot est le meme',
        );
      }
    });

    test('SEPT JOURS COUTENT LE DOUBLE DE SEIZE, ET LE MOT N EN DIT RIEN', () {
      // L'ARGUMENT DE VENTE EN UN RAPPORT. C'est le chiffre que l'echelle de
      // mots de Christophe cherchait a dire et n'arrivait pas a dire, puisque
      // ses quatre bandes rendaient le meme mot.
      final nuits = lireLesNuitsDuGr20();
      final sept = surLesNuits(nuits, 7).pireJournee!.kmEffort;
      final seize = surLesNuits(nuits, 16).pireJournee!.kmEffort;
      expect(sept / seize, greaterThan(2.0));
      expect(surLesNuits(nuits, 7).verdict, surLesNuits(nuits, 16).verdict);
    });

    test('LE CHIFFRE DESCEND QUAND L ALLURE S ETALE, SANS EXCEPTION', () {
      // LA MONOTONIE EST UNE PROPRIETE DU DECOUPAGE, PAS UNE COINCIDENCE : un
      // jour de plus ne peut pas rendre la pire journee PLUS dure. Si ce cas
      // rougit, c'est le repartiteur qui a un defaut, pas l'affichage.
      final nuits = lireLesNuitsDuGr20();
      var precedent = double.infinity;
      for (var jours = 7; jours <= 31; jours++) {
        final effort = surLesNuits(nuits, jours).pireJournee!.kmEffort;
        expect(
          effort,
          lessThanOrEqualTo(precedent + 0.001),
          reason: 'a $jours jours la pire journee remonte',
        );
        precedent = effort;
      }
      // Et le plancher structurel reste : la premiere journee ne se coupe pas.
      expect(precedent, closeTo(26.48, 0.01));
    });
  });
}
