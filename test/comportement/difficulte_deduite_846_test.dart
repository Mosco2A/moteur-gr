// GARDE — TACHE 846 : LA DIFFICULTE SE DEDUIT, ET ELLE DIT DE QUOI.
//
// CE QUE CES CAS EMPECHENT. La facon la plus simple de donner une difficulte a
// un sentier est une etiquette dans sa configuration (`difficulte: 'hard'`).
// Une etiquette ne se verifie pas, se recopie d'un sentier a l'autre, et ne
// bouge pas quand le randonneur decide de marcher le meme chemin en sept jours
// au lieu de seize. Le depot a deja paye ce genre d'affirmation : seize
// longueurs d'etape venues d'un topo et remises a l'echelle, justes au total et
// fausses partout ailleurs, jusqu'a 62 % d'ecart sur une etape (tache 839).
//
// LES CHIFFRES DU GR20 CI-DESSOUS NE SONT PAS ECRITS A LA MAIN : ils sont
// RELUS dans `assets/data/gr20.json` et `assets/data/gr20/mesure_etapes.json`,
// eux-memes produits par `tool/gr20_dans_stepways.py` depuis la trace de
// 9 128 points. Un chiffre modifie quelque part fait rougir ce fichier.
//
// ET LES CHAPITRES SONT COUVERTS AVANT D'EXISTER. Le nord et le sud ne sont pas
// encore des produits sur la principale (tache 841, non fusionnee), mais leurs
// etapes, elles, existent dans la donnee. Les deux verdicts sont donc verifies
// ici : le jour ou les chapitres seront vendus, la garde sera deja en place.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
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

/// L'altitude maximale mesuree, sur tout le sentier ou sur une tranche
/// d'etapes — relue dans le fichier de mesure, jamais ecrite ici.
int altitudeMaxMesuree({int rangMin = 1, int rangMax = 16}) {
  final brut =
      jsonDecode(File('assets/data/gr20/mesure_etapes.json').readAsStringSync())
          as Map<String, dynamic>;
  return (brut['etapes'] as List<dynamic>)
      .cast<Map<String, dynamic>>()
      .where((e) {
        final rang = e['rang_trace'] as int;
        return rang >= rangMin && rang <= rangMax;
      })
      .map((e) => (e['altitude_max_m'] as num).round())
      .reduce((a, b) => a > b ? a : b);
}

/// La difficulte d'une liste d'etapes a une allure donnee, par le MEME chemin
/// que l'ecran : le decoupage du programme, puis la deduction.
DifficulteDuSentier deduire(
  List<StageModel> etapes,
  int jours, {
  int? altitudeMaxM,
}) {
  final journees = PlanningCalculator.distribute(etapes, jours)
      .where((jour) => !jour.isRestDay)
      .map((jour) => jour.totalElevationGainM)
      .toList(growable: false);
  return DifficulteDuSentier.calculer(
    jours: jours,
    denivelesParJournee: journees,
    altitudeMaxM: altitudeMaxM,
  )!;
}

