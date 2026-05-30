import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/models/stage.dart';

/// Composant marqueurs d'etapes - affiche un cercle numerote par etape.
///
/// Encapsule un [MarkerLayer] flutter_map v8.
/// Couleurs : premiere etape = vert, derniere = rouge, intermediaires = bleu.
/// Callback [onStageTap] pour navigation vers le detail de l'etape.
class StageMarkersLayer extends StatelessWidget {
  const StageMarkersLayer({
    super.key,
    required this.stages,
    this.onStageTap,
    this.markerSize = 32.0,
  });

  /// Liste des etapes a afficher sur la carte.
  final List<Stage> stages;

  /// Callback appele au tap sur un marqueur, avec le stageId.
  final void Function(String stageId)? onStageTap;

  /// Taille des marqueurs en pixels.
  final double markerSize;

  /// Retourne la couleur du marqueur selon sa position dans la liste.
  Color _markerColor(int index) {
    if (stages.length <= 1) return Colors.green;
    if (index == 0) return Colors.green;
    if (index == stages.length - 1) return Colors.red;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: List.generate(stages.length, (index) {
        final stage = stages[index];
        return Marker(
          point: LatLng(stage.startLat, stage.startLng),
          width: markerSize,
          height: markerSize,
          child: GestureDetector(
            onTap: onStageTap != null ? () => onStageTap!(stage.id) : null,
            child: Container(
              decoration: BoxDecoration(
                color: _markerColor(index),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '${stage.orderIndex}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
