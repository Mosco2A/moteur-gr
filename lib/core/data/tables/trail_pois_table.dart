import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des points d'interet par etape (Phase 4 Drift v7).
///
/// POI rattaches a une etape avec noms et descriptions i18n.
/// Noms i18n aplatis : nameFr/nameEn/nameDe/nameIt/nameEs,
/// descriptionFr/descriptionEn/descriptionDe/descriptionIt/descriptionEs.
class TrailPois extends Table {
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

  /// Description en francais (nullable)
  TextColumn get descriptionFr => text().nullable()();

  /// Description en anglais (nullable)
  TextColumn get descriptionEn => text().nullable()();

  /// Description en allemand (nullable)
  TextColumn get descriptionDe => text().nullable()();

  /// Description en italien (nullable)
  TextColumn get descriptionIt => text().nullable()();

  /// Description en espagnol (nullable)
  TextColumn get descriptionEs => text().nullable()();

  /// Type de POI (water, viewpoint, shelter, danger, info, etc.)
  TextColumn get type => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Altitude en metres (nullable)
  RealColumn get elevation => real().nullable()();

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
