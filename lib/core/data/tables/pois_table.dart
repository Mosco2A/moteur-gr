import 'package:drift/drift.dart';

/// Table des points d'interet (POI) d'un sentier.
///
/// Les POI sont rattaches a un sentier et optionnellement
/// a une etape. Types : refuge, eau, panorama, camping,
/// restaurant, urgence, danger, boutique.
class Pois extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier parent
  TextColumn get trailId => text()();

  /// Numero de l'etape associee
  IntColumn get stageNumber => integer()();

  /// Nom du point d'interet
  TextColumn get name => text()();

  /// Description du POI
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Type de POI (shelter, water, viewpoint, campsite, restaurant, emergency, danger, shop)
  TextColumn get type => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Altitude en metres
  IntColumn get altitudeM => integer().withDefault(const Constant(0))();

  /// Horaires d'ouverture (nullable)
  TextColumn get openingHours => text().nullable()();
}
