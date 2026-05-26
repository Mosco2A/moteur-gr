import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

/// État des permissions GPS.
///
/// Simplifie la gestion des différents cas (accordé, refusé,
/// service désactivé) pour l'UI.
enum GpsPermissionState {
  /// Permission accordée, GPS actif
  granted,

  /// Permission refusée par l'utilisateur
  denied,

  /// Permission refusée définitivement
  deniedForever,

  /// Service de localisation désactivé
  disabled,

  /// En attente de vérification
  checking,
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
    return GpsPermissionState.disabled;
  }

  // Vérifier les permissions
  var permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    // Demander la permission
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      return GpsPermissionState.denied;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    return GpsPermissionState.deniedForever;
  }

  return GpsPermissionState.granted;
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
      if (state != GpsPermissionState.granted) {
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
