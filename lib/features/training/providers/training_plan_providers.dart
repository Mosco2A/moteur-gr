import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/trail_selection.dart';
import '../../feasibility/providers/hiker_profile_provider.dart';
import '../../feasibility/providers/trek_feasibility_provider.dart';
import '../../notifications/providers/download_reminder_provider.dart';
import '../data/training_plan_loader.dart';
import '../models/training_plan.dart';

/// Providers de l'ECRAN ENTRAINEMENT payant (StepWays LOT 5, sous-ensemble A).
///
/// Le plan est EXTERNALISE (JSON, [TrainingPlanLoader]) et PERSONNALISE + DATE :
/// - personnalise : la fiche de renseignement L4 ([hikerProfileProvider]) + le
///   verdict de faisabilite L4 ([trekFeasibilityResultProvider]) ;
/// - date : la date de depart du Calendrier ([downloadReminderProvider]) donne
///   le compte a rebours (« X jours avant ») et l'etat « depart trop proche ».
///
/// Le SUIVI (seances cochees) est persiste UNIQUEMENT en local (SharedPreferences,
/// cle par sentier) — aucune donnee envoyee a un serveur (minimisation RGPD). Le
/// coche est indexe par l'ID STABLE de seance (survit a un changement de plan).

/// Plan d'entrainement du sentier ACTIF (externalise, repli `default`).
final trainingPlanProvider = FutureProvider<TrainingPlan>((ref) async {
  final trailId = ref.watch(resolvedTrailConfigProvider).id;
  return TrainingPlanLoader.loadForTrail(trailId);
});

/// Vrai si un plan SPECIFIQUE (non generique) existe pour le sentier actif.
///
/// Faux -> le plan `default` est servi : l'UI montre une invite non bloquante
/// « plan generique » (spec etat « sans plan specifique »).
final hasSpecificTrainingPlanProvider = FutureProvider<bool>((ref) async {
  final trailId = ref.watch(resolvedTrailConfigProvider).id;
  return TrainingPlanLoader.hasSpecificPlan(trailId);
});

/// Date de depart du sentier actif (Calendrier L3) — null si non posee.
///
/// Source du compte a rebours et de l'etat « depart trop proche ». Reutilise le
/// meme provider que le Calendrier ([downloadReminderProvider]) : une seule
/// source de date, jamais de duplication.
final trainingDepartureDateProvider = Provider<DateTime?>((ref) {
  final trailId = ref.watch(resolvedTrailConfigProvider).id;
  return ref.watch(downloadReminderProvider(trailId)).departureDate;
});

/// Nombre de jours avant le depart (compte a rebours), null si pas de date.
///
/// Calcule en jours calendaires (minuit a minuit) pour eviter qu'une heure de
/// journee fasse varier le chiffre. Negatif si la date est passee (l'UI gere).
final trainingDaysUntilDepartureProvider = Provider<int?>((ref) {
  final date = ref.watch(trainingDepartureDateProvider);
  if (date == null) return null;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dep = DateTime(date.year, date.month, date.day);
  return dep.difference(today).inDays;
});

/// Seuil (en jours) sous lequel le depart est « trop proche » -> plan condense.
///
/// Repere produit : en dessous d'une phase (≈ 3 semaines) le plan complet ne
/// tient plus, on avertit et on condense. DONNEE de reglage (pas une loi).
const int kTrainingTooCloseThresholdDays = 21;

/// Vrai si le depart est pose ET trop proche pour derouler le plan complet.
final trainingDepartureTooCloseProvider = Provider<bool>((ref) {
  final days = ref.watch(trainingDaysUntilDepartureProvider);
  if (days == null) return false;
  return days >= 0 && days < kTrainingTooCloseThresholdDays;
});

