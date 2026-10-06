/// Permission de localisation et REGIME de precision, pilote par le mouvement :
/// on ne demande pas la meme finesse a l'arret qu'en marche.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';
import 'background_gps_service.dart'
    show bgReadStoredPositionProfile, bgWritePositionProfile;
import 'position_controller.dart';

/// Resultat de la demande de permission GPS.
///
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef GpsPermissionResult = String;

/// Valeurs connues pour GpsPermissionResult.
abstract class GpsPermissionResultValues {
  static const String granted = 'granted';
  static const String denied = 'denied';
  static const String deniedForever = 'deniedForever';
  static const String serviceDisabled = 'serviceDisabled';
  static const String fallback = denied;
  static const List<String> values = [
    granted,
    denied,
    deniedForever,
    serviceDisabled,
  ];

  static GpsPermissionResult fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Regime de precision GPS, pilote par le mouvement (E5.2b + F6A-03).
///
/// [resting] : utilisateur a l'arret -> precision basse (economie batterie).
/// [walking] : marche lente prolongee -> precision moyenne/balanced (palier
///             intermediaire ajoute en F6A-03, correction CP1 #1 batterie).
/// [moving]  : utilisateur en mouvement franc -> precision haute (suivi fidele).
enum GpsAccuracyMode { resting, walking, moving }

/// Service GPS : permissions et flux de positions de l'interface.
///
/// Responsabilites :
/// - Demander les permissions foreground (puis background si besoin)
/// - Fournir LE flux de positions de l'interface, celui du
///   [PositionController] (lot 671-00) : un seul flux diffuse, quel que soit
///   le nombre d'appels a [getPositionStream].
/// - Garder les regles du regime de precision pilote par le mouvement
///   ([classifyMovement], [settingsForMode], 3 paliers F6A-03). DEPUIS LE LOT
///   671-00 ELLES NE PILOTENT PLUS LE FLUX : le robinet unique ne sert que le
///   profil carte. Elles restent la reference des profils a venir.
/// - ZERO catch silencieux — toute erreur est loggee via ErrorHandler
class GpsService {
  /// Wrapper Geolocator injecte pour testabilite.
  ///
  /// Par defaut utilise les methodes statiques de Geolocator.
  /// En test, on injecte un mock via le constructeur : [positions] pour
  /// partager un controleur, ou [getPositionStream] pour en batir un prive
  /// sur une source simulee.
  GpsService({
    Future<bool> Function()? isLocationServiceEnabled,
    Future<LocationPermission> Function()? checkPermission,
    Future<LocationPermission> Function()? requestPermission,
    PositionStreamFactory? getPositionStream,
    PositionController? positions,
  }) : _isLocationServiceEnabled =
           isLocationServiceEnabled ?? Geolocator.isLocationServiceEnabled,
       _checkPermission = checkPermission ?? Geolocator.checkPermission,
       _requestPermission = requestPermission ?? Geolocator.requestPermission,
       _positions =
           positions ?? PositionController(positionStream: getPositionStream);

  final Future<bool> Function() _isLocationServiceEnabled;
  final Future<LocationPermission> Function() _checkPermission;
  final Future<LocationPermission> Function() _requestPermission;
  final PositionController _positions;

  /// Filtre de distance conserve dans tous les regimes de precision.
  static const int distanceFilterMeters = 10;

  /// Seuil (m/s) au-dela duquel on passe en mouvement franc (~3.6 km/h).
  static const double movingSpeedThresholdMps = 1.0;

  /// Seuil (m/s) d'entree en marche lente (~1.4 km/h). En deca on est au repos.
  static const double walkingSpeedThresholdMps = 0.4;

  /// Seuil (m/s) en deca duquel on repasse au repos (~1.4 km/h).
  ///
  /// Egal a [walkingSpeedThresholdMps] : on quitte le repos a la meme vitesse
  /// qu'on y revient, l'hysteresis anti-flapping etant portee par la marge
  /// descendante depuis `moving` ([movingExitSpeedThresholdMps]).
  static const double restingSpeedThresholdMps = walkingSpeedThresholdMps;

