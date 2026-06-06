import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';

void main() {
  group('TrekSession', () {
    test('serialization roundtrip', () {
      final session = TrekSession(
        id: '550e8400-e29b-41d4-a716-446655440000',
        trailId: 'sentier-bleu-nord',
        startedAt: DateTime.utc(2026, 6, 15, 7, 30),
        finishedAt: DateTime.utc(2026, 6, 15, 18, 45),
        status: 'completed',
      );

      final json = session.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = TrekSession.fromJson(decoded);

      expect(restored, equals(session));
      expect(restored.id, equals('550e8400-e29b-41d4-a716-446655440000'));
      expect(restored.trailId, equals('sentier-bleu-nord'));
      expect(restored.startedAt, equals(DateTime.utc(2026, 6, 15, 7, 30)));
      expect(restored.finishedAt, equals(DateTime.utc(2026, 6, 15, 18, 45)));
      expect(restored.status, equals('completed'));
    });

    test('serialization avec finishedAt null', () {
      final session = TrekSession(
        id: 'abc-123',
        trailId: 'mare-a-mare',
        startedAt: DateTime.utc(2026, 7, 1, 8, 0),
        status: 'active',
      );

      final json = session.toJson();
      final jsonString = jsonEncode(json);
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final restored = TrekSession.fromJson(decoded);

      expect(restored.finishedAt, isNull);
      expect(restored.status, equals('active'));
    });

    test('status String extensible', () {
      final session = TrekSession(
        id: 'def-456',
        trailId: 'sentier-bleu-sud',
        startedAt: DateTime.utc(2026, 8, 1),
        status: 'paused',
      );

      expect(session.status, equals('paused'));

      final abandoned = session.copyWith(status: 'abandoned');
      expect(abandoned.status, equals('abandoned'));

      final custom = session.copyWith(status: 'weather_hold');
      expect(custom.status, equals('weather_hold'));

      // JSON roundtrip avec status custom
      final json = custom.toJson();
      final restored = TrekSession.fromJson(json);
      expect(restored.status, equals('weather_hold'));
    });
  });
}
