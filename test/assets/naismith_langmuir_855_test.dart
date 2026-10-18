// GARDE — TACHE 855 : LE TEMPS DE MARCHE PAR NAISMITH, CORRIGE PAR LANGMUIR.
//
// LA DECISION, verbatim le 18/10 11:33 : « prend NAISMITH pour tes calculs ».
// Le motif n'est pas une preference de formule : Christophe a demande d'ou
// sortait le calculateur de difficulte, et la reponse honnete etait mauvaise.
// Le bareme de l'IBP n'est pas public (le depot l'ecrit lui-meme),
// l'equivalence « 100 m de montee valent 1 km de plat » n'a pas d'etude
// primaire, et le poids 0,30 de la descente n'est source nulle part. Rien de
// tout cela ne se verifie. NAISMITH (SMCJ, 1892) est public
// et verifiable : une heure pour cinq kilometres, plus une heure pour six cents
// metres de montee. Naismith PUR ne comptant pas la descente, on prend la
// correction de LANGMUIR (Mountaincraft and Leadership, 1984), publique et de
// la meme lignee.
//
// DEUX CALCULS INDEPENDANTS, ET ILS DOIVENT CONCORDER AU DIXIEME DE MINUTE.
// `tool/naismith_langmuir_855.py` mesure sur les 9 128 points de la trace et
// ecrit `assets/data/gr20/naismith_855.json` : c'est lui qui CLASSE les pentes,
// parce que le classement demande la trace. Ce fichier-ci refait le CALCUL en
// Dart, par le socle du produit ([TempsNaismithLangmuir]), sur les entrees que
// le Python publie — et exige le meme nombre de minutes.
//
// POURQUOI LA GARDE EXIGE L'EXACTITUDE ET NON UNE TOLERANCE D'UNE MINUTE. Les
// entrees du modele sont publiees NON ARRONDIES exprès : sur les
// quatre-vingt-quatorze unites mesurees, DEUX basculent d'une minute quand on
// repart des metres arrondis (le segment 7 sort 56 au lieu de 57). Une garde a
// une minute pres aurait laisse passer les deux, donc n'aurait rien garde.
//
// CE QUE CE FICHIER NE GARDE PAS, ET C'EST VOULU. AUCUN SEUIL, AUCUNE BANDE.
// Christophe, le 18/10 11:33 : « ensuite on discutera du positionnement
// facile/moyen/difficile/tres difficile ». Les quatre bandes de
// [SeuilsDeDifficulte] restent donc en kilometres-effort, et ce test verifie
// seulement qu'elles n'ont PAS ete touchees — la conversion en heures est a
// Christophe, pas a moi.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/echelle_de_difficulte.dart';
import 'package:moteur_gr/domain/temps_de_marche_naismith.dart';

/// La mesure publiee par `tool/naismith_langmuir_855.py`.
Map<String, dynamic> _mesure() {
  final fichier = File('assets/data/gr20/naismith_855.json');
  expect(
    fichier.existsSync(),
    isTrue,
    reason:
        'assets/data/gr20/naismith_855.json manque. Relancer '
        '`python tool/naismith_langmuir_855.py`.',
  );
  return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
}

/// Toutes les unites mesurees — seize etapes et trente et un segments.
List<Map<String, dynamic>> _unites(Map<String, dynamic> mesure) => [
  ...(mesure['etapes'] as List<dynamic>).cast<Map<String, dynamic>>(),
  ...(mesure['segments_entre_nuits'] as List<dynamic>)
      .cast<Map<String, dynamic>>(),
];

double _nombre(Object? valeur) => (valeur as num).toDouble();

