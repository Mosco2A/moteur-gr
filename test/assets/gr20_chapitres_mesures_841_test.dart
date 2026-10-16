import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/gr20_nord_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_sud_trail_config.dart';
import 'package:moteur_gr/core/config/gr20_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/models/stage_duration.dart';
import 'package:moteur_gr/domain/nuit_possible.dart';

/// LA GARDE DES CHAPITRES : AUCUN CHIFFRE N EST SAISI, ET AUCUN N EST REMESURE
/// (tache 841).
///
/// CE QUE CE FICHIER EMPECHE. La tache 839 a pose une regle qui a coute une
/// journee a etablir : les chiffres du GR20 sont LUS sur la trace, jamais
/// recales. Publier deux chapitres ouvrait un chemin pour la perdre en silence
/// — remesurer la moitie nord avec un autre outil, ou pire, saisir « environ
/// 92 km » dans une configuration. Deux mesures du meme terrain finissent
/// toujours par divergier.
///
/// LA REPONSE N EST PAS UNE SECONDE MESURE, C EST UN DECOUPAGE.
/// `tool/gr20_chapitres.py` ne mesure RIEN : il decoupe les fichiers deja
/// mesures en tache 839. Les cas ci-dessous ferment la boucle : ils relisent
/// `assets/data/gr20/chapitres.json`, les donnees de chaque chapitre, et les
/// trois configurations, et refusent toute divergence entre elles — et avec le
/// sentier mere.
///
/// LE CAS LE PLUS IMPORTANT EST « RIEN NE SE PERD ». Neuf plus sept etapes font
/// seize ; les deux longueurs font la trace entiere au metre ; les deux
/// deniveles font celui du sentier ; les nuits et les segments se repartissent
/// a l unite. C est ce cas qui a trouve un vrai defaut pendant la fabrication :
/// une premiere version du decoupage additionnait les longueurs d etape pour
/// borner les chapitres, et perdait SIX KILOMETRES de segments au sud sur trois
/// metres d arrondi.
void main() {
  Map<String, dynamic> lireJson(String chemin) {
    final file = File(chemin);
    expect(file.existsSync(), isTrue, reason: '$chemin absent');
    return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  }

  List<Map<String, dynamic>> lireListe(String chemin) {
    final file = File(chemin);
    expect(file.existsSync(), isTrue, reason: '$chemin absent');
    return (jsonDecode(file.readAsStringSync()) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> manifeste() =>
      lireJson('assets/data/gr20/chapitres.json');

  Map<String, dynamic> chapitreDit(String id) =>
      (manifeste()['chapitres'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .firstWhere((c) => c['id'] == id);

  DecoupageDeNuits lireNuits(String id) => DecoupageDeNuits.fromJson(
    lireJson('assets/data/$id/nuits_possibles.json'),
  );

  group('LE DECOUPAGE EST A VIZZAVONA, ET IL EST COMPTE', () {
    test('la coupe est le lieu que Christophe a nomme, et un seul', () {
      final m = manifeste();
      // « vizzavona pardon, c'est la que ca se decoupe et seulement la »
      // (Christophe, 15/10 17:58).
      expect(m['lieuDeLaCoupe'], 'Vizzavona');
      expect(m['parentTrailId'], 'gr20');
      expect(m['etapesDuSentierMere'], gr20TrailConfig.totalStages);
      // LE RANG DE LA COUPE EST NEUF, ET IL EST TROUVE PAR LE NOM. L ancienne
      // application coupait a huit, c est-a-dire au refuge de l Onda, une
      // journee entiere AVANT Vizzavona, sans gare et sans lit hors dortoir.
      expect(m['etapeDArriveeDeLaCoupe'], 9);
      final etapesMeres = lireListe('assets/data/gr20/stages.json');
      expect(etapesMeres[8]['arrivalName'], 'Vizzavona');
      // ET UN SEUL LIEU PORTE CE NOM : sinon la coupe serait ambigue.
      expect(
        etapesMeres
            .where((e) => (e['arrivalName'] as String) == 'Vizzavona')
            .length,
        1,
      );
      expect((m['chapitres'] as List<dynamic>).length, 2);
    });

    test('DEUX CHAPITRES, ET RIEN NE SE PERD ENTRE EUX', () {
      final nord = chapitreDit('gr20-nord');
      final sud = chapitreDit('gr20-sud');

      // LES ETAPES : neuf plus sept font seize, et aucune journee n est
      // partagee entre deux chapitres voisins (regle CH-9).
      expect(nord['etapes'], 9);
      expect(sud['etapes'], 7);
      expect(
        (nord['etapes'] as int) + (sud['etapes'] as int),
        gr20TrailConfig.totalStages,
      );
      expect(nord['premiereEtapeDuSentierMere'], 1);
      expect(nord['derniereEtapeDuSentierMere'], 9);
      expect(sud['premiereEtapeDuSentierMere'], 10);
      expect(sud['derniereEtapeDuSentierMere'], 16);

      // LES BOUTS : Calenzana, Vizzavona, Conca. La coupe est l arrivee de
      // l un et le depart de l autre.
      expect(nord['depart'], 'Calenzana');
      expect(nord['arrivee'], 'Vizzavona');
      expect(sud['depart'], 'Vizzavona');
      expect(sud['arrivee'], 'Conca');

      // LES LONGUEURS : la somme fait celle du sentier entier, au centieme.
      final kmNord = (nord['distanceKm'] as num).toDouble();
      final kmSud = (sud['distanceKm'] as num).toDouble();
      expect(
        kmNord + kmSud,
        closeTo(gr20TrailConfig.totalDistanceKm, 0.01),
        reason: 'decouper ne cree ni ne perd de kilometre',
      );
      // VIZZAVONA TOMBE A 50,0 % DE LA TRACE : dix metres d ecart entre les
      // deux moities. Ce n est pas un arrangement, c est une propriete du
      // sentier.
      expect((kmNord - kmSud).abs(), lessThan(0.02));

      // LES POINTS KILOMETRIQUES SE SUIVENT SANS TROU NI CHEVAUCHEMENT : le
      // sud part exactement ou le nord s arrete.
      expect(nord['pkDepartDansLeSentierMere'], 0.0);
      expect(
        sud['pkDepartDansLeSentierMere'],
        nord['pkArriveeDansLeSentierMere'],
      );
      expect(
        (sud['pkArriveeDansLeSentierMere'] as num).toDouble(),
        closeTo(183.585, 0.01),
      );

      // LE DENIVELE : la somme fait celui du sentier entier, au metre.
      expect(
        (nord['deniveleM'] as int) + (sud['deniveleM'] as int),
        gr20TrailConfig.totalElevationGain,
      );
      // MAIS IL N EST PAS PARTAGE, ET C EST LA QUE SE LIT LA DIFFICULTE : le
      // nord porte 1,74 fois le D+ du sud pour la MEME distance. Deux
      // chapitres de meme prix ne sont pas deux chapitres de meme effort.
      expect(
        (nord['deniveleM'] as int) / (sud['deniveleM'] as int),
        greaterThan(1.5),
      );
    });

    test(
      'LES CHIFFRES DU MANIFESTE SONT CEUX DU SENTIER MERE, pas une relecture',
      () {
        // LE MANIFESTE EST LE DECOUPAGE DE LA MESURE 839, et les parcours NORD
        // et SUD de `gr20.json` sont cette mesure. Les deux doivent coincider
        // EXACTEMENT : si quelqu un remesurait les chapitres un jour, c est ce
        // cas qui rougirait.
        final parcours =
            (lireJson('assets/data/gr20.json')['itineraries'] as List<dynamic>)
                .cast<Map<String, dynamic>>();
        for (final code in ['NORD', 'SUD']) {
          final p = parcours.firstWhere((x) => x['code'] == code);
          final c = chapitreDit('gr20-${code.toLowerCase()}');
          expect(c['etapes'], p['stageCount'], reason: '$code : etapes');
          expect(c['distanceKm'], p['distanceKm'], reason: '$code : longueur');
          expect(
            c['deniveleM'],
            p['elevationGain'],
            reason: '$code : denivele',
          );
        }
      },
    );
  });

  group('CHAQUE CHAPITRE EST UN SENTIER COMPLET (regle CH-11)', () {
    for (final (id, config) in <(String, TrailConfig)>[
      ('gr20-nord', gr20NordTrailConfig),
      ('gr20-sud', gr20SudTrailConfig),
    ]) {
      test('$id : la configuration ne dit rien que la mesure ne dise', () {
        final dit = chapitreDit(id);
        final etapes = lireListe('assets/data/$id/stages.json');

        expect(etapes.length, config.totalStages);
        expect(dit['etapes'], config.totalStages);
        expect(
          etapes.fold<double>(
            0,
            (s, e) => s + (e['distanceKm'] as num).toDouble(),
          ),
          closeTo(config.totalDistanceKm, 0.01),
        );
        expect(
          etapes.fold<int>(
            0,
            (s, e) => s + (e['elevationGainM'] as num).round(),
          ),
          config.totalElevationGain,
        );
        // LE PRIX EST LE NOMBRE D ETAPES, et le manifeste le dit lui aussi.
        expect(dit['prixEnEtapes'], config.totalStages);
        expect(config.priceInStages, config.totalStages);
      });

      test(
        '$id : ses etapes sont RENUMEROTEES de un a n, et portent son id',
        () {
          final etapes = lireListe('assets/data/$id/stages.json');
          for (var i = 0; i < etapes.length; i++) {
            expect(etapes[i]['stageNumber'], i + 1);
            expect(etapes[i]['trailId'], id);
            expect(etapes[i]['id'], '$id-s${i + 1}');
            // LA DESCRIPTION SUIT LA RENUMEROTATION. Sans cela, la quatrieme
            // etape du sud se presenterait comme la treizieme du GR20.
            expect(
              etapes[i]['descriptionFr'] as String,
              startsWith('Etape ${i + 1} du'),
            );
          }
          // Les etapes se suivent sans trou : la fin de l une EST le depart de
          // la suivante.
          for (var i = 1; i < etapes.length; i++) {
            expect(etapes[i]['startLat'], etapes[i - 1]['endLat']);
            expect(etapes[i]['startLng'], etapes[i - 1]['endLng']);
          }
        },
      );

      test('$id : les durees sortent du MODELE UNIQUE du depot', () {
        // La meme garde que la tache 839, appliquee au chapitre : une duree
        // est calculee, jamais saisie.
        for (final e in lireListe('assets/data/$id/stages.json')) {
          expect(
            e['estimatedDurationMinutes'],
            estimatedStageDurationMinutes(
              distanceKm: (e['distanceKm'] as num).toDouble(),
              elevationGainM: (e['elevationGainM'] as num).round(),
              elevationLossM: (e['elevationLossM'] as num).round(),
            ),
            reason: 'etape ${e['stageNumber']} de $id',
          );
        }
      });

      test('$id : il a SA TRACE, et elle ne contient pas celle du voisin', () {
        final gpx = File('assets/data/$id/track.gpx');
        expect(gpx.existsSync(), isTrue);
        expect(config.gpxAssetPath, 'assets/data/$id/track.gpx');
        final texte = gpx.readAsStringSync();
        final points = RegExp('<trkpt ').allMatches(texte).length;
        final altitudes = RegExp('<ele>').allMatches(texte).length;
        // AUCUNE ALTITUDE MANQUANTE, comme sur la trace mere : c est la regle
        // de la tache 837, et le decoupage ne la relache pas.
        expect(points, altitudes);
        expect(points, chapitreDit(id)['pointsDeTrace']);
        // ET IL EN A MOINS QUE LE SENTIER ENTIER : un randonneur qui achete le
        // nord ne telecharge pas le sud.
        expect(points, lessThan(9128));
        expect(points, greaterThan(4000));
      });

      test(
        '$id : ses nuits sont celles du sentier, restreintes et remises a zero',
        () {
          final nuits = lireNuits(id);
          expect(nuits.trailId, id);
          expect(config.possibleNightsAssetPath, isNotNull);
          expect(nuits.nuits.length, chapitreDit(id)['nuits']);
          // LA SOMME DES SEGMENTS EST LA LONGUEUR DE LA TRANCHE DE TRACE. C est
          // ce cas qui a trouve le defaut des bornes sommees : il manquait six
          // kilometres au sud.
          final kmSegments = nuits.segments.fold<double>(0, (s, x) => s + x.km);
          final json = lireJson('assets/data/$id/nuits_possibles.json');
          expect(
            kmSegments,
            closeTo((json['longueur_km'] as num).toDouble(), 0.01),
          );
          // LE PREMIER SEGMENT PART DU DEPART DU CHAPITRE, point kilometrique
          // remis a zero.
          expect(
            (json['entre_les_nuits'] as List<dynamic>).first
                as Map<String, dynamic>,
            containsPair('pk_depart_km', 0.0),
          );
          expect(nuits.segments.first.rang, 1);
          // CHAQUE NUIT PORTE SON IDENTIFIANT OPENSTREETMAP, et son temps de
          // detour reste sous le seuil du releve.
          for (final n in nuits.nuits) {
            expect(n.osm, isNotEmpty, reason: '${n.nom} de $id');
            for (final osm in n.osm) {
              expect(osm, matches(RegExp(r'^(node|way|relation)/\d+$')));
            }
            expect(n.minutesAller, lessThanOrEqualTo(30));
            expect(n.minutesRetour, lessThanOrEqualTo(30));
            if (n.lits != null) expect(n.lits, greaterThan(0));
          }
        },
      );

      test('$id : son fichier monolithique a UN parcours, le sien', () {
        final mono = lireJson('assets/data/$id.json');
        expect(config.accommodationsAssetPath, 'assets/data/$id.json');
        expect((mono['trail_meta'] as Map)['id'], id);
        // IL DIT DE QUI IL EST LE CHAPITRE, et cela ne sert qu a le ranger.
        expect((mono['trail_meta'] as Map)['parentTrailId'], 'gr20');
        // UN SEUL PARCOURS : le sentier mere en porte trois parce qu il est un
        // REFERENTIEL ; un produit qui proposerait trois parcours dont deux ne
        // sont pas a vendre ne serait pas un produit.
        final itineraires = (mono['itineraries'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(itineraires.length, 1);
        expect(itineraires.single['stageCount'], config.totalStages);
        expect((mono['stages'] as List<dynamic>).length, config.totalStages);
        // LES COUCHAGES ET LES REPERES PORTENT L IDENTIFIANT DU CHAPITRE et
        // gardent leur identifiant OpenStreetMap — un couchage sans identifiant
        // est inverifiable.
        final couchages = (mono['accommodations'] as List<dynamic>)
            .cast<Map<String, dynamic>>();
        expect(couchages, isNotEmpty);
        for (final c in couchages) {
          expect(
            c['id'] as String,
            matches(RegExp('^$id-(node|way|relation)-\\d+\$')),
          );
          if (c['capacity'] != null) {
            expect(c['capacity'] as num, greaterThan(0));
          }
        }
      });
    }

    test('LES DEUX CHAPITRES SE PARTAGENT LES NUITS DU SENTIER, A L UNITE', () {
      final mere = DecoupageDeNuits.fromJson(
        lireJson('assets/data/gr20/nuits_possibles.json'),
      );
      final nord = lireNuits('gr20-nord');
      final sud = lireNuits('gr20-sud');
      // TRENTE ET UNE NUITS, QUINZE PLUS SEIZE. Vizzavona est l ARRIVEE du
      // nord — donc une de ses nuits — et le DEPART du sud — donc pas une des
      // siennes. C est ce qui garantit qu aucune ne se perd ni ne compte deux
      // fois.
      expect(mere.nuits.length, 31);
      expect(nord.nuits.length + sud.nuits.length, mere.nuits.length);
      expect(nord.segments.length + sud.segments.length, mere.segments.length);
      expect(nord.nuits.last.nom, contains('Vizzavona'));
      expect(sud.nuits.last.nom, 'Conca');
      // LES DEUX TRANCHES DE TRACE FONT LA TRACE ENTIERE, AU METRE.
      final kmNord = nord.segments.fold<double>(0, (s, x) => s + x.km);
      final kmSud = sud.segments.fold<double>(0, (s, x) => s + x.km);
      expect(kmNord + kmSud, closeTo(183.585, 0.01));
    });
  });

  group('LE SENTIER MERE RESTE UNE REFERENCE, ET N EST PLUS UN PRODUIT', () {
    test(
      'le catalogue montre les chapitres, le referentiel garde le sentier',
      () {
        expect(TrailCatalog.ids, containsAll(['gr20-nord', 'gr20-sud']));
        expect(TrailCatalog.ids, isNot(contains('gr20')));
        expect(TrailCatalog.referentiel.map((c) => c.id), contains('gr20'));
        expect(TrailCatalog.byId('gr20'), isNotNull);
        expect(gr20TrailConfig.aDesChapitres, isTrue);
        expect(gr20TrailConfig.estVendable, isFalse);
        expect(gr20TrailConfig.chapterIds, ['gr20-nord', 'gr20-sud']);
      },
    );

    test(
      'les chapitres sont vendables, et ils disent DE QUI ils sont chapitres',
      () {
        for (final c in [gr20NordTrailConfig, gr20SudTrailConfig]) {
          expect(c.estChapitre, isTrue);
          expect(c.parentTrailId, 'gr20');
          expect(c.aDesChapitres, isFalse);
          expect(c.estVendable, isTrue);
          expect(c.isFictional, isFalse);
          expect(c.isFreeTrail, isFalse);
          // LES SECOURS SONT LES MEMES QUE CEUX DU SENTIER, et c est la MEME
          // constante : un numero de secours recopie finit par divergier, et un
          // numero de secours perime est le pire chiffre faux de l application.
          expect(c.emergencyNumbers, same(gr20TrailConfig.emergencyNumbers));
        }
      },
    );

    test('AUCUN AUTRE SENTIER DU CATALOGUE N A DE CHAPITRES', () {
      // Le GR20 est le SEUL cas, et c est une exception declaree : chaque
      // moitie fait neuf ou sept etapes, au-dessus des cinq a six jours de la
      // regle CH-1. Si un autre sentier gagnait des chapitres un jour, ce cas
      // le dirait plutot que de laisser la regle se relacher en silence.
      expect(TrailCatalog.sentiersMeres.map((c) => c.id), ['gr20']);
      for (final c in TrailCatalog.all) {
        expect(c.aDesChapitres, isFalse, reason: c.id);
      }
    });
  });
}
