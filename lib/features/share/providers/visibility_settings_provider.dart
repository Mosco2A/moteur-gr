import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cles SharedPreferences des reglages de visibilite sociale (F7D-02).
abstract final class VisibilityKeys {
  static const String shareStageResults = 'visibility_share_stage_results';
  static const String shareLeaderboard = 'visibility_share_leaderboard';
  static const String shareActivityFeed = 'visibility_share_activity_feed';
}

/// Etat de VISIBILITE sociale, GRANULAIRE par finalite (F7D-02, Phase 7).
///
/// REGLE : PRIVE PAR DEFAUT (tous les drapeaux a faux). L'utilisateur active
/// EXPLICITEMENT (opt-in) chaque finalite separement. Coherent avec la gestion
/// de consentement RGPD du design Securite D4 (granularite par finalite).
class VisibilitySettings {
  const VisibilitySettings({
    this.shareStageResults = false,
    this.shareLeaderboard = false,
    this.shareActivityFeed = false,
  });

  /// Partage des resultats d'etape (carte F7D-01) — opt-in.
  final bool shareStageResults;

  /// Presence dans les leaderboards par tranche (F7A-04) — opt-in.
  final bool shareLeaderboard;

  /// Publication au fil d'activite (F7B-04) — opt-in.
  final bool shareActivityFeed;

  VisibilitySettings copyWith({
    bool? shareStageResults,
    bool? shareLeaderboard,
    bool? shareActivityFeed,
  }) {
    return VisibilitySettings(
      shareStageResults: shareStageResults ?? this.shareStageResults,
      shareLeaderboard: shareLeaderboard ?? this.shareLeaderboard,
      shareActivityFeed: shareActivityFeed ?? this.shareActivityFeed,
    );
  }
}

/// Notifier des reglages de visibilite, persiste via SharedPreferences (F7D-02).
///
/// Au demarrage : PRIVE PAR DEFAUT. Chaque toggle persiste l'opt-in de la
/// finalite concernee, independamment des autres (granularite).
class VisibilitySettingsNotifier extends Notifier<VisibilitySettings> {
  SharedPreferences? _prefs;

  @override
  VisibilitySettings build() {
    _load();
    // Prive par defaut tant que les prefs ne sont pas chargees.
    return const VisibilitySettings();
  }

  /// Charge les reglages de visibilite depuis SharedPreferences.
  ///
  /// `ref.mounted` apres le gap async : si le provider a ete dispose pendant
  /// l'attente (ex. container detruit tot en test, ou rebuild), on n'ecrit pas
  /// `state` (sinon Riverpod 3 leve « Ref used after dispose »).
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return;
    _prefs = prefs;
    state = VisibilitySettings(
      shareStageResults:
          _prefs!.getBool(VisibilityKeys.shareStageResults) ?? false,
      shareLeaderboard:
          _prefs!.getBool(VisibilityKeys.shareLeaderboard) ?? false,
      shareActivityFeed:
          _prefs!.getBool(VisibilityKeys.shareActivityFeed) ?? false,
    );
  }

  /// Opt-in/opt-out du partage des resultats d'etape (persiste).
  void setShareStageResults(bool value) {
    state = state.copyWith(shareStageResults: value);
    _prefs?.setBool(VisibilityKeys.shareStageResults, value);
  }

  /// Opt-in/opt-out de la presence au leaderboard (persiste).
  void setShareLeaderboard(bool value) {
    state = state.copyWith(shareLeaderboard: value);
    _prefs?.setBool(VisibilityKeys.shareLeaderboard, value);
  }

  /// Opt-in/opt-out de la publication au fil d'activite (persiste).
  void setShareActivityFeed(bool value) {
    state = state.copyWith(shareActivityFeed: value);
    _prefs?.setBool(VisibilityKeys.shareActivityFeed, value);
  }
}

/// Provider des reglages de visibilite sociale (F7D-02).
final visibilitySettingsProvider =
    NotifierProvider<VisibilitySettingsNotifier, VisibilitySettings>(
  VisibilitySettingsNotifier.new,
);
