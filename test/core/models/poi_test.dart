import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/pois_dao.dart';
import 'package:moteur_gr/core/models/poi.dart';

/// Tests du modele PoiModel (fromJson, toCompanion, String type, fromDb).
void main() {
  group('PoiModel', () {
    test('fromJson deserialise correctement', () {
      final json = {
        'id': 1,
        'trailId': 'trail1',
        'stageNumber': 2,
        'name': 'Refuge du Sommet',
        'description': 'Refuge garde',
        'type': 'shelter',
        'lat': 42.15,
        'lng': 9.10,
        'altitudeM': 1800,
        'openingHours': 'Juin-Sept',
      };

      final model = PoiModel.fromJson(json);
      expect(model.trailId, 'trail1');
      expect(model.name, 'Refuge du Sommet');
      expect(model.type, 'shelter');
      expect(model.altitudeM, 1800);
      expect(model.openingHours, 'Juin-Sept');
    });

    test('fromJson avec valeurs par defaut', () {
      final json = {
        'trailId': 'trail1',
        'stageNumber': 1,
        'name': 'POI',
        'type': 'water',
        'lat': 42.0,
        'lng': 9.0,
      };

      final model = PoiModel.fromJson(json);
      expect(model.id, 0);
      expect(model.description, '');
      expect(model.altitudeM, 0);
      expect(model.openingHours, isNull);
    });

    test('toCompanion genere un companion Drift valide', () {
      const model = PoiModel(
        trailId: 'trail1',
        stageNumber: 1,
        name: 'Source',
        type: 'water',
        lat: 42.0,
        lng: 9.0,
        altitudeM: 1200,
      );

      final companion = model.toCompanion();
      expect(companion.trailId.value, 'trail1');
      expect(companion.type.value, 'water');
      expect(companion.altitudeM.value, 1200);
    });

    test('fromDb roundtrip : insertion puis lecture', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final dao = PoisDao(db);

      const original = PoiModel(
        trailId: 'roundtrip',
        stageNumber: 1,
        name: 'Refuge Test',
        description: 'Un refuge de test',
        type: 'shelter',
        lat: 42.0,
        lng: 9.0,
        altitudeM: 1500,
        openingHours: 'Toute annee',
      );

      await dao.insertAll([original.toCompanion()]);
      final rows = await dao.getByTrailId('roundtrip');
      final restored = PoiModel.fromDb(rows.first);

      expect(restored.trailId, original.trailId);
      expect(restored.name, original.name);
      expect(restored.type, 'shelter');
      expect(restored.altitudeM, original.altitudeM);
      expect(restored.openingHours, original.openingHours);

      await db.close();
    });

    test('type String extensible accepte des types custom', () {
      const model = PoiModel(
        trailId: 't1',
        stageNumber: 1,
        name: 'Parking',
        type: 'parking',
        lat: 42.0,
        lng: 9.0,
      );
      expect(model.type, 'parking');
    });

    test('equality fonctionne avec freezed', () {
      const a = PoiModel(
        trailId: 't1', stageNumber: 1, name: 'A',
        type: 'water', lat: 42.0, lng: 9.0,
      );
      const b = PoiModel(
        trailId: 't1', stageNumber: 1, name: 'A',
        type: 'water', lat: 42.0, lng: 9.0,
      );
      expect(a, equals(b));
    });
  });
}
