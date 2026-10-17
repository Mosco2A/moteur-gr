import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';

/// LA GARDE DES CHIFFRES DU GR20 : AUCUN N'EST SAISI A LA MAIN (tache 839).
///
/// CE QUE CE FICHIER EMPECHE, ET POURQUOI IL EXISTE. L'ancienne application
/// GR20 portait seize longueurs d'etape venues d'un TOPO puis multipliees par
/// 1,069 pour que leur somme tombe sur les 183 km annonces ; son propre code
/// l'avouait en commentaire. Le total etait juste et les etapes fausses —
/// jusqu'a 62 % d'ecart sur l'etape 13. Rien n'empechait ce genre de recalage,
/// parce que rien ne reliait un chiffre affiche a une mesure.
///
/// Ces cas-ci font ce lien. Ils relisent `assets/data/gr20/stages.json` et
/// `assets/data/gr20/nuits_possibles.json` — produits par
/// `python tool/gr20_dans_stepways.py` depuis `assets/data/gr20/track.gpx` — et
/// refusent toute divergence avec [gr20TrailConfig], avec l'ordre de la trace,
/// et avec LE modele de temps de marche du depot. Un chiffre modifie a la main
/// quelque part fait rougir ce fichier.
void main() {
  List<Map<String, dynamic>> lireEtapes() {
    final file = File('assets/data/gr20/stages.json');
    expect(file.existsSync(), isTrue, reason: 'stages.json du GR20 absent');
    return (jsonDecode(file.readAsStringSync()) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> lireSentier() {
    final file = File('assets/data/gr20.json');
    expect(file.existsSync(), isTrue, reason: 'gr20.json absent');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  DecoupageDeNuits lireNuits() {
    final file = File('assets/data/gr20/nuits_possibles.json');
    expect(file.existsSync(), isTrue, reason: 'nuits_possibles.json absent');
    return DecoupageDeNuits.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  group('LES SEIZE ETAPES SONT MESUREES SUR LA TRACE', () {
    test('la configuration ne dit rien que la mesure ne dise', () {
      final etapes = lireEtapes();
      expect(etapes.length, gr20TrailConfig.totalStages);

      final km = etapes.fold<double>(
        0,
        (s, e) => s + (e['distanceKm'] as num).toDouble(),
      );
      final dplus = etapes.fold<int>(
        0,
        (s, e) => s + (e['elevationGainM'] as num).round(),
      );
      // LA GARDE EST ICI : le total de la config EST la somme des etapes
      // mesurees, a l'arrondi du centieme de kilometre pres.
      expect(km, closeTo(gr20TrailConfig.totalDistanceKm, 0.01));
      expect(dplus, gr20TrailConfig.totalElevationGain);
    });

    test(
      'AUCUN COEFFICIENT : la somme des etapes EST la longueur de la trace',
      () {
        final etapes = lireEtapes();
        final nuits = lireNuits();
        final km = etapes.fold<double>(
          0,
          (s, e) => s + (e['distanceKm'] as num).toDouble(),
        );
        // La trace mesure 183,585 km. Les etapes en sont des TRANCHES : leur
        // somme ne peut donc s'en ecarter que de l'arrondi. Un recalage du
        // genre « x1,069 » ferait exploser cet ecart (il valait 9 km sur
        // l'ancienne application).
        expect(km, closeTo(183.585, 0.02));
        // Les points kilometriques se suivent sans trou ni chevauchement.
        for (var i = 1; i < etapes.length; i++) {
          final finPrecedente = etapes[i - 1]['endLat'] as num;
          expect(etapes[i]['startLat'], finPrecedente);
        }
        expect(nuits.segments.length, 31);
      },
    );

    test('LES DUREES SORTENT DU MODELE UNIQUE, pas d une saisie', () {
      for (final e in lireEtapes()) {
        final attendu = estimatedStageDurationMinutes(
          distanceKm: (e['distanceKm'] as num).toDouble(),
          elevationGainM: (e['elevationGainM'] as num).round(),
          elevationLossM: (e['elevationLossM'] as num).round(),
        );
        expect(
          e['estimatedDurationMinutes'],
          attendu,
          reason:
              'etape ${e['stageNumber']} : la duree de la donnee doit etre '
              'celle du modele de marche du depot, a la minute',
        );
      }
    });
  });

  group('L ORDRE DE LA TRACE, ET LES BORNES DES DEUX PARCOURS', () {
    test('BAVELLA AVANT PALIRI — 9,06 km ne sont plus marches deux fois', () {
      final etapes = lireEtapes();
      final arrivees = etapes
          .map((e) => e['arrivalName'] as String)
          .toList(growable: false);
      final bavella = arrivees.indexWhere((n) => n.contains('Bavella'));
      final paliri = arrivees.indexWhere((n) => n.contains('Paliri'));
      expect(bavella, greaterThanOrEqualTo(0));
      expect(paliri, greaterThanOrEqualTo(0));
      expect(
        bavella,
        lessThan(paliri),
        reason:
            'sur la trace, le col de Bavella est au PK 165,84 et Paliri au '
            'PK 170,38 : l ordre inverse faisait parcourir 9,06 km deux fois',
      );
      expect(arrivees.last, 'Conca');
    });

    test('LE NORD NE DEPOSE PLUS PERSONNE A L ONDA', () {
      final etapes = lireEtapes();
      // L'ancien code declarait le nord sur les etapes 1 a 8 « jusqu a
      // Vizzavona ». L'etape 8 finit a l'Onda, PK 81,59, une journee entiere
      // AVANT Vizzavona (PK 91,80). La liste le dit, et ce cas le fige.
      expect(etapes[7]['arrivalName'], "l'Onda");
      expect(etapes[8]['arrivalName'], 'Vizzavona');
    });

    test('NEUF ETAPES AU NORD, SEPT AU SUD — comptees, jamais ecrites', () {
      final parcours = (lireSentier()['itineraries'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      final nord = parcours.firstWhere((p) => p['code'] == 'NORD');
      final sud = parcours.firstWhere((p) => p['code'] == 'SUD');
      final integral = parcours.firstWhere((p) => p['code'] == 'NS');

      expect(nord['stageCount'], 9);
      expect(sud['stageCount'], 7);
      expect(integral['stageCount'], gr20TrailConfig.totalStages);
      expect(nord['stageCount'] + sud['stageCount'], integral['stageCount']);

      // VIZZAVONA TOMBE A 50,0 % DE LA TRACE : les deux moities sont egales a
      // dix metres pres, et c'est une propriete du sentier, pas un arrangement.
      final kmNord = (nord['distanceKm'] as num).toDouble();
      final kmSud = (sud['distanceKm'] as num).toDouble();
      expect((kmNord - kmSud).abs(), lessThan(0.02));
      expect(kmNord + kmSud, closeTo(integral['distanceKm'] as num, 0.01));

      // MAIS LE DENIVELE N'EST PAS PARTAGE : le nord porte ~1,74 fois le D+ du
      // sud pour la meme distance. C'est la que se lit la difficulte.
      final dNord = (nord['elevationGain'] as num).toDouble();
      final dSud = (sud['elevationGain'] as num).toDouble();
      expect(dNord / dSud, greaterThan(1.5));
    });
  });

  group('LES TRENTE ET UNE NUITS OUVERTES AU DECOUPAGE', () {
    test('trente et une nuits, seize fins d etape et quinze coupures', () {
      final nuits = lireNuits();
      expect(nuits.nuits.length, 31);
      expect(nuits.nuits.where((n) => n.estFinDEtape).length, 16);
      expect(nuits.coupuresNouvelles.length, 15);
      expect(nuits.journeesMaximales, 31);
      expect(nuits.trailId, gr20TrailConfig.id);
    });

    test('CHAQUE NUIT PORTE SON IDENTIFIANT OPENSTREETMAP', () {
      for (final n in lireNuits().nuits) {
        expect(
          n.osm,
          isNotEmpty,
          reason:
              '${n.nom} : une nuit sans identifiant OpenStreetMap est une '
              'nuit qu on ne peut pas verifier',
        );
        for (final id in n.osm) {
          expect(id, matches(RegExp(r'^(node|way|relation)/\d+$')));
        }
      }
    });

    test(
      'LE TEMPS DU DETOUR EST DIT DANS LES DEUX SENS, et il est asymetrique',
      () {
        final nuits = lireNuits();
        // Le releve 838 a calcule l'aller et le retour SEPAREMENT. Le refuge
        // Laparo le justifie a lui seul : 10 minutes a l'aller, 28 au retour.
        final laparo = nuits.nuits.firstWhere((n) => n.nom.contains('Laparo'));
        expect(laparo.minutesAller, 10);
        expect(laparo.minutesRetour, 28);
        expect(laparo.lits, 6);
        // Aucun detour ne depasse le seuil de trente minutes du releve.
        for (final n in nuits.nuits) {
          expect(n.minutesAller, lessThanOrEqualTo(30));
          expect(n.minutesRetour, lessThanOrEqualTo(30));
        }
        // Les lits, QUAND ILS SONT CONNUS : jamais un zero pour « on ne sait
        // pas ». Au moins la moitie des nuits les connait.
        expect(
          nuits.nuits.where((n) => n.lits != null).length,
          greaterThan(15),
        );
        for (final n in nuits.nuits) {
          if (n.lits != null) expect(n.lits, greaterThan(0));
        }
      },
    );

    test('LES SEGMENTS SONT MESURES, et leur somme EST la trace', () {
      final segments = lireNuits().segments;
      final km = segments.fold<double>(0, (s, x) => s + x.km);
      expect(km, closeTo(183.585, 0.01));
      for (final s in segments) {
        expect(s.km, greaterThan(0));
        expect(
          s.minutes,
          (walkingSeconds(
                    distanceMetres: s.km * 1000,
                    ascentMetres: s.deniveleM.toDouble(),
                    descentMetres: s.descenteM.toDouble(),
                  ) /
                  60)
              .round(),
          reason:
              'segment ${s.rang} : la duree doit venir du modele unique, '
              'jamais d une saisie',
        );
      }
    });
  });

  group('LE SENTIER EST AU REFERENTIEL, SES CHAPITRES AU CATALOGUE', () {
    test(
      'le GR20 est connu, et il ne prend pas la place du sentier de depart',
      () {
        // CE CAS A CHANGE AVEC LA TACHE 841, ET C EST LA REGLE QUI A CHANGE,
        // PAS LA MESURE. Il verifiait que le GR20 figure au CATALOGUE. Depuis
        // la decision de Christophe du 15/10 17:45 — « on achete le sentier
        // seulement si il n y a pas de chapitres » — un sentier qui a des
        // chapitres n est plus un produit : il quitte le catalogue de vente et
        // reste au REFERENTIEL, parce que ses seize etapes portent la
        // numerotation de reference d ou ses chapitres sont decoupes et que
        // cette numerotation ne doit jamais bouger (regle CH-10).
        //
        // TOUS LES CHIFFRES DE CE FICHIER RESTENT CEUX-LA, ET C EST L ESSENTIEL
        // : le decoupage en chapitres ne remesure rien (cf.
        // `gr20_chapitres_mesures_841_test.dart`).
        expect(TrailCatalog.byId('gr20'), isNotNull);
        expect(TrailCatalog.referentiel.map((c) => c.id), contains('gr20'));
        expect(TrailCatalog.ids, isNot(contains('gr20')));
        expect(TrailCatalog.ids, containsAll(['gr20-nord', 'gr20-sud']));
        // L'application demarre toujours sur le meme sentier : le defaut est le
        // PREMIER du catalogue.
        expect(TrailCatalog.defaultTrail.id, 'mare-a-mare-centre');
        // Son prix reste deduit de ses etapes — le modele de vente n a pas
        // change, c est l UNITE de vente qui a change : seize etapes au
        // sentier, neuf plus sept a ses deux chapitres.
        expect(gr20TrailConfig.priceInStages, gr20TrailConfig.totalStages);
        expect(gr20TrailConfig.isFreeTrail, isFalse);
        expect(gr20TrailConfig.isFictional, isFalse);
        expect(gr20TrailConfig.aDesChapitres, isTrue);
        expect(gr20TrailConfig.estVendable, isFalse);
      },
    );

    test('les couchages releves portent leur identifiant dans leur id', () {
      final couchages = (lireSentier()['accommodations'] as List<dynamic>)
          .cast<Map<String, dynamic>>();
      expect(couchages.length, greaterThan(50));
      for (final c in couchages) {
        expect(
          c['id'] as String,
          matches(RegExp(r'^gr20-(node|way|relation)-\d+$')),
          reason: 'un couchage sans identifiant OpenStreetMap est invérifiable',
        );
        // La capacite est SOIT connue SOIT nulle — jamais zero pour
        // « inconnu ».
        final lits = c['capacity'];
        if (lits != null) expect(lits as num, greaterThan(0));
      }
    });
  });
}
