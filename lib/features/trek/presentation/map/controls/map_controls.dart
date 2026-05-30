import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Controles de carte — zoom in, zoom out, centrer sur moi.
///
/// Trois [FloatingActionButton] empiles verticalement (Material 3).
/// Recoit un [MapController] pour piloter le zoom et un callback
/// [onCenterOnMe] pour recentrer sur la position utilisateur.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.mapController,
    required this.onCenterOnMe,
  });

  /// Controleur FlutterMap v8 pour piloter zoom et camera.
  final MapController mapController;

  /// Callback appele lors du tap sur le bouton "centrer sur moi".
  final VoidCallback onCenterOnMe;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'mapZoomIn',
          onPressed: _zoomIn,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'mapZoomOut',
          onPressed: _zoomOut,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'mapCenterOnMe',
          onPressed: onCenterOnMe,
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  void _zoomIn() {
    final currentZoom = mapController.camera.zoom;
    mapController.move(
      mapController.camera.center,
      currentZoom + 1,
    );
  }

  void _zoomOut() {
    final currentZoom = mapController.camera.zoom;
    mapController.move(
      mapController.camera.center,
      currentZoom - 1,
    );
  }
}
