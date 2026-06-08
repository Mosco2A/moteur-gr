import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../i18n/translations.g.dart';
import '../../../domain/models/stage.dart';
import '../marker_cluster.dart';

/// Composant marqueurs d'etapes - affiche un cercle numerote par etape.
///
/// Encapsule un [MarkerLayer] flutter_map v8.
/// Couleurs : premiere etape = vert, derniere = rouge, intermediaires = bleu.
/// Callback [onStageTap] pour navigation vers le detail de l'etape.
///
/// Perf (E5.2a) : au-dela de [kClusterThreshold] etapes et si [zoom] est
/// fourni, les marqueurs proches sont agreges en bulles de cluster via
/// [ClusteredMarkerLayer] (rare pour des etapes, mais garanti homogene
/// avec le reste de la carte).
class StageMarkersLayer extends StatelessWidget {
  const StageMarkersLayer({
    super.key,
    required this.stages,
    this.onStageTap,
    this.markerSize = 32.0,
    this.zoom,
  });

  /// Liste des etapes a afficher sur la carte.
  final List<Stage> stages;

  /// Callback appele au tap sur un marqueur, avec le stageId.
  final void Function(String stageId)? onStageTap;

  /// Taille des marqueurs en pixels.
  final double markerSize;

  /// Niveau de zoom courant (active le clustering au-dela du seuil).
  final double? zoom;

  /// Retourne la couleur du marqueur selon sa position dans la liste.
  Color _markerColor(int index) {
    if (stages.length <= 1) return Colors.green;
    if (index == 0) return Colors.green;
    if (index == stages.length - 1) return Colors.red;
    return Colors.blue;
  }

  /// Construit le marqueur visuel d'une etape (cercle numerote).
  Marker _stageMarker(int index) {
    final stage = stages[index];
    return Marker(
      point: LatLng(stage.startLat, stage.startLng),
      width: markerSize,
      height: markerSize,
      child: Semantics(
        button: onStageTap != null,
        label: t.a11y.stageMarker(number: stage.orderIndex),
        child: GestureDetector(
          onTap: onStageTap != null ? () => onStageTap!(stage.id) : null,
          child: ExcludeSemantics(
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentZoom = zoom;
    if (currentZoom != null && stages.length > kClusterThreshold) {
      return ClusteredMarkerLayer<int>(
        zoom: currentZoom,
        points: [
          for (var i = 0; i < stages.length; i++)
            ClusterPoint<int>(
              position: LatLng(stages[i].startLat, stages[i].startLng),
              data: i,
            ),
        ],
        singleMarkerBuilder: (context, point) => _stageMarker(point.data),
      );
    }

    return MarkerLayer(
      markers: List.generate(stages.length, _stageMarker),
    );
  }
}
