import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Controles de la carte : zoom in, zoom out, recentrer sur moi.
///
/// Trois [FloatingActionButton] empiles verticalement (Column),
/// theme Material 3. Le widget est stateless — il recoit le
/// [MapController] et un callback [onCenterOnMe] depuis le parent.
///
/// Utilise [FloatingActionButton.small] pour un rendu discret
/// adapte a un overlay carte. Chaque bouton a un [heroTag] unique
/// pour eviter les conflits Hero dans le meme arbre.
class MapControls extends StatelessWidget {
  const MapControls({
    super.key,
    required this.mapController,
    required this.onCenterOnMe,
  });

  /// Controller FlutterMap pour piloter zoom in/out.
  final MapController mapController;

  /// Callback declenche par le bouton "recentrer sur moi".
  ///
  /// Le parent gere la logique GPS (recuperer la position,
  /// animer la camera). Ce widget ne fait que transmettre le tap.
  final VoidCallback onCenterOnMe;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton.small(
          heroTag: 'mapZoomIn',
          onPressed: _zoomIn,
          tooltip: 'Zoom avant',
          child: const Icon(Icons.add),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'mapZoomOut',
          onPressed: _zoomOut,
          tooltip: 'Zoom arriere',
          child: const Icon(Icons.remove),
        ),
        const SizedBox(height: 8),
        FloatingActionButton.small(
          heroTag: 'mapCenterOnMe',
          onPressed: onCenterOnMe,
          tooltip: 'Centrer sur moi',
          child: const Icon(Icons.my_location),
        ),
      ],
    );
  }

  void _zoomIn() {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom + 1);
  }

  void _zoomOut() {
    final camera = mapController.camera;
    mapController.move(camera.center, camera.zoom - 1);
  }
}
