import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/track_point.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../providers/gpx_track_provider.dart';
import '../providers/simplified_track_provider.dart';
import '../widgets/trail_polyline.dart';

/// Écran carte plein écran affichant le tracé GPX du sentier.
///
/// Utilise flutter_map avec des tuiles OpenStreetMap.
/// Le tracé est simplifié selon le niveau de zoom via Douglas-Peucker.
/// Se centre automatiquement sur la bounding box du tracé au chargement.
class TrailMapScreen extends ConsumerStatefulWidget {
  const TrailMapScreen({super.key, required this.trailId});

  /// Identifiant du sentier à afficher
  final String trailId;

  @override
  ConsumerState<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends ConsumerState<TrailMapScreen> {
  final MapController _mapController = MapController();
  int _currentZoom = 10;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Calcule la bounding box englobant tous les points du tracé
  LatLngBounds _boundsFromPoints(List<TrackPoint> points) {
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;

    for (final pt in points) {
      if (pt.lat < minLat) minLat = pt.lat;
      if (pt.lat > maxLat) maxLat = pt.lat;
      if (pt.lng < minLng) minLng = pt.lng;
      if (pt.lng > maxLng) maxLng = pt.lng;
    }

    return LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(trailConfigProvider);
    final rawTrack = ref.watch(gpxTrackProvider(widget.trailId));
    final trailColor = Color(config.primaryColorValue);

    return Scaffold(
      appBar: AppBar(
        title: Text(config.displayName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: rawTrack.when(
        loading: () => const LoadingOverlay(message: 'Chargement du tracé...'),
        error: (error, _) => EmptyState(
          icon: Icons.error_outline,
          title: 'Impossible de charger le tracé',
          subtitle: error.toString(),
        ),
        data: (points) {
          if (points.isEmpty) {
            return const EmptyState(
              icon: Icons.map_outlined,
              title: 'Aucun tracé disponible',
              subtitle: 'Le fichier GPX ne contient aucun point.',
            );
          }

          // Récupérer le tracé simplifié pour le zoom courant
          final simplifiedAsync = ref.watch(
            simplifiedTrackProvider((
              trailId: widget.trailId,
              zoomLevel: _currentZoom,
            )),
          );

          final displayPoints = simplifiedAsync.valueOrNull ?? points;
          final bounds = _boundsFromPoints(points);

          return FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(32),
              ),
              onPositionChanged: (position, hasGesture) {
                final newZoom = position.zoom?.round() ?? _currentZoom;
                if (newZoom != _currentZoom) {
                  setState(() => _currentZoom = newZoom);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.moteur-gr.app',
              ),
              TrailPolyline.build(
                points: displayPoints,
                color: trailColor,
              ),
            ],
          );
        },
      ),
    );
  }
}
