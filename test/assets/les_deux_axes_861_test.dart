// GARDE — TACHE 861 : LES DEUX AXES DU GR20, MESURES DEUX FOIS, EN DART ET EN
// PYTHON.
//
// `tool/les_deux_axes_861.py` mesure l'effort et la raideur des seize etapes,
// le decoupage a l'effort des trois produits dans les deux sens et les
// lectures de chaque plan ; il ecrit `assets/data/gr20/axes_861.json`. Ce
// fichier-ci recalcule tout en DART, par le socle du produit, et exige les
// memes nombres. Un calcul qui s'auto-atteste ne prouve rien ; deux qui
// tombent d'accord, si.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/gpx_depuis_les_assets.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/note_d_effort.dart';
import 'package:moteur_gr/domain/note_de_raideur.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';

Map<String, dynamic> lireJson(String chemin) =>
    json.decode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

ProfilDuTerrain profilDuGr20() {
  final points = GpxDepuisLesAssets.parseFromString(
    File('assets/data/gr20/track.gpx').readAsStringSync(),
  );
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

double nombre(Object? valeur) => (valeur! as num).toDouble();

void main() {
  final mesure = lireJson('assets/data/gr20/axes_861.json');
  final etapesPubliees = lireJson('assets/data/gr20/mesure_etapes.json');

  group('861 — les deux jauges du fichier sont les deux jauges du code', () {
    test('L AXE EFFORT : LES CINQ PALIERS, LEUR DATE ET LEUR SOURCE', () {
      final axe = mesure['axe_effort'] as Map<String, dynamic>;
      expect(axe['figee_le'], NoteDEffort.dateDuCalage);
      expect(axe['source_des_seuils'], NoteDEffort.sourceDesSeuils);
      expect(axe['etape_du_vingt'], NoteDEffort.etapeDuVingt);
      expect(
        nombre(axe['indice_du_dernier_seuil_publie']),
        NoteDEffort.indiceDuDernierSeuilPublie,
      );
      expect(nombre(axe['indice_du_vingt']), NoteDEffort.indiceDuVingt);
      final paliers = axe['paliers'] as List<dynamic>;
      expect(paliers, hasLength(NoteDEffort.paliers.length));
      for (var i = 0; i < paliers.length; i++) {
        final couple = paliers[i] as List<dynamic>;
        expect(nombre(couple[0]), closeTo(NoteDEffort.paliers[i].$1, 1e-9));
        expect(nombre(couple[1]), closeTo(NoteDEffort.paliers[i].$2, 1e-9));
      }
    });

    test('L AXE EFFORT : LE CONTROLE CROISE ALLTRAILS EST DANS LE FICHIER', () {
      final croise =
          (mesure['axe_effort']
                  as Map<String, dynamic>)['controle_croise_alltrails']
              as Map<String, dynamic>;
      expect(
        nombre(croise['frontiere_alltrails_11km_450m']),
        NoteDEffort.indiceDeLaFrontiereAllTrails,
      );
      expect(
        nombre(croise['frontiere_francaise_12km_450m']),
        NoteDEffort.indiceDe12km450m,
      );
      expect(nombre(croise['ecart_pct']), lessThan(6));
    });

    test('L AXE RAIDEUR : LES QUATRE BANDES IMBA ET LEUR DIVISEUR', () {
      final axe = mesure['axe_raideur'] as Map<String, dynamic>;
      expect(axe['figee_le'], NoteDeRaideur.dateDuCalage);
      expect(
        nombre(axe['metres_par_km_par_point_de_note']),
        NoteDeRaideur.metresParKmParPointDeNote,
      );
      final bandes = axe['bandes_imba_m_par_km'] as Map<String, dynamic>;
      expect(nombre(bandes['vert']), NoteDeRaideur.vertM);
      expect(nombre(bandes['bleu']), NoteDeRaideur.bleuM);
      expect(nombre(bandes['noir']), NoteDeRaideur.noirM);
      expect(nombre(bandes['double_noir']), NoteDeRaideur.doubleNoirM);
      // ET LA RESERVE EST DANS LE FICHIER, PAS SEULEMENT DANS LE CODE : ces
      // seuils viennent du VTT, et le dire fait partie de la mesure.
      expect(axe['reserve'], contains('VTT'));
      expect(axe['source_des_bandes'], contains('IMBA'));
    });

    test('LES QUATRE BANDES REPRODUITES TOMBENT SUR 5, 10, 15 ET 20', () {
      final reproduites =
          mesure['bandes_imba_reproduites'] as Map<String, dynamic>;
      expect(nombre(reproduites['vert']), 5.0);
      expect(nombre(reproduites['bleu']), 10.0);
      expect(nombre(reproduites['noir']), 15.0);
      expect(nombre(reproduites['double_noir']), 20.0);
    });
  });

  group('861 — les seize etapes tombent sur les memes deux notes', () {
    test('CHAQUE ETAPE : EFFORT, RAIDEUR ET CHIFFRE BRUT CONCORDENT', () {
      final profil = profilDuGr20();
      final etapes = mesure['etapes_officielles'] as List<dynamic>;
      final publiees = etapesPubliees['etapes'] as List<dynamic>;
      expect(etapes, hasLength(publiees.length));
      for (var i = 0; i < etapes.length; i++) {
        final attendu = etapes[i] as Map<String, dynamic>;
        final publiee = publiees[i] as Map<String, dynamic>;
        final terrain = IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: nombre(publiee['pk_depart_km']) * 1000.0,
            pkFinM: nombre(publiee['pk_arrivee_km']) * 1000.0,
          ),
        );
        final rang = attendu['rang'];
        expect(
          terrain.indice,
          closeTo(nombre(attendu['indice']), 0.01),
          reason: 'indice de l etape $rang',
        );
        expect(
          NoteDEffort.pourIndice(terrain.indice),
          closeTo(nombre(attendu['effort']), 0.01),
          reason: 'effort de l etape $rang',
        );
        expect(
          NoteDeRaideur.pourJournee(
            deniveleM: terrain.deniveleM,
            km: terrain.kmDeCarte,
          ),
          closeTo(nombre(attendu['raideur']), 0.01),
          reason: 'raideur de l etape $rang',
        );
        expect(
          NoteDeRaideur.metresParKm(
            deniveleM: terrain.deniveleM,
            km: terrain.kmDeCarte,
          ),
          closeTo(nombre(attendu['metres_par_km']), 0.1),
          reason: 'metres par km de l etape $rang',
        );
        expect(
          terrain.kmDeCarte,
          closeTo(nombre(attendu['km_de_carte']), 0.01),
          reason: 'km de carte de l etape $rang',
        );
      }
    });

    test('CALENZANA EST COURTE ET BRUTALE, L ETAPE 6 EST LONGUE ET '
        'ROULANTE', () {
      // LES DEUX AXES DISENT CE QU UN SEUL NE POUVAIT PAS, et c'est lisible
      // sur deux etapes officielles du meme sentier : l'etape 1 et l'etape 6
      // sont proches en effort et opposees en raideur.
      final etapes = mesure['etapes_officielles'] as List<dynamic>;
      final etape1 = etapes.first as Map<String, dynamic>;
      final etape6 = etapes[5] as Map<String, dynamic>;
      expect(nombre(etape1['effort']), closeTo(16.06, 0.01));
      expect(nombre(etape1['raideur']), closeTo(12.81, 0.01));
      expect(nombre(etape6['effort']), closeTo(13.32, 0.01));
      expect(nombre(etape6['raideur']), closeTo(3.07, 0.01));
      expect(
        nombre(etape1['raideur']) - nombre(etape6['raideur']),
        greaterThan(9),
      );
    });

    test('LE MUR DE 300 M EN 1 KM EST DANS LE FICHIER, bas en effort et au '
        'plafond en raideur', () {
      final mur = mesure['mur_de_300m_en_1km'] as Map<String, dynamic>;
      expect(nombre(mur['effort']), closeTo(3.15, 0.01));
      expect(nombre(mur['raideur']), 20.0);
      expect(mur['raideur_ecretee'], isTrue);
      expect(mur['effort_ecrete'], isFalse);
    });
  });

  group('861 — les plans et leurs lectures', () {
    test('CHAQUE PLAN PORTE SES DEUX LECTURES SUR LES DEUX AXES', () {
      final plans = mesure['plans'] as List<dynamic>;
      expect(plans, isNotEmpty);
      for (final brut in plans) {
        final plan = brut as Map<String, dynamic>;
        final lectures = plan['lectures'] as Map<String, dynamic>;
        final journees = plan['journees'] as List<dynamic>;
        final quoi =
            '${plan['produit']} ${plan['sens']} '
            '${plan['jours_demandes']}';
        expect(
          lectures['nombre_de_jours'],
          journees.length,
          reason: 'le compte de journees de $quoi',
        );
        // LA PIRE JOURNEE EST BIEN LE MAXIMUM, SUR CHAQUE AXE SEPAREMENT, et
        // ce n'est pas forcement la meme journee des deux cotes.
        var pireEffort = 0.0;
        var pireRaideur = 0.0;
        for (final j in journees) {
          final journee = j as Map<String, dynamic>;
          final effort = nombre(journee['effort']);
          final raideur = nombre(journee['raideur']);
          if (effort > pireEffort) pireEffort = effort;
          if (raideur > pireRaideur) pireRaideur = raideur;
        }
        expect(
          nombre(lectures['pire_journee']),
          closeTo(pireEffort, 0.01),
          reason: 'pire journee en effort de $quoi',
        );
        expect(
          nombre(lectures['pire_journee_en_raideur']),
          closeTo(pireRaideur, 0.01),
          reason: 'pire journee en raideur de $quoi',
        );
      }
    });

    test('AUCUN PLAN NE PORTE DE NOTE DE SENTIER — on ne somme jamais', () {
      // LA REGLE DE LA 860 TIENT AVEC DEUX AXES : un plan porte des lectures
      // prises sur ses journees, jamais un total. Deux axes doublent le
      // nombre de totaux qu'on pourrait fabriquer, donc la garde compte
      // double.
      final plans = mesure['plans'] as List<dynamic>;
      for (final brut in plans) {
        final plan = brut as Map<String, dynamic>;
        final lectures = plan['lectures'] as Map<String, dynamic>;
        for (final interdit in <String>[
          'note',
          'note_du_sentier',
          'total',
          'somme',
          'effort_total',
          'raideur_totale',
        ]) {
          expect(
            lectures.containsKey(interdit),
            isFalse,
            reason: '${plan['produit']} porte un $interdit',
          );
          expect(plan.containsKey(interdit), isFalse);
        }
      }
    });

    test('LE GR20 A SEPT JOURS : LES SEPT EFFORTS ET LES SEPT RAIDEURS', () {
      final plan =
          (mesure['plans'] as List<dynamic>).firstWhere(
                (p) =>
                    (p as Map<String, dynamic>)['produit'] == 'gr20' &&
                    p['sens'] == 'trace' &&
                    p['jours_demandes'] == 7,
              )
              as Map<String, dynamic>;
      final journees = plan['journees'] as List<dynamic>;
      expect(journees, hasLength(7));
      const efforts = <double>[18.13, 17.78, 17.00, 17.92, 16.48, 16.51, 17.77];
      const raideurs = <double>[11.19, 14.53, 4.54, 7.46, 4.36, 5.67, 3.85];
      for (var i = 0; i < 7; i++) {
        final journee = journees[i] as Map<String, dynamic>;
        expect(
          nombre(journee['effort']),
          closeTo(efforts[i], 0.01),
          reason: 'effort du jour ${i + 1}',
        );
        expect(
          nombre(journee['raideur']),
          closeTo(raideurs[i], 0.01),
          reason: 'raideur du jour ${i + 1}',
        );
      }
    });
  });
}
