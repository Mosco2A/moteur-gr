import 'package:shared_preferences/shared_preferences.dart';

/// Cles SharedPreferences pour les parametres utilisateur.
class SettingsKeys {
  static const String language = 'settings_language';
  static const String distanceUnit = 'settings_distance_unit';

  /// Unite de temperature ('celsius'|'fahrenheit'), defaut 'celsius'.
  ///
  /// CETTE CLE N'EST PAS NEUVE, ET LE LOT 645-F1 SE TROMPAIT EN L'ECRIVANT ICI
  /// (« cle nouvelle, jamais ecrite avant ce lot, aucune migration »). Le build
  /// du 26/05/2026 (commit db71ad1e) l'ecrivait deja — sous la forme d'un INDEX
  /// D'ENUM, donc en entier. C'est ce que la lecture tolerante plus bas paie.
  static const String temperatureUnit = 'settings_temperature_unit';

  static const String themeMode = 'settings_theme_mode';
  static const String cacheEnabled = 'settings_cache_enabled';
  static const String cacheSizeMb = 'settings_cache_size_mb';

  /// Peau visuelle selectionnee (SW-SKIN-L7). Choix GLOBAL (pas par sentier),
  /// persiste par le nom de l'enum [AppSkin] (ex: 'sentierVivant').
  static const String skin = 'settings_skin';

  /// Lateralite (main dominante) pour l'ergonomie thumb zone (nav V2, R9/R10).
  /// Valeurs 'right'|'left', defaut 'right' (droitier). Donnee NON sensible.
  static const String dominantHand = 'settings_dominant_hand';
}

/// Service de persistance des parametres via SharedPreferences.
///
/// Responsabilite unique : lecture/ecriture SharedPreferences.
/// Les providers Riverpod consomment ce service pour exposer l'etat reactif.
class SettingsService {
  SettingsService(this._prefs);

  final SharedPreferences _prefs;

