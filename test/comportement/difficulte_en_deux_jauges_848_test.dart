// GARDE — TACHE 848 : LES SEUILS CLASSENT LA JOURNEE, LE VERDICT EST CELUI DE
// LA PIRE, ET LE REPARTITEUR REND LE NOMBRE DE JOURS DEMANDE.
//
// CE FICHIER REMPLACE `difficulte_deduite_846_test.dart`, ET IL FAUT DIRE
// POURQUOI PLUTOT QUE DE LE FAIRE DISPARAITRE. La tache 846 avait fige une
// regle a TROIS mesures — denivele moyen par journee, journee la plus dure,
// altitude maximale — dont on prenait le pire. Christophe l'a changee le 17/10
// 11:04 puis 11:07-11:08 : les seuils classent L'ETAPE sur son denivele, le
// verdict du sentier est celui de SA PIRE etape, l'altitude SORT du calcul, et
// l'affichage est une JAUGE DOUBLE. Les cas de la 846 qui figeaient la moyenne
// et l'altitude ne sont donc pas « reparables » : ils gardaient une regle qui
// n'est plus la regle. Ceux qui survivent sont repris ici mot pour mot.
//
// LES CHIFFRES DU GR20 NE SONT PAS ECRITS A LA MAIN : ils sont RELUS dans
// `assets/data/gr20.json` et `assets/data/gr20/nuits_possibles.json`, produits
// par `tool/gr20_dans_stepways.py` depuis la trace de 9 128 points. Un chiffre
// modifie quelque part fait rougir ce fichier.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/decoupage_sur_les_nuits.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';

/// Les seize etapes du GR20, telles que la donnee les porte.
List<StageModel> lireLesEtapesDuGr20() {
  final brut =
      jsonDecode(File('assets/data/gr20.json').readAsStringSync())
          as Map<String, dynamic>;
  return [
    for (final e
        in (brut['stages'] as List<dynamic>).cast<Map<String, dynamic>>())
      StageModel(
        trailId: 'gr20',
        stageNumber: e['stageNumber'] as int,
        name: e['nameFr'] as String,
        distanceKm: (e['distanceKm'] as num).toDouble(),
        elevationGainM: (e['elevationGain'] as num).round(),
        elevationLossM: (e['elevationLoss'] as num).round(),
        startLat: 0,
        startLng: 0,
        endLat: 0,
        endLng: 0,
      ),
  ];
}

/// Les trente et une nuits relevees du GR20 (tache 838), telles qu'embarquees.
DecoupageDeNuits lireLesNuitsDuGr20() => DecoupageDeNuits.fromJson(
  jsonDecode(File('assets/data/gr20/nuits_possibles.json').readAsStringSync())
      as Map<String, dynamic>,
);

/// La difficulte du GR20 a l'allure [jours], PAR LE MEME CHEMIN QUE LA FICHE :
/// les journees posees sur les nuits relevees, puis la deduction.
DifficulteDuSentier surLesNuits(int jours) => DifficulteDuSentier.calculer(
  jours: jours,
  denivelesParJournee: DecoupageSurLesNuits.repartir(
    lireLesNuitsDuGr20(),
    jours,
  ).map((journee) => journee.deniveleM).toList(growable: false),
)!;

/// La difficulte d'une liste d'etapes regroupees sur [jours] journees.
DifficulteDuSentier surLesEtapes(List<StageModel> etapes, int jours) =>
    DifficulteDuSentier.calculer(
      jours: jours,
      denivelesParJournee: PlanningCalculator.distribute(etapes, jours)
          .where((jour) => !jour.isRestDay)
          .map((jour) => jour.totalElevationGainM)
          .toList(growable: false),
    )!;

