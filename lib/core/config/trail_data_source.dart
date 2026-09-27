/// OU VIVENT LES DONNEES DE SENTIER — UNE SEULE SOURCE DE VERITE (tache 604).
///
/// CE QUI ETAIT CASSE. Deux endroits du moteur portaient, EN DUR et
/// SEPAREMENT, l adresse d un espace de stockage qui repond 404 :
///
///   * `update_downloader.dart`  -> `storage.googleapis.com/moteur-gr`
///   * `catalog_provider.dart`   -> `storage.googleapis.com/moteur-gr/manifest.json`
///
/// Deux copies de la meme information, aucune des deux valide, et aucun moyen
/// d en changer sans toucher au code. Le bucket `moteur-gr` n a jamais existe
/// (verifie : 404 sur la racine comme sur l objet). Le projet Firebase de
/// StepWays est `stepways-app` et son espace de stockage par defaut est
/// [_bucketParDefaut] — c est la valeur que porte le fichier de configuration
/// Firebase pose dans android/app/ et ios/Runner/.
///
/// CE QUE FAIT CE FICHIER. Il devient le SEUL endroit qui sait ou sont les
/// donnees. Les deux appelants le lisent ; plus aucune adresse en dur ailleurs.
///
/// FORME REPRISE DU GR20. `GR20/app/lib/core/data/remote_data_service.dart`
/// lit `data/version.json` par REFERENCE Firebase Storage, compare la version,
/// telecharge, met en cache, et retombe proprement quand le reseau manque. On
/// garde cette forme : chemins prefixes `data/`, version comparee, cache local
/// qui fait foi hors ligne. Le transport reste HTTP (le moteur telecharge deja
/// en HTTP avec reprise et progression — cf. `TrailDownloadService`), mais
/// l URL est desormais construite depuis la reference Storage au lieu d etre
/// devinee.
library;

/// Espace de stockage des donnees de sentier.
///
/// Surchargeable au build, comme l identifiant de projet Firebase
/// (`STEPWAYS_FIREBASE_PROJECT_ID`) et les identifiants AdMob :
///
/// ```bash
/// flutter build appbundle --release \
///   --dart-define=STEPWAYS_TRAIL_DATA_BUCKET=stepways-app.firebasestorage.app
/// ```
///
/// La valeur par defaut est celle du projet `stepways-app`. Cette valeur n est
/// PAS sensible : le nom du bucket figure deja dans le fichier de configuration
/// Firebase embarque dans l application, et l acces reel est gouverne par les
/// regles de securite Firebase Storage, pas par la discretion de ce nom.
abstract final class TrailDataSource {
  TrailDataSource._();

  /// Nom de la variable de build — publie pour que Chris ou la CI la passe
  /// sans avoir a la deviner (meme convention que 596).
  static const String variableDeBuild = 'STEPWAYS_TRAIL_DATA_BUCKET';

  static const String _bucketParDefaut = 'stepways-app.firebasestorage.app';

  /// Espace de stockage effectif.
  static const String bucket = String.fromEnvironment(
    variableDeBuild,
    defaultValue: _bucketParDefaut,
  );

  /// Dossier des donnees dans l espace de stockage.
  ///
  /// Identique au GR20 (`data/version.json`, `data/stages.json`...) : un seul
  /// prefixe, pour que les deux produits se relisent l un l autre.
  static const String dossier = 'data';

  /// Chemin du manifeste du catalogue DANS l espace de stockage.
  static const String cheminManifeste = '$dossier/manifest.json';

  /// URL de telechargement d un objet de l espace de stockage.
  ///
  /// Forme REST Firebase Storage : le chemin est encode (les `/` deviennent
  /// `%2F`), ce que la forme `storage.googleapis.com/<bucket>/<chemin>`
  /// n exigeait pas — c est la raison d etre de cette fonction plutot que
  /// d une simple concatenation.
  static String urlDe(String chemin) {
    final encode = Uri.encodeComponent(chemin);
    return 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encode'
        '?alt=media';
  }

  /// URL du manifeste du catalogue des sentiers.
  static String get urlManifeste => urlDe(cheminManifeste);

  /// URL des donnees d un sentier, depuis le chemin porte par le manifeste.
  ///
  /// Un manifeste peut porter soit un chemin relatif ("mare_a_mare/v3.json"),
  /// soit une URL absolue deja resolue. On respecte l absolu tel quel : c est
  /// ce qui permet de servir un sentier depuis un autre hebergeur sans
  /// reconstruire le moteur.
  static String urlDonneesSentier(String cheminDuManifeste) {
    final deja = Uri.tryParse(cheminDuManifeste);
    if (deja != null && deja.hasScheme) return cheminDuManifeste;
    return urlDe('$dossier/$cheminDuManifeste');
  }
}
