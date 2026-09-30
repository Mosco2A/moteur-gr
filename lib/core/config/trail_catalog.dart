import 'mare_a_mare_centre_trail_config.dart';
import 'pyrenees_trail_config.dart';
import 'test_trail_config.dart';
import 'trail_config.dart';

/// Catalogue des sentiers connus du Moteur GR (F8D-01, Phase 8 P8-D).
///
/// Le moteur est GENERIQUE multi-sentiers (#84627) : il ne hardcode AUCUNE
/// localite (ni Corse, ni Mare a Mare). Chaque sentier est une [TrailConfig] —
/// une DONNEE — enregistree ici. Ajouter un sentier = ajouter une entree, sans
/// toucher au moteur.
///
/// En P2-P3, le catalogue est embarque (donnees fictives, #84627). En Phase 4,
/// le backend pourra fournir/mettre a jour la liste des sentiers disponibles.
///
/// Contient au moins DEUX sentiers de regions differentes pour prouver la
/// genericite : le sentier de demonstration d'Auvergne ([testTrailConfig]) et un
/// premier sentier HORS Corse dans les Pyrenees ([pyreneesTrailConfig]).
abstract final class TrailCatalog {
  TrailCatalog._();

  /// Tous les sentiers disponibles, dans l'ordre d'affichage du catalogue.
  ///
  /// `const` : la liste est figee a la compilation en P2-P3 (#84627). L'ordre
  /// fait foi pour le selecteur de sentier (F8D-02).
  static const List<TrailConfig> all = <TrailConfig>[
    // Sentier reel PAYANT de StepWays (#99423). EN TETE => devient
    // [defaultTrail] : l'app demarre dessus. Reste une DONNEE (TrailConfig), le
    // moteur ne hardcode aucune localite.
    mareAMareCentreTrailConfig,
    // IL N'Y A PLUS DE SENTIER « MARE A MARE CENTRE DEMO » (tache 638, bugs 1 et
    // 8 — DEM-260930-1005 et DEM-260930-1014). Le lot 601 avait ajoute ici un
    // SECOND Mare a Mare, gratuit et ampute a deux etapes, sur la decision de
    // Christophe du 27/09 : « il y a mare a mare ET mare a mare demo des le
    // catalogue ». Son test du 30/09 a renverse les deux moities de cette
    // decision, verbatim : « il reste Mare a Mare Centre Demo gratuite en doublon
    // avec Essayer la demo » (bug 1) et « la demo de Mare a Mare ce doit etre la
    // demo de Mare a Mare, pas un truc avec 2 etapes !! » (bug 8).
    //
    // LA DEMO N'EST DONC PLUS UN SENTIER, C'EST UN MODE, et il s'applique au
    // sentier ci-dessus — entier. Le doublon disparait du catalogue avec
    // l'entree, et le bouton orange « Essayer la demo » reste la seule porte
    // d'entree de la demonstration (cf. `session_demo.dart`).
    //
    // ET IL N'Y A PLUS AUCUN SENTIER GRATUIT AU CATALOGUE. C'est une decision de
    // Christophe, pas une consequence : son scenario d'acceptation du 29/09
    // 14:17 dit, verbatim, « la prochaine fois que j'ouvre l'application je n'ai
    // droit a rien ». Un sentier gratuit au catalogue lui donnerait droit a
    // quelque chose sans qu'il ait rien achete — exactement ce qu'il refuse.
    //
    // LE NIVEAU GRATUIT DU MODELE ECO, C'EST LA DEMO, PAS UN SENTIER. Le modele
    // du lot 601 — « un sentier gratuit est une ENTREE du modele, dont le prix
    // est nul ; une exemption serait un trou » — reste ecrit et teste
    // ([TrailConfig.isFreeTrail], [freeIds]) : il n'a simplement plus d'instance,
    // et c'est un etat legitime. Ce que le randonneur qui n'a rien achete peut
    // faire, il le fait par le bouton orange : il VOIT tout, il n'ACQUIERT rien.
    //
    // COROLLAIRE ASSUME : « Mes treks » est VIDE au premier lancement, et il le
    // DIT (cf. `my_treks_screen.dart`, etat vide) en renvoyant vers le catalogue
    // et vers la demo. Un accueil vide qui explique n'est pas une panne ; un
    // sentier offert pour eviter un ecran vide serait un cadeau que personne n'a
    // decide.
    testTrailConfig,
    pyreneesTrailConfig,
  ];

  /// Sentier par defaut (premier du catalogue) — jamais une localite hardcodee,
  /// toujours derive des donnees. Sert de selection initiale (F8D-02).
  static TrailConfig get defaultTrail => all.first;

  /// Identifiants de tous les sentiers du catalogue (ordre d'affichage).
  static List<String> get ids => all.map((c) => c.id).toList(growable: false);

  /// Identifiants des sentiers GRATUITS — ceux dont le PRIX est nul.
  ///
  /// Dérivé du PRIX porté par la donnée ([TrailConfig.priceStages] à 0), jamais
  /// d'un id de localité codé en dur. Remplace l'ancien `showcaseIds`, qui
  /// dérivait d'un drapeau d'EXEMPTION (`isShowcaseTrail`) au lieu d'un prix :
  /// la différence est de fond et pas de forme (tâche 601). Une exemption est un
  /// trou dans le modèle ; un prix nul est une entrée du modèle, dont tout le
  /// reste — accès, réalisation, publicité — se déduit.
  static Set<String> get freeIds =>
      all.where((c) => c.isFreeTrail).map((c) => c.id).toSet();

  /// Vrai si [id] est un sentier GRATUIT (prix nul, donc rien à débloquer).
  static bool isFree(String? id) => id != null && freeIds.contains(id);

  /// Retourne la config du sentier [id], ou null si inconnu.
  static TrailConfig? byId(String id) {
    for (final config in all) {
      if (config.id == id) return config;
    }
    return null;
  }

  /// Vrai si [id] correspond a un sentier connu du catalogue.
  static bool contains(String id) => byId(id) != null;

  /// Resout [id] vers une config connue, ou retombe sur [defaultTrail].
  ///
  /// Garantit qu'une selection invalide (sentier retire, id obsolete) ne casse
  /// jamais le moteur : on retombe sur un sentier valide (genericite robuste).
  static TrailConfig resolveOrDefault(String? id) {
    if (id == null) return defaultTrail;
    return byId(id) ?? defaultTrail;
  }
}
