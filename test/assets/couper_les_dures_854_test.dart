// GARDE — TACHE 854 : PEUT-ON COUPER LES ETAPES LES PLUS DURES DU GR20 ?
//
// LA QUESTION DE CHRISTOPHE, verbatim le 18/10 10:18 : « tu ne m'a pas dit
// s'il etait possible de decouper les etapes les plus dure ».
//
// LE MODELE, PRECISE LE 18/10 11:03, ET C'EST LUI QUI FAIT LOI : « NON si on
// peut couper des etapes pour rendre le GR20 plus facile et le faire en 19
// Jours on fait!! Mais les etapes du GR restent les etapes du GR. 16 c'et 16,
// si le gars fait la premiere en 2 fois et bien c'est toujours 16 etape en 17
// jours ».
//
// LES DEUX COMPTES NE SE TOUCHENT JAMAIS. L'ETAPE est la reference FIXE du
// sentier et l'unite de VENTE : seize, pour toujours, 16 EUR. La JOURNEE est
// libre — on peut faire une etape en DEUX journees, grouper plusieurs etapes,
// ajouter du repos. Couper une journee a l'interieur d'une etape est donc
// AUTORISE, et les trente et une nuits de la tache 838 sont de bonnes bornes.
// Le COMPTE D'ETAPES et le PRIX sont gardes a part, dans
// `le_prix_ne_suit_pas_les_jours_854_test.dart`.
//
// LA LACUNE QUE CE LOT COMBLE. La tache 849 n'a fouille QU'UN segment,
// Calenzana vers l'Ortu di u Piobbu, et y a trouve qu'on ne peut rien couper.
// Sa reponse a ete lue comme « on ne peut pas couper », alors qu'elle ne
// portait que sur la PREMIERE etape. Les quinze autres n'avaient jamais ete
// examinees — et depuis la 852 la pire a CHANGE D'IDENTITE : ce n'est plus
// l'etape 1 mais l'ETAPE 6, Ciottulu di i Mori vers Manganu.
//
// DEUX CALCULS INDEPENDANTS, ET ILS DOIVENT CONCORDER.
// `tool/couper_les_etapes_dures_854.py` mesure en Python et ecrit
// `assets/data/gr20/coupes_854.json`. Ce fichier-ci recalcule les MEMES
// scenarios en DART, par le socle du produit (`SeuilsDeDifficulte`,
// `DifficulteDuSentier`, `RepartitionEquilibree`), et exige le meme verdict.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/difficulte_du_sentier.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/repartition_equilibree.dart';

/// Le nom de bande tel que le Python l'ecrit, pour comparer sans ambiguite.
String _nomDeBande(NiveauDeDifficulte niveau) => switch (niveau) {
  NiveauDeDifficulte.facile => 'facile',
  NiveauDeDifficulte.moyen => 'moyen',
  NiveauDeDifficulte.difficile => 'difficile',
  NiveauDeDifficulte.tresDifficile => 'tres difficile',
};

