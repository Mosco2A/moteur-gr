import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/diploma/domain/finisher_number.dart';

/// CORRECTIF L5-7 — NUMERO DE FINISHER (arbitrage ARB-3, option par defaut).
///
/// Le numero du journal de reference est un LITTERAL EN DUR : le meme pour
/// tous, a chaque session, sans compteur ni serveur. Il n'y avait rien a
/// greffer. Celui-ci est derive de la session : LISIBLE, HORODATE, STABLE
/// — et volontairement PAS unique a l'echelle mondiale, ce qui est
/// impossible sans serveur.
void main() {
  group('L5-7 — numero de finisher', () {
    test('forme lisible et horodatee sur la date de fin', () {
      final number = buildFinisherNumber(
        sessionId: 'sess-abc-123',
        finishedAt: DateTime(2026, 6, 16, 18, 30),
      );

      expect(number, startsWith('SW-20260616-'));
      expect(RegExp(r'^SW-\d{8}-[0-9A-F]{4}$').hasMatch(number), isTrue,
          reason: 'Forme SW-AAAAMMJJ-XXXX, lisible et recopiable a la main');
    });

    test('STABLE : la meme session rend toujours le meme numero', () {
      final a = buildFinisherNumber(
        sessionId: 'sess-abc-123',
        finishedAt: DateTime(2026, 6, 16, 18, 30),
      );
      final b = buildFinisherNumber(
        sessionId: 'sess-abc-123',
        // Meme journee, heure differente : le numero ne bouge pas.
        finishedAt: DateTime(2026, 6, 16, 23, 59),
      );

      expect(a, b);
    });

    test('deux sessions du meme jour ne portent pas le meme numero', () {
      final a = buildFinisherNumber(
        sessionId: 'sess-abc-123',
        finishedAt: DateTime(2026, 6, 16),
      );
      final b = buildFinisherNumber(
        sessionId: 'sess-abc-124',
        finishedAt: DateTime(2026, 6, 16),
      );

      expect(a, isNot(b));
    });

    test('deux identifiants permutes ne collent pas au meme suffixe', () {
      // Un simple total de codes de caracteres les confondrait.
      final a = buildFinisherNumber(
        sessionId: 'ab',
        finishedAt: DateTime(2026, 6, 16),
      );
      final b = buildFinisherNumber(
        sessionId: 'ba',
        finishedAt: DateTime(2026, 6, 16),
      );

      expect(a, isNot(b));
    });
  });
}
