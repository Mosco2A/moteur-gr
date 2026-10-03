/// Le contenu de la carte : la FlutterMap, ses couches et ses
/// surcouches.
///
/// Morceau de `map_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'map_screen.dart';

/// Contenu carte interne -- separe pour isoler les rebuilds.
///
/// Recoit les points bruts en parametre (deja charges).
/// Utilise Consumer + select() pour chaque layer independant.
/// Stack : FlutterMap (TileLayer + TraceLayer + TrailMarkersLayer
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
                      const StepIcon(StepwaysIcons.calques),
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
                //
                // GRISES EN DEMO (tache 638, bug 14) : cocher un point de
                // passage ecrit la progression du sentier REEL en base. C'etait
                // la 8e des ecritures laissees ouvertes par le lot 634. La liste
                // reste LISIBLE — la demo doit montrer ce que l'ecran fait — mais
                // les coches sont visiblement indisponibles.
                GriseEnDemo(child: StagePoiChecklist(trailId: widget.trailId)),
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
                        onPoiTap: (poi) => _showPoiDetails(context, poi),
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
          child: _MapBottomBar(
            bounds: bounds,
            onShowLayers: () => _showLayersSheet(context),
          ),
        ),

        // --- Bandeaux du haut, empiles : hors-trace (securite) puis
        // ravitaillement (correctif L6-1). Deux alertes de nature differente
        // qui peuvent coexister ; la Column garantit qu'aucune ne recouvre
        // l'autre, quelle que soit la hauteur du texte traduit.
        Positioned(top: 0, left: 0, right: 0, child: _MapTopBanners()),

        // --- Pipeline detection d'etape -> arrivee -> finisher (PARITE GR20,
        // LOT 2, #99433). L'ecran carte est l'ECRAN TERRAIN ACTIF de StepWays :
        // on y monte le pont d'arrivee pour qu'il soit VIVANT pendant un trek.
        // GR20 fait pareil dans active_stage_screen. Rendu invisible.
        const _ArrivalPipelineMount(),
      ],
    );
  }
}
