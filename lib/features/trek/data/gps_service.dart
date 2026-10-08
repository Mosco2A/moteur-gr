/// Permission de localisation et flux de positions de l'interface : celui du
/// robinet unique GPS.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/services/session_demo.dart';
import 'background_gps_service.dart'
    show bgReadStoredPositionProfile, bgWritePositionProfile;
import 'marcheur_simule.dart';
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
///
/// EN DEMO, LA SOURCE EST LE MARCHEUR SIMULE — ET C'EST TOUT CE QUI CHANGE
/// (tache 742). C'EST LA PORTE D'ENTREE DE LA SIMULATION, et elle a ete choisie
/// ici plutot qu'ailleurs pour une raison qui tient en une phrase : TOUT ce qui
/// sait ou se trouve le randonneur descend de ce robinet. La projection sur le
/// trace, le « Parcouru » de la barre, l'altitude courante, la detection
/// d'etape, la detection d'arrivee, le marqueur de la carte, le hors-trace :
/// aucun de ces calculs n'est recrit pour la demo, ils recoivent simplement des
/// positions qui viennent d'ailleurs. Brancher la simulation plus bas (sur
/// chaque ecran) ou plus haut (sur Geolocator) aurait demande soit de dupliquer
/// la chaine, soit une permission de localisation.
///
/// DEUX CHOSES NE SONT PAS FOURNIES EN DEMO, ET LEUR ABSENCE EST LA GARANTIE :
///   * aucune fonction Geolocator — ni flux, ni tir unique : regardez les
///     arguments, la source est le flux du marcheur et rien d'autre. La garde
///     `un_seul_robinet_gps_671_test.dart` compte les appels a
///     `Geolocator.getPositionStream(` dans `lib/` et son plafond NE MONTE PAS
///     avec ce lot : la simulation n'en ajoute aucun. Donc aucune demande
///     d'autorisation de position ne peut partir pendant une demo.
///   * ni [bgWritePositionProfile] ni [bgReadStoredPositionProfile] : le profil
///     GPS n'est NI lu NI ecrit pendant une demo. Armer ce canal ecrirait une
///     preference pour l'isolate de fond — c'est-a-dire une trace durable, ce
///     que la demo s'interdit (tache 634, « rien en base »).
final positionControllerProvider = Provider<PositionController>((ref) {
  if (ref.watch(enDemoProvider)) {
    final marcheur = ref.watch(marcheurSimuleProvider);
    return PositionController(
      positionStream: ({required LocationSettings locationSettings}) =>
          marcheur.positions,
      // UN TIR UNIQUE EN DEMO, C'EST LA DERNIERE POSITION SIMULEE. Tant que la
      // simulation n'a pas demarre il n'y en a aucune : on refuse, exactement
      // comme un recepteur sans fix, plutot que d'aller la chercher au GPS.
      currentPosition: ({required LocationSettings locationSettings}) async {
        final position = marcheur.dernierePosition;
        if (position == null) {
          throw StateError('Aucune position simulee en demo');
        }
        return position;
      },
    );
  }
  return PositionController(
    writeProfile: bgWritePositionProfile,
    readProfile: bgReadStoredPositionProfile,
  );
});
