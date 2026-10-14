import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/stage_detector.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/core/utils/nombre_en_clair.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/map/providers/track_position_provider.dart';
import 'package:moteur_gr/features/planning/domain/shop_catalog.dart';
import 'package:moteur_gr/features/planning/providers/shop_providers.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// TACHE 834 — LA PREUVE QUE L'ALERTE SE DECLENCHE SUR LE TROU REEL.
///
/// Les autres tests de l'alerte travaillent sur un sentier fabrique, aux
/// distances rondes, pour que la regle soit lisible. Celui-ci ne fabrique
/// RIEN : il lit le catalogue de ravitaillement embarque
/// ([ShopCatalog.forTrail]), les sept etapes de
/// `assets/data/mare_a_mare_centre/stages.json` et les points d'eau de
/// `assets/data/mare_a_mare_centre/pois.json`, c'est-a-dire exactement ce que
/// le telephone du randonneur embarque.
///
/// CE QU'IL VERROUILLE, ET POURQUOI. Le catalogue a ete refait le 14/10 sur un
/// releve OpenStreetMap (tache 844) et sa note annonce « les cinq etapes entre
/// Cozzano et Porticcio (52,5 km) n'en ont aucune ». L'alerte de la carte,
/// elle, restait muette : elle comptait les etapes portant UNE ENTREE de
/// catalogue, et les sept en portent une. Ce test echoue le jour ou l'alerte
/// redevient sourde, et le jour ou un commerce ajoute au catalogue coupe le
/// trou sans qu'on l'ait decide.
const trailId = 'mare-a-mare-centre';

/// Le dossier de la donnee embarquee — en souligne, la ou l'identifiant du
/// sentier prend des tirets.
const dossierDonnees = 'assets/data/mare_a_mare_centre';

/// Les sept etapes reelles, lues dans la donnee embarquee du sentier.
List<StageModel> etapesReelles() {
  final fichier = File('$dossierDonnees/stages.json');
  final brut = jsonDecode(fichier.readAsStringSync()) as List<dynamic>;
  return brut.map((e) {
    final m = e as Map<String, dynamic>;
    return StageModel(
      trailId: m['trailId'] as String,
      stageNumber: (m['stageNumber'] as num).toInt(),
      name: m['nameFr'] as String,
      distanceKm: (m['distanceKm'] as num).toDouble(),
      elevationGainM: (m['elevationGainM'] as num).toInt(),
      elevationLossM: (m['elevationLossM'] as num).toInt(),
      startLat: (m['startLat'] as num).toDouble(),
      startLng: (m['startLng'] as num).toDouble(),
      endLat: (m['endLat'] as num).toDouble(),
      endLng: (m['endLng'] as num).toDouble(),
    );
  }).toList();
}

/// Les points d'interet reels, lus dans la donnee embarquee du sentier.
List<PoiModel> poisReels() {
  final fichier = File('$dossierDonnees/pois.json');
  final brut = jsonDecode(fichier.readAsStringSync()) as List<dynamic>;
  return brut.map((e) {
    final m = e as Map<String, dynamic>;
    return PoiModel(
      trailId: m['trailId'] as String? ?? trailId,
      stageNumber: (m['stageNumber'] as num).toInt(),
      name: m['nameFr'] as String,
      type: m['type'] as String,
      lat: (m['lat'] as num).toDouble(),
      lng: (m['lng'] as num).toDouble(),
    );
  }).toList();
}

