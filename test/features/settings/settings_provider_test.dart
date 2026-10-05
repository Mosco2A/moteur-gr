import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/domain/temperature_unit.dart';
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
      final updated = settings.copyWith(
        temperatureUnit: TemperatureUnitValues.fahrenheit,
      );
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
      // StepWays L7 (A) : endonymes ACCENTUES (chaque langue dans sa propre
      // langue, i18n.md). Francais/Espanol -> Français/Español.
      expect(AppLanguageValues.labelFor('fr'), 'Français');
      expect(AppLanguageValues.labelFor('en'), 'English');
      expect(AppLanguageValues.labelFor('de'), 'Deutsch');
      expect(AppLanguageValues.labelFor('it'), 'Italiano');
      expect(AppLanguageValues.labelFor('es'), 'Español');
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

    test('dispose du container pendant le _load async ne leve pas '
        '« Ref used after dispose »', () async {
      final container = ProviderContainer();

      // Declenche build() -> _load() (async : await SettingsService.create()).
      // StepWays L7 : build() seed la langue depuis la locale Slang courante
      // (fr par defaut en test) ; on verifie l'etat par defaut via ses champs
      // (AppSettings n'a pas d'egalite de valeur, l'instance differe de const).
      final initial = container.read(settingsProvider);
      expect(initial.language, AppLanguageValues.fr);
      expect(initial.distanceUnit, DistanceUnitValues.km);
      expect(initial.themeMode, AppThemeModeValues.dark);

      // Dispose AVANT que le microtask de load ne reprenne apres l'await :
      // sans le garde `ref.mounted`, l'ecriture `state = ...` post-await
      // leverait « Ref used after dispose » (Riverpod 3).
      container.dispose();

      // Laisse le _load reprendre : le garde doit court-circuiter proprement.
      await Future<void>.delayed(Duration.zero);
      // Pas d'exception => garde effectif (le test echouerait sur throw async).
    });

    test(
      'sans dispose, la valeur persistee est bien relue apres le load',
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
      },
    );
  });

  // LOT 645-F1 (mesure Artemis 03/10) : l'unite de temperature etait gardee en
  // memoire seulement -> le randonneur qui choisissait Fahrenheit le perdait a
  // chaque redemarrage. Un NOUVEAU conteneur, avec le cache SharedPreferences
  // remis a zero (le store reste), joue le relancement de l'application.
  group('SettingsNotifier — unite de temperature apres redemarrage', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('Fahrenheit choisi est relu par un nouveau conteneur', () async {
      final avant = ProviderContainer();
      avant.read(settingsProvider);
      // Laisse _load() finir : le service doit etre pret avant l'ecriture.
      await Future<void>.delayed(Duration.zero);

      avant
          .read(settingsProvider.notifier)
          .setTemperatureUnit(TemperatureUnitValues.fahrenheit);
      expect(
        avant.read(settingsProvider).temperatureUnit,
        TemperatureUnitValues.fahrenheit,
      );
      await Future<void>.delayed(Duration.zero);
      avant.dispose();

      // Redemarrage : plus aucun etat en memoire, seul le store persiste.
      SharedPreferences.resetStatic();
      final apres = ProviderContainer();
      addTearDown(apres.dispose);

      expect(
        apres.read(settingsProvider).temperatureUnit,
        TemperatureUnitValues.celsius,
      );
      await Future<void>.delayed(Duration.zero);
      expect(
        apres.read(settingsProvider).temperatureUnit,
        TemperatureUnitValues.fahrenheit,
      );
    });

    test('installation vierge : Celsius par defaut apres le load', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(settingsProvider).temperatureUnit,
        TemperatureUnitValues.celsius,
      );
    });
  });

  // P1 (#101255 point 1, defaut #101197 point 1) — `_LOAD` NE LEVE PLUS, ET UNE
  // CLE HERITEE N'EN REMET PAS CINQ AUTRES PAR DEFAUT.
  //
  // Le test du service prouve que chaque LECTURE se replie ; celui-ci prouve ce
  // qui compte pour le randonneur : apres le chargement, l'ETAT de l'application
  // porte ses choix. Avant le correctif, `getString` sur l'index d'enum du
  // 26/05 levait un `TypeError` au milieu de la construction d'`AppSettings` :
  // l'affectation `state = ...` n'avait jamais lieu et l'ecran des reglages
  // affichait francais / sombre / km / cache a 500 Mo, sans un mot.
  group('SettingsNotifier — une preference heritee ne perd pas les autres', () {
    test('_load relit les autres reglages malgre l unite de temperature '
        'ecrite a l ancienne forme (build du 26/05)', () async {
      SharedPreferences.setMockInitialValues({
        'settings_language': AppLanguageValues.en,
        'settings_distance_unit': DistanceUnitValues.miles,
        // Forme du build du 26/05 (commit db71ad1e) : un INDEX d'enum.
        'settings_temperature_unit': 1,
        'settings_theme_mode': AppThemeModeValues.light,
        'settings_cache_enabled': false,
        'settings_cache_size_mb': 250,
        'settings_dominant_hand': DominantHandValues.left,
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(settingsProvider);
      await Future<void>.delayed(Duration.zero);

      final apres = container.read(settingsProvider);
      // La cle heritee, et elle seule, retombe sur son defaut.
      expect(apres.temperatureUnit, TemperatureUnitValues.celsius);
      // Les six autres choix du randonneur sont intacts.
      expect(apres.language, AppLanguageValues.en);
      expect(apres.distanceUnit, DistanceUnitValues.miles);
      expect(apres.themeMode, AppThemeModeValues.light);
      expect(apres.cacheEnabled, isFalse);
      expect(apres.cacheSizeMb, 250);
      expect(apres.dominantHand, DominantHandValues.left);
    });
  });

  // Meme durcissement anti-dispose (garde `ref.mounted` apres l'await, comme
  // SkinNotifier / SW-SKIN-L7) pour tous les Notifier au MEME schema : build()
  // synchrone puis lecture async (SharedPreferences / service) qui ecrit `state`
  // APRES l'await. Sans le garde, disposer le container pendant le gap async
  // leverait « Cannot use "ref" after the provider was disposed » (Riverpod 3).
  group(
    'Notifiers au schema async-load — robustesse dispose pendant le load',
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
        await expectNoThrowOnDisposeDuringLoad(
          (c) => c.read(syncConfigProvider),
        );
      });

      test('SyncStatusNotifier ne throw pas', () async {
        await expectNoThrowOnDisposeDuringLoad(
          (c) => c.read(syncStatusProvider),
        );
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
    },
  );
}
