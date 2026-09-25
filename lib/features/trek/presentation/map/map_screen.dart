import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/track_point.dart';
import '../../../../core/map/test_inert_tile_provider.dart';
import '../../../../core/models/poi.dart';
import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../journal/data/photo_service.dart';
import '../../../journal/providers/journal_providers.dart';
import '../../../map/providers/gpx_track_provider.dart';
import '../../../map/providers/location_provider.dart';
import '../../../map/providers/map_pois_provider.dart';
import '../../../map/providers/off_track_provider.dart';
import '../../../map/providers/simplified_track_provider.dart';
import '../../../map/providers/supply_alert_provider.dart';
import '../../../map/providers/track_position_provider.dart';
import '../../../map/widgets/map_guide_sheet.dart';
import '../../../map/widgets/off_track_banner.dart';
import '../../../map/widgets/poi_filter_bar.dart';
import '../../../map/widgets/poi_marker.dart';
import '../../../map/widgets/poi_popup.dart';
import '../../../map/widgets/stage_poi_checklist.dart';
import '../../../map/widgets/stage_progress_bar.dart';
import '../../../safety/presentation/sos_button.dart';
import '../../../trail/providers/stages_provider.dart';
import '../../domain/models/stage.dart';
import '../../providers/gps_providers.dart';
import '../../providers/live_trek_stats_provider.dart';
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
///
/// CARTE TERRAIN — PLUS AUCUNE BARRE DU BAS (correctif L6-3, 21/09/2026).
///
/// L'ecran portait une barre contextuelle heritee du LOT 3 (« Étape en cours »
/// / « Journal »). La navigation de reference n'a AUCUNE barre du bas sur sa
/// carte — sa seule definition de barre est un theme jamais consomme. Sur un
/// ecran de terrain, cette barre prenait de la hauteur utile a la carte et
/// proposait deux navigations deja accessibles depuis le cockpit, ou l'on
/// revient par le bouton retour. Elle est donc RETIREE.
///
/// NUANCE EXPLICITE, pour qu'elle ne soit pas « corrigee » par erreur plus
/// tard : l'accueil maison (`my_treks_screen.dart`) GARDE sa barre. C'est un
/// ecran multi-sentiers qui n'existe pas dans la reference — la comparaison ne
/// tient pas pour lui. Seule la barre de la CARTE etait un vrai ecart.
///
/// LOT D (tache 554) — « 14 navigation ne ressemble en rien a GR20 !!!!! »,
/// retour de Chris mot pour mot. Trois choses changent ici, et une seule etait
/// un vrai manque de fonction :
///
///  1. PLUS JAMAIS D'ECRAN NU. La barre d'etape ne se rendait QUE pendant un
///     trek avec fix GPS : un utilisateur neuf n'avait qu'une carte et des
///     boutons. Elle se rend desormais TOUJOURS — en trek avec les chiffres
///     mesures, avant le depart avec les chiffres DU PROGRAMME (distance de
///     l'etape, D+, D-) et un tiret sur ce qui demande le GPS. Cf.
///     [_PlannedStageBar].
///  2. LE BOUTON PHOTO VERS LE JOURNAL DU JOUR, present sur la carte de
///     reference (`_takePhoto`), qui n'existait nulle part cote StepWays. Cf.
///     [_MapPhotoButton] — et il respecte le verrou du journal (#99410) : sans
///     achat, il ouvre la vitrine au lieu d'ecrire.
///  3. LE GUIDE DES ICONES (reference l.1087-1284) : action (i) de l'en-tete,
///     cf. [showMapGuideSheet] ; et la LISTE DES POINTS DE L'ETAPE qu'on coche
///     au passage, ajoutee au panneau Calques (cf. [StagePoiChecklist]) — le
///     panneau ne savait qu'afficher et masquer des couches, ce qui est une
///     autre fonction.
///
/// SOS — ACCES UNIQUE ALIGNE GR20 (decision Chris 12/09, cycle 3) : le SOS n'a
/// qu'UN SEUL point d'entree — le bouton flottant en overlay (colonne bas-gauche,
/// [SosButton], visible en trek actif). C'est EXACTEMENT le placement GR20
/// (`SosFloatingButton` positionne dans le Stack, bas-gauche ; GR20 n'a AUCUNE
/// barre contextuelle ni SOS en barre). Le retrait de la barre rend ce point
/// definitif : il n'existe plus de barre ou un second SOS pourrait reapparaitre.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key, required this.trailId});

  /// Identifiant du sentier a afficher sur la carte.
  final String trailId;

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  @override
  Widget build(BuildContext context) {
    final trailId = widget.trailId;
    return Scaffold(
      // AUCUN bottomNavigationBar (correctif L6-3) : la carte occupe toute la
      // hauteur, comme sur la navigation de reference.
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
        // GUIDE DES ICONES (LOT D, manque reel n°2). Place en action (i) de
        // l'en-tete : c'est le geste maison pour un guide d'ecran (cf. le (i)
        // du Programme), et cela n'ajoute pas un huitieme bouton flottant sur
        // une carte de terrain.
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: t.map.title,
            onPressed: () => showMapGuideSheet(context, trailId),
          ),
        ],
      ),
      body: Consumer(
        builder: (context, ref, _) {
          final trackAsync = ref.watch(gpxTrackProvider(trailId));

          return trackAsync.when(
            loading: () => LoadingView(message: t.map.loading),
            error: (error, _) => ErrorView(
              message: t.common.cannotLoadTrack,
              onRetry: () => ref.invalidate(gpxTrackProvider(trailId)),
            ),
            data: (points) {
              if (points.isEmpty) {
                return ErrorView(
                  message: t.map.noTrack,
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
  ///
  /// LOT D (tache 554) : le panneau porte DESORMAIS AUSSI la liste des points
  /// d'eau et des hebergements DE L'ETAPE EN COURS, qu'on coche au passage
  /// ([StagePoiChecklist]). C'est la troisieme fonction manquante de la carte :
  /// le panneau de calques savait montrer et masquer des couches, il ne disait
  /// pas « voila ce que tu vas croiser aujourd'hui ». La feuille de reference
  /// fait exactement cela : elle est titree par l'etape et compte ses points.
  ///
  /// Feuille DEFILANTE et haute : la liste des points peut etre longue, et une
  /// feuille a hauteur naturelle deborderait sur les etapes bien pourvues.
  void _showLayersSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.3,
            maxChildSize: 0.9,
            expand: false,
            builder: (innerCtx, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.layers),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t.map.layersTitle,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
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
                const Divider(height: AppTheme.spacingLg),
                // Les points de l'etape en cours, coches au passage (LOT D).
                StagePoiChecklist(trailId: widget.trailId),
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
                //
                // tileProvider : en PROD, `inertTileProviderOrNull()` renvoie
                // null -> TileLayer utilise son NetworkTileProvider par defaut
                // (fond OSM en ligne, comportement inchange). En TEST
                // d'integration (flag --dart-define=STEPWAYS_INERT_TILES=true),
                // il renvoie un fournisseur INERTE (tuile transparente,
                // synchrone) qui supprime la tempete de SocketException/retries
                // offline responsable des timeouts/teardowns (cycle 3).
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moteur-gr.app',
                  tileProvider: inertTileProviderOrNull(),
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
                    // Colonne gauche : SOS (visible en trek) + Photo + Calques.
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SosButton(),
                        const SizedBox(height: 8),
                        // PHOTO VERS LE JOURNAL DU JOUR (LOT D, manque reel
                        // n°1) : present sur la carte de reference, absent de
                        // StepWays. Cote gauche avec le SOS, pour ne pas
                        // allonger la colonne des controles de carte.
                        const _MapPhotoButton(),
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

        // --- Bandeaux du haut, empiles : hors-trace (securite) puis
        // ravitaillement (correctif L6-1). Deux alertes de nature differente
        // qui peuvent coexister ; la Column garantit qu'aucune ne recouvre
        // l'autre, quelle que soit la hauteur du texte traduit.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Alerte hors-trace : banniere in-screen en tete.
              // La notification + la vibration partent du provider (meme
              // telephone en poche) ; ici on injecte les libelles traduits
              // (Slang) dans le provider et on affiche le bonus visuel.
              // RepaintBoundary : isole du raster carte.
              Consumer(
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
              // Alerte ravitaillement (correctif L6-1).
              const _SupplyAlertBanner(),
            ],
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

/// Bandeau « ravitaillement » de la carte (correctif L6-1).
///
/// CE QUI EXISTAIT DEJA, ET QUI N'EST PAS RECONSTRUIT ICI : le calcul de
/// l'ecart au prochain commerce ([TrailShops.gapAfter] / [TrailShops.isGapAlert]),
/// le catalogue du sentier ([trailShopsProvider]), les libelles traduits dans
/// les CINQ langues ([Translations] `shop.gapShort` / `shop.gapLong`) et la
/// detection de l'etape courante ([trackPositionProvider]). Ce qui manquait
/// etait le MONTAGE de l'alerte sur la carte : sa minuterie et son etat de
/// fermeture. C'est tout ce que porte ce widget.
///
/// COMPORTEMENT, aligne sur la reference terrain :
///  - rien hors trek : l'alerte parle au marcheur, pas au lecteur de carte ;
///  - rien tant que l'ecart ne depasse pas le seuil du sentier (cf.
///    [supplyGapAlertProvider]) ;
///  - la banniere s'efface SEULE au bout d'une minute, une seule minuterie
///    posee par apparition ;
///  - elle s'efface aussi a la demande (croix), et cette fermeture tient ;
///  - elle se REARME au changement d'etape : une nouvelle etape est une
///    nouvelle decision de ravitaillement, meme si la precedente avait ete
///    fermee a la main.
///
/// UN POINT OU STEPWAYS FAIT MIEUX QUE LA REFERENCE : chez GR20 le texte de ce
/// bandeau est ECRIT EN DUR dans l'ecran alors qu'une cle de traduction
/// existe. GR20 est bilingue et s'en accommode ; StepWays sert CINQ langues,
/// le texte en dur y est interdit. Le libelle vient donc de Slang, et le
/// nombre d'etapes y est injecte en parametre.
class _SupplyAlertBanner extends ConsumerStatefulWidget {
  const _SupplyAlertBanner();

  @override
  ConsumerState<_SupplyAlertBanner> createState() => _SupplyAlertBannerState();
}

class _SupplyAlertBannerState extends ConsumerState<_SupplyAlertBanner> {
  /// Duree d'affichage avant effacement automatique (parite reference).
  static const Duration _autoHideDelay = Duration(seconds: 60);

  Timer? _timer;

  /// Etape pour laquelle la minuterie courante a ete posee. Sert de memoire
  /// de rearmement : tant qu'elle ne change pas, on ne repose pas de
  /// minuterie et on ne rouvre pas une banniere fermee a la main.
  int? _armedForStage;

  /// Vrai quand la banniere est effacee (minuterie echue ou fermeture
  /// utilisateur) pour l'etape [_armedForStage].
  bool _hidden = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Remet l'alerte a zero pour [stageNumber] : une minuterie, une seule.
  void _armFor(int stageNumber) {
    _timer?.cancel();
    _armedForStage = stageNumber;
    _hidden = false;
    _timer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _hidden = true);
    });
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
    _armedForStage = null;
    _hidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive = status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    final alert = ref.watch(supplyGapAlertProvider);

    if (!trekActive || alert == null) {
      // Plus rien a signaler : on desarme, sinon une minuterie continuerait
      // de courir pour une alerte disparue et la prochaine apparition sur la
      // meme etape naitrait deja effacee.
      _disarm();
      return const SizedBox.shrink();
    }

    if (_armedForStage != alert.stageNumber) {
      // Changement d'etape (ou premiere apparition) : minuterie et fermeture
      // repartent de zero. Pas de setState — on est deja dans le build de ce
      // bandeau, le rendu de ce tour tient compte de la remise a zero.
      _armFor(alert.stageNumber);
    }
    if (_hidden) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          AppTheme.spacingSm,
          AppTheme.spacingBase,
          0,
        ),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(20),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(80)),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: AppTheme.orangeDifficile,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.shop.limitedTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Libelle TRADUIT (jamais en dur) : le nombre d'etapes
                      // sans commerce est injecte en parametre.
                      Text(
                        t.shop.gapLong(n: alert.gap),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  color: AppTheme.orangeDifficile,
                  tooltip: t.map.supplyDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _hidden = true),
                ),
              ],
            ),
          ),
        ),
      ),
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
///
/// CORRECTIF L6-2 : la barre portait QUATRE informations la ou la navigation
/// de reference en affiche SIX sur deux lignes. Les manquantes — denivele,
/// vitesse moyenne, altitude, plus le couple total/parcouru — sont ajoutees
/// ici, MESUREES sur la trace de la session ([liveTrekStatsProvider]) et non
/// deduites d'une somme nominale d'etapes. Chaque valeur indisponible est
/// MASQUEE plutot qu'affichee a zero (meme regle que le correctif L5-6 : une
/// vitesse mesuree, ou rien).
///
/// LOT D (tache 554) — CETTE BARRE NE DISPARAIT PLUS JAMAIS. Elle se rendait en
/// `SizedBox.shrink()` hors trek et sans fix GPS : c'est EXACTEMENT l'ecran nu
/// que Chris a vu (« 14 navigation ne ressemble en rien a GR20 !!!!! »). La
/// navigation de reference, elle, affiche sa barre de chiffres EN PERMANENCE et
/// met un tiret dans les cases qu'elle ne sait pas encore remplir. Hors trek, la
/// barre passe donc la main a [_PlannedStageBar] au lieu de s'effacer.
class _ActiveStageBar extends ConsumerWidget {
  const _ActiveStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive = status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    if (!trekActive) return const _PlannedStageBar();

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

