// E5.19a — Service donnees widget Home Screen progression trek.
//
// Met a jour SharedPreferences avec les donnees de progression
// du trek en cours. Ces donnees sont lues par le widget natif
// (Android HomeScreen / iOS WidgetKit) pour afficher la
// progression sans ouvrir l'app.
//
// Appele par TrekRecorder a chaque flush (toutes les 10 positions).
//
// Donnees exposees :
// - trailName, stageName, stageProgress (0.0-1.0)
// - distanceRemaining (metres), etaMinutes
// - altitude (metres), stageIndex, totalStages

import 'package:shared_preferences/shared_preferences.dart';

/// Service de mise a jour des donnees pour le widget Home Screen.
///
/// Ecrit les donnees de progression trek dans SharedPreferences
/// pour que le widget natif (Android/iOS) puisse les lire.
/// Chaque flush du TrekRecorder (10 positions) declenche une MAJ.
class WidgetDataService {
  WidgetDataService({SharedPreferences? prefs}) : _prefs = prefs;

  /// Instance SharedPreferences (injectee ou chargee au premier appel).
  SharedPreferences? _prefs;

  // --- Cles SharedPreferences pour le widget ---
  static const String _prefix = 'widget_trek_';
  static const String keyTrailName = '${_prefix}trail_name';
  static const String keyStageName = '${_prefix}stage_name';
  static const String keyStageProgress = '${_prefix}stage_progress';
  static const String keyDistanceRemaining = '${_prefix}distance_remaining';
  static const String keyEtaMinutes = '${_prefix}eta_minutes';
  static const String keyAltitude = '${_prefix}altitude';
  static const String keyStageIndex = '${_prefix}stage_index';
  static const String keyTotalStages = '${_prefix}total_stages';
  static const String keyLastUpdate = '${_prefix}last_update';
  static const String keyThemeColor = '${_prefix}theme_color';

  /// Initialise le service (charge SharedPreferences si pas injecte).
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Met a jour les donnees du widget avec la progression actuelle.
  ///
  /// Appele par TrekRecorder a chaque flush (10 positions).
  /// Toutes les valeurs sont ecrites atomiquement dans SharedPreferences.
  Future<void> updateWidgetData({
    required String trailName,
    required String stageName,
    required double stageProgress,
    required double distanceRemaining,
    required int etaMinutes,
    required double altitude,
    required int stageIndex,
    required int totalStages,
    int? themeColorValue,
  }) async {
    await initialize();
    final prefs = _prefs;
    if (prefs == null) return;

    if (themeColorValue != null) {
      await prefs.setInt(keyThemeColor, themeColorValue);
    }

    await prefs.setString(keyTrailName, trailName);
    await prefs.setString(keyStageName, stageName);
    await prefs.setDouble(keyStageProgress, stageProgress.clamp(0.0, 1.0));
    await prefs.setDouble(keyDistanceRemaining, distanceRemaining);
    await prefs.setInt(keyEtaMinutes, etaMinutes);
    await prefs.setDouble(keyAltitude, altitude);
    await prefs.setInt(keyStageIndex, stageIndex);
    await prefs.setInt(keyTotalStages, totalStages);
    await prefs.setString(keyLastUpdate, DateTime.now().toIso8601String());
  }

  /// Efface les donnees du widget (fin de trek ou desactivation).
  Future<void> clearWidgetData() async {
    await initialize();
    final prefs = _prefs;
    if (prefs == null) return;

    await prefs.remove(keyTrailName);
    await prefs.remove(keyStageName);
    await prefs.remove(keyStageProgress);
    await prefs.remove(keyDistanceRemaining);
    await prefs.remove(keyEtaMinutes);
    await prefs.remove(keyAltitude);
    await prefs.remove(keyStageIndex);
    await prefs.remove(keyTotalStages);
    await prefs.remove(keyLastUpdate);
    await prefs.remove(keyThemeColor);
  }

  /// Retourne les donnees actuelles du widget (debug/test).
  Map<String, dynamic> getWidgetData() {
    final prefs = _prefs;
    if (prefs == null) return {};

    return {
      'trailName': prefs.getString(keyTrailName) ?? '',
      'stageName': prefs.getString(keyStageName) ?? '',
      'stageProgress': prefs.getDouble(keyStageProgress) ?? 0.0,
      'distanceRemaining': prefs.getDouble(keyDistanceRemaining) ?? 0.0,
      'etaMinutes': prefs.getInt(keyEtaMinutes) ?? 0,
      'altitude': prefs.getDouble(keyAltitude) ?? 0.0,
      'stageIndex': prefs.getInt(keyStageIndex) ?? 0,
      'totalStages': prefs.getInt(keyTotalStages) ?? 0,
      'lastUpdate': prefs.getString(keyLastUpdate) ?? '',
    };
  }
}
