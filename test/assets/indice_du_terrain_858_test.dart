// GARDE — TACHE 858 : LE GR20 PESE DEUX FOIS, EN DART ET EN PYTHON, ET LES
// DEUX MESURES DOIVENT TOMBER D'ACCORD.
//
// DOCTRINE DU DEPOT, ET ELLE A DEJA SERVI. `tool/indice_du_terrain_858.py`
// mesure l'indice de terrain du GR20 sur sa trace et ecrit
// `assets/data/gr20/indice_858.json`. Ce fichier-ci le recalcule en DART, par
// le socle du produit (`ProfilDuTerrain`, `FacteurDePenteMinetti`,
// `IndiceDuTerrain`), et exige les memes nombres etape par etape. Un calcul qui
// s'auto-atteste ne prouve rien ; deux qui tombent d'accord, si. C'est le
// precedent de la tache 852 (`effort_des_journees_852.py` contre
// `effort_et_troncon_852_test.dart`), applique a un calcul qui, lui, se tient.
//
// CE QUE CE FICHIER VERIFIE EN PLUS, ET QUI COMPTE AUTANT. Que le profil sur
// lequel l'indice s'integre est bien CELUI QUI PRODUIT LE DENIVELE AFFICHE :
// 11 602 m de montee et 183,58 km, les chiffres que `mesure_etapes.json` publie
// et que l'ecran annonce. Un indice calcule sur un autre profil que le D+
// affiche ferait vivre deux sentiers differents dans le meme ecran.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/facteur_de_pente_minetti.dart';
import 'package:moteur_gr/domain/indice_du_terrain.dart';
import 'package:moteur_gr/domain/profil_du_terrain.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

/// Le profil du GR20, construit comme l'application le construit.
ProfilDuTerrain profilDuGr20() {
  final points = GpxParser.parse(
    File('assets/data/gr20/track.gpx').readAsStringSync(),
  ).allTrackPoints;
  return ProfilDuTerrain.depuisLaTrace(
    distancesM: points.map((p) => p.distanceFromStart).toList(growable: false),
    altitudesM: points.map((p) => p.altitude).toList(growable: false),
  );
}

