/// LA SEULE CORRESPONDANCE entre la cadence de l'application ([GpsCadence],
/// Dart pur) et les reglages du greffon geolocator (lot 671-01).
///
/// C'est l'unique endroit de `lib/` ou une precision du greffon est nommee :
/// le controleur de l'interface ET l'isolate de fond passent par ici. La garde
/// `un_seul_robinet_gps_671_test.dart` compte les `LocationAccuracy.high`.
library;

import 'dart:io';

import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';

/// La precision du greffon pour [precision].
LocationAccuracy locationAccuracyOf(GpsPrecision precision) =>
    switch (precision) {
      GpsPrecision.high => LocationAccuracy.high,
    };

/// Les reglages du flux de l'isolate d'interface pour [cadence].
///
/// Un `LocationSettings` simple, sans intervalle impose : exactement la
/// souscription du robinet unique du lot 671-00 pour le profil carte.
LocationSettings interfaceStreamSettings(GpsCadence cadence) =>
    LocationSettings(
      accuracy: locationAccuracyOf(cadence.precision),
      distanceFilter: cadence.distanceFilterMeters ?? 0,
    );

/// Les reglages d'un tir unique : precision du profil, delai maximum du
/// profil (ou [kSingleShotMaxDelay] pour le point de secours du flux).
LocationSettings singleShotSettings(GpsCadence cadence) => LocationSettings(
  accuracy: locationAccuracyOf(cadence.precision),
  timeLimit: cadence.maxDelay ?? kSingleShotMaxDelay,
);

/// Les reglages du flux de l'isolate de fond, filtre de [distanceFilter]
/// metres (celui de la poignee de main, 12 m par defaut).
///
/// PAS de foregroundNotificationConfig ici : flutter_background_service est
/// DEJA l'hote du foreground service `location`. En ajouter un via geolocator
/// demarrerait un SECOND FGS dans le meme process (double FGS fragile,
/// startForeground interdit depuis un contexte background sur Android 12+ ->
/// SecurityException avalee = capture morte). Geolocator se contente ici
/// d'ECOUTER ; l'hote maintient le process vivant.
LocationSettings backgroundStreamSettings(
  GpsCadence cadence, {
  required int distanceFilter,
}) {
  final accuracy = locationAccuracyOf(cadence.precision);
  if (Platform.isAndroid) {
    return AndroidSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      forceLocationManager: false,
    );
  }
  if (Platform.isIOS) {
    return AppleSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
      activityType: ActivityType.fitness,
      pauseLocationUpdatesAutomatically: false,
      showBackgroundLocationIndicator: true,
      allowBackgroundLocationUpdates: true,
    );
  }
  return LocationSettings(accuracy: accuracy, distanceFilter: distanceFilter);
}
