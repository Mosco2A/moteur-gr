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
import '../../../../core/map/fond_de_carte.dart';
import '../../../../core/models/poi.dart';
import '../../../../shared/widgets/attribution_osm.dart';
import '../../../map/map_facade.dart'
    show
        currentPositionProvider,
        jalonALAbscisse,
        jalonsDesEtapesProvider,
        mapFocusStage,
        mapPoisProvider,
        perimetreDeLaBarreProvider,
        simplifiedTrackProvider,
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
import 'recalage_mount.dart';
import 'felicitations_de_la_demo.dart';

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

  /// LE NUMERO DE L'ETAPE DEJA CADREE, `null` avant le premier cadrage.
  ///
  /// C'ETAIT UN SIMPLE DRAPEAU « deja cadre », ET C'EST CE QUI RAMENAIT LA
  /// CARTE AU DEPART (tache 747). Retour de Christophe du 09/10 09:00, mot pour
  /// mot : « il faut rester sur la fin pas revenir au debut dans l'affichage de
  /// la carte ».
  ///
  /// CE QUI SE PASSAIT, MESURE. Le cadrage lisait
  /// [currentStageNumberProvider], c'est-a-dire la colonne `currentStage` de la
  /// base — et le balayage du 09/10 a montre que `ProgressDao.updateCurrentStage`
  /// n'a AUCUN appelant dans l'application : cette colonne vaut donc toujours 1,
  /// et en demo il n'y a meme pas de ligne de progression. Le cadrage tombait
  /// donc TOUJOURS sur l'etape 1, une seule fois, et plus jamais : la carte
  /// restait sur le DEPART du sentier pendant toute la marche, et l'arrivee
  /// n'etait nulle part a l'ecran.
  ///
  /// CE QUI REMPLACE : on cadre sur l'etape SOUS LES PIEDS du marcheur, et on
  /// recadre QUAND ELLE CHANGE — pas a chaque releve. Deux fois par seconde, un
  /// recadrage arracherait la carte des mains du randonneur ; une fois par
  /// etape, c'est le geste qu'il attend. A l'arrivee, l'etape sous ses pieds est
  /// la DERNIERE : la carte reste donc sur la fin, sans traitement special.
  int? _etapeCadree;

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

    // TOUCHER L'ECRAN REMET LE COMPTE DES VINGT SECONDES A ZERO (tache 747).
    //
    // Decision de Christophe du 09/10 08:57 : la vue « sentier entier » revient
    // seule a l'etape au bout de vingt secondes, « et le temporisateur se remet
    // a zero si on touche l'ecran pendant les vingt secondes ». Vingt secondes
    // c'est long quand on lit, et court quand on deplace la carte pour situer
    // la suite du sentier : la vue ne doit pas se derober sous les doigts de
    // quelqu'un qui est en train de s'en servir.
    //
    // UN [Listener] ET NON UN [GestureDetector] : il OBSERVE les evenements de
    // pointeur sans en consommer aucun. La carte garde donc tous ses gestes —
    // deplacement, pincement, double-appui — exactement comme avant. Et
    // `translucent` le laisse voir les touchers qui atterrissent sur la carte
    // en dessous, ce qu'un comportement opaque intercepterait.
    //
    // LE [Consumer] NE SE RECONSTRUIT JAMAIS DE LUI-MEME : `ref.read` ne
    // s'abonne a rien. Il n'est la que pour tenir un `ref` — cet ecran est un
    // [StatefulWidget] et non un [ConsumerStatefulWidget], et le convertir
    // toucherait tous ses `Consumer` internes pour aucun gain.
    return Consumer(
      builder: (context, ref, _) => Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) =>
            ref.read(perimetreDeLaBarreProvider.notifier).toucheEcran(),
        child: _pile(bounds),
      ),
    );
  }

  Widget _pile(LatLngBounds bounds) {
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
            // L'ETAPE A CADRER SUIT LE MARCHEUR (747). L'abscisse sur la trace
            // dit sur quelle etape il se trouve ; sans position — avant le
            // depart — on retombe sur l'etape de la base, puis sur la premiere.
            final abscisseM = ref
                .watch(trackPositionProvider)
                .value
                ?.distanceFromStartM;
            final jalons = ref.watch(jalonsDesEtapesProvider(widget.trailId));
            final sousLesPieds = abscisseM == null
                ? null
                : jalonALAbscisse(jalons, abscisseM)?.numero;
            final focusStage = mapFocusStage(
              stages,
              sousLesPieds ??
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
            // le rejoue hors phase de build — et on le rejoue A CHAQUE
            // CHANGEMENT D'ETAPE, jamais entre deux.
            if (focusBounds != null &&
                _etapeCadree != focusStage!.stageNumber) {
              _etapeCadree = focusStage.stageNumber;
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
                // 1. Fond de carte : le fichier telecharge du sentier s'il
                //    est lisible, le reseau sinon (lot carte hors ligne).
                FondDeCarte(trailId: widget.trailId),

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

                // 4. Position courante (lot 671-03) : releve, ou estime
                Consumer(
                  builder: (context, ref, _) {
                    final positionAsync = ref.watch(
                      currentPositionProvider.select((async) => async.value),
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
        const Positioned(top: 0, left: 0, right: 0, child: MapTopBanners()),

        // --- Pipeline detection d'etape -> arrivee -> finisher (PARITE GR20,
        // LOT 2, #99433). L'ecran carte est l'ECRAN TERRAIN ACTIF de StepWays :
        // on y monte le pont d'arrivee pour qu'il soit VIVANT pendant un trek.
        // GR20 fait pareil dans active_stage_screen. Rendu invisible.
        const ArrivalPipelineMount(),
        // Lots 671-02 et 671-03 : pas calibre, recalage sur le trace.
        const StrideCalibrationMount(),
        const TrackRecalibrationMount(),

        // --- L'ARRIVEE DE LA DEMONSTRATION EST UN MOMENT (tache 747, retour
        // de Christophe du 09/10 08:59 : « A la fin il manque les
        // felicitations »). EN DERNIER dans la pile, donc au-dessus de tout :
        // c'est l'ecran de fin, il ne doit pas passer sous la barre de
        // chiffres. Invisible hors demo et avant l'arrivee.
        const FelicitationsDeLaDemo(),
      ],
    );
  }
}
