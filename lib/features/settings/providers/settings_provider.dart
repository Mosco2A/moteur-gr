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

/// Langues disponibles
enum AppLanguage {
  fr('Francais', 'fr'),
  en('English', 'en'),
  de('Deutsch', 'de'),
  it('Italiano', 'it'),
  es('Espanol', 'es');

  const AppLanguage(this.label, this.code);
  final String label;
  final String code;
}

/// Unites de distance
enum DistanceUnit {
  km('Kilometres', 'km'),
  miles('Miles', 'mi');

  const DistanceUnit(this.label, this.symbol);
  final String label;
  final String symbol;
}

/// Unites de temperature
enum TemperatureUnit {
  celsius('Celsius', '°C'),
  fahrenheit('Fahrenheit', '°F');

  const TemperatureUnit(this.label, this.symbol);
  final String label;
  final String symbol;
}

/// Mode de theme
enum AppThemeMode {
  dark('Sombre'),
  light('Clair'),
  system('Systeme');

  const AppThemeMode(this.label);
  final String label;
}

/// Etat des parametres complets
class AppSettings {
  const AppSettings({
    this.language = AppLanguage.fr,
    this.distanceUnit = DistanceUnit.km,
    this.temperatureUnit = TemperatureUnit.celsius,
    this.themeMode = AppThemeMode.dark,
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

  /// Charge les preferences sauvegardees
  Future<void> _load() async {
    _prefs = await SharedPreferences.getInstance();

    final langIndex = _prefs?.getInt(SettingsKeys.language) ?? 0;
    final distIndex = _prefs?.getInt(SettingsKeys.distanceUnit) ?? 0;
    final tempIndex = _prefs?.getInt(SettingsKeys.temperatureUnit) ?? 0;
    final themeIndex = _prefs?.getInt(SettingsKeys.themeMode) ?? 0;
    final cacheEnabled =
        _prefs?.getBool(SettingsKeys.cacheEnabled) ?? true;
    final cacheSizeMb =
        _prefs?.getInt(SettingsKeys.cacheSizeMb) ?? 500;

    state = AppSettings(
      language: AppLanguage.values[langIndex.clamp(0, AppLanguage.values.length - 1)],
      distanceUnit: DistanceUnit.values[distIndex.clamp(0, DistanceUnit.values.length - 1)],
      temperatureUnit: TemperatureUnit.values[tempIndex.clamp(0, TemperatureUnit.values.length - 1)],
      themeMode: AppThemeMode.values[themeIndex.clamp(0, AppThemeMode.values.length - 1)],
      cacheEnabled: cacheEnabled,
      cacheSizeMb: cacheSizeMb,
    );
  }

  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    _prefs?.setInt(SettingsKeys.language, language.index);
  }

  void setDistanceUnit(DistanceUnit unit) {
    state = state.copyWith(distanceUnit: unit);
    _prefs?.setInt(SettingsKeys.distanceUnit, unit.index);
  }

  void setTemperatureUnit(TemperatureUnit unit) {
    state = state.copyWith(temperatureUnit: unit);
    _prefs?.setInt(SettingsKeys.temperatureUnit, unit.index);
  }

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _prefs?.setInt(SettingsKeys.themeMode, mode.index);
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
