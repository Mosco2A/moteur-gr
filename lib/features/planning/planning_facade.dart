/// FACADE PUBLIQUE DE LA FEATURE `planning` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour
/// `planning` : tout ce qu il re-exporte est public, et tout le reste de
/// `planning` — `providers/`, `data/`, `domain/`, `presentation/` — est prive,
/// meme si rien dans le langage ne l empeche techniquement. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`, ET C EST LA TOUT SON INTERET. Une
/// facade est une REDIRECTION D IMPORT : aucun symbole n est declare ici, aucun
/// n est renomme, aucun code n a bouge. Le `show` de chaque ligne porte la
/// liste EXACTE des symboles qu une autre feature utilise reellement — releves
/// un par un, pas un `export` aveugle. Ajouter un nom a un `show`, c est donc
/// une decision : on elargit le contrat de `planning`.
///
/// CE QUE CETTE PORTE COUTE SI ON LA CONTOURNE. Un import direct vers
/// `features/planning/providers/...` soude les deux features : on ne touche
/// plus a l une sans ouvrir l autre, et le detail d implementation de
/// `planning` devient l interface sur laquelle les autres reposent. La facade
/// rend ce cout visible — elle ne l interdit pas, elle le NOMME.
///
/// LUE PAR 11 FICHIERS DE 7 FEATURES AU 07/10/2026 : `booking`, `feasibility`,
/// `hub`, `map`, `settings`, `trek`, `weather`.
library;

// LE DECOUPAGE SUR LES NUITS RELEVEES SORT PAR LA PORTE (tache 848). La FICHE
// du sentier doit annoncer la difficulte de l'allure CONSEILLEE, et le verdict
// est celui de la pire journee : il depend donc du decoupage. Or le decoupage
// qui pose les journees sur les trente et une nuits RELEVEES (tache 838) est
// plus fin que le regroupement des seize etapes de la federation, et ca se
// MESURE — sur douze jours, la pire journee du GR20 tombe de 1 824 m a 1 455 m.
// La fiche lit donc CE decoupage-la, et par cette porte : le plafond des
// croisements entre features est a ZERO
// (`test/structurel/couches_respectees_645_test.dart`).
export 'domain/decoupage_sur_les_nuits.dart'
    show DecoupageSurLesNuits, JourneeSurLesNuits;
// LE POSEUR DE JOURNEES SORT PAR LA PORTE (tache 855). La FICHE du sentier et
// le PROGRAMME du client doivent poser les MEMES journees : jusqu'ici la fiche
// coupait les etapes sur les nuits relevees et le programme ne coupait jamais,
// et a seize jours les deux annonçaient 26,48 et 36,45 km-effort pour la meme
// pire journee. `JourneesDuSentier` est desormais le SEUL endroit qui en
// decide ; la fiche le lit par cette porte.
export 'domain/journees_du_sentier.dart' show JourneePosee, JourneesDuSentier;
export 'domain/planning_calculator.dart' show PlanningCalculator;
export 'models/day_plan.dart' show DayPlan;
export 'providers/nuits_possibles_provider.dart'
    show decoupageDuSentierProvider;
export 'providers/planned_days_provider.dart'
    show manualRestDayCacheProvider, plannedDaysProvider;
export 'providers/planning_provider.dart'
    show
        defaultDurationWithRestProvider,
        durationBoundsProvider,
        planningProvider,
        recommendedRestDaysProvider,
        retainedDurationProvider,
        selectedDurationProvider;
export 'providers/shop_providers.dart' show trailShopsProvider;
// LE VERROU DE RANDO SORT PAR LA PORTE (tache 838, D1). La decision
// publicitaire a besoin du predicat « une rando est en cours » pour tenir la
// regle de Christophe « IL N Y A PAS DE PUB POSSIBLE EN MODE RANDO !!! ». Elle
// lit celui qui existe plutot que d'en ecrire un second — et elle le lit par
// cette facade, parce que le plafond des croisements entre features est a ZERO
// (`couches_respectees_645_test.dart`) et qu'un import visant
// `providers/trek_edit_lock_provider.dart` le ferait rougir.
export 'providers/trek_edit_lock_provider.dart' show trekEditLockProvider;
