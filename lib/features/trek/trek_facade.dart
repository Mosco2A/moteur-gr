/// FACADE PUBLIQUE DE LA FEATURE `trek` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour `trek` :
/// tout ce qu il re-exporte est public, et tout le reste de `trek` —
/// `providers/`, `data/`, `domain/`, `presentation/` — est prive, meme si rien
/// dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `trek`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/trek/providers/...` soude les deux features : on ne touche plus a
/// l une sans ouvrir l autre, et le detail d implementation de `trek` devient l
/// interface sur laquelle les autres reposent. La facade rend ce cout visible —
/// elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 25 FICHIERS DE 10 FEATURES AU 06/10/2026 : `after`,
/// `feasibility`, `hub`, `map`, `planning`, `safety`, `settings`, `tracking`,
/// `treks`, `weather`. Les trois venus du lot 671-00 lisent
/// `positionControllerProvider`, le robinet unique GPS ; le dernier venu (lot
/// 671-01), l'ecran cache de mesure batterie de `settings`, lit
/// `measureBenchProvider` et `kLowBatteryThreshold`.
///
/// LOT 671-02, LE SOCLE PODOMETRE : `hub` lit `ensureStepCountingExplained`
/// (l'explication du podometre au demarrage d'un trek), `settings` lit
/// `PodometerSettingsTile` (la ligne des reglages) et `StrideCalibration`
/// (la longueur de pas que montre l'ecran cache de mesure).
///
/// LOT 671-03, LE RECALAGE SUR LE TRACE : `map` lit `BgTrackPoint` et
/// `estimatedTrackPointsProvider`, les points estimes que l'isolate de fond
/// fait avancer le long du trace, pour en tenir la position courante.
///
/// LOT 671-04, LES REVEILS FINS : `safety` lit `positionsConnuesProvider` et
/// `PositionConnue` — la derniere position connue (releve ou estime) sans
/// aucun flux chaud, et le tir unique qui la remplace — pour le bouton SOS,
/// qui ne garde plus `positionStreamProvider` en ecoute (l'ecran d'urgence,
/// ouvert volontairement, garde le sien).
library;

export 'data/background_gps_service.dart'
    show BgTrackPoint, estimatedTrackPointsProvider, kLowBatteryThreshold;
export 'data/gps_service.dart'
    show
        GpsPermissionResultValues,
        GpsService,
        gpsServiceProvider,
        positionControllerProvider;
export 'data/position_connue.dart'
    show PositionConnue, positionsConnuesProvider;
// TACHE 742, LA DEMO QUI MARCHE : `journal` lit `sourceDesRelevesProvider` —
// d'ou viennent les releves de marche : la base en vrai, et la memoire du
// marcheur simule en demo. ON ELARGIT DONC LE CONTRAT DE `trek`, et c'est une
// decision : le journal du jour mesurait ses chiffres sur
// `session_track_points`, une table que la demo laisse vide par construction
// (tache 634). Sans cette porte il
// aurait fallu soit un `if (enDemo)` recopie dans le journal, soit un second
// calcul de journee — exactement les deux choses que le lot 671-06 avait
// supprimees. La facade rend le cout visible : une ligne, et un seul symbole.
export 'data/source_des_releves.dart'
    show
        SourceDesReleves,
        cadenceDesRelevesSimulesProvider,
        sourceDesRelevesProvider;
export 'data/track_simplifier.dart' show DouglasPeucker;
export 'domain/longueur_de_pas.dart' show StrideCalibration;
export 'presentation/map/marker_cluster.dart' show dynamicEpsilonForZoom;
export 'presentation/podometre_autorisation.dart'
    show PodometerSettingsTile, ensureStepCountingExplained;
export 'providers/gps_providers.dart'
    show
        currentStageIdProvider,
        currentTrekPlanProvider,
        domainStagesProvider,
        positionStreamProvider,
        selectedDirectionProvider;
export 'providers/measure_bench_provider.dart'
    show MeasureBench, measureBenchProvider;
export 'providers/session_recovery_provider.dart' show pendingSessionProvider;
export 'providers/stage_providers.dart' show stagesProvider;
export 'providers/tracking_providers.dart'
    show
        ActiveTrekConflictChoice,
        StartOutcome,
        TrackingSessionState,
        TrackingSessionStatus,
        trekSessionManagerProvider;
