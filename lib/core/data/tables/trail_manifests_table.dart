/// Entrees du manifeste distant ET la version locale en face : c'est cette
/// confrontation qui detecte une mise a jour.
library;

import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table locale des manifestes de sentier (Phase 4 Drift v8).
///
/// Stocke les entrees du manifeste distant avec la version locale
/// pour detecter les mises a jour necessaires.
class TrailManifests extends Table {
  /// Identifiant unique du sentier (cle primaire)
  TextColumn get trailId => text()();

  /// L INSTANT DE LA DERNIERE PUBLICATION DU SENTIER, tel que la liste distante
  /// l annonce. Millisecondes depuis l epoch (cf. `revision_de_donnee.dart`).
  ///
  /// C est la moitie SERVEUR de l unique question : « je suis a jour jusqu a
  /// [localVersion], tu es publie a [dataVersion] ; donne-moi tout ce qui porte
  /// une date plus recente que mon repere ».
  ///
  /// LE NOM RESTE `dataVersion` ALORS QUE LA VALEUR EST UNE DATE, et c est un
  /// choix de perimetre, pas un oubli : la consigne du lot 610 est « meme
  /// mecanisme, SEUL LE TYPE DE LA COMPARAISON CHANGE ». Renommer la colonne
  /// aurait impose une reconstruction de table a une migration qui, ainsi, n a
  /// aucun `ALTER TABLE` a faire — et une migration qui echoue empeche la base de
  /// s ouvrir. La dette de vocabulaire est nommee dans la specification serveur.
  IntColumn get dataVersion =>
      integer().map(const HorodatageServeurConverter())();

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

  /// LE REPERE DU TELEPHONE : jusqu a QUEL INSTANT ce sentier est copie ici.
  /// Null = jamais telecharge. Millisecondes depuis l epoch.
  ///
  /// CE QUI EST ECRIT ICI EST LA DATE QUE LE SERVEUR A ANNONCEE, JAMAIS L HEURE
  /// DE L APPAREIL — et ce n est pas une consigne, c est le type
  /// `HorodatageServeur` qui l impose : il ne se construit qu en LISANT une
  /// valeur venue du serveur. Un telephone dont l horloge avance d une heure et
  /// qui inscrirait son propre `now()` se croirait a jour jusqu a une heure dans
  /// le futur, et raterait DEFINITIVEMENT, sans que rien ne le dise, tout ce que
  /// le serveur publie entre-temps.
  ///
  /// IL N AVANCE QUE SI TOUT A ETE RECU, dans la MEME transaction que la pose des
  /// donnees (le mot « complet » de Christophe, 28/09 09:32). Un telephone coupe
  /// au milieu d une copie ne doit pas se croire a jour.
  IntColumn get localVersion =>
      integer().nullable().map(const HorodatageServeurConverter())();

  /// LE DERNIER CATALOGUE DISTANT RECU, POUR QU IL SURVIVE AU HORS-LIGNE.
  ///
  /// Fiche d affichage du sentier (`TrailManifestSheet`) serialisee en JSON,
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

  /// JUSQU A QUEL NIVEAU CE SENTIER EST DESCENDU (tache 616).
  ///
  /// Code stable de [NiveauDeTelechargement] (`regarder`, `preparer`,
  /// `realiser`). Null = jamais telecharge, comme [localVersion] null.
  ///
  /// POURQUOI CETTE COLONNE EST INDISPENSABLE ET PAS UN CONFORT — C EST LE PIEGE
  /// QUE LES NIVEAUX OUVRENT. Le repere [localVersion] est UN SEUL instant pour
  /// tout le sentier, et la regle de pose est « je prends ce qui est plus recent
  /// que mon repere ». Un telephone qui aurait copie le sentier au niveau
  /// « preparer » jusqu a l instant T, et qui demanderait ensuite « realiser »,
  /// verrait ses points de trace REFUSES : ils portent une date anterieure a T,
  /// donc la regle les declare deja a jour. Le randonneur partirait sans trace,
  /// en croyant avoir tout telecharge, et AUCUNE mise a jour ulterieure n irait
  /// jamais la chercher. Sans cette colonne, le defaut est silencieux et
  /// definitif.
  ///
  /// CE QU ELLE PERMET, ET C EST LA SEULE CHOSE QU ELLE PERMET : comparer le
  /// niveau DEMANDE au niveau DEJA DESCENDU. S il monte, la copie repart de
  /// l origine pour ce sentier (`repartirDeZero`), ce qui est deja un chemin
  /// eprouve du moteur et ne coute RIEN de plus en reseau sur le transport actuel
  /// — la source de fichier telecharge le fichier entier de toute facon.
  TextColumn get niveauLocal => text().nullable()();

  /// OU SONT LES TUILES DE CE SENTIER, CE QU ELLES PESENT, ET LEUR EMPREINTE
  /// (tache 622).
  ///
  /// Miroir local de `TrailManifestEntry.tilesPath` / `tilesSize` / `tilesHash`.
  /// Nulles quand la liste distante ne publie pas de carte pour ce sentier — ce qui
  /// est un cas NORMAL, pas une anomalie.
  ///
  /// POURQUOI EN BASE, ET PAS LUES AU VOL DANS LA LISTE DISTANTE. Le geste
  /// « telecharger » lit la LIGNE LOCALE (`CatalogNotifier.downloadTrail` ->
  /// `getByTrailId`), jamais la reponse reseau : c est ce qui lui permet de partir
  /// d un catalogue affiche depuis le dernier distant recu. Si l adresse des tuiles
  /// n etait pas conservee ici, la descente des cartes exigerait une SECONDE lecture
  /// du manifeste au moment du geste — donc un second chemin de resolution, avec sa
  /// propre facon d echouer. Trois colonnes valent mieux que deux verites.
  ///
  /// ELLES NE DISENT RIEN DE CE QUI EST SUR LE TELEPHONE. Ce sont des faits
  /// SERVEUR, comme [hash] et [fileSize] : « voila la carte publiee ». La presence
  /// reelle du fichier se lit sur le systeme de fichiers (`MBTilesManager`), une
  /// seule source, et pas dans une colonne qui pourrait mentir apres un effacement
  /// de donnees d application.
  TextColumn get tilesPath => text().nullable()();

  /// Poids du fichier de tuiles publie, en octets. Null = aucune carte publiee.
  IntColumn get tilesSize => integer().nullable()();

  /// Empreinte SHA-256 du fichier de tuiles publie. Null = aucune carte publiee.
  TextColumn get tilesHash => text().nullable()();

  @override
  Set<Column> get primaryKey => {trailId};
}