void main() {
  group('TACHE 855 — Naismith-Langmuir : le Dart et le Python concordent', () {
    test('les quatre-vingt-quatorze unites rendent les memes minutes', () {
      final mesure = _mesure();
      final unites = _unites(mesure);

      // LE COMPTE EST VERIFIE AVANT LES VALEURS. Un fichier tronque ferait
      // passer une boucle vide pour un succes : seize etapes et trente et un
      // segments, dans les deux sens, font quatre-vingt-quatorze cas.
      expect(unites.length, 47, reason: '16 etapes + 31 segments entre nuits');

      var cas = 0;
      for (final unite in unites) {
        for (final sens in const ['sens trace', 'sens inverse']) {
          final mesureDuSens = unite[sens] as Map<String, dynamic>;
          final detail =
              mesureDuSens['detail_du_temps'] as Map<String, dynamic>;
          final entrees = detail['entrees_du_modele'] as Map<String, dynamic>;

          final minutes = TempsNaismithLangmuir.minutes(
            km: _nombre(entrees['km']),
            deniveleM: _nombre(entrees['dplus_m']),
            descenteEnPenteDouceM: _nombre(
              entrees['descente_en_pente_douce_m'],
            ),
            descenteEnPenteRaideM: _nombre(
              entrees['descente_en_pente_raide_m'],
            ),
          );

          final attendues = _nombre(detail['minutes_exactes']);
          expect(
            minutes,
            closeTo(attendues, 0.01),
            reason:
                'unite ${unite['depart']} -> ${unite['arrivee']} ($sens) : '
                'le Dart dit $minutes minutes, le Python $attendues',
          );
          expect(
            minutes.round(),
            mesureDuSens['minutes'],
            reason:
                'la minute ARRONDIE doit concorder aussi : '
                '${unite['depart']} -> ${unite['arrivee']} ($sens)',
          );
          cas++;
        }
      }
      expect(cas, 94, reason: '47 unites x 2 sens');
    });

    test('le moteur de denivele est celui de la maison, pas un second', () {
      final mesure = _mesure();
      final controle = mesure['controle_du_moteur'] as Map<String, dynamic>;

      // C'EST LA GARDE LA PLUS IMPORTANTE DU FICHIER, ET ELLE A DEJA SERVI.
      // Les montees et descentes de la mesure doivent etre IDENTIQUES a celles
      // que l'application affiche (`stages.json` pour les seize etapes,
      // `nuits_possibles.json` pour les trente et un segments). Au premier
      // essai elles ne l'etaient pas : quinze etapes sur seize sortaient a
      // cote, parce que les bornes d'etape avaient ete cherchees par point
      // kilometrique alors que ce sont DIX-SEPT REPERES OPENSTREETMAP projetes
      // sur la trace. Sans ce controle, un temps de marche faux serait parti
      // vers Christophe avec l'air d'etre juste.
      expect(
        controle['toutes_identiques'],
        isTrue,
        reason:
            'le moteur de denivele ne reproduit plus les chiffres publies : '
            '${controle['ecarts']}',
      );
      expect(controle['unites_controlees'], 47);
    });

    test('les deux constantes de Naismith sont celles de 1892', () {
      // ELLES SONT VERIFIEES CONTRE LA PHRASE, PAS CONTRE ELLES-MEMES. Une
      // heure pour cinq kilometres et une heure pour six cents metres de
      // montee : si quiconque touche a l'une, ce test dit laquelle et ce que la
      // reference publique en dit.
      expect(TempsNaismithLangmuir.kmParHeure, 5.0);
      expect(TempsNaismithLangmuir.monteeMetresParHeure, 600.0);
      expect(TempsNaismithLangmuir.minutesParKm, 12.0);
      expect(
        TempsNaismithLangmuir.minutesParMetreDeMontee,
        closeTo(0.1, 1e-12),
      );

      // LANGMUIR : dix minutes par trois cents metres, et les deux pentes qui
      // decident du signe.
      expect(TempsNaismithLangmuir.langmuirMinutes, 10.0);
      expect(TempsNaismithLangmuir.langmuirParMetres, 300.0);
      expect(TempsNaismithLangmuir.penteDouceDeg, 5.0);
      expect(TempsNaismithLangmuir.penteRaideDeg, 12.0);
    });

    test('le cas de etape 6 se refait a la main', () {
      // 25,014 km, 786 m de montee, 723 m de pente douce, 200 m de pente raide.
      // 300,2 + 78,6 - 24,1 + 6,7 = 361,4 minutes, soit 6 h 01. C'est l'exemple
      // ecrit dans la documentation de [TempsNaismithLangmuir.minutes] : un
      // exemple de documentation qui n'est pas verifie finit par mentir.
      final minutes = TempsNaismithLangmuir.minutes(
        km: 25.014,
        deniveleM: 786,
        descenteEnPenteDouceM: 723,
        descenteEnPenteRaideM: 200,
      );
      expect(minutes, closeTo(361.4, 0.1));
      expect(minutes ~/ 60, 6);
    });

    test('la pente se classe en degres, et une falaise ne rend pas NaN', () {
      // 100 m de descente sur 1 000 m de plat : 5,7 degres, pente DOUCE.
      final douce = TempsNaismithLangmuir.penteDeg(
        longueurM: 1000,
        chuteM: 100,
      );
      expect(douce, closeTo(5.71, 0.01));
      expect(TempsNaismithLangmuir.penteDouce(douce), isTrue);
      expect(TempsNaismithLangmuir.penteRaide(douce), isFalse);

      // 300 m de descente sur 1 000 m : 16,7 degres, pente RAIDE.
      final raide = TempsNaismithLangmuir.penteDeg(
        longueurM: 1000,
        chuteM: 300,
      );
      expect(raide, closeTo(16.70, 0.01));
      expect(TempsNaismithLangmuir.penteRaide(raide), isTrue);

      // UNE LONGUEUR NULLE SOUS UNE CHUTE EST UNE FALAISE, PAS UN NaN. Un seul
      // NaN contaminerait le total de toute une etape, et aucune garde de total
      // ne saurait dire d'ou il vient.
      final falaise = TempsNaismithLangmuir.penteDeg(longueurM: 0, chuteM: 50);
      expect(falaise, 90);
      expect(falaise.isNaN, isFalse);
      expect(TempsNaismithLangmuir.penteRaide(falaise), isTrue);

      // Pas de chute, pas de pente — et pas de division par zero non plus.
      expect(TempsNaismithLangmuir.penteDeg(longueurM: 0, chuteM: 0), 0);
    });

    test('une mesure absente ne devient jamais une duree inventee', () {
      expect(
        TempsNaismithLangmuir.minutes(
          km: -1,
          deniveleM: -1,
          descenteEnPenteDouceM: -1,
          descenteEnPenteRaideM: -1,
        ),
        0,
      );
      expect(
        TempsNaismithLangmuir.minutes(
          km: double.nan,
          deniveleM: double.infinity,
          descenteEnPenteDouceM: double.nan,
          descenteEnPenteRaideM: double.nan,
        ),
        0,
      );

      // UNE DUREE NEGATIVE N'EST PAS UNE DUREE. Un sentier qui ne descendrait
      // que des pentes douces pourrait, sur un segment presque plat, voir la
      // remise de Langmuir depasser le temps de Naismith.
      expect(
        TempsNaismithLangmuir.minutes(
          km: 0.1,
          deniveleM: 0,
          descenteEnPenteDouceM: 5000,
          descenteEnPenteRaideM: 0,
        ),
        0,
      );
    });
  });

  group('TACHE 855 — TOBLER : la seule des trois qui voie la raideur', () {
    test('elle repond chiffre en main au cas de Christophe', () {
      // SON EXEMPLE, 18/10 11:56 : « c'est pus dificile de monter 700 metres
      // sur 1KM que 700 metre sur 5 ». Naismith dit 1 h 10 dans les deux cas.
      // Tobler separe les deux, et c'est la raison de son ajout.
      final raide = VitesseDeTobler.minutes(
        longueurHorizontaleM: 1000,
        deniveleM: 700,
      );
      final etale = VitesseDeTobler.minutes(
        longueurHorizontaleM: 5000,
        deniveleM: 700,
      );

      expect(
        raide / 60,
        closeTo(2.32, 0.02),
        reason: '700 m sur 1 km ~ 2 h 19',
      );
      expect(
        etale / 60,
        closeTo(1.62, 0.02),
        reason: '700 m sur 5 km ~ 1 h 37',
      );
      expect(
        raide - etale,
        closeTo(42, 2),
        reason:
            'quarante-deux minutes d ecart pour le MEME denivele — '
            'exactement ce que Naismith ne sait pas dire',
      );

      // NAISMITH, LUI, NE LES SEPARE PAS SUR LE DENIVELE : son cout de montee
      // est le meme, et seule la distance les distingue.
      const monteeRaide = 700 * TempsNaismithLangmuir.minutesParMetreDeMontee;
      const monteeEtale = 700 * TempsNaismithLangmuir.minutesParMetreDeMontee;
      expect(monteeRaide, monteeEtale);
    });

    test('la vitesse est maximale en LEGERE DESCENTE, pas a plat', () {
      // C'est l'une des choses que Tobler apporte : -5 % est plus rapide que 0.
      expect(VitesseDeTobler.kmH(-0.05), closeTo(6.0, 1e-9));
      expect(VitesseDeTobler.kmH(0), closeTo(5.04, 0.01));
      expect(VitesseDeTobler.kmH(0), lessThan(VitesseDeTobler.kmH(-0.05)));

      // Et elle s'ecrase quand ca se redresse.
      expect(VitesseDeTobler.kmH(0.70), closeTo(0.43, 0.01));
      expect(VitesseDeTobler.kmH(0.14), closeTo(3.08, 0.01));
    });

    test('les trois constantes sont celles de Tobler 1993', () {
      expect(VitesseDeTobler.vitesseKmH, 6.0);
      expect(VitesseDeTobler.amortissement, 3.5);
      expect(VitesseDeTobler.penteLaPlusRapide, 0.05);
    });

    test('le Dart refait les temps de Tobler publies par la mesure', () {
      final mesure = _mesure();
      final etapes = (mesure['etapes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(etapes.length, 16);

      for (final etape in etapes) {
        for (final sens in const ['sens trace', 'sens inverse']) {
          final tobler =
              (etape[sens] as Map<String, dynamic>)['tobler']
                  as Map<String, dynamic>;
          // LE TEMPS DE TOBLER NE SE REFAIT PAS DEPUIS UN TOTAL : il est somme
          // segment par segment sur la trace, et deux etapes de meme longueur
          // et meme denivele n'ont pas le meme temps si leurs pentes diffèrent.
          // On verifie donc ce qui EST verifiable sans la trace : que le temps
          // publie est coherent avec la vitesse de Tobler appliquee a la pente
          // MOYENNE, en etant forcement PLUS LENT que cette approximation —
          // parce que la fonction est convexe et que la vraie trace alterne
          // des pentes plus fortes.
          final km = _nombre(tobler['km_du_profil']);
          final minutes = _nombre(tobler['minutes_exactes']);
          expect(km, greaterThan(0));
          expect(minutes, greaterThan(0));

          final parLaPenteMoyenne = VitesseDeTobler.minutes(
            longueurHorizontaleM: km * 1000,
            deniveleM:
                ((etape[sens] as Map<String, dynamic>)['dplus_m'] as int)
                    .toDouble() -
                ((etape[sens] as Map<String, dynamic>)['dmoins_m'] as int)
                    .toDouble(),
          );
          expect(
            minutes,
            greaterThan(parLaPenteMoyenne),
            reason:
                'etape ${etape['rang']} ($sens) : le temps mesure segment par '
                'segment doit etre PLUS LENT que celui de la pente moyenne — '
                'si ce n est plus vrai, la mesure ne lit plus la trace',
          );
        }
      }
    });
  });

  group('TACHE 855 — la raideur et les montees d\'un seul tenant', () {
    test('le seuil de pente est justifie par la mesure, pas decrete', () {
      final mesure = _mesure();
      final choix =
          (mesure['la_raideur_et_les_montees_dun_seul_tenant']
                  as Map<String, dynamic>)['choix_du_seuil']
              as Map<String, dynamic>;

      // HUIT SEUILS SONT ESSAYES et le retenu est le plus STRICT qui ne casse
      // encore aucune vraie montee : a 5 % la plus longue montee du sentier
      // vaut toujours ses 1 146 m, au seuil suivant elle tombe a 881 m.
      expect((choix['seuils_essayes_pct'] as List<dynamic>).length, 8);
      expect(choix['seuil_retenu_pct'], 5.0);

      final essais = (choix['essais'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final sansFiltre = essais.first['plus_longue_montee_du_sentier_m'] as int;
      final auSeuil =
          essais.firstWhere(
                (e) => e['seuil_pct'] == 5.0,
              )['plus_longue_montee_du_sentier_m']
              as int;
      final auDessus =
          essais.firstWhere(
                (e) => e['seuil_pct'] == 8.0,
              )['plus_longue_montee_du_sentier_m']
              as int;

      expect(auSeuil, sansFiltre, reason: 'a 5 % on ne casse encore rien');
      expect(
        auDessus,
        lessThan(sansFiltre),
        reason: 'au-dela, le filtre coupe de vraies montees',
      );
    });

    test('chaque etape porte sa plus longue montee, dans les deux sens', () {
      final mesure = _mesure();
      final etapes = (mesure['etapes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      for (final etape in etapes) {
        for (final sens in const ['sens trace', 'sens inverse']) {
          final raideur =
              (etape[sens] as Map<String, dynamic>)['raideur']
                  as Map<String, dynamic>;
          final plusLongue =
              raideur['plus_longue_montee'] as Map<String, dynamic>?;

          // TOUTE ETAPE DU GR20 MONTE QUELQUE PART, dans les deux sens : une
          // etape sans aucune montee d'un seul tenant signalerait que le
          // detecteur ne detecte plus rien.
          expect(
            plusLongue,
            isNotNull,
            reason: 'etape ${etape['rang']} ($sens) sans aucune montee',
          );
          expect(raideur['montees_dun_seul_tenant'], greaterThan(0));
          expect(plusLongue!['dplus_m'], greaterThan(0));
          expect(plusLongue['pente_moyenne_pct'], greaterThanOrEqualTo(5.0));
          expect(
            plusLongue['pente_max_pct'],
            greaterThanOrEqualTo(plusLongue['pente_moyenne_pct']),
          );
        }
      }
    });

    test(
      'le vecu de Christophe est situe, et la raideur explique son arret',
      () {
        final mesure = _mesure();
        final calibration =
            mesure['calibration_sur_le_vecu_de_christophe']
                as Map<String, dynamic>;
        final montee =
            calibration['la_premiere_montee_en_partant_de_conca']
                as Map<String, dynamic>;
        final premiere =
            montee['premiere_montee_dun_seul_tenant'] as Map<String, dynamic>;

        // LA PREMIERE VRAIE MONTEE EN PARTANT DE CONCA. Sans plancher de
        // materialite, ce calcul tombait sur une BOSSE DE 24 M au kilometre 0
        // — personne n'appelle ca une montee, et surtout pas quelqu'un qui dit
        // s'etre arrete aux quatre cinquiemes de la sienne.
        expect(premiere['dplus_m'], greaterThan(100));
        expect(premiere['pente_moyenne_pct'], greaterThan(10));

        final fractions = (montee['aux_fractions'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        final trois = fractions.firstWhere(
          (f) => (f['fraction_de_la_montee'] as num) == 0.6,
        );
        final quatre = fractions.firstWhere(
          (f) => (f['fraction_de_la_montee'] as num) == 0.8,
        );

        // CE QUI CHANGE ENTRE SON POINT « SANS PROBLEME » ET SON ARRET N'EST NI
        // LE TEMPS NI LE DENIVELE, C'EST LA PENTE LOCALE. C'est la mesure qui
        // confirme son intuition, et c'est le resultat a ne pas perdre.
        expect(
          (quatre['pente_locale_pct'] as num),
          greaterThan(trois['pente_locale_pct'] as num),
          reason:
              'la pente locale doit se redresser entre 3/5 et 4/5 — sinon '
              'l explication de son arret tombe',
        );
        expect(
          (quatre['denivele_monte_m'] as int) -
              (trois['denivele_monte_m'] as int),
          lessThan(100),
          reason: 'moins de cent metres separent les deux points',
        );
      },
    );

    test('TOBLER separe MOINS BIEN les deux sens que Naismith', () {
      final mesure = _mesure();
      final sens =
          (mesure['calibration_sur_le_vecu_de_christophe']
                  as Map<String, dynamic>)['ce_que_les_deux_sens_coutent']
              as Map<String, dynamic>;
      final parModele = sens['par_modele'] as Map<String, dynamic>;

      double rapport(String nom) =>
          _nombre((parModele[nom] as Map<String, dynamic>)['rapport']);

      // C'EST LE RESULTAT CONTRE-INTUITIF DU LOT, ET IL EST GARDE POUR QU'ON
      // NE LE PERDE PAS. Christophe a trouve Paliri-Conca FACILE et
      // Conca-Paliri ARRETANT : c'est le seul vecu dont nous disposons. Tobler
      // ecarte les deux sens de 17 % seulement, Naismith de 43 %, parce que
      // Tobler penalise aussi la descente raide et alourdit donc le sens que
      // Christophe a trouve facile. La recommandation « prendre Tobler » ne
      // tient pas sur ce critere-la.
      expect(rapport('tobler'), lessThan(rapport('naismith_seul')));
      expect(rapport('tobler'), lessThan(rapport('naismith_plus_langmuir')));
      expect(sens['celui_qui_separe_le_mieux'], isNot('tobler'));
    });
  });

  group('TACHE 855 — ce que la mesure REPOND, y compris ce qui derange', () {
    test('Langmuir ne fait presque rien sur le GR20, et c\'est ecrit', () {
      final mesure = _mesure();
      final etapes = (mesure['etapes'] as List<dynamic>)
          .cast<Map<String, dynamic>>();

      var naismith = 0;
      var langmuir = 0;
      for (final e in etapes) {
        final detail =
            (e['sens trace'] as Map<String, dynamic>)['detail_du_temps']
                as Map<String, dynamic>;
        naismith += detail['minutes_naismith'] as int;
        langmuir += detail['minutes_langmuir'] as int;
      }

      // LA PREMISSE DU MANDAT NE TIENT PAS, ET CE TEST EST LA POUR QU'ON NE
      // L'OUBLIE PAS. On attendait de Langmuir qu'il CHARGE la descente du
      // GR20 et tienne ainsi la demande de Christophe (« que le negatif
      // compte »). La mesure dit qu'il l'ANNULE : la correction pese moins de
      // deux pour cent du temps de Naismith pur, parce que les pentes douces
      // escomptees et les pentes raides chargees se compensent.
      expect(
        langmuir.abs() / naismith,
        lessThan(0.02),
        reason:
            'Langmuir pese $langmuir minutes sur $naismith : si ce rapport '
            'devient significatif, la conclusion de la 855 a change et le '
            'rapport a Christophe doit etre refait.',
      );

      // ET SUR L'ETAPE 6, LA PLUS DURE, LANGMUIR ACCORDE UNE REMISE.
      final e6 = etapes.firstWhere((e) => e['rang'] == 6);
      final detail6 =
          (e6['sens trace'] as Map<String, dynamic>)['detail_du_temps']
              as Map<String, dynamic>;
      expect(
        detail6['minutes_langmuir'] as int,
        lessThan(0),
        reason:
            'les 1 191 m de descente de l etape 6 la rendent plus RAPIDE sous '
            'Langmuir, pas plus dure — c est le fait a dire a Christophe',
      );
    });

    test('les six etapes les plus dures gardent le meme ordre', () {
      final mesure = _mesure();
      final reponse = mesure['ce_que_la_mesure_repond'] as Map<String, dynamic>;
      final classement =
          reponse['3_le_classement_ne_s_effondre_pas'] as Map<String, dynamic>;

      final parTemps = (classement['ordre_naismith'] as List<dynamic>)
          .cast<int>();
      final parAncien = (classement['ordre_ancien_km_effort'] as List<dynamic>)
          .cast<int>();

      // CHANGER DE MODELE NE RENVERSE PAS LES VERDICTS, et c'est la bonne
      // nouvelle du lot : les six premieres places sont identiques.
      expect(parTemps.take(6), parAncien.take(6));
      expect(parTemps.first, 6, reason: 'l etape 6 reste la plus dure');
      expect(parTemps.last, 15, reason: 'l etape 15 reste la plus facile');
    });

    test('les deux ancres de Christophe laissent un intervalle VIDE', () {
      final mesure = _mesure();
      final ancres =
          ((mesure['ce_que_la_mesure_repond']
                      as Map<
                        String,
                        dynamic
                      >)['3_le_classement_ne_s_effondre_pas']
                  as Map<String, dynamic>)['les_deux_ancres_de_christophe']
              as Map<String, dynamic>;

      final dure =
          (ancres['calenzana_ortu_tres_difficile']
                  as Map<String, dynamic>)['minutes']
              as int;
      final sous =
          (ancres['vizzavona_e_capanelle_sous_le_seuil']
                  as Map<String, dynamic>)['minutes']
              as int;

      // IL A CLASSE CES DEUX ETAPES A LA MAIN LE 17/10 : Calenzana-Ortu TRES
      // DIFFICILE, Vizzavona-E Capanelle SOUS le seuil. Tout seuil entre les
      // deux reproduit ses deux verdicts, et AUCUNE des seize etapes ne tombe
      // entre les deux — l'intervalle est donc large et sans ambiguite.
      expect(sous, lessThan(dure));
      expect(
        (ancres['etapes_dans_cet_intervalle'] as List<dynamic>),
        isEmpty,
        reason:
            'une etape tombee dans l intervalle rendrait le choix du seuil '
            'ambigu : il faudrait le dire a Christophe avant qu il tranche',
      );
    });

    test('AUCUN seuil de difficulte n\'a ete touche par ce lot', () {
      // LA GARDE DU PERIMETRE. Christophe a dit « ensuite on discutera du
      // positionnement ». Les quatre bandes restent donc exactement ou la
      // tache 852 les a laissees, en kilometres-effort. Ce test rougit si
      // quiconque — moi compris — convertit l'echelle en heures avant qu'il
      // ait tranche.
      expect(SeuilsDeDifficulte.effortMoyenKm, 10);
      expect(SeuilsDeDifficulte.effortDifficileKm, 17.5);
      expect(SeuilsDeDifficulte.effortTresDifficileKm, 25);
      expect(SeuilsDeDifficulte.metresDeMonteeParKmDePlat, 100);
      expect(SeuilsDeDifficulte.poidsDeLaDescente, 0.30);
      expect(NiveauDeDifficulte.values.length, 4);
    });
  });
}