void main() {
  group('848 — la regle : la pire journee fait le verdict', () {
    test('L\'EXEMPLE DE CHRISTOPHE, mot pour mot, devient un cas', () {
      // « Mais un sentier qui a 5 etapes a moins de 1000 metre et une a plus de
      // 1500 est classe expert » (17/10 11:07). Cinq journees moyennes et une
      // d'expert : le verdict est EXPERT. Une moyenne rendrait 683 m, soit
      // « moyen » — et noierait exactement la journee qui casse le marcheur.
      final d = DifficulteDuSentier.calculer(
        jours: 6,
        denivelesParJournee: const <int>[500, 500, 500, 500, 500, 1600],
      )!;
      expect(d.verdict, NiveauDeDifficulte.expert);
      expect(d.pireJournee!.deniveleM, 1600);
      expect(d.pireJournee!.numero, 6);
      // La moyenne, si on l'avait gardee, aurait dit « moyen » :
      expect(SeuilsDeDifficulte.pourDenivele(683), NiveauDeDifficulte.moyen);
    });

    test('LES CINQ BANDES, A LEURS BORNES EXACTES', () {
      // Les bornes sont INCLUSIVES EN BAS : 1 000 m est tres difficile, pas
      // difficile. C'est la lettre de « a partir de 1000 metres ».
      expect(SeuilsDeDifficulte.pourDenivele(0), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourDenivele(399), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourDenivele(400), NiveauDeDifficulte.moyen);
      expect(SeuilsDeDifficulte.pourDenivele(699), NiveauDeDifficulte.moyen);
      expect(
        SeuilsDeDifficulte.pourDenivele(700),
        NiveauDeDifficulte.difficile,
      );
      expect(
        SeuilsDeDifficulte.pourDenivele(999),
        NiveauDeDifficulte.difficile,
      );
      expect(
        SeuilsDeDifficulte.pourDenivele(1000),
        NiveauDeDifficulte.tresDifficile,
      );
      expect(
        SeuilsDeDifficulte.pourDenivele(1499),
        NiveauDeDifficulte.tresDifficile,
      );
      expect(SeuilsDeDifficulte.pourDenivele(1500), NiveauDeDifficulte.expert);
    });

    test('LES DEUX SEUILS DU HAUT SONT CEUX DE CHRISTOPHE', () {
      // « 0 partir de 1000 metres de denivele par jour on passe a tres
      // difficile, au dessus de 1500 a expert ». Les deux nombres sont dans le
      // code, pas dans un commentaire.
      expect(SeuilsDeDifficulte.deniveleTresDifficileM, 1000);
      expect(SeuilsDeDifficulte.deniveleExpertM, 1500);
      expect(SeuilsDeDifficulte.deniveleMoyenM, 400);
      expect(SeuilsDeDifficulte.deniveleDifficileM, 700);
    });

    test('L\'ALTITUDE N\'ENTRE PLUS DANS LE CALCUL', () {
      // Le GR20 monte a 2 578 m. Sous la regle de la 846, une altitude
      // superieure a 2 500 m suffisait a declarer un sentier EXPERT. Christophe
      // ne la retient pas : trois petites journees font un sentier FACILE,
      // quelle que soit l'altitude de la trace.
      final d = DifficulteDuSentier.calculer(
        jours: 3,
        denivelesParJournee: const <int>[100, 200, 300],
      )!;
      expect(d.verdict, NiveauDeDifficulte.facile);
      expect(d.mesuresManquantes, isEmpty);
    });

    test('LA REPARTITION COMPTE LES CINQ NIVEAUX, ZEROS COMPRIS', () {
      final d = DifficulteDuSentier.calculer(
        jours: 4,
        denivelesParJournee: const <int>[100, 500, 500, 1200],
      )!;
      expect(d.repartition.length, NiveauDeDifficulte.values.length);
      expect(d.repartition[NiveauDeDifficulte.facile], 1);
      expect(d.repartition[NiveauDeDifficulte.moyen], 2);
      expect(d.repartition[NiveauDeDifficulte.difficile], 0);
      expect(d.repartition[NiveauDeDifficulte.tresDifficile], 1);
      expect(d.repartition[NiveauDeDifficulte.expert], 0);
      // La somme des comptes EST le nombre de journees : aucune journee ne se
      // perd entre les bandes.
      expect(d.repartition.values.reduce((a, b) => a + b), d.journeesDeMarche);
    });

    test('sans journee, il n y a AUCUN verdict, et le manque est NOMME', () {
      final vide = DifficulteDuSentier.calculer(
        jours: 3,
        denivelesParJournee: const <int>[],
      )!;
      expect(vide.verdict, isNull);
      expect(vide.pireJournee, isNull);
      expect(vide.mesuresManquantes, contains('le denivele des journees'));
    });

    test('UNE JOURNEE CLASSEE NE SE SEPARE PAS DE SA MESURE', () {
      // Les trois champs voyagent ENSEMBLE, et c'est voulu : « Tres
      // difficile » tout seul est une affirmation ; « Tres difficile —
      // 1 455 m de montee dans la journee 1 » est une deduction que le
      // randonneur peut refaire. La fiche affiche les trois.
      const journee = JourneeClassee(
        numero: 1,
        deniveleM: 1455,
        niveau: NiveauDeDifficulte.tresDifficile,
      );
      expect(journee.numero, 1);
      expect(journee.deniveleM, 1455);
      expect(journee.niveau, NiveauDeDifficulte.tresDifficile);
      // Et le niveau porte n'est pas libre : c'est celui que les seuils
      // rendent pour ce denivele-la.
      expect(
        SeuilsDeDifficulte.pourDenivele(journee.deniveleM),
        journee.niveau,
      );
    });

    test('zero jour ne produit pas de difficulte', () {
      expect(
        DifficulteDuSentier.calculer(
          jours: 0,
          denivelesParJournee: const <int>[500],
        ),
        isNull,
      );
    });

    test('LA REGLE AFFICHEE EST LA REGLE APPLIQUEE', () {
      // Elle interpole les constantes : un seuil change dans le code change le
      // texte affiche, et il est impossible d'afficher autre chose que ce qui
      // est applique.
      final regle = SeuilsDeDifficulte.regleAffichee;
      expect(regle, contains('${SeuilsDeDifficulte.deniveleMoyenM} m'));
      expect(regle, contains('${SeuilsDeDifficulte.deniveleDifficileM} m'));
      expect(regle, contains('${SeuilsDeDifficulte.deniveleTresDifficileM} m'));
      expect(regle, contains('${SeuilsDeDifficulte.deniveleExpertM} m'));
      expect(regle, contains('la PLUS DURE'));
      expect(regle, contains('jamais une moyenne'));
      expect(
        regle,
        isNot(contains('altitude')),
        reason: 'l\'altitude est sortie du calcul, elle sort aussi du texte',
      );
    });
  });

  group('848 — le repartiteur rend le NOMBRE DE JOURS DEMANDE', () {
    test('LE DEFAUT DE LA 846 EST RENVERSE, AUX MEMES ALLURES', () {
      // MESURE DE LA 846 : 7 jours demandes rendaient 6 journees, 9 en
      // rendaient 6, 10 en rendaient 7, 12 en rendaient 8. Les memes appels
      // rendent desormais le compte demande.
      final etapes = lireLesEtapesDuGr20();
      expect(etapes.length, 16);
      for (final jours in <int>[7, 9, 10, 12, 16]) {
        expect(
          surLesEtapes(etapes, jours).journeesDeMarche,
          jours,
          reason: '$jours jours demandes doivent rendre $jours journees',
        );
      }
    });

    test('AUCUNE JOURNEE VIDE, A TOUTES LES ALLURES', () {
      final etapes = lireLesEtapesDuGr20();
      for (var jours = 1; jours <= etapes.length; jours++) {
        final journees = PlanningCalculator.distribute(
          etapes,
          jours,
        ).where((jour) => !jour.isRestDay).toList();
        expect(journees.length, jours);
        for (final journee in journees) {
          expect(
            journee.stages,
            isNotEmpty,
            reason: 'une journee de marche sans etape n est pas une journee',
          );
        }
      }
      // L'ORDRE EST GARDE : les etapes se suivent, on ne marche pas la 6 avant
      // la 5.
      final numeros = PlanningCalculator.distribute(etapes, 7)
          .expand((jour) => jour.stages)
          .map((etape) => etape.stageNumber)
          .toList();
      expect(numeros, List<int>.generate(16, (i) => i + 1));
    });

    test('SUR LES NUITS RELEVEES AUSSI, ET JUSQU A TRENTE ET UNE', () {
      final nuits = lireLesNuitsDuGr20();
      expect(nuits.segments.length, 31);
      expect(nuits.journeesMaximales, 31);
      for (var jours = 1; jours <= 31; jours++) {
        final journees = DecoupageSurLesNuits.repartir(nuits, jours);
        expect(journees.length, jours, reason: '$jours jours demandes');
        for (final journee in journees) {
          expect(journee.segments, isNotEmpty);
        }
      }
    });
  });

  group('848 — le GR20 mesure, allure par allure', () {
    test('LA PIRE JOURNEE NE DESCEND JAMAIS SOUS 1 455 M', () {
      // LE PLANCHER EST STRUCTUREL, PAS UN REGLAGE. Le premier segment du
      // GR20 — Calenzana a l'Ortu di u Piobbu, 11,349 km et 1 455 m de montee —
      // ne porte AUCUNE nuit relevee a l'interieur : c'est la plus petite unite
      // que le decoupage sait manipuler. Aucun nombre de jours, de 1 a 31, ne
      // peut donc produire une journee la plus dure inferieure a 1 455 m.
      final nuits = lireLesNuitsDuGr20();
      final premier = nuits.segments.first;
      expect(premier.depart, 'Calenzana');
      expect(premier.arrivee, 'Refuge de l\'Ortu di u Piobbu');
      expect(premier.deniveleM, 1455);
      // LE SEGMENT EST INDIVISIBLE : la PREMIERE nuit relevee du sentier est
      // deja son arrivee. Il n'y a donc aucun endroit ou dormir entre
      // Calenzana et l'Ortu di u Piobbu, et c'etait tout le grief de
      // Christophe du 29/09 — « couper une journer c est dormir ou? ».
      expect(nuits.nuits.first.nom, 'Refuge de l\'Ortu di u Piobbu');
      expect(nuits.nuits.first.pkKm, 11.349);
      for (var jours = 1; jours <= 31; jours++) {
        expect(
          surLesNuits(jours).pireJournee!.deniveleM,
          greaterThanOrEqualTo(1455),
          reason: 'a $jours jours',
        );
      }
    });

    test('LES QUATRE ALLURES DE LA FICHE, MESUREES', () {
      // Ce sont les quatre allures que le selecteur propose, et les chiffres
      // sont ceux que la fiche affiche.
      expect(gr20TrailConfig.availableDurations, <int>[7, 9, 12, 16]);
      expect(gr20TrailConfig.defaultDuration, 16);

      final sept = surLesNuits(7);
      expect(sept.journeesDeMarche, 7);
      expect(sept.pireJournee!.deniveleM, 2088);
      expect(sept.verdict, NiveauDeDifficulte.expert);

      final neuf = surLesNuits(9);
      expect(neuf.journeesDeMarche, 9);
      expect(neuf.pireJournee!.deniveleM, 2088);
      expect(neuf.verdict, NiveauDeDifficulte.expert);

      final douze = surLesNuits(12);
      expect(douze.journeesDeMarche, 12);
      expect(douze.pireJournee!.deniveleM, 1455);
      expect(douze.verdict, NiveauDeDifficulte.tresDifficile);

      final seize = surLesNuits(16);
      expect(seize.journeesDeMarche, 16);
      expect(seize.pireJournee!.deniveleM, 1455);
      expect(seize.verdict, NiveauDeDifficulte.tresDifficile);
    });

    test('A SEIZE JOURS, LA REPARTITION DIT CE QU UN MOT NE DIT PAS', () {
      // Le verdict est « tres difficile », mais DEUX journees seulement le
      // sont : les quatorze autres sont plus faciles. C'est exactement ce que
      // la jauge de repartition montre et qu'un mot seul cache.
      final seize = surLesNuits(16);
      final r = seize.repartition;
      expect(r.values.reduce((a, b) => a + b), 16);
      expect(r[NiveauDeDifficulte.expert], 0);
      expect(r[NiveauDeDifficulte.tresDifficile], 2);
      expect(r[NiveauDeDifficulte.difficile], 6);
      expect(r[NiveauDeDifficulte.moyen], 7);
      expect(r[NiveauDeDifficulte.facile], 1);
    });

    test('LES NUITS RELEVEES ALLEGENT LA PIRE JOURNEE, ET CA SE CHIFFRE', () {
      // A DOUZE JOURS : les seize etapes de la federation laissent une journee
      // a 1 824 m de montee ; les trente et une nuits relevees descendent a
      // 1 455 m. 369 m de montee en moins sur la journee la plus dure, soit un
      // cran de verdict : expert d'un cote, tres difficile de l'autre.
      final parLesEtapes = surLesEtapes(lireLesEtapesDuGr20(), 12);
      final parLesNuits = surLesNuits(12);
      expect(parLesEtapes.pireJournee!.deniveleM, 1824);
      expect(parLesEtapes.verdict, NiveauDeDifficulte.expert);
      expect(parLesNuits.pireJournee!.deniveleM, 1455);
      expect(parLesNuits.verdict, NiveauDeDifficulte.tresDifficile);
      expect(
        parLesEtapes.pireJournee!.deniveleM -
            parLesNuits.pireJournee!.deniveleM,
        369,
      );
    });

    test('A L ALLURE FEDERALE, UNE ETAPE PAR JOUR : 1 453 M', () {
      // Sur les ETAPES, la pire est l'etape 1 a 1 453 m — deux metres de moins
      // que le segment de nuits qui couvre le meme terrain (1 455 m). Les deux
      // chiffres viennent de deux mesures differentes du meme morceau de trace,
      // et aucun des deux n'est arrondi vers l'autre.
      final seize = surLesEtapes(lireLesEtapesDuGr20(), 16);
      expect(seize.journeesDeMarche, 16);
      expect(seize.pireJournee!.deniveleM, 1453);
      expect(seize.pireJournee!.numero, 1);
      expect(seize.verdict, NiveauDeDifficulte.tresDifficile);
    });
  });

  group('848 — ce que Christophe annonce, face a la mesure', () {
    test('DEUX ANNONCES SUR QUATRE NE CONCORDENT PAS, ET C EST ECRIT ICI', () {
      // ANNONCE DE CHRISTOPHE, 17/10 11:05, verbatim : « Et quand tu presente
      // tu mets 7 jours= experts, 9jours = tres difficile, 12 jours Difficile,
      // 16 jours = Difficile ».
      //
      // CE QUE LA MESURE DIT, sur les nuits relevees :
      //   7 jours  -> expert          : CONCORDE
      //   9 jours  -> expert          : la mesure est PLUS DURE d'un cran
      //   12 jours -> tres difficile  : la mesure est PLUS DURE d'un cran
      //   16 jours -> tres difficile  : la mesure est PLUS DURE d'un cran
      //
      // L'ECART N'EST PAS UN REGLAGE A CORRIGER : le GR20 ne peut pas etre
      // « difficile », parce que sa premiere journee pese 1 455 m et qu'aucune
      // nuit relevee ne permet de la couper. Ce cas EXISTE pour que l'ecart
      // reste visible, et pour qu'il rougisse le jour ou une nuit nouvelle
      // rendrait ce segment divisible.
      final annonce = <int, NiveauDeDifficulte>{
        7: NiveauDeDifficulte.expert,
        9: NiveauDeDifficulte.tresDifficile,
        12: NiveauDeDifficulte.difficile,
        16: NiveauDeDifficulte.difficile,
      };
      final mesure = <int, NiveauDeDifficulte>{
        for (final jours in annonce.keys) jours: surLesNuits(jours).verdict!,
      };

      expect(mesure[7], annonce[7], reason: 'sept jours concordent');
      for (final jours in <int>[9, 12, 16]) {
        expect(
          mesure[jours]!.rang,
          greaterThan(annonce[jours]!.rang),
          reason: 'a $jours jours la mesure est plus dure que l annonce',
        );
      }
      // Et le sentier n'est JAMAIS « difficile » : le plancher est au-dessus.
      expect(
        mesure.values.any((n) => n == NiveauDeDifficulte.difficile),
        isFalse,
      );
    });
  });
}
