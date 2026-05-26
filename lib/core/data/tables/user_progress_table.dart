import 'package:drift/drift.dart';

/// Table de progression utilisateur sur un sentier.
///
/// Une seule ligne par sentier. Mise a jour a chaque
/// changement d'etape ou progression de distance.
class UserProgressEntries extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier
  TextColumn get trailId => text().withLength(min: 1)();

  /// Etape courante (1-indexed)
  IntColumn get currentStage => integer().withDefault(const Constant(1))();

  /// Distance totale parcourue en km
  RealColumn get totalDistanceWalkedKm =>
      real().withDefault(const Constant(0.0))();

  /// Denivele positif total cumule en metres
  IntColumn get totalElevationGainedM =>
      integer().withDefault(const Constant(0))();

  /// Sentier complete ou non
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();

  /// Date de debut du sentier (nullable)
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// Date de fin du sentier (nullable)
  DateTimeColumn get completedAt => dateTime().nullable()();
}
