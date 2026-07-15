// BRIDGE: Le nouvel ecran carte est lib/features/trek/presentation/map/map_screen.dart (MapScreen).
// TrailMapScreen est conserve pour retrocompatibilite pendant la migration Phase 2.
// A terme, app_router pointera vers MapScreen et ce fichier sera supprime.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/track_point.dart';
import '../../../core/models/poi.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_overlay.dart';
import '../../trek/presentation/map/marker_cluster.dart';
import '../providers/gpx_track_provider.dart';
import '../providers/location_provider.dart';
import '../providers/map_pois_provider.dart';
import '../providers/simplified_track_provider.dart';
import '../providers/track_position_provider.dart';
import '../widgets/poi_filter_bar.dart';
import '../widgets/poi_marker.dart';
import '../widgets/poi_popup.dart';
import '../widgets/stage_progress_bar.dart';
import '../widgets/trail_polyline.dart';
import '../widgets/user_position_marker.dart';
import '../../tracking/presentation/tracking_overlay.dart';

/// Ecran carte plein ecran affichant le trace GPX du sentier.
///
/// Utilise flutter_map avec des tuiles OpenStreetMap.
/// Le trace est simplifie selon le niveau de zoom via Douglas-Peucker.
/// Se centre automatiquement sur la bounding box du trace au chargement.
/// Affiche la position GPS de l'utilisateur et la progression d'etape.
class TrailMapScreen extends ConsumerStatefulWidget {
  const TrailMapScreen({super.key, required this.trailId});

  /// Identifiant du sentier a afficher
  final String trailId;

  @override
  ConsumerState<TrailMapScreen> createState() => _TrailMapScreenState();
}

class _TrailMapScreenState extends ConsumerState<TrailMapScreen> {
  final MapController _mapController = MapController();
  int _currentZoom = 10;
  PoiModel? _selectedPoi;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  /// Calcule la bounding box englobant tous les points du trace
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

  /// Centre la carte sur la position GPS de l'utilisateur
  void _centerOnUser() {
    final positionAsync = ref.read(locationProvider);
    positionAsync.whenData((position) {
      _mapController.move(
        LatLng(position.latitude, position.longitude),
        15.0,
      );
    });
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

          return _buildMapContent(context, points, trailColor);
        },
      ),
    );
  }

  /// Construit le contenu carte avec trace, POIs, position et progression.
  Widget _buildMapContent(
    BuildContext context,
    List<TrackPoint> points,
    Color trailColor,
  ) {
    final simplifiedAsync = ref.watch(
      simplifiedTrackProvider((
        trailId: widget.trailId,
        zoomLevel: _currentZoom,
      )),
    );

    final poisAsync = ref.watch(mapPoisProvider(widget.trailId));
    final filteredPois = poisAsync.value ?? [];

    // Position GPS de l'utilisateur
    final userPositionAsync = ref.watch(locationProvider);

    // Position projetee sur le trace
    final trackPosAsync = ref.watch(trackPositionProvider);

    final displayPoints = simplifiedAsync.value ?? points;
    final bounds = _boundsFromPoints(points);

    return Column(
      children: [
        PoiFilterBar(trailId: widget.trailId),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: bounds,
                    padding: const EdgeInsets.all(32),
                  ),
                  onPositionChanged: (camera, hasGesture) {
                    final newZoom = camera.zoom.round();
                    if (newZoom != _currentZoom) {
                      setState(() => _currentZoom = newZoom);
                    }
                  },
                  onTap: (_, __) {
                    if (_selectedPoi != null) {
                      setState(() => _selectedPoi = null);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.moteur-gr.app',
                  ),
                  // Trace statique -> RepaintBoundary (raster isole des
                  // rebuilds POI/position)
                  RepaintBoundary(
                    child: TrailPolyline.build(
                      points: displayPoints,
                      color: trailColor,
                    ),
                  ),
                  // POIs statiques -> clusterises au-dela du seuil + raster
                  // isole. Le marqueur de position utilisateur reste dans
                  // une couche dynamique separee (au-dessus).
                  RepaintBoundary(
                    child: ClusteredMarkerLayer<PoiModel>(
                      zoom: _currentZoom.toDouble(),
                      points: [
                        for (final poi in filteredPois)
                          ClusterPoint<PoiModel>(
                            position: LatLng(poi.lat, poi.lng),
                            data: poi,
                          ),
                      ],
                      singleMarkerBuilder: (context, point) {
                        final poi = point.data;
                        return Marker(
                          point: point.position,
                          width: 36,
                          height: 36,
                          child: Semantics(
                            button: true,
                            label: t.a11y.poiMarker(name: poi.name),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedPoi = poi),
                              child: ExcludeSemantics(
                                child: PoiMarker(type: poi.type),
                              ),
                            ),
                          ),
                        );
                      },
                      onClusterTap: (cluster) {
                        _mapController.move(
                          cluster.position,
                          _mapController.camera.zoom + 2,
                        );
                      },
                    ),
                  ),
                  // Marqueur position utilisateur (dynamique, au-dessus)
                  MarkerLayer(
                    markers: [
                      ...userPositionAsync.maybeWhen(
                        data: (position) => [
                          Marker(
                            point: LatLng(
                              position.latitude,
                              position.longitude,
                            ),
                            width: 60,
                            height: 60,
                            child: Semantics(
                              label: t.a11y.userPosition,
                              image: true,
                              child: const UserPositionMarker(),
                            ),
                          ),
                        ],
                        orElse: () => <Marker>[],
                      ),
                    ],
                  ),
                ],
              ),

              // Popup du POI selectionne
              if (_selectedPoi != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPoi = null),
                      child: PoiPopup(poi: _selectedPoi!),
                    ),
                  ),
                ),

              // Bouton centrer sur moi
              Positioned(
                right: 16,
                bottom: _hasTrackPosition(trackPosAsync) ? 130 : 16,
                child: FloatingActionButton.small(
                  heroTag: 'centerOnMe',
                  onPressed: _centerOnUser,
                  child: const Icon(Icons.my_location),
                ),
              ),

              // Barre de progression d'etape
              if (_hasTrackPosition(trackPosAsync))
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildProgressBar(trackPosAsync),
                ),

              // Overlay de tracking GPS
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: TrackingOverlay(trailId: widget.trailId),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Verifie si la position sur le trace est disponible.
  bool _hasTrackPosition(AsyncValue<TrackPositionState> trackPosAsync) {
    return trackPosAsync.whenOrNull(data: (state) => true) ?? false;
  }

  /// Construit la barre de progression a partir de l'etat du trace.
  Widget _buildProgressBar(AsyncValue<TrackPositionState> trackPosAsync) {
    return trackPosAsync.when(
      data: (state) {
        final stageName = 'Etape ${state.stageDetection.stageNumber}';
        return StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: state.distanceRemainingKm,
          progressRatio: state.progressRatio,
          isOffTrack: state.isOffTrack,
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