Map<String, dynamic> lireJson(String chemin) =>
    json.decode(File(chemin).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final mesure = lireJson('assets/data/gr20/indice_858.json');
  final etapesPubliees = lireJson('assets/data/gr20/mesure_etapes.json');
  final profil = profilDuGr20();

  group('858 — le profil est celui du denivele AFFICHE', () {
    test('LA TRACE RENDUE EST CELLE DE LA MESURE PUBLIEE : 9 128 points, '
        '183,58 km', () {
      final attendu = mesure['profil'] as Map<String, dynamic>;
      expect(attendu['points_de_trace'], etapesPubliees['points']);
      expect(profil.segments, hasLength(attendu['morceaux']));
      expect(
        (attendu['longueur_km'] as num).toDouble(),
        closeTo((etapesPubliees['longueur_totale_km'] as num).toDouble(), 0.01),
        reason: 'la trace mesuree est bien celle que le sentier publie',
      );
      // LA QUEUE PLUS COURTE QUE LE PAS N'EST PAS PROFILEE, et c'est la
      // convention de la mesure publiee : 215 m sur 183,6 km, soit 0,12 %.
      expect(
        profil.longueurM / 1000.0,
        closeTo((attendu['longueur_profilee_km'] as num).toDouble(), 0.01),
      );
      expect(
        (attendu['queue_non_profilee_m'] as num).toDouble(),
        lessThan(300.0),
      );
      expect(ProfilDuTerrain.fenetreDeLissage, attendu['fenetre_de_lissage']);
      expect(
        ProfilDuTerrain.pasDEchantillonnage,
        attendu['pas_d_echantillonnage'],
      );
    });

    test('LE DENIVELE DU PROFIL EST CELUI QUE L ECRAN ANNONCE : 11 602 m', () {
      final tout = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: 0, pkFinM: profil.longueurM),
      );
      expect(
        tout.deniveleM,
        closeTo((etapesPubliees['dplus_total_m'] as num).toDouble(), 2.0),
        reason:
            'l indice doit s integrer sur LE profil qui produit le D+ '
            'affiche, sinon l ecran decrit deux sentiers',
      );
      expect(
        tout.descenteM,
        closeTo((etapesPubliees['dmoins_total_m'] as num).toDouble(), 2.0),
      );
      expect(
        tout.kmDeTrajet,
        greaterThan(profil.longueurM / 1000.0),
        reason: 'on marche la pente, pas sa projection sur la carte',
      );
    });

    test('ETAPE PAR ETAPE, L ECART AU D+ PUBLIE EST CELUI QUE LE FICHIER '
        'ANNONCE — ET IL A UNE RAISON', () {
      // CE QUE CE TEST DIT, PARCE QUE LE TAIRE SERAIT PIRE.
      // `mesure_etapes.json` RE-CALE son echantillonnage au depart de CHAQUE
      // etape ; l'indice, lui,
      // echantillonne le sentier UNE fois et decoupe dedans — c'est exactement
      // ce qui rend son socle additif a la machine pres. Les deux D+ totaux
      // concordent au metre ; une etape peut s'ecarter de quelques metres, et
      // la pire est l'etape 6 (767 contre 786, 2,4 %).
      final ecart =
          (mesure['profil'] as Map<String, dynamic>)['ecart_au_denivele_publie']
              as Map<String, dynamic>;
      final pireAnnonce = (ecart['pire_etape_m'] as num).toDouble();
      var pireMesure = 0.0;
      for (final publiee in etapesPubliees['etapes'] as List<dynamic>) {
        final e = publiee as Map<String, dynamic>;
        final indice = IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: (e['pk_depart_km'] as num).toDouble() * 1000.0,
            pkFinM: (e['pk_arrivee_km'] as num).toDouble() * 1000.0,
          ),
        );
        final d = (indice.deniveleM - (e['dplus_m'] as num).toDouble()).abs();
        if (d > pireMesure) pireMesure = d;
      }
      expect(
        pireMesure,
        lessThanOrEqualTo(pireAnnonce + 1.0),
        reason:
            'l ecart au D+ publie ne doit pas croitre en silence : le fichier '
            'annonce $pireAnnonce m au pire',
      );
      expect(
        pireAnnonce,
        lessThan(25.0),
        reason: 'au-dela, ce ne serait plus un ecart de phase',
      );
      expect(
        (ecart['total_m'] as num).toDouble().abs(),
        lessThan(1.0),
        reason: 'sur le TOTAL, les deux mesures doivent coller au metre',
      );
    });
  });

  group('858 — la table de pente de Dart est celle de Python', () {
    test('LES DIX-NEUF PENTES DU FICHIER SONT RENDUES AU DIX-MILLIEME', () {
      final table = mesure['points_par_km_de_trajet'] as Map<String, dynamic>;
      expect(table, hasLength(19));
      table.forEach((pourcent, valeur) {
        final pente = int.parse(pourcent) / 100.0;
        expect(
          FacteurDePenteMinetti.pointsParKmDeTrajet(pente),
          closeTo((valeur as num).toDouble(), 0.0002),
          reason: 'pente $pourcent %',
        );
      });
    });

    test('LA LOI DU FICHIER EST LA LOI DU CODE', () {
      final loi = mesure['loi'] as Map<String, dynamic>;
      const retenue = LoiDeLIndice.retenue;
      expect(retenue.beta, (loi['beta'] as num).toDouble());
      expect(
        retenue.deniveleDeReferenceM,
        (loi['denivele_de_reference_m'] as num).toDouble(),
      );
      expect(
        retenue.repitQuiCoupeUneMonteeMinutes,
        (loi['repit_qui_coupe_une_montee_minutes'] as num).toDouble(),
      );
      expect(
        retenue.allureSurTerrainReposantKmH,
        (loi['allure_sur_terrain_reposant_kmh'] as num).toDouble(),
      );
      expect(
        retenue.secondesParMetreDeDescente,
        (loi['secondes_par_metre_de_descente'] as num).toDouble(),
      );
      expect(
        FacteurDePenteMinetti.penteOuLaDescenteCouteLePlat,
        closeTo(
          (loi['pente_ou_la_descente_coute_le_plat'] as num).toDouble(),
          0.0005,
        ),
      );
      expect(
        FacteurDePenteMinetti.pentesMesurees,
        (loi['pentes_mesurees'] as List<dynamic>)
            .map((e) => (e as num).toDouble())
            .toList(),
      );
      for (final interpolee
          in loi['pentes_interpolees_citees_par_le_mandat'] as List<dynamic>) {
        expect(
          FacteurDePenteMinetti.mesuree((interpolee as num).toDouble()),
          isFalse,
        );
      }
    });
  });

  group('858 — les seize etapes du GR20, Dart contre Python', () {
    test('CHAQUE ETAPE REND LE MEME INDICE, LE MEME SOCLE ET LES MEMES '
        'MONTEES', () {
      for (final attendue in mesure['etapes_sens_trace'] as List<dynamic>) {
        final e = attendue as Map<String, dynamic>;
        final calculee = IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: (e['pk_depart_km'] as num).toDouble() * 1000.0,
            pkFinM: (e['pk_arrivee_km'] as num).toDouble() * 1000.0,
          ),
        );
        final ou = 'etape ${e['rang']} ${e['depart']} -> ${e['arrivee']}';
        expect(
          calculee.socleMesure,
          closeTo((e['socle_mesure'] as num).toDouble(), 0.01),
          reason: '$ou : socle mesure',
        );
        expect(
          calculee.majorationDeContinuite,
          closeTo((e['majoration_de_continuite'] as num).toDouble(), 0.01),
          reason: '$ou : majoration assumee',
        );
        expect(
          calculee.indice,
          closeTo((e['indice'] as num).toDouble(), 0.01),
          reason: '$ou : indice',
        );
        expect(
          calculee.monteesContinues,
          e['montees_continues'],
          reason: '$ou : montees continues',
        );
        expect(
          calculee.plusGrosseMonteeM,
          closeTo((e['plus_grosse_montee_m'] as num).toDouble(), 1.0),
          reason: '$ou : plus grosse montee continue',
        );
      }
    });

    test('LE TOTAL ET LE SENTIER D UN SEUL TENANT CONCORDENT, et le prix du '
        'decoupage avec', () {
      final totaux = mesure['totaux'] as Map<String, dynamic>;
      final sensTrace = totaux['sens_trace'] as Map<String, dynamic>;
      final dUnTenant = sensTrace['d_un_seul_tenant'] as Map<String, dynamic>;

      var somme = 0.0;
      for (final attendue in mesure['etapes_sens_trace'] as List<dynamic>) {
        final e = attendue as Map<String, dynamic>;
        somme += IndiceDuTerrain.calculer(
          terrain: profil.tranche(
            pkDebutM: (e['pk_depart_km'] as num).toDouble() * 1000.0,
            pkFinM: (e['pk_arrivee_km'] as num).toDouble() * 1000.0,
          ),
        ).indice;
      }
      expect(
        somme,
        closeTo((sensTrace['somme_des_16_etapes'] as num).toDouble(), 0.05),
      );

      final tout = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: 0, pkFinM: profil.longueurM),
      );
      expect(
        tout.indice,
        closeTo((dUnTenant['indice'] as num).toDouble(), 0.05),
      );
      expect(tout.monteesContinues, dUnTenant['montees_continues']);
      expect(
        tout.plusGrosseMonteeM,
        closeTo((dUnTenant['plus_grosse_montee_m'] as num).toDouble(), 1.0),
      );
      expect(
        100 * (tout.indice - somme) / tout.indice,
        closeTo((totaux['prix_du_decoupage_pct'] as num).toDouble(), 0.05),
        reason:
            'dormir seize fois rend le sentier moins dur que de le marcher '
            'd un trait, et ce pourcentage est cette information',
      );
    });

    test('LE SENTIER PESE EN DESCENDANT N EST PAS LE MEME QU EN REMONTANT', () {
      final totaux = mesure['totaux'] as Map<String, dynamic>;
      final trace = (totaux['sens_trace'] as Map<String, dynamic>);
      final inverse = (totaux['sens_inverse'] as Map<String, dynamic>);
      // La premiere etape est la preuve la plus parlante : 1 454 m de montee
      // dans un sens, 1 454 m de descente dans l'autre.
      final premiereAuTrace =
          (mesure['etapes_sens_trace'] as List<dynamic>).first
              as Map<String, dynamic>;
      final premiereAlEnvers =
          (mesure['etapes_sens_inverse'] as List<dynamic>).first
              as Map<String, dynamic>;
      expect(
        (premiereAuTrace['indice'] as num).toDouble(),
        greaterThan(3 * (premiereAlEnvers['indice'] as num).toDouble()),
        reason:
            'Calenzana - l Ortu di u Piobbu vaut 3,6 fois plus en montant qu '
            'en descendant a l exposant mesure 1,08 (4,8 fois a 1,25) : le '
            'compte de la 852, lui, les cotait presque pareil',
      );
      expect(
        (trace['somme_des_16_etapes'] as num).toDouble(),
        greaterThan((inverse['somme_des_16_etapes'] as num).toDouble()),
      );
    });
  });

  group('858 — ce que le fichier promet sur la loi se verifie sur la '
      'trace', () {
    test('A BETA = 1, LE GR20 ENTIER VAUT EXACTEMENT SON SOCLE MESURE', () {
      final attendu =
          mesure['sans_part_assumee_beta_1'] as Map<String, dynamic>;
      final sansPartAssumee = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: 0, pkFinM: profil.longueurM),
        loi: LoiDeLIndice.entierementMesuree,
      );
      expect(sansPartAssumee.majorationDeContinuite, closeTo(0.0, 1e-9));
      expect(
        sansPartAssumee.indice,
        closeTo((attendu['indice'] as num).toDouble(), 0.05),
      );
      expect(
        sansPartAssumee.indice,
        closeTo(sansPartAssumee.socleMesure, 1e-9),
      );
    });

    test('LE SOCLE RESTE ADDITIF SUR LA VRAIE TRACE, OU QU ON COUPE', () {
      final tout = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: 0, pkFinM: profil.longueurM),
      );
      var pireEcart = 0.0;
      for (var k = 1; k < 40; k++) {
        final coupe = profil.longueurM * k / 40.0;
        final avant = IndiceDuTerrain.calculer(
          terrain: profil.tranche(pkDebutM: 0, pkFinM: coupe),
        );
        final apres = IndiceDuTerrain.calculer(
          terrain: profil.tranche(pkDebutM: coupe, pkFinM: profil.longueurM),
        );
        final ecart = (avant.socleMesure + apres.socleMesure - tout.socleMesure)
            .abs();
        if (ecart > pireEcart) pireEcart = ecart;
      }
      expect(pireEcart, lessThan(1e-9));
    });

    test('DORMIR A L ORTU DI U PIOBBU ECONOMISE CE QUE LE FICHIER DIT : '
        'environ 12 % d indice', () {
      final cas =
          (mesure['additivite']
                  as Map<String, dynamic>)['cas_reel_ortu_di_u_piobbu']
              as Map<String, dynamic>;
      final etapes = etapesPubliees['etapes'] as List<dynamic>;
      final e1 = etapes[0] as Map<String, dynamic>;
      final e2 = etapes[1] as Map<String, dynamic>;
      final debut = (e1['pk_depart_km'] as num).toDouble() * 1000.0;
      final milieu = (e1['pk_arrivee_km'] as num).toDouble() * 1000.0;
      final fin = (e2['pk_arrivee_km'] as num).toDouble() * 1000.0;

      final dUnTrait = IndiceDuTerrain.calculer(
        terrain: profil.tranche(pkDebutM: debut, pkFinM: fin),
      );
      final enDeuxJournees =
          IndiceDuTerrain.calculer(
            terrain: profil.tranche(pkDebutM: debut, pkFinM: milieu),
          ).indice +
          IndiceDuTerrain.calculer(
            terrain: profil.tranche(pkDebutM: milieu, pkFinM: fin),
          ).indice;

      expect(
        dUnTrait.indice,
        closeTo((cas['en_une_journee'] as num).toDouble(), 0.05),
      );
      expect(
        enDeuxJournees,
        closeTo((cas['en_deux_journees'] as num).toDouble(), 0.05),
      );
      expect(
        enDeuxJournees,
        lessThan(dUnTrait.indice),
        reason:
            'la coupure tombe DANS la premiere montee continue du sentier, a '
            '74 % de son denivele : la somme DOIT etre inferieure au tout',
      );
      expect(
        100 * (dUnTrait.indice - enDeuxJournees) / dUnTrait.indice,
        closeTo((cas['deficit_pct'] as num).toDouble(), 0.1),
      );
    });
  });
}
