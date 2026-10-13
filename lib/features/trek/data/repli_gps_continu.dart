/// LES TROIS SORTIES DE SECOURS VERS LE GPS CONTINU (lot 671-03) : quand
/// l'estime le long du trace est impossible, le profil passe en carte, par le
/// canal du lot 671-00, et revient au profil choisi quand la raison tombe.
///
/// - HORS DU TRACE, au premier releve reel qui le dit : hors du sentier le
///   podometre n'a plus de rail, l'estime est impossible — ce n'est pas une
///   precaution, c'est une necessite. Retour au profil choisi au retour sur
///   le trace.
/// - PAS DE TRACE CHARGE (trace perdu, sentier sans trace) : le GPS continu,
///   c'est-a-dire le comportement d'avant les lots batterie.
/// - PODOMETRE ABSENT, EN ERREUR OU REFUSE : le drapeau pose par le lot 671-02
///   ([EstimateReadiness]) le dit ; aucune autorisation n'est redemandee.
///
/// LE SELECTEUR CACHE DE L'ECRAN DE MESURE RESTE MAITRE. Une sortie de secours
/// ne se declenche que sur une TRANSITION (la condition apparait), jamais sur
/// un etat qui dure ; un choix manuel efface les raisons en cours. Un
/// randonneur qui choisit lui-meme « batterie d'abord » hors du trace l'obtient
/// donc, et le garde jusqu'a la PROCHAINE sortie du trace : la sortie de
/// secours et le choix manuel ne se battent jamais en boucle.
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/gps_cadence.dart';

/// Le profil CHOISI a l'ecran de mesure, distinct du profil EN VIGUEUR du
/// canal (`kPrefsBgProfile`) qu'une sortie de secours peut remplacer par la
/// carte. Sans lui, une application relancee pendant un repli prendrait la
/// carte pour le choix du randonneur.
const String kPrefsBgProfileChosen = 'bg_gps_profile_chosen';

/// Relit le profil choisi ; absent, illisible ou inconnu : [fallback].
Future<PositionProfile> readChosenPositionProfile(
  PositionProfile fallback,
) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(kPrefsBgProfileChosen);
    return stored == null ? fallback : PositionProfile.fromStored(stored);
  } on Object {
    return fallback;
  }
}

/// Range le profil choisi a l'ecran de mesure. Ne leve jamais.
Future<void> writeChosenPositionProfile(PositionProfile profile) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(kPrefsBgProfileChosen, profile.name);
  } on Object {
    // Perdu : le profil en vigueur du canal reste lisible.
  }
}

/// Pourquoi le GPS tourne en continu malgre un profil batterie.
enum ContinuousGpsReason {
  /// Le dernier releve reel est hors du trace.
  offTrack,

  /// Aucun trace charge pour le sentier suivi.
  noTrack,

  /// Le podometre ne permet pas l'estime (absent, en erreur, refuse).
  noStepCounter,
}

/// Decide du profil EN VIGUEUR : le profil choisi, ou la carte tant qu'une
/// raison de secours tient.
class ContinuousGpsFallback {
  /// [apply] change le profil par le canal du lot 671-00 ; [chosen] est le
  /// profil choisi, deja en vigueur au depart.
  ContinuousGpsFallback({
    required Future<void> Function(PositionProfile profile) apply,
    required PositionProfile chosen,
  }) : _apply = apply,
       _chosen = chosen,
       _applied = chosen;

  final Future<void> Function(PositionProfile profile) _apply;
  PositionProfile _chosen;
  PositionProfile _applied;
  final Set<ContinuousGpsReason> _reasons = {};
  final Map<ContinuousGpsReason, bool> _seen = {};

  /// Le profil choisi a l'ecran de mesure.
  PositionProfile get chosen => _chosen;

  /// Les raisons de secours qui tiennent.
  Set<ContinuousGpsReason> get reasons => Set.unmodifiable(_reasons);

  /// Le profil en vigueur : la carte tant qu'une raison tient, sinon le
  /// choisi.
  PositionProfile get effective =>
      _reasons.isEmpty ? _chosen : PositionProfile.map;

  /// Observe les trois conditions ; une valeur nulle est encore inconnue et
  /// ne fait rien. Rend la raison qui vient de faire passer un profil
  /// batterie en carte, pour que l'ecran le dise ; nulle sinon.
  Future<ContinuousGpsReason?> observe({
    bool? offTrack,
    bool? trackLoaded,
    bool? estimatePossible,
  }) async {
    final before = effective;
    ContinuousGpsReason? raised;
    for (final (reason, active) in [
      (ContinuousGpsReason.offTrack, offTrack),
      (ContinuousGpsReason.noTrack, trackLoaded == null ? null : !trackLoaded),
      (
        ContinuousGpsReason.noStepCounter,
        estimatePossible == null ? null : !estimatePossible,
      ),
    ]) {
      if (_transition(reason, active)) raised ??= reason;
    }
    await _applyEffective();
    final fellBack =
        before != PositionProfile.map && effective == PositionProfile.map;
    return fellBack ? raised : null;
  }

  /// LE CHOIX MANUEL DE L'ECRAN DE MESURE, deja applique par lui : il devient
  /// le profil choisi, et efface les raisons en cours.
  void choose(PositionProfile profile) {
    _chosen = profile;
    _applied = profile;
    _reasons.clear();
  }

  /// Vrai si [reason] vient d'apparaitre.
  bool _transition(ContinuousGpsReason reason, bool? active) {
    if (active == null) return false;
    final was = _seen[reason] ?? false;
    _seen[reason] = active;
    if (active && !was) return _reasons.add(reason);
    if (!active && was) _reasons.remove(reason);
    return false;
  }

  Future<void> _applyEffective() async {
    final target = effective;
    if (target == _applied) return;
    _applied = target;
    await _apply(target);
  }
}
