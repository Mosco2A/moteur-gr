/// LE SEPARATEUR DECIMAL SE LIT DANS LA LANGUE (tache 835, lots A3 et A4).
///
/// CE QUI ETAIT MESURE A L'ECRAN AVANT CE LOT : « 19.9 km », « 27.0 Mo »,
/// « 2.7 km/h », « 1.6 % ». Quatre nombres CALCULES, quatre points decimaux,
/// dans une application francaise dont les textes ecrits a la main etaient deja
/// justes (les fiches conseils ecrivent bien « 0,5 a 1 litre par heure »).
///
/// ET POUR LES DUREES : « 5 H 3 » au lieu de « 5 H 03 », parce que trois
/// ecrans recalculaient `inMinutes.remainder(60)` a la main sans zero-padder,
/// alors que onze autres endroits du depot pensaient, eux, a le faire.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/core/utils/nombre_en_clair.dart';

void main() {
  group('nombreEnClair — le separateur suit la langue (835)', () {
    // LES QUATRE SYMPTOMES EXACTS DU SIGNALEMENT, UN TEST CHACUN.
    test('les quatre nombres du signalement s ecrivent a la francaise', () {
      expect(nombreEnClair(19.9, 'fr'), '19,9'); // « 19.9 km »
      expect(nombreEnClair(27.0, 'fr'), '27,0'); // « 27.0 Mo »
      expect(nombreEnClair(2.7, 'fr'), '2,7'); // « 2.7 km/h »
      expect(nombreEnClair(1.6, 'fr'), '1,6'); // « 1.6 % »
    });

    test('l anglais garde son point, et c est le fond du correctif', () {
      // Le reflexe `toStringAsFixed(1).replaceAll('.', ',')` aurait rendu
      // « 19,9 » a un anglophone : c est l anti-patron que la tache 806 avait
      // deja nomme pour l argent, et qu on ne rejoue pas ici.
      expect(nombreEnClair(19.9, 'en'), '19.9');
    });

    test('les trois autres langues du depot veulent la virgule', () {
      for (final langue in <String>['de', 'es', 'it']) {
        expect(
          nombreEnClair(19.9, langue),
          '19,9',
          reason: 'la langue $langue ecrit une virgule decimale',
        );
      }
    });

    test('le nombre de decimales est commande par l appelant', () {
      expect(nombreEnClair(19.94, 'fr', decimales: 0), '20');
      expect(nombreEnClair(19.94, 'fr', decimales: 2), '19,94');
    });

    test('un entier garde sa decimale demandee (27 Mo s ecrit 27,0)', () {
      // Le poids d une carte hors ligne passe par la : sans cela, « 27 » et
      // « 27,0 » alterneraient d un telephone a l autre.
      expect(nombreEnClair(27, 'fr'), '27,0');
    });

    test('zero et les negatifs ne cassent rien', () {
      expect(nombreEnClair(0, 'fr'), '0,0');
      expect(nombreEnClair(-3.5, 'fr'), '-3,5');
    });
  });

  group('formatDuree — les minutes sur deux chiffres (835)', () {
    // LE TEST QUI DONNE SON NOM AU LOT A3.
    test('cinq heures et trois minutes s ecrivent 5h03, jamais 5h3', () {
      expect(formatDuree(const Duration(hours: 5, minutes: 3)), '5h03');
    });

    test('une heure ronde n affiche pas de minutes', () {
      expect(formatDuree(const Duration(hours: 4)), '4h');
    });

    test('sous l heure, on ecrit les minutes seules', () {
      expect(formatDuree(const Duration(minutes: 45)), '45 min');
      expect(formatDuree(const Duration(minutes: 3)), '3 min');
      // Et surtout PAS « 0h03 », qui se lit mal et n etait pas ce que les
      // ecrans faisaient avant ce lot.
      expect(formatDuree(const Duration(minutes: 3)), isNot(contains('h')));
    });

    test('la minute pile et l heure pile sont les deux bornes', () {
      expect(formatDuree(const Duration(minutes: 59)), '59 min');
      expect(formatDuree(const Duration(minutes: 60)), '1h');
      expect(formatDuree(const Duration(minutes: 61)), '1h01');
    });

    test('une duree negative ne produit pas de texte absurde', () {
      expect(formatDuree(const Duration(minutes: -5)), '0 min');
    });

    test('une longue duree compte les heures sans les plafonner', () {
      expect(formatDuree(const Duration(hours: 30, minutes: 7)), '30h07');
    });
  });

  group('deuxChiffresDeMinutes — le zero que l ETA oubliait (835)', () {
    test('les minutes sous dix recoivent leur zero', () {
      expect(deuxChiffresDeMinutes(const Duration(hours: 5, minutes: 3)), '03');
      expect(deuxChiffresDeMinutes(const Duration(hours: 1)), '00');
    });

    test('les minutes a deux chiffres ne sont pas touchees', () {
      const deuxHeuresTrente = Duration(hours: 2, minutes: 30);
      expect(deuxChiffresDeMinutes(deuxHeuresTrente), '30');
      expect(deuxChiffresDeMinutes(const Duration(minutes: 59)), '59');
    });

    test('seules les minutes DANS l heure sont rendues', () {
      // 125 minutes = 2 h 05 : la fonction rend « 05 », pas « 125 ».
      expect(deuxChiffresDeMinutes(const Duration(minutes: 125)), '05');
    });
  });
}
