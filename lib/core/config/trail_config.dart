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
    this.isShowcaseTrail = false,
    this.firebaseProjectId,
    this.emergencyNumbers = const [],
    this.seedAssetsBase,
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

  /// Sentier VITRINE de démonstration (déblocage jouable sans achat).
  ///
  /// PARITÉ GR20, LOT 2 (#99433) : le sentier de démonstration par défaut
  /// (`TrailCatalog.defaultTrail`) est une VITRINE entièrement jouable —
  /// GPS, journal et navigation actifs — SANS achat, pour que la démo se
  /// démontre de bout en bout (parité avec le mode démo « tout débloqué » de
  /// GR20). C'est un FLAG de DONNÉE porté par la config du sentier, jamais un
  /// id de localité codé en dur dans le moteur.
  ///
  /// GARDE-FOU (décision Christophe) : ce flag ne concerne QUE la vitrine. Le
  /// modèle de monétisation à la carte reste INTACT sur tous les autres
  /// sentiers (non-vitrine = mode démo / paywall inchangé). `false` par défaut.
  final bool isShowcaseTrail;

  /// ID du projet Firebase (null = pas de backend Firebase)
  final String? firebaseProjectId;

  /// Numeros de secours regionaux du sentier (ex: secours montagne
  /// local). Affiches apres le 112 universel dans l'ecran urgence.
  /// Vide par defaut : seul le 112 est propose.
  final List<TrailEmergencyNumber> emergencyNumbers;

  /// Racine des assets de donnees du sentier pour le seed initial
  /// (ex: 'assets/data/mon_sentier'). Null = pas de seed embarque.
  final String? seedAssetsBase;

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
