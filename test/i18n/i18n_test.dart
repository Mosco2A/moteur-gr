import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/i18n/i18n_setup.dart';

void main() {
  group('Slang i18n', () {
    test('5 locales sont supportees (fr, en, de, it, es)', () {
      // Verifier que AppLocale contient bien 5 valeurs
      expect(AppLocale.values.length, equals(5));

      // Verifier les codes de langue
      final localeTags = AppLocale.values.map((l) => l.languageTag).toList();
      expect(localeTags, contains('fr'));
      expect(localeTags, contains('en'));
      expect(localeTags, contains('de'));
      expect(localeTags, contains('it'));
      expect(localeTags, contains('es'));
    });

    test('les constantes i18n_setup matchent les locales generees', () {
      // Verifier la coherence entre la config et le code genere
      expect(supportedLocales.length, equals(AppLocale.values.length));
      expect(defaultLocale, equals('fr'));

      // Chaque locale de la config doit exister dans le code genere
      for (final code in supportedLocales) {
        final found = AppLocale.values.any(
          (l) => l.languageTag == code,
        );
        expect(found, isTrue,
            reason: 'Locale $code doit exister dans AppLocale');
      }
    });
  });
}
