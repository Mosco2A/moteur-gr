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

  ConnectivityStatus _mapResult(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return ConnectivityStatusValues.offline;
    }
    return ConnectivityStatusValues.online;
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

final connectivityProvider =
    StreamProvider<ConnectivityStatus>((ref) async* {
  final monitor = ref.watch(connectivityMonitorProvider);
  final initial = await monitor.checkStatus();
  yield initial;
  yield* monitor.onStatusChange;
});