        // Chiffres mesures sur la trace de la session en cours (L6-2).
        // Tant que la trace n'a pas deux points, il n'y a rien de mesurable :
        // `hasData` est faux et toutes les valeurs restent masquees.
        final mesures = ref.watch(liveTrekStatsProvider).value;
        final mesurable = mesures != null && mesures.hasData;
        final totalKm = ref.watch(
          trailConfigProvider.select((c) => c.totalDistanceKm),
        );
        // Parcouru = distance PROJETEE sur le trace, la meme source unique que
        // le HUB, l'accueil et le widget — jamais le cumul GPS brut, qui
        // gonfle sur un aller-retour.
        final parcouruKm = ref.watch(stageDistanceCoveredProvider) / 1000.0;

        return StageProgressBar(
          stageName: stageName,
          distanceRemainingKm: state.distanceRemainingKm,
          progressRatio: state.progressRatio,
          isOffTrack: state.isOffTrack,
          totalDistanceKm: totalKm > 0 ? totalKm : null,
          distanceCoveredKm: parcouruKm,
          elevationGainM: mesurable ? mesures.elevationGainM : null,
          elevationLossM: mesurable ? mesures.elevationLossM : null,
          // `averageSpeedKmh` vaut deja null quand le chiffre n'aurait aucun
          // sens (duree nulle, vitesse non marchable) : on le laisse decider.
          avgSpeedKmh: mesurable ? mesures.averageSpeedKmh : null,
          altitudeM: ref.watch(currentAltitudeProvider),
        );
      },
      // En trek mais sans projection encore disponible (le fix GPS met une
      // seconde a arriver) : barre du PROGRAMME plutot qu'ecran nu.
      orElse: () => const _PlannedStageBar(),
    );
  }
}