  /// Seuil (m/s) sous lequel on redescend de `moving` vers `walking`
  /// (~2.5 km/h). L'ecart avec [movingSpeedThresholdMps] cree l'hysteresis qui
  /// evite le battement (flapping) autour de la charniere haute.
  static const double movingExitSpeedThresholdMps = 0.7;

  /// Intervalle d'updates GPS (Android) par regime — proxy de batching.
  /// Croissant : plus on est immobile, plus on espace (economie batterie).
  static const Duration movingInterval = Duration(seconds: 2);
  static const Duration walkingInterval = Duration(seconds: 5);
  static const Duration restingInterval = Duration(seconds: 15);

  /// Demande les permissions GPS : foreground d'abord, background ensuite si besoin.
  ///
  /// Retourne le resultat final de la demande.
  /// ZERO catch silencieux — chaque erreur est loggee via ErrorHandler.
  Future<GpsPermissionResult> requestPermission() async {
    try {
      // 1. Verifier que le service GPS est actif
      final serviceEnabled = await _isLocationServiceEnabled();
      if (!serviceEnabled) {
        ErrorHandler.log(
          StateError('Service GPS desactive'),
          context: 'GpsService.requestPermission',
        );
        return GpsPermissionResultValues.serviceDisabled;
      }

      // 2. Verifier les permissions actuelles
      var permission = await _checkPermission();

      // 3. Si denied, demander foreground
      if (permission == LocationPermission.denied) {
        permission = await _requestPermission();
        if (permission == LocationPermission.denied) {
          ErrorHandler.log(
            StateError('Permission GPS refusee par utilisateur'),
            context: 'GpsService.requestPermission',
          );
          return GpsPermissionResultValues.denied;
        }
      }

      // 4. Si denied forever, on ne peut plus demander
      if (permission == LocationPermission.deniedForever) {
        ErrorHandler.log(
          StateError('Permission GPS refusee definitivement'),
          context: 'GpsService.requestPermission',
        );
        return GpsPermissionResultValues.deniedForever;
      }

      // 5. Permission accordee (whileInUse ou always)
      return GpsPermissionResultValues.granted;
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'GpsService.requestPermission',
      );
      rethrow;
    }
  }

  /// Classe une vitesse en regime de precision, machine a 3 etats avec
  /// hysteresis (F6A-03).
  ///
  /// Fonction PURE (sans effet de bord) — testable directement. Transitions
  /// depuis [current] :
  /// - depuis [GpsAccuracyMode.resting] : -> moving si speed >=
  ///   [movingSpeedThresholdMps] ; -> walking si speed >=
  ///   [walkingSpeedThresholdMps] ; sinon reste resting.
  /// - depuis [GpsAccuracyMode.walking] : -> moving si speed >=
  ///   [movingSpeedThresholdMps] ; -> resting si speed <
  ///   [restingSpeedThresholdMps] ; sinon reste walking.
  /// - depuis [GpsAccuracyMode.moving] : -> resting si speed <=
  ///   [restingSpeedThresholdMps] ; -> walking si speed <=
  ///   [movingExitSpeedThresholdMps] ; sinon reste moving.
  ///
  /// L'asymetrie montee (1.0) / descente (0.7) depuis `moving` cree
  /// l'hysteresis anti-flapping. Une vitesse non finie est traitee comme nulle
  /// (repos).
  static GpsAccuracyMode classifyMovement(
    double speedMps,
    GpsAccuracyMode current,
  ) {
    final speed = speedMps.isFinite ? speedMps.abs() : 0.0;
    switch (current) {
      case GpsAccuracyMode.resting:
        if (speed >= movingSpeedThresholdMps) return GpsAccuracyMode.moving;
        if (speed >= walkingSpeedThresholdMps) return GpsAccuracyMode.walking;
        return GpsAccuracyMode.resting;
      case GpsAccuracyMode.walking:
        if (speed >= movingSpeedThresholdMps) return GpsAccuracyMode.moving;
        if (speed < restingSpeedThresholdMps) return GpsAccuracyMode.resting;
        return GpsAccuracyMode.walking;
      case GpsAccuracyMode.moving:
        if (speed <= restingSpeedThresholdMps) return GpsAccuracyMode.resting;
        if (speed <= movingExitSpeedThresholdMps) {
          return GpsAccuracyMode.walking;
        }
        return GpsAccuracyMode.moving;
    }
  }

