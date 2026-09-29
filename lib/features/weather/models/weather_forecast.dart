import '../../../core/data/revision_de_donnee.dart';

/// Prévision météo quotidienne pour un point géographique.
///
/// ELLE N EST PLUS CONSTRUITE DEPUIS UNE REPONSE DE FOURNISSEUR (lot 625). Elle est
/// construite depuis ce que NOTRE SERVEUR a fabrique et depose, et que
/// l application a recopie en base par le meme chemin que les etapes ou les points
/// d interet. Decision de Christophe du 28/09, verbatim : « Ce n est pas l appli qui
/// demande la meteo mais notre serveur. »
///
/// CE QUE CELA SUPPRIME, ET C EST LA MESURE DU LOT : la fabrique
/// `WeatherForecast.fromOpenMeteo` n existe plus, et avec elle le dernier endroit du
/// depot qui connaissait la forme d un fournisseur de meteo. L application ne sait
/// plus d ou vient le temps qu il fait — elle sait seulement QUAND il a ete regarde.
class WeatherForecast {
  const WeatherForecast({
    required this.days,
    required this.latitude,
    required this.longitude,
    this.produiteLe,
    this.collecteeLe,
    this.source,
  });

  final List<DayForecast> days;
  final double latitude;
  final double longitude;

  /// INSTANT DE FABRICATION PAR LE MODELE METEO — LA SEULE DATE QU ON AFFICHE.
  ///
  /// DEMANDE EXPLICITE DE CHRISTOPHE, 28/09 : « la date affichee est celle de
  /// FABRICATION », pas celle du telechargement. Les deux peuvent differer de
  /// plusieurs heures, et c est justement l ecart qui est dangereux : un bulletin
  /// telecharge a l instant peut avoir ete fabrique la veille.
  ///
  /// SON TYPE EST CE QUI EMPECHE LE MENSONGE, PAS UN COMMENTAIRE.
  /// [HorodatageServeur] ne se construit qu en LISANT une valeur venue du serveur ;
  /// `HorodatageServeur(DateTime.now())` n existe pas. Une date de fabrication posee
  /// par l horloge du telephone est donc une erreur de COMPILATION, pas une
  /// vigilance a maintenir de lot en lot.
  ///
  /// `null` seulement pour un bulletin construit en memoire (jeu de demonstration,
  /// fixture de test) : l ecran dit alors qu il ne connait pas l age, jamais qu il
  /// est nul.
  final HorodatageServeur? produiteLe;

  /// Instant ou notre serveur a reussi sa collecte. EXPLOITATION SEULEMENT.
  ///
  /// La conception 611 le tranche (#W11) : trois dates existent, une seule
  /// s affiche. Celle-ci sert a comprendre une source qui radote — elle bouge
  /// pendant que [produiteLe] reste immobile — et l afficher au randonneur
  /// lui ferait croire a un bulletin neuf.
  final HorodatageServeur? collecteeLe;

  /// Fournisseur nomme dans la donnee (#A3). `null` pour un bulletin en memoire.
  final String? source;

  /// Le point qu on affiche, en heure locale lisible.
  DateTime? get produiteLeLocal => produiteLe?.date.toLocal();

  /// Age du bulletin a [now] (horloge injectable pour les tests).
  ///
  /// `null` quand l instant de fabrication est inconnu — un age inconnu doit
  /// s afficher comme inconnu, jamais comme zero.
  ///
  /// L HORLOGE DU TELEPHONE INTERVIENT ICI, ET C EST LE SEUL ENDROIT OU ELLE PEUT.
  /// Un age est une difference avec maintenant : hors reseau, il n existe aucune
  /// autre reference. Consequence a connaitre : un telephone dont l horloge retarde
  /// de deux jours affichera un bulletin de deux jours comme frais. On ne peut pas
  /// le detecter sans reseau — mais on peut refuser de FABRIQUER la date de
  /// fabrication, et c est ce que fait [produiteLe].
  Duration? ageAt([DateTime? now]) => produiteLe == null
      ? null
      : (now ?? DateTime.now()).toUtc().difference(produiteLe!.date);