void main() {
  group('846 — la regle : trois mesures, le pire des trois', () {
    test('le niveau retenu est LE PIRE, jamais une moyenne', () {
      // Deux journees tres faciles et une altitude d'expert : le verdict est
      // expert. Moyenner rendrait « modere », c'est-a-dire dirait qu'une
      // altitude basse rachete une journee dure — sur le terrain, elle ne
      // rachete rien.
      final d = deduire(
        <StageModel>[_etape(1, 100), _etape(2, 120)],
        2,
        altitudeMaxM: 2600,
      );
      expect(d.niveau, NiveauDeDifficulte.expert);
      expect(d.cleDuSocle, 'expert');
      expect(d.criteres.length, 3);
    });

    test('une mesure absente DISPARAIT du calcul et est NOMMEE', () {
      final d = deduire(<StageModel>[_etape(1, 300)], 1);
      expect(d.criteres.length, 2, reason: 'plus de critere d altitude');
      expect(d.mesuresManquantes, contains("l'altitude maximale de la trace"));
      expect(d.niveau, NiveauDeDifficulte.facile);
    });

    test('sans journee ni altitude, il n y a AUCUN niveau', () {
      final vide = DifficulteDuSentier.calculer(
        jours: 3,
        denivelesParJournee: const <int>[],
      )!;
      expect(vide.niveau, isNull);
      expect(vide.cleDuSocle, isNull);
      expect(vide.mesuresManquantes.length, 2);
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

    test('les seuils de journee sont CEUX du socle, pas des nouveaux', () {
      // Les memes que l'etiquetage d'etape de `tool/gr20_dans_stepways.py` :
      // easy jusqu a 400 m, hard a partir de 1 000, extreme a partir de 1 500.
      expect(SeuilsDeDifficulte.denivelFacileM, 400);
      expect(SeuilsDeDifficulte.denivelDifficileM, 1000);
      expect(SeuilsDeDifficulte.denivelExpertM, 1500);
      expect(SeuilsDeDifficulte.pourDenivele(400), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourDenivele(401), NiveauDeDifficulte.modere);
      expect(
        SeuilsDeDifficulte.pourDenivele(1000),
        NiveauDeDifficulte.difficile,
      );
      expect(SeuilsDeDifficulte.pourDenivele(1500), NiveauDeDifficulte.expert);
    });

    test('le premier seuil d altitude est celui de la faisabilite', () {
      // 1 500 m : le seuil publie du facteur d'altitude (#2-h, source #S8-e).
      // En dessous, l'altitude ne coute rien, et le dire autrement ici
      // contredirait l'ecran de faisabilite.
      expect(SeuilsDeDifficulte.altitudeFacileM, 1500);
      expect(SeuilsDeDifficulte.pourAltitude(1499), NiveauDeDifficulte.facile);
      expect(SeuilsDeDifficulte.pourAltitude(1500), NiveauDeDifficulte.modere);
      expect(
        SeuilsDeDifficulte.pourAltitude(2000),
        NiveauDeDifficulte.difficile,
      );
      expect(SeuilsDeDifficulte.pourAltitude(2500), NiveauDeDifficulte.expert);
    });

    test('la regle AFFICHEE est celle qui est APPLIQUEE', () {
      // Elle cite les seuils par interpolation des constantes : impossible de
      // changer un seuil sans changer le texte, ni l'inverse.
      const regle = SeuilsDeDifficulte.regleAffichee;
      expect(regle, contains('${SeuilsDeDifficulte.denivelDifficileM} m'));
      expect(regle, contains('${SeuilsDeDifficulte.denivelExpertM} m'));
      expect(regle, contains('${SeuilsDeDifficulte.altitudeFacileM} m'));
      expect(regle, contains('PIRE'));
    });

    test('chaque critere porte sa mesure, avec son unite', () {
      final d = deduire(
        <StageModel>[_etape(1, 1200), _etape(2, 600)],
        2,
        altitudeMaxM: 1800,
      );
      for (final critere in d.criteres) {
        expect(critere.nom, isNotEmpty);
        expect(critere.mesure, contains('m'));
      }
      expect(d.criteres.first.mesure, contains('900 m de montee par jour'));
      expect(
        d.criteres[1].mesure,
        contains('1200 m de montee en une seule journee'),
      );
      expect(d.criteres[2].mesure, contains('1800 m au point le plus haut'));
    });
  });

  group('846 — le GR20, sur ses chiffres mesures', () {
    test("l'altitude de la configuration EST celle de la mesure", () {
      expect(gr20TrailConfig.maxAltitudeM, altitudeMaxMesuree());
      expect(gr20TrailConfig.maxAltitudeM, 2578);
    });

    test('A L ALLURE FEDERALE (16 jours) : expert, et on sait pourquoi', () {
      final d = deduire(
        lireLesEtapesDuGr20(),
        16,
        altitudeMaxM: altitudeMaxMesuree(),
      );

      expect(d.journeesDeMarche, 16, reason: 'une etape par jour');
      expect(d.criteres[0].mesure, contains('728 m de montee par jour'));
      expect(d.criteres[0].niveau, NiveauDeDifficulte.modere);
      expect(d.criteres[1].mesure, contains('1453 m'));
      expect(d.criteres[1].niveau, NiveauDeDifficulte.difficile);
      expect(d.criteres[2].mesure, contains('2578 m'));
      expect(d.criteres[2].niveau, NiveauDeDifficulte.expert);
      // C'est l'ALTITUDE qui emporte le verdict : la moyenne est moderee et la
      // pire journee seulement difficile.
      expect(d.cleDuSocle, 'expert');
    });

    test('A 7 JOURS : la moyenne passe de moderee a expert', () {
      final d = deduire(
        lireLesEtapesDuGr20(),
        7,
        altitudeMaxM: altitudeMaxMesuree(),
      );
      expect(d.criteres[0].mesure, contains('1941 m de montee par jour'));
      expect(d.criteres[0].niveau, NiveauDeDifficulte.expert);
      expect(d.criteres[1].mesure, contains('2860 m'));
      expect(d.cleDuSocle, 'expert');
    });

    test('LE NORD, a ses neuf etapes : expert', () {
      final nord = lireLesEtapesDuGr20()
          .where((s) => s.stageNumber <= 9)
          .toList();
      final d = deduire(nord, 9, altitudeMaxM: altitudeMaxMesuree(rangMax: 9));
      expect(d.journeesDeMarche, 9);
      expect(d.criteres[0].mesure, contains('822 m de montee par jour'));
      expect(d.criteres[1].mesure, contains('1453 m'));
      expect(d.criteres[2].mesure, contains('2578 m'));
      expect(d.cleDuSocle, 'expert');
    });

    test('LE SUD, a ses sept etapes : difficile, et pas expert', () {
      final sud = lireLesEtapesDuGr20()
          .where((s) => s.stageNumber > 9)
          .toList();
      final d = deduire(sud, 7, altitudeMaxM: altitudeMaxMesuree(rangMin: 10));
      expect(d.journeesDeMarche, 7);
      expect(d.criteres[0].mesure, contains('606 m de montee par jour'));
      expect(d.criteres[0].niveau, NiveauDeDifficulte.modere);
      expect(d.criteres[1].mesure, contains('967 m'));
      expect(d.criteres[1].niveau, NiveauDeDifficulte.modere);
      expect(d.criteres[2].mesure, contains('2021 m'));
      expect(d.criteres[2].niveau, NiveauDeDifficulte.difficile);
      expect(d.cleDuSocle, 'hard');
    });

    test('LES DEUX MOITIES NE SE MARCHENT PAS PAREIL, ET LA FICHE LE DIT', () {
      // C'est la phrase de l'en-tete de `gr20_trail_config.dart` — « les deux
      // moities se marchent tres differemment, et c'est la que se lit la
      // difficulte » — devenue un ecart MESURE entre deux verdicts.
      final etapes = lireLesEtapesDuGr20();
      final nord = deduire(
        etapes.where((s) => s.stageNumber <= 9).toList(),
        9,
        altitudeMaxM: altitudeMaxMesuree(rangMax: 9),
      );
      final sud = deduire(
        etapes.where((s) => s.stageNumber > 9).toList(),
        7,
        altitudeMaxM: altitudeMaxMesuree(rangMin: 10),
      );
      expect(nord.niveau!.rang, greaterThan(sud.niveau!.rang));
    });
  });

  group('846 — le decoupage rend MOINS de journees qu on en demande', () {
    test('sept jours demandes sur le GR20 rendent SIX journees de marche', () {
      // CE CAS NE CELEBRE PAS UN DEFAUT, IL L'EMPECHE DE SE PROPAGER.
      //
      // `PlanningCalculator._distributeGreedy` ne coupe que lorsque le score
      // accumule franchit sa cible : le dernier groupe avale le reste et le
      // nombre de journees produites peut etre INFERIEUR au nombre demande.
      // Mesure sur le GR20 : 7 demandes -> 6 journees, 10 -> 7, 12 -> 8.
      //
      // Le defaut est dans le decoupage et il depasse cette tache : il touche
      // aussi l'ecran Programme, qui emploie le meme calculateur. Ce qui est
      // garanti ICI est plus modeste et c'etait le point : la fiche annonce le
      // nombre de journees REELLEMENT produites, jamais le nombre demande. Le
      // jour ou le decoupage sera repare, ce cas rougira et dira ou regarder.
      final etapes = lireLesEtapesDuGr20();
      expect(deduire(etapes, 7).journeesDeMarche, 6);
      expect(deduire(etapes, 10).journeesDeMarche, 7);
      expect(deduire(etapes, 12).journeesDeMarche, 8);
      expect(deduire(etapes, 16).journeesDeMarche, 16);
    });

    test('la mesure affichee nomme les journees REELLES', () {
      final d = deduire(lireLesEtapesDuGr20(), 7);
      expect(d.joursChoisis, 7);
      expect(d.journeesDeMarche, 6);
      expect(d.criteres.first.mesure, contains('6 journees de marche'));
      expect(
        d.criteres.first.mesure,
        isNot(contains('7 journees')),
        reason: 'une moyenne sur six journees ne s annonce pas sur sept',
      );
    });
  });
}

/// Une etape de decor, reduite a ce qui compte ici : son denivele positif.
StageModel _etape(int numero, int denivelePositifM) => StageModel(
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
