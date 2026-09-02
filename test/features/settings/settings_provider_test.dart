import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/providers/feasibility_provider.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/features/settings/providers/sync_settings_provider.dart';
import 'package:moteur_gr/features/share/providers/visibility_settings_provider.dart';
import 'package:moteur_gr/features/training/providers/training_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('SettingsNotifier — robustesse dispose pendant le load', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
        'dispose du container pendant le _load async ne leve pas '
        '« Ref used after dispose »', () async {
      final container = ProviderContainer();

      // Declenche build() -> _load() (async : await SettingsService.create()).
      expect(container.read(settingsProvider), const AppSettings());

      // Dispose AVANT que le microtask de load ne reprenne apres l'await :
      // sans le garde `ref.mounted`, l'ecriture `state = ...` post-await
      // leverait « Ref used after dispose » (Riverpod 3).
      container.dispose();

      // Laisse le _load reprendre : le garde doit court-circuiter proprement.
      await Future<void>.delayed(Duration.zero);
      // Pas d'exception => garde effectif (le test echouerait sur throw async).
    });

    test('sans dispose, la valeur persistee est bien relue apres le load',
        () async {
      SharedPreferences.setMockInitialValues({
        'settings_language': AppLanguageValues.en,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Etat initial = defaut, puis ecrase par la valeur relue.
      expect(container.read(settingsProvider).language, AppLanguageValues.fr);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(settingsProvider).language, AppLanguageValues.en);
    });
  });

  // Meme durcissement anti-dispose (garde `ref.mounted` apres l'await, comme
  // SkinNotifier / SW-SKIN-L7) pour tous les Notifier au MEME schema : build()
  // synchrone puis lecture async (SharedPreferences / service) qui ecrit `state`
  // APRES l'await. Sans le garde, disposer le container pendant le gap async
  // leverait « Cannot use "ref" after the provider was disposed » (Riverpod 3).
  group('Notifiers au schema async-load — robustesse dispose pendant le load',
      () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    // Declenche le build+load async via [read] (qui lit le provider vise),
    // dispose AVANT la fin du gap async, puis laisse microtasks/timers
    // s'ecouler. Le test echoue si une exception « Ref used after dispose »
    // remonte de facon asynchrone. On passe l'action de lecture en callback
    // pour ne pas dependre du nom du type de base des providers Riverpod 3.
    Future<void> expectNoThrowOnDisposeDuringLoad(
      void Function(ProviderContainer) read,
    ) async {
      final container = ProviderContainer();
      read(container);
      container.dispose();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    test('SyncConfigNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad((c) => c.read(syncConfigProvider));
    });

    test('SyncStatusNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad((c) => c.read(syncStatusProvider));
    });

    test('VisibilitySettingsNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad(
        (c) => c.read(visibilitySettingsProvider),
      );
    });

    test('TrainingNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad((c) => c.read(trainingProvider));
    });

    test('DownloadReminderNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad(
        (c) => c.read(downloadReminderProvider('gr20')),
      );
    });

    test('FeasibilityNotifier ne throw pas', () async {
      await expectNoThrowOnDisposeDuringLoad(
        (c) => c.read(feasibilityProvider),
      );
    });
  });
}
