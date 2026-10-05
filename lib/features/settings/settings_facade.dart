/// FACADE PUBLIQUE DE LA FEATURE `settings` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour
/// `settings` : tout ce qu il re-exporte est public, et tout le reste de
/// `settings` — `providers/`, `data/`, `domain/`, `presentation/` — est prive,
/// meme si rien dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `settings`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/settings/providers/...` soude les deux features : on ne touche
/// plus a l une sans ouvrir l autre, et le detail d implementation de
/// `settings` devient l interface sur laquelle les autres reposent. La facade
/// rend ce cout visible — elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 9 FICHIERS DE 4 FEATURES AU 05/10/2026 : `auth`, `onboarding`,
/// `weather` (5 fichiers) et `hub` (2). LES SEPT DERNIERS SONT ARRIVES AVEC LE
/// LOT PRODUIT P1 (#101255) : le reglage Celsius / Fahrenheit existait et aucun
/// ecran ne le lisait. Ces sept-la lisent `settingsProvider` — rien d'autre — et
/// mettent en forme la temperature par `lib/domain/temperature_unit.dart`, qui
/// n'appartient a aucune feature.
library;

export 'providers/settings_provider.dart'
    show DominantHand, DominantHandValues, settingsProvider;
