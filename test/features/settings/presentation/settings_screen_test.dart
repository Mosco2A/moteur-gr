import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests E3.9b SettingsScreen - ecran affiche parametres actuels.
///
/// Verifie que :
/// - les textes Slang settings sont presents dans les 5 langues
/// - le provider AppSettings expose les bonnes valeurs par defaut
/// - les 6 sections (langue, unites, theme, cache, notifications, version)
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    LocaleSettings.setLocaleRaw('fr');
  });

  group('E3.9b SettingsScreen affiche parametres actuels', () {
    test('textes Slang settings complets en FR', () {
      // GIVEN: Slang initialise en francais
      LocaleSettings.setLocaleRaw('fr');

      // THEN: toutes les cles settings presentes et non vides
      final s = t.settings;
      expect(s.title, isNotEmpty);
      expect(s.language, isNotEmpty);
      expect(s.units, isNotEmpty);
      expect(s.distance, isNotEmpty);
      expect(s.temperature, isNotEmpty);
      expect(s.theme, isNotEmpty);
      expect(s.dark, isNotEmpty);
      expect(s.light, isNotEmpty);
      expect(s.system, isNotEmpty);
      expect(s.cache, isNotEmpty);
      expect(s.cacheEnabled, isNotEmpty);
      expect(s.cacheDesc, isNotEmpty);
      expect(s.cacheSize, isNotEmpty);
      expect(s.notifications, isNotEmpty);
      expect(s.morningReminder, isNotEmpty);
      expect(s.weatherAlerts, isNotEmpty);
      expect(s.weatherAlertsDesc, isNotEmpty);
      expect(s.countdownReminder, isNotEmpty);
      expect(s.countdownDesc, isNotEmpty);
      expect(s.version, isNotEmpty);
      expect(s.versionLabel, isNotEmpty);
    });

    test('textes Slang settings presents dans les 5 langues', () {
      for (final locale in ['fr', 'en', 'de', 'es', 'it']) {
        LocaleSettings.setLocaleRaw(locale);
        expect(t.settings.title, isNotEmpty,
            reason: 'title manquant pour $locale');
        expect(t.settings.language, isNotEmpty,
            reason: 'language manquant pour $locale');
        expect(t.settings.units, isNotEmpty,
            reason: 'units manquant pour $locale');
        expect(t.settings.theme, isNotEmpty,
            reason: 'theme manquant pour $locale');
        expect(t.settings.cache, isNotEmpty,
            reason: 'cache manquant pour $locale');
        expect(t.settings.notifications, isNotEmpty,
            reason: 'notifications manquant pour $locale');
        expect(t.settings.version, isNotEmpty,
            reason: 'version manquant pour $locale');
        expect(t.settings.versionLabel, isNotEmpty,
            reason: 'versionLabel manquant pour $locale');
        expect(t.settings.morningReminder, isNotEmpty,
            reason: 'morningReminder manquant pour $locale');
        expect(t.settings.weatherAlerts, isNotEmpty,
            reason: 'weatherAlerts manquant pour $locale');
        expect(t.settings.countdownReminder, isNotEmpty,
            reason: 'countdownReminder manquant pour $locale');
      }

      // Retour au francais
      LocaleSettings.setLocaleRaw('fr');
    });

    test('provider AppSettings expose valeurs par defaut pour toutes les sections', () {
      // GIVEN: un container Riverpod avec le provider settings
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // WHEN: on lit les parametres
      final settings = container.read(settingsProvider);

      // THEN: section langue - francais par defaut
      expect(settings.language, AppLanguageValues.fr);
      expect(AppLanguageValues.values.length, 5,
          reason: '5 langues: fr, en, de, it, es');

      // THEN: section unites - metriques par defaut
      expect(settings.distanceUnit, DistanceUnitValues.km);
      expect(settings.temperatureUnit, TemperatureUnitValues.celsius);

      // THEN: section theme - dark par defaut
      expect(settings.themeMode, AppThemeModeValues.dark);
      expect(AppThemeModeValues.values.length, 3,
          reason: '3 modes: dark, light, system');

      // THEN: section cache - active par defaut, 500 Mo
      expect(settings.cacheEnabled, true);
      expect(settings.cacheSizeMb, 500);
    });

    test('provider repercute les modifications de parametres', () {
      // GIVEN: un container Riverpod
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // WHEN: on modifie chaque section
      container.read(settingsProvider.notifier).setLanguage(AppLanguageValues.en);
      container.read(settingsProvider.notifier).setDistanceUnit(DistanceUnitValues.miles);
      container.read(settingsProvider.notifier).setTemperatureUnit(TemperatureUnitValues.fahrenheit);
      container.read(settingsProvider.notifier).setThemeMode(AppThemeModeValues.light);
      container.read(settingsProvider.notifier).setCacheEnabled(false);
      container.read(settingsProvider.notifier).setCacheSizeMb(1000);

      // THEN: toutes les modifications sont refletees
      final settings = container.read(settingsProvider);
      expect(settings.language, AppLanguageValues.en);
      expect(settings.distanceUnit, DistanceUnitValues.miles);
      expect(settings.temperatureUnit, TemperatureUnitValues.fahrenheit);
      expect(settings.themeMode, AppThemeModeValues.light);
      expect(settings.cacheEnabled, false);
      expect(settings.cacheSizeMb, 1000);
    });
  });
}
