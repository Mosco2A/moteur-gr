/// Les endroits ou une journee peut se terminer : des lieux RELEVES, jamais un
/// point calcule entre deux refuges.
library;

/// UN ENDROIT OU L'ON PEUT DORMIR, ET D'OU L'ON PEUT REPARTIR (tache 839).
///
/// POURQUOI CE MODELE EXISTE. La tache 634 a RETIRE le decoupage d'etape que le
/// lot 558 avait ajoute, et Christophe avait deux fois raison, verbatim :
/// « Decouper les etapes en deux est une mauvaise idee... il n'y a pas de
/// refuge et surtout JE N'AI JAMAIS DEMANDE CA » (29/09). Le defaut n'etait pas
/// le decoupage : c'etait le POINT DE COUPE, une interpolation lineaire entre
/// le depart et l'arrivee de l'etape — ni un lieu releve, ni un hebergement
/// verifie, parfois ni eau ni abri.
///
/// CE QUI A CHANGE, ET SEUL CELA. La tache 838 a releve, dans un couloir de
/// 3 km autour de la trace du GR20, 147 couchages d'OpenStreetMap, calcule le
/// temps de marche REEL pour les rejoindre ET en revenir (deux sens,
/// separement, sur le reseau pieton — 5 125 chemins, 132 428 aretes,
/// Dijkstra multi-source),
/// et retenu ceux qui sont a moins de trente minutes dans les deux sens. Une
/// [NuitPossible] est donc un endroit qui EXISTE, porte son identifiant
/// OpenStreetMap, son detour aller et retour, et ses lits quand OpenStreetMap
/// les connait. Sur le GR20 il y en a trente et une : les seize fins d'etape et
/// quinze coupures de jour nouvelles.
///
/// CE QUE CE MODELE NE FAIT PAS. Il ne juge pas, il n'invente pas et il ne
/// comble pas : un endroit dont le nombre de lits est inconnu rend [lits] nul,
/// et « on ne sait pas » n'est jamais ecrit « zero ».
class NuitPossible {
  /// Construit une nuit possible (toutes ses valeurs viennent du releve).
  const NuitPossible({
    required this.nom,
    required this.osm,
    required this.pkKm,
    required this.altitudeM,
    required this.lat,
    required this.lon,
    required this.minutesAller,
    required this.minutesRetour,
    required this.lits,
    required this.finDEtape,
  });

  /// Nom du lieu, tel qu'OpenStreetMap le porte.
  final String nom;

  /// Identifiants OpenStreetMap des couchages de cet endroit (ex. `way/123`).
  ///
  /// Plusieurs quand plusieurs etablissements partagent le lieu (un refuge, son
  /// camping et son gite font trois objets et une seule nuit possible).
  final List<String> osm;

  /// Point kilometrique sur la trace du sentier.
  final double pkKm;

  /// Altitude LUE sur la trace a ce point kilometrique.
  final int altitudeM;

  /// Latitude WGS84 du lieu.
  final double lat;

  /// Longitude WGS84 du lieu.
  final double lon;

  /// Minutes de marche pour QUITTER la trace et rejoindre le lieu.
  ///
  /// Zero quand le lieu est sur la trace. Calcule avec LE modele de temps de
  /// marche du depot, sur un itineraire releve.
  final int minutesAller;

  /// Minutes de marche pour REVENIR du lieu sur la trace.
  ///
  /// Mesure SEPAREMENT de [minutesAller], et ce n'est pas une coquetterie : le
  /// refuge Laparo se rejoint en 10 minutes et se quitte en 28, parce qu'on y
  /// descend et qu'on en remonte. Un seul chiffre aurait cache l'asymetrie la
  /// plus couteuse du releve.
  final int minutesRetour;

  /// Lits CONNUS d'OpenStreetMap, ou `null` quand personne ne les a renseignes.
  final int? lits;

  /// Numero de l'etape dont ce lieu est la FIN, ou `null` si c'est une coupure
  /// de jour nouvelle (un endroit que le decoupage en seize etapes ignore).
  final int? finDEtape;

  /// Vrai si ce lieu est une fin d'etape du decoupage officiel.
  bool get estFinDEtape => finDEtape != null;

  /// Vrai si l'on dort SUR la trace (aucun detour, dans aucun des deux sens).
  bool get surLaTrace => minutesAller == 0 && minutesRetour == 0;

  /// Minutes de detour d'une nuit ici : y aller le soir, en revenir le matin.
  int get minutesDeDetour => minutesAller + minutesRetour;

