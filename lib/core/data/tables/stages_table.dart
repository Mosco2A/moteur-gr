import 'package:drift/drift.dart';

/// Table des etapes d'un sentier.
///
/// Chaque sentier contient N etapes. Une etape est un troncon
/// avec point de depart, point d'arrivee, distance et denivele.
class Stages extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier parent (ex: 'sentier-volcans')
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

  /// Duree estimee de l'etape, en MINUTES (parite GR20).
  ///
  /// Champ RICHE optionnel du socle « donnees externes ». NULLABLE : renseigne
  /// uniquement pour les sentiers dont la source de donnees le fournit
  /// (`stages.json`, backend P4). Ajoute en migration v20 -> v21.
  IntColumn get estimatedDurationMinutes => integer().nullable()();
}
