import 'package:drift/drift.dart';

/// Table des randonnees passees « notables » du randonneur (StepWays LOT 4,
/// faisabilite Ph3) — interview des 5 dernieres randos.
///
/// Max 5 par utilisateur (garde applicative), indexee par [userId] (hash
/// SHA-256 deterministe, cf. `anonymous_id_service.dart`). Chaque ligne decrit
/// UNE rando notable ; la faisabilite en DEDUIT le niveau reel (rythme,
/// endurance multi-jours, habitude du D+) au lieu d'un auto-label biaise.
///
/// Le champ texte libre « difficultes rencontrees » est GLOBAL (un seul pour
/// les 5 randos, pas par rando) : il vit dans une table SEPAREE
/// (`HikerExperienceNote`), pas ici. En V1 il est seulement STOCKE (l'IA le
/// lira en V2).
///
/// CONFIDENTIALITE : meme regle que le profil (spec §3.1) — local durable +
/// miroir cloud anonyme (hash), zero nominatif. Ajoutee en migration v25.
class PastHikeEntries extends Table {
  /// Cle primaire auto-incrementee.
  IntColumn get id => integer().autoIncrement()();

  /// Identifiant utilisateur (hash SHA-256 deterministe).
  TextColumn get userId => text()();

  /// Date de la rando (recence — pese dans la deduction du niveau).
  DateTimeColumn get date => dateTime()();

  /// Nombre de jours de la rando (endurance multi-jours).
  IntColumn get days => integer().withDefault(const Constant(1))();

  /// Temps moyen de marche PAR JOUR, en heures.
  RealColumn get avgWalkHoursPerDay =>
      real().withDefault(const Constant(0))();

  /// Denivele positif TOTAL de la rando, en metres (habitude du D+).
  IntColumn get totalElevationGain =>
      integer().withDefault(const Constant(0))();

  /// Distance TOTALE de la rando, en km (=> deduit le km/jour).
  RealColumn get totalDistanceKm => real().withDefault(const Constant(0))();

  /// Horodatage de saisie/modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();
}

/// Note d'experience GLOBALE du randonneur : le champ texte libre
/// « difficultes rencontrees lors de ces 5 derniers treks » (StepWays LOT 4,
/// Ph3). SEPARE des randos (pas par rando) : singleton par [userId].
///
/// V1 : STOCKE seulement (l'IA le lira en V2 — envoi anonymise). Meme regle de
/// confidentialite que le reste du profil. Ajoutee en migration v25.
class HikerExperienceNote extends Table {
  /// Identifiant utilisateur (hash SHA-256 deterministe) — cle primaire.
  TextColumn get userId => text()();

  /// Texte libre global « difficultes rencontrees » (ampoules, genoux en
  /// descente, essoufflement en altitude, coup de chaud...). Defaut vide.
  TextColumn get freeTextDifficulties =>
      text().withDefault(const Constant(''))();

  /// Horodatage de saisie/modification (last-write-wins du miroir cloud).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {userId};
}