  /// Lit une nuit possible depuis le JSON du sentier.
  factory NuitPossible.fromJson(Map<String, dynamic> json) => NuitPossible(
    nom: json['nom'] as String,
    osm: ((json['osm'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => e as String)
        .toList(growable: false),
    pkKm: (json['pk_km'] as num).toDouble(),
    altitudeM: (json['altitude_m'] as num).round(),
    lat: (json['lat'] as num).toDouble(),
    lon: (json['lon'] as num).toDouble(),
    minutesAller: (json['minutes_aller'] as num?)?.round() ?? 0,
    minutesRetour: (json['minutes_retour'] as num?)?.round() ?? 0,
    lits: (json['lits'] as num?)?.round(),
    finDEtape: (json['fin_d_etape'] as num?)?.round(),
  );
}

/// LE CHEMIN ENTRE DEUX NUITS CONSECUTIVES, MESURE SUR LA TRACE.
///
/// C'est la brique du decoupage, et c'est tout l'interet : une journee
/// de marche est une SUITE de segments consecutifs, et ses chiffres sont la
/// SOMME de segments mesures un a un. Aucune proportion, aucune
/// interpolation — le reproche exact fait au decoupage du lot 558.
class SegmentEntreNuits {
  /// Construit un segment mesure entre deux nuits consecutives.
  const SegmentEntreNuits({
    required this.rang,
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
  });

  /// Rang du segment dans l'ordre de la trace (1-indexed).
  final int rang;

  /// Nom du lieu de depart (la tete de sentier pour le premier segment).
  final String depart;

  /// Nom de la nuit d'arrivee.
  final String arrivee;

  /// Longueur mesuree, en km.
  final double km;

  /// Denivele positif mesure, en metres.
  final int deniveleM;

  /// Denivele negatif mesure, en metres.
  final int descenteM;

  /// Temps de marche du segment, par LE modele de temps de marche du depot.
  final int minutes;

  /// Lit un segment depuis le JSON du sentier.
  factory SegmentEntreNuits.fromJson(Map<String, dynamic> json) =>
      SegmentEntreNuits(
        rang: (json['rang'] as num).round(),
        depart: json['depart'] as String,
        arrivee: json['arrivee'] as String,
        km: (json['km'] as num).toDouble(),
        deniveleM: (json['dplus_m'] as num).round(),
        descenteM: (json['dmoins_m'] as num).round(),
        minutes: (json['minutes'] as num).round(),
      );
}

/// TOUT CE QU'UN SENTIER OFFRE AU DECOUPAGE : ses nuits et ses segments.
///
/// Fourni par la donnee du sentier (`assets/data/<trail>/nuits_possibles.json`,
/// backend en P4), jamais ecrit dans le moteur. Un sentier qui n'en fournit pas
/// rend [vide] : le curseur de duree se comporte alors comme avant, aucune
/// regression pour les sentiers plus pauvres.
class DecoupageDeNuits {
  /// Construit le decoupage possible d'un sentier.
  const DecoupageDeNuits({
    required this.trailId,
    required this.teteDeSentier,
    required this.nuits,
    required this.segments,
  });

  /// Aucun decoupage disponible pour ce sentier.
  static const DecoupageDeNuits aucun = DecoupageDeNuits(
    trailId: '',
    teteDeSentier: '',
    nuits: <NuitPossible>[],
    segments: <SegmentEntreNuits>[],
  );

  /// Identifiant du sentier.
  final String trailId;

  /// Lieu de depart du sentier (on y dort AVANT de partir, pas pendant).
  final String teteDeSentier;

  /// Les nuits possibles, dans l'ordre de la trace.
  final List<NuitPossible> nuits;

  /// Les segments entre nuits consecutives, dans l'ordre de la trace.
  final List<SegmentEntreNuits> segments;

  /// Vrai quand le sentier n'offre aucune nuit au decoupage.
  bool get vide => segments.isEmpty;

  /// Nombre maximal de journees de MARCHE que ce decoupage permet.
  ///
  /// Une journee par segment : c'est le decoupage le plus fin que des lieux
  /// RELEVES autorisent. Au-dela, il faudrait inventer un point d'arret, et on
  /// ne le fait pas.
  int get journeesMaximales => segments.length;

  /// Les nuits qui ne sont PAS des fins d'etape : ce que ce lot ajoute au jeu.
  List<NuitPossible> get coupuresNouvelles =>
      nuits.where((n) => !n.estFinDEtape).toList(growable: false);

  /// Lit le decoupage depuis le JSON du sentier.
  factory DecoupageDeNuits.fromJson(
    Map<String, dynamic> json,
  ) => DecoupageDeNuits(
    trailId: json['trailId'] as String? ?? '',
    teteDeSentier: json['tete_de_sentier'] as String? ?? '',
    nuits: ((json['liste'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => NuitPossible.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    segments: ((json['entre_les_nuits'] as List<dynamic>?) ?? const <dynamic>[])
        .map((e) => SegmentEntreNuits.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}
