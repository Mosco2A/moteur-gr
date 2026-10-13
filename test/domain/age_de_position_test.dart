import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/age_de_position.dart';

/// LOT 671-04 — L'AGE D'UNE POSITION, AUX BORNES, SUR UNE HORLOGE INJECTEE
/// (fiche E7 (4)). Une fonction PURE : le test l'appelle sans monter de
/// widget. L'arrondi est vers le BAS : 179 s font deux minutes, jamais trois.
void main() {
  final t0 = DateTime(2026, 10, 7, 14);

  group('(4) L AGE, AUX BORNES, SUR UNE HORLOGE INJECTEE — une fonction pure, '
      'appelee sans monter de widget', () {
    AgeEnClair? age(int secondes) => ageEnClair(
      mesureeA: t0,
      maintenant: t0.add(Duration(seconds: secondes)),
    );

    test('0 s et 59 s : a l instant', () {
      expect(age(0), isNull);
      expect(age(59), isNull);
    });

    test('60 s, 61 s et 119 s : une minute', () {
      for (final s in [60, 61, 119]) {
        expect(age(s), (heures: 0, minutes: 1), reason: '$s s');
      }
    });

    test('179 s : DEUX minutes, JAMAIS trois — l arrondi est vers le bas', () {
      expect(age(179), (heures: 0, minutes: 2));
    });

    test('3 600 s : une heure ; 3 725 s : une heure et deux minutes', () {
      expect(age(3600), (heures: 1, minutes: 0));
      expect(age(3725), (heures: 1, minutes: 2));
    });

    test('une heure de mesure dans le futur (horloge d un autre appareil) : '
        'a l instant, jamais un age negatif', () {
      expect(age(-30), isNull);
    });
  });
}
