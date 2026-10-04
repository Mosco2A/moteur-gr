/// Le controleur de la carte, expose en provider.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b).
library;

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider du MapController, gere dans un Notifier pour le cycle de vie.
///
/// Expose le controleur de carte FlutterMap v8 de facon centralisee.
/// Le Notifier le cree au build et le dispose automatiquement.
class MapControllerNotifier extends Notifier<MapController> {
  @override
  MapController build() {
    final controller = MapController();
    ref.onDispose(controller.dispose);
    return controller;
  }
}

/// Provider Riverpod pour le MapController.
final mapControllerProvider =
    NotifierProvider<MapControllerNotifier, MapController>(
      MapControllerNotifier.new,
    );
