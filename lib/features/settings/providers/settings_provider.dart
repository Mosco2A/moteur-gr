import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_service.dart';

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

/// Provider du SettingsService — initialise SharedPreferences.
final settingsServiceProvider = FutureProvider<SettingsService>((ref) async {
  return SettingsService.create();
});

/// Notifier pour les parametres avec persistance via SettingsService.
///
/// Migration v2: delegue la persistance a SettingsService (separation of concerns).
/// Utilise select() dans les widgets pour ecouter un seul champ.
class SettingsNotifier extends Notifier<AppSettings> {
  SettingsService? _service;

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  /// Charge les preferences sauvegardees via SettingsService.
  Future<void> _load() async {
    _service = await SettingsService.create();

    state = AppSettings(
      language: AppLanguageValues.fromString(_service!.getLanguage()),
      distanceUnit: DistanceUnitValues.fromString(_service!.getDistanceUnit()),
      temperatureUnit: state.temperatureUnit,
      themeMode: AppThemeModeValues.fromString(_service!.getThemeMode()),
      cacheEnabled: _service!.getCacheEnabled(),
      cacheSizeMb: _service!.getCacheSizeMb(),
    );
  }

  /// Met a jour la langue et persiste.
  void setLanguage(AppLanguage language) {
    state = state.copyWith(language: language);
    _service?.setLanguage(language);
  }

  /// Met a jour l unite de distance et persiste.
  void setDistanceUnit(DistanceUnit unit) {
    state = state.copyWith(distanceUnit: unit);
    _service?.setDistanceUnit(unit);
  }

  /// Met a jour l unite de temperature et persiste.
  void setTemperatureUnit(TemperatureUnit unit) {
    state = state.copyWith(temperatureUnit: unit);
  }

  /// Met a jour le mode de theme et persiste.
  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _service?.setThemeMode(mode);
  }

  /// Active/desactive le cache et persiste.
  void setCacheEnabled(bool enabled) {
    state = state.copyWith(cacheEnabled: enabled);
    _service?.setCacheEnabled(enabled);
  }

  /// Met a jour la taille max du cache et persiste.
  void setCacheSizeMb(int sizeMb) {
    state = state.copyWith(cacheSizeMb: sizeMb);
    _service?.setCacheSizeMb(sizeMb);
  }
}

/// Provider des parametres de l application — Riverpod 3.
///
/// Utilise select() dans les widgets pour minimiser les rebuilds :
///   ref.watch(settingsProvider.select((s) => s.language))
final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);
