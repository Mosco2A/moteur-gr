import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/skin_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests SW-SKIN-L7 — provider de peau : selection, resolution effectiveSkin,
/// fallback d'eligibilite Grand Air -> Sentier Vivant, robustesse du parse.
void main() {
  setUp(() {
    // Store vide par defaut (aucune peau persistee -> defaut Sentier Vivant).
    SharedPreferences.setMockInitialValues({});
  });

  group('skinProvider — selection', () {
    test('defaut = Sentier Vivant (aucun choix persiste)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(skinProvider), AppSkin.sentierVivant);
    });

    test('select(topographique) met a jour la peau choisie', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(skinProvider.notifier).select(AppSkin.topographique);
      expect(container.read(skinProvider), AppSkin.topographique);
    });
  });

  group('effectiveSkinProvider — resolution + fallback', () {
    test('reflete le choix quand la peau n\'est pas Grand Air', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(skinProvider.notifier).select(AppSkin.topographique);
      expect(container.read(effectiveSkinProvider), AppSkin.topographique);
    });

    test(
        'Grand Air choisi + sentier NON eligible -> fallback Sentier Vivant',
        () {
      // Par defaut trailHasCoverPhotosProvider = false (defaut sur L7).
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(skinProvider.notifier).select(AppSkin.grandAir);

      // La peau CHOISIE reste Grand Air (non perdue)...
      expect(container.read(skinProvider), AppSkin.grandAir);
      // ...mais la peau EFFECTIVE retombe sur Sentier Vivant (fallback).
      expect(container.read(effectiveSkinProvider), AppSkin.sentierVivant);
    });

    test('Grand Air choisi + sentier eligible -> Grand Air effective', () {
      // Simule un sentier eligible en surchargeant l'eligibilite (ce que L9
      // fera via le vrai drapeau hasCoverPhotos du TrailConfig).
      final container = ProviderContainer(
        overrides: [
          trailHasCoverPhotosProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      container.read(skinProvider.notifier).select(AppSkin.grandAir);
      expect(container.read(effectiveSkinProvider), AppSkin.grandAir);
    });

    test(
        'la preference Grand Air se re-applique des que le sentier devient eligible',
        () {
      // 1) Sentier non eligible : effective = Sentier Vivant.
      final ineligible = ProviderContainer();
      addTearDown(ineligible.dispose);
      ineligible.read(skinProvider.notifier).select(AppSkin.grandAir);
      expect(ineligible.read(effectiveSkinProvider), AppSkin.sentierVivant);

      // 2) Meme choix, sentier eligible : effective = Grand Air (choix intact).
      final eligible = ProviderContainer(
        overrides: [trailHasCoverPhotosProvider.overrideWithValue(true)],
      );
      addTearDown(eligible.dispose);
      eligible.read(skinProvider.notifier).select(AppSkin.grandAir);
      expect(eligible.read(effectiveSkinProvider), AppSkin.grandAir);
    });
  });

  group('trailHasCoverPhotos — defaut sur L7 (isolation L9)', () {
    test('retourne false pour toute config (aucun sentier eligible en L7)', () {
      // Point d'isolation : L9 branchera le vrai drapeau ici. En L7, toujours
      // false quel que soit le sentier.
      final container = ProviderContainer();
      addTearDown(container.dispose);
      expect(container.read(trailHasCoverPhotosProvider), isFalse);
    });
  });

  group('skinProvider — persistance (relecture au demarrage)', () {
    test('une peau persistee est relue au build du provider', () async {
      // Store pre-rempli comme apres un choix + redemarrage.
      SharedPreferences.setMockInitialValues({
        'settings_skin': AppSkin.topographique.name,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // _load() est asynchrone : on lit une premiere fois (defaut) puis on
      // laisse le microtask de chargement s'executer.
      expect(container.read(skinProvider), AppSkin.sentierVivant);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(skinProvider), AppSkin.topographique);
    });

    test('une valeur persistee inconnue retombe sur Sentier Vivant', () async {
      SharedPreferences.setMockInitialValues({
        'settings_skin': 'peauInexistante',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);
      expect(container.read(skinProvider), AppSkin.sentierVivant);
    });
  });
}
