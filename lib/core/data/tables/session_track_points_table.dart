import 'package:drift/drift.dart';

/// Table des points GPS du tracé de la dernière session de tracking.
///
/// Alimentée au fil de l'eau par le tracking GPS (TrackingNotifier) :
/// le tracé du sentier est remplacé au démarrage d'une nouvelle session.
/// Lue par le récap diplôme pour afficher le tracé réel parcouru
/// (finitions V8 F3). Ajoutée en migration v13.
class SessionTrackPoints extends Table {
  /// Clé primaire auto-incrémentée (ordre d'enregistrement)
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (TrailConfig.id)
  TextColumn get trailId => text()();

  /// Latitude WGS84
  RealColumn get lat => real()();

  /// Longitude WGS84
  RealColumn get lng => real()();

  /// Altitude en mètres
  RealColumn get altitude => real()();

  /// Horodatage d'enregistrement du point
  DateTimeColumn get recordedAt => dateTime()();
}
