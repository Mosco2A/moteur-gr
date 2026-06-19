import 'mare_a_mare_trail_config.dart';
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
/// Contient plusieurs sentiers de regions differentes pour prouver la
/// genericite : le premier sentier cible Mare a Mare Centre (Corse,
/// [mareAMareTrailConfig], en TETE = sentier par defaut #84627/#86163), le
/// sentier de demonstration d'Auvergne ([testTrailConfig]) et un sentier des
/// Pyrenees ([pyreneesTrailConfig]).
abstract final class TrailCatalog {
  TrailCatalog._();

  /// Tous les sentiers disponibles, dans l'ordre d'affichage du catalogue.
  ///
  /// `const` : la liste est figee a la compilation en P2-P3 (#84627). L'ordre
  /// fait foi pour le selecteur de sentier (F8D-02) ET pour le sentier par
  /// defaut ([defaultTrail] = premier element). Mare a Mare Centre est en TETE :
  /// c'est le sentier propose et centre par defaut a l'ouverture (GO-62).
  static const List<TrailConfig> all = <TrailConfig>[
    mareAMareTrailConfig,
    testTrailConfig,
    pyreneesTrailConfig,
  ];

  /// Sentier par defaut (premier du catalogue) — jamais une localite hardcodee,
  /// toujours derive des donnees. Sert de selection initiale (F8D-02).
  static TrailConfig get defaultTrail => all.first;

  /// Identifiants de tous les sentiers du catalogue (ordre d'affichage).
  static List<String> get ids =>
      all.map((c) => c.id).toList(growable: false);

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
