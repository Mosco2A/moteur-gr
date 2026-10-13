/// Points d'une trace, ordonnes par index de sequence : c'est cet ordre qui
/// reconstitue le trace.
library;

import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des points GPX d'une trace (Phase 4 Drift v7).
///
/// Points ordonnes par sequenceIndex pour reconstituer le trace.
class TrailGpxPoints extends Table {
  /// Cle primaire auto-incrementee
  IntColumn get id => integer().autoIncrement()();

  /// Reference vers trail_gpx_tracks.id
  TextColumn get trackId => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Altitude en metres
  RealColumn get elevation => real()();

  /// Index de sequence pour l'ordre des points
  IntColumn get sequenceIndex => integer()();

  /// HORODATAGE de cet enregistrement : L INSTANT ou il a ete modifie pour la
  /// derniere fois, pose par le SERVEUR (StepWays taches 605 puis 610).
  ///
  /// Nullable : les lignes anterieures a la migration v27, celles que la v28 a
  /// remises a zero, et les donnees embarquees qui ne declarent pas d instant.
  ///
  /// STOCKE EN MILLISECONDES DEPUIS L EPOCH, DANS LA MEME COLONNE `INTEGER`
  /// QU AVANT : la bascule du compteur vers la date ne demande AUCUN
  /// `ALTER TABLE`. Le modele complet — et pourquoi le telephone ne doit jamais
  /// y ecrire sa propre horloge — est dans
  /// `lib/core/data/revision_de_donnee.dart`.
  IntColumn get rev =>
      integer().nullable().map(const HorodatageServeurConverter())();
}