void main() {
  final etapes = etapesReelles();
  final pois = poisReels();
  final catalogue = ShopCatalog.forTrail(trailId)!;

  TrackPositionState surEtape(int stageNumber) => TrackPositionState(
    userLat: 41.9,
    userLng: 9.1,
    projectedLat: 41.9,
    projectedLng: 9.1,
    distanceToTrackM: 4,
    distanceFromStartM: 20000,
    distanceRemainingM: 60000,
    trackIndex: 120,
    stageDetection: (
      stageNumber: stageNumber,
      event: StageDetectionEventValues.between,
    ),
    isOffTrack: false,
  );

  Future<SupplyGapAlert?> alerteSurEtape(int stageNumber) async {
    final container = ProviderContainer(
      overrides: [
        trailIdProvider.overrideWithValue(trailId),
        trailShopsProvider(trailId).overrideWithValue(catalogue),
        trackPositionProvider.overrideWithValue(
          AsyncData(surEtape(stageNumber)),
        ),
        stagesProvider(trailId).overrideWith((ref) async => etapes),
        poisProvider(trailId).overrideWith((ref) async => pois),
      ],
    );
    addTearDown(container.dispose);
    await container.read(stagesProvider(trailId).future);
    await container.read(poisProvider(trailId).future);
    return container.read(supplyGapAlertProvider);
  }

  group('Le trou reel du Mare a Mare Centre — les vivres', () {
    test('SEULES Ghisonaccia, Cozzano et Porticcio ravitaillent', () {
      // Huit localites, vingt-quatre entrees, et TROIS etapes seulement ou
      // l on refait ses vivres : le depart, Cozzano, l arrivee.
      expect(catalogue.resupplyStages, [1, 2, 7]);
      // L ancien instrument, lui, voyait les sept etapes servies — d ou son
      // silence.
      expect(catalogue.supplyStages, [1, 2, 3, 4, 5, 6, 7]);
      expect(catalogue.gapAfter(2), 1);
      expect(catalogue.isGapAlert(2), isFalse);
    });

    test('CINQ ETAPES ET 52,5 KM entre Cozzano et Porticcio', () {
      // L ecart en etapes : de l etape 2 (Cozzano) a l etape 7 (Porticcio).
      expect(catalogue.resupplyGapAfter(2), 5);

      // Et la portee en kilometres, etape par etape, somme annoncee :
      //   etape 3 Cozzano -> Guitera-les-Bains      13,7
      //   etape 4 Guitera-les-Bains -> Quasquara      9,7
      //   etape 5 Quasquara -> Santa-Maria-Siche      8,1
      //   etape 6 Santa-Maria-Siche -> Bisinao        9,9
      //   etape 7 Bisinao -> Porticcio               11,1
      //                                            ------
      //                                              52,5
      final trou = etapes.where((e) => e.stageNumber >= 3).toList();
      expect(trou.length, 5);
      expect(trou.map((e) => e.distanceKm).toList(), [
        13.7,
        9.7,
        8.1,
        9.9,
        11.1,
      ]);
      final somme = trou.fold<double>(0, (a, e) => a + e.distanceKm);
      expect(somme, closeTo(52.5, 0.001));
    });

    test('L ALERTE SE DECLENCHE A COZZANO, et dit la taille du trou', () async {
      final alerte = await alerteSurEtape(2);
      expect(alerte, isNotNull, reason: 'muette, c est le defaut de la 834');
      expect(alerte!.kind, SupplyGapKind.food);
      expect(alerte.stageNumber, 2);
      expect(alerte.gap, 5);
      expect(alerte.km, closeTo(52.5, 0.001));
    });

    test('MOT POUR MOT, ce que le randonneur lit a Cozzano', () async {
      final alerte = await alerteSurEtape(2);
      final portee = nombreEnClair(alerte!.km!, 'fr');
      expect(portee, '52,5');
      expect(
        t.map.supplyGapRange(n: alerte.gap, km: portee),
        'Dernier ravitaillement avant 5 étapes et 52,5 km. '
        'Prévois tes réserves !',
      );
    });

    test('le trou se referme a Porticcio, et l alerte se tait', () async {
      // Etape 5 : plus que deux etapes avant Porticcio, sous le seuil.
      expect(catalogue.resupplyGapAfter(5), 2);
      expect(catalogue.isResupplyGapAlert(5), isFalse);
      // Etape 7, l arrivee : plus rien apres, donc aucun trou.
      expect(catalogue.resupplyGapAfter(7), 0);
      expect(await alerteSurEtape(7), isNull);
    });
  });

  group('Le trou reel du Mare a Mare Centre — l eau', () {
    test('QUATRE ETAPES portent un point d eau', () {
      // Cinq POI d eau releves dans OSM, sur quatre etapes : l etape 3 en
      // porte deux (la Funtana di Croce et les sources thermales de Guitera).
      final eau = pois.where((p) => p.type == 'water').toList();
      expect(eau.length, 5);
      final etapesDEau = eau.map((p) => p.stageNumber).toSet().toList()..sort();
      expect(etapesDEau, [1, 3, 4, 6]);
    });

    test(
      'DEUX TROUS D EAU DE DEUX ETAPES, que le seuil de l eau voit',
      () async {
        // Le seuil de l eau de ce sentier vaut 1 : un trou de deux etapes
        // alerte. Avec le seuil des vivres (2), les deux seraient passes sous
        // silence — c est precisement la demande de la tache 834.
        expect(catalogue.waterGapThreshold, 1);
        expect(catalogue.gapThreshold, 2);

        // Depuis l etape 1 : prochain point d eau a l etape 3.
        final apresGhisonaccia = await alerteSurEtape(1);
        expect(apresGhisonaccia, isNotNull);
        expect(apresGhisonaccia!.kind, SupplyGapKind.water);
        expect(apresGhisonaccia.gap, 2);
        // Etapes 2 et 3 : 14,9 + 13,7 = 28,6 km.
        expect(apresGhisonaccia.km, closeTo(28.6, 0.001));

        // Depuis l etape 4 : prochain point d eau a l etape 6.
        final apresQuasquara = await alerteSurEtape(4);
        expect(apresQuasquara, isNotNull);
        expect(apresQuasquara!.kind, SupplyGapKind.water);
        expect(apresQuasquara.gap, 2);
        // Etapes 5 et 6 : 8,1 + 9,9 = 18,0 km.
        expect(apresQuasquara.km, closeTo(18.0, 0.001));
      },
    );

    test('MOT POUR MOT, ce que le randonneur lit apres Ghisonaccia', () async {
      final alerte = await alerteSurEtape(1);
      final portee = nombreEnClair(alerte!.km!, 'fr');
      expect(portee, '28,6');
      expect(t.map.waterGapTitle, 'Points d\'eau limités');
      expect(
        t.map.waterGapRange(n: alerte.gap, km: portee),
        'Dernier point d\'eau avant 2 étapes et 28,6 km. Fais le plein !',
      );
    });

    test(
      'L EAU PASSE DEVANT A L ETAPE 4, ou les deux trous s ouvrent',
      () async {
        // A l etape 4 les vivres manquent AUSSI (trois etapes, 29,1 km) : une
        // seule alerte s affiche, et c est celle de l eau.
        expect(catalogue.isResupplyGapAlert(4), isTrue);
        expect(catalogue.resupplyGapAfter(4), 3);
        final alerte = await alerteSurEtape(4);
        expect(alerte!.kind, SupplyGapKind.water);
      },
    );
  });

  group('Le trou reel — la carte des sept etapes, etape par etape', () {
    test('ce que le randonneur voit a chacune des sept etapes', () async {
      // LE TABLEAU COMPLET, verrouille : il dit a la fois ce qui parle et ce
      // qui se tait, pour qu une regression se lise d un coup d oeil.
      final attendu = <int, String>{
        1: 'water 2 28.6',
        2: 'food 5 52.5',
        3: 'food 4 38.8',
        4: 'water 2 18.0',
        5: 'rien',
        6: 'rien',
        7: 'rien',
      };
      for (var etape = 1; etape <= 7; etape++) {
        final a = await alerteSurEtape(etape);
        final lu = a == null
            ? 'rien'
            : '${a.kind.name} ${a.gap} '
                  '${a.km!.toStringAsFixed(1)}';
        expect(lu, attendu[etape], reason: 'etape $etape');
      }
    });
  });
}
