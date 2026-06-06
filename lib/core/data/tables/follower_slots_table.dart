import 'package:drift/drift.dart';

/// Table Drift des slots de suiveur (Phase 4 E4.10).
///
/// Chaque slot represente un proche qui suit le randonneur.
/// 2 slots gratuits par session (#81759), au-dela pub ou paiement.
/// Le nom de ligne genere est suffixe `Row` pour ne pas entrer
/// en collision avec le modele Freezed [FollowerSlot].
@DataClassName('FollowerSlotRow')
class FollowerSlots extends Table {
  /// Identifiant unique (UUID)
  TextColumn get id => text()();

  /// Reference vers la session de suivi
  TextColumn get sessionId => text()();

  /// Nom du suiveur
  TextColumn get followerName => text()();

  /// Slot paye (pass web ou app complementaire)
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();

  /// Slot supporte par la publicite (3eme suiveur et plus)
  BoolColumn get adSupported => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
