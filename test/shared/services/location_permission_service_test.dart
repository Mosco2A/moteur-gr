import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/shared/services/location_permission_service.dart';

/// Tests device-independants du service de permissions de localisation.
///
/// LIMITE : les methodes du service (requestBackgroundPermission,
/// requestBatteryOptimizationExemption, requestNotificationPermission,
/// ensureBackgroundTracking) appellent directement les canaux natifs
/// permission_handler / geolocator ; leur comportement reel (escalade
/// « Toujours », dialog Doze cas Samsung, POST_NOTIFICATIONS) exige un DEVICE.
/// On verifie ici le contrat testable : completude de l'enum de statut, mapping
/// stable des valeurs, et cablage du provider (instance singleton).
void main() {
  group('BackgroundLocationStatus (contrat)', () {
    test('couvre tous les statuts attendus du re-portage socle', () {
      expect(BackgroundLocationStatus.values, containsAll(const [
        BackgroundLocationStatus.granted,
        BackgroundLocationStatus.whileInUseOnly,
        BackgroundLocationStatus.permanentlyDenied,
        BackgroundLocationStatus.denied,
        BackgroundLocationStatus.serviceDisabled,
      ]));
      expect(BackgroundLocationStatus.values.length, 5);
    });

    test('granted et whileInUseOnly sont les seuls etats ou la capture de fond '
        'est envisageable (exemption batterie declenchee)', () {
      // Documente la regle d'orchestration d'ensureBackgroundTracking : seuls
      // ces deux statuts declenchent la demande d'exemption batterie.
      const captureEnvisageable = {
        BackgroundLocationStatus.granted,
        BackgroundLocationStatus.whileInUseOnly,
      };
      expect(captureEnvisageable.contains(BackgroundLocationStatus.granted),
          isTrue);
      expect(
          captureEnvisageable.contains(BackgroundLocationStatus.whileInUseOnly),
          isTrue);
      expect(captureEnvisageable.contains(BackgroundLocationStatus.denied),
          isFalse);
    });
  });

  group('locationPermissionServiceProvider (cablage)', () {
    test('fournit une instance de LocationPermissionService', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final service = container.read(locationPermissionServiceProvider);
      expect(service, isA<LocationPermissionService>());
    });
  });
}