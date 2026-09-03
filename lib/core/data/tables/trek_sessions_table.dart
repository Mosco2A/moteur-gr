import 'package:drift/drift.dart';

/// Table des sessions de trek (PARITE GR20, LOT 2, #99433).
///
/// Persistance LOCALE Drift d'une [TrekSession] : identite, sentier, horodatage,
/// statut, et surtout la MEMOIRE DU FINISHER — les etapes reellement marchees
/// ([completedStages], serialisees en JSON) et le drapeau [parcoursFullyWalked].
///
/// Objectif : que `completedStages` / `parcoursFullyWalked` SURVIVENT a un
/// redemarrage de l'app (au LOT 1, `onSessionPersist` etait vide -> tout perdu).
/// Firestore reste hors perimetre (Phase 4).
///
/// Cle metier = [id] (UUID de la session). Une session par id (upsert). Ajoutee
/// en migration v18.
///
/// `@DataClassName('TrekSessionRow')` : la classe de ligne generee est nommee
/// explicitement pour NE PAS entrer en collision avec le modele de domaine
/// `TrekSession` (features/trek/domain/models/trek_session.dart).
@DataClassName('TrekSessionRow')
class TrekSessions extends Table {
  /// Identifiant unique de la session (UUID) — cle primaire metier.
  TextColumn get id => text()();

  /// Identifiant du sentier parcouru (TrailConfig.id).
  TextColumn get trailId => text()();

  /// Date/heure de debut de la session.
  DateTimeColumn get startedAt => dateTime()();

  /// Date/heure de fin (null tant que la session est en cours).
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Statut extensible (active, paused, completed, abandoned, ...).
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Etapes REELLEMENT completees, serialisees en JSON (liste de stageId).
  ///
  /// Critere bloquant du finisher : conserve entre les redemarrages pour que la
  /// reprise de session reflete les etapes deja marchees. Defaut `[]`.
  TextColumn get completedStagesJson =>
      text().withDefault(const Constant('[]'))();

  /// Le parcours a-t-il ete REELLEMENT parcouru en entier (finisher legitime) ?
  ///
  /// Fige quand la porte du finisher s'ouvre. Defaut false. Persiste pour tracer
  /// qu'un finisher a bien eu lieu (vs un arret manuel).
  BoolColumn get parcoursFullyWalked =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
