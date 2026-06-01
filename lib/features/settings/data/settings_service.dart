import 'package:shared_preferences/shared_preferences.dart';

/// Cles SharedPreferences pour les parametres utilisateur.
class SettingsKeys {
  static const String language = 'settings_language';
  static const String distanceUnit = 'settings_distance_unit';
  static const String themeMode = 'settings_theme_mode';
  static const String cacheEnabled = 'settings_cache_enabled';
  static const String cacheSizeMb = 'settings_cache_size_mb';
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

  // --- Langue ---

  /// Lit la langue sauvegardee (fallback: 'fr').
  String getLanguage() =>
      _prefs.getString(SettingsKeys.language) ?? 'fr';

  /// Persiste la langue choisie.
  Future<bool> setLanguage(String language) =>
      _prefs.setString(SettingsKeys.language, language);

  // --- Unites de distance ---

  /// Lit l unite de distance sauvegardee (fallback: 'km').
  String getDistanceUnit() =>
      _prefs.getString(SettingsKeys.distanceUnit) ?? 'km';

  /// Persiste l unite de distance.
  Future<bool> setDistanceUnit(String unit) =>
      _prefs.setString(SettingsKeys.distanceUnit, unit);

  // --- Theme ---

  /// Lit le mode de theme sauvegarde (fallback: 'dark').
  String getThemeMode() =>
      _prefs.getString(SettingsKeys.themeMode) ?? 'dark';

  /// Persiste le mode de theme.
  Future<bool> setThemeMode(String mode) =>
      _prefs.setString(SettingsKeys.themeMode, mode);

  // --- Cache ---

  /// Lit si le cache est active (fallback: true).
  bool getCacheEnabled() =>
      _prefs.getBool(SettingsKeys.cacheEnabled) ?? true;

  /// Persiste l activation du cache.
  Future<bool> setCacheEnabled(bool enabled) =>
      _prefs.setBool(SettingsKeys.cacheEnabled, enabled);

  /// Lit la taille max du cache en Mo (fallback: 500).
  int getCacheSizeMb() =>
      _prefs.getInt(SettingsKeys.cacheSizeMb) ?? 500;

  /// Persiste la taille max du cache.
  Future<bool> setCacheSizeMb(int sizeMb) =>
      _prefs.setInt(SettingsKeys.cacheSizeMb, sizeMb);
}