/// Personnalisation du plan DERIVEE du profil L4 (fiche + verdict).
///
/// - [hasProfile] : la fiche morpho est-elle renseignee ? (sinon invite non
///   bloquante « remplir la fiche pour adapter », spec etat « sans fiche ») ;
/// - [verdict] : verdict de faisabilite (go/caution/danger/null) -> l'UI adapte
///   le message de cadrage (un profil prudent recoit un rappel de prudence).
class TrainingPersonalization {
  const TrainingPersonalization({
    required this.hasProfile,
    required this.verdict,
  });

  /// Fiche de renseignement remplie (morpho minimale presente).
  final bool hasProfile;

  /// Verdict de faisabilite L4 (cle stable : go/caution/danger), null si absent.
  final String? verdict;

  /// Aucune personnalisation exploitable (ni fiche, ni verdict).
  bool get isGeneric => !hasProfile && verdict == null;
}

/// Personnalisation courante (fiche L4 + verdict L4), pour adapter le plan.
final trainingPersonalizationProvider =
    FutureProvider<TrainingPersonalization>((ref) async {
  final profile = await ref.watch(hikerProfileProvider.future);
  // Le verdict peut etre indisponible (pas d'etapes) -> null tolere.
  final feas = await ref.watch(trekFeasibilityResultProvider.future);
  return TrainingPersonalization(
    hasProfile: profile.hasMorphology,
    verdict: feas?.verdict,
  );
});

// --- Suivi local des seances cochees -------------------------------------

/// Cle SharedPreferences des seances faites (par sentier, local-only).
String trainingDoneKey(String trailId) => 'training_done_sessions_$trailId';

/// Etat du suivi d'entrainement : ensemble des IDs de seances faites.
class TrainingProgressState {
  const TrainingProgressState({this.doneSessionIds = const {}});

  /// IDs STABLES des seances marquees comme faites (cf. [TrainingSession.id]).
  final Set<String> doneSessionIds;

  /// Une seance (par son ID) est-elle faite ?
  bool isDone(String sessionId) => doneSessionIds.contains(sessionId);

  /// Nombre de seances faites PARMI [planSessionIds] (borne au plan courant :
  /// un coche orphelin d'un ancien plan ne gonfle pas la progression).
  int doneCountFor(Set<String> planSessionIds) =>
      doneSessionIds.where(planSessionIds.contains).length;

  TrainingProgressState copyWith({Set<String>? doneSessionIds}) =>
      TrainingProgressState(
        doneSessionIds: doneSessionIds ?? this.doneSessionIds,
      );
}

/// Notifier du suivi (local-only), indexe par sentier.
///
/// Riverpod 3 : `FamilyNotifier` retire — l'argument de famille (`trailId`) est
/// recu par le CONSTRUCTEUR (pattern officiel sans codegen, cf.
/// `DownloadReminderNotifier`). Le tear-off `.new` passe a
/// [NotifierProvider.family] transmet l'argument ici.
class TrainingProgressNotifier extends Notifier<TrainingProgressState> {
  TrainingProgressNotifier(this._trailId);

  final String _trailId;

  @override
  TrainingProgressState build() {
    _loadDone();
    return const TrainingProgressState();
  }

  Future<void> _loadDone() async {
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted) return; // dispose pendant le gap async (Riverpod 3)
    final raw = prefs.getStringList(trainingDoneKey(_trailId)) ?? const [];
    state = state.copyWith(doneSessionIds: raw.toSet());
  }

  /// Bascule l'etat « faite » d'une seance (persiste localement, par sentier).
  Future<void> toggle(String sessionId) async {
    final updated = Set<String>.from(state.doneSessionIds);
    if (!updated.add(sessionId)) updated.remove(sessionId);
    state = state.copyWith(doneSessionIds: updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(trainingDoneKey(_trailId), updated.toList());
  }
}

/// Provider du suivi d'entrainement (seances cochees), indexe par sentier.
final trainingProgressProvider = NotifierProvider.family<
    TrainingProgressNotifier, TrainingProgressState, String>(
  TrainingProgressNotifier.new,
);
