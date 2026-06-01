import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  });
}
