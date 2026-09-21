import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/session_track_points_table.dart';

part 'session_track_points_dao.g.dart';

/// DAO des tracés GPS enregistrés sur un sentier.
///
/// SOCLE L3-1 (conformité cycle 4) — le tracé n'est PLUS effacé au
/// démarrage d'une session : chaque point porte sa session, son jour de
/// marche et son étape. On peut donc relire le tracé du jour 3 alors
/// qu'on marche le jour 5, et une nouvelle randonnée n'efface plus la
/// précédente. [clearTrail] reste disponible pour l'effacement VOULU
/// (purge de confidentialité, réinitialisation), jamais pour un start.
///
/// Les points sont insérés au fil de l'eau pendant l'enregistrement
/// (robuste à un arrêt brutal de l'app).
@DriftAccessor(tables: [SessionTrackPoints])
class SessionTrackPointsDao extends DatabaseAccessor<AppDatabase>
    with _$SessionTrackPointsDaoMixin {
  SessionTrackPointsDao(super.db);

  /// Numéro du jour de marche de [at] pour une randonnée partie le [startedAt].
  ///
  /// 1 = jour du départ. Le calcul se fait sur les dates CALENDAIRES
  /// (minuit à minuit) et non sur un écart de 24 h : un départ à 17 h et
  /// une arrivée le lendemain à 9 h font bien deux jours de marche, et
  /// un changement d'heure ne décale pas la numérotation.
  /// Jamais inférieur à 1 (un point antidaté reste au jour 1).
  static int dayIndexFor(DateTime startedAt, DateTime at) {
    final start = DateTime(startedAt.year, startedAt.month, startedAt.day);
    final day = DateTime(at.year, at.month, at.day);
    final diff = day.difference(start).inDays;
    return diff < 0 ? 1 : diff + 1;
  }

  /// Efface TOUT le tracé du sentier — effacement VOULU uniquement.
  ///
  /// NE PAS appeler au démarrage d'une session : c'était le défaut
  /// corrigé par L3-1 (la randonnée en cours effaçait la précédente).
  Future<void> clearTrail(String trailId) async {
    await (delete(sessionTrackPoints)
          ..where((t) => t.trailId.equals(trailId)))
        .go();
  }

  /// Efface le tracé d'UNE session (reprise d'un enregistrement raté).
  Future<void> clearSession(String sessionId) async {
    await (delete(sessionTrackPoints)
          ..where((t) => t.sessionId.equals(sessionId)))
        .go();
  }

  /// Insère un point GPS du tracé en cours d'enregistrement.
  ///
  /// [sessionId], [dayIndex] et [stageId] sont optionnels : un appelant
  /// qui ne connaît pas le contexte enregistre quand même le point (il
  /// reste lisible par [getByTrailId]).
  Future<void> insertPoint({
    required String trailId,
    required double lat,
    required double lng,
    required double altitude,
    DateTime? recordedAt,
    String? sessionId,
    int? dayIndex,
    String? stageId,
  }) async {
    await into(sessionTrackPoints).insert(
      SessionTrackPointsCompanion.insert(
        trailId: trailId,
        lat: lat,
        lng: lng,
        altitude: altitude,
        recordedAt: recordedAt ?? DateTime.now(),
        sessionId: Value(sessionId),
        dayIndex: Value(dayIndex),
        stageId: Value(stageId),
      ),
    );
  }

  /// Tracé complet du sentier, toutes sessions confondues, dans l'ordre
  /// d'enregistrement.
  Future<List<SessionTrackPoint>> getByTrailId(String trailId) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.trailId.equals(trailId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  /// Tracé d'UNE session de randonnée, dans l'ordre d'enregistrement.
  Future<List<SessionTrackPoint>> getBySessionId(String sessionId) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.sessionId.equals(sessionId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  /// Tracé d'UN jour de marche du sentier (1 = jour du départ).
  ///
  /// [sessionId] restreint à une randonnée précise ; sans lui, le jour N
  /// de toutes les randonnées du sentier est retourné.
  Future<List<SessionTrackPoint>> getByDayIndex(
    String trailId,
    int dayIndex, {
    String? sessionId,
  }) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.trailId.equals(trailId) & t.dayIndex.equals(dayIndex))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (sessionId != null) {
      query.where((t) => t.sessionId.equals(sessionId));
    }
    return query.get();
  }

  /// Tracé d'UNE étape du sentier, dans l'ordre d'enregistrement.
  Future<List<SessionTrackPoint>> getByStageId(
    String trailId,
    String stageId, {
    String? sessionId,
  }) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.trailId.equals(trailId) & t.stageId.equals(stageId))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    if (sessionId != null) {
      query.where((t) => t.sessionId.equals(sessionId));
    }
    return query.get();
  }

  /// Tracé d'une JOURNÉE CALENDAIRE (minuit à minuit), dans l'ordre
  /// d'enregistrement.
  ///
  /// Utilisé par le journal, qui groupe ses entrées par date réelle et
  /// non par numéro de jour de marche.
  Future<List<SessionTrackPoint>> getByCalendarDay(
    String trailId,
    DateTime day,
  ) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final query = select(sessionTrackPoints)
      ..where(
        (t) =>
            t.trailId.equals(trailId) &
            t.recordedAt.isBiggerOrEqualValue(from) &
            t.recordedAt.isSmallerThanValue(to),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  /// Numéros de jours de marche qui portent au moins un point, triés.
  ///
  /// Alimente le navigateur par jour (journal, détail du récap).
  Future<List<int>> getRecordedDayIndexes(String trailId) async {
    final query = selectOnly(sessionTrackPoints, distinct: true)
      ..addColumns([sessionTrackPoints.dayIndex])
      ..where(
        sessionTrackPoints.trailId.equals(trailId) &
            sessionTrackPoints.dayIndex.isNotNull(),
      )
      ..orderBy([OrderingTerm.asc(sessionTrackPoints.dayIndex)]);
    final rows = await query.get();
    return rows
        .map((r) => r.read(sessionTrackPoints.dayIndex))
        .whereType<int>()
        .toList();
  }
}
