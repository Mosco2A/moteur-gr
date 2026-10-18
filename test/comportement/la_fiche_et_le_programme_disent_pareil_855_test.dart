// GARDE — TACHE 855 : LA FICHE DE VENTE ET LE PROGRAMME DU CLIENT DOIVENT
// ANNONCER LE MEME CHIFFRE.
//
// LE DEFAUT, ET IL ETAIT LIVRE AUX CLIENTS. Deux calculs independants posaient
// les journees du MEME sentier a la MEME allure, et ils ne tombaient pas
// d'accord :
//
//   - la FICHE (`difficulte_calculee.dart`, l.141-164 avant ce lot) posait les
//     journees sur les TRENTE ET UNE NUITS relevees du GR20 (tache 838), donc
//     EN COUPANT a l'interieur des etapes ;
//   - le PROGRAMME (`PlanningCalculator.distribute`, l.92) ne coupait JAMAIS :
//     en dessous du nombre d'etapes il les groupait, au-dela tout jour de plus
//     devenait du REPOS.
//
// A SEIZE JOURS LA FICHE ANNONCAIT UNE PIRE JOURNEE DE 26,48 KM-EFFORT QUAND LE
// PROGRAMME EN PRODUISAIT UNE DE 36,45. Neuf km-effort d'ecart, DU COTE QUI
// RASSURE A TORT, sur un sentier de haute montagne : le randonneur lisait,
// AVANT de payer, une journee plus legere que celle qu'il allait marcher. Le
// « mode facile » etait ANNONCE et PAS IMPLEMENTE.
//
// CE QUE CE FICHIER GARDE, ET CE QU'IL NE PEUT PAS GARDER SEUL. La divergence
// n'est plus surveillee, elle est devenue IMPOSSIBLE A ECRIRE :
// [JourneesDuSentier] pose les journees UNE fois et les deux ecrans n'en sont
// que deux PROJECTIONS. Ce test garde donc les deux choses qu'une structure ne
// garantit pas toute seule :
//
//   1. que les deux projections rendent bien les MEMES chiffres (une
//      projection peut perdre la mesure en route — et c'est exactement ce que
//      ferait un `PlannedDay` qui cesserait de preferer sa mesure propre) ;
//   2. que le defaut etait REEL : l'ancien chemin est rejoue et doit, lui,
//      donner un chiffre DIFFERENT. Un test qui ne verifie que l'etat actuel
//      ne dit pas s'il a repare quoi que ce soit.
//
// LE MODELE QUI AUTORISE LA COUPE, Christophe 18/10 11:03, verbatim : « les
// etapes du GR restent les etapes du GR. 16 c'et 16, si le gars fait la
// premiere en 2 fois et bien c'est toujours 16 etape en 17 jours ».
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';
import 'package:moteur_gr/features/planning/domain/journees_du_sentier.dart';
import 'package:moteur_gr/features/planning/domain/planning_calculator.dart';

/// Les seize etapes REELLES du GR20, telles que l'application les lit.
List<StageModel> etapesDuGr20() {
  final brut =
      jsonDecode(File('assets/data/gr20/stages.json').readAsStringSync())
          as List<dynamic>;
  final etapes =
      brut
          .cast<Map<String, dynamic>>()
          .map(
            (e) => StageModel(
              trailId: e['trailId'] as String,
              stageNumber: (e['stageNumber'] as num).toInt(),
              name: e['nameFr'] as String,
              distanceKm: (e['distanceKm'] as num).toDouble(),
              elevationGainM: (e['elevationGainM'] as num).toInt(),
              elevationLossM: (e['elevationLossM'] as num).toInt(),
              startLat: (e['startLat'] as num).toDouble(),
              startLng: (e['startLng'] as num).toDouble(),
              endLat: (e['endLat'] as num).toDouble(),
              endLng: (e['endLng'] as num).toDouble(),
            ),
          )
          .toList()
        ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
  return etapes;
}

/// Les trente et une nuits relevees du GR20.
DecoupageDeNuits nuitsDuGr20() => DecoupageDeNuits.fromJson(
  jsonDecode(File('assets/data/gr20/nuits_possibles.json').readAsStringSync())
      as Map<String, dynamic>,
);

