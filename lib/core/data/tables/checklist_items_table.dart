import 'package:drift/drift.dart';

/// Table des items de checklist materiel.
///
/// Chaque ligne represente un item coche ou non coche
/// pour un sentier donne. Ajoutee en migration v4.
class ChecklistItems extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr10')
  TextColumn get trailId => text()();

  /// Identifiant unique de l'item (ex: 'backpack')
  TextColumn get itemId => text()();

  /// Categorie de l'item (ex: 'equipment', 'clothing')
  TextColumn get category => text()();

  /// Item coche ou non
  BoolColumn get isChecked =>
      boolean().withDefault(const Constant(false))();

  /// Date de derniere modification
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
