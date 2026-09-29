import 'package:freezed_annotation/freezed_annotation.dart';

import '../data/revision_de_donnee.dart';

part 'trail_manifest.freezed.dart';
part 'trail_manifest.g.dart';

/// LES HUIT FAMILLES DE DONNEES D UN SENTIER, ET LEUR ORDRE.
///
/// Ces noms ne sont pas un choix : ce sont les clefs du fichier de
/// donnees de sentier que le moteur sait deja lire (`TrailSeeder`,
/// `DeltaUpdateService`), c est-a-dire le schema
/// MONOLITHE documente au §3.5 du MODOP 603. Les changer ici sans les changer
/// la-bas casserait la copie.
///
/// ELLES ETAIENT SEPT JUSQU AU LOT 625, ET LA HUITIEME EST LA METEO. Decision de
/// Christophe du 28/09, verbatim : « Ce n est pas l appli qui demande la meteo mais
/// notre serveur, les infos meteo sont mises sur firebase et quand l appli voit
/// qu il y a des donnees a jour elle les met a jour, COMME POUR LE RESTE. » « Comme
/// pour le reste » est la phrase qui compte : la meteo n a pas de mecanisme a elle,
/// elle entre dans celui-ci. La conception 611 d Athena le formule autrement (#N6) :
/// **le mecanisme est commun, la peremption est par famille** — une trace ne perime
/// pas, une prevision oui, et c est la presentation qui porte cette difference,
/// pas le transport.
///
/// L ORDRE EST CELUI DES CLES ETRANGERES, et il n est pas decoratif : un
/// hebergement rattache a une etape qui n existe pas encore echoue. Cet ordre
/// existait en TROIS copies dans le depot (ici, `_insertionSteps`, et le retour
/// en dur de l ancien `_inferChangedTables`) : il n en reste qu une — les deux
/// autres ont disparu avec leurs porteurs (`_inferChangedTables` en 605,
/// `TrailDownloadService` en 606).
///
/// CE QUE CETTE LISTE N EST PAS — ET C EST LA CORRECTION DU 27/09 20:43. Elle
/// n est PAS une unite de version. Une premiere version de ce lot versionnait par
/// famille (« une version par table ») ; Christophe a simplifie : « On ne met
/// qu une info de version sur chaque donnee ». La version vit DANS
/// l enregistrement (`RevisionDeDonnee`), et cette liste ne sert plus qu a savoir
/// dans quel ORDRE poser les donnees et dans quelle TABLE.
abstract final class MorceauxDeSentier {
  MorceauxDeSentier._();

  /// Fiche du sentier : sa ligne d identite en base (`trail_meta`).
  static const String fiche = 'trail_meta';

  /// Itineraires du sentier.
  static const String itineraires = 'itineraries';

  /// Etapes.
  static const String etapes = 'stages';

  /// Hebergements.
  static const String hebergements = 'accommodations';

  /// Points d interet.
  static const String pointsDInteret = 'pois';

  /// METEO FABRIQUEE PAR LE SERVEUR, un enregistrement par etape (lot 625).
  ///
  /// C est la seule famille dont le producteur n est PAS le publicateur mais le
  /// COLLECTEUR (#L1 de la conception 611), et cela ne change rien au transport :
  /// les deux ecrivent la meme borne, chacun ses lignes (#K9). La liste des
  /// producteurs est close — une famille appartient a l un ou a l autre, jamais
  /// aux deux.
  static const String meteo = 'meteo';

  /// Traces GPX (l entete des traces).
  static const String traces = 'gpx_tracks';

  /// Points de trace GPX (le gros du volume).
  static const String pointsDeTrace = 'gpx_points';

  /// Les huit familles, dans l ORDRE D INSERTION impose par les cles
  /// etrangeres.
  ///
  /// [meteo] EST PLACEE APRES [etapes] PARCE QU ELLE S Y RATTACHE, et avant
  /// [traces] parce que c est ce qui la fait entrer dans le niveau « preparer »
  /// (`NiveauDeTelechargement.volumineux` retire les deux dernieres, et seulement
  /// elles). Ce placement n est donc pas esthetique : il decide que le randonneur
  /// qui PREPARE recoit la meteo. C est le but — preparer, c est choisir un jour de
  /// depart, et cela se decide sur le temps.
  static const List<String> tous = <String>[
    fiche,
    itineraires,
    etapes,
    hebergements,
    pointsDInteret,
    meteo,
    traces,
    pointsDeTrace,
  ];

  /// Vrai si [nom] designe une famille connue du moteur.
  ///
  /// Une famille inconnue publiee par le serveur est IGNOREE et journalisee :
  /// mieux vaut une donnee non copiee et DITE, qu une exception sur une table qui
  /// n existe pas dans cette version de l application.
  static bool estConnu(String nom) => tous.contains(nom);
}

