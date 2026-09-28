import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des traces GPX par itineraire (Phase 4 Drift v7).
///
/// Chaque itineraire peut avoir une ou plusieurs traces GPX.
class TrailGpxTracks extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_itineraries.id
  TextColumn get itineraryId => text()();

  /// Nom de la trace
  TextColumn get name => text()();

  /// URL source du fichier GPX (nullable)
  TextColumn get sourceUrl => text().nullable()();

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

  @override
  Set<Column> get primaryKey => {id};
}
