/// Variantes de parcours d'un sentier (Nord-Sud, Sud-Nord...), avec leurs noms
/// aplatis en cinq langues.
library;

import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des itineraires d'un sentier (Phase 4 Drift v7).
///
/// Un sentier peut avoir plusieurs itineraires (Nord-Sud, Sud-Nord, etc.).
/// Noms i18n aplatis : nameFr, nameEn, nameDe, nameIt, nameEs.
class TrailItineraries extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_meta.id
  TextColumn get trailId => text()();

  /// Code de l'itineraire (ex: 'ns', 'sn')
  TextColumn get code => text()();

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

  /// Distance totale en kilometres
  RealColumn get distanceKm => real()();

  /// Denivele positif total en metres
  IntColumn get elevationGain => integer()();

  /// Nombre d'etapes
  IntColumn get stageCount => integer()();

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