/// Barre d'etape AVANT le depart (LOT D, tache 554) — l'etat garni qui manquait.
///
/// CE QU'ELLE MONTRE, ET POURQUOI CHAQUE CHIFFRE EST LEGITIME :
///  * le nom et les chiffres de la PREMIERE etape du programme — distance, D+,
///    D- : ce sont des donnees du sentier, connues sans le moindre GPS ;
///  * la distance totale du sentier, qui vient de la configuration ;
///  * un TIRET sur les trois chiffres qui exigent la marche (parcouru, vitesse
///    moyenne) — jamais un zero, qui se lirait comme une mesure ;
///  * l'altitude REELLE des qu'un fix existe (le marcheur est peut-etre deja au
///    depart), un tiret sinon.
///
/// CE QU'ELLE NE PRETEND PAS : elle ne dit pas ou se trouve le marcheur. Elle
/// nomme la premiere etape parce que c'est le point de depart connu du
/// programme ; des que la projection GPS repond, l'etape DETECTEE prend le
/// relais ([_ActiveStageBar]). Il n'existe a ce jour aucune source persistee de
/// l'etape courante hors trek (la colonne `currentStage` de la table de
/// progression n'est lue par aucun provider) : la brancher serait un travail de
/// couche de donnees, hors de ce lot d'ecrans.
class _PlannedStageBar extends ConsumerWidget {
  const _PlannedStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final stages = ref.watch(
      stagesProvider(trailId).select((async) => async.value),
    );
    final stage = (stages == null || stages.isEmpty) ? null : stages.first;
    final totalKm = ref.watch(
      trailConfigProvider.select((c) => c.totalDistanceKm),
    );

