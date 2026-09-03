import 'package:flutter_riverpod/flutter_riverpod.dart';

// Le modele de domaine `Stage` (features/trek/domain/models/stage.dart) est la
// source des distances/D+ par etape. La base Drift expose aussi une classe
// `Stage` (table) : on la masque ici pour lever l'ambiguite tout en gardant
// `SessionTrackPoint` (trace GPS de session).
import '../../../core/data/database.dart' hide Stage;
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/service_providers.dart';
import '../../trek/domain/models/stage.dart';
import '../../trek/domain/models/trek_session.dart';
import '../../trek/domain/trek_completion.dart';
import '../../trek/providers/gps_providers.dart';
import '../../trek/providers/stage_providers.dart';

/// PARITE GR20, LOT 3 (#99433) — socle « Apres le trek » : session reelle,
/// stats reelles, et gate du diplome (finisher).
///
/// Toutes les donnees « apres le trek » (Recap « Mon aventure », chiffres et
/// gate du Diplome) sont derivees de la SESSION REELLEMENT persistee du sentier
/// actif ([TrekSessionsDao.getLatestByTrailId]) — jamais des totaux statiques du
/// sentier. C'est la parite avec GR20 : le diplome et le recap refletent le
/// parcours reellement effectue (etapes marchees, distance/D+ parcourus), et le
/// diplome est verrouille tant que le parcours n'a pas ete fini — sauf sur un
/// sentier VITRINE, debloque pour la demonstration.

/// Statut « brut » de la derniere session persistee (String extensible).
const String kTrekStatusCompleted = 'completed';
const String kTrekStatusAbandoned = 'abandoned';

/// Derniere session persistee du sentier actif (ou null si aucune).
///
/// Source unique de l'etat « apres le trek ». Relit la base a chaque
/// invalidation ; l'ecran Recap et le gate du diplome s'y abonnent.
final latestTrekSessionProvider = FutureProvider<TrekSession?>((ref) async {
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final db = ref.watch(databaseProvider);
  return db.trekSessionsDao.getLatestByTrailId(trailId);
});

/// Le sentier actif est-il une VITRINE de demonstration ?
///
/// Exception de parite (LOT 2/3) : sur une vitrine, le diplome et le recap sont
/// debloques pour la demo (comme le mode demo « tout debloque » de GR20). Pilote
/// par le flag de donnees [TrailConfig.isShowcaseTrail] (via
/// [DemoModeService]) — jamais un id de localite en dur.
final isShowcaseTrailProvider = Provider<bool>((ref) {
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final demo = ref.watch(demoModeServiceProvider);
  return demo.isShowcaseTrail(trailId);
});

/// Le DIPLOME est-il deverrouille ? (gate finisher + exception vitrine).
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(1) :
///  * Un sentier VITRINE est TOUJOURS deverrouille (demonstration) — parite avec
///    le diplome GR20 debloque en mode demo.
///  * Sinon (vrai trek non-vitrine), le diplome n'est deverrouille QUE si le
///    parcours a ete REELLEMENT parcouru en entier : la derniere session
///    persistee porte `parcoursFullyWalked == true` (le finisher, cf.
///    [TrekPlan.isFullyWalked] fige au franchissement de la porte). Tant que
///    `!parcoursFullyWalked`, le diplome est VERROUILLE (equivalent du
///    `status != completed` de GR20, mais sur l'etat de session reel).
///
/// Retourne false tant que la session n'est pas chargee (fail-closed : jamais de
/// faux deverrouillage pendant le chargement).
final isDiplomaUnlockedProvider = Provider<bool>((ref) {
  if (ref.watch(isShowcaseTrailProvider)) return true;
  final session = ref.watch(latestTrekSessionProvider).value;
  return session?.parcoursFullyWalked ?? false;
});

/// Le RECAP « Mon aventure » est-il accessible ?
///
/// PARITE GR20, LOT 3 (#99433), point 3.A : accessible quand le trek est TERMINE
/// (`completed`) OU ABANDONNE (`abandoned`) — plus la VITRINE (demo). Un abandon
/// doit pouvoir revoir son aventure (parite `after/adventure_recap_screen.dart`
/// GR20, chantier C #97501). Fail-closed pendant le chargement.
final isRecapAvailableProvider = Provider<bool>((ref) {
  if (ref.watch(isShowcaseTrailProvider)) return true;
  final session = ref.watch(latestTrekSessionProvider).value;
  if (session == null) return false;
  return session.status == kTrekStatusCompleted ||
      session.status == kTrekStatusAbandoned;
});

