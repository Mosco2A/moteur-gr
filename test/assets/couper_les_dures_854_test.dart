// GARDE — TACHE 854 : UNE ETAPE NE SE COUPE PAS, ET VOILA CE QUE CA CHANGE.
//
// LA REGLE, TRANCHEE PAR CHRISTOPHE LE 18/10 10:46, verbatim : « pourquoi 19
// jours??? il y a 16 etapes ???? et tu ne peux pas couper les etapes !!!! ».
//
// LA DISTINCTION QUI COMMANDE TOUT. Une ETAPE est un segment FIXE du sentier
// et l'unite de VENTE (1 EUR l'etape, GR20 = 16 etapes = 16 EUR, modele
// #99305) : la couper fabriquerait une dix-septieme etape et changerait le
// produit et son prix. Une JOURNEE est ce que le marcheur fait de sa journee :
// il GROUPE des etapes entieres, il ajoute des journees de REPOS, il ne coupe
// jamais une etape en deux demi-journees.
//
// CE QUE CE FICHIER A D'ABORD EU FAUX, ET IL FAUT QUE CA RESTE ECRIT. La
// premiere version de ce lot cherchait ou DORMIR A L'INTERIEUR des etapes
// dures pour les couper, et concluait que le plancher du GR20 etait l'etape 1
// (26,46 km-effort). C'etait une mesure juste sur une base INTERDITE. Sur la
// seule base legale — grouper des etapes entieres — le plancher est l'ETAPE 6,
// Ciottulu di i Mori vers Manganu, a 36,45 km-effort. La bonne regle donne un
// sentier BIEN PLUS DUR que la mauvaise, pas plus facile.
//
// DEUX CALCULS INDEPENDANTS, ET ILS DOIVENT CONCORDER.
// `tool/couper_les_etapes_dures_854.py` mesure en Python et ecrit
// `assets/data/gr20/coupes_854.json`. Ce fichier-ci recalcule les MEMES
// scenarios en DART, par le socle du produit (`SeuilsDeDifficulte`,
// `DifficulteDuSentier`, `RepartitionEquilibree`), et exige le meme verdict
// etape par etape et allure par allure.
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
  late Map<String, dynamic> legal;

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
    legal = mesure['base_legale_groupement_d_etapes'] as Map<String, dynamic>;
  });

  /// Les etapes, dans l'ordre, reduites a ce que le classement demande.
  List<JourneeMesuree> etapesMesurees({bool envers = false}) {
    final liste = <JourneeMesuree>[];
    for (final brut in etapes) {
      final e = brut as Map<String, dynamic>;
      liste.add(
        JourneeMesuree(
          km: (e['km'] as num).toDouble(),
          // LE SENS INVERSE ECHANGE LES DEUX DENIVELES : ce qu'on montait, on
          // le descend.
          deniveleM: envers ? e['dmoins_m'] as int : e['dplus_m'] as int,
          descenteM: envers ? e['dplus_m'] as int : e['dmoins_m'] as int,
        ),
      );
    }
    return envers ? liste.reversed.toList() : liste;
  }

  /// Le sentier groupe en [jours] journees de marche — DES ETAPES ENTIERES,
  /// jamais une coupure.
  DifficulteDuSentier? auRythmeDe(int jours, {bool envers = false}) {
    final unites = etapesMesurees(envers: envers);
    final charges = <double>[
      for (final brut in etapes)
        ((brut as Map<String, dynamic>)['minutes'] as num).toDouble(),
    ];
    final ordonnees = envers ? charges.reversed.toList() : charges;
    final debuts = RepartitionEquilibree.coupes(ordonnees, jours);

    final journees = <JourneeMesuree>[];
    for (var i = 0; i < debuts.length; i++) {
      final fin = i + 1 < debuts.length ? debuts[i + 1] : unites.length;
      var km = 0.0;
      var dplus = 0;
      var dmoins = 0;
      for (var j = debuts[i]; j < fin; j++) {
        km += unites[j].km;
        dplus += unites[j].deniveleM;
        dmoins += unites[j].descenteM;
      }
      journees.add(JourneeMesuree(km: km, deniveleM: dplus, descenteM: dmoins));
    }
    return DifficulteDuSentier.calculer(jours: jours, journees: journees);
  }

  // =========================================================================
  // 1 — LES SEIZE ETAPES : LE DART ET LE PYTHON DISENT LA MEME BANDE
  // =========================================================================

  group('les seize etapes federales', () {
    test('il y en a bien SEIZE, et c est le nombre qui se vend', () {
      expect(
        etapes.length,
        16,
        reason:
            'le modele du 01/09 (#99305) vend le GR20 seize etapes ; le '
            'catalogue porte 9 au nord et 7 au sud, qui somment a seize',
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
            'de bande selon la source : les chiffres de ce lot ne seraient '
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
  // 2 — LE PLANCHER EST L'ETAPE LA PLUS DURE, ET IL NE BOUGE PLUS
  // =========================================================================

  group('le plancher du sentier', () {
    test('AU PLUS SEIZE JOURNEES DE MARCHE, parce qu il y a seize etapes', () {
      expect(
        legal['journees_de_marche_maximum'],
        16,
        reason:
            'une journee groupe des etapes entieres : on ne peut pas en '
            'fabriquer une dix-septieme. Au-dela de seize, on n ajoute que '
            'du REPOS, qui ne touche aucune journee de marche.',
      );
    });

    test('LE PLANCHER EST L ETAPE 6, PAS L ETAPE 1', () {
      final plancher = legal['plancher_sens_normal'] as Map<String, dynamic>;
      expect(
        plancher['rang'],
        6,
        reason:
            'Ciottulu di i Mori vers Manganu : 25,02 km, D+786, D-1190. Elle '
            'ne monte que 786 m et c est pourtant la plus dure des seize — '
            'une journee de vingt-cinq kilometres n est pas facile parce '
            'qu elle monte peu.',
      );
      expect(
        (plancher['effort_km'] as num).toDouble(),
        closeTo(36.45, 0.01),
        reason:
            'et le seuil du tres difficile est a 25,0 : le plancher le '
            'depasse de plus de onze km-effort, pas de un et demi comme le '
            'disait la mesure faite sur la base interdite',
      );
      expect(plancher['bande'], 'tres difficile');
    });

    test('EN SENS INVERSE LE PLANCHER EST ENCORE PLUS HAUT', () {
      final envers = legal['plancher_sens_inverse'] as Map<String, dynamic>;
      expect(
        (envers['effort_km'] as num).toDouble(),
        closeTo(39.28, 0.01),
        reason:
            'la meme etape marchee a l envers monte 1 190 m au lieu de 786 : '
            'de Manganu vers Ciottulu di i Mori elle vaut 39,28 km-effort',
      );
      expect(
        (envers['effort_km'] as num).toDouble(),
        greaterThan(
          ((legal['plancher_sens_normal'] as Map<String, dynamic>)['effort_km']
                  as num)
              .toDouble(),
        ),
        reason: 'le sens inverse est le sens DUR sur cette etape',
      );
    });

    test('LE PLANCHER EST ATTEINT DES TREIZE JOURNEES, ET NE BOUGE PLUS', () {
      expect(
        legal['plancher_atteint_a_partir_de_jours'],
        13,
        reason:
            'des treize journees de marche, le repartiteur laisse l etape 6 '
            'seule dans sa journee : la pire journee EST cette etape. '
            'Christophe le disait de seize ; la mesure dit treize, donc son '
            'raisonnement tient et le plancher arrive meme plus tot.',
      );

      // LA PREUVE EN DART, allure par allure : de 13 a 16 journees la pire
      // journee ne bouge pas d'un centieme.
      for (var jours = 13; jours <= 16; jours++) {
        final pire = auRythmeDe(jours)!.pireJournee!;
        expect(
          pire.kmEffort,
          closeTo(36.45, 0.01),
          reason:
              'a $jours journees de marche la pire journee est encore '
              'l etape 6 : ajouter des journees ne la coupe pas',
        );
      }
    });
  });

  // =========================================================================
  // 3 — LES QUATRE ALLURES, DANS LES DEUX SENS, SUR LA BASE LEGALE
  // =========================================================================

  group('les quatre allures de la fiche', () {
    test('7, 9, 12 et 16 journees : TRES DIFFICILE dans les deux sens', () {
      for (final jours in <int>[7, 9, 12, 16]) {
        for (final envers in <bool>[false, true]) {
          final d = auRythmeDe(jours, envers: envers);
          expect(d, isNotNull);
          expect(
            _nomDeBande(d!.verdict!),
            'tres difficile',
            reason:
                'a $jours journees, sens ${envers ? 'inverse' : 'normal'} : '
                'AUCUNE des quatre allures ne fait descendre le GR20, et '
                'aucune n en est proche',
          );
        }
      }
    });

    test('le Dart retrouve les chiffres du Python, allure par allure', () {
      final normal = legal['allures_sens_normal'] as Map<String, dynamic>;
      final inverse = legal['allures_sens_inverse'] as Map<String, dynamic>;

      for (var jours = 7; jours <= 16; jours++) {
        final attenduNormal =
            (normal['$jours'] as Map<String, dynamic>)['pire_journee_km_effort']
                as num;
        expect(
          auRythmeDe(jours)!.pireJournee!.kmEffort,
          closeTo(attenduNormal.toDouble(), 0.02),
          reason: 'sens normal, $jours journees',
        );

        final attenduInverse =
            (inverse['$jours']
                    as Map<String, dynamic>)['pire_journee_km_effort']
                as num;
        expect(
          auRythmeDe(jours, envers: true)!.pireJournee!.kmEffort,
          closeTo(attenduInverse.toDouble(), 0.02),
          reason: 'sens inverse, $jours journees',
        );
      }
    });

    test('AUCUNE allure de 1 a 16 journees ne descend sous tres difficile', () {
      for (var jours = 1; jours <= 16; jours++) {
        expect(
          _nomDeBande(auRythmeDe(jours)!.verdict!),
          'tres difficile',
          reason:
              'a $jours journees. LA REPONSE A « pourquoi 19 jours » : il n y '
              'a pas de dix-neuvieme journee de MARCHE a avoir, et aucune des '
              'seize possibles ne fait descendre le sentier. Les dix-neuf '
              'jours de la 852 venaient d un decoupage qui coupait les '
              'etapes.',
        );
      }
    });
  });

  // =========================================================================
  // 4 — LE DEFAUT : LE DECOUPAGE DU PRODUIT COUPE LES ETAPES
  // =========================================================================

  group('le defaut mesure', () {
    test('QUINZE des trente et une bornes de journee ne sont pas des fins '
        'd etape', () {
      final defaut =
          mesure['defaut_le_decoupage_coupe_les_etapes']
              as Map<String, dynamic>;
      expect(defaut['bornes_possibles'], 31);
      expect(
        defaut['bornes_qui_ne_sont_pas_des_fins_d_etape'],
        15,
        reason:
            'A CES QUINZE BORNES, LE PRODUIT COUPE UNE ETAPE EN DEUX. Il '
            'fabrique donc des etapes que personne n a vendues, et c est ce '
            'que Christophe a interdit le 18/10.',
      );
    });

    test('la donnee du produit AVOUE elle-meme le decoupage interdit', () {
      final defaut =
          mesure['defaut_le_decoupage_coupe_les_etapes']
              as Map<String, dynamic>;
      expect(
        defaut['aveu_dans_la_donnee'],
        contains('ailleurs qu a une fin d etape'),
        reason:
            'LA PREUVE N EST PAS UNE DEDUCTION : le champ `quoi` de '
            'nuits_possibles.json dit mot pour mot que le curseur de duree '
            's en sert « pour poser une fin de journee ailleurs qu a une fin '
            'd etape ». C est ecrit dans le binaire livre.',
      );
    });

    test('LA BASE INTERDITE ANNONCAIT UN SENTIER PLUS FACILE QU IL N EST', () {
      final defaut =
          mesure['defaut_le_decoupage_coupe_les_etapes']
              as Map<String, dynamic>;
      final faux =
          defaut['allures_sur_cette_base_fausse'] as Map<String, dynamic>;
      final pireFausse =
          ((faux['16'] as Map<String, dynamic>)['pire_journee_km_effort']
                  as num)
              .toDouble();

      expect(
        pireFausse,
        lessThan(
          ((legal['plancher_sens_normal'] as Map<String, dynamic>)['effort_km']
                  as num)
              .toDouble(),
        ),
        reason:
            'LE SENS DE L ERREUR COMPTE, ET IL EST DU MAUVAIS COTE : a seize '
            'jours, la base interdite annoncait une pire journee de '
            '${pireFausse.toStringAsFixed(2)} km-effort quand la verite est '
            '36,45. Elle annoncait donc au randonneur une journee PLUS '
            'LEGERE que celle qu il marchera. Une erreur qui rassure a tort '
            'est la pire espece sur un sentier de haute montagne.',
      );
    });
  });

  // =========================================================================
  // 5 — LES DEUX CHAPITRES, LES VRAIS PRODUITS
  // =========================================================================

  group('les deux chapitres', () {
    test('le nord porte 9 etapes, le sud 7, donc 9 et 7 journees de marche '
        'au plus', () {
      final chapitres = legal['chapitres'] as Map<String, dynamic>;
      expect((chapitres['gr20-nord'] as Map<String, dynamic>)['etapes'], 9);
      expect((chapitres['gr20-sud'] as Map<String, dynamic>)['etapes'], 7);
      expect(
        (chapitres['gr20-nord']
            as Map<String, dynamic>)['journees_de_marche_maximum'],
        9,
        reason:
            'ET C EST UN DEFAUT LIVRE : la fiche du chapitre nord, ecrite par '
            'la tache 853, annonce « de cinq a quinze jours ». Quinze '
            'journees de marche sur neuf etapes demanderait de couper six '
            'etapes.',
      );
    });

    test('les deux chapitres sont TRES DIFFICILES a toutes leurs allures', () {
      final chapitres = legal['chapitres'] as Map<String, dynamic>;
      for (final id in <String>['gr20-nord', 'gr20-sud']) {
        final c = chapitres[id] as Map<String, dynamic>;
        final allures = c['allures'] as Map<String, dynamic>;
        for (final entree in allures.entries) {
          expect(
            (entree.value as Map<String, dynamic>)['verdict'],
            'tres difficile',
            reason:
                '$id a ${entree.key} journee(s). LE SUD N EST PLUS LE '
                'CHAPITRE OU L ALLURE CHANGE LE VERDICT : son plancher est '
                'l etape 13 (Usciolu vers Asinau, 33,12 km-effort), donc il '
                'est tres difficile a TOUTES ses allures. La fiche du sud '
                'dit le contraire et doit etre corrigee.',
          );
        }
      }
    });
  });
}
