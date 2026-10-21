// GARDE — TACHE 860 : LE PLAN PAR DEFAUT DES TROIS PRODUITS TIENT DANS SEPT
// A HUIT JOURS DE MARCHE.
//
// POURQUOI CE N'EST PAS UN REGLAGE COSMETIQUE. Le sentier entier ouvrait sur
// SEIZE jours, soit une etape par jour : c'est le decoupage du topoguide, pas
// un plan de marche. Et seize jours est le plan le PLUS FACILE de toute la
// serie — le defaut montrait donc au client la version la plus douce du GR20
// et lui laissait decouvrir le reste en deplacant le curseur. Le chapitre
// nord ouvrait sur neuf jours, son allure etalee, pour la meme raison.
//
// CE QUE LA NOTATION EXIGE. La note sur vingt est posee sur la JOURNEE, et
// une journee n'existe qu'une fois le sentier decoupe. Le decoupage par
// defaut n'est donc plus un confort d'affichage : c'est LUI qui decide la
// note que le client lit en premier. Le plan par defaut doit etre celui que
// le marcheur fait reellement, sinon la note est juste et hors sujet.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_nord_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_sud_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/trail_config.dart';

void main() {
  group('860 — sept a huit jours par defaut sur les trois produits', () {
    final produits = <String, TrailConfig>{
      'GR20 entier': gr20TrailConfig,
      'GR20 nord': gr20NordTrailConfig,
      'GR20 sud': gr20SudTrailConfig,
    };

    test('LE DEFAUT TIENT DANS LA FOURCHETTE SEPT-HUIT', () {
      for (final MapEntry(key: nom, value: config) in produits.entries) {
        expect(
          config.defaultDuration,
          inInclusiveRange(7, 8),
          reason:
              '$nom ouvre sur ${config.defaultDuration} jours : le plan par '
              'defaut decide la note que le client lit en premier, il doit '
              'donc etre le plan qu il marche',
        );
      }
    });

    test('LE SENTIER ENTIER OUVRE SUR HUIT, LES CHAPITRES SUR SEPT', () {
      // Huit sur l'entier et sept sur les chapitres : un chapitre est deux
      // fois plus court, son plan courant l'est aussi.
      expect(gr20TrailConfig.defaultDuration, 8, reason: 'GR20 entier');
      expect(gr20NordTrailConfig.defaultDuration, 7, reason: 'GR20 nord');
      expect(gr20SudTrailConfig.defaultDuration, 7, reason: 'GR20 sud');
    });

    test('LE DEFAUT EST TOUJOURS UNE ALLURE QUE LE SELECTEUR PROPOSE', () {
      // Un defaut absent de la serie laisserait le curseur ouvrir sur une
      // position qu'il ne sait pas afficher.
      for (final MapEntry(key: nom, value: config) in produits.entries) {
        expect(
          config.availableDurations,
          contains(config.defaultDuration),
          reason: '$nom : le defaut doit figurer dans les allures offertes',
        );
      }
    });
  });
}
