/// Points du trace GPS, chacun portant sa session, son jour de marche et son
/// etape : une nouvelle rando n'efface plus la precedente.
library;

import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/session_track_points_table.dart';

part 'session_track_points_dao.g.dart';

/// L'ORIGINE d'un point de trace (lot 671-03), telle qu'elle est rangee dans
/// la colonne `source`.
enum TrackPointSource {
  /// Un releve reel du recepteur GPS.
  gps('gps'),

  /// Un point CALCULE le long du trace entre deux releves, a partir des pas.
  estimated('estime');

  const TrackPointSource(this.stored);

  /// La valeur rangee en base et dans le tampon de l'isolate de fond.
  final String stored;

  /// L'origine rangee sous [value]. LECTURE TOLERANTE : absente (point
  /// d'avant la v32, tampon d'une version precedente) ou inconnue, elle vaut
  /// un releve reel — c'est ce qu'etait tout point avant le lot 671-03.
  static TrackPointSource fromStored(String? value) =>
      value == estimated.stored ? estimated : gps;
}

/// CE QU'UNE LECTURE DE LA TRACE VEUT, DIT PAR CHAQUE APPELANT (lot 671-03).
///
/// LES POINTS ESTIMES SONT ENREGISTRES EN PLUS DES RELEVES, JAMAIS A LEUR
/// PLACE : le journal et le diplome gardent une trace dense sans depenser un
/// releve GPS, la derive se mesure gratuitement en comparant l'estime au
/// releve qui le suit, et une mesure peut toujours separer le vrai du calcule.
/// Mais ils CHANGERAIENT les chiffres du jour (distance, denivele) de toute
/// lecture qui les passe a `computeTrackStats`, et le changement d'entree des
/// statistiques est le lot 671-06, pas celui-ci.
///
/// D'OU CE PARAMETRE, OBLIGATOIRE ET SANS VALEUR PAR DEFAUT, sur chaque
/// lecture de points : la decision vit ici, en un seul endroit, et aucun
/// appelant ne peut lire des points estimes par accident. Un filtre implicite
/// serait un piege pour le prochain lot.
enum TrackPointsRead {
  /// Les seuls releves reels (origine `gps` ou nulle) : pour tout calcul de
  /// distance ou de denivele.
  gpsOnly,

  /// La trace dense, releves ET points estimes : pour dessiner la trace.
  withEstimated,
}

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
    await (delete(
      sessionTrackPoints,
    )..where((t) => t.trailId.equals(trailId))).go();
  }

  /// Efface le tracé d'UNE session (reprise d'un enregistrement raté).
  Future<void> clearSession(String sessionId) async {
    await (delete(
      sessionTrackPoints,
    )..where((t) => t.sessionId.equals(sessionId))).go();
  }

  /// Insère un point GPS du tracé en cours d'enregistrement.
  ///
  /// [sessionId], [dayIndex] et [stageId] sont optionnels : un appelant
  /// qui ne connaît pas le contexte enregistre quand même le point (il
  /// reste lisible par [getByTrailId]). [source] est OBLIGATOIRE (lot
  /// 671-03) : un écrivain qui oublierait de marquer un point estimé le
  /// ferait compter dans les chiffres du jour.
  Future<void> insertPoint({
    required String trailId,
    required double lat,
    required double lng,
    required double altitude,
    required TrackPointSource source,
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
        source: Value(source.stored),
      ),
    );
  }

  /// Le filtre d'origine de [read] : vrai pour tout point a garder.
  Expression<bool> _origin($SessionTrackPointsTable t, TrackPointsRead read) =>
      switch (read) {
        TrackPointsRead.withEstimated => const Constant(true),
        TrackPointsRead.gpsOnly =>
          t.source.isNull() |
              t.source.isNotValue(TrackPointSource.estimated.stored),
      };

  /// Tracé complet du sentier, toutes sessions confondues, dans l'ordre
  /// d'enregistrement ; [read] dit si les points estimés en font partie.
  Future<List<SessionTrackPoint>> getByTrailId(
    String trailId, {
    required TrackPointsRead read,
  }) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.trailId.equals(trailId) & _origin(t, read))
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.get();
  }

  /// Tracé d'UNE session de randonnée, dans l'ordre d'enregistrement ;
  /// [read] dit si les points estimés en font partie.
  Future<List<SessionTrackPoint>> getBySessionId(
    String sessionId, {
    required TrackPointsRead read,
  }) async {
    final query = select(sessionTrackPoints)
      ..where((t) => t.sessionId.equals(sessionId) & _origin(t, read))
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
    required TrackPointsRead read,
    String? sessionId,
  }) async {
    final query = select(sessionTrackPoints)
      ..where(
        (t) =>
            t.trailId.equals(trailId) &
            t.dayIndex.equals(dayIndex) &
            _origin(t, read),
      )
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
    required TrackPointsRead read,
    String? sessionId,
  }) async {
    final query = select(sessionTrackPoints)
      ..where(
        (t) =>
            t.trailId.equals(trailId) &
            t.stageId.equals(stageId) &
            _origin(t, read),
      )
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
    DateTime day, {
    required TrackPointsRead read,
  }) async {
    final from = DateTime(day.year, day.month, day.day);
    final to = from.add(const Duration(days: 1));
    final query = select(sessionTrackPoints)
      ..where(
        (t) =>
            t.trailId.equals(trailId) &
            t.recordedAt.isBiggerOrEqualValue(from) &
            t.recordedAt.isSmallerThanValue(to) &
            _origin(t, read),
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
