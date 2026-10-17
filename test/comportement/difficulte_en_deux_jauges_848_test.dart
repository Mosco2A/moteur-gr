// GARDE — TACHE 852 : QUATRE BANDES, L'EFFORT D'UNE JOURNEE SUR SES TROIS
// MESURES, ET LE VERDICT D'UN TRONCON QUI PART DE SA PIRE JOURNEE.
//
// CE FICHIER A DEJA REMPLACE `difficulte_deduite_846_test.dart`, ET IL EST
// RECALIBRE PAR LA 852. IL FAUT DIRE POURQUOI PLUTOT QUE DE LE FAIRE
// DISPARAITRE.
//
//  - LA 846 figeait une regle a TROIS mesures (denivele moyen, journee la plus
//    dure, altitude maximale) dont on prenait le pire. Christophe l'a changee
//    le 17/10 11:04 : les seuils classent LA JOURNEE, le verdict est celui de
//    la PIRE, l'altitude SORT.
//  - LA 848 figeait CINQ bandes et des seuils sur le seul DENIVELE POSITIF.
//    Christophe a change les deux le 17/10 17:25, verbatim :
//    « facile/moyen/Difficile/tres difficile === et tu mets une methode de
//    calcul par etape et une par troncon » (memoire #102180). La bande
//    « expert » est SUPPRIMEE ; l'effort d'une journee se calcule sur la
//    distance, la montee ET la descente ; le troncon a sa propre methode.
//
// Les cas qui figeaient cinq bandes ou des seuils en metres de D+ ne sont donc
// pas « reparables » : ils gardaient une regle qui n'est plus la regle. Ceux
// qui survivent sont repris ici mot pour mot.
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
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/feasibility_engine.dart';
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
  journees: DecoupageSurLesNuits.repartir(lireLesNuitsDuGr20(), jours)
      .map(
        (journee) => JourneeMesuree(
          km: journee.km,
          deniveleM: journee.deniveleM,
          descenteM: journee.descenteM,
        ),
      )
      .toList(growable: false),
)!;

/// La difficulte d'une liste d'etapes regroupees sur [jours] journees.
DifficulteDuSentier surLesEtapes(List<StageModel> etapes, int jours) =>
    DifficulteDuSentier.calculer(
      jours: jours,
      journees: PlanningCalculator.distribute(etapes, jours)
          .where((jour) => !jour.isRestDay)
          .map(
            (jour) => JourneeMesuree(
              km: jour.totalDistanceKm,
              deniveleM: jour.totalElevationGainM,
              descenteM: jour.totalElevationLossM,
            ),
          )
          .toList(growable: false),
    )!;

/// Un troncon fabrique a la main depuis les seuls efforts voulus, pour tester
/// la methode du TRONCON sans dependre d'un sentier reel.
///
/// Chaque entree est un effort en km-effort, pose en DISTANCE PURE : une
/// journee de plat de `n` km vaut exactement `n` km-effort, donc la table se
/// lit directement dans les bandes.
DifficulteDuSentier tronconDEfforts(List<double> efforts) =>
    DifficulteDuSentier.calculer(
      jours: efforts.length,
      journees: [
        for (final effort in efforts)
          JourneeMesuree(km: effort, deniveleM: 0, descenteM: 0),
      ],
    )!;

