import 'mare_a_mare_centre_demo_trail_config.dart';
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
    // Sentier de DEMONSTRATION, GRATUIT (tache 601). Decision de Chris du
    // 27/09 12:24 : « il y a mare a mare ET mare a mare demo des le catalogue ».
    // Deux entrees distinctes et visibles, pas une entree bridee. Il suit
    // immediatement le sentier qu'il fait decouvrir : on les voit ensemble.
    mareAMareCentreDemoTrailConfig,
    testTrailConfig,
    pyreneesTrailConfig,
  ];

  /// Sentier par defaut (premier du catalogue) — jamais une localite hardcodee,
  /// toujours derive des donnees. Sert de selection initiale (F8D-02).
  static TrailConfig get defaultTrail => all.first;

  /// Identifiants de tous les sentiers du catalogue (ordre d'affichage).
  static List<String> get ids =>
      all.map((c) => c.id).toList(growable: false);

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
