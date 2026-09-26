import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../i18n/translations.g.dart';
import '../../../domain/models/stage.dart';
import '../marker_cluster.dart';

/// LE DISQUE NUMEROTE D'UNE ETAPE — le repere de parcours de la carte.
///
/// Extrait de [StageMarkersLayer] a la tache 571 pour qu'il n'existe qu'UNE
/// definition de ce disque : la couche des etapes seules le dessine, et la
/// couche unifiee du sentier (TrailMarkersLayer) le reutilise tel quel au
/// coeur de ses reperes fusionnes. Deux dessins du meme repere finiraient par
/// divergent — un liseré ici, une ombre la.
class StageNumberCircle extends StatelessWidget {
  const StageNumberCircle({
    super.key,
    required this.number,
    required this.color,
    this.size = 32.0,
  });

  /// Numero affiche au centre (l'ordre de l'etape dans le sentier).
  final int number;

  /// Couleur de fond du disque (cf. [stageMarkerColor]).
  final Color color;

  /// Diametre du disque en pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
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
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.375,
        ),
      ),
    );
  }
}

/// COULEUR DU DISQUE D'ETAPE selon sa place dans le sentier.
///
/// Premiere etape = vert (le depart), derniere = rouge (l'arrivee),
/// intermediaires = bleu. Regle partagee avec TrailMarkersLayer depuis la
/// tache 571 : le repere fusionne garde la couleur qu'il aurait eue seul.
Color stageMarkerColor(int index, int total) {
  if (total <= 1) return Colors.green;
  if (index == 0) return Colors.green;
  if (index == total - 1) return Colors.red;
  return Colors.blue;
}

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
///
/// PORTEE DEPUIS LA TACHE 571 : cette couche dessine les etapes SEULES. Elle
/// convient a une carte sans point d'interet, et c'est a ce titre qu'elle
/// reste. L'ecran carte du sentier, lui, passe par TrailMarkersLayer, qui
/// pose etapes ET points d'interet dans une couche UNIQUE — parce que deux
/// couches empilees ne peuvent pas, par construction, s'entendre sur un
/// repere commun quand elles designent le meme lieu.
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
            child: StageNumberCircle(
              number: stage.orderIndex,
              color: stageMarkerColor(index, stages.length),
              size: markerSize,
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
