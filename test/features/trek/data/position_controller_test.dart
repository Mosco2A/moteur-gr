import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';

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

/// Tests unitaires du robinet unique GPS (lot 671-00). Le contrat
/// multi-abonnes et le canal du profil sont dans
/// `test/comportement/un_seul_robinet_671_test.dart`.
void main() {
  group('PositionController — cycle de vie de la source', () {
    test(
      'une ecoute apres le depart du dernier abonne rouvre la source',
      () async {
        var ouvertures = 0;
        final source = StreamController<Position>.broadcast();
        final controleur = PositionController(
          positionStream: ({required LocationSettings locationSettings}) {
            ouvertures++;
            return source.stream;
          },
        );

        final premier = controleur.positions.listen((_) {});
        await premier.cancel();
        final recu = <Position>[];
        final second = controleur.positions.listen(recu.add);
        source.add(_position(42));
        await Future<void>.delayed(Duration.zero);

        expect(ouvertures, 2);
        expect(recu.single.latitude, 42);
        await second.cancel();
        await source.close();
      },
    );

    test('la fin de la source termine les abonnes du moment', () async {
      final controleur = PositionController(
        positionStream: ({required LocationSettings locationSettings}) =>
            Stream.fromIterable([_position(1), _position(2)]),
      );

      final recu = await controleur.positions.toList();

      expect(recu.map((p) => p.latitude), [1, 2]);
    });

    test('une erreur de la source est propagee sans couper le flux', () async {
      final source = StreamController<Position>();
      final controleur = PositionController(
        positionStream: ({required LocationSettings locationSettings}) =>
            source.stream,
      );
      final recu = <Position>[];
      final erreurs = <Object>[];
      final abonne = controleur.positions.listen(
        recu.add,
        onError: erreurs.add,
      );

      source
        ..addError(StateError('signal GPS perdu'))
        ..add(_position(43));
      await Future<void>.delayed(Duration.zero);

      expect(erreurs.single, isA<StateError>());
      expect(recu.single.latitude, 43);
      await abonne.cancel();
      await source.close();
    });
  });

  group('PositionController — profil', () {
    test('le coup unique prend les reglages du profil courant', () async {
      LocationSettings? demandes;
      final controleur = PositionController(
        currentPosition: ({required LocationSettings locationSettings}) async {
          demandes = locationSettings;
          return _position(44);
        },
      );

      final position = await controleur.currentPosition();

      expect(position.latitude, 44);
      expect(demandes?.accuracy, LocationAccuracy.high);
      expect(demandes?.distanceFilter, 10);
    });

    test('un profil non actif au lot 671-00 est refuse', () async {
      final controleur = PositionController();

      for (final profil in PositionProfile.values) {
        if (PositionController.activeProfiles.contains(profil)) continue;
        await expectLater(
          controleur.setProfile(profil),
          throwsA(isA<UnsupportedError>()),
        );
      }
      expect(controleur.profile, PositionProfile.map);
    });
  });
}
