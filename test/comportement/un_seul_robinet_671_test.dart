// LOT 671-00 — LE ROBINET UNIQUE GPS, PREMIER LOT « BATTERIE D'ABORD ».
//
// CE QUE CE FICHIER PROUVE. Le lot DEPLACE de la plomberie GPS a comportement
// identique : c'est la seule facon de le rendre verifiable. Il prouve donc,
// dans l'ordre :
//
//  1. QUE LE FLUX EST VRAIMENT PARTAGE. Deux abonnes simultanes recoivent tous
//     deux chaque position, d'UNE seule souscription a la source, et le depart
//     du dernier abonne ferme cette souscription (pas de GPS residuel).
//
//  2. QUE LE CANAL DU PROFIL EST POSE ET TOLERANT. `kPrefsBgProfile` absent ou
//     inconnu donne la carte, une valeur valide se relit telle quelle ;
//     l'isolate de fond le relit a son demarrage avec les cles voisines, et
//     depuis le lot 671-01 il en tire sa cadence.
//
//  3. QUE LE CONTROLEUR ECRIT SON PROFIL, une fois, et par le canal reel en
//     production.
//
//  4. QUE LE COMPORTEMENT EST IDENTIQUE. Le profil carte demande EXACTEMENT les
//     reglages de la souscription la plus utilisee avant le lot (carte,
//     hors-trace, suivi) : `LocationSettings(accuracy: high, distanceFilter:
//     10)`, sans intervalle impose. Et la carte, le hors-trace, le pipeline
//     d'etapes et `GpsService` lisent la MEME souscription.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/off_track_provider.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position _position(double lat) => Position(
  latitude: lat,
  longitude: 9,
  altitude: 0,
  accuracy: 5,
  altitudeAccuracy: 5,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
  timestamp: DateTime.utc(2026, 10, 6),
);

/// Une source GPS simulee qui compte ses souscriptions et retient les
/// reglages demandes.
class _SourceSimulee {
  final reglages = <LocationSettings>[];
  final _flux = StreamController<Position>.broadcast();
  var souscriptions = 0;
  var annulations = 0;

  Stream<Position> ouvrir({required LocationSettings locationSettings}) {
    reglages.add(locationSettings);
    return Stream<Position>.multi((abonne) {
      souscriptions++;
      final sub = _flux.stream.listen(
        abonne.add,
        onError: abonne.addError,
        onDone: abonne.close,
      );
      abonne.onCancel = () {
        annulations++;
        return sub.cancel();
      };
    });
  }

  void emettre(Position p) => _flux.add(p);

  Future<void> fermer() => _flux.close();
}

Future<void> _laisserPasser() => Future<void>.delayed(Duration.zero);

/// Le corps de `_onServiceStart`, l'entree de l'isolate de fond.
String _corpsDeLIsolate() {
  final source = File(
    'lib/features/trek/data/background_gps_service.dart',
  ).readAsStringSync();
  final debut = source.indexOf('Future<void> _onServiceStart(');
  expect(debut, greaterThanOrEqualTo(0), reason: '_onServiceStart introuvable');
  final fin = source.indexOf('\n}\n', debut);
  return source.substring(debut, fin);
}

