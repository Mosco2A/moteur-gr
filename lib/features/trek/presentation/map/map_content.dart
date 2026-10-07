/// Le contenu de la carte : la FlutterMap, ses couches et ses
/// surcouches.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/geo/trace_point.dart';
import '../../../../core/map/test_inert_tile_provider.dart';
import '../../../../core/models/poi.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/attribution_osm.dart';
import '../../../map/map_facade.dart'
    show
        StageProgressBar,
        locationProvider,
        mapFocusStage,
        mapPoisProvider,
        simplifiedTrackProvider,
        stageDistanceCoveredProvider,
        stageTrackSegment,
        trackPositionProvider;
import '../../../trail/trail_facade.dart'
    show currentStageNumberProvider, stagesProvider;
import '../../../../domain/stage.dart';
import 'layers/trace_layer.dart';
import 'layers/trail_markers_layer.dart';
import 'layers/user_position_layer.dart';
import 'marker_overlap.dart';
import 'map_controller.dart';
import 'map_overlays.dart';
import 'map_arrival_pipeline.dart';
import 'map_sheets.dart';
import '../../providers/live_trek_stats_provider.dart';
import '../../providers/tracking_providers.dart';

/// Contenu carte interne -- separe pour isoler les rebuilds.
///
/// Recoit les points bruts en parametre (deja charges).
/// Utilise Consumer + select() pour chaque layer independant.
/// Stack : FlutterMap (TileLayer + TraceLayer + TrailMarkersLayer
/// + UserPositionLayer) en fond, overlays (barre d'etape, controles, SOS,
/// calques, banniere hors-trace) par-dessus.
///
/// Structure : Scaffold > Stack > FlutterMap(TileLayer, TraceLayer,
/// TrailMarkersLayer, UserPositionLayer) + overlays (barre d'etape, controles,
/// SOS, calques, banniere hors-trace). Les etapes et les points d'interet
/// partagent UNE couche depuis la tache 571 : deux couches empilees ne peuvent
/// pas s'entendre sur un repere commun quand elles designent le meme lieu.
class MapContent extends StatefulWidget {
  const MapContent({super.key, required this.trailId, required this.rawPoints});

  final String trailId;
  final List<TrackPoint> rawPoints;

  @override
  State<MapContent> createState() => _MapContentState();
}

class _MapContentState extends State<MapContent> {
  int _currentZoom = 10;

  /// Vrai une fois la carte cadree sur l'etape (tache 558).
  ///
  /// UNE SEULE FOIS, et c'est le point important : les etapes arrivent en
  /// asynchrone, donc le cadrage peut devoir attendre un tour. Passe ce
  /// premier cadrage, la carte appartient au randonneur — un recadrage
  /// automatique lui arracherait la carte des mains pendant qu'il la deplace.
  bool _stageFramed = false;

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