  /// Factory async — initialise SharedPreferences une seule fois.
  static Future<SettingsService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SettingsService(prefs);
  }

  // --- LECTURE TOLERANTE : UNE CLE ABIMEE N'EN EMPORTE PAS LES AUTRES ------
  //
  // P1 (#101255 point 1, defaut mesure par Artemis #101197 point 1).
  //
  // CE QUI SE PASSAIT. Le build du 26/05/2026 (commit db71ad1e, « E3.9
  // parametres complets ») ecrivait langue, unites et theme sous la forme d'un
  // INDEX D'ENUM : `_prefs.setInt('settings_temperature_unit', unit.index)`.
  // Ces memes cles sont relues en CHAINES depuis le lot 645-F1. Or
  // `getString` sur une valeur entiere ne rend pas `null` : il LEVE un
  // `TypeError` (« type 'int' is not a subtype of type 'String?' »). La
  // lecture s'arretait donc au premier reglage herite, `_load` du provider
  // n'affectait jamais `state`, et langue, theme, unites ET cache repartaient
  // tous a leur defaut EN SILENCE : un reglage abime en emportait cinq
  // intacts, et le randonneur n'avait aucun message pour le lui dire.
  //
  // CE QUE CES TROIS LECTEURS GARANTISSENT. Une valeur absente, inconnue ou
  // d'un ancien format se replie sur le defaut DE SA SEULE CLE ; les autres
  // cles rendent ce que le randonneur a choisi ; et aucune lecture de reglage
  // ne leve, jamais.
  //
  // POURQUOI UN REPLI ET PAS UNE MIGRATION DE L'INDEX. Traduire l'entier 1 en
  // 'fahrenheit' supposerait que l'ordre des enums du 26/05 n'a pas bouge
  // depuis — il a bouge (le lot 645-F1 a remplace les enums par des chaines
  // extensibles) — et une supposition fausse rendrait un reglage que le
  // randonneur n'a jamais choisi. Le defaut de la cle, lui, ne ment pas.
  //
  // POURQUOI ON NE REECRIT PAS LA CLE ABIMEE AU PASSAGE. Une lecture qui
  // ecrit est une surprise : elle transforme l'ouverture d'un ecran en
  // modification du magasin, et deux lectures concurrentes n'ont plus le meme
  // resultat. La valeur heritee est inoffensive une fois le repli en place, et
  // le premier `set...` du randonneur l'ecrase avec la forme courante.
  //
  // POURQUOI `on Object` ET PAS `on TypeError`. Ces trois lecteurs n'enveloppent
  // QUE l'appel a SharedPreferences, qui n'a pas d'autre facon d'echouer qu'un
  // type qui ne correspond pas — la classe exacte levee par un cast rate
  // (`_TypeError`) est privee au coeur de Dart et son nom public a deja change
  // une fois. Attraper l'erreur par son type exact, c'est parier sur ce nom.

  /// Lit une chaine, ou [defaut] si la cle est absente ou d'un autre type.
  String _chaine(String cle, String defaut) => _chaineOuNull(cle) ?? defaut;

  /// Lit une chaine, ou `null` si la cle est absente ou d'un autre type.
  String? _chaineOuNull(String cle) {
    try {
      return _prefs.getString(cle);
    } on Object catch (_) {
      return null;
    }
  }

  /// Lit un booleen, ou [defaut] si la cle est absente ou d'un autre type.
  bool _booleen(String cle, bool defaut) {
    try {
      return _prefs.getBool(cle) ?? defaut;
    } on Object catch (_) {
      return defaut;
    }
  }

  /// Lit un entier, ou [defaut] si la cle est absente ou d'un autre type.
  int _entier(String cle, int defaut) {
    try {
      return _prefs.getInt(cle) ?? defaut;
    } on Object catch (_) {
      return defaut;
    }
  }

  // --- Langue ---

  /// Lit la langue sauvegardee (fallback: 'fr').
  String getLanguage() => _chaine(SettingsKeys.language, 'fr');

  /// Persiste la langue choisie.
  Future<bool> setLanguage(String language) =>
      _prefs.setString(SettingsKeys.language, language);

  // --- Unites de distance ---

  /// Lit l unite de distance sauvegardee (fallback: 'km').
  String getDistanceUnit() => _chaine(SettingsKeys.distanceUnit, 'km');

  /// Persiste l unite de distance.
  Future<bool> setDistanceUnit(String unit) =>
      _prefs.setString(SettingsKeys.distanceUnit, unit);

  // --- Unites de temperature ---

  /// Lit l unite de temperature sauvegardee (fallback: 'celsius').
  ///
  /// C'est la cle que le build du 26/05/2026 ecrivait en entier : voir
  /// « LECTURE TOLERANTE » plus haut.
  String getTemperatureUnit() =>
      _chaine(SettingsKeys.temperatureUnit, 'celsius');

  /// Persiste l unite de temperature.
  Future<bool> setTemperatureUnit(String unit) =>
      _prefs.setString(SettingsKeys.temperatureUnit, unit);

  // --- Theme ---

  /// Lit le mode de theme sauvegarde (fallback: 'dark').
  String getThemeMode() => _chaine(SettingsKeys.themeMode, 'dark');

  /// Persiste le mode de theme.
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(SettingsKeys.themeMode, mode);

  // --- Cache ---

  /// Lit si le cache est active (fallback: true).
  bool getCacheEnabled() => _booleen(SettingsKeys.cacheEnabled, true);

  /// Persiste l activation du cache.
  Future<bool> setCacheEnabled(bool enabled) =>
      _prefs.setBool(SettingsKeys.cacheEnabled, enabled);

  /// Lit la taille max du cache en Mo (fallback: 500).
  int getCacheSizeMb() => _entier(SettingsKeys.cacheSizeMb, 500);

  /// Persiste la taille max du cache.
  Future<bool> setCacheSizeMb(int sizeMb) =>
      _prefs.setInt(SettingsKeys.cacheSizeMb, sizeMb);

  // --- Peau visuelle (SW-SKIN-L7) ---

  /// Lit le nom de la peau selectionnee (fallback: null si aucun choix).
  ///
  /// Retourne la chaine brute (nom d'enum `AppSkin`, ex 'sentierVivant') ;
  /// la resolution vers l'enum (avec defaut sur choix inconnu) est faite par
  /// `skinProvider`. `null` -> jamais choisi -> defaut Sentier Vivant.
  String? getSkin() => _chaineOuNull(SettingsKeys.skin);

  /// Persiste la peau choisie (nom d'enum `AppSkin`). Choix global au sentier.
  Future<bool> setSkin(String skinName) =>
      _prefs.setString(SettingsKeys.skin, skinName);

  // --- Lateralite / main dominante (nav V2, R9/R10) ---

  /// Lit la main dominante sauvegardee (fallback: 'right' — droitier).
  ///
  /// Pilote la position du SOS et des commandes critiques cote main dominante
  /// (thumb zone). Chaine brute ('right'|'left') ; la resolution vers l'enum
  /// (avec defaut sur valeur inconnue) est faite par `DominantHandValues`.
  String getDominantHand() => _chaine(SettingsKeys.dominantHand, 'right');

  /// Persiste la main dominante choisie ('right'|'left').
  Future<bool> setDominantHand(String hand) =>
      _prefs.setString(SettingsKeys.dominantHand, hand);
}
