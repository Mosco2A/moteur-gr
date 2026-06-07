import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Clustering de marqueurs + helpers de simplification dependants du zoom.
///
/// Objectif perf (E5.2a) : au-dela de [kClusterThreshold] marqueurs, on
/// agrege les points proches en bulles de cluster pour eviter de construire
/// des centaines de widgets Marker a chaque frame. L'algorithme est en O(n)
/// (grille spatiale) afin de tenir dans un budget de frame (<16ms) meme a
/// 100+ marqueurs.
///
/// Le module est volontairement decouple de flutter_map pour la partie
/// calcul ([MarkerClusterer.cluster]) afin d'etre testable et benchmarkable
/// sans pumper de widget.

/// Seuil au-dela duquel le clustering s'active.
///
/// En-dessous (<=), chaque point reste un marqueur isole : pas d'agregation,
/// donc aucun changement de rendu pour les cartes a faible densite.
const int kClusterThreshold = 50;

/// Rayon d'agregation en pixels ecran (a un zoom donne).
///
/// Deux marqueurs distants de moins de ~[_clusterPixelRadius] px sont
/// candidats a la fusion. 60 px est la valeur usuelle des bibliotheques
/// de clustering cartographique.
const double _clusterPixelRadius = 60.0;

/// Largeur d'une tuile carto en pixels (OSM/standard slippy map).
const double _tileSizePx = 256.0;

/// Un point clusterisable : une position + une charge utile typee.
@immutable
class ClusterPoint<T> {
  const ClusterPoint({required this.position, required this.data});

  /// Position geographique du point.
  final LatLng position;

  /// Donnee metier associee (POI, etape, etc.).
  final T data;
}

/// Resultat d'un clustering : soit un point isole, soit un agregat.
///
/// [position] est le centroide des membres. [count] vaut 1 pour un point
/// isole, >1 pour un cluster.
@immutable
class MarkerCluster<T> {
  const MarkerCluster({required this.position, required this.points});

  /// Centroide (moyenne des positions des membres).
  final LatLng position;

  /// Points membres de ce cluster (au moins un).
  final List<ClusterPoint<T>> points;

  /// Nombre de points agreges.
  int get count => points.length;

  /// Vrai si plus d'un point a ete agrege.
  bool get isCluster => points.length > 1;
}

/// Algorithme de clustering par grille spatiale dependante du zoom.
abstract final class MarkerClusterer {
  /// Regroupe [points] en clusters selon une grille dont la maille depend
  /// du [zoom].
  ///
  /// Si le nombre de points est <= [threshold], chaque point devient son
  /// propre cluster singleton (aucune agregation) — la densite est trop
  /// faible pour justifier le surcout.
  ///
  /// Sinon, les points sont ranges dans des cellules de grille de taille
  /// [cellSizeForZoom] (en degres) ; chaque cellule non vide produit un
  /// cluster centre sur le centroide de ses membres. Complexite O(n).
  static List<MarkerCluster<T>> cluster<T>(
    List<ClusterPoint<T>> points, {
    required double zoom,
    int threshold = kClusterThreshold,
  }) {
    if (points.length <= threshold) {
      return [
        for (final p in points)
          MarkerCluster<T>(position: p.position, points: [p]),
      ];
    }

    final cellDeg = cellSizeForZoom(zoom);
    // Cle de cellule = (indice lat, indice lng). Les records Dart 3 ont une
    // egalite structurelle native, parfaits comme cle de Map.
    final buckets = <(int, int), List<ClusterPoint<T>>>{};

    for (final p in points) {
      final key = (
        (p.position.latitude / cellDeg).floor(),
        (p.position.longitude / cellDeg).floor(),
      );
      (buckets[key] ??= <ClusterPoint<T>>[]).add(p);
    }

    final clusters = <MarkerCluster<T>>[];
    for (final members in buckets.values) {
      var sumLat = 0.0;
      var sumLng = 0.0;
      for (final m in members) {
        sumLat += m.position.latitude;
        sumLng += m.position.longitude;
      }
      final n = members.length;
      clusters.add(
        MarkerCluster<T>(
          position: LatLng(sumLat / n, sumLng / n),
          points: members,
        ),
      );
    }
    return clusters;
  }

