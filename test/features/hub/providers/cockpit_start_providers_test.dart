import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/features/hub/providers/cockpit_start_providers.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/trek_completion.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';

/// Tests unitaires des providers du DÉMARRAGE RÉEL (StepWays LOT 3, Q1 §12.5) :
///   - [prepareCoreDoneProvider] : gate 3 cartes (Itinéraire + Date + Programme) ;
///   - [startProximityProvider] : proximité au départ de l'étape 1 (300 m) +
///     `gpsAvailable` (false si pas de fix).
Position _pos({required double lat, required double lng}) => Position(
      latitude: lat,
      longitude: lng,
      altitude: 0,
      accuracy: 5,
      altitudeAccuracy: 5,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
      timestamp: DateTime.now(),
    );

/// Étape 1 démarre à (42.0, 9.0).
const _stages = [
  Stage(
    id: '1',
    nameFr: 'Etape 1',
    distance: 10,
    elevationGain: 500,
    elevationLoss: 300,
    orderIndex: 1,
    startLat: 42.0,
    startLng: 9.0,
    endLat: 42.1,
    endLng: 9.1,
  ),
  Stage(
    id: '2',
    nameFr: 'Etape 2',
    distance: 12,
    elevationGain: 600,
    elevationLoss: 400,
    orderIndex: 2,
    startLat: 42.1,
    startLng: 9.1,
    endLat: 42.2,
    endLng: 9.2,
  ),
];

const _plan = TrekPlan(
  orderedStageIds: ['1', '2'],
  direction: 'NS',
  isFullTrail: true,
);

/// Notifier factice pour piloter l'ensemble des étapes cœur faites en test.
class _FakeStepsNotifier extends PrepareCoreStepsNotifier {
  _FakeStepsNotifier(this._value) : super('t');
  final Set<PrepCoreStep> _value;

  @override
  Set<PrepCoreStep> build() => _value;
}

/// Notifier factice pour piloter la date de départ persistée en test.
class _FakeReminderNotifier extends DownloadReminderNotifier {
  _FakeReminderNotifier(this._state) : super('t');
  final DepartureReminderState _state;

  @override
  DepartureReminderState build() => _state;
}

void main() {
  group('prepareCoreDoneProvider (gate 3 cartes, §12.1)', () {
    ProviderContainer make({
      required Set<PrepCoreStep> steps,
      required DateTime? departureDate,
    }) {
      return ProviderContainer(
        overrides: [
          prepareCoreStepsProvider('t').overrideWith(
            () => _FakeStepsNotifier(steps),
          ),
          downloadReminderProvider('t').overrideWith(
            () => _FakeReminderNotifier(
              DepartureReminderState(departureDate: departureDate),
            ),
          ),
        ],
      );
    }

    test('vrai seulement si Itinéraire ET Programme ET Date présents', () {
      final c = make(
        steps: {PrepCoreStep.itinerary, PrepCoreStep.programme},
        departureDate: DateTime(2026, 7, 1),
      );
      addTearDown(c.dispose);
      expect(c.read(prepareCoreDoneProvider('t')), isTrue);
    });

    test('faux si Itinéraire manque', () {
      final c = make(
        steps: {PrepCoreStep.programme},
        departureDate: DateTime(2026, 7, 1),
      );
      addTearDown(c.dispose);
      expect(c.read(prepareCoreDoneProvider('t')), isFalse);
    });

    test('faux si Programme manque', () {
      final c = make(
        steps: {PrepCoreStep.itinerary},
        departureDate: DateTime(2026, 7, 1),
      );
      addTearDown(c.dispose);
      expect(c.read(prepareCoreDoneProvider('t')), isFalse);
    });

    test('faux si Date (calendrier) manque', () {
      final c = make(
        steps: {PrepCoreStep.itinerary, PrepCoreStep.programme},
        departureDate: null,
      );
      addTearDown(c.dispose);
      expect(c.read(prepareCoreDoneProvider('t')), isFalse);
    });

    test('faux si aucune carte cœur faite', () {
      final c = make(steps: const {}, departureDate: null);
      addTearDown(c.dispose);
      expect(c.read(prepareCoreDoneProvider('t')), isFalse);
    });
  });

  group('startProximityProvider (proximité départ étape 1, §12.5)', () {
    /// Container avec un StreamController de positions (émission synchrone
    /// contrôlée), + stages/plan injectés. On attend une itération de la boucle
    /// d'événements pour laisser le StreamProvider passer en AsyncData.
    ProviderContainer make(StreamController<Position> controller) {
      final c = ProviderContainer(
        overrides: [
          positionStreamProvider.overrideWith((ref) => controller.stream),
          domainStagesProvider.overrideWithValue(_stages),
          currentTrekPlanProvider.overrideWithValue(_plan),
        ],
      );
      // Abonnement actif pour que le StreamProvider consomme le stream.
      c.listen(positionStreamProvider, (_, __) {});
      return c;
    }

    test('atDeparture=true si la position est a moins de 300 m du depart',
        () async {
      final controller = StreamController<Position>();
      final c = make(controller);
      addTearDown(() {
        c.dispose();
        controller.close();
      });
      // ~15 m au nord du départ (42.0, 9.0) — bien sous la tolérance de 300 m.
      controller.add(_pos(lat: 42.00013, lng: 9.0));
      await Future<void>.delayed(Duration.zero);

      final prox = c.read(startProximityProvider);
      expect(prox.gpsAvailable, isTrue);
      expect(prox.distanceMeters, isNotNull);
      expect(prox.distanceMeters!, lessThan(kStartProximityToleranceMeters));
      expect(prox.atDeparture, isTrue);
    });

    test('atDeparture=false si la position est a plus de 300 m du depart',
        () async {
      final controller = StreamController<Position>();
      final c = make(controller);
      addTearDown(() {
        c.dispose();
        controller.close();
      });
      // ~1.1 km au nord (0.01° de latitude) -> hors tolérance.
      controller.add(_pos(lat: 42.01, lng: 9.0));
      await Future<void>.delayed(Duration.zero);

      final prox = c.read(startProximityProvider);
      expect(prox.gpsAvailable, isTrue);
      expect(prox.distanceMeters!, greaterThan(kStartProximityToleranceMeters));
      expect(prox.atDeparture, isFalse);
    });

    // gpsAvailable=false couvre indistinctement « pas encore de fix » (loading),
    // stream en erreur et permission refusée : dans tous ces cas le stream n'a
    // pas de valeur exploitable -> le clic sur Démarrer passera par le dialog de
    // secours (jamais de blocage, Q1 filet).
    test('gpsAvailable=false et atDeparture=false tant qu\'aucun fix', () {
      final controller = StreamController<Position>();
      final c = make(controller);
      addTearDown(() {
        c.dispose();
        controller.close();
      });
      // Aucune position émise -> AsyncLoading.
      final prox = c.read(startProximityProvider);
      expect(prox.gpsAvailable, isFalse);
      expect(prox.atDeparture, isFalse);
      expect(prox.distanceMeters, isNull);
    });
  });
}
