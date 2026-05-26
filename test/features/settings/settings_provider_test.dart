import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';

/// Tests du provider de paramètres.
void main() {
  group('AppSettings', () {
    test('valeurs par défaut correctes', () {
      const settings = AppSettings();
      expect(settings.language, AppLanguage.fr);
      expect(settings.distanceUnit, DistanceUnit.km);
      expect(settings.temperatureUnit, TemperatureUnit.celsius);
      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.cacheEnabled, true);
      expect(settings.cacheSizeMb, 500);
    });

    test('copyWith modifie la langue', () {
      const settings = AppSettings();
      final updated = settings.copyWith(language: AppLanguage.en);
      expect(updated.language, AppLanguage.en);
      expect(updated.distanceUnit, DistanceUnit.km); // Pas modifié
    });

    test('copyWith modifie les unités de distance', () {
      const settings = AppSettings();
      final updated = settings.copyWith(distanceUnit: DistanceUnit.miles);
      expect(updated.distanceUnit, DistanceUnit.miles);
    });

    test('copyWith modifie les unités de température', () {
      const settings = AppSettings();
      final updated = settings.copyWith(temperatureUnit: TemperatureUnit.fahrenheit);
      expect(updated.temperatureUnit, TemperatureUnit.fahrenheit);
    });

    test('copyWith modifie le thème', () {
      const settings = AppSettings();
      final updated = settings.copyWith(themeMode: AppThemeMode.light);
      expect(updated.themeMode, AppThemeMode.light);
    });

    test('copyWith modifie le cache', () {
      const settings = AppSettings();
      final updated = settings.copyWith(cacheEnabled: false, cacheSizeMb: 1000);
      expect(updated.cacheEnabled, false);
      expect(updated.cacheSizeMb, 1000);
    });
  });

  group('AppLanguage', () {
    test('5 langues disponibles', () {
      expect(AppLanguage.values.length, 5);
    });

    test('codes langue corrects', () {
      expect(AppLanguage.fr.code, 'fr');
      expect(AppLanguage.en.code, 'en');
      expect(AppLanguage.de.code, 'de');
      expect(AppLanguage.it.code, 'it');
      expect(AppLanguage.es.code, 'es');
    });
  });

  group('DistanceUnit', () {
    test('symboles corrects', () {
      expect(DistanceUnit.km.symbol, 'km');
      expect(DistanceUnit.miles.symbol, 'mi');
    });
  });

  group('TemperatureUnit', () {
    test('symboles corrects', () {
      expect(TemperatureUnit.celsius.symbol, '°C');
      expect(TemperatureUnit.fahrenheit.symbol, '°F');
    });
  });
}
