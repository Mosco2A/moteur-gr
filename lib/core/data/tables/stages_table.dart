import 'package:drift/drift.dart';

/// Table des etapes d'un sentier.
///
/// Chaque sentier contient N etapes. Une etape est un troncon
/// avec point de depart, point d'arrivee, distance et denivele.
class Stages extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier parent (ex: 'mare_a_mare')
  TextColumn get trailId => text()();

  /// Numero de l'etape dans le sentier (1-indexed)
  IntColumn get stageNumber => integer()();

  /// Nom de l'etape (ex: 'Vizzavona - Bocognano')
  TextColumn get name => text()();

  /// Distance en kilometres
  RealColumn get distanceKm => real()();

  /// Denivele positif en metres
  IntColumn get elevationGainM => integer()();

  /// Denivele negatif en metres
  IntColumn get elevationLossM => integer()();

  /// Description textuelle de l'etape
  TextColumn get description => text().withDefault(const Constant(''))();

  /// Latitude du point de depart
  RealColumn get startLat => real()();

  /// Longitude du point de depart
  RealColumn get startLng => real()();

  /// Latitude du point d'arrivee
  RealColumn get endLat => real()();

  /// Longitude du point d'arrivee
  RealColumn get endLng => real()();

  /// Difficulte (easy, moderate, hard, extreme)
  TextColumn get difficulty => text().withDefault(const Constant('moderate'))();
}
