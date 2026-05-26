import 'package:drift/drift.dart';

/// Table des itineraires d'un sentier (Phase 4 Drift v7).
///
/// Un sentier peut avoir plusieurs itineraires (Nord-Sud, Sud-Nord, etc.).
/// Noms i18n aplatis : nameFr, nameEn, nameDe, nameIt, nameEs.
class TrailItineraries extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_meta.id
  TextColumn get trailId => text()();

  /// Code de l'itineraire (ex: 'ns', 'sn')
  TextColumn get code => text()();

  /// Nom en francais
  TextColumn get nameFr => text()();

  /// Nom en anglais
  TextColumn get nameEn => text()();

  /// Nom en allemand
  TextColumn get nameDe => text()();

  /// Nom en italien
  TextColumn get nameIt => text()();

  /// Nom en espagnol
  TextColumn get nameEs => text()();

  /// Distance totale en kilometres
  RealColumn get distanceKm => real()();

  /// Denivele positif total en metres
  IntColumn get elevationGain => integer()();

  /// Nombre d'etapes
  IntColumn get stageCount => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