void main() {
  group('852 — la methode PAR JOURNEE : quatre bandes, trois mesures', () {
    test('LES QUATRE BANDES, A LEURS BORNES EXACTES', () {
      // Les bornes sont INCLUSIVES EN BAS : 25,0 km-effort est tres difficile,
      // pas difficile. C'est la lettre de « a partir de 1000 metres ».
      expect(SeuilsDeDifficulte.pourEffort(0), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourEffort(9.99), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourEffort(10), NiveauDeDifficulte.moyen);
      expect(SeuilsDeDifficulte.pourEffort(17.49), NiveauDeDifficulte.moyen);
      expect(SeuilsDeDifficulte.pourEffort(17.5), NiveauDeDifficulte.difficile);
      expect(
        SeuilsDeDifficulte.pourEffort(24.99),
        NiveauDeDifficulte.difficile,
      );
      expect(
        SeuilsDeDifficulte.pourEffort(25),
        NiveauDeDifficulte.tresDifficile,
      );
      expect(
        SeuilsDeDifficulte.pourEffort(999),
        NiveauDeDifficulte.tresDifficile,
      );
    });

    test('LA BANDE EXPERT N EXISTE PLUS, ET RIEN NE LA RAPPELLE', () {
      // Christophe, 17/10 17:25 : quatre mots, pas cinq. La bande du haut est
      // « tres difficile » et elle est OUVERTE — il n'y a plus de cran au-dela,
      // donc plus aucun effort qui sorte un cinquieme mot.
      expect(NiveauDeDifficulte.values.length, 4);
      expect(NiveauDeDifficulte.values.last, NiveauDeDifficulte.tresDifficile);
      expect(NiveauDeDifficulte.tresDifficile.rang, 3);
      for (final niveau in NiveauDeDifficulte.values) {
        expect(
          niveau.libelle.toLowerCase(),
          isNot(contains('expert')),
          reason: 'aucun libelle ne dit expert',
        );
        expect(
          niveau.libelle.toLowerCase(),
          isNot(contains('extreme')),
          reason: 'aucun libelle ne dit extreme',
        );
        // ET L'ECHELLE NE DEMANDE PLUS JAMAIS `expert` NI `extreme` AU SOCLE :
        // c'est ce trou qui affichait une pastille GRISE avec le mot
        // « extreme » brut a l'ecran (defaut signale par la 848).
        expect(niveau.cleDuSocleApprochante, isNot('expert'));
        expect(niveau.cleDuSocleApprochante, isNot('extreme'));
      }
    });

    test('LES TROIS SEUILS SONT CEUX DE CHRISTOPHE, UN SEUL FACTEUR', () {
      // « 0 partir de 1000 metres de denivele par jour on passe a tres
      // difficile » (17/10 11:04), et les deux bandes du dessous a 400 et 700
      // (17/10 11:07). Un SEUL facteur les transpose en km-effort, et il est
      // dans le code : aucun seuil n'a ete reecrit a la main.
      expect(SeuilsDeDifficulte.metresDeMonteeParKmEffort, 40);
      expect(
        SeuilsDeDifficulte.effortMoyenKm *
            SeuilsDeDifficulte.metresDeMonteeParKmEffort,
        400,
      );
      expect(
        SeuilsDeDifficulte.effortDifficileKm *
            SeuilsDeDifficulte.metresDeMonteeParKmEffort,
        700,
      );
      expect(
        SeuilsDeDifficulte.effortTresDifficileKm *
            SeuilsDeDifficulte.metresDeMonteeParKmEffort,
        1000,
      );
    });

    test('LE FACTEUR EST ENCADRE PAR DEUX JOURNEES QU IL A CLASSEES', () {
      // LE SEUL SEUIL QU IL AIT PRONONCE EST 1 000 M = TRES DIFFICILE, et deux
      // etapes reelles l'encadrent — il a tranche sur les deux le 17/10 11:04 :
      //
      //  - Calenzana - l'Ortu di u Piobbu (11,35 km / 1 453 / 194) est TRES
      //    DIFFICILE : le seuil doit etre DESSOUS de son effort.
      //  - Vizzavona - E Capanelle (13,95 km / 967 / 294) est SOUS le seuil :
      //    le seuil doit etre DESSUS de son effort.
      //
      // 25,0 km-effort est le seul nombre rond de l'intervalle, et c'est lui.
      final calenzana = SeuilsDeDifficulte.effortDeLaJournee(
        km: 11.35,
        deniveleM: 1453,
        descenteM: 194,
      );
      final vizzavona = SeuilsDeDifficulte.effortDeLaJournee(
        km: 13.95,
        deniveleM: 967,
        descenteM: 294,
      );
      expect(calenzana, closeTo(26.46, 0.01));
      expect(vizzavona, closeTo(24.50, 0.01));
      expect(SeuilsDeDifficulte.effortTresDifficileKm, lessThan(calenzana));
      expect(SeuilsDeDifficulte.effortTresDifficileKm, greaterThan(vizzavona));
      expect(
        SeuilsDeDifficulte.pourEffort(calenzana),
        NiveauDeDifficulte.tresDifficile,
      );
      expect(
        SeuilsDeDifficulte.pourEffort(vizzavona),
        NiveauDeDifficulte.difficile,
      );
    });

    test('LES TROIS INGREDIENTS ENTRENT, ET LA DESCENTE NE VAUT PAS ZERO', () {
      // 100 m de montee = 1 km de plat (BP §A, deja en production dans le
      // moteur de faisabilite) ; la descente pese 0,30 de la montee (BP §B).
      // Aucun des deux coefficients n'est choisi dans ce lot.
      expect(SeuilsDeDifficulte.metresDeMonteeParKmDePlat, 100);
      expect(SeuilsDeDifficulte.poidsDeLaDescente, 0.30);

      const km = 10.0;
      final plat = SeuilsDeDifficulte.effortDeLaJournee(
        km: km,
        deniveleM: 0,
        descenteM: 0,
      );
      final avecMontee = SeuilsDeDifficulte.effortDeLaJournee(
        km: km,
        deniveleM: 1000,
        descenteM: 0,
      );
      final avecDescente = SeuilsDeDifficulte.effortDeLaJournee(
        km: km,
        deniveleM: 0,
        descenteM: 1000,
      );
      expect(plat, closeTo(10, 0.001));
      expect(avecMontee, closeTo(20, 0.001));
      expect(avecDescente, closeTo(13, 0.001));
      // La descente compte, et elle compte MOINS que la montee : les deux
      // affirmations sont ici, pas dans un commentaire.
      expect(avecDescente, greaterThan(plat));
      expect(avecDescente, lessThan(avecMontee));
    });

    test('LA DISTANCE BASCULE UNE JOURNEE QUE LE SEUL D+ CLASSAIT BAS', () {
      // L'ETAPE 6 DU GR20, ET C'EST ELLE QUI JUSTIFIE TOUT LE LOT. Ciottulu di
      // i Mori - Manganu ne monte que 786 m — « difficile » sur l'ancienne
      // regle — mais elle fait 25,02 km et descend 1 191 m. Sur l'effort
      // complet elle est TRES DIFFICILE, et c'est la journee la plus dure des
      // seize. Une journee de vingt-cinq kilometres n'est pas facile parce
      // qu'elle monte peu.
      final etape6 = SeuilsDeDifficulte.pourUneJournee(
        km: 25.02,
        deniveleM: 786,
        descenteM: 1191,
      );
      expect(etape6, NiveauDeDifficulte.tresDifficile);
      // Et l'ancienne lecture — le seul D+ transpose — l'aurait laissee un cran
      // plus bas :
      expect(
        SeuilsDeDifficulte.pourEffort(
          786 / SeuilsDeDifficulte.metresDeMonteeParKmEffort,
        ),
        NiveauDeDifficulte.difficile,
      );
    });

    test('L\'ALTITUDE N\'ENTRE PLUS DANS LE CALCUL', () {
      // Le GR20 monte a 2 578 m. Sous la regle de la 846, une altitude
      // superieure a 2 500 m suffisait a declarer un sentier EXPERT. Christophe
      // ne la retient pas : trois petites journees font un sentier FACILE,
      // quelle que soit l'altitude de la trace.
      final d = DifficulteDuSentier.calculer(
        jours: 3,
        journees: const <JourneeMesuree>[
          JourneeMesuree(km: 3, deniveleM: 100, descenteM: 100),
          JourneeMesuree(km: 4, deniveleM: 200, descenteM: 150),
          JourneeMesuree(km: 5, deniveleM: 300, descenteM: 200),
        ],
      )!;
      expect(d.verdict, NiveauDeDifficulte.facile);
      expect(d.mesuresManquantes, isEmpty);
    });

    test('LA REPARTITION COMPTE LES QUATRE NIVEAUX, ZEROS COMPRIS', () {
      final d = tronconDEfforts(const <double>[5, 12, 12, 30]);
      expect(d.repartition.length, NiveauDeDifficulte.values.length);
      expect(d.repartition[NiveauDeDifficulte.facile], 1);
      expect(d.repartition[NiveauDeDifficulte.moyen], 2);
      expect(d.repartition[NiveauDeDifficulte.difficile], 0);
      expect(d.repartition[NiveauDeDifficulte.tresDifficile], 1);
      // La somme des comptes EST le nombre de journees : aucune journee ne se
      // perd entre les bandes.
      expect(d.repartition.values.reduce((a, b) => a + b), d.journeesDeMarche);
    });

    test('sans journee, il n y a AUCUN verdict, et le manque est NOMME', () {
      final vide = DifficulteDuSentier.calculer(
        jours: 3,
        journees: const <JourneeMesuree>[],
      )!;
      expect(vide.verdict, isNull);
      expect(vide.plancher, isNull);
      expect(vide.pireJournee, isNull);
      expect(vide.verdictMonteParLAccumulation, isFalse);
      expect(
        vide.mesuresManquantes,
        contains('la distance et le denivele des journees'),
      );
    });

    test('UNE MESURE NEGATIVE N EST PAS UNE MESURE', () {
      // [JourneeMesuree.estMesurable] est le seul garde-fou a l'entree du
      // calcul, et il est teste ICI parce qu'il n'a pas d'autre appelant que
      // `calculer` : un kilometrage negatif ou un denivele negatif ne sont pas
      // des mesures, et les laisser passer ferait mentir l'effort.
      expect(
        const JourneeMesuree(
          km: 10,
          deniveleM: 500,
          descenteM: 400,
        ).estMesurable,
        isTrue,
      );
      expect(
        const JourneeMesuree(
          km: -1,
          deniveleM: 500,
          descenteM: 400,
        ).estMesurable,
        isFalse,
      );
      expect(
        const JourneeMesuree(
          km: 10,
          deniveleM: -5,
          descenteM: 400,
        ).estMesurable,
        isFalse,
      );
      expect(
        const JourneeMesuree(
          km: 10,
          deniveleM: 500,
          descenteM: -2,
        ).estMesurable,
        isFalse,
      );
      // ZERO EST UNE MESURE : une journee de repos n'entre pas ici, mais un
      // segment plat de longueur nulle entre deux nuits voisines, si.
      expect(
        const JourneeMesuree(km: 0, deniveleM: 0, descenteM: 0).estMesurable,
        isTrue,
      );
    });

    test('UNE MESURE NEGATIVE EST ECARTEE, ET LE COMPTE LE DIT', () {
      final d = DifficulteDuSentier.calculer(
        jours: 3,
        journees: const <JourneeMesuree>[
          JourneeMesuree(km: 10, deniveleM: 500, descenteM: 400),
          JourneeMesuree(km: 10, deniveleM: -5, descenteM: 400),
          JourneeMesuree(km: 10, deniveleM: 500, descenteM: 400),
        ],
      )!;
      // La journee impossible est ECARTEE, et l'ecart se voit : deux journees
      // rendues pour trois jours demandes.
      expect(d.journeesDeMarche, 2);
      expect(d.joursChoisis, 3);
    });

    test('UNE JOURNEE CLASSEE NE SE SEPARE PAS DE SES MESURES', () {
      // Tout voyage ENSEMBLE, et c'est voulu : « Tres difficile » tout seul est
      // une affirmation ; « Tres difficile — 11,3 km, 1 455 m de montee, 194 m
      // de descente, soit 26,5 km-effort » est une deduction que le randonneur
      // peut refaire. La fiche affiche les quatre.
      const journee = JourneeClassee(
        numero: 1,
        km: 11.349,
        deniveleM: 1455,
        descenteM: 194,
      );
      expect(journee.numero, 1);
      expect(journee.km, 11.349);
      expect(journee.deniveleM, 1455);
      expect(journee.descenteM, 194);
      expect(journee.kmEffort, closeTo(26.48, 0.01));
      // Et le niveau porte n'est pas libre : c'est celui que les seuils rendent
      // pour cet effort-la.
      expect(journee.niveau, NiveauDeDifficulte.tresDifficile);
      expect(SeuilsDeDifficulte.pourEffort(journee.kmEffort), journee.niveau);
    });

    test('zero jour ne produit pas de difficulte', () {
      expect(
        DifficulteDuSentier.calculer(
          jours: 0,
          journees: const <JourneeMesuree>[
            JourneeMesuree(km: 10, deniveleM: 500, descenteM: 0),
          ],
        ),
        isNull,
      );
    });

    test('LA REGLE DE LA JOURNEE AFFICHEE EST LA REGLE APPLIQUEE', () {
      // Elle interpole les constantes : un seuil change dans le code change le
      // texte affiche, et il est impossible d'afficher autre chose que ce qui
      // est applique.
      final regle = SeuilsDeDifficulte.regleAffichee;
      expect(
        regle,
        contains('${SeuilsDeDifficulte.metresDeMonteeParKmDePlat} m'),
      );
      expect(regle, contains('10 km-effort'));
      expect(regle, contains('17,5'));
      expect(regle, contains('25'));
      expect(regle, contains('0,30'));
      expect(regle, contains('km-effort'));
      expect(
        regle,
        isNot(contains('altitude')),
        reason: 'l\'altitude est sortie du calcul, elle sort aussi du texte',
      );
      expect(
        regle.toLowerCase(),
        isNot(contains('expert')),
        reason: 'la bande n existe plus, le texte ne la cite plus',
      );
    });

    test('LA REGLE DU TRONCON AFFICHEE EST LA REGLE APPLIQUEE', () {
      final regle = SeuilsDeDifficulte.regleDuTronconAffichee;
      expect(regle, contains('ni la somme ni la moyenne'));
      expect(regle, contains('PLUS DURE'));
      expect(regle, contains('${SeuilsDeDifficulte.suiteQuiMonteLeVerdict} '));
      expect(regle, contains('SUIVENT'));
      expect(regle, contains('d\'un cran'));
    });
  });

  group('852 — la methode PAR TRONCON : plancher puis accumulation', () {
    test('L\'EXEMPLE DE CHRISTOPHE, mot pour mot, devient un cas', () {
      // « Mais un sentier qui a 5 etapes a moins de 1000 metre et une a plus de
      // 1500 est classe expert » (17/10 11:07). Cinq journees moyennes et une
      // tres difficile : le verdict suit la PIRE. Une moyenne rendrait
      // 15 km-effort, soit « moyen » — et noierait exactement la journee qui
      // casse le marcheur.
      final d = tronconDEfforts(const <double>[12, 12, 12, 12, 12, 30]);
      expect(d.plancher, NiveauDeDifficulte.tresDifficile);
      expect(d.verdict, NiveauDeDifficulte.tresDifficile);
      expect(d.pireJournee!.numero, 6);
      expect(d.pireJournee!.kmEffort, closeTo(30, 0.001));
      // La moyenne, si on l'avait gardee, aurait dit « moyen » :
      expect(SeuilsDeDifficulte.pourEffort(15), NiveauDeDifficulte.moyen);
      // Et la somme aurait dit « tres difficile » de n'importe quel sentier
      // long : quatre-vingt-dix journees de plat ne demandent pas de savoir
      // faire ce qu'une journee tres difficile demande.
      expect(
        tronconDEfforts(List<double>.filled(9, 5)).verdict,
        NiveauDeDifficulte.facile,
      );
    });

    test('L\'ACCUMULATION MONTE LE VERDICT D UN CRAN, ET D UN SEUL', () {
      // QUATRE journees difficiles d'affilee : le verdict monte au-dessus du
      // plancher. TROIS : il ne bouge pas. C'est le seul endroit ou le verdict
      // d'un troncon s'ecarte de sa pire journee.
      final trois = tronconDEfforts(const <double>[20, 20, 20, 5]);
      expect(trois.plancher, NiveauDeDifficulte.difficile);
      expect(trois.plusLongueSuiteEnBandesHautes, 3);
      expect(trois.verdictMonteParLAccumulation, isFalse);
      expect(trois.verdict, NiveauDeDifficulte.difficile);

      final quatre = tronconDEfforts(const <double>[20, 20, 20, 20, 5]);
      expect(quatre.plancher, NiveauDeDifficulte.difficile);
      expect(quatre.plusLongueSuiteEnBandesHautes, 4);
      expect(quatre.verdictMonteParLAccumulation, isTrue);
      expect(quatre.verdict, NiveauDeDifficulte.tresDifficile);
      // D'UN CRAN ET D'UN SEUL : dix journees d'affilee ne font pas deux crans,
      // parce qu'il n'y a pas de cran au-dessus.
      final dix = tronconDEfforts(List<double>.filled(10, 20));
      expect(dix.verdict, NiveauDeDifficulte.tresDifficile);
    });

    test('UNE JOURNEE DURE N EST PAS SIX D AFFILEE — son exemple', () {
      // « Un troncon avec une journee dure n'est pas un troncon avec six
      // journees dures d'affilee » (17/10 17:25). Les deux troncons ont la MEME
      // pire journee ; leurs verdicts different.
      final une = tronconDEfforts(const <double>[5, 5, 20, 5, 5, 5]);
      final six = tronconDEfforts(const <double>[20, 20, 20, 20, 20, 20]);
      expect(une.plancher, six.plancher);
      expect(une.pireJournee!.kmEffort, six.pireJournee!.kmEffort);
      expect(une.verdict, NiveauDeDifficulte.difficile);
      expect(six.verdict, NiveauDeDifficulte.tresDifficile);
      // CE QUI LES SEPARE EST LA SUITE, PAS LE COMPTE SEUL : six journees dures
      // ESPACEES ne montent pas le verdict.
      final sixEspacees = tronconDEfforts(const <double>[
        20, 5, 20, 5, 20, 5, 20, 5, 20, 5, 20, 5, //
      ]);
      expect(sixEspacees.journeesEnBandesHautes, 6);
      expect(sixEspacees.plusLongueSuiteEnBandesHautes, 1);
      expect(sixEspacees.verdict, NiveauDeDifficulte.difficile);
    });

    test('LE SEUIL DE LA SUITE EST LA MAJORITE DE LA FENETRE DU PRODUIT', () {
      // LA FENETRE N'EST PAS CHOISIE DANS CE LOT : c'est celle sur laquelle le
      // moteur de faisabilite mesure deja la monotonie de Foster (1998) pour
      // conseiller un jour de repos. Les deux nombres doivent rester le meme —
      // ce test est la pour que personne ne les fasse divulguer.
      expect(
        SeuilsDeDifficulte.fenetreDAccumulationJours,
        FeasibilityFormula.monotonyWindowDays,
      );
      // ET LE SEUIL EST SA PLUS PETITE MAJORITE : la moitie, plus un.
      expect(
        SeuilsDeDifficulte.suiteQuiMonteLeVerdict,
        SeuilsDeDifficulte.fenetreDAccumulationJours ~/ 2 + 1,
      );
      expect(SeuilsDeDifficulte.suiteQuiMonteLeVerdict, 4);
    });

    test('UN TRONCON SANS JOURNEE HAUTE NE MONTE JAMAIS', () {
      // La suite compte les DEUX BANDES HAUTES (le vocabulaire de Christophe) :
      // un troncon dont la pire journee est moyenne n'en a aucune, et trente
      // journees moyennes d'affilee restent un sentier moyen.
      final moyen = tronconDEfforts(List<double>.filled(30, 12));
      expect(moyen.plancher, NiveauDeDifficulte.moyen);
      expect(moyen.journeesEnBandesHautes, 0);
      expect(moyen.plusLongueSuiteEnBandesHautes, 0);
      expect(moyen.verdictMonteParLAccumulation, isFalse);
      expect(moyen.verdict, NiveauDeDifficulte.moyen);
    });

    test('LES DEUX BANDES HAUTES SONT DIFFICILE ET TRES DIFFICILE', () {
      expect(NiveauDeDifficulte.facile.estUneBandeHaute, isFalse);
      expect(NiveauDeDifficulte.moyen.estUneBandeHaute, isFalse);
      expect(NiveauDeDifficulte.difficile.estUneBandeHaute, isTrue);
      expect(NiveauDeDifficulte.tresDifficile.estUneBandeHaute, isTrue);
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

  group('852 — le GR20 remesure, allure par allure', () {
    test('LA PIRE JOURNEE NE DESCEND JAMAIS SOUS 26,4 KM-EFFORT', () {
      // LE PLANCHER EST STRUCTUREL, PAS UN REGLAGE. Le premier segment du
      // GR20 — Calenzana a l'Ortu di u Piobbu, 11,349 km, 1 455 m de montee et
      // 194 m de descente, soit 26,48 km-effort — ne porte AUCUNE nuit relevee
      // a l'interieur : c'est la plus petite unite que le decoupage sait
      // manipuler. Aucun nombre de jours, de 1 a 31, ne peut donc produire une
      // journee la plus dure moins dure que celle-la.
      final nuits = lireLesNuitsDuGr20();
      final premier = nuits.segments.first;
      expect(premier.depart, 'Calenzana');
      expect(premier.arrivee, 'Refuge de l\'Ortu di u Piobbu');
      expect(premier.deniveleM, 1455);
      expect(premier.descenteM, 194);
      expect(premier.km, closeTo(11.349, 0.001));
      // LE SEGMENT EST INDIVISIBLE : la PREMIERE nuit relevee du sentier est
      // deja son arrivee. Il n'y a donc aucun endroit ou dormir entre
      // Calenzana et l'Ortu di u Piobbu, et c'etait tout le grief de
      // Christophe du 29/09 — « couper une journer c est dormir ou? ».
      expect(nuits.nuits.first.nom, 'Refuge de l\'Ortu di u Piobbu');
      expect(nuits.nuits.first.pkKm, 11.349);
      for (var jours = 1; jours <= 31; jours++) {
        expect(
          surLesNuits(jours).pireJournee!.kmEffort,
          greaterThanOrEqualTo(26.4),
          reason: 'a $jours jours',
        );
        expect(
          surLesNuits(jours).verdict,
          NiveauDeDifficulte.tresDifficile,
          reason: 'a $jours jours le GR20 reste tres difficile',
        );
      }
    });

    test('LES QUATRE ALLURES DE LA FICHE, REMESUREES SUR L EFFORT', () {
      // Ce sont les quatre allures que le selecteur propose, et les chiffres
      // sont ceux que la fiche affiche. LES QUATRE SONT TRES DIFFICILES — et ce
      // n'est plus parce que la bande du dessus a disparu, c'est parce que
      // l'effort de leur pire journee depasse 25 km-effort aux quatre.
      expect(gr20TrailConfig.availableDurations, <int>[7, 9, 12, 16]);
      expect(gr20TrailConfig.defaultDuration, 16);

      final sept = surLesNuits(7);
      expect(sept.journeesDeMarche, 7);
      expect(sept.pireJournee!.kmEffort, closeTo(55.3, 0.1));
      expect(sept.verdict, NiveauDeDifficulte.tresDifficile);

      final neuf = surLesNuits(9);
      expect(neuf.journeesDeMarche, 9);
      expect(neuf.pireJournee!.kmEffort, closeTo(43.1, 0.1));
      expect(neuf.verdict, NiveauDeDifficulte.tresDifficile);

      final douze = surLesNuits(12);
      expect(douze.journeesDeMarche, 12);
      expect(douze.pireJournee!.kmEffort, closeTo(35.1, 0.1));
      expect(douze.verdict, NiveauDeDifficulte.tresDifficile);

      final seize = surLesNuits(16);
      expect(seize.journeesDeMarche, 16);
      expect(seize.pireJournee!.kmEffort, closeTo(26.48, 0.01));
      expect(seize.pireJournee!.numero, 1);
      expect(seize.pireJournee!.deniveleM, 1455);
      expect(seize.verdict, NiveauDeDifficulte.tresDifficile);
    });

    test('A SEIZE JOURS, LA REPARTITION DIT CE QU UN MOT NE DIT PAS', () {
      // Le verdict est « tres difficile », mais UNE journee seulement l'est :
      // les quinze autres sont plus faciles. C'est ce que la jauge de
      // repartition montre et qu'un mot seul cache. Et l'accumulation ne joue
      // pas ici : le plancher est deja la bande du haut.
      final seize = surLesNuits(16);
      final r = seize.repartition;
      expect(r.values.reduce((a, b) => a + b), 16);
      expect(r[NiveauDeDifficulte.tresDifficile], 1);
      expect(r[NiveauDeDifficulte.difficile], 12);
      expect(r[NiveauDeDifficulte.moyen], 3);
      expect(r[NiveauDeDifficulte.facile], 0);
      expect(seize.journeesEnBandesHautes, 13);
      expect(seize.plusLongueSuiteEnBandesHautes, 8);
      expect(seize.verdictMonteParLAccumulation, isFalse);
    });

    test('A L ALLURE FEDERALE, LA PIRE JOURNEE CHANGE D IDENTITE', () {
      // SUR LES SEIZE ETAPES, LA PLUS DURE N'EST PLUS LA PREMIERE. Par le seul
      // denivele c'etait l'etape 1 (1 453 m) ; sur l'effort complet c'est
      // l'etape 6, Ciottulu di i Mori - Manganu, 25,02 km, 786 m de montee et
      // 1 191 m de descente. C'est le changement le plus visible du lot, et il
      // est ecrit ici pour qu'il ne passe pas inapercu.
      final seize = surLesEtapes(lireLesEtapesDuGr20(), 16);
      expect(seize.journeesDeMarche, 16);
      expect(seize.pireJournee!.numero, 6);
      expect(seize.pireJournee!.kmEffort, closeTo(36.45, 0.05));
      expect(seize.verdict, NiveauDeDifficulte.tresDifficile);
    });

    test('LES NUITS RELEVEES ALLEGENT LA PIRE JOURNEE, ET CA SE CHIFFRE', () {
      // A DOUZE JOURS, les seize etapes de la federation laissent une journee
      // plus dure que les trente et une nuits relevees. Le verdict ne change
      // pas — les deux sont tres difficiles —, mais l'ECART reste et il est
      // chiffre : annoncer la plus dure des deux serait annoncer une journee
      // que la preparation ne posera pas.
      final parLesEtapes = surLesEtapes(lireLesEtapesDuGr20(), 12);
      final parLesNuits = surLesNuits(12);
      expect(
        parLesEtapes.pireJournee!.kmEffort,
        greaterThan(parLesNuits.pireJournee!.kmEffort),
      );
      expect(parLesEtapes.verdict, NiveauDeDifficulte.tresDifficile);
      expect(parLesNuits.verdict, NiveauDeDifficulte.tresDifficile);
    });
  });

  group('852 — ce que Christophe annonce, face a la mesure', () {
    test('UNE ANNONCE SUR QUATRE CONCORDE, ET C EST ECRIT ICI', () {
      // ANNONCE DE CHRISTOPHE, 17/10 11:05, verbatim : « Et quand tu presente
      // tu mets 7 jours= experts, 9jours = tres difficile, 12 jours Difficile,
      // 16 jours = Difficile ».
      //
      // CE QUE LA MESURE DIT, sur les nuits relevees et sur l'effort complet :
      //   7 jours  -> tres difficile  : la bande « expert » n'existe plus
      //   9 jours  -> tres difficile  : CONCORDE
      //   12 jours -> tres difficile  : la mesure est PLUS DURE d'un cran
      //   16 jours -> tres difficile  : la mesure est PLUS DURE d'un cran
      //
      // L'ECART N'EST PAS UN REGLAGE A CORRIGER : le GR20 ne peut pas etre
      // « difficile », parce que sa premiere journee pese 26,5 km-effort et
      // qu'aucune nuit relevee ne permet de la couper. Ce cas EXISTE pour que
      // l'ecart reste visible, et pour qu'il rougisse le jour ou une nuit
      // nouvelle rendrait ce segment divisible.
      final annonce = <int, NiveauDeDifficulte>{
        9: NiveauDeDifficulte.tresDifficile,
        12: NiveauDeDifficulte.difficile,
        16: NiveauDeDifficulte.difficile,
      };
      final mesure = <int, NiveauDeDifficulte>{
        for (final jours in <int>[7, 9, 12, 16])
          jours: surLesNuits(jours).verdict!,
      };

      expect(mesure[9], annonce[9], reason: 'neuf jours concordent');
      for (final jours in <int>[12, 16]) {
        expect(
          mesure[jours]!.rang,
          greaterThan(annonce[jours]!.rang),
          reason: 'a $jours jours la mesure est plus dure que l annonce',
        );
      }
      // SEPT JOURS : son mot etait « expert », et il n'y a plus de bande de ce
      // nom. Ce qu'elle portait est dans « tres difficile », donc l'annonce et
      // la mesure se rejoignent — par le haut.
      expect(mesure[7], NiveauDeDifficulte.tresDifficile);
      // Et le sentier n'est JAMAIS « difficile » : le plancher est au-dessus.
      expect(
        mesure.values.any((n) => n == NiveauDeDifficulte.difficile),
        isFalse,
      );
    });
  });
}
