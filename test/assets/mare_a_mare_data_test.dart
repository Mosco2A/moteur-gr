import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/models/stage.dart';

/// Tests de validation des donnees Mare a Mare Centre.
/// Verifie que les JSON sont valides et parseables par les modeles Freezed.
void main() {
  group('Mare a Mare Centre data', () {
    test('stages.json est valide et contient 7 etapes', () {
      final file = File('assets/data/mare_a_mare_centre/stages.json');
      expect(file.existsSync(), isTrue,
          reason: 'stages.json doit exister');

      final content = file.readAsStringSync();
      final List<dynamic> stages = jsonDecode(content);

      expect(stages.length, 7, reason: 'Le Mare a Mare Centre a 7 etapes');

      // Verifier que chaque etape a les champs requis
      for (final stage in stages) {
        final map = stage as Map<String, dynamic>;
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('trailId'), isTrue);
        expect(map.containsKey('stageNumber'), isTrue);
        expect(map.containsKey('nameFr'), isTrue);
        expect(map.containsKey('nameEn'), isTrue);
        expect(map.containsKey('distanceKm'), isTrue);
        expect(map.containsKey('elevationGainM'), isTrue);
        expect(map.containsKey('elevationLossM'), isTrue);
        expect(map.containsKey('difficulty'), isTrue);
        expect(map.containsKey('startLat'), isTrue);
        expect(map.containsKey('startLng'), isTrue);
        expect(map.containsKey('endLat'), isTrue);
        expect(map.containsKey('endLng'), isTrue);

        // Coordonnees en Corse (lat ~41.8-42.1, lng ~8.8-9.5)
        final lat = (map['startLat'] as num).toDouble();
        final lng = (map['startLng'] as num).toDouble();
        expect(lat, greaterThan(41.5), reason: 'Latitude Corse > 41.5');
        expect(lat, lessThan(42.5), reason: 'Latitude Corse < 42.5');
        expect(lng, greaterThan(8.5), reason: 'Longitude Corse > 8.5');
        expect(lng, lessThan(9.6), reason: 'Longitude Corse < 9.6');

        // Distance positive et realiste
        final dist = (map['distanceKm'] as num).toDouble();
        expect(dist, greaterThan(0));
        expect(dist, lessThan(30), reason: 'Distance etape < 30km');
      }

      // Verifier l ordre des etapes
      for (int i = 0; i < stages.length; i++) {
        expect(stages[i]['stageNumber'], i + 1);
      }

      // Verifier parseable par StageModel (core)
      for (final stage in stages) {
        final map = stage as Map<String, dynamic>;
        // Adapter au format StageModel.fromJson
        final stageModelJson = {
          'trailId': map['trailId'],
          'stageNumber': map['stageNumber'],
          'name': map['nameFr'],
          'distanceKm': map['distanceKm'],
          'elevationGainM': map['elevationGainM'],
          'elevationLossM': map['elevationLossM'],
          'description': map['descriptionFr'] ?? '',
          'startLat': map['startLat'],
          'startLng': map['startLng'],
          'endLat': map['endLat'],
          'endLng': map['endLng'],
          'difficulty': map['difficulty'],
        };
        final model = StageModel.fromJson(stageModelJson);
        expect(model.trailId, 'mare-a-mare-centre');
        expect(model.distanceKm, greaterThan(0));
      }
    });

    test('pois.json est valide et contient 20 POIs', () {
      final file = File('assets/data/mare_a_mare_centre/pois.json');
      expect(file.existsSync(), isTrue,
          reason: 'pois.json doit exister');

      final content = file.readAsStringSync();
      final List<dynamic> pois = jsonDecode(content);

      expect(pois.length, 20, reason: 'Au moins 20 POIs attendus');

      // Types valides
      final validTypes = {'shelter', 'water', 'viewpoint', 'info', 'shop', 'danger', 'campsite', 'restaurant', 'emergency', 'village'};

      for (final poi in pois) {
        final map = poi as Map<String, dynamic>;
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('stageId'), isTrue);
        expect(map.containsKey('nameFr'), isTrue);
        expect(map.containsKey('type'), isTrue);
        expect(map.containsKey('lat'), isTrue);
        expect(map.containsKey('lng'), isTrue);

        // Type connu
        expect(validTypes.contains(map['type']), isTrue,
            reason: 'Type POI inconnu: ${map["type"]}');

        // Coordonnees en Corse
        final lat = (map['lat'] as num).toDouble();
        final lng = (map['lng'] as num).toDouble();
        expect(lat, greaterThan(41.5));
        expect(lat, lessThan(42.5));
        expect(lng, greaterThan(8.5));
        expect(lng, lessThan(9.6));
      }
    });

    test('track.gpx est valide et contient des points', () {
      final file = File('assets/data/mare_a_mare_centre/track.gpx');
      expect(file.existsSync(), isTrue,
          reason: 'track.gpx doit exister');

      final content = file.readAsStringSync();

      // Verifier structure XML de base
      expect(content.contains('<?xml'), isTrue);
      expect(content.contains('<gpx'), isTrue);
      expect(content.contains('<trk>'), isTrue);
      expect(content.contains('<trkseg>'), isTrue);
      expect(content.contains('<trkpt'), isTrue);
      expect(content.contains('</gpx>'), isTrue);

      // Compter les points de trace
      final trkptCount = RegExp(r'<trkpt').allMatches(content).length;
      expect(trkptCount, greaterThanOrEqualTo(40),
          reason: 'Au moins 40 points de trace attendus');
    });

    test('coherence stages-pois: chaque POI reference un stage valide', () {
      final stagesFile = File('assets/data/mare_a_mare_centre/stages.json');
      final poisFile = File('assets/data/mare_a_mare_centre/pois.json');

      final stages = jsonDecode(stagesFile.readAsStringSync()) as List<dynamic>;
      final pois = jsonDecode(poisFile.readAsStringSync()) as List<dynamic>;

      final stageIds = stages.map((s) => s['id'] as String).toSet();

      for (final poi in pois) {
        final map = poi as Map<String, dynamic>;
        expect(stageIds.contains(map['stageId']), isTrue,
            reason: 'POI ${map["id"]} reference un stage inexistant: ${map["stageId"]}');
      }
    });
  });
}
