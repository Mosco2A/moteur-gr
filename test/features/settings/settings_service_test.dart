import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/features/settings/data/settings_service.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';

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
}
