import 'package:drift/drift.dart';

/// Table des entrées de journal de trek.
///
/// Chaque ligne représente une note ou photo du randonneur
/// pour un sentier et une étape donnés. Ajoutée en migration v3.
class JournalEntries extends Table {
  /// Clé primaire auto-incrémentée
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr20')
  TextColumn get trailId => text()();

  /// Numéro d'étape (1-based)
  IntColumn get stageNumber => integer()();

  /// Contenu textuel de la note
  TextColumn get content => text().withDefault(const Constant(''))();

  /// Chemin local de la photo (null si note sans photo)
  TextColumn get photoPath => text().nullable()();

  /// Taille de la photo en octets (pour vérifier compression < 500 Ko)
  IntColumn get photoSizeBytes => integer().nullable()();

  /// Date de création de l'entrée
  DateTimeColumn get createdAt => dateTime()();

  /// Date de dernière modification
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
