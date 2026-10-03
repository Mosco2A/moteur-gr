/// FACADE PUBLIQUE DE LA FEATURE `share` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour `share` :
/// tout ce qu il re-exporte est public, et tout le reste de `share` —
/// `providers/`, `data/`, `domain/`, `presentation/` — est prive, meme si rien
/// dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `share`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/share/providers/...` soude les deux features : on ne touche plus a
/// l une sans ouvrir l autre, et le detail d implementation de `share` devient
/// l interface sur laquelle les autres reposent. La facade rend ce cout visible —
/// elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 2 FICHIERS DE 1 FEATURE AU 03/10/2026 : `settings`.
library;

export 'providers/visibility_settings_provider.dart'
    show visibilitySettingsProvider;
