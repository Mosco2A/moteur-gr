import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../i18n/translations.g.dart';
import '../../../../settings/presentation/skin_selector.dart';

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

    // Ordre de focus logique (a11y E5.3b) : changer de peau -> zoom + ->
    // zoom - -> centrer.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Acces « Changer de peau » (SW-SKIN-L7) : ouvre le meme selecteur
          // que les Reglages, en bottom-sheet. Le marcheur choisit sa peau
          // directement depuis la carte (exige par le mandat).
          FocusTraversalOrder(
            order: const NumericFocusOrder(0),
            child: FloatingActionButton.small(
              heroTag: 'mapChangeSkin',
              onPressed: () => showSkinSelectorSheet(context),
              tooltip: t.appearance.changeSkin,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.brush_outlined),
            ),
          ),
          const SizedBox(height: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(1),
            child: FloatingActionButton.small(
              heroTag: 'mapZoomIn',
              onPressed: _zoomIn,
              tooltip: t.a11y.zoomIn,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.add),
            ),
          ),
          const SizedBox(height: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(2),
            child: FloatingActionButton.small(
              heroTag: 'mapZoomOut',
              onPressed: _zoomOut,
              tooltip: t.a11y.zoomOut,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.remove),
            ),
          ),
          const SizedBox(height: 8),
          FocusTraversalOrder(
            order: const NumericFocusOrder(3),
            child: FloatingActionButton.small(
              heroTag: 'mapCenterOnMe',
              onPressed: onCenterOnMe,
              tooltip: t.a11y.centerOnMe,
              backgroundColor: colorScheme.primaryContainer,
              foregroundColor: colorScheme.onPrimaryContainer,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
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
