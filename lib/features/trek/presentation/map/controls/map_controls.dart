import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../../../../i18n/translations.g.dart';

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

    // Ordre de focus logique (a11y E5.3b) : zoom + -> zoom - -> centrer.
    //
    // LE BOUTON « CHANGER DE PEAU » A ETE RETIRE (tache 570, S4). Il ouvrait le
    // selecteur de peaux en bottom-sheet, c'est-a-dire un choix entre trois
    // peaux dont deux ne changent rien a l'ecran (`cardStyle` et
    // `photoScrimOpacity` ne sont lues par aucun widget, et Grand Air attend
    // encore ses photos). Decision de Chris du 26/09 : « retire ». La carte
    // reprend ses trois gestes de carte, et l'ordre de focus redescend de 0.
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FocusTraversalOrder(
            order: const NumericFocusOrder(0),
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
            order: const NumericFocusOrder(1),
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
            order: const NumericFocusOrder(2),
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
