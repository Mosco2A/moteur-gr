import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/stage.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';

void main() {
  group('Stage', () {
    test('fromJson roundtrip — serialisation et deserialisation identiques', () {
      final json = {
        'id': 'stage-001',
        'nameFr': 'Calenzana - Ortu di u Piobbu',
        'nameEn': 'Calenzana - Ortu di u Piobbu',
        'nameDe': 'Calenzana - Ortu di u Piobbu',
        'nameIt': 'Calenzana - Ortu di u Piobbu',
        'nameEs': 'Calenzana - Ortu di u Piobbu',
        'distance': 12.5,
        'elevationGain': 1500,
        'elevationLoss': 200,
        'estimatedDurationMinutes': 420,
        'difficulty': 'hard',
        'orderIndex': 0,
        'startLat': 42.5075,
        'startLng': 8.8553,
        'endLat': 42.4631,
        'endLng': 8.9375,
        'descriptionFr': 'Premiere etape du GR20 Nord',
        'descriptionEn': 'First stage of GR20 North',
        'descriptionDe': '',
        'descriptionIt': '',
        'descriptionEs': '',
      };

      final stage = Stage.fromJson(json);

      // Verifier les champs
      expect(stage.id, 'stage-001');
      expect(stage.nameFr, 'Calenzana - Ortu di u Piobbu');
      expect(stage.nameEn, 'Calenzana - Ortu di u Piobbu');
      expect(stage.distance, 12.5);
      expect(stage.elevationGain, 1500);
      expect(stage.elevationLoss, 200);
      expect(stage.estimatedDurationMinutes, 420);
      expect(stage.estimatedDuration, const Duration(hours: 7));
      expect(stage.difficulty, 'hard');
      expect(stage.orderIndex, 0);
      expect(stage.startLat, 42.5075);
      expect(stage.startLng, 8.8553);
      expect(stage.endLat, 42.4631);
      expect(stage.endLng, 8.9375);
      expect(stage.descriptionFr, 'Premiere etape du GR20 Nord');

      // Roundtrip: toJson -> fromJson = identique
      final reEncoded = jsonEncode(stage.toJson());
      final reDecoded = Stage.fromJson(jsonDecode(reEncoded) as Map<String, dynamic>);
      expect(reDecoded, equals(stage));
    });

    test('difficulty String inconnue ne crash pas', () {
      final json = {
        'id': 'stage-x',
        'nameFr': 'Etape test',
        'nameEn': 'Test stage',
        'distance': 5.0,
        'elevationGain': 300,
        'elevationLoss': 100,
        'estimatedDurationMinutes': 180,
        'difficulty': 'ultra_extreme_variant_2027',
        'orderIndex': 99,
        'startLat': 42.0,
        'startLng': 9.0,
        'endLat': 42.1,
        'endLng': 9.1,
      };

      // Pas de crash, la valeur String inconnue est acceptee telle quelle
      final stage = Stage.fromJson(json);
      expect(stage.difficulty, 'ultra_extreme_variant_2027');

      // Roundtrip conserve la valeur inconnue
      final roundtripped = Stage.fromJson(stage.toJson());
      expect(roundtripped.difficulty, 'ultra_extreme_variant_2027');
    });
  });

  group('TrekSession', () {
    test('serialization — toJson/fromJson roundtrip avec DateTime', () {
      final now = DateTime(2026, 5, 28, 14, 30, 0);
      final later = DateTime(2026, 5, 28, 21, 45, 0);

      final session = TrekSession(
        id: 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        trailId: 'gr20-north',
        startedAt: now,
        finishedAt: later,
        status: 'completed',
      );

      // Verifier les champs de base
      expect(session.id, 'a1b2c3d4-e5f6-7890-abcd-ef1234567890');
      expect(session.trailId, 'gr20-north');
      expect(session.startedAt, now);
      expect(session.finishedAt, later);
      expect(session.status, 'completed');
      expect(session.isFinished, isTrue);
      expect(session.elapsed, const Duration(hours: 7, minutes: 15));

      // Roundtrip: toJson -> fromJson = identique
      final jsonStr = jsonEncode(session.toJson());
      final restored = TrekSession.fromJson(
        jsonDecode(jsonStr) as Map<String, dynamic>,
      );
      expect(restored.id, session.id);
      expect(restored.trailId, session.trailId);
      expect(restored.startedAt, session.startedAt);
      expect(restored.finishedAt, session.finishedAt);
      expect(restored.status, session.status);

      // Session active (finishedAt null)
      final active = TrekSession(
        id: 'active-uuid',
        trailId: 'gr20-south',
        startedAt: now,
        status: 'active',
      );
      expect(active.isFinished, isFalse);
      expect(active.finishedAt, isNull);

      // Roundtrip session active
      final activeJson = jsonEncode(active.toJson());
      final activeRestored = TrekSession.fromJson(
        jsonDecode(activeJson) as Map<String, dynamic>,
      );
      expect(activeRestored.finishedAt, isNull);
      expect(activeRestored.status, 'active');

      // Statut String inconnu
      final unknown = TrekSession(
        id: 'unknown-uuid',
        trailId: 'tmb',
        startedAt: now,
        status: 'emergency_stop_v3',
      );
      final unknownRoundtripped = TrekSession.fromJson(unknown.toJson());
      expect(unknownRoundtripped.status, 'emergency_stop_v3');
    });
  });
}
