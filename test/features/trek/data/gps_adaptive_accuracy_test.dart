import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';

/// Position de test avec vitesse parametrable (m/s).
Position _pos({double speed = 0, double lat = 42, double lng = 9}) {
  return Position(
    latitude: lat,
    longitude: lng,
    altitude: 0,
    accuracy: 5,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 0,
    speed: speed,
    speedAccuracy: 0,
    timestamp: DateTime.now(),
  );
}

/// Tests E5.2b (maj F6A-03, puis lot 671-00) — ce qui reste de la precision
/// adaptative : la vitesse ne pilote plus le flux.
///
/// LOT 671-01 — LA DETTE DU LOT 671-00 EST PAYEE. Les regles du regime
/// adaptatif (`classifyMovement`, `accuracyForMode`, `intervalForMode`,
/// `settingsForMode`) n'avaient plus aucun appelant depuis le robinet unique :
/// elles sont retirees avec leurs huit cas d'ici et leurs quinze cas de
/// `gps_service_test.dart`. Les cadences vivent dans `GpsCadence`.
void main() {
  // LOT 671-00 — ROBINET UNIQUE GPS. Jusqu'au lot 671-00, ce groupe
  // verrouillait la RE-SOUSCRIPTION adaptative de getPositionStream (low au
  // repos, high en mouvement). Ce regime ne pilote plus le flux : chaque appel
  // rend le flux unique du PositionController, profil carte (high, 10 m). Les
  // deux cas verrouillent desormais ce contrat.
  group('getPositionStream — robinet unique, profil carte (lot 671-00)', () {
    test(
      'precision haute constante : la vitesse ne re-souscrit plus la source',
      () async {
        final accuracies = <LocationAccuracy>[];
        final controllers = <StreamController<Position>>[];

        final service = GpsService(
          getPositionStream: ({required LocationSettings locationSettings}) {
            accuracies.add(locationSettings.accuracy);
            final c = StreamController<Position>();
            controllers.add(c);
            return c.stream;
          },
        );

        final received = <Position>[];
        final sub = service.getPositionStream().listen(received.add);

        // onListen -> une souscription, profil carte -> high.
        await Future<void>.delayed(Duration.zero);
        expect(accuracies, [LocationAccuracy.high]);

        // Mouvement puis repos : plus aucune re-souscription.
        controllers.last.add(_pos(speed: 5.0));
        controllers.last.add(_pos(speed: 0.0));
        await Future<void>.delayed(Duration.zero);
        expect(accuracies, [LocationAccuracy.high]);

        // Les positions ont bien ete transmises au consommateur.
        expect(received.length, 2);

        await sub.cancel();
        for (final c in controllers) {
          await c.close();
        }
      },
    );

    test(
      'deux appels a getPositionStream partagent une seule source',
      () async {
        final accuracies = <LocationAccuracy>[];
        final controllers = <StreamController<Position>>[];

        final service = GpsService(
          getPositionStream: ({required LocationSettings locationSettings}) {
            accuracies.add(locationSettings.accuracy);
            final c = StreamController<Position>();
            controllers.add(c);
            return c.stream;
          },
        );

        final sub1 = service.getPositionStream().listen((_) {});
        final sub2 = service.getPositionStream().listen((_) {});
        await Future<void>.delayed(Duration.zero);

        controllers.last
          ..add(_pos(speed: 0.0))
          ..add(_pos(speed: 0.1))
          ..add(_pos(speed: 3.0));
        await Future<void>.delayed(Duration.zero);

        expect(accuracies, [LocationAccuracy.high]);
        expect(controllers.length, 1);

        await sub1.cancel();
        await sub2.cancel();
        for (final c in controllers) {
          await c.close();
        }
      },
    );
  });
}
