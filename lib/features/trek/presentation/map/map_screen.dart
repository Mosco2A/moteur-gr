import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/track_point.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_overlay.dart';
import '../../../map/providers/gpx_track_provider.dart';
import '../../../map/widgets/trail_polyline.dart';
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

/// Contenu carte avec FlutterMap et overlays.
///
/// Affiche la carte une fois les points GPS charges.
/// Chaque donnee reactive est dans son propre Consumer.
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

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(32),
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moteur-gr.app',
                ),
                TrailPolyline.build(
                  points: points,
                  color: trailColor,
                ),
              ],
            );
          },
        ),

        // Overlay : bouton recentrer sur le trace
        Positioned(
          right: 16,
          bottom: 16,
          child: Consumer(
            builder: (context, ref, _) {
              return FloatingActionButton.small(
                heroTag: 'centerOnTrail',
                onPressed: () {
                  final controller = ref.read(mapControllerProvider);
                  final bounds = _boundsFromPoints(points);
                  controller.fitCamera(
                    CameraFit.bounds(
                      bounds: bounds,
                      padding: const EdgeInsets.all(32),
                    ),
                  );
                },
                child: const Icon(Icons.center_focus_strong),
              );
            },
          ),
        ),
      ],
    );
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