/// Stats REELLES de l'aventure, derivees de la session persistee + de la trace.
///
/// - `stagesWalked` : nombre d'etapes REELLEMENT marchees
///   ([TrekSession.completedStages]).
/// - `totalStages` : nombre d'etapes du parcours (pour l'affichage « n/total »).
/// - `distanceKm` / `elevationGainM` : somme des etapes REELLEMENT marchees
///   (mappees sur les etapes du sentier). Fait foi sur les totaux statiques.
/// - `startDate` / `endDate` / `durationDays` : horodatage reel de la session.
/// - `fullyWalked` : le parcours a-t-il ete fini (finisher legitime) ?
/// - `tracePoints` : trace GPS reelle de la session (peut etre vide).
class AdventureStats {
  const AdventureStats({
    required this.stagesWalked,
    required this.totalStages,
    required this.distanceKm,
    required this.elevationGainM,
    required this.startDate,
    required this.endDate,
    required this.durationDays,
    required this.fullyWalked,
    required this.tracePoints,
  });

  final int stagesWalked;
  final int totalStages;
  final double distanceKm;
  final int elevationGainM;
  final DateTime? startDate;
  final DateTime? endDate;
  final int durationDays;
  final bool fullyWalked;
  final List<SessionTrackPoint> tracePoints;

  /// Y a-t-il au moins une etape marchee (donnees exploitables) ?
  bool get hasWalkedStages => stagesWalked > 0;
}

/// Stats reelles de l'aventure pour le sentier actif.
///
/// Combine la session persistee ([latestTrekSessionProvider]), les etapes du
/// sentier ([domainStagesProvider], pour mapper distance/D+ des etapes
/// marchees) et la trace GPS reelle ([SessionTrackPointsDao]). Zero total
/// statique du sentier : seule l'etape REELLEMENT marchee compte.
final adventureStatsProvider = FutureProvider<AdventureStats>((ref) async {
  final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
  final db = ref.watch(databaseProvider);
  final session = await ref.watch(latestTrekSessionProvider.future);
  // Garantir que les etapes du sentier sont chargees AVANT de calculer : sans
  // cela, [domainStagesProvider] (derive sync de stagesProvider.value) renverrait
  // une liste vide tant que le chargement async n'a pas abouti -> distance/D+ et
  // totalStages fausses (=0). On attend donc explicitement la resolution.
  await ref.watch(stagesProvider.future);
  final stages = ref.watch(domainStagesProvider);
  final plan = ref.watch(currentTrekPlanProvider);
  final trace = await db.sessionTrackPointsDao.getByTrailId(trailId);

  // Nombre d'etapes du parcours choisi (jamais un total statique en dur) :
  // le plan si dispo, sinon la liste d'etapes du sentier.
  final totalStages = plan?.stageCount ?? stages.length;

  final completed = session?.completedStages ?? const <String>[];
  final completedSet = completed.toSet();

  // Distance / D+ REELS = somme des etapes REELLEMENT marchees. On mappe chaque
  // stageId marche sur l'etape du sentier correspondante (index par id).
  final Map<String, Stage> byId = {for (final s in stages) s.id: s};
  double distanceKm = 0;
  int elevationGainM = 0;
  for (final id in completedSet) {
    final s = byId[id];
    if (s == null) continue;
    distanceKm += s.distance;
    elevationGainM += s.elevationGain;
  }

  // Duree reelle : de startedAt a finishedAt (jours entames, minimum 1 des qu'au
  // moins une etape a ete marchee ou une session existe).
  final start = session?.startedAt;
  final end = session?.finishedAt;
  int durationDays = 0;
  if (start != null && end != null) {
    final days = end.difference(start).inDays + 1;
    durationDays = days < 1 ? 1 : days;
  } else if (session != null) {
    durationDays = 1;
  }

  return AdventureStats(
    stagesWalked: completedSet.length,
    totalStages: totalStages,
    distanceKm: distanceKm,
    elevationGainM: elevationGainM,
    startDate: start,
    endDate: end,
    durationDays: durationDays,
    fullyWalked: session?.parcoursFullyWalked ?? false,
    tracePoints: trace,
  );
});

/// Libelle « Integral / partiel » du parcours, derive de la session reelle.
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(3) : branche
/// [TrekCongratulations.partialLabel] via le plan de marche + l'etat reel.
///  * Parcours fini (finisher) sur un parcours ENTIER -> « Integral ».
///  * Sinon -> « partiel » (le libelle i18n final est choisi par l'UI selon
///    [TrekCompletionKind]).
///
/// Retourne le [TrekCongratulations] du plan courant (complet vs partiel) ou
/// null si aucun plan (pas d'etapes chargees). L'UI mappe [kind] -> libelle.
final adventureCongratulationsProvider = Provider<TrekCongratulations?>((ref) {
  final plan = ref.watch(currentTrekPlanProvider);
  if (plan == null) return null;
  return TrekCongratulations.forPlan(plan);
});
