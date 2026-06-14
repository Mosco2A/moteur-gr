import 'package:drift/drift.dart';

/// Table des segments comparables d'un sentier (F7A-01, Phase 7 social).
///
/// Un segment est une portion remarquable d'une etape (montee, traversee)
/// sur laquelle les trekkeurs peuvent etre compares ("Roi de l etape").
/// La table est un CACHE LOCAL des segments publies cote serveur :
/// la lecture est 100 % offline-first (S-1). La polyline de reference du
/// segment est portee par [polylineGpxRef] (reference vers la trace GPX).
/// Ajoutee en migration v15.
class Segments extends Table {
  /// Identifiant unique du segment (fourni serveur, stable).
  TextColumn get id => text()();

  /// Identifiant du sentier auquel appartient le segment.
  TextColumn get trailId => text()();

  /// Nom lisible du segment (libelle, i18n cote presentation).
  TextColumn get nom => text()();

  /// Reference vers la polyline GPX de definition du segment.
  /// Encodee en JSON (liste de {lat,lng}) ou cle de track GPX selon la source.
  TextColumn get polylineGpxRef => text()();

  /// Distance du segment en metres.
  RealColumn get distanceM => real()();

  /// Denivele positif du segment en metres.
  RealColumn get deniveleM => real()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Table des efforts d'un utilisateur sur un segment, en file offline-first
/// (F7A-01, Phase 7).
///
/// Chaque ligne est un effort detecte LOCALEMENT (SegmentMatchingService
/// F7A-02) lors du passage sur un segment : il est ecrit d'abord en local
/// (`syncState=pending`) puis pousse vers Firestore au retour du reseau
/// (collection `segment_efforts`, F7A-03). Le classement OFFICIEL est
/// recalcule COTE SERVEUR apres sync (R2) — cette table ne sert qu'au
/// stockage local et a l'affichage immediat.
///
/// [userUidHash] est l'UID HACHE (SHA-256, AnonymousIdService) : JAMAIS
/// d'email ni de nom (#85383, minimisation RGPD).
class SegmentEffortLocal extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant du segment concerne (FK logique vers Segments.id).
  TextColumn get segmentId => text()();

  /// UID HACHE de l'auteur de l'effort (SHA-256, jamais de PII #85383).
  TextColumn get userUidHash => text()();

  /// Duree de l'effort en secondes (calcul local pour affichage).
  IntColumn get durationSeconds => integer()();

  /// Horodatage de debut de l'effort (UTC).
  DateTimeColumn get startedAt => dateTime()();

  /// Etat de synchronisation ('pending', 'synced', 'failed').
  TextColumn get syncState =>
      text().withDefault(const Constant('pending'))();

  /// Identifiant Firestore distant une fois synchronise (nullable).
  TextColumn get remoteId => text().nullable()();

  /// Nombre de tentatives de synchronisation echouees.
  IntColumn get attempts => integer().withDefault(const Constant(0))();

  /// Derniere erreur de synchronisation (nullable).
  TextColumn get lastError => text().nullable()();
}
