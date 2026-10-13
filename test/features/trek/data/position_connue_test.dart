import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/position_connue.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';

/// LOT 671-04 — LA DERNIERE POSITION CONNUE ET LE TIR UNIQUE DU SOS.
///
/// La derniere connue est la plus recente de deux memoires (le robinet de
/// l'interface, le service de fond) ; le tir unique passe par la fabrique du
/// robinet avec la precision haute — LA SEULE DU DEPOT, c'est la « precision
/// maximale » de la conception — et 15 s au plus, quel que soit le profil.
void main() {
  final t0 = DateTime(2026, 10, 7, 14);
  late List<LocationSettings> reglages;
  late List<Completer<Position>> tirs;
  late PositionController robinet;
  BgTrackPoint? pointDeFond;
  late Directory dossier;
  late MeasureJournal journal;

  Position releve(DateTime at, {double lat = 42.1}) => Position(
    latitude: lat,
    longitude: 9.1,
    timestamp: at,
    accuracy: 5,
    altitude: 1000,
    altitudeAccuracy: 3,
    heading: 0,
    headingAccuracy: 0,
    speed: 1,
    speedAccuracy: 0,
  );

  BgTrackPoint estime(DateTime at) => BgTrackPoint(
    id: 'e',
    sessionId: 's',
    trailId: 't',
    latitude: 42.2,
    longitude: 9.2,
    altitude: 1100,
    accuracy: 0,
    speed: 0,
    timestamp: at,
    source: TrackPointSource.estimated,
    trackDistanceM: 800,
  );

  setUp(() async {
    reglages = [];
    tirs = [];
    pointDeFond = null;
    dossier = await Directory.systemTemp.createTemp('position_connue_');
    journal = MeasureJournal(directory: () async => dossier);
    robinet = PositionController(
      currentPosition: ({required locationSettings}) {
        reglages.add(locationSettings);
        final c = Completer<Position>();
        tirs.add(c);
        return c.future;
      },
    );
  });

  tearDown(() async {
    await journal.idle;
    await dossier.delete(recursive: true);
  });

  PositionsConnues positions() => PositionsConnues(
    robinet: robinet,
    pointDeFond: () => pointDeFond,
    journal: journal,
    maintenant: () => t0.add(const Duration(minutes: 5)),
  );

  Future<void> releveA(DateTime at, {double lat = 42.1}) async {
    final shot = robinet.singleShot();
    tirs.removeLast().complete(releve(at, lat: lat));
    await shot;
  }

  group('la derniere position connue', () {
    test('rien recu : nulle', () {
      expect(positions().derniere(), isNull);
    });

    test('seul le robinet : son releve, non estime', () async {
      await releveA(t0);
      final p = positions().derniere()!;
      expect(p.latitude, 42.1);
      expect(p.mesureeA, t0);
      expect(p.estimee, isFalse);
    });

    test('seul le fond : son point, estime le long du trace', () {
      pointDeFond = estime(t0);
      final p = positions().derniere()!;
      expect(p.latitude, 42.2);
      expect(p.altitude, 1100);
      expect(p.estimee, isTrue);
    });

    test(
      'les deux : LA PLUS RECENTE, dans un sens comme dans l autre',
      () async {
        await releveA(t0);
        pointDeFond = estime(t0.add(const Duration(minutes: 1)));
        expect(positions().derniere()!.estimee, isTrue);
        await releveA(t0.add(const Duration(minutes: 2)), lat: 42.3);
        expect(positions().derniere()!.latitude, 42.3);
      },
    );

    test('la lire n ouvre rien : aucun tir, aucune souscription', () {
      positions().derniere();
      expect(tirs, isEmpty);
      expect(robinet.hasLiveSubscription, isFalse);
    });
  });

  group('le tir unique du SOS', () {
    for (final profil in [PositionProfile.map, PositionProfile.batteryFirst]) {
      test('profil ${profil.name} : precision haute et 15 s au plus, et la '
          'position obtenue devient la derniere connue', () async {
        await robinet.setProfile(profil);
        final frais = positions().tirer();
        expect(reglages.single.accuracy, LocationAccuracy.high);
        expect(reglages.single.timeLimit, kSingleShotMaxDelay);
        tirs.single.complete(releve(t0, lat: 42.4));
        expect((await frais).latitude, 42.4);
        expect(robinet.lastFix!.latitude, 42.4);
        expect(robinet.hasLiveSubscription, isFalse);
      });
    }
  });

  test(
    'la ligne sos sans position connue : des tirets aux champs 6 et 9',
    () async {
      await positions().noterLAppel(null);
      await journal.idle;
      final ligne = (await (await journal.file()).readAsLines()).single;
      final champs = ligne.split(';');
      expect(champs, hasLength(kMeasureEventFieldCount));
      expect(champs[2], MeasureEvent.sos.word);
      expect(champs[5], kMeasureNoValue);
      expect(champs[8], kMeasureNoValue);
    },
  );
}
