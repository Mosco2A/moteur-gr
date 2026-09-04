import 'package:drift/drift.dart';

/// Table des selections de nuitees (PARITE GR20 « Reserver vos nuits »).
///
/// Chaque ligne represente l'etat d'une nuit du PROGRAMME pour un sentier
/// donne : le type de nuitee choisi (refuge / gite / bivouac / autre) et
/// l'etat reserve / a reserver. Persistance 100 % locale (Drift), sans
/// Firebase (parite fonctionnelle GR20 mais backend local avant Phase 4).
///
/// Cle logique : (trailId, dayNumber). Le dayNumber 0 correspond a la nuit
/// avant le depart (N0, veille), comme GR20. Ajoutee en migration v22.
class NuiteeSelections extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du sentier (ex: 'gr10').
  TextColumn get trailId => text()();

  /// Numero du jour du PROGRAMME (1-indexed ; 0 = nuit avant depart N0).
  IntColumn get dayNumber => integer()();

  /// Nuit reservee ou non (etat « a reserver » / « reserve », parite GR20).
  BoolColumn get isBooked => boolean().withDefault(const Constant(false))();

  /// Type de nuitee choisi (nom de l'enum NuiteeType : refuge / gite /
  /// bivouac / autreHebergement). String pour tolerer l'evolution de l'enum.
  TextColumn get nuiteeType =>
      text().withDefault(const Constant('refuge'))();

  /// Date de derniere modification.
  DateTimeColumn get updatedAt => dateTime().nullable()();
}
