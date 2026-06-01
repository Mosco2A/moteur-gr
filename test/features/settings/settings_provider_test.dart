import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';

/// Tests du provider de parametres (modele AppSettings + types).
void main() {
  group('AppSettings', () {
    test('valeurs par defaut correctes', () {
      const settings = AppSettings();
      expect(settings.language, AppLanguageValues.fr);
      expect(settings.distanceUnit, DistanceUnitValues.km);
      expect(settings.temperatureUnit, TemperatureUnitValues.celsius);
      expect(settings.themeMode, AppThemeModeValues.dark);
      expect(settings.cacheEnabled, true);
      expect(settings.cacheSizeMb, 500);
    });

    test('copyWith modifie la langue', () {
      const settings = AppSettings();
      final updated = settings.copyWith(language: AppLanguageValues.en);
      expect(updated.language, AppLanguageValues.en);
      expect(updated.distanceUnit, DistanceUnitValues.km);
    });

    test('copyWith modifie les unites de distance', () {
      const settings = AppSettings();
      final updated = settings.copyWith(distanceUnit: DistanceUnitValues.miles);
      expect(updated.distanceUnit, DistanceUnitValues.miles);
    });

    test('copyWith modifie les unites de temperature', () {
      const settings = AppSettings();
      final updated = settings.copyWith(temperatureUnit: TemperatureUnitValues.fahrenheit);
      expect(updated.temperatureUnit, TemperatureUnitValues.fahrenheit);
    });

    test('copyWith modifie le theme', () {
      const settings = AppSettings();
      final updated = settings.copyWith(themeMode: AppThemeModeValues.light);
      expect(updated.themeMode, AppThemeModeValues.light);
    });

    test('copyWith modifie le cache', () {
      const settings = AppSettings();
      final updated = settings.copyWith(cacheEnabled: false, cacheSizeMb: 1000);
      expect(updated.cacheEnabled, false);
      expect(updated.cacheSizeMb, 1000);
    });
  });

  group('AppLanguageValues', () {
    test('5 langues disponibles', () {
      expect(AppLanguageValues.values.length, 5);
    });

    test('labels corrects', () {
      expect(AppLanguageValues.labelFor('fr'), 'Francais');
      expect(AppLanguageValues.labelFor('en'), 'English');
      expect(AppLanguageValues.labelFor('de'), 'Deutsch');
      expect(AppLanguageValues.labelFor('it'), 'Italiano');
      expect(AppLanguageValues.labelFor('es'), 'Espanol');
    });

    test('fromString avec valeur inconnue retourne fallback', () {
      expect(AppLanguageValues.fromString('xx'), AppLanguageValues.fallback);
    });
  });

  group('DistanceUnitValues', () {
    test('symboles corrects', () {
      expect(DistanceUnitValues.symbolFor('km'), 'km');
      expect(DistanceUnitValues.symbolFor('miles'), 'mi');
    });
  });

  group('TemperatureUnitValues', () {
    test('symboles corrects', () {
      expect(TemperatureUnitValues.symbolFor('celsius'), '°C');
      expect(TemperatureUnitValues.symbolFor('fahrenheit'), '°F');
    });
  });
}
