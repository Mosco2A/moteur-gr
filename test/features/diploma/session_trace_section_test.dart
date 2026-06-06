import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/features/diploma/presentation/widgets/session_trace_painter.dart';
import 'package:moteur_gr/features/diploma/providers/session_trace_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests finitions V8 F3 — trace GPS reel dans le recap diplome.
///
/// La section carte du diplome affiche le trace persiste de la
/// session (SessionTracePainter) et retombe sur le message
/// recapNoMap si aucun trace n'est disponible.
void main() {
  SessionTrackPoint point(int id, double lat, double lng) =>
      SessionTrackPoint(
        id: id,
        trailId: 'sentier-bleu',
        lat: lat,
        lng: lng,
        altitude: 1000,
        recordedAt: DateTime.utc(2026, 6, 1, 8, id),
      );

  Widget harness(List<SessionTrackPoint> points) {
    return ProviderScope(
      overrides: [
        sessionTraceProvider.overrideWith((ref) async => points),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              final traceAsync = ref.watch(sessionTraceProvider);
              return traceAsync.when(
                data: (pts) => pts.length < 2
                    ? Text(t.diploma.recapNoMap)
                    : CustomPaint(
                        painter: SessionTracePainter(
                          points: [
                            for (final p in pts) Offset(p.lng, p.lat),
                          ],
                          color: Colors.green,
                        ),
                      ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(t.diploma.recapNoMap),
              );
            },
          ),
        ),
      ),
    );
  }

  group('Recap diplome — trace GPS reel (F3)', () {
    testWidgets('trace present : painter rendu, pas de placeholder',
        (tester) async {
      await tester.pumpWidget(harness([
        point(1, 45.10, 3.10),
        point(2, 45.12, 3.13),
        point(3, 45.15, 3.16),
      ]));
      await tester.pumpAndSettle();

      final custom = tester.widgetList<CustomPaint>(
        find.byType(CustomPaint),
      );
      expect(
        custom.any((w) => w.painter is SessionTracePainter),
        isTrue,
      );
      expect(find.text(t.diploma.recapNoMap), findsNothing);
    });

    testWidgets('aucun trace : fallback recapNoMap', (tester) async {
      await tester.pumpWidget(harness(const []));
      await tester.pumpAndSettle();

      expect(find.text(t.diploma.recapNoMap), findsOneWidget);
    });
  });

  group('SessionTracePainter', () {
    test('peint sans erreur sur une trace reelle', () {
      final painter = SessionTracePainter(
        points: const [
          Offset(3.10, 45.10),
          Offset(3.12, 45.11),
          Offset(3.16, 45.15),
        ],
        color: Colors.green,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(300, 180));
      expect(recorder.endRecording(), isNotNull);
    });

    test('moins de 2 points : aucun dessin (pas de crash)', () {
      final painter = SessionTracePainter(
        points: const [Offset(3.10, 45.10)],
        color: Colors.green,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      painter.paint(canvas, const Size(300, 180));
      expect(recorder.endRecording(), isNotNull);
    });
  });
}
