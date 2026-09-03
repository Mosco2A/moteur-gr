import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/track_point.dart';
import '../../../../core/models/poi.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/providers/gpx_track_provider.dart';
import '../../../map/providers/location_provider.dart';
import '../../../map/providers/map_pois_provider.dart';
import '../../../map/providers/off_track_provider.dart';
import '../../../map/providers/simplified_track_provider.dart';
import '../../../map/providers/track_position_provider.dart';
import '../../../map/widgets/off_track_banner.dart';
import '../../../map/widgets/poi_filter_bar.dart';
import '../../../map/widgets/poi_marker.dart';
import '../../../map/widgets/poi_popup.dart';
import '../../../map/widgets/stage_progress_bar.dart';
import '../../../safety/presentation/sos_button.dart';
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
/// PARITE GR20 (#99460, ecran Navigation terrain) : l'onglet Carte de StepWays
/// reprend, hors peau, tout ce que la Navigation GR20 affiche —
///   * fond OSM + trace de reference + position GPS (socle E2.3f) ;
///   * couche POI + bouton Calques (toggle par type, reutilise [PoiFilterBar]) ;
///   * bouton SOS (reutilise [SosButton], visible pendant un trek) ;
///   * banniere hors-trace VISIBLE (reutilise [OffTrackBanner]) ;
///   * barre d'etape active (reutilise [StageProgressBar]) pendant un trek.
/// Generique multi-sentiers (donnees du sentier courant, zero hardcode), i18n
/// Slang, a11y (SOS + calques labellises).
///
/// Structure : Scaffold > Stack > FlutterMap(TileLayer, TraceLayer, PoiLayer,
/// StageMarkersLayer, UserPositionLayer) + overlays (barre d'etape, controles,
/// SOS, calques, banniere hors-trace).
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
        // Fix retour (#99460) : l'onglet Carte est la RACINE d'une branche du
        // shell (StatefulShellRoute). Y appeler `Navigator.pop()` viderait une
        // pile vide -> bouton mort / exception. On ne pope que s'il y a
        // reellement une page a depiler (cas ou la carte est atteinte via un
        // `push` hors-shell) ; sinon on revient a l'accueil (comportement
        // attendu depuis le HUB, aligne sur le correctif « Itineraire »).
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t.a11y.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
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
/// Stack : FlutterMap (TileLayer + TraceLayer + PoiLayer + StageMarkersLayer
/// + UserPositionLayer) en fond, overlays (barre d'etape, controles, SOS,
/// calques, banniere hors-trace) par-dessus.
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

  /// Ouvre le panneau « Calques » (toggle des types de POI) — parite GR20
  /// (bouton calques de la Navigation). Reutilise [PoiFilterBar] : aucun
  /// nouveau modele, la selection persiste dans [activePoiTypesProvider].
  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 8),
                      Text(t.map.layersTitle, style: theme.textTheme.titleLarge),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    t.map.layersSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PoiFilterBar(trailId: widget.trailId),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Affiche le detail d'un POI au tap sur son marqueur (parite GR20 : bulle
  /// d'info au tap). Reutilise [PoiPopup] dans un bottom-sheet.
  void _showPoiDetails(BuildContext context, PoiModel poi) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: PoiPopup(poi: poi),
        ),
      ),
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

                // 4. Couche POI (parite GR20 : refuges/eau/points d'interet…),
                //    filtree par type via le panneau Calques. RepaintBoundary :
                //    isole le raster des marqueurs des rebuilds de position.
                Consumer(
                  builder: (context, ref, _) {
                    final poisAsync = ref.watch(
                      mapPoisProvider(widget.trailId).select(
                        (async) => async.value,
                      ),
                    );
                    final pois = poisAsync ?? const <PoiModel>[];
                    if (pois.isEmpty) return const SizedBox.shrink();

                    return RepaintBoundary(
                      child: MarkerLayer(
                        markers: [
                          for (final poi in pois)
                            Marker(
                              point: LatLng(poi.lat, poi.lng),
                              width: 36,
                              height: 36,
                              child: Semantics(
                                button: true,
                                label: t.a11y.poiMarker(name: poi.name),
                                child: GestureDetector(
                                  onTap: () => _showPoiDetails(context, poi),
                                  child: ExcludeSemantics(
                                    child: PoiMarker(type: poi.type),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // 5. Position utilisateur
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

        // --- Bloc bas : boutons flottants EMPILES AU-DESSUS de la barre
        // d'etape (parite GR20). Ancre en bas et en Column : la barre d'etape
        // (hauteur dynamique) ne recouvre jamais les boutons, quel que soit son
        // contenu — a l'inverse de Positioned a offset fixe. Rangee de boutons :
        //   * gauche  : SOS (au-dessus) + Calques — parite GR20 ;
        //   * droite  : controles carte (peau + zoom + centrer).
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Colonne gauche : SOS (visible en trek) + Calques.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SosButton(),
                        const SizedBox(height: 8),
                        FloatingActionButton.small(
                          heroTag: 'mapLayers',
                          tooltip: t.map.layers,
                          onPressed: () => _showLayersSheet(context),
                          child: const Icon(Icons.layers),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Colonne droite : controles carte (peau + zoom + centrer).
                    Consumer(
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
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Barre d'etape active (parite GR20 : bandeau de progression).
              // Visible uniquement pendant un trek reel, alimentee par la
              // projection sur le trace (etape, distance restante, progression,
              // hors-trace). Reutilise [StageProgressBar]. Rendu nul hors trek.
              const _ActiveStageBar(),
            ],
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

/// Barre d'etape active affichee en bas de la carte pendant un trek (PARITE
/// GR20 : bandeau de progression d'etape de la Navigation).
///
/// N'est rendue que lorsqu'une session est `recording`/`paused` ET qu'une
/// projection sur le trace est disponible (etape detectee). Alimente
/// [StageProgressBar] avec : nom de l'etape courante (donnees du sentier),
/// distance restante, progression et etat hors-trace — le tout depuis
/// [trackPositionProvider] et [stagesProvider] (source unique projetee, aucune
/// donnee en dur, generique multi-sentiers). Hors trek ou sans fix GPS : rendu
/// nul (SizedBox.shrink), la carte reste degagee.
class _ActiveStageBar extends ConsumerWidget {
  const _ActiveStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive = status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    if (!trekActive) return const SizedBox.shrink();

    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final trackPos = ref.watch(trackPositionProvider);

    return trackPos.maybeWhen(
      data: (state) {
        final stages = ref.watch(
          stagesProvider(trailId).select((async) => async.value),
        );
        // Nom de l'etape courante detectee (fallback : libelle generique).
        final stageNumber = state.stageDetection.stageNumber;
        final stage = (stages ?? const [])
            .where((s) => s.stageNumber == stageNumber)
            .firstOrNull;
        final stageName = stage?.name ??
            (stageNumber > 0
                ? t.a11y.stageMarker(number: stageNumber)
                : t.map.title);

        return StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: state.distanceRemainingKm,
          progressRatio: state.progressRatio,
          isOffTrack: state.isOffTrack,
        );
      },
      orElse: () => const SizedBox.shrink(),
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
