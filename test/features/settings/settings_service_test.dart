import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/domain/temperature_unit.dart';
import 'package:moteur_gr/features/settings/data/settings_service.dart';

/// Tests du SettingsService — persistance SharedPreferences.
void main() {
  group('SettingsService', () {
    test('changement langue persiste et relit correctement', () async {
      // Arrange: SharedPreferences vide au depart
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      // Assert: valeur par defaut
      expect(service.getLanguage(), 'fr');

      // Act: changer la langue en anglais
      await service.setLanguage('en');

      // Assert: la valeur est persistee
      expect(service.getLanguage(), 'en');

      // Verify: un nouveau service relit la meme valeur
      final service2 = SettingsService(await SharedPreferences.getInstance());
      expect(service2.getLanguage(), 'en');
    });

    test('changement unite distance persiste et relit correctement', () async {
      // Arrange: SharedPreferences vide au depart
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      // Assert: valeur par defaut
      expect(service.getDistanceUnit(), 'km');

      // Act: changer en miles
      await service.setDistanceUnit('miles');

      // Assert: la valeur est persistee
      expect(service.getDistanceUnit(), 'miles');

      // Verify: un nouveau service relit la meme valeur
      final service2 = SettingsService(await SharedPreferences.getInstance());
      expect(service2.getDistanceUnit(), 'miles');
    });

    // LOT 645-F1 : l'unite de temperature est persistee comme la distance.
    test('unite temperature persiste et relit fahrenheit', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      await service.setTemperatureUnit('fahrenheit');

      expect(service.getTemperatureUnit(), 'fahrenheit');
      final service2 = SettingsService(await SharedPreferences.getInstance());
      expect(service2.getTemperatureUnit(), 'fahrenheit');
      expect(
        (await SharedPreferences.getInstance()).getString(
          SettingsKeys.temperatureUnit,
        ),
        'fahrenheit',
      );
    });

    test('unite temperature absente -> celsius', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      expect(service.getTemperatureUnit(), 'celsius');
    });

    // Meme partage des roles que la distance : le service rend la chaine
    // brute, TemperatureUnitValues.fromString (lecture de _load) la normalise.
    test('unite temperature inconnue -> celsius a la lecture', () async {
      SharedPreferences.setMockInitialValues({
        SettingsKeys.temperatureUnit: 'kelvin',
      });
      final service = SettingsService(await SharedPreferences.getInstance());

      expect(
        TemperatureUnitValues.fromString(service.getTemperatureUnit()),
        TemperatureUnitValues.celsius,
      );
    });
  });

  // =========================================================================
  // P1 (#101255, defaut #101197 point 1) — LECTURE TOLERANTE DES REGLAGES
  // =========================================================================
  //
  // CE QUI SE PASSAIT. Le build du 26/05/2026 (commit db71ad1e, « E3.9
  // parametres complets ») ecrivait CHAQUE reglage sous la forme d'un INDEX
  // D'ENUM : `_prefs.setInt('settings_temperature_unit', unit.index)`. Le
  // service actuel relit ces memes cles en CHAINES. Or `getString` sur une
  // valeur entiere ne rend pas `null` : il LEVE un `TypeError`. La lecture
  // s'arretait donc au premier reglage herite, `_load` n'affectait jamais
  // `state`, et langue, theme, unites et cache repartaient TOUS a leur defaut
  // EN SILENCE — un reglage abime en emportait cinq autres intacts.
  //
  // CE QUE LA REGLE DIT MAINTENANT (arbitrage #101255 point 1). Une valeur
  // inconnue ou d'un ancien format se replie sur le defaut DE SA SEULE CLE ;
  // les autres cles restent ce que le randonneur a choisi. Aucune lecture de
  // reglage ne leve.
  //
  // POURQUOI UN REPLI ET PAS UNE MIGRATION D'INDEX. Traduire l'index 1 en
  // 'fahrenheit' supposerait que l'ordre des enums du 26/05 n'a pas bouge
  // depuis — il a bouge (les enums sont devenus des chaines au lot 645-F1), et
  // une supposition fausse rendrait un reglage que le randonneur n'a pas
  // choisi. Le defaut de la cle, lui, ne ment pas.
  group('SettingsService — lecture tolerante (P1 #101255)', () {
    test('ancienne forme (index d enum) de l unite de temperature -> celsius, '
        'sans lever', () async {
      SharedPreferences.setMockInitialValues({
        // Forme du build du 26/05 : TemperatureUnit.fahrenheit.index == 1.
        SettingsKeys.temperatureUnit: 1,
      });
      final service = SettingsService(await SharedPreferences.getInstance());

      expect(service.getTemperatureUnit(), 'celsius');
    });

    test(
      'une cle a l ancienne forme n emporte pas les autres reglages',
      () async {
        SharedPreferences.setMockInitialValues({
          SettingsKeys.language: 'en',
          SettingsKeys.distanceUnit: 'miles',
          // La seule cle heritee du build du 26/05.
          SettingsKeys.temperatureUnit: 1,
          SettingsKeys.themeMode: 'light',
          SettingsKeys.cacheEnabled: false,
          SettingsKeys.cacheSizeMb: 250,
          SettingsKeys.skin: 'grandAir',
          SettingsKeys.dominantHand: 'left',
        });
        final service = SettingsService(await SharedPreferences.getInstance());

        // La cle en cause se replie sur SON defaut...
        expect(service.getTemperatureUnit(), 'celsius');
        // ...et les sept autres restent ce que le randonneur avait choisi.
        expect(service.getLanguage(), 'en');
        expect(service.getDistanceUnit(), 'miles');
        expect(service.getThemeMode(), 'light');
        expect(service.getCacheEnabled(), isFalse);
        expect(service.getCacheSizeMb(), 250);
        expect(service.getSkin(), 'grandAir');
        expect(service.getDominantHand(), 'left');
      },
    );

    test(
      'TOUTES les cles a l ancienne forme -> chacune son propre defaut',
      () async {
        SharedPreferences.setMockInitialValues({
          // Les quatre index d enum du 26/05...
          SettingsKeys.language: 1,
          SettingsKeys.distanceUnit: 1,
          SettingsKeys.temperatureUnit: 1,
          SettingsKeys.themeMode: 2,
          // ...et, pour les trois types restants, le mauvais type a l'envers :
          // un booleen ecrit en entier, un entier ecrit en chaine, une chaine
          // ecrite en booleen. Aucune des trois ne doit lever non plus.
          SettingsKeys.cacheEnabled: 1,
          SettingsKeys.cacheSizeMb: '250',
          SettingsKeys.skin: true,
          SettingsKeys.dominantHand: 1,
        });
        final service = SettingsService(await SharedPreferences.getInstance());

        expect(service.getLanguage(), 'fr');
        expect(service.getDistanceUnit(), 'km');
        expect(service.getTemperatureUnit(), 'celsius');
        expect(service.getThemeMode(), 'dark');
        expect(service.getCacheEnabled(), isTrue);
        expect(service.getCacheSizeMb(), 500);
        expect(service.getSkin(), isNull);
        expect(service.getDominantHand(), 'right');
      },
    );
  });
}
