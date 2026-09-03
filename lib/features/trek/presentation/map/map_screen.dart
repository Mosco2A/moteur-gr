import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/track_point.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/providers/gpx_track_provider.dart';
import '../../../map/providers/location_provider.dart';
import '../../../map/providers/off_track_provider.dart';
import '../../../map/providers/simplified_track_provider.dart';
import '../../../map/widgets/off_track_banner.dart';
import '../../../trail/providers/stages_provider.dart';
import '../../domain/models/stage.dart';
import '../../providers/gps_providers.dart';
import '../../providers/tracking_providers.dart';
import 'controls/map_controls.dart';
import 'layers/stage_markers_layer.dart';
import 'layers/trace_layer.dart';
import 'layers/user_position_layer.dart';

/// Provider du MapController, gere dans un Notifier pour le cycle de vie.
///
/// Expose le controleur de carte FlutterMap v8 de facon centralisee.
/// Le Notifier le cree au build et le dispose automatiquement.
class MapControllerNotifier extends Notifier<MapController> {
  @override
  MapController build() {
    final controller = MapController();
    ref.onDispose(controller.dispose);
    return controller;
  }
}

/// Provider Riverpod pour le MapController.
final mapControllerProvider =
    NotifierProvider<MapControllerNotifier, MapController>(
  MapControllerNotifier.new,
);

/// Ecran carte orchestrateur -- FlutterMap v8 + tous layers assembles.
///
/// Structure : Scaffold > Stack > FlutterMap(TileLayer, TraceLayer,
/// StageMarkersLayer, UserPositionLayer) + MapControls overlay.
/// ZERO ref.watch() dans build() -- chaque donnee passe par Consumer
/// avec select() pour un rebuild minimal et chirurgical.
class MapScreen extends StatelessWidget {
  const MapScreen({super.key, required this.trailId});

  /// Identifiant du sentier a afficher sur la carte.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final name = ref.watch(
              trailConfigProvider.select((c) => c.displayName),
            );
            return Text(name);
          },
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t.a11y.back,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final trackAsync = ref.watch(gpxTrackProvider(trailId));

          return trackAsync.when(
            loading: () => LoadingView(message: t.map.loading),
            error: (error, _) => ErrorView(
              message: 'Impossible de charger le trace',
              onRetry: () => ref.invalidate(gpxTrackProvider(trailId)),
            ),
            data: (points) {
              if (points.isEmpty) {
                return const ErrorView(
                  message: 'Aucun trace disponible',
                );
              }
              return _MapContent(trailId: trailId, rawPoints: points);
            },
          );
        },
      ),
    );
  }
}

/// Contenu carte interne -- separe pour isoler les rebuilds.
///
/// Recoit les points bruts en parametre (deja charges).
/// Utilise Consumer + select() pour chaque layer independant.
/// Stack : FlutterMap (TileLayer + TraceLayer + StageMarkersLayer
/// + UserPositionLayer) en fond, MapControls en overlay.
class _MapContent extends StatefulWidget {
  const _MapContent({required this.trailId, required this.rawPoints});

  final String trailId;
  final List<TrackPoint> rawPoints;