    // Repli de titre : le nom du sentier. Toujours vrai, meme quand la base
    // n'a pas encore rendu les etapes.
    final String trailName = ref.watch(
      trailConfigProvider.select((c) => c.displayName),
    );
    final String stageName = stage?.name ?? trailName;

    // « Restant » avant le depart = toute l'etape (rien n'est marche). Sans
    // etape connue, on retombe sur le sentier entier.
    final remainingKm = stage?.distanceKm ?? (totalKm > 0 ? totalKm : 0.0);

    return StageProgressBar(
      stageName: stageName,
      distanceRemainingKm: remainingKm,
      progressRatio: 0,
      isOffTrack: false,
      totalDistanceKm: totalKm > 0 ? totalKm : null,
      // Rien de marche : tiret, jamais « 0.0 km ».
      distanceCoveredKm: null,
      elevationGainM: stage?.elevationGainM,
      elevationLossM: stage?.elevationLossM,
      avgSpeedKmh: null,
      altitudeM: ref.watch(currentAltitudeProvider),
      showPendingValues: true,
      footer: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icone de MARCHE et non un (i) : le (i) de l'en-tete ouvre le guide
          // de la carte, deux sens differents ne partagent pas un signe.
          Icon(
            Icons.hiking,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              // Phrase MAISON de l'etat « aucune rando en cours », deja
              // traduite dans les cinq langues (carte d'accueil du HUB) : elle
              // dit ce qui demarrera, sans inventer un texte en dur.
              t.hub.trekCard.noTrekBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bouton PHOTO de la carte -> journal du jour (LOT D, manque reel n°1).
///
/// LA REFERENCE L'A SUR SA CARTE (`_takePhoto`), STEPWAYS NE L'AVAIT NULLE PART :
/// zero occurrence de `photo_camera` dans `lib/features/trek/` et
/// `lib/features/map/`. Le marcheur devait quitter la navigation, ouvrir le
/// journal, creer une note, choisir la galerie… pour garder une image du col.
///
/// DEUX REGLES MAISON RESPECTEES, ET ELLES COMPTENT :
///  1. LE VERROU DU JOURNAL TIENT (decision Chris du 02/09, memoire #99410) :
///     le journal fait partie du pack. Sans achat, ce bouton n'ecrit RIEN — il
///     ouvre la vitrine ([showPaywallSheet]). On ne remplit pas un carnet
///     verrouille, et on ne masque pas la fonction pour autant : le marcheur
///     voit ce qu'il gagne en achetant.
///  2. L'ERREUR EST DITE, jamais avalee : quota du jour atteint, photo trop
///     lourde, disque en echec -> message traduit ([PhotoError]), la meme
///     table de libelles que le journal.
class _MapPhotoButton extends ConsumerStatefulWidget {
  const _MapPhotoButton();

  @override
  ConsumerState<_MapPhotoButton> createState() => _MapPhotoButtonState();
}

class _MapPhotoButtonState extends ConsumerState<_MapPhotoButton> {
  /// Vrai pendant la prise et l'enregistrement : le bouton ne se redeclenche
  /// pas (un double tap en marchant est la norme, pas l'exception).
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    // Le droit d'acces est OBSERVE ici, pas seulement lu au moment du tap : un
    // `ref.read` sur un provider jamais observe declenche son chargement et
    // rend `AsyncLoading` -> un payeur se serait vu proposer la vitrine au
    // premier appui. En l'observant, il est resolu avant que le doigt arrive.
    ref.watch(isDemoModeProvider(trailId));
    return FloatingActionButton.small(
      heroTag: 'mapTakePhoto',
      tooltip: t.journal.addPhoto,
      onPressed: _busy ? null : () => _onPressed(trailId),
      child: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.photo_camera),
    );
  }

  Future<void> _onPressed(String trailId) async {
    // Acces au journal = SOURCE UNIQUE [isDemoModeProvider] (correctif L7-3).
    // FAIL-CLOSED : tant que le droit est indetermine ou en erreur, on n'ecrit
    // pas — on propose l'achat, exactement comme l'ecran du journal.
    final acces = ref.read(isDemoModeProvider(trailId));
    final verrouille = acces.value ?? true;
    if (verrouille) {
      final totalStages = ref.read(
        trailConfigProvider.select((c) => c.totalStages),
      );
      if (!mounted) return;
      await showPaywallSheet(
        context,
        trailId: trailId,
        totalStages: totalStages,
      );
      return;
    }

    // Capture AVANT tout await : la feuille systeme de l'appareil photo peut
    // demonter ce contexte, il ne doit pas servir a afficher le message.
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.camera,
        // Memes bornes que le dialogue du journal : la compression finale
        // reste l'affaire de PhotoService (500 Ko max).
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return;

      final error = await ref
          .read(journalScreenProvider.notifier)
          .addPhotoNote(
            stageNumber: _currentStageNumber(),
            content: '',
            sourcePath: picked.path,
          );

      if (error != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(_photoErrorLabel(error))),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, size: 18),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(child: Text(t.journal.entriesOfDay)),
            ],
          ),
          action: SnackBarAction(
            label: t.nav.journal,
            // Resolution du routeur DIFFEREE au tap : la carte est alors
            // encore montee (le message s'efface avec elle), et un harnais de
            // test sans routeur ne paye pas ce branchement.
            onPressed: () {
              if (mounted) context.push('/journal');
            },
          ),
        ),
      );
    } catch (_) {
      // Appareil photo indisponible / permission refusee : on le DIT.
      messenger.showSnackBar(SnackBar(content: Text(t.journal.photoError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Etape a laquelle rattacher la photo : l'etape DETECTEE si la projection
  /// repond, sinon la premiere du programme (plancher a 1 — une entree de
  /// journal doit porter un numero d'etape valide).
  int _currentStageNumber() {
    final detected = ref
        .read(trackPositionProvider)
        .whenOrNull(data: (s) => s.stageDetection.stageNumber);
    if (detected != null && detected > 0) return detected;
    return 1;
  }

  /// Libelle Slang d'un echec d'ajout de photo (meme table que le journal).
  String _photoErrorLabel(PhotoError error) {
    switch (error) {
      case PhotoError.dailyLimitReached:
        return t.journal.photoLimit;
      case PhotoError.tooLarge:
        return t.journal.photoTooBig;
      case PhotoError.fileNotFound:
      case PhotoError.ioError:
        return t.journal.photoError;
    }
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
      // L3-1 : l'etape detectee est notee au gestionnaire de session, qui
      // l'inscrit sur chaque point de trace — c'est ce qui permet de rendre
      // le trace ETAPE PAR ETAPE dans le recap.
      final stageId = ref.watch(currentStageIdProvider).value;
      ref.read(trekSessionManagerProvider.notifier).noteCurrentStage(stageId);
    }

    return const SizedBox.shrink();
  }
}