  /// Precision Geolocator correspondant a un [GpsAccuracyMode] (3 paliers).
  static LocationAccuracy accuracyForMode(GpsAccuracyMode mode) {
    switch (mode) {
      case GpsAccuracyMode.moving:
        return LocationAccuracy.high;
      case GpsAccuracyMode.walking:
        return LocationAccuracy.medium;
      case GpsAccuracyMode.resting:
        return LocationAccuracy.low;
    }
  }

  /// Intervalle d'updates GPS pour un [GpsAccuracyMode] (espacement = proxy
  /// de batching, F6A-03).
  static Duration intervalForMode(GpsAccuracyMode mode) {
    switch (mode) {
      case GpsAccuracyMode.moving:
        return movingInterval;
      case GpsAccuracyMode.walking:
        return walkingInterval;
      case GpsAccuracyMode.resting:
        return restingInterval;
    }
  }

  /// [LocationSettings] pour un regime donne (precision adaptative + filtre
  /// 10 m). Sur Android, utilise [AndroidSettings] avec un `intervalDuration`
  /// croissant en marche lente / repos pour espacer (batcher) les updates ;
  /// sur les autres plateformes, conserve un [LocationSettings] simple (l'API
  /// d'intervalle est specifique Android).
  ///
  /// NOTE : `setMaxUpdateDelayMillis` (batching natif Android) n'est PAS
  /// surface par geolocator 11 — on allonge `intervalDuration` comme substitut
  /// fonctionnel (moins d'updates = moins de reveils GPS = economie batterie).
  static LocationSettings settingsForMode(GpsAccuracyMode mode) {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: accuracyForMode(mode),
        distanceFilter: distanceFilterMeters,
        intervalDuration: intervalForMode(mode),
      );
    }
    return LocationSettings(
      accuracy: accuracyForMode(mode),
      distanceFilter: distanceFilterMeters,
    );
  }

  /// LE flux de positions de l'interface (lot 671-00).
  ///
  /// Chaque appel rend le MEME flux diffuse, celui du [PositionController] :
  /// la detection d'etape, les arrivees et l'ecran d'urgence ne s'abonnent
  /// plus chacun a la source. Les erreurs de la source sont loggees par le
  /// controleur ET propagees aux abonnes.
  Stream<Position> getPositionStream() => _positions.positions;
}

/// Provider Riverpod pour GpsService.
///
/// Fournit une instance par defaut utilisant Geolocator.
/// Overridable dans les tests avec un mock.
final gpsServiceProvider = Provider<GpsService>((ref) {
  return GpsService(positions: ref.watch(positionControllerProvider));
});

/// LE robinet unique GPS de l'isolate d'interface (lot 671-00).
///
/// Carte, hors-trace, suivi, detection d'etape et arrivees en derivent : un
/// seul controleur pour toute l'application, donc une seule souscription. Il
/// publie son profil pour l'isolate de fond par [bgWritePositionProfile], et
/// le reprend a sa premiere ecoute par [bgReadStoredPositionProfile] (lot
/// 671-01) : une interface relancee garde le profil choisi.
final positionControllerProvider = Provider<PositionController>((ref) {
  return PositionController(
    writeProfile: bgWritePositionProfile,
    readProfile: bgReadStoredPositionProfile,
  );
});
