import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../domain/models/stage.dart';

/// Couleur du marqueur de depart (premier index).
const _kStartColor = Color(0xFF2E7D32); // vert

/// Couleur du marqueur d'arrivee (dernier index).
const _kFinishColor = Color(0xFFC62828); // rouge

/// Couleur des marqueurs intermediaires.
const _kDefaultColor = Color(0xFF1565C0); // bleu

/// Taille du marqueur cercle.
const _kMarkerSize = 36.0;

/// Layer FlutterMap v8 affichant un marqueur cercle numerote pour chaque etape.
///
/// Couleurs :
/// - index 0 = vert (depart)
/// - dernier index = rouge (arrivee)
/// - tous les autres = bleu
///
/// Chaque marqueur expose un callback [onStageTap] avec le `stageId`
/// de l'etape tapee, destine a la navigation GoRouter.
///
/// ZERO nom de lieu specifique — seul le numero d'etape est affiche.
class StageMarkersLayer extends StatelessWidget {
  const StageMarkersLayer({
    super.key,
    required this.stages,
    required this.onStageTap,
  });

  /// Liste ordonnee des etapes a afficher.
  final List<Stage> stages;

  /// Callback appele au tap sur un marqueur, avec l'id de l'etape.
  final void Function(String stageId) onStageTap;

  /// Determine la couleur du marqueur selon sa position dans la liste.
  @visibleForTesting
  static Color colorForIndex(int index, int total) {
    if (total <= 0) return _kDefaultColor;
    if (index == 0) return _kStartColor;
    if (index == total - 1) return _kFinishColor;
    return _kDefaultColor;
  }

  @override
  Widget build(BuildContext context) {
    return MarkerLayer(
      markers: [
        for (int i = 0; i < stages.length; i++)
          _buildMarker(stages[i], i, stages.length),
      ],
    );
  }

  /// Construit un [Marker] FlutterMap v8 pour une etape donnee.
  Marker _buildMarker(Stage stage, int index, int total) {
    final color = colorForIndex(index, total);
    final number = index + 1;

    return Marker(
      point: LatLng(stage.startLat, stage.startLng),
      width: _kMarkerSize,
      height: _kMarkerSize,
      child: GestureDetector(
        onTap: () => onStageTap(stage.id),
        child: Container(
          width: _kMarkerSize,
          height: _kMarkerSize,
          decoration: BoxDecoration(
            color: color,
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
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
