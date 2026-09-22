import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/features/feasibility/domain/hiker_input_bounds.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';

/// GATE — LES BORNES DE SAISIE N ECARTENT QUE L IMPOSSIBLE.
///
/// Principe pose par Chris le 22/09 (decisions #100327 puis #100328) :
/// UNE BORNE DE SAISIE ATTRAPE UNE FAUTE DE FRAPPE. Elle ne decide pas qui a
/// le droit d exister ni qui a le droit de randonner.
///
/// Les bornes precedentes (8-100 ans, 100-250 cm, 30-150 kg) jugeaient des
/// morphologies humaines REELLES : une personne de petite taille par
/// achondroplasie et un randonneur de 160 kg ne pouvaient pas creer leur
/// fiche. Cette gate existe pour qu on ne puisse plus les re-exclure sans
/// qu un test tombe, et elle a trois roles distincts :
///
/// 1. VALEURS EPINGLEES — les six constantes sont ecrites en toutes lettres
///    ici. Les resserrer redevient un acte DELIBERE, jamais un effet de bord.
/// 2. PERSONNES REELLES — des profils humains attestes passent la porte.
/// 3. COHERENCE DU MESSAGE — les 5 fichiers i18n citent les bornes en toutes
///    lettres. Un ecran qui annonce une borne que le code n applique pas est
///    un mensonge affiche a l utilisateur : le message doit citer les valeurs
///    REELLEMENT en vigueur, dans les 5 langues.
void main() {
  group('valeurs epinglees — un resserrement doit etre delibere', () {
    test('age 18-120, taille 60-255 cm, poids 25-200 kg', () {
      expect(kAgeMin, 18, reason: 'majorite (decision Chris #100327)');
      expect(kAgeMax, 120, reason: 'record humain documente : 122 ans');
      expect(kHeightMinCm, 60);
      expect(kHeightMaxCm, 255,
          reason: 'le plus grand homme vivant mesure 251 cm');
      expect(kWeightMinKg, 25);
      expect(kWeightMaxKg, 200,
          reason: 'au-dela on ne marche plus un sentier (#100328)');
    });
  });

  group('des personnes reelles passent la porte', () {
    test('un adulte de petite taille (1 m 30) est accepte', () {
      // #100327 : « les nains n ont pas le droit de faire de GR ». Une borne
      // de saisie n a pas a juger une morphologie humaine reelle.
      expect(130 >= kHeightMinCm && 130 <= kHeightMaxCm, isTrue);
      expect(liveBmiWithinBounds(130, 42), isNotNull);
    });

    test('un randonneur de 160 kg est accepte', () {
      // La vraie exclusion de l application : l ancien plafond de 150 kg
      // ecartait ceux pour qui le dispositif de charge du sac vaut le plus.
      expect(isValidBodyWeightKg(160), isTrue);
      expect(isValidBodyWeightKg(200), isTrue, reason: 'borne haute incluse');
      expect(liveBmiWithinBounds(178, 160), isNotNull);
    });

    test('un randonneur de 90 ans et un homme de 251 cm sont acceptes', () {
      expect(90 >= kAgeMin && 90 <= kAgeMax, isTrue);
      expect(251 <= kHeightMaxCm, isTrue);
      expect(liveBmiWithinBounds(251, 180), isNotNull);
    });

    test('un poids de 25 kg reste accepte (borne basse incluse)', () {
      expect(isValidBodyWeightKg(25), isTrue);
    });
  });

  group('les fautes de frappe sont toujours attrapees', () {
    test('les saisies signalees par Chris restent refusees', () {
      // 8000 et 600000 cm, 3261 kg : les frappes reelles du rapport personas.
      expect(liveBmiWithinBounds(8000, 70), isNull);
      expect(liveBmiWithinBounds(600000, 70), isNull);
      expect(isValidBodyWeightKg(3261), isFalse);
      expect(liveBmiWithinBounds(175, 3261), isNull);
    });

    test('Infinity, NaN, zero et negatif restent refuses', () {
      // `double.tryParse('Infinity')` rendait `double.infinity`, affiche tel
      // quel dans le bandeau du sac (finding B1).
      expect(isValidBodyWeightKg(double.infinity), isFalse);
      expect(isValidBodyWeightKg(double.nan), isFalse);
      expect(isValidBodyWeightKg(0), isFalse);
      expect(isValidBodyWeightKg(-50), isFalse);
      expect(isValidBodyWeightKg(1e9), isFalse);
    });

    test('juste sous et juste au-dessus des bornes', () {
      expect(isValidBodyWeightKg(kWeightMinKg - 0.1), isFalse);
      expect(isValidBodyWeightKg(kWeightMaxKg + 0.1), isFalse);
      expect(liveBmiWithinBounds(kHeightMinCm - 1, 70), isNull);
      expect(liveBmiWithinBounds(kHeightMaxCm + 1, 70), isNull);
      expect(liveBmiWithinBounds(kHeightMinCm, kWeightMinKg.toDouble()),
          isNotNull);
      expect(liveBmiWithinBounds(kHeightMaxCm, kWeightMaxKg.toDouble()),
          isNotNull);
    });
  });

  group('les 5 langues citent les bornes REELLEMENT en vigueur', () {
    // Les messages d erreur ecrivent les bornes en toutes lettres (« Age
    // invalide (18 a 120 ans) »). Si une constante bouge sans que le texte
    // suive, l ecran annonce une regle que le code n applique pas.
    const langues = <String>['fr', 'de', 'es', 'it', 'en'];
    const attendu = <String, List<int>>{
      'errorAge': <int>[kAgeMin, kAgeMax],
      'errorHeight': <int>[kHeightMinCm, kHeightMaxCm],
      'errorWeight': <int>[kWeightMinKg, kWeightMaxKg],
    };

    for (final langue in langues) {
      test('$langue — les 3 messages citent les bonnes valeurs', () {
        final fichier = File('assets/i18n/$langue.i18n.json');
        expect(fichier.existsSync(), isTrue,
            reason: 'fichier i18n introuvable : ${fichier.path}');

        final racine =
            jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
        final profil = racine['hikerProfile'] as Map<String, dynamic>;

        attendu.forEach((cle, bornes) {
          final message = profil[cle] as String;
          for (final borne in bornes) {
            expect(message.contains('$borne'), isTrue,
                reason: '$langue / hikerProfile.$cle doit citer $borne — '
                    'message affiche : « $message »');
          }
        });
      });
    }
  });
}
