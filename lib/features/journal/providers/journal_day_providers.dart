/// Les journees du carnet, de la plus ancienne a la plus recente : une journee
/// existe des qu'elle porte une entree.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/recorded_track_stats.dart';
import '../../../core/geo/trace_point.dart';
import '../../../core/geo/track_segment_stats.dart';
import '../../map/map_facade.dart' show statsTraceProvider;
import '../../trek/trek_facade.dart'
    show cadenceDesRelevesSimulesProvider, sourceDesRelevesProvider;
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
/// TACHE 742 — ET EN DEMO, UNE JOURNEE MARCHEE EST UNE JOURNEE DU CARNET.
///
/// CE QUI MANQUAIT, MESURE. Les journees du journal viennent des ENTREES du
/// carnet. Or une demo n'ecrit aucune entree (tache 634, « rien en base ») :
/// la liste restait donc VIDE, [journalSelectedDayProvider] rendait `null`, et
/// la trace du jour comme les chiffres du jour rendaient le vide AVANT MEME de
/// chercher un releve. Brancher la source des releves sans corriger cela
/// n'aurait rien change a l'ecran : c'etait le deuxieme verrou, et le premier
/// dans l'ordre.
///
/// Une journee ou l'on a marche existe, meme sans note — c'est vrai en vrai, et
/// en demo c'est la seule qu'il y ait. Hors demo, `journeesEnMemoire()` rend
/// une liste vide et ce provider se comporte EXACTEMENT comme avant.
final journalDaysProvider = Provider<List<DateTime>>((ref) {
  final entries = ref.watch(journalScreenProvider.select((s) => s.entries));
  final days = <DateTime>{};
  for (final e in entries) {
    days.add(journalDayOf(e.createdAt));
  }
  days.addAll(ref.watch(sourceDesRelevesProvider).journeesEnMemoire());
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
  final ofDay = entries.where((e) => journalDayOf(e.createdAt) == day).toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  return ofDay;
});

/// Trace GPS de la journee affichee (correctif L4-2).
///
/// Depend du socle L3-1 : avant lui, la table de trace n'etait indexee que
/// par sentier et etait EFFACEE a chaque nouvelle randonnee — la trace
/// d'une journee passee n'existait tout simplement plus.
final journalDayTraceProvider = FutureProvider<List<SessionTrackPoint>>((
  ref,
) async {
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const <SessionTrackPoint>[];
  final trailId = ref.watch(trailIdProvider);
  // TACHE 742 : la base en vrai, la memoire du marcheur simule en demo. Le
  // signal de cadence fait relire la trace a chaque pas simule — sans lui elle
  // resterait figee a l'instant ou l'ecran s'est ouvert.
  ref.watch(cadenceDesRelevesSimulesProvider);
  // La trace DENSE, points estimes compris (lot 671-03) : elle se dessine.
  // Les chiffres de la journee, eux, se lisent a part, sur les seuls releves
  // reels ([journalDayStatsProvider]).
  return ref
      .watch(sourceDesRelevesProvider)
      .parJourCalendaire(trailId, day, read: TrackPointsRead.withEstimated);
});

/// Chiffres d'une journee de marche, mesures sur la trace GPS.
///
/// Le calcul a ete FACTORISE au lot L5-5, quand le recapitulatif d'aventure
/// a eu besoin exactement des memes chiffres : deux implantations auraient
/// fini par donner deux valeurs differentes pour la meme journee. Le journal
/// garde ses noms d'origine, le socle vit dans [TrackSegmentStats].
typedef JournalDayStats = TrackSegmentStats;

/// Calcule les chiffres d'une journee : sur la tranche de [trace] que ses
/// releves reels [points] bornent et datent (lot 671-06), sur les releves
/// eux-memes sans trace (cf. [computeTrackStatsOnTrace]).
JournalDayStats computeDayStats(
  List<SessionTrackPoint> points, {
  List<TrackPoint>? trace,
}) => computeTrackStatsOnTrace(readings: points, trace: trace);

/// Chiffres de la journee affichee (correctif L4-3).
///
/// LOT 671-03 : bornes et duree sur les SEULS RELEVES REELS, et non sur la
/// trace dessinee : un point estime ne date ni ne borne rien.
///
/// LOT 671-06 : distance et denivele SUR LE TRACE, entre le premier et le
/// dernier releve reel de la journee, projetes. LE PERIMETRE NE CHANGE PAS :
/// la journee CIVILE, de minuit a minuit, celle de [getByCalendarDay].
final journalDayStatsProvider = FutureProvider<JournalDayStats>((ref) async {
  // La trace dessinee reste la source de rafraichissement (meme journee,
  // memes invalidations) ; les chiffres se relisent sur les releves seuls.
  await ref.watch(journalDayTraceProvider.future);
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const JournalDayStats();
  final trailId = ref.watch(trailIdProvider);
  final trace = ref.watch(statsTraceProvider.future);
  // TACHE 742 : meme [computeDayStats] qu'avant, entree differente en demo.
  final points = await ref
      .watch(sourceDesRelevesProvider)
      .parJourCalendaire(trailId, day, read: TrackPointsRead.gpsOnly);
  return computeDayStats(points, trace: await trace);
});

/// Cumul depuis le depart, jusqu'a la journee affichee INCLUSE (L4-3).
///
/// Se calcule journee par journee et non sur la trace entiere : additionner
/// des journees distinctes evite de compter le trajet qui relie le dernier
/// point d'un soir au premier point du lendemain matin (souvent un transfert
/// en voiture, parfois des dizaines de kilometres).
///
/// LOT 671-06 : chaque journee du cumul se calcule comme la journee affichee,
/// sur sa tranche de trace — le cumul du premier jour est le chiffre du jour.
final journalCumulativeStatsProvider = FutureProvider<JournalDayStats>((
  ref,
) async {
  final day = ref.watch(journalSelectedDayProvider);
  if (day == null) return const JournalDayStats();
  final trailId = ref.watch(trailIdProvider);
  final traceFuture = ref.watch(statsTraceProvider.future);
  // Les seuls releves reels : un cumul de chiffres (lot 671-03).
  // TACHE 742 : la base en vrai, la memoire en demo — le cumul se calcule
  // ensuite exactement de la meme facon, journee par journee.
  final all = await ref
      .watch(sourceDesRelevesProvider)
      .parSentier(trailId, read: TrackPointsRead.gpsOnly);
  final trace = await traceFuture;

  final byDay = <DateTime, List<SessionTrackPoint>>{};
  for (final p in all) {
    final k = journalDayOf(p.recordedAt);
    if (k.isAfter(day)) continue;
    byDay.putIfAbsent(k, () => <SessionTrackPoint>[]).add(p);
  }
  var total = const JournalDayStats();
  for (final points in byDay.values) {
    total = total.plus(computeDayStats(points, trace: trace));
  }
  return total;
});
