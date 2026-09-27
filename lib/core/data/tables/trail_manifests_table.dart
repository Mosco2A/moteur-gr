import 'package:drift/drift.dart';

/// Table locale des manifestes de sentier (Phase 4 Drift v8).
///
/// Stocke les entrees du manifeste distant avec la version locale
/// pour detecter les mises a jour necessaires.
class TrailManifests extends Table {
  /// Identifiant unique du sentier (cle primaire)
  TextColumn get trailId => text()();

  /// Version des donnees distantes
  IntColumn get dataVersion => integer()();

  /// Hash SHA-256 du fichier distant
  TextColumn get hash => text()();

  /// Chemin du fichier sur le serveur
  TextColumn get filePath => text()();

  /// Taille du fichier en octets
  IntColumn get fileSize => integer()();

  /// Statut du sentier ('active', 'draft', 'archived')
  TextColumn get status => text()();

  /// Date de derniere mise a jour (ISO 8601)
  TextColumn get lastUpdated => text()();

  /// Version telechargee localement (null = jamais telecharge)
  IntColumn get localVersion => integer().nullable()();

  /// LE DERNIER CATALOGUE DISTANT RECU, POUR QU IL SURVIVE AU HORS-LIGNE.
  ///
  /// Fiche d affichage du sentier (`TrailManifestFiche`) serialisee en JSON,
  /// telle que le manifeste distant l a declaree. Null = le manifeste n a
  /// jamais decrit ce sentier (entree de simple versionnement, ou base
  /// anterieure a la migration v27).
  ///
  /// POURQUOI UNE COLONNE JSON ET PAS DOUZE COLONNES. La fiche est une donnee
  /// SERVEUR que l on stocke pour la RELIRE telle quelle : le moteur ne la
  /// requete jamais champ par champ, il la desserialise en entier pour en faire
  /// une `TrailConfig`. Douze colonnes obligeraient a une migration a chaque
  /// champ que Christophe voudra decrire a distance — exactement la
  /// republication que ce lot supprime. C est aussi la forme du patron GR20,
  /// qui stocke ses listes distantes en JSON dans Hive
  /// (`remote_data_service.dart`).
  ///
  /// C EST LA COUCHE 2 DE L ORDRE DES SOURCES : distant, puis DERNIER DISTANT
  /// RECU (cette colonne), puis compile. Sans elle, un randonneur hors ligne
  /// perdrait de son catalogue tout sentier que le binaire ne connait pas.
  TextColumn get ficheJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {trailId};
}
