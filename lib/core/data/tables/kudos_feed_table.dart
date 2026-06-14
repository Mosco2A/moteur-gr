import 'package:drift/drift.dart';

/// Table des kudos en file offline-first (F7B-01, Phase 7 social).
///
/// Un kudo est un "j'encourage" pose par un utilisateur sur une activite du
/// fil. Il est ecrit d'abord EN LOCAL (`syncState=pending`) puis pousse vers
/// Firestore au retour du reseau (KudosService F7B-02, sync differee R2).
/// L'idempotence (1 seul kudo par (fromUidHash, targetActivityId)) est portee
/// par le service + les regles (F7B-03) : la cle distante = hash(from+target).
///
/// [fromUidHash] est l'UID HACHE (jamais de PII, #85383).
/// Ajoutee en migration v16.
class KudosLocal extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant de l'activite ciblee par le kudo.
  TextColumn get targetActivityId => text()();

  /// UID HACHE de l'auteur du kudo (jamais de PII #85383).
  TextColumn get fromUidHash => text()();

  /// Date de creation locale (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Etat de synchronisation ('pending', 'synced', 'failed').
  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();

  /// Nombre de tentatives de synchronisation echouees.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Derniere erreur de synchronisation (nullable).
  TextColumn get lastError => text().nullable()();
}

/// Cache local du fil d'activite (F7B-01, Phase 7 social).
///
/// Le fil se LIT depuis ce cache (offline-first, R2). Chaque entree porte un
/// [moderationState] (hebergeur DSA art. 16, design Securite D4) : les
/// activites 'removed' sont masquees a la lecture. [authorUidHash] est l'UID
/// HACHE (pas de PII #85383). [payload] est une charge JSON (type d'activite).
/// Ajoutee en migration v16.
class ActivityFeedCache extends Table {
  /// Identifiant de l'activite (fourni serveur, stable).
  TextColumn get id => text()();

  /// Type d'activite ('segment_effort', 'badge', 'defi', ...).
  TextColumn get type => text()();

  /// UID HACHE de l'auteur de l'activite (jamais de PII #85383).
  TextColumn get authorUidHash => text()();

  /// Charge utile JSON de l'activite (details d'affichage).
  TextColumn get payload => text().nullable()();

  /// Date de creation de l'activite (UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Etat de moderation ('visible', 'flagged', 'removed'). Defaut 'visible'.
  TextColumn get moderationState =>
      text().withDefault(const Constant('visible'))();

  @override
  Set<Column> get primaryKey => {id};
}
