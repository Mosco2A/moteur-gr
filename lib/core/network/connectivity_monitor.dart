/// L'etat du reseau ramene a quelques valeurs extensibles : une valeur inconnue
/// se replie au lieu de faire tomber l'app.
library;

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

final _log = Logger(
  printer: PrettyPrinter(methodCount: 0),
  level: kReleaseMode ? Level.off : Level.debug,
);

/// Statut de connectivite simplifie.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef ConnectivityStatus = String;

/// Valeurs connues pour ConnectivityStatus avec fallback generique.
abstract class ConnectivityStatusValues {
  static const String online = 'online';
  static const String offline = 'offline';
  static const String fallback = offline;
  static const List<String> values = [online, offline];
  static ConnectivityStatus fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// PAR QUEL LIEN LE TELEPHONE EST CONNECTE (tache 622).
///
/// POURQUOI CE N EST PAS UN DETAIL D AFFICHAGE. Une descente de cartes hors ligne
/// pese des dizaines a des centaines de megaoctets (260 Mo mesures en z10-16 par la
/// tache 608). Sur un partage de connexion ou en itinerance, la lancer sans
/// demander serait une facture que le randonneur n a pas choisie. Le moniteur ne
/// savait dire que « en ligne / hors ligne » : la question « est-ce que ca coute ? »
/// n avait aucune reponse dans le moteur.
typedef TypeDeLien = String;

/// Valeurs connues de [TypeDeLien], avec repli.
abstract class TypesDeLien {
  /// Wifi : le seul lien sur lequel on descend une grosse carte sans demander.
  static const String wifi = 'wifi';

  /// Reseau mobile — facture au volume, ou plafonne.
  static const String mobile = 'mobile';

  /// Autre lien connecte (ethernet, VPN, lien non identifie).
  ///
  /// IL EST TRAITE COMME PAYANT, ET C EST DELIBERE. La consigne de Christophe est
  /// « demande confirmation hors wifi » : tout ce qui n est pas identifie comme du
  /// wifi passe donc par sa confirmation. Un VPN monte au-dessus d une 4G se
  /// presente ici, et le prendre pour du wifi ferait payer le randonneur.
  static const String autre = 'autre';

  /// Aucun lien : hors ligne.
  static const String aucun = 'aucun';

  static const String repli = autre;

  static const List<String> valeurs = [wifi, mobile, autre, aucun];

  static TypeDeLien depuis(String valeur) =>
      valeurs.contains(valeur) ? valeur : repli;

  /// Vrai si une grosse descente peut partir sans confirmation sur ce lien.
  static bool sansSupplement(TypeDeLien lien) => lien == wifi;
}

/// Moniteur de connectivite avec debounce online (5s).
class ConnectivityMonitor {
  ConnectivityMonitor({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;
  static const _onlineDebounce = Duration(seconds: 5);

  Future<ConnectivityStatus> checkStatus() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return _mapResult(result);
    } catch (e) {
      _log.d('[ConnectivityMonitor] Erreur checkStatus: $e');
      return ConnectivityStatusValues.offline;
    }
  }

  Stream<ConnectivityStatus> get onStatusChange {
    return _connectivity.onConnectivityChanged
        .map(_mapResult)
        .transform(_OnlineDebounceTransformer(_onlineDebounce));
  }

  /// PAR QUEL LIEN ON EST CONNECTE, MAINTENANT (tache 622).
  ///
  /// Rend [TypesDeLien.aucun] hors ligne, et [TypesDeLien.autre] quand la question
  /// ne peut pas etre posee (erreur de plateforme). LE REPLI EST LE PLUS PRUDENT :
  /// ne pas savoir si le lien coute, c est devoir demander.
  Future<TypeDeLien> typeDeLien() async {
    try {
      return _mapLien(await _connectivity.checkConnectivity());
    } catch (e) {
      _log.d('[ConnectivityMonitor] Erreur typeDeLien: $e');
      return TypesDeLien.autre;
    }
  }

  /// DEPUIS connectivity_plus 6, LE GREFFON REND UNE LISTE, PAS UNE VALEUR.
  /// Un telephone peut porter plusieurs liens actifs a la fois (wifi et mobile
  /// montes ensemble, VPN par-dessus un lien physique). Hors ligne se presente
  /// ici comme `[ConnectivityResult.none]`, et une liste vide est possible :
  /// les deux se replient sur hors ligne, comme la valeur unique `none` avant.
  ConnectivityStatus _mapResult(List<ConnectivityResult> results) {
    final enLigne = results.any((r) => r != ConnectivityResult.none);
    return enLigne
        ? ConnectivityStatusValues.online
        : ConnectivityStatusValues.offline;
  }

  TypeDeLien _mapLien(List<ConnectivityResult> results) {
    final liens = results
        .where((r) => r != ConnectivityResult.none)
        .toList(growable: false);
    if (liens.isEmpty) return TypesDeLien.aucun;
    // PLUSIEURS LIENS A LA FOIS : ON NE SAIT PAS LEQUEL PORTE LE TRAFIC, DONC
    // ON DEMANDE. Ce cas n existait pas avant connectivity_plus 6, qui ne
    // savait nommer qu un seul lien. Le replier sur [TypesDeLien.autre] est le
    // seul choix qui ne peut pas facturer le randonneur : si le trafic part en
    // reel sur la 4G montee a cote du wifi, une descente de 260 Mo lancee sans
    // demander serait une facture qu il n a pas choisie.
    if (liens.length > 1) return TypesDeLien.autre;
    switch (liens.single) {
      case ConnectivityResult.wifi:
        return TypesDeLien.wifi;
      case ConnectivityResult.mobile:
        return TypesDeLien.mobile;
      default:
        // Ethernet, VPN, bluetooth, satellite (ajoute en 7.1.0), lien inconnu
        // d une version future du plugin : tout ce qui n est pas identifie
        // comme du wifi demande confirmation.
        return TypesDeLien.autre;
    }
  }
}

class _OnlineDebounceTransformer
    extends StreamTransformerBase<ConnectivityStatus, ConnectivityStatus> {
  _OnlineDebounceTransformer(this._duration);
  final Duration _duration;

  @override
  Stream<ConnectivityStatus> bind(Stream<ConnectivityStatus> stream) {
    ConnectivityStatus? lastEmitted;
    Timer? debounceTimer;
    final controller = StreamController<ConnectivityStatus>();

    final subscription = stream.listen(
      (status) {
        if (status == ConnectivityStatusValues.offline) {
          debounceTimer?.cancel();
          debounceTimer = null;
          if (lastEmitted != ConnectivityStatusValues.offline) {
            lastEmitted = ConnectivityStatusValues.offline;
            controller.add(status);
          }
        } else {
          debounceTimer?.cancel();
          debounceTimer = Timer(_duration, () {
            if (lastEmitted != ConnectivityStatusValues.online) {
              lastEmitted = ConnectivityStatusValues.online;
              controller.add(status);
            }
          });
        }
      },
      onError: controller.addError,
      onDone: () {
        debounceTimer?.cancel();
        controller.close();
      },
    );

    controller.onCancel = () {
      debounceTimer?.cancel();
      subscription.cancel();
    };

    return controller.stream;
  }
}

final connectivityMonitorProvider = Provider<ConnectivityMonitor>((ref) {
  return ConnectivityMonitor();
});

final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  final monitor = ref.watch(connectivityMonitorProvider);
  final initial = await monitor.checkStatus();
  yield initial;
  yield* monitor.onStatusChange;
});
