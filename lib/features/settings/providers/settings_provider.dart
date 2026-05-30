import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cles des preferences utilisateur
class SettingsKeys {
  static const String language = 'settings_language';
  static const String distanceUnit = 'settings_distance_unit';
  static const String temperatureUnit = 'settings_temperature_unit';
  static const String themeMode = 'settings_theme_mode';
  static const String cacheEnabled = 'settings_cache_enabled';
  static const String cacheSizeMb = 'settings_cache_size_mb';
}

/// Langues disponibles.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef AppLanguage = String;

abstract class AppLanguageValues {
  static const String fr = 'fr';
  static const String en = 'en';
  static const String de = 'de';
  static const String it = 'it';
  static const String es = 'es';
  static const String fallback = fr;
  static const List<String> values = [fr, en, de, it, es];

  static const Map<String, String> labels = {
    fr: 'Francais', en: 'English', de: 'Deutsch', it: 'Italiano', es: 'Espanol',
  };
  static String labelFor(String lang) => labels[lang] ?? lang;
  static AppLanguage fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Unites de distance.
typedef DistanceUnit = String;

abstract class DistanceUnitValues {
  static const String km = 'km';
  static const String miles = 'miles';
  static const String fallback = km;
  static const List<String> values = [km, miles];

  static const Map<String, String> labels = {km: 'Kilometres', miles: 'Miles'};
  static const Map<String, String> symbols = {km: 'km', miles: 'mi'};
  static String labelFor(String unit) => labels[unit] ?? unit;
  static String symbolFor(String unit) => symbols[unit] ?? unit;
  static DistanceUnit fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Unites de temperature.
typedef TemperatureUnit = String;

abstract class TemperatureUnitValues {
  static const String celsius = 'celsius';
  static const String fahrenheit = 'fahrenheit';
  static const String fallback = celsius;
  static const List<String> values = [celsius, fahrenheit];

  static const Map<String, String> labels = {celsius: 'Celsius', fahrenheit: 'Fahrenheit'};
  static const Map<String, String> symbols = {celsius: '°C', fahrenheit: '°F'};
  static String labelFor(String unit) => labels[unit] ?? unit;
  static String symbolFor(String unit) => symbols[unit] ?? unit;
  static TemperatureUnit fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Mode de theme.
typedef AppThemeMode = String;

abstract class AppThemeModeValues {
  static const String dark = 'dark';
  static const String light = 'light';
  static const String system = 'system';
  static const String fallback = dark;
  static const List<String> values = [dark, light, system];

  static const Map<String, String> labels = {dark: 'Sombre', light: 'Clair', system: 'Systeme'};
  static String labelFor(String mode) => labels[mode] ?? mode;
  static AppThemeMode fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Etat des parametres complets
class AppSettings {
  const AppSettings({
    this.language = AppLanguageValues.fr,
    this.distanceUnit = DistanceUnitValues.km,
    this.temperatureUnit = TemperatureUnitValues.celsius,
    this.themeMode = AppThemeModeValues.dark,
    this.cacheEnabled = true,
    this.cacheSizeMb = 500,
  });

  final AppLanguage language;
  final DistanceUnit distanceUnit;
  final TemperatureUnit temperatureUnit;
  final AppThemeMode themeMode;
  final bool cacheEnabled;
  final int cacheSizeMb;

  AppSettings copyWith({
    AppLanguage? language,
    DistanceUnit? distanceUnit,
    TemperatureUnit? temperatureUnit,
    AppThemeMode? themeMode,
    bool? cacheEnabled,
    int? cacheSizeMb,
  }) {
    return AppSettings(
      language: language ?? this.language,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
      themeMode: themeMode ?? this.themeMode,
      cacheEnabled: cacheEnabled ?? this.cacheEnabled,
      cacheSizeMb: cacheSizeMb ?? this.cacheSizeMb,
    );
  }
}

/// Notifier pour les parametres avec persistance SharedPreferences
class SettingsNotifier extends Notifier<AppSettings> {
  SharedPreferences? _prefs;

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  /// Charge les preferences sauvegardees (String-based)
  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final lang = _prefs?.getString(SettingsKeys.language) ?? AppLanguageValues.fr;
    final dist = _prefs?.getString(SettingsKeys.distanceUnit) ?? DistanceUnitValues.km;
    final temp = _prefs?.getString(SettingsKeys.temperatureUnit) ?? TemperatureUnitValues.celsius;
    final theme = _prefs?.getString(SettingsKeys.themeMode) ?? AppThemeModeValues.dark;
    final cacheEnabled = _prefs?.getBool(SettingsKeys.cacheEnabled) ?? true;
    final cacheSizeMb = _prefs?.getInt(SettingsKeys.cacheSizeMb) ?? 500;

    state = AppSettings(
      language: AppLanguageValues.fromString(lang),
      distanceUnit: DistanceUnitValues.fromString(dist),
      temperatureUnit: TemperatureUnitValues.fromString(temp),
      themeMode: AppThemeModeValues.fromString(theme),
      cacheEnabled: cacheEnabled,
      cacheSizeMb: cacheSizeMb,
    );
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    _prefs?.setString(SettingsKeys.language, language);
  }

  void setDistanceUnit(DistanceUnit unit) {
    state = state.copyWith(distanceUnit: unit);
    _prefs?.setString(SettingsKeys.distanceUnit, unit);
  }

  void setTemperatureUnit(TemperatureUnit unit) {
    state = state.copyWith(temperatureUnit: unit);
    _prefs?.setString(SettingsKeys.temperatureUnit, unit);
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setString(SettingsKeys.themeMode, mode);
  }

  void setCacheEnabled(bool enabled) {
    state = state.copyWith(cacheEnabled: enabled);
    _prefs?.setBool(SettingsKeys.cacheEnabled, enabled);
  }

  void setCacheSizeMb(int sizeMb) {
    state = state.copyWith(cacheSizeMb: sizeMb);
    _prefs?.setInt(SettingsKeys.cacheSizeMb, sizeMb);
  }
}

/// Provider des parametres de l'application
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