void main() {
  late Map<String, dynamic> mesure;
  late List<dynamic> etapes;
  late List<dynamic> segments;
  late Map<String, dynamic> enCoupant;

  setUpAll(() {
    final fichier = File('assets/data/gr20/coupes_854.json');
    expect(
      fichier.existsSync(),
      isTrue,
      reason:
          'la mesure Python doit avoir tourne : '
          'python tool/couper_les_etapes_dures_854.py',
    );
    mesure = jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
    etapes = mesure['etapes_federales'] as List<dynamic>;
    enCoupant = mesure['en_coupant_ou_l_on_peut'] as Map<String, dynamic>;

    final nuits =
        jsonDecode(
              File('assets/data/gr20/nuits_possibles.json').readAsStringSync(),
            )
            as Map<String, dynamic>;
    segments = nuits['entre_les_nuits'] as List<dynamic>;
  });

  // =========================================================================
  // 1 — LES SEIZE ETAPES : LE DART ET LE PYTHON DISENT LA MEME BANDE
  // =========================================================================

  group('les seize etapes federales', () {
    test('il y en a bien SEIZE, et ce nombre ne bougera jamais', () {
      expect(
        etapes.length,
        16,
        reason:
            '« 16 c est 16 ». C est la reference du sentier et l unite de '
            'vente ; couper des journees dedans n en fait pas dix-sept.',
      );
    });

    test('le Dart classe chaque etape dans la bande que le Python annonce', () {
      for (final brut in etapes) {
        final e = brut as Map<String, dynamic>;
        final enDart = SeuilsDeDifficulte.pourUneJournee(
          km: (e['km'] as num).toDouble(),
          deniveleM: e['dplus_m'] as int,
          descenteM: e['dmoins_m'] as int,
        );
        expect(
          _nomDeBande(enDart),
          e['bande'],
          reason:
              'etape ${e['rang']} (${e['depart']} -> ${e['arrivee']}) : le '
              'socle du produit et la mesure Python doivent tomber sur la '
              'meme bande',
        );
      }
    });

    test('le Dart retrouve l effort au millieme que le Python annonce', () {
      for (final brut in etapes) {
        final e = brut as Map<String, dynamic>;
        final enDart = SeuilsDeDifficulte.effortDeLaJournee(
          km: (e['km'] as num).toDouble(),
          deniveleM: e['dplus_m'] as int,
          descenteM: e['dmoins_m'] as int,
        );
        expect(
          enDart,
          closeTo((e['effort_km'] as num).toDouble(), 0.001),
          reason: 'etape ${e['rang']} : meme formule, meme chiffre',
        );
      }
    });

    test('LES DEUX SOURCES DE MESURE CONCORDENT SUR TOUTES LES BANDES', () {
      // La mesure d'un bout a l'autre (839) et la somme des segments (838) ne
      // tombent pas sur le meme chiffre — le denivele est ancre aux deux bouts
      // de chaque morceau mesure, donc decouper puis sommer derive un peu. Ce
      // qui compte est que la derive ne change AUCUNE bande.
      final controle =
          mesure['controle_des_deux_mesures'] as Map<String, dynamic>;
      expect(
        controle['toutes_les_bandes_concordent'],
        isTrue,
        reason:
            'les etapes ${controle['etapes_dont_la_bande_differe']} changent '
            'de bande selon la source : les chiffres de coupe ne seraient '
            'plus comparables a ceux de la fiche',
      );
      expect(
        (controle['ecart_max_km_effort'] as num).toDouble(),
        lessThan(0.5),
        reason:
            'un ecart de plus d un demi km-effort entre les deux sources ne '
            'serait plus un effet d ancrage, ce serait une erreur de donnee',
      );
    });
  });

  // =========================================================================
  // 2 — LA REPONSE : QUI SE COUPE, QUI NE SE COUPE PAS
  // =========================================================================

  group('peut-on couper les etapes dures', () {
    test('DIX etapes sur seize sont dans les deux bandes hautes', () {
      final hautes = etapes.where((e) {
        final niveau = SeuilsDeDifficulte.pourUneJournee(
          km: ((e as Map<String, dynamic>)['km'] as num).toDouble(),
          deniveleM: e['dplus_m'] as int,
          descenteM: e['dmoins_m'] as int,
        );
        return niveau.estUneBandeHaute;
      }).toList();

      expect(hautes.length, 10);
      expect(
        (mesure['bilan'] as Map<String, dynamic>)['etapes_hautes'],
        10,
        reason: 'le Python doit compter les memes',
      );
    });

    test('OUI : SIX des dix se coupent sur une nuit DEJA RELEVEE', () {
      final bilan = mesure['bilan'] as Map<String, dynamic>;
      expect(
        bilan['hautes_coupables'],
        containsAll(<int>[6, 9, 10, 11, 12, 13]),
        reason:
            'LA REPONSE A CHRISTOPHE : oui, la majorite des etapes dures se '
            'coupent, et les points de coupe existent deja dans la donnee du '
            'produit (releve 838). Il n y a rien a inventer.',
      );
      expect((bilan['hautes_coupables'] as List<dynamic>).length, 6);
    });

    test('QUATRE ne se coupent pas, et il faut dire lesquelles', () {
      final bilan = mesure['bilan'] as Map<String, dynamic>;
      expect(
        bilan['hautes_incoupables'],
        containsAll(<int>[1, 4, 7, 16]),
        reason:
            'ces quatre n ont AUCUNE nuit relevee a l interieur. Pour trois '
            'd entre elles (4, 7, 16) cela veut dire « rien dans le releve de '
            'la 838 », pas « rien n existe » : seule la premiere a ete '
            'fouillee au large par la 849.',
      );
      expect((bilan['hautes_incoupables'] as List<dynamic>).length, 4);
    });

    test('TROIS etapes hautes restent a fouiller au large', () {
      final aFouiller = (mesure['a_fouiller_au_large'] as List<dynamic>)
          .where(
            (e) =>
                (e as Map<String, dynamic>)['deja_fouille_par_la_849'] == false,
          )
          .map((e) => (e as Map<String, dynamic>)['rang'])
          .toList();
      expect(
        aFouiller,
        containsAll(<int>[4, 7, 16]),
        reason:
            'LE TROU DE MESURE DE CE LOT, NOMME PLUTOT QU ARRONDI : le releve '
            '838 avait un couloir de 3 km et un seuil de 30 minutes. Dire de '
            'ces trois etapes qu elles ne se coupent pas demanderait le '
            'releve large de la 849 (8 km, aucun seuil), qui n a ete fait que '
            'sur la premiere.',
      );
    });

    test('QUINZE des trente et une bornes tombent DANS une etape, et c est '
        'autorise', () {
      expect(enCoupant['bornes_possibles'], 31);
      expect(
        enCoupant['bornes_a_l_interieur_d_une_etape'],
        15,
        reason:
            'A CES QUINZE BORNES, LE MARCHEUR S ARRETE AU MILIEU D UNE ETAPE. '
            'C est permis : « si le gars fait la premiere en 2 fois et bien c '
            'est toujours 16 etape en 17 jours ». Le compte d etapes ne bouge '
            'pas, le compte de jours monte.',
      );
    });
  });

  // =========================================================================
  // 3 — LA PIRE ETAPE SE COUPE, ET ELLE SORT DE LA BANDE DU HAUT
  // =========================================================================

  group('l etape 6, la pire des seize', () {
    Map<String, dynamic> etape6() =>
        etapes.firstWhere((e) => (e as Map<String, dynamic>)['rang'] == 6)
            as Map<String, dynamic>;

    test('elle est bien la pire des seize sur l effort complet', () {
      var pire = etapes.first as Map<String, dynamic>;
      for (final e in etapes) {
        final m = e as Map<String, dynamic>;
        if ((m['effort_km'] as num) > (pire['effort_km'] as num)) pire = m;
      }
      expect(
        pire['rang'],
        6,
        reason:
            'la 852 l a etabli : par le seul D+ la pire etait la premiere ; '
            'sur l effort complet c est l etape 6, qui ne monte que 786 m '
            'mais fait 25,02 km et descend 1 190 m',
      );
      expect(pire['bande'], 'tres difficile');
      expect(
        (pire['effort_km'] as num).toDouble(),
        closeTo(36.45, 0.01),
        reason: 'et c est le chiffre que la 852 a publie',
      );
    });

    test('ELLE SE COUPE, et trois endroits releves tombent dedans', () {
      final nuits = etape6()['nuits_interieures'] as List<dynamic>;
      expect(nuits.length, 3);
      expect(
        nuits.map((n) => (n as Map<String, dynamic>)['nom']),
        containsAll(<String>[
          'Bergeries de Radule',
          'Castel De Vergio',
          'Bergeries de Vaccaghia',
        ]),
        reason:
            'les trois portent un identifiant OpenStreetMap et un temps '
            'd acces mesure dans les deux sens',
      );
    });

    test('coupee a Castel De Vergio elle QUITTE la bande du haut', () {
      final coupe = etape6()['coupe'] as Map<String, dynamic>;
      expect(coupe['coupe_a'], 'Castel De Vergio');

      // On recalcule les deux moities EN DART, pour ne pas croire le Python
      // sur parole.
      final demi1 = coupe['demi_1'] as Map<String, dynamic>;
      final demi2 = coupe['demi_2'] as Map<String, dynamic>;
      final e1 = SeuilsDeDifficulte.effortDeLaJournee(
        km: (demi1['km'] as num).toDouble(),
        deniveleM: demi1['dplus_m'] as int,
        descenteM: demi1['dmoins_m'] as int,
      );
      final e2 = SeuilsDeDifficulte.effortDeLaJournee(
        km: (demi2['km'] as num).toDouble(),
        deniveleM: demi2['dplus_m'] as int,
        descenteM: demi2['dmoins_m'] as int,
      );
      final pire = e1 > e2 ? e1 : e2;

      expect(
        pire,
        closeTo((coupe['pire_des_deux_km_effort'] as num).toDouble(), 0.001),
      );
      expect(
        _nomDeBande(SeuilsDeDifficulte.pourEffort(pire)),
        'difficile',
        reason:
            'LA REPONSE CHIFFREE A CHRISTOPHE : la pire etape du GR20 passe '
            'de « tres difficile » a « difficile » en dormant a Castel De '
            'Vergio, qui est a UNE MINUTE du sentier. Elle se coupe, et la '
            'coupe est bon marche. Et ca reste l etape 6 : on en a fait deux '
            'journees, pas deux etapes.',
      );
      expect(
        (coupe['minutes_aller'] as int) + (coupe['minutes_retour'] as int),
        lessThanOrEqualTo(4),
        reason: 'une minute a l aller, une au retour : le detour est nul',
      );
    });
  });

  // =========================================================================
  // 4 — LE RECALCUL : CE QUE COUPER APPORTE, ET CE QUI BLOQUE ENCORE
  // =========================================================================

  group('le recalcul du sentier entier', () {
    /// Les trente et une journees du produit, groupees en [jours] par le
    /// repartiteur du depot, puis classees par le socle.
    DifficulteDuSentier? auRythmeDe(int jours) {
      final charges = segments
          .map(
            (s) => ((s as Map<String, dynamic>)['minutes'] as num).toDouble(),
          )
          .toList();
      final debuts = RepartitionEquilibree.coupes(charges, jours);
      final journees = <JourneeMesuree>[];
      for (var i = 0; i < debuts.length; i++) {
        final fin = i + 1 < debuts.length ? debuts[i + 1] : segments.length;
        var km = 0.0;
        var dplus = 0;
        var dmoins = 0;
        for (var j = debuts[i]; j < fin; j++) {
          final s = segments[j] as Map<String, dynamic>;
          km += (s['km'] as num).toDouble();
          dplus += s['dplus_m'] as int;
          dmoins += s['dmoins_m'] as int;
        }
        journees.add(
          JourneeMesuree(km: km, deniveleM: dplus, descenteM: dmoins),
        );
      }
      return DifficulteDuSentier.calculer(jours: jours, journees: journees);
    }

    test('COUPER APPORTE BEAUCOUP A LA JOURNEE DU MARCHEUR', () {
      // La comparaison qui chiffre le benefice : meme sentier, meme formule,
      // mais sans jamais couper a l'interieur d'une etape.
      final sans =
          (mesure['si_l_on_ne_coupait_jamais_dans_une_etape']
                  as Map<String, dynamic>)['allures_sens_normal']
              as Map<String, dynamic>;
      final avec = enCoupant['allures'] as Map<String, dynamic>;

      final pireAvec =
          ((avec['16'] as Map<String, dynamic>)['pire_journee_km_effort']
                  as num)
              .toDouble();
      final pireSans =
          ((sans['16'] as Map<String, dynamic>)['pire_journee_km_effort']
                  as num)
              .toDouble();

      expect(
        pireSans - pireAvec,
        greaterThan(9.0),
        reason:
            'LE CHIFFRE A RETENIR : a seize jours, les quinze coupures font '
            'passer la journee la plus dure de ${pireSans.toStringAsFixed(2)} '
            'a ${pireAvec.toStringAsFixed(2)} km-effort — pres de dix '
            'km-effort en moins sur le pire jour du marcheur. Couper sert.',
      );
    });

    test('MAIS LE SENTIER RESTE TRES DIFFICILE DE 7 A 31 JOURS', () {
      for (var jours = 7; jours <= 31; jours++) {
        final d = auRythmeDe(jours);
        expect(d, isNotNull);
        expect(
          _nomDeBande(d!.verdict!),
          'tres difficile',
          reason:
              'a $jours jours, en coupant partout ou le releve 838 le permet',
        );
      }
      expect(
        enCoupant['premiere_allure_non_tres_difficile'],
        isNull,
        reason: 'aucune allure de 7 a 31 jours ne fait descendre le sentier',
      );
    });

    test('ET LA CAUSE EST UNE SEULE ETAPE : LA PREMIERE', () {
      // A partir de seize jours, la pire journee EST l'etape 1, et elle vaut
      // 26,48 km-effort pour un seuil a 25,0.
      for (var jours = 16; jours <= 31; jours++) {
        final pire = auRythmeDe(jours)!.pireJournee!;
        expect(
          pire.kmEffort,
          closeTo(26.48, 0.01),
          reason:
              'a $jours jours la pire journee est le premier segment, '
              'Calenzana vers l Ortu di u Piobbu, et elle ne change plus : '
              'aucune nuit ne tombe a son interieur, meme en fouillant au '
              'large (849)',
        );
      }
      expect(
        SeuilsDeDifficulte.effortTresDifficileKm,
        25.0,
        reason: 'le seuil que cette etape depasse de 1,48 km-effort',
      );
      expect(
        enCoupant['ce_qui_bloque'],
        contains('ETAPE 1'),
        reason: 'et la mesure Python nomme la meme cause',
      );
    });

    test('LE SEUL CHEMIN VERS DIFFICILE PASSE PAR LA VARIANTE BONIFATU', () {
      expect(
        enCoupant['le_seul_chemin_vers_difficile'],
        allOf(contains('BONIFATU'), contains('DIX-NEUF')),
        reason:
            'LA REPONSE A « le GR20 descend-il a difficile AVANT 19 jours » : '
            'NON. Couper partout ou l on peut n y suffit pas, parce que la '
            'premiere etape ne se coupe pas. Le seul chemin est la variante '
            'Bonifatu, qui la remplace par deux journees difficiles (19,21 et '
            '18,63 km-effort, mesure 849) — et avec elle le sentier devient '
            'difficile a DIX-NEUF jours (mesure 852), pas avant. Les '
            'dix-neuf jours sont donc un chiffre de VARIANTE, pas de coupe.',
      );
    });
  });
}
