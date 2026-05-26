import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/features/map/providers/map_pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';

/// Tests du provider mapPoisProvider.
///
/// Vérifie que le filtrage par type de POI fonctionne correctement.
void main() {
  /// Données de test : 4 POIs de types différents
  final testPois = [
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Source du Tilleul',
      type: PoiType.water,
      lat: 45.506,
      lng: 2.805,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Belvédère de Valmont',
      type: PoiType.viewpoint,
      lat: 45.52,
      lng: 2.82,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 2,
      name: 'Refuge du Pic Brunel',
      type: PoiType.shelter,
      lat: 45.542,
      lng: 2.838,
      altitudeM: 1350,
    ),
    const PoiModel(
      trailId: 'test-trail',
      stageNumber: 3,
      name: 'Passage des Ecailles',
      type: PoiType.danger,
      lat: 45.557,
      lng: 2.85,
    ),
  ];

  group('mapPoisProvider', () {
    test('retourne tous les POIs quand tous les types sont actifs', () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(testPois),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(mapPoisProvider('test-trail').future);
      expect(result.length, 4);
    });

    test('filtre correctement quand un type est désactivé', () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(testPois),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Désactiver le type water
      final activeTypes = Set<PoiType>.from(PoiType.values);
      activeTypes.remove(PoiType.water);
      container.read(activePoiTypesProvider.notifier).state = activeTypes;

      final result = await container.read(mapPoisProvider('test-trail').future);
      expect(result.length, 3);
      expect(result.any((p) => p.type == PoiType.water), isFalse);
    });

    test('retourne une liste vide quand tous les types sont désactivés',
        () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(testPois),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Tout désactiver
      container.read(activePoiTypesProvider.notifier).state = {};

      final result = await container.read(mapPoisProvider('test-trail').future);
      expect(result, isEmpty);
    });

    test('filtre pour un seul type activé', () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(testPois),
          ),
        ],
      );
      addTearDown(container.dispose);

      // N'activer que shelter
      container.read(activePoiTypesProvider.notifier).state = {
        PoiType.shelter,
      };

      final result = await container.read(mapPoisProvider('test-trail').future);
      expect(result.length, 1);
      expect(result.first.name, 'Refuge du Pic Brunel');
    });
  });

  group('activePoiTypesProvider', () {
    test('tous les types sont actifs par défaut', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final active = container.read(activePoiTypesProvider);
      expect(active, PoiType.values.toSet());
    });

    test('peut basculer un type', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(activePoiTypesProvider.notifier);
      final current = Set<PoiType>.from(notifier.state);
      current.remove(PoiType.danger);
      notifier.state = current;

      final active = container.read(activePoiTypesProvider);
      expect(active.contains(PoiType.danger), isFalse);
      expect(active.length, PoiType.values.length - 1);
    });
  });

  group('availablePoiTypesProvider', () {
    test('retourne les types présents dans les données', () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(testPois),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        availablePoiTypesProvider('test-trail').future,
      );
      expect(
        result,
        {PoiType.water, PoiType.viewpoint, PoiType.shelter, PoiType.danger},
      );
    });

    test('retourne un ensemble vide quand il n\'y a pas de POIs', () async {
      final container = ProviderContainer(
        overrides: [
          poisProvider('test-trail').overrideWith(
            (ref) => Future.value(<PoiModel>[]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        availablePoiTypesProvider('test-trail').future,
      );
      expect(result, isEmpty);
    });
  });
}
