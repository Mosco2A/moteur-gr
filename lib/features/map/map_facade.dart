/// FACADE PUBLIQUE DE LA FEATURE `map` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour `map` :
/// tout ce qu il re-exporte est public, et tout le reste de `map` —
/// `providers/`, `data/`, `domain/`, `presentation/` — est prive, meme si rien
/// dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `map`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/map/providers/...` soude les deux features : on ne touche plus a l
/// une sans ouvrir l autre, et le detail d implementation de `map` devient l
/// interface sur laquelle les autres reposent. La facade rend ce cout visible —
/// elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 9 FICHIERS DE 6 FEATURES AU 03/10/2026 : `community`, `feasibility`,
/// `hub`, `safety`, `settings`, `trek`.
library;

export 'providers/gpx_track_provider.dart' show gpxTrackProvider;
export 'providers/location_provider.dart' show locationProvider;
export 'providers/map_pois_provider.dart' show mapPoisProvider;
export 'providers/off_track_provider.dart'
    show OffTrackMessages, offTrackMessagesProvider;
export 'providers/simplified_track_provider.dart' show simplifiedTrackProvider;
export 'providers/stage_poi_check_provider.dart' show stagePoiChecksProvider;
export 'providers/supply_alert_provider.dart' show supplyGapAlertProvider;
export 'providers/track_position_provider.dart'
    show stageDistanceCoveredProvider, trackPositionProvider;
