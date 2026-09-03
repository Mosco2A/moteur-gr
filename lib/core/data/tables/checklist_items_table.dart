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

  /// Poids unitaire en grammes (parite GR20 « Materiel & Sac », migration v19).
  ///
  /// Initialise depuis le poids de reference du template ; editable par
  /// l'utilisateur. Alimente la jauge poids du sac (total = somme des items
  /// coches). 0 = non pese / porte (ne contribue pas au total).
  IntColumn get weightGrams => integer().withDefault(const Constant(0))();

  /// Quantite de l'article (parite GR20, migration v20). Min 1. Le poids total
  /// d'un article coche = weightGrams * quantity.
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  /// Article personnalise ajoute par l'utilisateur (parite GR20, migration v20).
  ///
  /// true = article cree via « Ajouter un item » (nom editable, supprimable).
  /// false = article du template (nom en lecture seule, non supprimable).
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();

  /// Article ajoute a la liste de courses (parite GR20, migration v20).
  BoolColumn get inShoppingList =>
      boolean().withDefault(const Constant(false))();

  /// Nom d'un article personnalise (parite GR20, migration v20).
  ///
  /// null pour les articles du template (nom resolu via i18n depuis itemId).
  TextColumn get customName => text().nullable()();

  /// Date de derniere modification
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
