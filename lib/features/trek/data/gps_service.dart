/// Permission de localisation et flux de positions de l'interface : celui du
/// robinet unique GPS.
library;

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
///
/// LOT 671-01 : les regles qui en tiraient des reglages GPS sont retirees (plus
/// aucun appelant depuis le robinet unique du lot 671-00). Il ne reste que le
/// type, lu par `battery_aware_location_controller.dart`, que rien ne branche.
enum GpsAccuracyMode { resting, walking, moving }

/// Service GPS : permissions et flux de positions de l'interface.
///
/// Responsabilites :
/// - Demander les permissions foreground (puis background si besoin)
/// - Fournir LE flux de positions de l'interface, celui du
///   [PositionController] (lot 671-00) : un seul flux diffuse, quel que soit
///   le nombre d'appels a [getPositionStream].
/// - Les cadences des profils ne vivent plus ici mais dans `GpsCadence`
///   (lot 671-01) : le regime adaptatif, sans appelant depuis le lot 671-00,
///   a ete retire.
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
