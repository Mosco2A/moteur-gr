import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/trek_recorder.dart';
import 'package:moteur_gr/features/trek/domain/models/track_point.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';

void main() {
  group('TrekRecorder', () {
    // --- Stockage en memoire pour les tests ---
    late List<TrekSession> persistedSessions;
    late Map<String, List<TrackPoint>> flushedPoints;
    late TrekRecorder recorder;

    setUp(() {
      persistedSessions = [];
      flushedPoints = {};

      recorder = TrekRecorder(
        bufferSize: 10,
        onFlush: (sessionId, points) async {
          flushedPoints
              .putIfAbsent(sessionId, () => [])
              .addAll(points);
        },
        onSessionPersist: (session) async {
          persistedSessions.add(session);
        },
      );
    });

    /// Helper : genere un TrackPoint avec index comme altitude.
    TrackPoint makePoint(int index) => TrackPoint(
          lat: 42.0 + index * 0.001,
          lng: 9.0 + index * 0.001,
          elevation: index.toDouble(),
          timestamp: DateTime.utc(2026, 6, 15, 8, index),
        );

    test('buffer flush a 10 points', () async {
      // Demarrer une session
      final session = await recorder.start('sentier-bleu-nord');
      expect(session.status, equals('active'));
      expect(session.trailId, equals('sentier-bleu-nord'));
      expect(recorder.isRecording, isTrue);

      // Ajouter 9 points — pas de flush
      for (var i = 0; i < 9; i++) {
        await recorder.addPoint(makePoint(i));
      }
      expect(recorder.bufferCount, equals(9));
      expect(flushedPoints, isEmpty);

      // Le 10e point declenche le flush
      await recorder.addPoint(makePoint(9));
      expect(recorder.bufferCount, equals(0));
      expect(flushedPoints[session.id], isNotNull);
      expect(flushedPoints[session.id]!.length, equals(10));

      // Verifier l'ordre des points flushed
      for (var i = 0; i < 10; i++) {
        expect(flushedPoints[session.id]![i].elevation, equals(i.toDouble()));
      }

      // Ajouter 10 de plus — 2e flush
      for (var i = 10; i < 20; i++) {
        await recorder.addPoint(makePoint(i));
      }
      expect(recorder.bufferCount, equals(0));
      expect(flushedPoints[session.id]!.length, equals(20));

      // Cleanup
      await recorder.stop();
    });

    test('start/stop cree et finalise une session', () async {
      // Etat initial
      expect(recorder.isStopped, isTrue);
      expect(recorder.currentSession, isNull);

      // Demarrer
      final session = await recorder.start('mare-a-mare');
      expect(recorder.isRecording, isTrue);
      expect(recorder.currentSession, isNotNull);
      expect(session.id, isNotEmpty);
      expect(session.trailId, equals('mare-a-mare'));
      expect(session.status, equals('active'));
      expect(session.finishedAt, isNull);

      // Session persistee au start
      expect(persistedSessions.length, equals(1));
      expect(persistedSessions.first.status, equals('active'));

      // Ajouter quelques points (< 10, dans le buffer)
      for (var i = 0; i < 5; i++) {
        await recorder.addPoint(makePoint(i));
      }
      expect(recorder.bufferCount, equals(5));

      // Stopper — doit flush le buffer restant + finaliser la session
      final finalized = await recorder.stop();
      expect(finalized.status, equals('completed'));
      expect(finalized.finishedAt, isNotNull);
      expect(recorder.isStopped, isTrue);
      expect(recorder.currentSession, isNull);
      expect(recorder.bufferCount, equals(0));

      // Les 5 points ont ete flushed au stop
      expect(flushedPoints[session.id]!.length, equals(5));

      // Session persistee 2 fois : start (active) + stop (completed)
      expect(persistedSessions.length, equals(2));
      expect(persistedSessions.last.status, equals('completed'));
      expect(persistedSessions.last.finishedAt, isNotNull);
    });

    test('pause/resume controle le flux de points', () async {
      await recorder.start('sentier-bleu-sud');

      // Ajouter un point en mode recording
      await recorder.addPoint(makePoint(0));
      expect(recorder.bufferCount, equals(1));

      // Pause
      recorder.pause();
      expect(recorder.isPaused, isTrue);

      // Les points en pause sont ignores
      await recorder.addPoint(makePoint(1));
      await recorder.addPoint(makePoint(2));
      expect(recorder.bufferCount, equals(1));

      // Resume
      recorder.resume();
      expect(recorder.isRecording, isTrue);

      // Points acceptes a nouveau
      await recorder.addPoint(makePoint(3));
      expect(recorder.bufferCount, equals(2));

      await recorder.stop();
    });

    test('start sur session active leve StateError', () async {
      await recorder.start('sentier-bleu-nord');

      expect(
        () => recorder.start('sentier-bleu-sud'),
        throwsA(isA<StateError>()),
      );

      await recorder.stop();
    });

    test('stop sans session active leve StateError', () {
      expect(
        () => recorder.stop(),
        throwsA(isA<StateError>()),
      );
    });

    test('pause hors enregistrement leve StateError', () {
      expect(
        () => recorder.pause(),
        throwsA(isA<StateError>()),
      );
    });

    test('resume hors pause leve StateError', () async {
      await recorder.start('sentier-bleu-nord');

      // resume sans pause prealable
      expect(
        () => recorder.resume(),
        throwsA(isA<StateError>()),
      );

      await recorder.stop();
    });
  });
}
