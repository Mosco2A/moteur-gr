import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/planning/domain/shop_info.dart';
import 'package:moteur_gr/features/planning/providers/shop_providers.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';

/// Tests du declencheur d'alerte ravitaillement de la carte (correctif L6-1,
/// etendu a l'eau et a la portee en kilometres par la tache 834).
///
/// Ce qui est verifie ici est la REGLE, pas la peau : quand l'alerte doit
/// parler, ce qu'elle mesure, et quand elle doit se taire. Le rendu du bandeau
/// (minuterie, fermeture, libelles) est couvert cote widget.
void main() {
  const trailId = 'test_trail';

  /// Catalogue de test : des entrees aux etapes 1, 3 et 9, mais SEULES celles
  /// des etapes 1, 3 et 9 qui le declarent sont des ravitaillements.
  ///
  /// Ecarts de RAVITAILLEMENT : apres 1 -> 2 etapes, apres 3 -> 6 etapes.
  TrailShops catalogue({int seuil = 2, int seuilEau = 1}) => TrailShops(
    trailId: trailId,
    gapThreshold: seuil,
    waterGapThreshold: seuilEau,
    shops: const [
      Shop(
        name: 'Epicerie du depart',
        type: ShopKind.epicerie,
        stageNumber: 1,
        providesResupply: true,
      ),
      Shop(
        name: 'Bar du col',
        type: ShopKind.bar,
        stageNumber: 3,
        providesResupply: true,
      ),
      Shop(
        name: 'Epicerie du village',
        type: ShopKind.epicerie,
        stageNumber: 9,
        providesResupply: true,
      ),
    ],
  );

  /// NEUF ETAPES DONT LA DISTANCE EST SON PROPRE NUMERO : l'etape 4 mesure
  /// 4,0 km, l'etape 9 en mesure 9,0. Toute somme attendue est donc verifiable
  /// de tete, et c'est fait pour.
  final etapes = <StageModel>[
    for (var n = 1; n <= 9; n++)
      StageModel(
        trailId: trailId,
        stageNumber: n,
        name: 'Etape $n',
        distanceKm: n.toDouble(),
        elevationGainM: 100,
        elevationLossM: 100,
        startLat: 42.0,
        startLng: 9.0,
        endLat: 42.1,
        endLng: 9.1,
      ),
  ];

  /// Un point d'eau sur l'etape [stageNumber].
  PoiModel pointDEau(int stageNumber) => PoiModel(
    trailId: trailId,
    stageNumber: stageNumber,
    name: 'Fontaine de l etape $stageNumber',
    type: 'water',
    lat: 42.0,
    lng: 9.0,
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
    List<StageModel>? stages,
    List<PoiModel> pois = const [],
  }) {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        trailShopsProvider(trailId).overrideWithValue(shops),
        trackPositionProvider.overrideWithValue(position),
        stagesProvider(trailId).overrideWith((ref) async => stages ?? etapes),
        poisProvider(trailId).overrideWith((ref) async => pois),
      ],
    );
    addTearDown(container.dispose);
    // Les deux sources asynchrones sont lues par `.value` : on les amorce pour
    // qu'elles soient resolues au moment ou l'alerte se calcule.
    container.listen(stagesProvider(trailId), (_, _) {});
    container.listen(poisProvider(trailId), (_, _) {});
    return container;
  }

  group('supplyGapAlertProvider — les vivres', () {
    test('alerte quand l ecart DEPASSE le seuil du sentier', () async {
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: catalogue(),
      );
      await container.read(stagesProvider(trailId).future);
      // Etape 3 -> prochain ravitaillement etape 9 -> ecart de 6 etapes > 2.
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.stageNumber, 3);
      expect(alerte.gap, 6);
      expect(alerte.kind, SupplyGapKind.food);
      // Etapes 4 a 9 : 4+5+6+7+8+9 = 39,0 km.
      expect(alerte.km, 39.0);
    });

    test('SILENCE quand l ecart ne depasse pas le seuil', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(),
      );
      // Etape 1 -> prochain ravitaillement etape 3 -> ecart de 2, pile au
      // seuil.
      expect(container.read(supplyGapAlertProvider), isNull);
    });

    test('le seuil vient de la DONNEE du sentier, pas du moteur', () async {
      // Un sentier isole abaisse son seuil a 1 : le meme ecart de 2 etapes
      // devient une alerte.
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(seuil: 1),
      );
      await container.read(stagesProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.gap, 2);
      // Etapes 2 et 3 : 2+3 = 5,0 km.
      expect(alerte.km, 5.0);
    });

    test('SILENCE apres le dernier ravitaillement du sentier', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(9)),
        shops: catalogue(),
      );
      // Plus rien apres l etape 9 : l ecart vaut 0, pas d alerte.
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

    test('UNE ENTREE QUI NE RAVITAILLE PAS NE COMPTE PAS', () async {
      // LE DEFAUT MESURE DE LA TACHE 834 : un constat d absence et un bar
      // portent un ShopKind, donc l ancienne regle (« une entree existe »)
      // les comptait comme des ravitaillements et se taisait. Ici l etape 5
      // porte DEUX entrees, aucune n approvisionne : le trou reste entier.
      final shops = TrailShops(
        trailId: trailId,
        shops: const [
          Shop(
            name: 'Epicerie du depart',
            type: ShopKind.epicerie,
            stageNumber: 1,
            providesResupply: true,
          ),
          Shop(
            name: 'Col — aucune epicerie relevee',
            type: ShopKind.epicerie,
            stageNumber: 5,
          ),
          Shop(name: 'Bar du col', type: ShopKind.bar, stageNumber: 5),
          Shop(
            name: 'Epicerie du village',
            type: ShopKind.epicerie,
            stageNumber: 9,
            providesResupply: true,
          ),
        ],
      );
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: shops,
      );
      await container.read(stagesProvider(trailId).future);

      // L ancien instrument, celui qui compte les entrees, voit un ecart de 4.
      expect(shops.gapAfter(1), 4);
      // Le nouveau voit le vrai trou : 8 etapes jusqu a l etape 9.
      expect(shops.resupplyGapAfter(1), 8);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.gap, 8);
      // Etapes 2 a 9 : 2+3+4+5+6+7+8+9 = 44,0 km.
      expect(alerte.km, 44.0);
    });
  });

  group('supplyGapAlertProvider — l eau', () {
    test('alerte sur un trou d EAU, avec son propre seuil', () async {
      // Eau aux etapes 1 et 5. Depuis l etape 1, l ecart vaut 4 etapes : il
      // depasse le seuil de l eau (1) ET celui des vivres (2), mais c est
      // l eau qui manque ici — les vivres sont a l etape 3.
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(),
        pois: [pointDEau(1), pointDEau(5)],
      );
      await container.read(stagesProvider(trailId).future);
      await container.read(poisProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.water);
      expect(alerte.gap, 4);
      // Etapes 2 a 5 : 2+3+4+5 = 14,0 km.
      expect(alerte.km, 14.0);
    });

    test('LE SEUIL DE L EAU EST PLUS SEVERE QUE CELUI DES VIVRES', () async {
      // Un ecart de DEUX etapes : muet du cote des vivres (seuil 2), parlant
      // du cote de l eau (seuil 1). C est toute la demande de la tache 834.
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(),
        pois: [pointDEau(1), pointDEau(3)],
      );
      await container.read(stagesProvider(trailId).future);
      await container.read(poisProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.water);
      expect(alerte.gap, 2);
      // Le meme ecart de 2 etapes, cote vivres, ne declenche RIEN.
      expect(catalogue().isGapAlert(1), isFalse);
      expect(catalogue().isResupplyGapAlert(1), isFalse);
    });

    test('le seuil de l eau vient AUSSI de la donnee du sentier', () async {
      // Un sentier de vallee releve son seuil d eau a 4 : le meme trou de
      // 4 etapes se tait.
      final container = conteneur(
        position: AsyncData(positionSurEtape(1)),
        shops: catalogue(seuilEau: 4),
        pois: [pointDEau(1), pointDEau(5)],
      );
      await container.read(stagesProvider(trailId).future);
      await container.read(poisProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      // Plus d alerte d eau ; et aucune alerte de vivres a l etape 1.
      expect(alerte, isNull);
    });

    test('L EAU PASSE DEVANT QUAND LES DEUX TROUS S OUVRENT', () async {
      // Etape 3 : les vivres manquent (ecart 6) et l eau manque (ecart 3).
      // Une seule alerte s affiche, et c est celle de l eau.
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: catalogue(),
        pois: [pointDEau(1), pointDEau(6)],
      );
      await container.read(stagesProvider(trailId).future);
      await container.read(poisProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.water);
      expect(alerte.gap, 3);
      // Etapes 4 a 6 : 4+5+6 = 15,0 km.
      expect(alerte.km, 15.0);
      // Le trou de vivres existe bel et bien, il attend son tour.
      expect(catalogue().isResupplyGapAlert(3), isTrue);
    });

    test('SILENCE quand le sentier ne declare AUCUN point d eau', () async {
      // Pas de donnee d eau = pas d alerte d eau inventee. Seuls les vivres
      // parlent encore.
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: catalogue(),
      );
      await container.read(stagesProvider(trailId).future);
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.food);
    });

    test('SILENCE apres le dernier point d eau du sentier', () async {
      final container = conteneur(
        position: AsyncData(positionSurEtape(5)),
        shops: catalogue(),
        pois: [pointDEau(1), pointDEau(5)],
      );
      await container.read(stagesProvider(trailId).future);
      await container.read(poisProvider(trailId).future);
      // Plus d eau apres l etape 5 : l ecart vaut 0. Les vivres, eux, parlent
      // (etape 5 -> etape 9, ecart 4).
      final alerte = container.read(supplyGapAlertProvider);
      expect(alerte, isNotNull);
      expect(alerte!.kind, SupplyGapKind.food);
      expect(alerte.gap, 4);
    });
  });

  group('supplyGapAlertProvider — la portee en kilometres', () {
    test('PAS DE KILOMETRES INVENTES quand les etapes sont inconnues', () {
      final container = conteneur(
        position: AsyncData(positionSurEtape(3)),
        shops: catalogue(),
        stages: const [],
      );
      final alerte = container.read(supplyGapAlertProvider);
      // L alerte parle encore — en etapes — mais ne chiffre pas la portee.
      expect(alerte, isNotNull);
      expect(alerte!.gap, 6);
      expect(alerte.km, isNull);
    });

    test(
      'PAS DE KILOMETRES quand une etape du trou n en declare pas',
      () async {
        // Les etapes 1 a 5 seulement : le trou va jusqu a l etape 9, donc
        // quatre distances manquent. On se tait sur la portee plutot que de
        // rendre une somme partielle qui serait un mensonge.
        final container = conteneur(
          position: AsyncData(positionSurEtape(3)),
          shops: catalogue(),
          stages: etapes.take(5).toList(),
        );
        await container.read(stagesProvider(trailId).future);
        final alerte = container.read(supplyGapAlertProvider);
        expect(alerte, isNotNull);
        expect(alerte!.gap, 6);
        expect(alerte.km, isNull);
      },
    );
  });
}
