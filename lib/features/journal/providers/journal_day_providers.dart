import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/geo_utils.dart';
import '../../../core/providers/database_provider.dart';
import '../../trek/domain/trek_stats.dart';
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
class JournalDayStats {
  const JournalDayStats({
    this.distanceKm = 0,
    this.elevationGainM = 0,
    this.elevationLossM = 0,
    this.duration = Duration.zero,
    this.maxAltitudeM,
    this.pointCount = 0,
  });

  /// Distance MESUREE au GPS (et non une somme d'etapes nominale).
  final double distanceKm;
  final int elevationGainM;
  final int elevationLossM;

  /// Ecart entre le premier et le dernier point de la journee.
  final Duration duration;

  /// Point le plus haut de la journee, `null` sans trace.
  final double? maxAltitudeM;

  /// Nombre de points GPS derriere ces chiffres (0 = rien a afficher).
  final int pointCount;

  bool get hasData => pointCount > 1;

  /// Somme de deux journees (pour le cumul depuis le depart).
  JournalDayStats plus(JournalDayStats other) => JournalDayStats(
        distanceKm: distanceKm + other.distanceKm,
        elevationGainM: elevationGainM + other.elevationGainM,
        elevationLossM: elevationLossM + other.elevationLossM,
        duration: duration + other.duration,
        maxAltitudeM: switch ((maxAltitudeM, other.maxAltitudeM)) {
          (null, final b) => b,
          (final a, null) => a,
          (final a?, final b?) => a > b ? a : b,
        },
        pointCount: pointCount + other.pointCount,
      );
}

/// Calcule les chiffres d'une suite de points GPS.
///
/// Reutilise [GeoUtils.haversineDistance] et le SEUIL DE BRUIT de
/// [TrekStats] (3 m) : sans ce seuil, le tremblement de l'altimetre
/// fabrique plusieurs centaines de metres de denivele sur une journee
/// plate. Aucun moteur de stats n'est reconstruit ici.
JournalDayStats computeDayStats(List<SessionTrackPoint> points) {
  if (points.length < 2) {
    return JournalDayStats(
      pointCount: points.length,
      maxAltitudeM: points.isEmpty ? null : points.first.altitude,
    );
  }
  var meters = 0.0;
  var gain = 0.0;
  var loss = 0.0;
  var maxAlt = points.first.altitude;
  for (var i = 1; i < points.length; i++) {
    final prev = points[i - 1];
    final cur = points[i];
    meters += GeoUtils.haversineDistance(prev.lat, prev.lng, cur.lat, cur.lng);
    final d = cur.altitude - prev.altitude;
    if (d.abs() >= TrekStats.elevationNoiseThresholdM) {
      if (d > 0) {
        gain += d;
      } else {
        loss += -d;
      }
    }
    if (cur.altitude > maxAlt) maxAlt = cur.altitude;
  }
  return JournalDayStats(
    distanceKm: meters / 1000.0,
    elevationGainM: gain.round(),
    elevationLossM: loss.round(),
    duration: points.last.recordedAt.difference(points.first.recordedAt),
    maxAltitudeM: maxAlt,
    pointCount: points.length,
  );
}

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
