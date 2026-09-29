/// PORTEE HONNETE DES PREVISIONS (tache 572, LOT U).
///
/// Chris n'a pas demande ca, mais c'est la realite du sentier : un randonneur
/// qui part dans trois semaines ne peut PAS avoir la meteo de sa journee 12, et
/// l'application doit le DIRE au lieu d'afficher du vide ou du faux.
///
/// CE QUI A CHANGE AU LOT 625, ET CELA RENVERSE L ARGUMENT DE CE FICHIER.
///
/// L APPLICATION NE DEMANDE PLUS RIEN. Elle ne choisit donc plus sa portee : elle
/// recoit celle que notre serveur a fabriquee. Ce fichier ne dit plus « ce que nous
/// demandons », il dit « ce que nous savons de ce qui arrive », et il n a plus aucun
/// parametre d appel a produire.
///
/// LA PORTEE EST CELLE DE LA DECISION DE CHRISTOPHE DU 28/09 : « le serveur a une
/// seule version de meteo par etapes et ce a 3 ou 5 jours ». La conception 611
/// d Athena retient 5 (#W6) et releve au passage que le depot en demandait DIX :
/// « C est le code qui demandait trop, pas Christophe qui demande trop peu. »
///
/// CE QUE LA PREVISION VAUT REELLEMENT (mesure conservee, c'est elle qui tranche) :
///   * NOAA : une prevision a 5 jours est juste environ 90 % du temps, a 7 jours
///     environ 80 %, a 10 jours et au-dela « environ une fois sur deux »
///     (https://scijinks.gov/forecast-reliability/).
///   * La competence des modeles progresse d'environ un jour par decennie ; on
///     ne franchit pas cette limite en demandant plus de jours a l'API.
///
/// DECISION, ECRITE DANS LE CODE COMME DEMANDE :
///   * la portee attendue est de [forecastHorizonDays] jours, et c est ce que le
///     serveur publie ;
///   * les [reliableForecastDays] premiers jours sont presentes comme une
///     PREVISION ;
///   * les jours suivants, s'il en arrive, sont presentes comme une TENDANCE — la
///     valeur est affichee, mais jamais sans le dire ;
///   * au-dela de la portee, AUCUN chiffre n'est affiche : l'ecran ecrit qu'il
///     ne sait pas encore, et a partir de quand il ne sait plus ;
///   * et, depuis ce lot, un bulletin TROP VIEUX ne rend plus aucun chiffre non
///     plus ([ForecastReach.tropVieux]) : voir `presentation/weather_freshness.dart`.
library;

/// Portee, en jours, de ce que le serveur publie.
///
/// CE N EST PLUS UN PARAMETRE D APPEL, C EST UNE ATTENTE. Rien dans
/// l application ne la transmet a qui que ce soit ; elle sert a phraser
/// « pas encore de prevision pour ce jour-la » quand aucun bulletin n est en main.
/// Quand un bulletin EST en main, c est le nombre de jours REELLEMENT recus qui
/// fait foi (`porteeRecue`) : une attente qui contredirait la donnee recue serait
/// exactement le genre de promesse que le lot 607 a ferme sur l empreinte.
const int forecastHorizonDays = 5;

/// Dernier rang de jour encore presente comme une PREVISION.
///
/// IL EGALE DESORMAIS LA PORTEE, ET CE N EST PAS UN ABANDON DU BARREAU
/// « TENDANCE ». A cinq jours, NOAA mesure ~90 % de justesse : tout ce que le
/// serveur descend est donc une prevision, et annoncer une « tendance » sur des
/// chiffres fiables serait un faux avertissement. Le barreau reste en place et
/// s allumera de lui-meme le jour ou le serveur publiera plus loin — c est la
/// recommandation d Athena (#W6), garder la distinction au lieu de la jeter.
const int reliableForecastDays = 5;

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

  /// LE BULLETIN EXISTE MAIS IL EST TROP VIEUX POUR QU ON EN MONTRE UN CHIFFRE
  /// (lot 625).
  ///
  /// C est la regle de peremption de la conception 611 (#T8) : « Au-dela de 72 h :
  /// plus aucun chiffre, l ecran dit qu il ne sait plus et depuis quand. » Elle est
  /// distincte de [noData] et la distinction compte : [noData] veut dire « je n ai
  /// rien pour ce jour-la », [tropVieux] veut dire « j ai quelque chose et je refuse
  /// de te le montrer comme si c etait d aujourd hui ». Le second doit nommer son
  /// age, le premier n en a pas.
  tropVieux,
}

/// Portee d'un jour situe a [daysAhead] jours d'aujourd'hui (0 = aujourd'hui).
///
/// Ne dit QUE ce que la position dans le temps permet de dire. Le fait que le
/// bulletin contienne ou non ce jour-la est une information distincte, portee
/// par [reachForProgramDay].
///
/// [porteeRecue] est le nombre de jours REELLEMENT presents dans le bulletin en
/// main. Quand il est fourni, il l emporte sur [forecastHorizonDays] : la donnee
/// recue fait toujours foi contre une attente ecrite dans le code. Un serveur qui
/// publierait trois jours au lieu de cinq ne doit pas faire afficher « aucune
/// donnee » sur les jours 4 et 5, mais « pas encore de prevision » — ce qui est la
/// verite.
ForecastReach forecastReachFor({required int daysAhead, int? porteeRecue}) {
  final portee = porteeRecue ?? forecastHorizonDays;
  if (daysAhead < 0) return ForecastReach.noData;
  if (daysAhead >= portee) return ForecastReach.beyondHorizon;
  if (daysAhead >= reliableForecastDays) return ForecastReach.trend;
  return ForecastReach.forecast;
}

/// Portee d'un jour de PROGRAMME : croise sa position dans le temps et la
/// presence effective d'une prevision pour ce jour-la.
///
/// [hasForecast] vient de `WeatherForecast.dayOn(date)`. Un jour dans la portee
/// mais absent du bulletin est [ForecastReach.noData] : le bulletin en cache est
/// peut-etre plus vieux que le programme, et on ne comble pas le trou.
/// [bulletinTropVieux] vient de la fraicheur du bulletin, pas de la position du
/// jour : un bulletin perime est perime pour TOUTES ses journees, y compris celle
/// d aujourd hui. Il l emporte sur tout le reste, parce que c est la seule
/// conclusion qui protege le randonneur.
ForecastReach reachForProgramDay({
  required int daysAhead,
  required bool hasForecast,
  int? porteeRecue,
  bool bulletinTropVieux = false,
}) {
  final reach = forecastReachFor(daysAhead: daysAhead, porteeRecue: porteeRecue);
  if (reach == ForecastReach.beyondHorizon) return reach;
  if (bulletinTropVieux) return ForecastReach.tropVieux;
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
