import 'package:drift/drift.dart';

/// Table des points GPS des tracés enregistrés sur un sentier.
///
/// Alimentée au fil de l'eau par le tracking GPS (TrackingNotifier et
/// TrekSessionManagerNotifier). Lue par le récap diplôme, le journal
/// (tracé du jour) et l'export GPX.
///
/// SOCLE L3-1 (conformité cycle 4) — la table portait auparavant le seul
/// `trailId`, et le tracé était EFFACÉ au démarrage de chaque session.
/// Conséquences corrigées ici :
///  * `sessionId` — plusieurs randonnées successives sur le même sentier
///    cohabitent, la nouvelle n'écrase plus la précédente ;
///  * `dayIndex` — numéro de jour de marche (1 = jour du départ), pour
///    afficher le tracé du jour 3 alors qu'on marche le jour 5 ;
///  * `stageId` — étape parcourue au moment du point, pour le détail
///    étape par étape du récap.
///
/// Les trois colonnes sont NULLABLES : les points enregistrés avant la
/// migration v26 (et ceux d'un appel qui ne connaît pas le contexte)
/// restent lisibles et exploitables par [getByTrailId].
/// Créée en migration v13, enrichie en migration v26.
///
/// LOT 671-03 — la colonne `source` dit l'ORIGINE du point : `gps` pour un
/// relevé réel, `estime` pour un point calculé le long du tracé entre deux
/// relevés (le recalage sur le tracé). NULLABLE, sur le motif exact des trois
/// colonnes de la v26 : les points enregistrés avant la migration v32 restent
/// lisibles et valent des relevés réels, et un retour à la v31 ne perd aucun
/// point, seulement leur origine. Enrichie en migration v32.
class SessionTrackPoints extends Table {
  /// Clé primaire auto-incrémentée (ordre d'enregistrement)
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (TrailConfig.id)
  TextColumn get trailId => text()();

  /// Identifiant de la session de randonnée (TrekSession.id).
  ///
  /// Null pour les points antérieurs à la migration v26.
  TextColumn get sessionId => text().nullable()();

  /// Numéro du jour de marche, 1 pour le jour du départ.
  ///
  /// Calculé en jours calendaires depuis `TrekSession.startedAt`
  /// (cf. `SessionTrackPointsDao.dayIndexFor`). Null si inconnu.
  IntColumn get dayIndex => integer().nullable()();

  /// Identifiant de l'étape parcourue au moment du point (Stage.id).
  ///
  /// Null hors étape connue (détection d'étape non encore établie).
  TextColumn get stageId => text().nullable()();

  /// Latitude WGS84
  RealColumn get lat => real()();

  /// Longitude WGS84
  RealColumn get lng => real()();

  /// Altitude en mètres
  RealColumn get altitude => real()();

  /// Horodatage d'enregistrement du point
  DateTimeColumn get recordedAt => dateTime()();

  /// Origine du point : `gps` (relevé réel) ou `estime` (calculé sur le
  /// tracé), cf. `TrackPointSource`.
  ///
  /// Null pour les points antérieurs à la migration v32 : ce sont des
  /// relevés réels, et toute lecture les traite comme tels.
  TextColumn get source => text().nullable()();
}
