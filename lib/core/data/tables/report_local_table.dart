import 'package:drift/drift.dart';

/// Table des signalements terrain en file offline-first (F6C-01, Phase 6).
///
/// Chaque ligne est un signalement cree EN LOCAL d'abord (obstacle, eau a sec,
/// danger), horodate et geolocalise, puis pousse vers Firestore au retour du
/// reseau (sync differee, voir SignalementService F6C-02). Colonne vertebrale
/// offline-first (S-1) : l'app fonctionne 100 % hors-ligne.
/// Ajoutee en migration v14.
class ReportLocal extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Type de signalement ('obstacle', 'eau_a_sec', 'danger').
  TextColumn get type => text()();

  /// Latitude du signalement (degres decimaux).
  RealColumn get latitude => real()();

  /// Longitude du signalement (degres decimaux).
  RealColumn get longitude => real()();

  /// Date de creation locale (ISO 8601 UTC).
  DateTimeColumn get createdAt => dateTime()();

  /// Charge utile JSON optionnelle (details du signalement).
  TextColumn get payload => text().nullable()();

  /// Etat de synchronisation ('pending', 'synced', 'failed').
  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();

  /// Identifiant Firestore distant une fois synchronise (nullable).
  TextColumn get remoteId => text().nullable()();

  /// Nombre de tentatives de synchronisation echouees.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Derniere erreur de synchronisation (nullable).
  TextColumn get lastError => text().nullable()();
}
