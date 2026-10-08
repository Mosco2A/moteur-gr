/// L'etat de la permission de localisation ramene a quelques cas lisibles par
/// l'ecran : accorde, refuse, service coupe.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/session_demo.dart';
import '../../trek/trek_facade.dart' show positionControllerProvider;

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
  static const List<String> values = [
    granted,
    denied,
    deniedForever,
    disabled,
    checking,
  ];
  static GpsPermissionState fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Provider de l'état des permissions GPS.
///
/// Vérifie le service de localisation et les permissions,
/// demande l'autorisation si nécessaire.
///
/// IL MESURE LE SYSTEME, ET IL OUVRE UNE FENETRE SYSTEME (ligne du
/// `requestPermission` ci-dessous). Donc : AUCUN CHEMIN DE DEMO NE DOIT LE
/// LIRE (tache 744). Le lire en demo, c'est faire surgir la demande
/// d'autorisation par-dessus la demonstration — et comme cette fenetre met
/// l'application en arriere-plan, elle TUE la marche simulee qu'elle
/// interrompt. On ne lui fait pas dire « accordee » en demo : un fournisseur
/// qui MESURE ne doit pas mentir. C'est le VERROU en aval, dans
/// [locationProvider], qui est court-circuite — pas la mesure.
final gpsPermissionProvider = FutureProvider<GpsPermissionState>((ref) async {
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
/// Derive du robinet unique GPS ([positionControllerProvider], lot 671-00),
/// profil carte : précision haute, filtre de distance 10m.
/// keepAlive pour ne pas re-demander la permission à chaque rebuild.
/// Ne s'active que si les permissions sont accordées — SAUF EN DEMO, ou les
/// positions sont simulees et ou aucune permission n'est ni demandee ni
/// consultee (tache 744, cf. la branche de demo ci-dessous).
final locationProvider = StreamProvider<Position>((ref) {
  final positions = ref.watch(positionControllerProvider).positions;

  final controller = StreamController<Position>();

  /// Branche la sortie du robinet sur ce flux, et la coupe au dispose.
  void brancherLeRobinet() {
    final subscription = positions.listen(
      controller.add,
      onError: controller.addError,
    );

    ref.onDispose(() {
      subscription.cancel();
      controller.close();
    });
  }

  // EN DEMO, LE VERROU EST COURT-CIRCUITE — ET LUI SEUL (tache 744).
  //
  // CE QUI NE MARCHAIT PAS, MESURE A L'EXECUTION (recette du lot 742, tache
  // 743) : la demo ne marchait QUE si la permission de position etait DEJA
  // accordee. Le lot 742 avait branche la source simulee dans le robinet
  // unique ([positionControllerProvider] rend les positions du marcheur en
  // demo, sans jamais toucher Geolocator) — mais ce provider-ci, le
  // CONSOMMATEUR en aval, exigeait encore une permission dont une simulation
  // n'a aucun besoin. Deux consequences, les deux vues en demonstration : une
  // fenetre systeme surgissait en pleine demo et, en mettant l'application en
  // arriere-plan, tuait la marche ; et si l'utilisateur refusait, la barre
  // restait a « -- » pour toujours puisque ce flux ne rendait plus qu'une
  // erreur.
  //
  // CE QUE LA DEMO N'A PAS BESOIN DE DEMANDER, ELLE NE LE DEMANDE PLUS. En
  // demo les positions viennent du marcheur simule : il n'y a pas de recepteur
  // a allumer, donc rien a autoriser. On s'abonne au robinet SANS LIRE
  // [gpsPermissionProvider] — ne pas le lire, c'est ne pas le construire, donc
  // ne JAMAIS appeler Geolocator : c'est la seule facon de garantir qu'aucune
  // fenetre systeme ne peut s'ouvrir.
  //
  // ON NE MENT PAS SUR LA PERMISSION REELLE. Le court-circuit est ICI, sur le
  // verrou, et pas dans la mesure : [gpsPermissionProvider] continue de dire
  // la verite du systeme a qui l'interroge hors demo. LE CHEMIN DE LA VRAIE
  // RANDONNEE EST INTACT, verrou compris — c'est la branche d'apres.
  if (ref.watch(enDemoProvider)) {
    brancherLeRobinet();
    ref.keepAlive();
    return controller.stream;
  }

  // Vérifier d'abord les permissions
  final permissionAsync = ref.watch(gpsPermissionProvider);

  permissionAsync.when(
    data: (state) {
      if (state != GpsPermissionStateValues.granted) {
        controller.addError(StateError('Permission GPS non accordée: $state'));
        return;
      }

      brancherLeRobinet();
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