  /// Taille de maille de la grille de clustering, en degres, pour un [zoom].
  ///
  /// Derivee d'un rayon d'agregation en pixels : a un zoom donne, une tuile
  /// de 256 px couvre `360 / 2^zoom` degres de longitude. La maille
  /// correspond donc a [_clusterPixelRadius] px convertis en degres.
  /// Plus le zoom est eleve, plus la maille est fine (moins d'agregation).
  static double cellSizeForZoom(double zoom) {
    final z = zoom.clamp(1.0, 22.0);
    final degreesPerTile = 360.0 / math.pow(2, z);
    return (_clusterPixelRadius / _tileSizePx) * degreesPerTile;
  }
}

/// Epsilon Douglas-Peucker (en metres) dependant du zoom, continu par niveau.
///
/// Remplace les anciens paliers discrets : l'epsilon decroit
/// exponentiellement quand on zoome (vue large = forte simplification,
/// vue rapprochee = plein detail). Au-dela de [_fullDetailZoom], epsilon = 0
/// (tous les points sont conserves).
///
/// Partage par [simplified_track_provider] pour que la simplification de
/// trace suive la meme courbe que le clustering.
double dynamicEpsilonForZoom(int zoomLevel) {
  const fullDetailZoom = 15;
  const referenceZoom = 14;
  const referenceEpsilon = 8.0; // metres a [referenceZoom]
  const maxEpsilon = 500.0;

  if (zoomLevel >= fullDetailZoom) return 0.0;

  // x2 d'epsilon par niveau de zoom perdu sous la reference.
  final levelsBelow = referenceZoom - zoomLevel;
  final eps = referenceEpsilon * math.pow(2, levelsBelow).toDouble();
  return eps.clamp(0.0, maxEpsilon);
}

/// Couche de marqueurs clusterisee pour flutter_map v8.
///
/// Construit un [MarkerLayer] dans lequel :
/// - les points isoles sont rendus via [singleMarkerBuilder] ;
/// - les agregats sont rendus en bulles de cluster (cercle + compteur),
///   tappables via [onClusterTap] (typiquement : zoomer dessus).
///
/// La couche est statique vis-a-vis de la position GPS : elle peut donc
/// etre enveloppee dans un `RepaintBoundary` par l'appelant.
class ClusteredMarkerLayer<T> extends StatelessWidget {
  const ClusteredMarkerLayer({
    super.key,
    required this.points,
    required this.zoom,
    required this.singleMarkerBuilder,
    this.threshold = kClusterThreshold,
    this.clusterColor = const Color(0xFF1976D2),
    this.clusterTextColor = Colors.white,
    this.clusterSize = 40.0,
    this.onClusterTap,
  });

  /// Points a afficher (chacun porte sa donnee metier).
  final List<ClusterPoint<T>> points;

  /// Niveau de zoom courant de la carte.
  final double zoom;

  /// Constructeur d'un marqueur pour un point isole.
  final Marker Function(BuildContext context, ClusterPoint<T> point)
      singleMarkerBuilder;

  /// Seuil d'activation du clustering.
  final int threshold;

  /// Couleur de la bulle de cluster.
  final Color clusterColor;

  /// Couleur du compteur dans la bulle.
  final Color clusterTextColor;

  /// Diametre de la bulle de cluster en pixels.
  final double clusterSize;

  /// Callback au tap sur une bulle de cluster (centroide + nb de points).
  final void Function(MarkerCluster<T> cluster)? onClusterTap;

  @override
  Widget build(BuildContext context) {
    final clusters = MarkerClusterer.cluster<T>(
      points,
      zoom: zoom,
      threshold: threshold,
    );

    final markers = <Marker>[
      for (final c in clusters)
        if (c.isCluster)
          Marker(
            point: c.position,
            width: clusterSize,
            height: clusterSize,
            child: _ClusterBubble(
              count: c.count,
              color: clusterColor,
              textColor: clusterTextColor,
              onTap: onClusterTap == null ? null : () => onClusterTap!(c),
            ),
          )
        else
          singleMarkerBuilder(context, c.points.first),
    ];

    return MarkerLayer(markers: markers);
  }
}

/// Bulle visuelle d'un cluster : cercle colore + compteur centre.
class _ClusterBubble extends StatelessWidget {
  const _ClusterBubble({
    required this.count,
    required this.color,
    required this.textColor,
    this.onTap,
  });

  final int count;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          '$count',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: count >= 100 ? 11 : 13,
          ),
        ),
      ),
    );
  }
}
