import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/eta_service.dart';

void main() {
  group('EtaService.naismithEta (fonction pure)', () {
    test('5 km a plat a 1.1 m/s -> ~1h15 (4545 s, +/-60 s)', () {
      final eta = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 1.1,
      );
      // 5000 / 1.1 = 4545 s ~ 75.8 min.
      expect(eta.inSeconds, closeTo(4545, 60));
    });

    test('+400 m de montee ajoute ~1 h — LE modele unique (tache 839)', () {
      // CE CAS A CHANGE DE CHIFFRE, ET C'EST TOUT LE SUJET DU LOT. Il
      // verifiait « 1 h par 600 m » : c'etait le SECOND modele du depot, celui
      // qui annonçait l'heure d'arrivee pendant que le programme decoupait les
      // jours a 400 m/h. Il n'en reste qu'un, et c'est le PRUDENT.
      final plat = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 1.1,
      );
      final avecMontee = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 400,
        descentMetres: 0,
        observedPaceMps: 1.1,
      );
      expect((avecMontee - plat).inSeconds, closeTo(3600, 5));
      // Et 600 m de montee coutent desormais une heure et demie.
      final plusHaut = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 600,
        descentMetres: 0,
        observedPaceMps: 1.1,
      );
      expect((plusHaut - plat).inSeconds, closeTo(5400, 5));
    });

    test('vitesse OBSERVEE plus rapide -> ETA plus courte', () {
      final lent = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 1.0,
      );
      final rapide = EtaService.naismithEta(
        distanceMetres: 5000,
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 1.5,
      );
      expect(rapide, lessThan(lent));
    });

    test('vitesse observee nulle -> retombe sur la vitesse par defaut', () {
      // LA VITESSE PAR DEFAUT EST DESORMAIS 4 km/h EXACTEMENT (1,1111 m/s),
      // derivee du modele unique. Elle valait 1,1 m/s ecrit en dur, soit
      // 3,96 km/h : deux chiffres pour une seule vitesse.
      final eta = EtaService.naismithEta(
        distanceMetres: 1000, // 1000 m a 4 km/h = 900 s.
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 0,
      );
      expect(eta.inSeconds, closeTo(900, 5));
      expect(EtaService.defaultFlatPaceMps, closeTo(1.1111, 0.0001));
    });

    test('descente raide ajoute une penalite de temps', () {
      final plat = EtaService.naismithEta(
        distanceMetres: 2000,
        ascentMetres: 0,
        descentMetres: 0,
        observedPaceMps: 1.1,
      );
      final descente = EtaService.naismithEta(
        distanceMetres: 2000,
        ascentMetres: 0,
        descentMetres: 300,
        observedPaceMps: 1.1,
      );
      expect(descente, greaterThan(plat));
    });

    test('valeurs non finies/negatives traitees comme nulles', () {
      final eta = EtaService.naismithEta(
        distanceMetres: double.nan,
        ascentMetres: -100,
        descentMetres: double.infinity,
        observedPaceMps: 1.1,
      );
      expect(eta.inSeconds, 0);
    });
  });

  group('EtaService.estimate (waypoint + fin + confiance)', () {
    EtaInput input({double pace = 1.1, bool degraded = false}) {
      return EtaInput(
        distanceToWaypointM: 1000,
        ascentToWaypointM: 60,
        descentToWaypointM: 0,
        distanceToStageEndM: 5000,
        ascentToStageEndM: 300,
        descentToStageEndM: 100,
        observedPaceMps: pace,
        gpsDegraded: degraded,
      );
    }

    test('fin d etape >= prochain waypoint', () {
      final est = EtaService.estimate(input());
      expect(est.toStageEnd, greaterThanOrEqualTo(est.toNextWaypoint));
    });

    test('GPS fiable + vitesse observee -> confiance haute', () {
      final est = EtaService.estimate(input(pace: 1.2, degraded: false));
      expect(est.confidence, EtaConfidence.high);
    });

    test('GPS degrade -> confiance basse', () {
      final est = EtaService.estimate(input(pace: 1.2, degraded: true));
      expect(est.confidence, EtaConfidence.low);
    });

    test('vitesse GPS nulle (mais cadence presente) -> confiance basse', () {
      final est = EtaService.estimate(input(pace: 0, degraded: false));
      expect(est.confidence, EtaConfidence.low);
    });
  });

  group('EtaService.estimateStream', () {
    test('chaque entree produit une estimation', () async {
      final ctrl = StreamController<EtaInput>();
      final service = EtaService(inputStream: ctrl.stream);

      final future = service.estimateStream().take(2).toList();
      ctrl
        ..add(
          const EtaInput(
            distanceToWaypointM: 500,
            ascentToWaypointM: 0,
            descentToWaypointM: 0,
            distanceToStageEndM: 2000,
            ascentToStageEndM: 0,
            descentToStageEndM: 0,
            observedPaceMps: 1.0,
            gpsDegraded: false,
          ),
        )
        ..add(
          const EtaInput(
            distanceToWaypointM: 300,
            ascentToWaypointM: 0,
            descentToWaypointM: 0,
            distanceToStageEndM: 1500,
            ascentToStageEndM: 0,
            descentToStageEndM: 0,
            observedPaceMps: 1.0,
            gpsDegraded: true,
          ),
        );
      await ctrl.close();

      final results = await future;
      expect(results.length, 2);
      expect(results[0].confidence, EtaConfidence.high);
      expect(results[1].confidence, EtaConfidence.low);
    });
  });
}
