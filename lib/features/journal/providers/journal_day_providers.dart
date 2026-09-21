import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/track_segment_stats.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/models/journal_entry.dart';
import 'journal_providers.dart';

// ---------------------------------------------------------------------------
// Journal — navigation PAR JOUR (correctifs L4-1, L4-2, L4-3).
//
// Avant ce lot, l'ecran journal deroulait toutes les entrees de toutes les
// journees dans une seule liste : aucune notion de jour selectionne, donc
// ni trace du jour, ni resume chiffre du jour. Ces providers posent cette
// notion une fois pour toutes ; l'ecran ne fait que les lire.
// ---------------------------------------------------------------------------

/// Ramene un horodatage a sa journee calendaire (minuit local).
DateTime journalDayOf(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

/// Journees du journal, de la PLUS ANCIENNE a la plus recente.
///
/// Une journee existe des qu'elle porte au moins une entree. L'ordre
/// croissant est celui de la marche : le navigateur avance dans le temps
/// quand on appuie sur la fleche droite.
final journalDaysProvider = Provider<List<DateTime>>((ref) {
  final entries = ref.watch(journalScreenProvider.select((s) => s.entries));
  final days = <DateTime>{};
  for (final e in entries) {
    days.add(journalDayOf(e.createdAt));
  }
  final list = days.toList()..sort();
  return list;
});

/// Journee choisie par l'utilisateur, `null` tant qu'il n'a rien choisi.
///
/// Volontairement separe de [journalSelectedDayProvider] : ce notifier ne
/// porte que l'INTENTION de l'utilisateur. La journee reellement affichee
/// est derivee, pour rester valide si l'entree choisie est supprimee.
class JournalSelectedDayNotifier extends Notifier<DateTime?> {
  @override
  DateTime? build() => null;

  /// Choisit explicitement une journee.
  void select(DateTime day) => state = journalDayOf(day);

  /// Revient a la journee par defaut (la plus recente).
  void reset() => state = null;
}

final journalSelectedDayRawProvider =
    NotifierProvider<JournalSelectedDayNotifier, DateTime?>(
  JournalSelectedDayNotifier.new,
);

/// Journee REELLEMENT affichee.
///
/// La journee choisie si elle porte encore des entrees, sinon la plus
/// recente. `null` quand le journal est vide. Ce repli evite l'ecran blanc
/// quand la derniere note d'une journee vient d'etre supprimee.
final journalSelectedDayProvider = Provider<DateTime?>((ref) {
  final days = ref.watch(journalDaysProvider);
  if (days.isEmpty) return null;
  final chosen = ref.watch(journalSelectedDayRawProvider);
  if (chosen != null && days.contains(chosen)) return chosen;
  return days.last;
});

/// Position de la journee affichee dans [journalDaysProvider] (0 si vide).
final journalSelectedDayIndexProvider = Provider<int>((ref) {
  final days = ref.watch(journalDaysProvider);
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return 0;
  final i = days.indexOf(day);
  return i < 0 ? 0 : i;
});

/// Entrees de la journee affichee, de la plus ancienne a la plus recente.
final journalEntriesOfDayProvider = Provider<List<JournalEntryModel>>((ref) {
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const <JournalEntryModel>[];
  final entries = ref.watch(journalScreenProvider.select((s) => s.entries));
  final ofDay = entries
      .where((e) => journalDayOf(e.createdAt) == day)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return ofDay;
});

/// Trace GPS de la journee affichee (correctif L4-2).
///
/// Depend du socle L3-1 : avant lui, la table de trace n'etait indexee que
/// par sentier et etait EFFACEE a chaque nouvelle randonnee — la trace
/// d'une journee passee n'existait tout simplement plus.
final journalDayTraceProvider =
    FutureProvider<List<SessionTrackPoint>>((ref) async {
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const <SessionTrackPoint>[];
  final trailId = ref.watch(trailIdProvider);
  final db = ref.watch(databaseProvider);
  return db.sessionTrackPointsDao.getByCalendarDay(trailId, day);
});

/// Chiffres d'une journee de marche, mesures sur la trace GPS.
///
/// Le calcul a ete FACTORISE au lot L5-5, quand le recapitulatif d'aventure
/// a eu besoin exactement des memes chiffres : deux implantations auraient
/// fini par donner deux valeurs differentes pour la meme journee. Le journal
/// garde ses noms d'origine, le socle vit dans [TrackSegmentStats].
typedef JournalDayStats = TrackSegmentStats;

/// Calcule les chiffres d'une suite de points GPS (cf. [computeTrackStats]).
JournalDayStats computeDayStats(List<SessionTrackPoint> points) =>
    computeTrackStats(points);

/// Chiffres de la journee affichee (correctif L4-3).
final journalDayStatsProvider = FutureProvider<JournalDayStats>((ref) async {
  final points = await ref.watch(journalDayTraceProvider.future);
  return computeDayStats(points);
});

/// Cumul depuis le depart, jusqu'a la journee affichee INCLUSE (L4-3).
///
/// Se calcule journee par journee et non sur la trace entiere : additionner
/// des journees distinctes evite de compter le trajet qui relie le dernier
/// point d'un soir au premier point du lendemain matin (souvent un transfert
/// en voiture, parfois des dizaines de kilometres).
final journalCumulativeStatsProvider =
    FutureProvider<JournalDayStats>((ref) async {
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const JournalDayStats();
  final trailId = ref.watch(trailIdProvider);
  final db = ref.watch(databaseProvider);
  final all = await db.sessionTrackPointsDao.getByTrailId(trailId);

  final byDay = <DateTime, List<SessionTrackPoint>>{};
  for (final p in all) {
    final k = journalDayOf(p.recordedAt);
    if (k.isAfter(day)) continue;
    byDay.putIfAbsent(k, () => <SessionTrackPoint>[]).add(p);
  }
  var total = const JournalDayStats();
  for (final points in byDay.values) {
    total = total.plus(computeDayStats(points));
  }
  return total;
});
