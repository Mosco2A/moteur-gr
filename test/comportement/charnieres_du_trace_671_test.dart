import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/geo/charnieres_du_trace.dart';
import 'package:moteur_gr/core/geo/geo_utils.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/geo/track_projection.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/trek/data/gps_cadence_engine.dart';
import 'package:moteur_gr/features/trek/data/trace_de_fond.dart';

import 'banc_des_reveils_671.dart';
import 'traces_fabriquees_671.dart';

/// LOT 671-04 — LES CHARNIERES ET LEUR FENETRE, PROUVEES SANS AUCUN CAPTEUR.
///
/// Fiche E7 (2) et (6) : la fenetre se mesure EN ABSCISSE, les fenetres d'un
/// lacet fusionnent, le tir periodique ne double pas le tir de fenetre, la
/// fenetre passe a l'isolate de fond par le canal du trace, et l'entree ecrit
/// UNE ligne `charniere` au journal. L'enrichissement par les jonctions
/// (fiche E2 (5)) est teste a cote de son fournisseur
/// (`test/features/map/providers/charnieres_provider_test.dart`).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  TrackAbscissa sur(List<TrackPoint> trace, double m) =>
      TrackProjector.locate(trackPoints: trace, distanceFromStartM: m);

  group('M1 — LA FENETRE SE MESURE SUR LE TRACE, JAMAIS A VOL D OISEAU', () {
    // Un lacet en trois branches de 400 m, a 15 m l'une de l'autre : la
    // troisieme branche repasse a 30 m de la premiere epingle (400, 0), a
    // 830 m de chemin d'elle.
    final trace = traceDesSommets([
      (0, 0),
      (400, 0),
      (400, 15),
      (0, 15),
      (0, 30),
      (800, 30),
    ]);
    final charnieres = charnieresDuTrace(trace);
    final fenetres = fenetresDesCharnieres(
      charnieres,
      longueurM: trace.last.distanceFromStart,
    );

    test('deux points proches a vol d oiseau et loin sur le sentier ne sont '
        'PAS dans la meme fenetre', () {
      // L'epingle de 15 m est UN virage, au milieu de son raccord.
      final epingle = charnieres.first;
      expect(epingle.abscisseM, inInclusiveRange(400, 415));
      // Sur la troisieme branche, a l'aplomb de l'epingle.
      final loin = sur(trace, 400 + 15 + 400 + 15 + 400);
      final volDOiseau = GeoUtils.haversineDistance(
        epingle.lat,
        epingle.lng,
        loin.lat,
        loin.lng,
      );
      expect(volDOiseau, lessThanOrEqualTo(30));
      final surLeSentier = loin.distanceFromStartM - epingle.abscisseM;
      expect(surLeSentier, greaterThan(800));
      expect(
        fenetreOu(fenetres, loin),
        isNull,
        reason:
            'un point a ${surLeSentier.round()} m sur le sentier de l epingle '
            'est declare dans sa fenetre parce qu il est a '
            '${volDOiseau.round()} m a vol d oiseau',
      );
      // Et le meme point, a 100 m de l'epingle SUR LE TRACE, y est.
      expect(fenetreOu(fenetres, sur(trace, 300)), isNotNull);
    });
  });

  group('le moteur des cadences : la fenetre REMPLACE la periode, elle ne '
      's y ajoute pas', () {
    late FausseHorloge horloge;
    late List<Duration> tirs;
    late GpsCadenceEngine moteur;

    setUp(() {
      horloge = FausseHorloge();
      final depart = horloge.maintenant;
      tirs = [];
      moteur = GpsCadenceEngine(
        openStream: ({required locationSettings}) => const Stream.empty(),
        takeShot: (_) {
          tirs.add(horloge.maintenant.difference(depart));
          return Completer<Position>().future;
        },
        streamSettings: (_) => const LocationSettings(),
        onFix: (_, _) {},
        schedule: horloge.armer,
        now: horloge.now,
      );
    });

    test(
      'entree loin du dernier tir : tir IMMEDIAT, puis toutes les 30 s ; '
      'sortie : la periode de 3 min revient, comptee du dernier tir',
      () async {
        moteur.start(GpsCadence.batteryFirst);
        await horloge.avancer(const Duration(seconds: 100));
        moteur.accelerate(kPeriodeDansLaFenetre);
        expect(moteur.windowPeriod, kPeriodeDansLaFenetre);
        await horloge.avancer(const Duration(seconds: 70));
        moteur.relax();
        await horloge.avancer(const Duration(minutes: 4));
        expect(tirs.map((d) => d.inSeconds), [0, 100, 130, 160, 340]);
      },
    );

    test('entree vue PAR UN RELEVE : ce releve tient lieu de tir d entree, '
        'le suivant part 30 s apres lui — un seul tir, pas deux', () async {
      moteur.start(GpsCadence.batteryFirst);
      await horloge.avancer(const Duration(minutes: 3, seconds: 10));
      moteur.accelerate(kPeriodeDansLaFenetre);
      moteur.accelerate(kPeriodeDansLaFenetre);
      await horloge.avancer(const Duration(seconds: 60));
      expect(tirs.map((d) => d.inSeconds), [0, 180, 210, 240]);
    });

    test('en flux continu (profil carte), la fenetre est sans objet', () {
      moteur.start(GpsCadence.map);
      moteur.accelerate(kPeriodeDansLaFenetre);
      expect(moteur.windowPeriod, isNull);
      expect(tirs, isEmpty);
    });
  });

  group('le canal du trace porte les charnieres', () {
    final trace = traceDesSommets([(0, 0), (500, 0), (500, 500)]);
    final base = (
      trailId: 'banc',
      points: trace,
      direction: WalkDirection.increasing,
    );

    test('sans charniere, le trace s ecrit AU CARACTERE PRES comme avant, et '
        'une valeur ecrite avant ce lot se relit sans charniere', () {
      final avant = encodeBackgroundTrace(base);
      expect(encodeBackgroundTrace(base, charnieres: const []), avant);
      expect(avant, isNot(contains('charnieres')));
      expect(decodeBackgroundHinges(avant), isEmpty);
      expect(decodeBackgroundHinges(null), isEmpty);
      expect(decodeBackgroundHinges('{abime'), isEmpty);
    });

    test('calculees et enrichies, elles reviennent avec leur abscisse', () {
      final c = [
        ...charnieresDuTrace(trace),
        const Charniere.enrichie(abscisseM: 120, lat: 42, lng: 9),
      ];
      final relues = decodeBackgroundHinges(
        encodeBackgroundTrace(base, charnieres: c),
      );
      expect(relues.first.abscisseM, closeTo(c.first.abscisseM, 0.05));
      expect(relues.last.abscisseM, 120);
      expect(relues.map((x) => x.enrichie), [false, true]);
      expect(relues.first.virageDegres, closeTo(-90, 0.5));
    });
  });

  group('LA TRAVERSEE : la vraie chaine de l isolate de fond sur une fausse '
      'horloge', () {
    // 1 000 m droits, une equerre de 70 degres, 1 000 m.
    final trace = traceDesSommets([
      (0, 0),
      (1000, 0),
      auCap(1000, 0, 160, 1000),
    ]);
    final charnieres = charnieresDuTrace(trace);

    test('entrer 150 m avant la charniere tire tout de suite, puis toutes les '
        '30 s ; sortir 150 m apres rend les 3 minutes ; le tir periodique ne '
        'double jamais', () async {
      expect(charnieres, hasLength(1));
      final r = await traverser(trace, charnieres: charnieres);
      final f = r.fenetres.single;
      final c = charnieres.single.abscisseM;
      expect(f.debutM, closeTo(c - kFenetreAvantMetres, 0.1));
      expect(f.finM, closeTo(c + kFenetreApresMetres, 0.1));
      // Dans la fenetre : de son entree a sa sortie, zone morte de 20 m
      // comprise (on n'en sort qu'en franchissant la borne de plus de 20 m).
      final dedans = [
        for (var i = 0; i < r.tirs; i++)
          if (r.abscissesDesTirs[i] >= f.debutM &&
              r.abscissesDesTirs[i] <= f.finM + kWalkDirectionDeadBandMeters)
            i,
      ];
      // Le premier tir de la fenetre tombe au paquet de pas qui y entre :
      // 10 s de marche, 11 m au plus.
      expect(r.abscissesDesTirs[dedans.first] - f.debutM, lessThan(12));
      // Toutes les 30 s dans la fenetre, jamais deux tirs plus rapproches.
      for (var k = 1; k < r.tirs; k++) {
        final ecart = r.heuresDesTirs[k] - r.heuresDesTirs[k - 1];
        expect(ecart, greaterThanOrEqualTo(kPeriodeDansLaFenetre));
      }
      for (final i in dedans.skip(1)) {
        expect(
          r.heuresDesTirs[i] - r.heuresDesTirs[i - 1],
          kPeriodeDansLaFenetre,
        );
      }
      // Apres la sortie, le tir suivant part 3 minutes apres le dernier.
      final apres = dedans.last + 1;
      expect(
        r.heuresDesTirs[apres] - r.heuresDesTirs[dedans.last],
        kBatteryFirstShotPeriod,
      );
      expect(r.abscissesDesTirs[dedans.last + 1], greaterThan(f.finM));
      // 300 m a 4 km/h = 270 s, plus les 20 m de la zone morte : dix tirs
      // dans la fenetre, un de plus au plus selon l'arrondi des paquets.
      expect(dedans.length, inInclusiveRange(10, 11));
      // Chaque tir est une acquisition : le compteur du journal le montre.
      expect(r.acquisitions, r.tirs);
    });

    test('LE JOURNAL : UNE ligne charniere a l entree, neuf champs, des '
        'releves ensuite ; aucun mot hors du vocabulaire ferme', () async {
      final r = await traverser(trace, charnieres: charnieres);
      final evenements = [
        for (final l in r.lignes)
          if (l.split(';')[2] != kMeasureCountersWord) l.split(';'),
      ];
      final ch = evenements.where((c) => c[2] == 'charniere').toList();
      expect(ch, hasLength(1));
      expect(ch.single, hasLength(kMeasureEventFieldCount));
      expect(ch.single[1], PositionProfile.batteryFirst.journalLabel);
      expect(ch.single[5], isNot(kMeasureNoValue)); // la position d'entree
      expect(ch.single.sublist(6), [
        kMeasureNoValue,
        kMeasureNoValue,
        kMeasureNoValue,
      ]);
      for (final c in evenements) {
        expect(c, hasLength(kMeasureEventFieldCount));
        expect(MeasureEvent.fromWord(c[2]).word, c[2]);
      }
      expect(() => MeasureEvent.fromWord('fenetre'), throwsArgumentError);
      // La ligne de compteurs porte les acquisitions : elles montent du
      // nombre de tirs, fenetre comprise.
      final compteurs = r.lignes
          .where((l) => l.split(';')[2] == kMeasureCountersWord)
          .last;
      final acquisitions = int.parse(
        compteurs
            .split(';')
            .firstWhere((v) => v.startsWith('acquisitions='))
            .substring('acquisitions='.length),
      );
      expect(acquisitions, lessThanOrEqualTo(r.tirs));
      expect(acquisitions, greaterThan(0));
    });

    test('sans charniere, aucune fenetre : la seule cadence de 3 minutes, '
        'aucune ligne charniere', () async {
      final r = await traverser(trace, charnieres: const []);
      expect(r.fenetres, isEmpty);
      expect(r.lignes.where((l) => l.split(';')[2] == 'charniere'), isEmpty);
      for (var k = 1; k < r.tirs; k++) {
        expect(
          r.heuresDesTirs[k] - r.heuresDesTirs[k - 1],
          kBatteryFirstShotPeriod,
        );
      }
    });
  });
}
