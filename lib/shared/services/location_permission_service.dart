import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/error/error_handler.dart';

/// Resultat de l'escalade des permissions de localisation de fond.
enum BackgroundLocationStatus {
  /// « Autoriser tout le temps » accorde — capture GPS ecran eteint possible.
  granted,

  /// Seul « Pendant l'utilisation » (whileInUse) est accorde : le premier plan
  /// marche mais la capture s'arrete ecran eteint. Il faut router l'utilisateur
  /// vers les reglages systeme pour « tout le temps » (Android 11+).
  whileInUseOnly,

  /// Permission de fond refusee definitivement — passage par les reglages requis.
  permanentlyDenied,

  /// Permission refusee (dialog decline) — pas encore definitif.
  denied,

  /// Service de localisation (GPS) desactive au niveau systeme.
  serviceDisabled,
}

/// Service centralisant la logique de permissions de localisation, generalise
/// (re-portage socle, aucun sentier particulier).
///
/// Le socle ne demandait que « Pendant l'utilisation » (whileInUse) : ecran
/// eteint / telephone en poche, Android coupe alors le GPS et la trace tire tout
/// droit entre deux passages au premier plan. Ce service escalade vers
/// « Autoriser tout le temps » (ACCESS_BACKGROUND_LOCATION) et demande
/// l'exemption d'optimisation batterie (Doze), indispensables pour que le
/// foreground service capture en continu.
///
/// Volontairement UI-agnostic : il n'affiche aucun dialog. Il renvoie un statut
/// clair et expose [openLocationSettings] / [openBatterySettings] ; c'est la
/// couche presentation qui montre la rationale et re-verifie au retour d'app.
///
/// ZERO catch silencieux : les erreurs inattendues passent par [ErrorHandler]
/// (les cas best-effort attendus renvoient un statut degrade sans jeter).
class LocationPermissionService {
  LocationPermissionService();

  /// Vrai si « Autoriser tout le temps » (background) est deja accorde.
  Future<bool> hasBackgroundPermission() async {
    return Permission.locationAlways.isGranted;
  }

  /// Escalade la permission de localisation vers « Autoriser tout le temps ».
  ///
  /// Sequence : garantir whileInUse (pre-requis systeme) puis demander
  /// locationAlways. Selon la version Android :
  /// - Android <= 10 : `locationAlways.request()` propose directement le choix
  ///   « Toujours » -> peut renvoyer [BackgroundLocationStatus.granted].
  /// - Android 11+ : quand whileInUse est deja accorde, la demande ne montre
  ///   AUCUN dialog et renvoie denied/permanentlyDenied ; l'OS impose un passage
  ///   manuel par les reglages -> [whileInUseOnly] (l'appelant affiche une
  ///   rationale + [openLocationSettings]).
  ///
  /// Best-effort : ne casse jamais le premier plan.
  Future<BackgroundLocationStatus> requestBackgroundPermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return BackgroundLocationStatus.serviceDisabled;
      }

      final whenInUse = await Permission.locationWhenInUse.status;
      if (!whenInUse.isGranted) {
        final requested = await Permission.locationWhenInUse.request();
        if (!requested.isGranted) {
          return requested.isPermanentlyDenied
              ? BackgroundLocationStatus.permanentlyDenied
              : BackgroundLocationStatus.denied;
        }
      }

      if (await Permission.locationAlways.isGranted) {
        return BackgroundLocationStatus.granted;
      }

      final always = await Permission.locationAlways.request();
      if (always.isGranted) {
        return BackgroundLocationStatus.granted;
      }
      if (always.isPermanentlyDenied) {
        return BackgroundLocationStatus.permanentlyDenied;
      }
      return BackgroundLocationStatus.whileInUseOnly;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'LocationPermissionService.requestBackgroundPermission');
      return BackgroundLocationStatus.denied;
    }
  }

  /// Demande POST_NOTIFICATIONS au RUNTIME (Android 13+ / API 33+).
  ///
  /// Sans cette permission, la notification permanente du foreground service ne
  /// s'affiche PAS et Android bride/tue le service ecran eteint : la capture de
  /// fond meurt. Declaree au manifeste mais, depuis Android 13, elle doit etre
  /// demandee au runtime. Best-effort : renvoie true si accordee.
  Future<bool> requestNotificationPermission() async {
    try {
      if (await Permission.notification.isGranted) return true;
      final status = await Permission.notification.request();
      return status.isGranted;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'LocationPermissionService.requestNotificationPermission');
      return false;
    }
  }

  /// Demande l'exemption d'optimisation batterie (mode Doze).
  ///
  /// Sans exemption, Android peut suspendre le foreground service ecran eteint
  /// (Doze), tuant la capture. Cas Samsung / OEM agressifs : le dialog systeme
  /// (REQUEST_IGNORE_BATTERY_OPTIMIZATIONS) est le premier levier. Best-effort :
  /// no-op / false sur iOS.
  Future<bool> requestBatteryOptimizationExemption() async {
    try {
      if (await Permission.ignoreBatteryOptimizations.isGranted) {
        return true;
      }
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context:
              'LocationPermissionService.requestBatteryOptimizationExemption');
      return false;
    }
  }

  /// Vrai si l'exemption d'optimisation batterie (Doze) est deja accordee.
  ///
  /// Sert a decider d'afficher (ou non) la rationale batterie. Best-effort — sur
  /// les plateformes sans cette notion (iOS), renvoie true (rien a guider).
  Future<bool> hasBatteryExemption() async {
    try {
      return await Permission.ignoreBatteryOptimizations.isGranted;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'LocationPermissionService.hasBatteryExemption');
      return true;
    }
  }

  /// Ouvre la fiche « reglages de l'application » (permission_handler).
  ///
  /// Point de sortie pour obtenir « Autoriser tout le temps » sur Android 11+,
  /// ou la localisation a ete refusee definitivement.
  Future<bool> openLocationSettings() {
    return openAppSettings();
  }

  /// Emmene l'utilisateur vers les reglages de l'application pour desactiver
  /// manuellement l'optimisation batterie.
  ///
  /// Filet quand le dialog systeme d'exemption a ete refuse, ou quand un OEM
  /// agressif (Samsung) continue de brider la capture malgre l'exemption :
  /// openAppSettings est le point d'entree portable (permission_handler n'expose
  /// pas d'intent direct vers l'ecran batterie). On guide, on ne promet pas.
  Future<bool> openBatterySettings() {
    return openAppSettings();
  }

  /// Orchestrateur haut-niveau appele au demarrage du suivi.
  ///
  /// Enchaine : (1) POST_NOTIFICATIONS (prerequis du vrai foreground service),
  /// (2) escalade vers la localisation de fond, (3) exemption batterie si la
  /// capture de fond est envisageable. Best-effort et NON bloquant pour le
  /// premier plan : renvoie le statut de fond pour que l'UI decide d'afficher
  /// (ou non) la rationale.
  Future<BackgroundLocationStatus> ensureBackgroundTracking() async {
    await requestNotificationPermission();

    final status = await requestBackgroundPermission();

    if (status == BackgroundLocationStatus.granted ||
        status == BackgroundLocationStatus.whileInUseOnly) {
      await requestBatteryOptimizationExemption();
    }
    return status;
  }
}

/// Provider singleton du service de permissions de localisation.
final locationPermissionServiceProvider =
    Provider<LocationPermissionService>((ref) {
  return LocationPermissionService();
});