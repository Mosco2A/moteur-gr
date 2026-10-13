// Test miroir de `lib/features/trek/domain/accumulateur_de_pas.dart` (lot
// 671-02) : l'origine, la reprise, l'erreur, et le vocabulaire ferme de
// l'estime. Le recul et le paquet sont prouves dans
// `test/comportement/longueur_de_pas_671_test.dart`.
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/domain/accumulateur_de_pas.dart';

void main() {
  group('671-02 — l accumulateur de pas', () {
    test('sans evenement le total est nul ; le premier donne l origine et '
        'ajoute zero pas', () {
      final pas = StepAccumulator();
      expect(pas.total, isNull);
      pas.add(12000);
      expect(pas.total, 0);
      expect(pas.lastRaw, 12000);
    });

    test('une session reprise garde son total des le depart, et compte les '
        'pas faits application fermee', () {
      final pas = StepAccumulator.resumed(total: 400, lastRaw: 1400);
      expect(pas.total, 400);
      pas.add(1550);
      expect(pas.total, 550);
    });

    test('une session reprise apres un redemarrage du telephone ne perd '
        'rien de ce qu elle avait', () {
      final pas = StepAccumulator.resumed(total: 400, lastRaw: 1400)
        ..add(30)
        ..add(80);
      expect(pas.total, 450);
    });

    test('une erreur rend le total nul, mais garde les pas comptes', () {
      final pas = StepAccumulator()
        ..add(100)
        ..add(160)
        ..fail();
      expect(pas.total, isNull);
      expect(pas.banked, 60);
      expect(pas.failed, isTrue);
    });
  });

  group('671-02 — le vocabulaire ferme de l estime', () {
    test('quatre mots, et pas un de plus', () {
      expect(EstimateReadiness.values.map((r) => r.word), [
        'possible',
        'autorisation_refusee',
        'podometre_indisponible',
        'flux_en_erreur',
      ]);
    });

    test('un mot inconnu ou absent ne vaut rien', () {
      expect(
        EstimateReadiness.fromWord('possible'),
        EstimateReadiness.possible,
      );
      expect(EstimateReadiness.fromWord('estime'), isNull);
      expect(EstimateReadiness.fromWord(null), isNull);
    });
  });
}