  /// Prevision du JOUR CALENDAIRE [date] (comparaison a la journee, pas a
  /// l instant), ou `null` si ce jour n est pas couvert par le bulletin.
  ///
  /// TACHE 572 (U1) : c est l acces dont le programme a besoin. Le randonneur ne
  /// veut pas « le jour 3 du bulletin », il veut « le mardi 22, la ou je serai
  /// ce mardi-la ». Les deux ne coincident que si le trek part aujourd hui.
  DayForecast? dayOn(DateTime date) {
    for (final d in days) {
      if (d.date.year == date.year &&
          d.date.month == date.month &&
          d.date.day == date.day) {
        return d;
      }
    }
    return null;
  }

  /// LE BULLETIN TEL QUE LE SERVEUR L A PUBLIE.
  ///
  /// [jours] est la valeur du champ `jours` du fichier publie, relue telle quelle
  /// depuis la colonne `trail_meteo.joursJson`. Il n y a donc PAS de troisieme
  /// format entre le serveur, la base et l ecran : la forme publiee est la forme
  /// stockee est la forme lue. Le lot 606 a paye le prix de trois definitions
  /// concurrentes de la meme donnee ; il n en existe ici qu une.
  factory WeatherForecast.depuisLePublie({
    required List<dynamic> jours,
    required double latitude,
    required double longitude,
    required HorodatageServeur produiteLe,
    HorodatageServeur? collecteeLe,
    String? source,
  }) {
    return WeatherForecast(
      days: jours
          .whereType<Map>()
          .map((j) => DayForecast.depuisLePublie(Map<String, dynamic>.from(j)))
          .toList(growable: false),
      latitude: latitude,
      longitude: longitude,
      produiteLe: produiteLe,
      collecteeLe: collecteeLe,
      source: source,
    );
  }
}

/// Prévision pour une journée unique.
class DayForecast {
  const DayForecast({
    required this.date,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.precipitationMm,
    required this.windSpeedKmh,
    required this.uvIndex,
    required this.weatherCode,
    this.precipitationProbabilityMax,
  });

  final DateTime date;
  final double temperatureMax;
  final double temperatureMin;
  final double precipitationMm;
  final double windSpeedKmh;
  final double uvIndex;

  /// Code WMO.
  ///
  /// IL RESTE UN CODE WMO, ET C EST LE COLLECTEUR QUI S Y PLIE. La conception 611
  /// le dit (#W7) : « traduire le `symbol_code` de MET Norway vers le code WMO que
  /// l application attend », et cette traduction vit dans le collecteur, une fois,
  /// pour tout le monde. L application ne connait donc aucun vocabulaire de
  /// fournisseur.
  final int weatherCode;

  /// Probabilité maximale de précipitations dans la journée (0-100 %).
  ///
  /// Nullable : un serveur qui ne l agrege pas ne doit pas rendre le bulletin
  /// illisible. `stormProbability` retombe alors sur le code WMO seul.
  final double? precipitationProbabilityMax;

  /// Indicateur de conditions dangereuses (orage, neige, pluie forte)
  bool get isAlertCondition =>
      weatherCode >= 65 || // Pluie forte, neige, orage
      windSpeedKmh >= 60 || // Vent très fort
      precipitationMm >= 20; // Grosses précipitations

  /// Vrai si un orage est prévu (code WMO 95/96/99).
  bool get isStorm => weatherCode >= 95;

  /// Probabilité d'orage dérivée (0-100 %) — AM-7.
  double get stormProbability {
    if (isStorm) return 100;
    return precipitationProbabilityMax ?? 0;
  }

  /// Description textuelle du code météo WMO
  String get weatherDescription {
    return _wmoCodeDescriptions[weatherCode] ?? 'Inconnu';
  }

