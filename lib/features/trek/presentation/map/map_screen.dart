import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/track_point.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../map/providers/location_provider.dart';
import '../../providers/trail_providers.dart';
import 'controls/map_controls.dart';
import 'layers/stage_markers_layer.dart';
import 'layers/trace_layer.dart';
import 'layers/user_position_layer.dart';
import '../../../map/providers/gpx_track_provider.dart';
import 'map_controller_notifier.dart';

/// Ecran carte principal du mode trek.
///
/// Orchestrateur FlutterMap v8 respectant les contraintes Riverpod :
/// - StatelessWidget — pas de mutable state local
/// - ZERO ref.watch() dans build() — chaque donnee est isolee
///   dans un [Consumer] avec select() pour limiter les rebuilds
/// - MapController initialise dans [MapControllerNotifier] (auto-dispose)
/// - AsyncValue.when pour les 3 etats : loading, error, data
///
/// Structure : Scaffold > Stack > FlutterMap + overlay widgets.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer pour le nom du sentier (AppBar) — select sur displayName
    return Consumer(
      builder: (context, ref, _) {
        final trailName = ref.watch(
          trailConfigProvider.select((config) => config.displayName),
        );
        final trailId = ref.watch(
          trailConfigProvider.select((config) => config.id),
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(trailName),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: _MapBody(trailId: trailId),
        );
      },
    );
  }
}

/// Corps de la carte — gere le tri-state AsyncValue.
///
/// Isole dans un widget separe pour que le Scaffold/AppBar
/// ne soit pas reconstruit quand les donnees GPS changent.
class _MapBody extends StatelessWidget {
  const _MapBody({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    // Consumer pour le trace GPX — AsyncValue.when
    return Consumer(
      builder: (context, ref, _) {
        final trackAsync = ref.watch(gpxTrackProvider(trailId));

        return trackAsync.when(
          loading: () =>
              const LoadingOverlay(message: 'Chargement du trace...'),
          error: (error, _) => EmptyState(
            icon: Icons.error_outline,
            title: 'Impossible de charger le trace',
            subtitle: error.toString(),
          ),
          data: (points) {
            if (points.isEmpty) {
              return const EmptyState(
                icon: Icons.map_outlined,
                title: 'Aucun trace disponible',
                subtitle: 'Le fichier GPX ne contient aucun point.',
              );
            }

            return _MapContent(
              trailId: trailId,
              points: points,
            );
          },
        );
      },
    );
  }
}

/// Contenu carte avec FlutterMap et overlays -- tous layers assembles.
///
/// Affiche la carte une fois les points GPS charges.
/// Chaque donnee reactive est dans son propre Consumer :
/// - MapController + trace GPX dans le Consumer principal
/// - Etapes dans un Consumer dedie (StageMarkersLayer)
/// - Position GPS dans un Consumer dedie (UserPositionLayer)
/// - Controles dans un Consumer dedie (MapControls overlay)
class _MapContent extends StatelessWidget {
  const _MapContent({
    required this.trailId,
    required this.points,
  });

  final String trailId;
  final List<TrackPoint> points;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Consumer pour le MapController (Notifier auto-dispose)
        Consumer(
          builder: (context, ref, _) {
            final mapController = ref.watch(mapControllerProvider);
            final trailColor = Color(
              ref.watch(
                trailConfigProvider.select((c) => c.primaryColorValue),
              ),
            );

            final bounds = _boundsFromPoints(points);
            final latLngPoints = points
                .map((tp) => LatLng(tp.lat, tp.lng))
                .toList(growable: false);

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(32),
                ),
              ),
              children: [
                // Layer 1 : fond de carte OpenStreetMap
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moteur-gr.app',
                ),

                // Layer 2 : trace GPX (polyline)
                TraceLayer(
                  points: latLngPoints,
                  color: trailColor,
                ),

                // Layer 3 : marqueurs des etapes (Consumer dedie)
                Consumer(
                  builder: (context, ref, _) {
                    final stagesAsync = ref.watch(trekStagesProvider);
                    return stagesAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (stages) => StageMarkersLayer(
                        stages: stages,
                        onStageTap: (stageId) {
                          context.pushNamed(
                            'stage-detail',
                            pathParameters: {
                              'id': trailId,
                              'num': _extractStageNumber(stageId),
                            },
                          );
                        },
                      ),
                    );
                  },
                ),

                // Layer 4 : position GPS de l'utilisateur (Consumer dedie)
                Consumer(
                  builder: (context, ref, _) {
                    final locationAsync = ref.watch(locationProvider);
                    return locationAsync.when(
                      loading: () => const UserPositionLayer(position: null),
                      error: (_, __) =>
                          const UserPositionLayer(position: null),
                      data: (position) => UserPositionLayer(
                        position: LatLng(
                          position.latitude,
                          position.longitude,
                        ),
                        accuracy: position.accuracy,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),

        // Overlay : MapControls (zoom + centrer sur moi)
        Positioned(
          right: 16,
          bottom: 16,
          child: Consumer(
            builder: (context, ref, _) {
              return MapControls(
                mapController: ref.watch(mapControllerProvider),
                onCenterOnMe: () {
                  final locationAsync = ref.read(locationProvider);
                  locationAsync.whenData((position) {
                    ref.read(mapControllerProvider).move(
                          LatLng(position.latitude, position.longitude),
                          15.0,
                        );
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// Extrait le numero d'etape depuis un stageId (format: 'trailId-N').
  String _extractStageNumber(String stageId) {
    final parts = stageId.split('-');
    return parts.isNotEmpty ? parts.last : '1';
  }

  /// Calcule la bounding box englobant tous les points du trace.
  LatLngBounds _boundsFromPoints(List<TrackPoint> pts) {
    var minLat = pts.first.lat;
    var maxLat = pts.first.lat;
    var minLng = pts.first.lng;
    var maxLng = pts.first.lng;

    for (final pt in pts) {
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
}
