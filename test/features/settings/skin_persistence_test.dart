import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/features/settings/data/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests SW-SKIN-L7 — persistance de la peau via [SettingsService].
///
/// Reutilise le MEME store que les autres preferences (SharedPreferences) :
/// aucune techno nouvelle. Prouve que le choix survit (un nouveau service
/// relit le dernier choix).
void main() {
  group('SettingsService — peau (SW-SKIN-L7)', () {
    test('aucune peau persistee au depart -> getSkin() null', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      expect(service.getSkin(), isNull);
    });

    test('setSkin persiste et un nouveau service relit le meme choix', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      // Act : choisir Topographique (nom d'enum persiste).
      await service.setSkin(AppSkin.topographique.name);

      // Assert : relu par le meme service...
      expect(service.getSkin(), AppSkin.topographique.name);

      // ...et par un service reconstruit (simulation redemarrage).
      final service2 = SettingsService(await SharedPreferences.getInstance());
      expect(service2.getSkin(), AppSkin.topographique.name);
    });

    test('un choix ecrase le precedent', () async {
      SharedPreferences.setMockInitialValues({});
      final service = SettingsService(await SharedPreferences.getInstance());

      await service.setSkin(AppSkin.grandAir.name);
      expect(service.getSkin(), AppSkin.grandAir.name);

      await service.setSkin(AppSkin.sentierVivant.name);
      expect(service.getSkin(), AppSkin.sentierVivant.name);
    });
  });
}
