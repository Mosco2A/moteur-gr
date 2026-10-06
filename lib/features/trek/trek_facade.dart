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
library;

export 'data/background_gps_service.dart' show kLowBatteryThreshold;
export 'data/gps_service.dart'
    show
        GpsPermissionResultValues,
        GpsService,
        gpsServiceProvider,
        positionControllerProvider;
export 'data/track_simplifier.dart' show DouglasPeucker;
export 'presentation/map/marker_cluster.dart' show dynamicEpsilonForZoom;
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
