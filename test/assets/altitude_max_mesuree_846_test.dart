// GARDE — TACHE 846 : L'ALTITUDE MAXIMALE EST MESUREE SUR LA TRACE.
//
// POURQUOI CETTE GARDE EXISTE. [TrailConfig.maxAltitudeM] entre dans le calcul
// de la difficulte d'un sentier : sur le GR20, c'est ELLE qui emporte le
// verdict a l'allure federale, la moyenne y etant seulement moderee et la pire
// journee seulement difficile. Un nombre qui decide d'un verdict et que
// personne ne verifie est une affirmation — exactement ce que la tache 846
// cherche a retirer de la fiche.
//
// CE QUE CE FICHIER FAIT. Il relit les deux traces GPX embarquees, prend
// l'altitude la plus haute de leurs points, et refuse toute divergence avec la
// configuration. C'est le meme procede que la garde des chiffres du GR20
// (tache 839), appliquee a un chiffre de plus.
//
// POURQUOI UN ARRONDI A L'ENTIER ET PAS UNE EGALITE STRICTE. Les altitudes du
// GPX sont des decimaux (2 578,2 m sur le GR20) : la configuration porte des
// METRES, parce qu'un dixieme de metre d'altitude n'a aucun sens pour un
// randonneur et aucun effet sur un seuil espace de 500 m.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/mare_a_mare_centre_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_config.dart';

/// L'altitude la plus haute d'une trace GPX, lue sur ses balises `ele`.
double altitudeMaxDuGpx(String chemin) {
  final fichier = File(chemin);
  expect(fichier.existsSync(), isTrue, reason: 'trace absente : $chemin');
  final altitudes = RegExp(r'<ele>([-0-9.]+)</ele>')
      .allMatches(fichier.readAsStringSync())
      .map((m) => double.parse(m.group(1)!))
      .toList(growable: false);
  expect(
    altitudes,
    isNotEmpty,
    reason: 'la trace $chemin ne porte aucune altitude',
  );
  return altitudes.reduce((a, b) => a > b ? a : b);
}

void main() {
  group('846 — la configuration ne dit rien que la trace ne dise', () {
    test('GR20 : 2 578 m, mesures sur 9 128 points', () {
      final mesuree = altitudeMaxDuGpx(gr20TrailConfig.gpxAssetPath);
      expect(gr20TrailConfig.maxAltitudeM, mesuree.round());
      expect(gr20TrailConfig.maxAltitudeM, 2578);
    });

    test('Mare a Mare Centre : 1 513 m, mesures sur 3 590 points', () {
      final mesuree = altitudeMaxDuGpx(mareAMareCentreTrailConfig.gpxAssetPath);
      expect(mareAMareCentreTrailConfig.maxAltitudeM, mesuree.round());
      expect(mareAMareCentreTrailConfig.maxAltitudeM, 1513);
    });

    test('un kilometre d altitude separe les deux sentiers du catalogue', () {
      // Ce n'est pas une coquetterie : c'est la raison pour laquelle
      // l'altitude est un critere A PART dans le calcul de la difficulte, et
      // non une consequence du denivele. Les deux sentiers ont des longueurs
      // voisines (183,59 km et 87,3 km) et des dix-septiemes de leur D+ en
      // commun, mais ils ne se marchent pas a la meme altitude.
      final ecart =
          gr20TrailConfig.maxAltitudeM! -
          mareAMareCentreTrailConfig.maxAltitudeM!;
      expect(ecart, 1065);
    });

    test('tout sentier du catalogue qui annonce une altitude la prouve', () {
      // LA GARDE EST GENERIQUE, et c'est ce qui la rend utile au PROCHAIN
      // sentier : elle ne nomme pas deux fichiers, elle parcourt le catalogue.
      // Un sentier qui arriverait demain avec une altitude ecrite a la main et
      // une trace qui dit autre chose ferait rougir ce cas sans qu'on ait rien
      // a ajouter ici.
      for (final TrailConfig sentier in TrailCatalog.all) {
        final annoncee = sentier.maxAltitudeM;
        if (annoncee == null) continue;
        final mesuree = altitudeMaxDuGpx(sentier.gpxAssetPath);
        expect(
          annoncee,
          mesuree.round(),
          reason:
              '${sentier.id} annonce $annoncee m alors que sa trace monte a '
              '${mesuree.round()} m',
        );
      }
    });
  });
}
