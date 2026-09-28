import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des etapes d'un itineraire (Phase 4 Drift v7).
///
/// Chaque itineraire contient N etapes avec coordonnees,
/// distance, denivele et difficulte.
/// Noms i18n aplatis : nameFr, nameEn, nameDe, nameIt, nameEs.
class TrailStages extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_itineraries.id
  TextColumn get itineraryId => text()();

  /// Numero de l'etape dans l'itineraire (1-indexed)
  IntColumn get stageNumber => integer()();

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

  /// Latitude du point de depart
  RealColumn get startLat => real()();

  /// Longitude du point de depart
  RealColumn get startLng => real()();

  /// Latitude du point d'arrivee
  RealColumn get endLat => real()();

  /// Longitude du point d'arrivee
  RealColumn get endLng => real()();

  /// Distance en kilometres
  RealColumn get distanceKm => real()();

  /// Denivele positif en metres
  IntColumn get elevationGain => integer()();

  /// Denivele negatif en metres
  IntColumn get elevationLoss => integer()();

  /// Duree estimee en minutes
  IntColumn get durationMinutes => integer()();

  /// Difficulte (easy, moderate, hard, extreme)
  TextColumn get difficulty => text()();

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