  /// Icône du code météo (nom Material Icon)
  String get weatherIconName {
    if (weatherCode <= 1) return 'wb_sunny';
    if (weatherCode <= 3) return 'cloud';
    if (weatherCode <= 48) return 'foggy';
    if (weatherCode <= 57) return 'grain';
    if (weatherCode <= 67) return 'water_drop';
    if (weatherCode <= 77) return 'ac_unit';
    if (weatherCode <= 82) return 'thunderstorm';
    if (weatherCode <= 86) return 'ac_unit';
    return 'thunderstorm';
  }

  /// LES NOMS DE CHAMPS DU FICHIER PUBLIE, ET C EST LE CONTRAT AVEC LE COLLECTEUR.
  ///
  /// SNAKE_CASE, comme les sept autres familles du fichier publie. Ce n est pas un
  /// gout : le depot porte deja le piege inverse (#S11 de la spec 605) — le fichier
  /// EMBARQUE est en camelCase, le fichier PUBLIE en snake_case, et les deux
  /// ecritures du Mare a Mare se contredisent pour cette raison exacte. Une
  /// huitieme famille publiee en camelCase aurait rouvert ce piege.
  Map<String, dynamic> versLePublie() => {
        'date': date.toIso8601String(),
        'temperature_max': temperatureMax,
        'temperature_min': temperatureMin,
        'precipitation_mm': precipitationMm,
        'wind_speed_kmh': windSpeedKmh,
        'uv_index': uvIndex,
        'weather_code': weatherCode,
        if (precipitationProbabilityMax != null)
          'precipitation_probability_max': precipitationProbabilityMax,
      };

  /// Relit un jour publie par le serveur.
  ///
  /// UNE DATE SANS FUSEAU EST LUE EN LOCAL, ET C EST VOULU ICI — a la difference
  /// des horodatages de synchronisation. Un jour de prevision est une JOURNEE
  /// CALENDAIRE (« mardi »), pas un instant : la convertir en UTC decalerait le
  /// mardi du randonneur d un jour a l est de Greenwich.
  factory DayForecast.depuisLePublie(Map<String, dynamic> json) {
    return DayForecast(
      date: DateTime.parse(json['date'] as String),
      temperatureMax: (json['temperature_max'] as num).toDouble(),
      temperatureMin: (json['temperature_min'] as num).toDouble(),
      precipitationMm: (json['precipitation_mm'] as num).toDouble(),
      windSpeedKmh: (json['wind_speed_kmh'] as num).toDouble(),
      uvIndex: (json['uv_index'] as num).toDouble(),
      weatherCode: json['weather_code'] as int,
      precipitationProbabilityMax:
          (json['precipitation_probability_max'] as num?)?.toDouble(),
    );
  }
}

/// Descriptions des codes météo WMO
const Map<int, String> _wmoCodeDescriptions = {
  0: 'Ciel dégagé',
  1: 'Principalement dégagé',
  2: 'Partiellement nuageux',
  3: 'Couvert',
  45: 'Brouillard',
  48: 'Brouillard givrant',
  51: 'Bruine légère',
  53: 'Bruine modérée',
  55: 'Bruine dense',
  56: 'Bruine verglaçante',
  57: 'Bruine verglaçante forte',
  61: 'Pluie légère',
  63: 'Pluie modérée',
  65: 'Pluie forte',
  66: 'Pluie verglaçante',
  67: 'Pluie verglaçante forte',
  71: 'Neige légère',
  73: 'Neige modérée',
  75: 'Neige forte',
  77: 'Grains de neige',
  80: 'Averses légères',
  81: 'Averses modérées',
  82: 'Averses violentes',
  85: 'Averses de neige',
  86: 'Averses de neige fortes',
  95: 'Orage',
  96: 'Orage avec grêle légère',
  99: 'Orage avec grêle forte',
};
