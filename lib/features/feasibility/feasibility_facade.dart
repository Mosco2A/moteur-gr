/// FACADE PUBLIQUE DE LA FEATURE `feasibility` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour
/// `feasibility` : tout ce qu il re-exporte est public, et tout le reste de
/// `feasibility` — `providers/`, `data/`, `domain/`, `presentation/` — est
/// prive, meme si rien dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `feasibility`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/feasibility/providers/...` soude les deux features : on ne touche
/// plus a l une sans ouvrir l autre, et le detail d implementation de
/// `feasibility` devient l interface sur laquelle les autres reposent. La
/// facade rend ce cout visible — elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 7 FICHIERS DE 5 FEATURES AU 05/10/2026 : `checklist`, `consent`,
/// `planning`, `settings`, `training`.
library;

export 'data/hiker_profile_repository.dart' show hikerProfileRepositoryProvider;
export 'providers/advised_program_provider.dart' show advisedTotalDaysProvider;
export 'providers/hiker_profile_provider.dart' show hikerProfileProvider;
export 'providers/trek_feasibility_provider.dart'
    show feasibilityAssessmentProvider;
