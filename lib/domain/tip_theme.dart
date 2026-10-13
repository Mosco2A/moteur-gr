/// Taxonomie des THEMES de fiches conseil (StepWays LOT 5, sous-ensemble C).
///
/// Decision Chris #99615 : les fiches sont RANGEES PAR THEMES (fini la liste a
/// plat). Themes de reference (exemples valides par Chris, extensibles) :
/// Materiel, Securite, Sante, Meteo, Vie du refuge. String extensible (jamais un
/// enum en donnee) : ajouter un theme = ajouter une cle i18n + du contenu, sans
/// recompiler. La liste EXACTE des themes et l'affectation fiche->theme sont a
/// arreter avec Chris a l'implementation ; le PRINCIPE (par themes) est acte.
///
/// Ordre d'AFFICHAGE stable ([displayOrder]) : les sections apparaissent
/// toujours dans cet ordre ; tout theme inconnu passe en fin (repli `other`).
abstract class TipTheme {
  static const String gear = 'gear'; // Materiel
  static const String safety = 'safety'; // Securite
  static const String health = 'health'; // Sante
  static const String weather = 'weather'; // Meteo
  static const String refuge = 'refuge'; // Vie du refuge
  static const String nature = 'nature'; // Nature / environnement
  static const String other = 'other'; // Divers (repli)

  /// Ordre d'affichage des sections par theme (parite lisible, stable).
  static const List<String> displayOrder = [
    gear,
    safety,
    health,
    weather,
    refuge,
    nature,
    other,
  ];

  /// Repli theme -> icone Material (nom, resolu cote UI).
  static String iconFor(String theme) {
    switch (theme) {
      case gear:
        return 'backpack';
      case safety:
        return 'health_and_safety';
      case health:
        return 'healing';
      case weather:
        return 'wb_sunny';
      case refuge:
        return 'cabin';
      case nature:
        return 'forest';
      default:
        return 'info';
    }
  }

  /// Derive un theme depuis l'ancienne CATEGORIE d'une fiche (repli).
  ///
  /// Les fiches historiques ne portent pas de `theme` : on le deduit de leur
  /// `category` pour ranger l'existant sans reecrire les fiches (spec C : « on
  /// ne reecrit pas les fiches, on les range »).
  static String fromCategory(String category) {
    switch (category) {
      case 'equipment':
        return gear;
      case 'safety':
        return safety;
      case 'nutrition': // hydratation / alimentation -> sante
      case 'recovery':
        return health;
      case 'weather':
        return weather;
      case 'nature':
        return nature;
      case 'preparation':
        return gear; // preparation materiel/logistique -> Materiel par defaut
      default:
        return other;
    }
  }

  /// Trie une liste de themes selon [displayOrder] (inconnus en fin).
  static int compare(String a, String b) {
    final ia = displayOrder.indexOf(a);
    final ib = displayOrder.indexOf(b);
    final na = ia < 0 ? displayOrder.length : ia;
    final nb = ib < 0 ? displayOrder.length : ib;
    return na.compareTo(nb);
  }
}
