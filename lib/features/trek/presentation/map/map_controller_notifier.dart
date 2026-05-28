import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifier gerant le [MapController] de FlutterMap v8.
///
/// Encapsule la creation et le dispose du controller dans un
/// [AutoDisposeNotifier] Riverpod. Permet a [MapScreen] de rester
/// StatelessWidget tout en beneficiant d'un controller persistent
/// tant que l'ecran est monte.
///
/// Le dispose est automatique grace a [ref.onDispose].
class MapControllerNotifier extends AutoDisposeNotifier<MapController> {
  @override
  MapController build() {
    final controller = MapController();
    ref.onDispose(controller.dispose);
    return controller;
  }
}

/// Provider du [MapController] gere par [MapControllerNotifier].
///
/// Usage dans un Consumer :
/// ```dart
/// Consumer(
///   builder: (context, ref, _) {
///     final controller = ref.watch(mapControllerProvider);
///     return FlutterMap(mapController: controller, ...);
///   },
/// )
/// ```
final mapControllerProvider =
    AutoDisposeNotifierProvider<MapControllerNotifier, MapController>(
  MapControllerNotifier.new,
);