    return LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng));
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
              ref.watch(trailConfigProvider.select((c) => c.primaryColorValue)),
            );

            final displayPoints = simplifiedAsync.value ?? widget.rawPoints;

            // Convertir TrackPoint -> LatLng pour TraceLayer
            final latLngPoints = displayPoints
                .map((tp) => LatLng(tp.lat, tp.lng))
                .toList(growable: false);

            // --- CADRAGE D'OUVERTURE (tache 558) ---
            //
            // Chris, mot pour mot : « Je veux etre a la premiere etape et voir
            // le sentier !!! ». La carte s'ouvrait sur le sentier ENTIER : a
            // cette echelle le trace tient dans un fil de quelques pixels et on
            // n'est nulle part. Elle s'ouvre desormais sur l'etape COURANTE
            // quand la base en connait une (`currentStage`, enfin lue), sur la
            // PREMIERE sinon — et sur son TRONCON DE TRACE, donc le sentier est
            // visible, pas devine.
            //
            // REPLI EXPLICITE : sans etape chargee ou sans troncon exploitable,
            // on garde le cadrage sur le sentier entier. Jamais de cadrage sur
            // une donnee absente.
            final stages = ref.watch(
              stagesProvider(widget.trailId).select((async) => async.value),
            );
            final focusStage = mapFocusStage(
              stages,
              ref.watch(currentStageNumberProvider(widget.trailId)),
            );
            final segment = focusStage == null
                ? const <TrackPoint>[]
                : stageTrackSegment(widget.rawPoints, focusStage);
            final focusBounds = segment.isEmpty
                ? null
                : _boundsFromPoints(segment);

            // Les etapes arrivent apres le trace : si le cadrage d'etape n'est
            // connu qu'au deuxieme build, `initialCameraFit` est deja passe. On
            // le rejoue UNE fois, hors phase de build.
            if (focusBounds != null && !_stageFramed) {
              _stageFramed = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: focusBounds,
                    padding: const EdgeInsets.all(48),
                  ),
                );
              });
            }

            return FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCameraFit: CameraFit.bounds(
                  bounds: focusBounds ?? bounds,
                  padding: EdgeInsets.all(focusBounds == null ? 32 : 48),
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
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.moteur-gr.app',
                  tileProvider: inertTileProviderOrNull(),
                ),

                // 2. Trace GPX (statique -> RepaintBoundary pour isoler
                //    le raster du trace des rebuilds de la position GPS)
                RepaintBoundary(
                  child: TraceLayer(points: latLngPoints, color: trailColor),
                ),

                // 3. LES REPERES DU SENTIER — ETAPES ET POINTS D'INTERET DANS
                //    UNE COUCHE UNIQUE (tache 571).
                //
                //    Retour de Chris, mot pour mot : « 14rando les numeros
                //    d'etapes son caches par les refucge, il ne faut pas que
                //    les icones se superposent ».
                //
                //    IL Y AVAIT ICI DEUX COUCHES : les numeros d'etape, puis
                //    les points d'interet peints PAR-DESSUS. Une etape se
                //    termine a un hebergement et la suivante en repart : les
                //    deux marqueurs tombent au MEME point par construction, et
                //    l'icone de couchage avalait le numero d'etape — soit
                //    l'information de reperage la plus utile de la carte.
                //
                //    Deux couches empilees ne peuvent pas s'entendre sur un
                //    repere commun : chacune ignore ce que l'autre dessine.
                //    D'ou UNE couche, qui voit les deux familles de reperes,
                //    regroupe geometriquement celles qui designent le meme
                //    lieu au zoom courant, et pose un repere qui porte les
                //    deux informations. Aucun decalage : on fusionne ou on
                //    separe, on ne deplace jamais un point sur une carte.
                //
                //    RepaintBoundary conserve : la couche reste statique
                //    vis-a-vis de la position GPS.
                Consumer(
                  builder: (context, ref, _) {
                    final stagesAsync = ref.watch(
                      stagesProvider(
                        widget.trailId,
                      ).select((async) => async.value),
                    );
                    final stages = stagesAsync ?? const [];
                    final poisAsync = ref.watch(
                      mapPoisProvider(
                        widget.trailId,
                      ).select((async) => async.value),
                    );
                    final pois = poisAsync ?? const <PoiModel>[];

                    if (stages.isEmpty && pois.isEmpty) {
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
                      child: TrailMarkersLayer(
                        stages: domainStages,
                        pois: pois,
                        // La carte ne notifie son zoom qu'ARRONDI : on evalue
                        // le recouvrement au plus petit zoom de la bande, donc
                        // du cote prudent (cf. lowestZoomOfBand).
                        zoom: MarkerOverlap.lowestZoomOfBand(_currentZoom),
                        onPoiTap: (poi) => showMapPoiDetails(context, poi),
                      ),
                    );
                  },
                ),

                // 4. Position utilisateur
                Consumer(
                  builder: (context, ref, _) {
                    final positionAsync = ref.watch(
                      locationProvider.select((async) => async.value),
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

                // 5. L ATTRIBUTION OPENSTREETMAP — OBLIGATION ODbL, PAS UNE
                //    POLITESSE (integration 647). Le fond vient d OSM, en ligne
                //    comme hors ligne (les tuiles embarquees du lot 648 sont
                //    rendues depuis des donnees OSM) : la carte doit le dire.
                const AttributionOsm(),
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
          child: MapBottomBar(
            bounds: bounds,
            onShowLayers: () => showMapLayersSheet(context, widget.trailId),
          ),
        ),

        // --- Bandeaux du haut, empiles : hors-trace (securite) puis
        // ravitaillement (correctif L6-1). Deux alertes de nature differente
        // qui peuvent coexister ; la Column garantit qu'aucune ne recouvre
        // l'autre, quelle que soit la hauteur du texte traduit.
        Positioned(top: 0, left: 0, right: 0, child: MapTopBanners()),

        // --- Pipeline detection d'etape -> arrivee -> finisher (PARITE GR20,
        // LOT 2, #99433). L'ecran carte est l'ECRAN TERRAIN ACTIF de StepWays :
        // on y monte le pont d'arrivee pour qu'il soit VIVANT pendant un trek.
        // GR20 fait pareil dans active_stage_screen. Rendu invisible.
        const ArrivalPipelineMount(),
        // Lot 671-02 : la longueur de pas se calibre en marchant. Invisible.
        const StrideCalibrationMount(),
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
class ActiveStageBar extends ConsumerWidget {
  const ActiveStageBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
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
        final stageName =
            stage?.name ??
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
/// nomme l'etape COURANTE quand la base en connait une (tache 558 : la colonne
/// `currentStage`, ecrite depuis toujours par le suivi de trek, est enfin LUE —
/// cf. [currentStageNumberProvider]), et la PREMIERE sinon, parce que c'est le
/// point de depart connu du programme. Des que la projection GPS repond,
/// l'etape DETECTEE prend le relais ([ActiveStageBar]).
class _PlannedStageBar extends ConsumerWidget {
  const _PlannedStageBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final stages = ref.watch(
      stagesProvider(trailId).select((async) => async.value),
    );
    // ETAPE COURANTE SI LA BASE EN CONNAIT UNE, PREMIERE ETAPE SINON.
    final currentNumber = ref.watch(currentStageNumberProvider(trailId));
    final stage = mapFocusStage(stages, currentNumber);
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
      // LE LAIUS SUR LES TIRETS EST SUPPRIME (tache 558). Retour de Chris, mot
      // pour mot : « enleve dans randonnee le laius sur les tiret ». La phrase
      // `map.statsPendingNote` expliquait pourquoi certaines cases portent un
      // tiret — elle part AVEC SA CLE dans les cinq langues. Un tiret se
      // comprend seul, et la navigation de reference n'explique pas les siens.
      // L'acquis du lot 554 reste entier : les six cases sont toujours la, avec
      // un tiret et jamais un zero sur ce qui exige la marche.
    );
  }
}
