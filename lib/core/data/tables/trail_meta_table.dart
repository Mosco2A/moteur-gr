/// Code unique d'un sentier, version de ses donnees et horodatage de sa
/// derniere synchronisation.
library;

import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des metadonnees de sentier (Phase 4 Drift v7).
///
/// Chaque sentier a un code unique, une version de donnees
/// et un horodatage de derniere synchronisation.
class TrailMeta extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Code unique du sentier (ex: 'gr10', 'tmb')
  TextColumn get code => text().unique()();

  /// L INSTANT DE LA DERNIERE PUBLICATION DU SENTIER, recopie dans sa fiche.
  /// Millisecondes depuis l epoch (cf. `revision_de_donnee.dart`).
  ///
  /// C EST UNE COPIE, PAS LE REPERE QUI FAIT FOI, et la distinction a ete mesuree
  /// a la tache 607 : toutes les lectures qui DECIDENT d une mise a jour viennent
  /// de `trail_manifests`, jamais d ici. Le repere qui fait foi est
  /// `trail_manifests.localVersion`, ecrit dans la transaction de la pose.
  IntColumn get dataVersion =>
      integer().map(const HorodatageServeurConverter())();

  /// Date de derniere synchronisation (ISO 8601, nullable)
  TextColumn get lastSync => text().nullable()();

  /// Statut du sentier ('active', 'archived', 'draft')
  TextColumn get status => text().withDefault(const Constant('active'))();

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
