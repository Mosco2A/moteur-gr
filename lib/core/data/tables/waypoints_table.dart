import 'package:drift/drift.dart';

/// Table des waypoints terrain (F8A-01, Phase 8 donnees/communaute).
///
/// Un waypoint est un point d'interet pratique du sentier facon FarOut :
/// eau, ravitaillement, danger, camp, connectivite, jonction. Il est mis en
/// cache LOCAL (offline-first, design D3 #86163) et lu hors-ligne. Les
/// waypoints 'officiel' proviennent des donnees sentier ; les waypoints
/// 'communaute' sont remontes par les utilisateurs (sync differee, hors lot
/// F8A-01 qui ne fait que la couche Drift + DAO).
/// Ajoutee en migration v17.
class Waypoint extends Table {
  /// Identifiant stable du waypoint (fourni serveur/seed).
  TextColumn get id => text()();

  /// Identifiant du sentier auquel appartient le waypoint.
  TextColumn get trailId => text()();

  /// Type de waypoint : 'eau', 'ravitaillement', 'danger', 'camp',
  /// 'connectivite', 'jonction'.
  TextColumn get type => text()();

  /// Latitude du waypoint (degres decimaux).
  RealColumn get latitude => real()();

  /// Longitude du waypoint (degres decimaux).
  RealColumn get longitude => real()();

  /// Titre court affiche du waypoint.
  TextColumn get titre => text()();

  /// Date de derniere mise a jour (UTC).
  DateTimeColumn get lastUpdatedAt => dateTime()();

  /// Source du waypoint : 'officiel' ou 'communaute'.
  TextColumn get source =>
      text().withDefault(const Constant('officiel'))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des commentaires de waypoint en file offline-first (F8A-01).
///
/// Un commentaire est ecrit EN LOCAL d'abord (`syncState=pending`) puis pousse
/// vers le backend au retour du reseau (sync differee, hors lot F8A-01).
/// La lecture est offline-first : [visibleComments] masque les commentaires
/// 'removed' (hebergeur DSA art. 16, design Securite D4). [authorUidHash] est
/// l'UID HACHE en SHA-256 (jamais de PII, #85383). [condition] precise un etat
/// terrain optionnel (ex : 'eau_a_sec', 'eau_coule_fort').
/// Ajoutee en migration v17.
class WaypointComment extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du waypoint commente.
  TextColumn get waypointId => text()();

  /// UID HACHE en SHA-256 de l'auteur (jamais de PII, #85383).
  TextColumn get authorUidHash => text()();

  /// Texte du commentaire.
  TextColumn get texte => text()();

  /// Condition terrain optionnelle (ex : 'eau_a_sec', 'eau_coule_fort').
  TextColumn get condition => text().nullable()();

  /// Date de creation locale (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Etat de moderation ('visible', 'flagged', 'removed'). Defaut 'visible'.
  TextColumn get moderationState =>
      text().withDefault(const Constant('visible'))();

  /// Etat de synchronisation ('pending', 'synced', 'failed').
  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();
}
