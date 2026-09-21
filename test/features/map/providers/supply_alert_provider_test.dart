import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/planning/domain/shop_info.dart';
import 'package:moteur_gr/features/planning/providers/shop_providers.dart';

/// Tests du declencheur d'alerte ravitaillement de la carte (correctif L6-1).
///
/// Ce qui est verifie ici est la REGLE, pas la peau : quand l'alerte doit
/// parler et quand elle doit se taire. Le rendu du bandeau (minuterie,
/// fermeture) est couvert cote widget.
void main() {
  const trailId = 'test_trail';

  /// Catalogue de test : commerces aux etapes 1, 3 et 9.
  /// Ecarts : apres 1 -> 2 etapes, apres 3 -> 6 etapes.
  TrailShops catalogue({int seuil = 2}) => TrailShops(
        trailId: trailId,
        gapThreshold: seuil,
        shops: const [
          Shop(name: 'Epicerie du depart', type: ShopKind.epicerie,
              stageNumber: 1),
          Shop(name: 'Bar du col', type: ShopKind.bar, stageNumber: 3),
          Shop(name: 'Epicerie du village', type: ShopKind.epicerie,
              stageNumber: 9),
        ],
      );

  TrackPositionState positionSurEtape(int stageNumber) => TrackPositionState(
        userLat: 42.0,
        userLng: 9.0,
        projectedLat: 42.0,
        projectedLng: 9.0,
        distanceToTrackM: 5,
        distanceFromStartM: 1000,
        distanceRemainingM: 2000,
        trackIndex: 3,
        stageDetection: (
          stageNumber: stageNumber,
          event: StageDetectionEventValues.between,
        ),
        isOffTrack: false,
      );

  ProviderContainer conteneur({
    required AsyncValue<TrackPositionState> position,
    TrailShops? shops,
  }) {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        trailShopsProvider(trailId).overrideWithValue(shops),
        trackPositionProvider.overrideWithValue(position),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('supplyGapAlertProvider', () {
    test('alerte quand l ecart DEPASSE le seuil du sentier', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: catalogue(),
      );
      // Etape 3 -> prochain commerce etape 9 -> ecart de 6 etapes > 2.
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.stageNumber, 3);
      expect(alerte.gap, 6);
    });

    test('SILENCE quand l ecart ne depasse pas le seuil', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(),
      );
      // Etape 1 -> prochain commerce etape 3 -> ecart de 2, pile au seuil.
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('le seuil vient de la DONNEE du sentier, pas du moteur', () {
      // Un sentier isole abaisse son seuil a 1 : le meme ecart de 2 etapes
      // devient une alerte.
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(seuil: 1),
      );
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.gap, 2);
    });

    test('SILENCE apres le dernier commerce du sentier', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(9)),
        shops: catalogue(),
      );
      // Plus de commerce apres l etape 9 : gapAfter vaut 0, pas d alerte.
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('SILENCE tant qu aucune etape n est detectee', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(0)),
        shops: catalogue(),
      );
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('SILENCE sans fix GPS', () {
      final container = conteneur(
        position: const AsyncLoading(),
        shops: catalogue(),
      );
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('SILENCE sur un sentier sans donnee de ravitaillement', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: null,
      );
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('SILENCE sur un catalogue vide (jamais d alerte inventee)', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: const TrailShops(trailId: trailId),
      );
      expect(container.read(supplyGapAlertProvider), isNull);
    });
  });
}