void main() {
  group('671-00 — le flux est vraiment partage', () {
    test(
      'deux abonnes simultanes recoivent TOUS DEUX chaque position',
      () async {
        final source = _SourceSimulee();
        final controleur = PositionController(positionStream: source.ouvrir);

        final premier = <double>[];
        final second = <double>[];
        final a = controleur.positions.listen((p) => premier.add(p.latitude));
        // Un flux a abonne unique REFUSE le deuxieme abonne : on garde le
        // refus pour le montrer, au lieu de laisser l'exception masquer le
        // constat.
        StreamSubscription<Position>? b;
        Object? refus;
        try {
          b = controleur.positions.listen((p) => second.add(p.latitude));
        } on StateError catch (e) {
          refus = e;
        }
        await _laisserPasser();
        source
          ..emettre(_position(1))
          ..emettre(_position(2));
        await _laisserPasser();

        expect(premier, [1, 2]);
        expect(
          second,
          [1, 2],
          reason:
              'le deuxieme abonne n a rien recu'
              '${refus == null ? '' : ' : il a ete refuse ($refus)'}',
        );
        expect(controleur.positions.isBroadcast, isTrue);
        await a.cancel();
        await b?.cancel();
        await source.fermer();
      },
    );

    test('une seule souscription a la source pour plusieurs abonnes', () async {
      final source = _SourceSimulee();
      final controleur = PositionController(positionStream: source.ouvrir);

      final abonnes = [
        for (var i = 0; i < 3; i++) controleur.positions.listen((_) {}),
      ];
      await _laisserPasser();

      expect(source.souscriptions, 1);
      expect(source.reglages, hasLength(1));
      for (final s in abonnes) {
        await s.cancel();
      }
      await source.fermer();
    });

    test('le dernier abonne parti ferme la souscription a la source', () async {
      final source = _SourceSimulee();
      final controleur = PositionController(positionStream: source.ouvrir);
      final a = controleur.positions.listen((_) {});
      final b = controleur.positions.listen((_) {});
      await _laisserPasser();

      await a.cancel();
      expect(source.annulations, 0, reason: 'un abonne reste : source ouverte');
      await b.cancel();
      expect(source.annulations, 1, reason: 'plus d abonne : source fermee');
      await source.fermer();
    });
  });

  group('671-00 — le canal kPrefsBgProfile', () {
    test('absent -> carte', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      expect(bgReadPositionProfile(prefs), PositionProfile.map);
    });

    test('inconnu -> carte', () async {
      SharedPreferences.setMockInitialValues({kPrefsBgProfile: 'turbo'});
      final prefs = await SharedPreferences.getInstance();
      expect(bgReadPositionProfile(prefs), PositionProfile.map);
    });

    test('valide -> la valeur, et l ecriture se relit', () async {
      SharedPreferences.setMockInitialValues({
        kPrefsBgProfile: PositionProfile.stationary.name,
      });
      final prefs = await SharedPreferences.getInstance();
      expect(bgReadPositionProfile(prefs), PositionProfile.stationary);

      await bgWritePositionProfile(PositionProfile.lowBattery);
      expect(bgReadPositionProfile(prefs), PositionProfile.lowBattery);
    });

    test('l isolate de fond relit le profil a son demarrage, avec les cles '
        'voisines', () {
      final corps = _corpsDeLIsolate();
      final voisine = corps.indexOf('p.getDouble(kPrefsBgDistanceFilter)');
      final lecture = corps.indexOf('profile = bgReadPositionProfile(p);');
      expect(voisine, greaterThanOrEqualTo(0));
      expect(
        lecture,
        greaterThanOrEqualTo(0),
        reason: 'l isolate de fond ne lit plus kPrefsBgProfile',
      );
      expect(
        (lecture - voisine).abs(),
        lessThan(200),
        reason: 'la lecture du profil a quitte le bloc du handshake',
      );
    });

    // LOT 671-01 : CE CAS VERROUILLAIT « AU LOT 00 L'ISOLATE NE FAIT RIEN DU
    // PROFIL ». Le lot 671-01 est celui qui branche le canal sur la
    // captation, comme le lot 00 l'annoncait : le contrat devient l'inverse,
    // et c'est lui que ce cas verrouille desormais.
    test('au lot 01 l isolate pilote sa cadence par le profil relu, et suit '
        'un changement sans redemarrer', () {
      final corps = _corpsDeLIsolate();
      expect(
        corps.contains('unawaited(cadence.start(profile));'),
        isTrue,
        reason: 'la captation de fond ne demarre plus sur le profil relu',
      );
      expect(
        corps.contains("service.on('profile')"),
        isTrue,
        reason: 'l isolate n ecoute plus les changements de profil',
      );
      expect(
        corps.contains('LocationSettings buildSettings()'),
        isFalse,
        reason:
            'des reglages GPS sont de nouveau batis hors de la '
            'correspondance unique',
      );
    });
  });

  group('671-00 — le controleur ecrit son profil', () {
    test('a la premiere ecoute, une seule fois, et seulement carte', () async {
      final source = _SourceSimulee();
      final ecrits = <PositionProfile>[];
      final controleur = PositionController(
        positionStream: source.ouvrir,
        writeProfile: (p) async => ecrits.add(p),
      );
      expect(ecrits, isEmpty, reason: 'rien n est ecrit sans abonne');

      final a = controleur.positions.listen((_) {});
      final b = controleur.positions.listen((_) {});
      await _laisserPasser();
      await controleur.setProfile(PositionProfile.map);
      await a.cancel();
      await b.cancel();
      final c = controleur.positions.listen((_) {});
      await _laisserPasser();

      expect(ecrits, [PositionProfile.map]);
      await c.cancel();
      await source.fermer();
    });

    test('en production, positionControllerProvider ecrit dans '
        'kPrefsBgProfile', () async {
      SharedPreferences.setMockInitialValues({});
      final conteneur = ProviderContainer();
      addTearDown(conteneur.dispose);

      await conteneur
          .read(positionControllerProvider)
          .setProfile(PositionProfile.map);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kPrefsBgProfile), PositionProfile.map.name);
    });
  });

  group('671-00 — comportement identique', () {
    test('le profil carte demande exactement les reglages d avant : '
        'precision haute, 10 m, intervalle par defaut', () async {
      final source = _SourceSimulee();
      final controleur = PositionController(positionStream: source.ouvrir);
      final a = controleur.positions.listen((_) {});
      await _laisserPasser();

      final demandes = source.reglages.single;
      // `LocationSettings` et non `AndroidSettings` : aucun intervalle impose,
      // comme les anciennes souscriptions de la carte, du hors-trace et du
      // suivi.
      expect(demandes.runtimeType, LocationSettings);
      expect(demandes.accuracy, LocationAccuracy.high);
      expect(demandes.distanceFilter, 10);
      expect(demandes.timeLimit, isNull);
      expect(controleur.profile, PositionProfile.map);
      await a.cancel();
      await source.fermer();
    });

    test('carte, hors-trace, pipeline d etapes et GpsService lisent la MEME '
        'souscription', () async {
      final source = _SourceSimulee();
      final controleur = PositionController(positionStream: source.ouvrir);
      final conteneur = ProviderContainer(
        overrides: [
          positionControllerProvider.overrideWithValue(controleur),
          gpsPermissionProvider.overrideWith(
            (ref) async => GpsPermissionStateValues.granted,
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      final carte = <double>[];
      final pipeline = <double>[];
      final horsTrace = <double>[];
      conteneur.listen(locationProvider, (_, v) {
        if (v.hasValue) carte.add(v.value!.latitude);
      });
      conteneur.listen(positionStreamProvider, (_, v) {
        if (v.hasValue) pipeline.add(v.value!.latitude);
      });
      final h = conteneur
          .read(offTrackGpsStreamProvider)
          .listen((p) => horsTrace.add(p.latitude));
      final g = conteneur
          .read(gpsServiceProvider)
          .getPositionStream()
          .listen((_) {});
      await conteneur.read(gpsPermissionProvider.future);
      await _laisserPasser();

      source.emettre(_position(7));
      await _laisserPasser();

      expect(source.souscriptions, 1);
      expect(carte, [7]);
      expect(pipeline, [7]);
      expect(horsTrace, [7]);
      await h.cancel();
      await g.cancel();
      await source.fermer();
    });
  });
}