/// Manifeste des sentiers disponibles cote serveur.
///
/// C est LA LISTE DES SENTIERS DISPONIBLES au sens du point 3 de Christophe
/// (27/09 20:11) : « il faut un processus de creation d un nouveau sentier en
/// base que l appli viendra ajouter a son catalogue en lisant la liste des
/// sentiers disponibles ». L application la lit, et ajoute a son catalogue les
/// sentiers qu elle ne connait pas.
///
/// [schemaVersion] vaut 2 depuis la tache 605 : la fiche d affichage
/// ([TrailManifestEntry.fiche]) y est apparue, et [TrailManifestEntry.dataVersion]
/// y a pris son sens de REVISION COURANTE. Un manifeste de schema 1 reste
/// lisible : sans fiche, ses entrees ne peuvent decrire que des sentiers que le
/// binaire connait deja, et le moteur le DIT au lieu de montrer une carte vide.
@freezed
abstract class TrailManifest with _$TrailManifest {
  const factory TrailManifest({
    /// Version du schema du manifeste (2 depuis la tache 605)
    required int schemaVersion,

    /// Liste des sentiers declares dans le manifeste
    required List<TrailManifestEntry> trails,
  }) = _TrailManifest;

  /// Deserialisation depuis JSON
  factory TrailManifest.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestFromJson(json);
}

/// Entree individuelle du manifeste pour un sentier.
@freezed
abstract class TrailManifestEntry with _$TrailManifestEntry {
  const factory TrailManifestEntry({
    /// Identifiant unique du sentier (ex: 'gr10', 'tmb').
    ///
    /// C EST LA CLE, et elle est la meme des deux cotes : un sentier present
    /// dans le catalogue compile ET dans le manifeste distant n est pas deux
    /// sentiers, c est le meme.
    required String trailId,

    /// L INSTANT DE LA DERNIERE PUBLICATION DU SENTIER, pose par le serveur.
    ///
    /// C est la moitie de l unique question que l application pose : « je suis a
    /// jour jusqu a R (`trail_manifests.localVersion`), tu es publie a
    /// [dataVersion] ; donne-moi tout ce qui porte une date plus recente que R ».
    /// L autre moitie est portee par chaque enregistrement
    /// (`RevisionDeDonnee.champRevision`).
    ///
    /// A la premiere ouverture le repere local vaut [HorodatageServeur.origine] :
    /// tout est plus recent, donc tout descend. Premiere copie et mise a jour sont
    /// le MEME chemin de code.
    ///
    /// LE TELEPHONE RETIENT CETTE VALEUR TELLE QUELLE, ET JAMAIS SA PROPRE
    /// HORLOGE. C est la regle absolue du modele : une seule autorite de temps, le
    /// serveur. Voir `revision_de_donnee.dart` pour ce que l autre choix aurait
    /// coute — une perte definitive et silencieuse.
    @HorodatageServeurJson() required HorodatageServeur dataVersion,

    /// Hash SHA-256 du fichier de donnees COMPLET du sentier.
    required String hash,

    /// Chemin du fichier de donnees du sentier.
    ///
    /// LE TRANSPORT, ET SA LIMITE MESUREE. Le moteur telecharge ce fichier puis
    /// ne pose QUE les enregistrements dont la revision depasse la sienne : la
    /// correction d une altitude ecrit UNE etape, pas sept tables. En revanche le
    /// TRANSFERT reste global tant que les donnees vivent dans un fichier a plat.
    /// Sur une base interrogeable (Firestore), la meme question devient une
    /// requete `rev > R` et le transfert devient lui aussi unitaire, sans changer
    /// une ligne de la logique ci-dessous. C est la seule difference entre les
    /// deux transports, et elle est en octets, pas en comportement.
    required String filePath,

    /// Taille du fichier de donnees complet, en octets.
    required int fileSize,

    /// Statut du sentier ('active', 'draft', 'archived')
    required String status,

    /// Date de derniere mise a jour (ISO 8601).
    ///
    /// DEPUIS LA TACHE 610, CE CHAMP ET [dataVersion] DESIGNENT LE MEME INSTANT —
    /// et deux noms pour un meme fait, c est deux autorites dont la plus
    /// silencieuse gagne. Le lot ne le supprime pas (renommer ou retirer un champ
    /// de la liste publiee depasse « seul le type de la comparaison change »),
    /// mais il ferme la divergence par les deux bouts : l outil de publication les
    /// ecrit depuis LA MEME horloge, et `verifier` refuse un depot ou ils ne
    /// concordent pas. CELUI QUI DECIDE EST [dataVersion] — celui-ci est lisible,
    /// pas normatif.
    required String lastUpdated,

    /// FICHE D AFFICHAGE DU SENTIER — LA PIECE QUI MANQUAIT AU MOTEUR.
    ///
    /// CE QUI ETAIT CASSE, ET C EST LE MUR N1 (tache 605). Le manifeste ne
    /// portait QUE du versionnement : identifiant, version, hash, taille,
    /// statut, date. Aucun NOM, aucune REGION, aucune STATISTIQUE. Or l ecran
    /// catalogue affiche une carte par sentier avec son nom, sa region, sa
    /// distance, son denivele et son nombre d etapes — toutes choses que le
    /// manifeste ne disait pas. CONSEQUENCE MECANIQUE : un sentier connu du
    /// SEUL distant etait strictement INAFFICHABLE, quoi qu on branche. Le
    /// chainage n etait donc pas le seul manque ; le manifeste lui-meme etait
    /// incapable de decrire un sentier.
    ///
    /// Elle est OPTIONNELLE, et les deux cas ont un sens precis :
    ///
    ///  * PRESENTE — le sentier est entierement decrit a distance. Il apparait
    ///    au catalogue SANS republication au magasin : c est le critere de
    ///    reussite du lot, verbatim de Christophe du 27/09 19:57 (« faire lire
    ///    les donnees automatiquement a l appli pour que ca affiche les
    ///    nouveaux sentiers totalement decrits en base »).
    ///
    ///  * ABSENTE — l entree ne fait que VERSIONNER un sentier que le binaire
    ///    connait deja (catalogue compile). Si le binaire ne le connait pas non
    ///    plus, l entree n est pas affichable et elle est ecartee avec un
    ///    journal qui le DIT (cf. `sentier_distant.dart`) — jamais une carte
    ///    vide au catalogue.
    TrailManifestFiche? fiche,
  }) = _TrailManifestEntry;