void main() {
  final etapes = etapesDuGr20();
  final nuits = nuitsDuGr20();

  test('le decor est bien le GR20 reel', () {
    expect(etapes.length, 16, reason: 'seize etapes, pour toujours');
    expect(nuits.segments.length, 31);
    expect(nuits.nuits.where((n) => n.estFinDEtape).length, 16);
    expect(nuits.coupuresNouvelles.length, 15);
  });

  group('TACHE 855 — les deux projections rendent le MEME chiffre', () {
    test('a toutes les allures, dans les deux sens', () {
      var cas = 0;
      for (final aLEnvers in const [false, true]) {
        for (var jours = 1; jours <= 31; jours++) {
          final posees = JourneesDuSentier.poser(
            etapes: etapes,
            nuitsDansLeSensDeLaTrace: nuits,
            aLEnvers: aLEnvers,
            jours: jours,
          );

          final pourLaFiche = JourneesDuSentier.mesurees(posees);
          final pourLeProgramme = JourneesDuSentier.programme(posees);

          expect(
            pourLeProgramme.length,
            pourLaFiche.length,
            reason: '$jours jours, aLEnvers=$aLEnvers : pas le meme nombre',
          );

          for (var i = 0; i < pourLaFiche.length; i++) {
            final fiche = pourLaFiche[i];
            final programme = pourLeProgramme[i];

            // LES TROIS MESURES, UNE A UNE. C'est ici qu'une projection qui
            // perd la mesure propre se fait prendre : un `PlannedDay` qui
            // cesserait de preferer `mesure` retomberait sur la somme de ses
            // etapes ENTIERES et annoncerait une journee plus dure qu'elle
            // n'est — ou plus facile, selon le bout.
            expect(
              programme.totalDistanceKm,
              closeTo(fiche.km, 1e-9),
              reason:
                  'journee ${i + 1} sur $jours (aLEnvers=$aLEnvers) : la '
                  'distance du programme ne vaut pas celle de la fiche',
            );
            expect(
              programme.totalElevationGainM,
              fiche.deniveleM,
              reason: 'journee ${i + 1} sur $jours : montee differente',
            );
            expect(
              programme.totalElevationLossM,
              fiche.descenteM,
              reason: 'journee ${i + 1} sur $jours : descente differente',
            );
            cas++;
          }
        }
      }
      expect(cas, greaterThan(400), reason: 'le balayage doit etre large');
    });

    test('la PIRE JOURNEE est la meme de part et d\'autre', () {
      for (final aLEnvers in const [false, true]) {
        for (var jours = 1; jours <= 31; jours++) {
          final posees = JourneesDuSentier.poser(
            etapes: etapes,
            nuitsDansLeSensDeLaTrace: nuits,
            aLEnvers: aLEnvers,
            jours: jours,
          );

          // CE QUE LA FICHE ANNONCE : la pire journee, en km-effort.
          final difficulte = DifficulteDuSentier.calculer(
            jours: jours,
            journees: JourneesDuSentier.mesurees(posees),
          );
          final annonce = difficulte?.pireJournee?.kmEffort;

          // CE QUE LE PROGRAMME PRODUIT : la pire de ses journees de marche,
          // mesuree par la MEME echelle.
          final programme = JourneesDuSentier.programme(posees);
          final produit = programme
              .map(
                (jour) => JourneeClassee(
                  numero: jour.dayNumber,
                  km: jour.totalDistanceKm,
                  deniveleM: jour.totalElevationGainM,
                  descenteM: jour.totalElevationLossM,
                ).kmEffort,
              )
              .fold<double?>(
                null,
                (pire, effort) => pire == null || effort > pire ? effort : pire,
              );

          expect(
            produit,
            annonce == null ? isNull : closeTo(annonce, 1e-9),
            reason:
                'LA FICHE ET LE PROGRAMME DIVERGENT a $jours jours '
                '(aLEnvers=$aLEnvers) : la fiche annonce $annonce km-effort, '
                'le programme produit $produit. C\'est le defaut de la tache '
                '855 qui revient.',
          );
        }
      }
    });
  });

  group('TACHE 855 — le defaut etait REEL, et il est ferme', () {
    test('a seize jours, le programme coupe desormais comme la fiche', () {
      const jours = 16;

      final posees = JourneesDuSentier.poser(
        etapes: etapes,
        nuitsDansLeSensDeLaTrace: nuits,
        aLEnvers: false,
        jours: jours,
      );
      final maintenant = JourneesDuSentier.programme(posees)
          .map(
            (jour) => JourneeClassee(
              numero: jour.dayNumber,
              km: jour.totalDistanceKm,
              deniveleM: jour.totalElevationGainM,
              descenteM: jour.totalElevationLossM,
            ).kmEffort,
          )
          .reduce((a, b) => a > b ? a : b);

      // L'ANCIEN CHEMIN, REJOUE : le regroupement d'etapes ENTIERES, qui ne
      // coupait jamais. C'est ce que le programme produisait avant ce lot.
      final avant = PlanningCalculator.distribute(etapes, jours)
          .where((jour) => !jour.isRestDay)
          .map(
            (jour) => JourneeClassee(
              numero: jour.dayNumber,
              km: jour.totalDistanceKm,
              deniveleM: jour.totalElevationGainM,
              descenteM: jour.totalElevationLossM,
            ).kmEffort,
          )
          .reduce((a, b) => a > b ? a : b);

      // LA PIRE ETAPE DU GR20 EST L'ETAPE 6 : 25,02 km, D+786, D-1191, soit
      // 36,45 km-effort. Sans coupe, c'est elle le plancher.
      expect(
        avant,
        closeTo(36.45, 0.1),
        reason:
            'l\'ancien chemin doit toujours rendre 36,45 : c\'est le chiffre '
            'mesure par la tache 854',
      );

      // ET AVEC LA COUPE, LA PIRE JOURNEE TOMBE. C'est tout le benefice pour
      // le marcheur, et c'est ce que la fiche promettait deja.
      expect(
        maintenant,
        lessThan(avant),
        reason:
            'couper doit ALLEGER la pire journee, sinon la coupe ne sert a '
            'rien',
      );
      expect(
        avant - maintenant,
        greaterThan(5),
        reason:
            'l\'ecart mesure par la tache 854 est de pres de dix km-effort : '
            's\'il devient petit, le decoupage ne se fait plus',
      );
    });

    test('couper NE FABRIQUE AUCUNE DIX-SEPTIEME ETAPE', () {
      // LA CONDITION DE CHRISTOPHE, ET ELLE EST ABSOLUE : l'etape est l'unite
      // de VENTE, seize pour toujours, 16 EUR. Une journee peut couvrir un
      // morceau d'etape ; le COMPTE D'ETAPES ne bouge pas.
      for (final aLEnvers in const [false, true]) {
        for (var jours = 16; jours <= 31; jours++) {
          final programme = JourneesDuSentier.programme(
            JourneesDuSentier.poser(
              etapes: etapes,
              nuitsDansLeSensDeLaTrace: nuits,
              aLEnvers: aLEnvers,
              jours: jours,
            ),
          );

          final numeros = <int>{
            for (final jour in programme)
              for (final etape in jour.stages) etape.stageNumber,
          };

          expect(
            numeros.length,
            16,
            reason:
                'a $jours jours (aLEnvers=$aLEnvers) le programme porte '
                '${numeros.length} etapes distinctes au lieu de seize — '
                'couper une journee a fabrique une etape, ce qui change le '
                'prix du produit',
          );
        }
      }
    });

    test('toute journee de marche touche au moins une etape', () {
      // UNE JOURNEE SANS ETAPE SERAIT INVENDABLE ET INAFFICHABLE : l'ecran
      // n'aurait rien a nommer. C'est le defaut qu'une attribution ratee
      // produirait en silence.
      for (final aLEnvers in const [false, true]) {
        for (var jours = 1; jours <= 31; jours++) {
          final programme = JourneesDuSentier.programme(
            JourneesDuSentier.poser(
              etapes: etapes,
              nuitsDansLeSensDeLaTrace: nuits,
              aLEnvers: aLEnvers,
              jours: jours,
            ),
          );
          for (final jour in programme) {
            expect(
              jour.stages,
              isNotEmpty,
              reason:
                  'journee ${jour.dayNumber} sur $jours (aLEnvers=$aLEnvers) '
                  'ne touche aucune etape',
            );
          }
        }
      }
    });
  });
}
