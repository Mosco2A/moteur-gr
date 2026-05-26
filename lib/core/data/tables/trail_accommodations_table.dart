import 'package:drift/drift.dart';

/// Table des hebergements par etape (Phase 4 Drift v7).
///
/// Refuges, gites, hotels rattaches a une etape.
/// Noms i18n aplatis : nameFr, nameEn, nameDe, nameIt, nameEs.
class TrailAccommodations extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_stages.id
  TextColumn get stageId => text()();

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

  /// Type d'hebergement (refuge, gite, hotel, camping, bivouac)
  TextColumn get type => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Telephone (nullable)
  TextColumn get phone => text().nullable()();

  /// Email (nullable)
  TextColumn get email => text().nullable()();

  /// Site web (nullable)
  TextColumn get website => text().nullable()();

  /// Capacite d'accueil (nullable)
  IntColumn get capacity => integer().nullable()();

  /// Fourchette de prix (nullable, ex: '30-50EUR')
  TextColumn get priceRange => text().nullable()();

  /// URL de reservation (nullable)
  TextColumn get bookingUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
