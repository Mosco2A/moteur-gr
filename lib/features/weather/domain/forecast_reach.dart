/// PORTEE HONNETE DES PREVISIONS (tache 572, LOT U).
///
/// Chris n'a pas demande ca, mais c'est la realite du sentier : un randonneur
/// qui part dans trois semaines ne peut PAS avoir la meteo de sa journee 12, et
/// l'application doit le DIRE au lieu d'afficher du vide ou du faux.
///
/// CE QUE LE FOURNISSEUR PERMET REELLEMENT (verifie, pas suppose) :
///   * Open-Meteo `forecast_days` accepte 0 a 16, valeur par defaut 7
///     (https://open-meteo.com/en/docs). Le module demandait 7 : un trek de
///     dix jours perdait donc ses trois derniers jours sans que rien ne le dise.
///   * Quota gratuit non commercial : moins de 10 000 appels/jour, 5 000/heure,
///     600/minute (https://open-meteo.com/en/pricing). Un appel par etape reste
///     tres loin de ces bornes, et le cache les divise encore.
///
/// CE QUE LA PREVISION VAUT REELLEMENT (et c'est ca qui fixe la limite) :
///   * NOAA : une prevision a 5 jours est juste environ 90 % du temps, a 7 jours
///     environ 80 %, a 10 jours et au-dela « environ une fois sur deux »
///     (https://scijinks.gov/forecast-reliability/).
///   * La competence des modeles progresse d'environ un jour par decennie ; on
///     ne franchit pas cette limite en demandant plus de jours a l'API.
///
/// DECISION, ECRITE DANS LE CODE COMME DEMANDE :
///   * on DEMANDE 10 jours ([forecastHorizonDays]) : c'est autorise par le
///     fournisseur et ca couvre la grande majorite des treks ;
///   * les [reliableForecastDays] premiers jours sont presentes comme une
///     PREVISION ;
///   * les jours suivants, jusqu'a l'horizon, sont presentes comme une
///     TENDANCE — la valeur est affichee, mais jamais sans le dire ;
///   * au-dela de l'horizon, AUCUN chiffre n'est affiche : l'ecran ecrit qu'il
///     ne sait pas encore, et a partir de quand il ne sait plus.
library;

/// Nombre de jours de prevision DEMANDES au fournisseur.
///
/// Doit rester <= 16 (borne `forecast_days` d'Open-Meteo). Toute valeur
/// annoncee a l'ecran DERIVE de cette constante : l'ecran ne peut donc pas
/// promettre une portee que l'appel ne demande pas.
const int forecastHorizonDays = 10;

/// Dernier rang de jour encore presente comme une PREVISION (NOAA : ~80 % de
/// justesse a 7 jours). Au-dela, c'est une tendance.
const int reliableForecastDays = 7;

/// Ce que vaut la prevision d'un jour donne, du point de vue du randonneur.
enum ForecastReach {
  /// Jour couvert et dans la fenetre fiable : c'est une prevision.
  forecast,

  /// Jour couvert mais au-dela de la fenetre fiable : c'est une tendance.
  trend,

  /// Jour hors de la portee du fournisseur : on ne sait pas encore, et on le dit.
  beyondHorizon,

  /// Jour dans la portee, mais le bulletin ne le contient pas (bulletin partiel,
  /// ancien, ou lieu sans donnee) : on le dit aussi, on n'extrapole pas.
  noData,

  /// Pas de date de depart : impossible de savoir quel jour le randonneur sera
  /// a quelle etape. On demande la date au lieu de supposer aujourd'hui.
  unknownDeparture,
}

/// Portee d'un jour situe a [daysAhead] jours d'aujourd'hui (0 = aujourd'hui).
///
/// Ne dit QUE ce que la position dans le temps permet de dire. Le fait que le
/// bulletin contienne ou non ce jour-la est une information distincte, portee
/// par [reachForProgramDay].
ForecastReach forecastReachFor({required int daysAhead}) {
  if (daysAhead < 0) return ForecastReach.noData;
  if (daysAhead >= forecastHorizonDays) return ForecastReach.beyondHorizon;
  if (daysAhead >= reliableForecastDays) return ForecastReach.trend;
  return ForecastReach.forecast;
}

/// Portee d'un jour de PROGRAMME : croise sa position dans le temps et la
/// presence effective d'une prevision pour ce jour-la.
///
/// [hasForecast] vient de `WeatherForecast.dayOn(date)`. Un jour dans la portee
/// mais absent du bulletin est [ForecastReach.noData] : le bulletin en cache est
/// peut-etre plus vieux que le programme, et on ne comble pas le trou.
ForecastReach reachForProgramDay({
  required int daysAhead,
  required bool hasForecast,
}) {
  final reach = forecastReachFor(daysAhead: daysAhead);
  if (reach == ForecastReach.beyondHorizon) return reach;
  return hasForecast ? reach : ForecastReach.noData;
}

/// Nombre de jours calendaires entre [from] et [to] (journees, pas instants).
///
/// Les deux dates sont ramenees a leur jour : un depart a 18:00 et une prevision
/// a 00:00 le meme jour valent 0 jour d'ecart, pas -1.
int calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime(from.year, from.month, from.day);
  final b = DateTime(to.year, to.month, to.day);
  return b.difference(a).inDays;
}