  /// Deserialisation depuis JSON
  factory TrailManifestEntry.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestEntryFromJson(json);
}

/// CE QU IL FAUT SAVOIR D UN SENTIER POUR L AFFICHER AU CATALOGUE.
///
/// Exactement les champs que la carte du catalogue et le moteur lisent sur une
/// [TrailConfig] : le nom tel que le randonneur le lit, ou c est, combien ca
/// fait, ce que ca coute. Rien de plus — un manifeste n est pas une base de
/// donnees de sentier : les etapes, les points d interet et la trace arrivent
/// par le fichier de donnees ([TrailManifestEntry.filePath]), pas par ici.
///
/// LES CHAMPS OBLIGATOIRES SONT CEUX SANS LESQUELS LA CARTE MENT. Un sentier
/// sans nom, sans region ou sans distance produirait une carte a trous ; le
/// reste (couleurs, prix, durees, secours) a un defaut honnete et documente.
@freezed
abstract class TrailManifestFiche with _$TrailManifestFiche {
  const factory TrailManifestFiche({
    /// Nom technique court (ex: 'GR10').
    required String name,

    /// Nom d affichage, celui que le randonneur lit (ex: 'Mare a Mare Centre').
    required String displayName,

    /// Accroche sous le nom.
    required String tagline,

    /// Region geographique (ex: 'Corse', 'Pyrenees').
    required String region,

    /// Pays.
    required String country,

    /// Nombre total d etapes.
    required int totalStages,

    /// Distance totale en kilometres.
    required double totalDistanceKm,

    /// Denivele positif total en metres.
    required int totalElevationGain,

    /// Couleur primaire du theme (valeur int d un Color). Null = defaut moteur.
    int? primaryColorValue,

    /// Couleur secondaire du theme. Null = defaut moteur.
    int? secondaryColorValue,

    /// PRIX du sentier EN ETAPES. Null = non declare (cf. `sentier_distant.dart`).
    ///
    /// `0` declare un SENTIER GRATUIT, et c est une decision de modele
    /// economique prise a distance : Christophe peut ouvrir un sentier gratuit
    /// sans republier l application. La regle de publicite en decoule sans
    /// exception nouvelle (#99404 : rien de paye => niveau gratuit).
    int? priceStages,

    /// Directions de parcours possibles (ex: ['NS', 'SN']). Null = defaut.
    List<String>? directions,

    /// Durees proposees pour le planning, en jours. Null = defaut.
    List<int>? availableDurations,

    /// Duree par defaut suggeree, en jours. Null = defaut.
    int? defaultDuration,

    /// Numeros de secours REGIONAUX du sentier. Le 112 est universel et gere
    /// par le moteur : ne pas le mettre ici.
    List<FicheNumeroSecours>? emergencyNumbers,

    /// URL de la politique de confidentialite du sentier.
    String? privacyPolicyUrl,
  }) = _TrailManifestFiche;

  /// Deserialisation depuis JSON
  factory TrailManifestFiche.fromJson(Map<String, dynamic> json) =>
      _$TrailManifestFicheFromJson(json);
}

/// Numero de secours regional declare a distance.
///
/// Miroir serialisable de `TrailEmergencyNumber` : le moteur ne hardcode aucun
/// numero, et un sentier neuf apporte les siens avec lui.
@freezed
abstract class FicheNumeroSecours with _$FicheNumeroSecours {
  const factory FicheNumeroSecours({
    /// Nom affiche du service de secours.
    required String name,

    /// Numero de telephone.
    required String phone,
  }) = _FicheNumeroSecours;

  /// Deserialisation depuis JSON
  factory FicheNumeroSecours.fromJson(Map<String, dynamic> json) =>
      _$FicheNumeroSecoursFromJson(json);
}
