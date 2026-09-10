import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/routing/home_location_provider.dart';
import 'package:moteur_gr/features/treks/providers/my_treks_provider.dart';

/// Tests du sélecteur d'ACCUEIL CONTEXTUEL (StepWays LOT 3, Ph3 — SPEC §2/§3).
///
/// [homeLocationProvider] dérive de [activeTrekIdProvider] : rando active → accueil
/// « terrain » (/home) ; aucune → accueil « maison » (/my-treks) ; défaut sûr
/// (maison) pendant le chargement.
void main() {
  group('homeLocationProvider (maison/terrain)', () {
    test('rando active -> accueil terrain (/home)', () async {
      final c = ProviderContainer(overrides: [
        activeTrekIdProvider.overrideWith((ref) async => 'volcans'),
      ]);
      addTearDown(c.dispose);
      // Laisse le FutureProvider résoudre avant de lire la dérivation synchrone.
      await c.read(activeTrekIdProvider.future);
      expect(c.read(homeLocationProvider), HomeLocations.terrain);
      expect(c.read(homeLocationProvider), '/home');
    });

    test('aucune rando active -> accueil maison (/my-treks)', () async {
      final c = ProviderContainer(overrides: [
        activeTrekIdProvider.overrideWith((ref) async => null),
      ]);
      addTearDown(c.dispose);
      await c.read(activeTrekIdProvider.future);
      expect(c.read(homeLocationProvider), HomeLocations.maison);
      expect(c.read(homeLocationProvider), '/my-treks');
    });

    test('pendant le chargement -> défaut sûr = maison', () {
      // FutureProvider non résolu (jamais complété) -> AsyncLoading -> valeur nulle
      // -> accueil maison (aucun cul-de-sac).
      final c = ProviderContainer(overrides: [
        activeTrekIdProvider.overrideWith((ref) => Completer<String?>().future),
      ]);
      addTearDown(c.dispose);
      expect(c.read(homeLocationProvider), HomeLocations.maison);
    });
  });
}
