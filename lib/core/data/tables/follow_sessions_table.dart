import 'package:drift/drift.dart';

/// Table Drift des sessions de suivi temps reel (Phase 4 E4.10).
///
/// Chaque session est creee par un randonneur et identifiee
/// par un shareCode unique de 6 caracteres alphanumeriques.
/// Le nom de ligne genere est suffixe `Row` pour ne pas entrer
/// en collision avec le modele Freezed [FollowSession].
@DataClassName('FollowSessionRow')
class FollowSessions extends Table {
  /// Identifiant unique (UUID)
  TextColumn get id => text()();

  /// UID (anonymise) du randonneur suivi
  TextColumn get trekkerUserId => text()();

  /// Code de partage unique (6 caracteres alphanum)
  TextColumn get shareCode => text().unique()();

  /// Date de creation (ISO 8601)
  TextColumn get createdAt => text()();

  /// Date d expiration (ISO 8601)
  TextColumn get expiresAt => text()();

  /// Session active ou terminee
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
