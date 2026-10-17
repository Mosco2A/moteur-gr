/// FACADE PUBLIQUE DE LA FEATURE `training` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour
/// `training` : tout ce qu il re-exporte est public, et tout le reste de
/// `training` — `providers/`, `data/`, `domain/`, `presentation/` — est prive,
/// meme si rien dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `training`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/training/providers/...` soude les deux features : on ne touche
/// plus a l une sans ouvrir l autre, et le detail d implementation de
/// `training` devient l interface sur laquelle les autres reposent. La facade
/// rend ce cout visible — elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 2 FICHIERS DE 2 FEATURES AU 07/10/2026 : `hub`, `settings`.
library;

/// `trainingPlanForTrailProvider` A ETE AJOUTE AU CONTRAT (tache 851), et la
/// decision est volontaire au sens de l'avertissement ci-dessus : `hub` avait
/// besoin du plan D'UN SENTIER DESIGNE, pas du plan du sentier ACTIF que
/// `trainingPlanProvider` rend. Il lisait donc le second faute d'avoir le
/// premier — et sa coche « preparation physique », qui vit par sentier,
/// s'invalidait a chaque bascule en pleine phase de build (memoire #101735).
/// Elargir la porte etait le prix a payer pour que chaque coche n'ecoute QUE
/// ses propres sources, ce que sa documentation promettait deja.
export 'providers/training_plan_providers.dart'
    show
        trainingPlanProvider,
        trainingPlanForTrailProvider,
        trainingProgressProvider;
