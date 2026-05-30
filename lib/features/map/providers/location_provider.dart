import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// Etat des permissions GPS.
///
/// Simplifie la gestion des differents cas (accorde, refuse,
/// service desactive) pour l'UI.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef GpsPermissionState = String;

/// Valeurs connues pour GpsPermissionState avec fallback generique.
abstract class GpsPermissionStateValues {
  static const String granted = 'granted';
  static const String denied = 'denied';
  static const String deniedForever = 'deniedForever';
  static const String disabled = 'disabled';
  static const String checking = 'checking';
  static const String fallback = checking;
  static const List<String> values = [granted, denied, deniedForever, disabled, checking];
  static GpsPermissionState fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Provider de l'état des permissions GPS.
///
/// Vérifie le service de localisation et les permissions,
/// demande l'autorisation si nécessaire.
final gpsPermissionProvider =
    FutureProvider<GpsPermissionState>((ref) async {
  // Vérifier si le service GPS est activé
  final serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    return GpsPermissionStateValues.disabled;
  }

  // Vérifier les permissions
  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Demander la permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return GpsPermissionStateValues.denied;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return GpsPermissionStateValues.deniedForever;
  }

  return GpsPermissionStateValues.granted;
});

/// Provider qui streame la position GPS de l'utilisateur.
///
/// Configuration : précision haute, filtre de distance 10m.
/// keepAlive pour ne pas re-demander la permission à chaque rebuild.
/// Ne s'active que si les permissions sont accordées.
final locationProvider = StreamProvider<Position>((ref) {
  // Vérifier d'abord les permissions
  final permissionAsync = ref.watch(gpsPermissionProvider);

  final controller = StreamController<Position>();

  permissionAsync.when(
    data: (state) {
      if (state != GpsPermissionStateValues.granted) {
        controller.addError(
          StateError('Permission GPS non accordée: $state'),
        );
        return;
      }

      // Paramètres du stream GPS
      const settings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );

      final subscription = Geolocator.getPositionStream(
        locationSettings: settings,
      ).listen(
        controller.add,
        onError: controller.addError,
      );

      ref.onDispose(() {
        subscription.cancel();
        controller.close();
      });
    },
    loading: () {
      // En attente de vérification des permissions
    },
    error: (error, stack) {
      controller.addError(error, stack);
    },
  );

  // keepAlive pour ne pas re-demander la permission
  ref.keepAlive();

  return controller.stream;
});
