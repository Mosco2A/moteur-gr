/// L'AUTORISATION D'ACTIVITE PHYSIQUE (lot 671-02) : un statut nomme, une
/// seule demande a la fois, et un refus retenu pour ne jamais redemander tout
/// seul.
///
/// RANGE DANS `trek`, A COTE DES DEUX FONCTIONS QU'IL APPELLE
/// ([bgStepsPermission], [bgRequestStepsPermission]), et non dans le socle a
/// cote de `location_permission_service.dart` dont il reprend la FORME : le
/// socle ne peut pas importer une feature (garde des couches du lot 645), et
/// dupliquer ces deux fonctions aurait fait deux verites.
///
/// VOLONTAIREMENT SANS INTERFACE, comme son voisin : il n'affiche rien. C'est
/// la presentation qui montre l'explication et la phrase du refus.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/error/error_handler.dart';
import 'background_gps_service.dart';

/// L'etat de l'autorisation du podometre, en clair.
enum PodometerAccess {
  /// Accordee : les pas sont comptes.
  granted,

  /// Refusee, pas definitivement : une demande peut encore s'afficher.
  denied,

  /// Refusee definitivement : seuls les reglages du systeme peuvent la donner.
  permanentlyDenied,

  /// Ce telephone ne compte pas les pas (ou son statut est illisible).
  unavailable,
}

/// Traduit le statut du systeme en [PodometerAccess].
PodometerAccess podometerAccessOf(PermissionStatus status) => switch (status) {
  PermissionStatus.granted ||
  PermissionStatus.limited ||
  PermissionStatus.provisional => PodometerAccess.granted,
  PermissionStatus.permanentlyDenied => PodometerAccess.permanentlyDenied,
  PermissionStatus.restricted => PodometerAccess.unavailable,
  PermissionStatus.denied => PodometerAccess.denied,
};

/// Le service d'autorisation du podometre.
class PodometerPermissionService {
  /// Chaque acces au systeme est injectable ; par defaut, le reel.
  PodometerPermissionService({
    Future<PermissionStatus> Function()? readStatus,
    Future<bool> Function()? request,
    Future<bool> Function()? openSettings,
    Future<SharedPreferences> Function()? preferences,
  }) : _readStatus = readStatus ?? (() => bgStepsPermission().status),
       _request = request ?? bgRequestStepsPermission,
       _openSettings = openSettings ?? openAppSettings,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<PermissionStatus> Function() _readStatus;
  final Future<bool> Function() _request;
  final Future<bool> Function() _openSettings;
  final Future<SharedPreferences> Function() _preferences;

  /// LE REFUS RETENU, sur le modele de la cle de fond de
  /// `LocationPermissionService` : vrai des que le randonneur a dit « Plus
  /// tard » a l'explication ou non au systeme. Le demarrage d'un trek ne
  /// redemande alors plus jamais ; seul le reglage le peut.
  static const String kDeclinedKey = 'tracking.stepCountingDeclined';

  /// La demande EN COURS, partagee par tous les appelants. Android n'accepte
  /// qu'UNE demande a la fois : deux chemins concurrents ont deja laisse
  /// l'application sept minutes derriere l'ecran systeme des permissions
  /// (campagne personas du 21/09). Au demarrage d'un trek, le meme risque.
  Future<PodometerAccess>? _inFlight;

  /// L'explication EN COURS au demarrage d'un trek, partagee de meme : deux
  /// demarrages simultanes ne montrent qu'une explication.
  Future<void>? _explaining;

  /// L'etat de l'autorisation. Ne leve jamais : illisible vaut indisponible.
  Future<PodometerAccess> status() async {
    try {
      return podometerAccessOf(await _readStatus());
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'PodometerPermissionService.status',
      );
      return PodometerAccess.unavailable;
    }
  }

  /// Demande l'autorisation au systeme, une seule demande a la fois.
  Future<PodometerAccess> request() {
    final pending = _inFlight;
    if (pending != null) return pending;
    final started = _runRequest();
    _inFlight = started;
    return started.whenComplete(() {
      if (identical(_inFlight, started)) _inFlight = null;
    });
  }

  Future<PodometerAccess> _runRequest() async {
    try {
      if (await _request()) return PodometerAccess.granted;
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'PodometerPermissionService.request',
      );
    }
    final after = await status();
    return after == PodometerAccess.granted ? PodometerAccess.denied : after;
  }

  /// Vrai si le randonneur a deja refuse : plus de demande au demarrage.
  Future<bool> hasDeclined() async {
    try {
      return (await _preferences()).getBool(kDeclinedKey) ?? false;
    } on Object {
      return true;
    }
  }

  /// Retient le refus : on ne redemandera plus tout seul.
  Future<void> rememberDeclined() async {
    try {
      await (await _preferences()).setBool(kDeclinedKey, true);
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'PodometerPermissionService.rememberDeclined',
      );
    }
  }

  /// AU DEMARRAGE D'UN TREK : si l'autorisation n'est ni accordee, ni
  /// refusee definitivement, ni deja declinee, et que le telephone compte les
  /// pas, [explain] montre l'explication ; s'il rend vrai, le systeme pose sa
  /// question. Tout refus est retenu et raconte une fois par [onRefused].
  ///
  /// Ne leve jamais, ne bloque jamais le demarrage : le trek demarre quelle
  /// que soit la reponse.
  Future<void> explainAtTrekStart({
    required Future<bool?> Function() explain,
    required void Function() onRefused,
  }) {
    final pending = _explaining;
    if (pending != null) return pending;
    final started = _runExplain(explain, onRefused);
    _explaining = started;
    return started.whenComplete(() {
      if (identical(_explaining, started)) _explaining = null;
    });
  }

  Future<void> _runExplain(
    Future<bool?> Function() explain,
    void Function() onRefused,
  ) async {
    if (await status() != PodometerAccess.denied) return;
    if (await hasDeclined()) return;
    bool? accepted;
    try {
      accepted = await explain();
    } on Object catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'podometre.explication');
    }
    if (accepted == true && await request() == PodometerAccess.granted) return;
    await rememberDeclined();
    onRefused();
  }

  /// Ouvre la fiche de l'application dans les reglages du systeme : le seul
  /// chemin apres un refus definitif.
  Future<bool> openSystemSettings() async {
    try {
      return await _openSettings();
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'PodometerPermissionService.openSystemSettings',
      );
      return false;
    }
  }
}

/// Le service d'autorisation du podometre, un seul pour l'application.
final podometerPermissionServiceProvider = Provider<PodometerPermissionService>(
  (ref) => PodometerPermissionService(),
);