  @override
  State<_MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<_MapContent> {
  int _currentZoom = 10;

  /// Calcule la bounding box englobant tous les points du trace.
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
    final bounds = _boundsFromPoints(widget.rawPoints);

    return Stack(
      children: [
        // --- FlutterMap avec tous les layers ---
        Consumer(
          builder: (context, ref, _) {
            final mapController = ref.watch(mapControllerProvider);
            final simplifiedAsync = ref.watch(
              simplifiedTrackProvider((
                trailId: widget.trailId,
                zoomLevel: _currentZoom,
              )),
            );
            final trailColor = Color(
              ref.watch(
                trailConfigProvider.select((c) => c.primaryColorValue),
              ),
            );

            final displayPoints =
                simplifiedAsync.value ?? widget.rawPoints;

            // Convertir TrackPoint -> LatLng pour TraceLayer
            final latLngPoints = displayPoints
                .map((tp) => LatLng(tp.lat, tp.lng))
                .toList(growable: false);

            return FlutterMap(
              mapController: mapController,
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
              ),
              children: [
                // 1. Fond de carte OSM
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moteur-gr.app',
                ),

                // 2. Trace GPX (statique -> RepaintBoundary pour isoler
                //    le raster du trace des rebuilds de la position GPS)
                RepaintBoundary(
                  child: TraceLayer(
                    points: latLngPoints,
                    color: trailColor,
                  ),
                ),

                // 3. Marqueurs d etapes (statiques -> RepaintBoundary +
                //    clustering au-dela du seuil via le zoom courant)
                Consumer(
                  builder: (context, ref, _) {
                    final stagesAsync = ref.watch(
                      stagesProvider(widget.trailId).select(
                        (async) => async.value,
                      ),
                    );
                    final stages = stagesAsync ?? [];

                    if (stages.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    // Convertir StageModel -> Stage (domain)
                    final domainStages = stages
                        .map(
                          (sm) => Stage(
                            id: '${sm.stageNumber}',
                            nameFr: sm.name,
                            distance: sm.distanceKm,
                            elevationGain: sm.elevationGainM,
                            elevationLoss: sm.elevationLossM,
                            orderIndex: sm.stageNumber,
                            startLat: sm.startLat,
                            startLng: sm.startLng,
                            endLat: sm.endLat,
                            endLng: sm.endLng,
                            difficulty: sm.difficulty,
                          ),
                        )
                        .toList();

                    return RepaintBoundary(
                      child: StageMarkersLayer(
                        stages: domainStages,
                        zoom: _currentZoom.toDouble(),
                      ),
                    );
                  },
                ),

                // 4. Position utilisateur
                Consumer(
                  builder: (context, ref, _) {
                    final positionAsync = ref.watch(
                      locationProvider.select(
                        (async) => async.value,
                      ),
                    );

                    if (positionAsync == null) {
                      return const SizedBox.shrink();
                    }

                    return UserPositionLayer(
                      position: LatLng(
                        positionAsync.latitude,
                        positionAsync.longitude,
                      ),
                      accuracy: positionAsync.accuracy,
                    );
                  },
                ),
              ],
            );
          },
        ),

        // --- MapControls overlay (zoom + center) ---
        Positioned(
          right: 16,
          bottom: 16,
          child: Consumer(
            builder: (context, ref, _) {
              final mapController = ref.read(mapControllerProvider);

              return MapControls(
                mapController: mapController,
                onCenterOnMe: () {
                  final posAsync = ref.read(locationProvider);
                  final pos = posAsync.value;
                  if (pos != null) {
                    mapController.move(
                      LatLng(pos.latitude, pos.longitude),
                      mapController.camera.zoom,
                    );
                  } else {
                    // Fallback : recentrer sur le trace
                    mapController.fitCamera(
                      CameraFit.bounds(
                        bounds: bounds,
                        padding: const EdgeInsets.all(32),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),

        // --- Alerte hors-trace (securite) : banniere in-screen en tete.
        // La notification + la vibration partent du provider (meme telephone en
        // poche) ; ici on injecte les libelles traduits (Slang) dans le provider
        // et on affiche le bonus visuel. RepaintBoundary : isole du raster carte.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Consumer(
            builder: (context, ref, _) {
              // Sync des libelles de notification avec la langue courante,
              // hors phase de build (setMessages modifie un provider).
              final messages = OffTrackMessages(
                notifTitle: t.navAlert.offTrackNotifTitle,
                notifBody: (m) => t.navAlert.offTrackNotifBody(meters: m),
              );
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref
                    .read(offTrackMessagesProvider.notifier)
                    .setMessages(messages);
              });
              return const RepaintBoundary(child: OffTrackBanner());
            },
          ),
        ),

        // --- Pipeline detection d'etape -> arrivee -> finisher (PARITE GR20,
        // LOT 2, #99433). L'ecran carte est l'ECRAN TERRAIN ACTIF de StepWays :
        // on y monte le pont d'arrivee pour qu'il soit VIVANT pendant un trek.
        // GR20 fait pareil dans active_stage_screen. Rendu invisible.
        const _ArrivalPipelineMount(),
      ],
    );
  }
}

/// Monte le pipeline « detection d'etape -> arrivee -> complétion/finisher »
/// tant qu'un trek est en cours (PARITE GR20, LOT 2, #99433).
///
/// Au LOT 1, [arrivalCompletionListenerProvider] et [currentStageIdProvider]
/// n'etaient observes par AUCUN ecran : la chaine terrain etait INERTE (aucune
/// arrivee detectee, finisher jamais declenche). Cet element, monte dans l'ecran
/// carte (terrain actif), les rend vivants — mais UNIQUEMENT quand une session
/// est `recording`/`paused`, pour ne pas ouvrir le flux GPS hors trek (et rester
/// neutre dans les tests d'ecran a l'arret). Ne rend rien a l'ecran.
class _ArrivalPipelineMount extends ConsumerWidget {
  const _ArrivalPipelineMount();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive = status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;

    if (trekActive) {
      // Rend le pont d'arrivee -> etapes completees -> porte du finisher ACTIF
      // (il s'auto-abonne a arrivalEventsProvider). Sans achat cote vitrine, le
      // GPS est jouable (2.A) : le cycle complet peut donc se derouler.
      ref.watch(arrivalCompletionListenerProvider);
      // Alimente aussi la detection d'etape courante pendant la nav (parite
      // GR20) : etape affichee coherente avec la position.
      ref.watch(currentStageIdProvider);
    }

    return const SizedBox.shrink();
  }
}
