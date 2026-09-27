/// Numero de secours regional d'un sentier.
///
/// Fourni par la configuration du sentier (jamais hardcode dans
/// le moteur). Exemple : secours montagne local de la region.
/// Le 112 (urgences europeennes) est universel et gere par le
/// moteur — ne pas le dupliquer ici.
class TrailEmergencyNumber {
  const TrailEmergencyNumber({required this.name, required this.phone});

  /// Nom affiche du service de secours (ex: 'Secours montagne').
  final String name;

  /// Numero de telephone (format national ou international).
  final String phone;
}

/// Configuration d'un sentier — coeur du Moteur GR.
///
/// Chaque sentier fournit sa propre instance de TrailConfig.
/// Le moteur s'adapte automatiquement : couleurs, étapes,
/// points d'intérêt, secours régionaux, etc.
class TrailConfig {
  const TrailConfig({
    required this.id,
    required this.name,
    required this.displayName,
    required this.tagline,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
    required this.region,
    required this.country,
    required this.primaryColorValue,
    required this.secondaryColorValue,
    required this.gpxAssetPath,
    this.directions = const ['NS', 'SN'],
    this.availableDurations = const [7, 9, 12, 14, 16],
    this.defaultDuration = 14,
    this.offlineFirst = true,
    this.hasPremium = false,
    this.priceStages,
    this.firebaseProjectId,
    this.emergencyNumbers = const [],
    this.seedAssetsBase,
    this.accommodationsAssetPath,
    this.tipAssetPaths = const [],
    this.privacyPolicyUrl,
  });

  /// Identifiant unique du sentier (ex: 'gr10', 'tmb')
  final String id;

  /// Nom technique court (ex: 'GR10')
  final String name;

  /// Nom d'affichage de l'app (ex: 'Volcans Trail')
  final String displayName;

  /// Accroche sous le nom (ex: 'Votre compagnon de trek')
  final String tagline;

  /// Nombre total d'étapes
  final int totalStages;

  /// Distance totale en kilomètres
  final double totalDistanceKm;

  /// Dénivelé positif total en mètres
  final int totalElevationGain;

  /// Région géographique (ex: 'Auvergne', 'Pyrénées')
  final String region;

  /// Pays (ex: 'France', 'Suisse')
  final String country;

  /// Couleur primaire du thème (valeur int du Color)
  final int primaryColorValue;

  /// Couleur secondaire du thème (valeur int du Color)
  final int secondaryColorValue;

  /// Chemin vers le fichier GPX dans les assets
  final String gpxAssetPath;

  /// Directions de parcours possibles (ex: ['NS', 'SN'])
  final List<String> directions;

  /// Durées proposées pour le planning (en jours)
  final List<int> availableDurations;

  /// Durée par défaut suggérée (en jours)
  final int defaultDuration;

  /// Mode offline-first obligatoire (true pour les sentiers sans réseau)
  final bool offlineFirst;

  /// Active les fonctionnalités premium
  final bool hasPremium;

  /// PRIX du sentier, EN ÉTAPES. `null` = le prix vaut [totalStages].
  ///
  /// L'unité du modèle économique est l'ÉTAPE (`MODELE_ECO.md` §1) : un trek de
  /// N étapes coûte N étapes, calées sur le palier store à 0,99 €. Ce champ
  /// EXISTE pour qu'un sentier puisse dire un prix DIFFÉRENT de son nombre
  /// d'étapes — et le seul cas qui compte aujourd'hui est le prix ZÉRO : un
  /// SENTIER GRATUIT ([isFreeTrail]).
  ///
  /// POURQUOI UN PRIX ET PAS UN DRAPEAU « DÉMO », ET C'EST TOUT LE SUJET DE LA
  /// TÂCHE 601. Ce champ remplace un booléen `isShowcaseTrail` qui disait « ce
  /// sentier ÉCHAPPE au mode démo ». Une exemption est un TROU dans le modèle :
  /// elle n'a pas de prix, elle ne se déduit de rien, et elle emporte tout ce
  /// qui s'accroche à `owned` — y compris le sans-pub permanent réservé à
  /// l'achat, que le sentier de démonstration recevait ainsi gratuitement. Un
  /// PRIX, lui, est une ENTRÉE du modèle : de lui se déduisent l'accès (rien à
  /// payer, donc jouable) et la publicité (rien de payé, donc niveau gratuit
  /// du §2). Le drapeau avait par ailleurs été attribué à Christophe dans un
  /// commentaire de code sans qu'aucune décision ne le soutienne, et il a dit
  /// le 27/09 n'avoir jamais parlé de sentier vitrine.
  ///
  /// Un sentier gratuit n'est donc PAS un sentier payant débridé : c'est un
  /// sentier de plus au catalogue, dont le prix est nul.
  final int? priceStages;

  /// Prix EFFECTIF du sentier en étapes (défaut : une étape par étape).
  int get priceInStages => priceStages ?? totalStages;

  /// Vrai si ce sentier est GRATUIT — son prix est nul.
  ///
  /// Gratuit par NATURE, pas par exemption : il n'y a rien à payer, donc rien
  /// à débloquer. Corollaire assumé (modèle éco §2/§3) : n'ayant rien payé, il
  /// relève du niveau gratuit côté publicité — hors mode trek, où la règle de
  /// Chris « EN MODE TREK JAMAIS de publicité » prime sur tout.
  bool get isFreeTrail => priceInStages == 0;

  /// ID du projet Firebase (null = pas de backend Firebase)
  final String? firebaseProjectId;

  /// Numeros de secours regionaux du sentier (ex: secours montagne
  /// local). Affiches apres le 112 universel dans l'ecran urgence.
  /// Vide par defaut : seul le 112 est propose.
  final List<TrailEmergencyNumber> emergencyNumbers;

  /// Racine des assets de donnees du sentier pour le seed initial
  /// (ex: 'assets/data/mon_sentier'). Null = pas de seed embarque.
  final String? seedAssetsBase;

  /// Fichier JSON MONOLITHIQUE (schema `trail_meta`/`itineraries`/`stages`/
  /// `accommodations`/`pois`) charge au seed dans les tables relationnelles
  /// riches (`trail_stages`/`trail_accommodations`...) via [TrailSeeder].
  ///
  /// R4 (retour Chris) : l'assistant Nuitees lit les hebergements par
  /// `getAccommodations` (jointure itineraires -> etapes -> hebergements sur
  /// ces tables riches). Le seed « dossier » ([seedAssetsBase]) ne peuple QUE
  /// les tables simples (etapes/POI) — les hebergements n'etaient donc jamais
  /// charges (noms manquants). Ce chemin optionnel branche le seed des
  /// hebergements. Null = pas d'hebergements embarques (fallback gracieux).
  final String? accommodationsAssetPath;

  /// Fichiers JSON de fiches conseils a charger au seed.
  final List<String> tipAssetPaths;

  /// URL de la politique de confidentialite du produit/sentier.
  ///
  /// Parametrique (jamais codee en dur dans le moteur) : fournie par la
  /// configuration du sentier. Requise pour les fiches store (Google Play /
  /// App Store) et l'ecran « Confidentialite ». Null = non renseignee
  /// (l'UI masque alors le lien). Exemple : 'https://exemple.org/privacy'.
  final String? privacyPolicyUrl;
}
