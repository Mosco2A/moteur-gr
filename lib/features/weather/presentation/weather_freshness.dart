import '../../../i18n/translations.g.dart';

/// L AGE D UN BULLETIN METEO, ET CE QU IL AUTORISE A AFFICHER.
///
/// C EST LE POINT LE PLUS IMPORTANT DU LOT 625, et la phrase qui le commande est
/// celle de Christophe : **une meteo de trois jours presentee comme fraiche a
/// quelqu un qui decide de passer un col est dangereuse.** Tout ce fichier existe
/// pour que cette presentation soit impossible.
///
/// CE QUI A CHANGE PAR RAPPORT A LA TACHE 572. L age etait calcule sur l instant du
/// RELEVE par le telephone (`fetchedAt`). Il l est desormais sur l instant de
/// FABRICATION par le modele meteo (`WeatherForecast.produiteLe`), pose par le
/// serveur — demande explicite de Christophe le 28/09. Les deux peuvent differer de
/// plusieurs heures, et c est precisement cet ecart qui trompait : un bulletin
/// telecharge a l instant pouvait avoir ete fabrique la veille, et il s affichait
/// « releve a l instant ».
///
/// LES TROIS SEUILS VIENNENT DE LA CONCEPTION 611 (#T8), PAS D UNE INTUITION :
/// « Meteo : peremption 6 h pour le jour courant, 24 h pour les suivants. Passe la
/// peremption, la prevision reste affichee, GRISEE ET DATEE. Au-dela de 72 h : plus
/// aucun chiffre, l ecran dit qu il ne sait plus et depuis quand. »
///
/// ET POURQUOI LA METEO GARDE SA DONNEE PERIMEE JUSQU A 72 H ALORS QUE LE RISQUE
/// INCENDIE NON (#T10) : « Une prevision de trois jours reste une INFORMATION : elle
/// dit la tendance, et datee elle n induit pas en erreur. Un niveau de danger
/// d incendie de la veille est une ASSERTION SUR AUJOURD HUI. » La difference n est
/// pas la gravite, c est que l un se lit comme un souvenir et l autre comme un etat.

/// Peremption du JOUR COURANT du bulletin (#T8).
///
/// Six heures, et la valeur n est pas ronde par hasard : c est en dessous de la
/// cadence de collecte du serveur (4 h, #W5). Un bulletin plus vieux que six heures
/// signifie donc qu AU MOINS une collecte n est pas arrivee jusqu a ce telephone —
/// ce qui est exactement ce que le randonneur doit savoir.
const Duration peremptionDuJourCourant = Duration(hours: 6);

/// Peremption des JOURS SUIVANTS du bulletin (#T8).
///
/// Vingt-quatre heures, parce qu une prevision a J+2 ne change pas au meme rythme
/// que le temps de cet apres-midi. Grisez les jours suivants des six heures et le
/// randonneur apprend a ignorer le grise.
const Duration peremptionDesJoursSuivants = Duration(hours: 24);

/// AU-DELA, PLUS AUCUN CHIFFRE (#T8). Soixante-douze heures.
///
/// C est litteralement « la meteo de trois jours » de Christophe. Passe cette borne
/// l ecran ne montre PAS la prevision grisee : il ne la montre plus du tout, et il
/// dit depuis combien de temps il ne sait plus. Griser eternellement finit par
/// devenir une decoration qu on ne lit plus ; retirer les chiffres, non.
const Duration plusAucunChiffreApres = Duration(hours: 72);

/// Duree lisible via Slang (memes paliers que l'ecran incendie, une seule fois).
String formatFreshnessDuration(Duration diff, Translations t) {
  if (diff.inMinutes < 1) return t.weather.duration.seconds;
  if (diff.inMinutes < 60) return t.weather.duration.minutes(n: diff.inMinutes);
  if (diff.inHours < 24) return t.weather.duration.hours(n: diff.inHours);
  return t.weather.duration.days(n: diff.inDays);
}

/// Horodatage JJ/MM/AAAA HH:MM (independant de la locale, aucune donnee intl
/// requise — un ecran ne doit pas perdre sa date parce qu'une locale manque).
String formatFetchedAt(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/'
    '${dt.month.toString().padLeft(2, '0')}/'
    '${dt.year} '
    '${dt.hour.toString().padLeft(2, '0')}:'
    '${dt.minute.toString().padLeft(2, '0')}';

/// Ce que l age du bulletin autorise a montrer.
enum FreshnessLevel {
  /// Fabrique il y a moins de [peremptionDuJourCourant] : tout s affiche.
  fresh,

  /// Le jour courant est perime, les jours suivants non : le chiffre du jour est
  /// grise et date, le reste tient.
  jourCourantPerime,

  /// Tout le bulletin est perime mais reste une information : chiffres grises et
  /// dates, age mis au premier plan.
  stale,

  /// Plus de [plusAucunChiffreApres] : AUCUN CHIFFRE. L ecran dit qu il ne sait
  /// plus, et depuis quand.
  tropVieux,

  /// Date de fabrication inconnue (bulletin construit en memoire, jeu de
  /// demonstration). On declare l ignorance, on ne suppose pas zero.
  unknown,
}

/// Fraicheur d'un bulletin : niveau + phrase prete a afficher.
class WeatherFreshness {
  const WeatherFreshness({
    required this.level,
    required this.label,
    this.age,
  });

  final FreshnessLevel level;
  final String label;

  /// Age reel du bulletin, `null` quand la date de fabrication est inconnue.
  final Duration? age;

  /// VRAI QUAND AUCUN CHIFFRE NE DOIT S AFFICHER.
  ///
  /// Un seul predicat, lu par tous les ecrans. Deux ecrans qui decideraient
  /// chacun de leur cote a partir de quel age ils se taisent finiraient par ne pas
  /// se taire au meme moment — et c est le defaut que la tache 572 a deja eu a
  /// corriger sur la ligne de mise a jour.
  bool get plusAucunChiffre => level == FreshnessLevel.tropVieux;

  /// Vrai quand le chiffre du JOUR COURANT doit etre grise.
  bool get jourCourantGrise =>
      level == FreshnessLevel.jourCourantPerime ||
      level == FreshnessLevel.stale ||
      level == FreshnessLevel.tropVieux;

  /// Vrai quand les chiffres des JOURS SUIVANTS doivent etre grises.
  bool get joursSuivantsGrises =>
      level == FreshnessLevel.stale || level == FreshnessLevel.tropVieux;
}

/// Construit la fraicheur affichable d un bulletin fabrique a [produiteLe].
///
/// [now] est injectable pour rester deterministe en test.
///
/// LE CAS « JAMAIS DE DATE » N EST PAS UN CAS D ERREUR. Un bulletin de
/// demonstration n a pas de date de fabrication, et il ne doit pas en recevoir une
/// d office : `t.weather.fabrication.unknown` dit l ignorance. Le cas « jamais de
/// BULLETIN », lui, ne passe pas ici du tout — il n y a rien a dater. Il est traite
/// par l ecran, qui explique au randonneur que la meteo arrivera avec les donnees
/// du sentier.
WeatherFreshness weatherFreshness({
  required DateTime? produiteLe,
  required Translations t,
  DateTime? now,
}) {
  if (produiteLe == null) {
    return WeatherFreshness(
      level: FreshnessLevel.unknown,
      label: t.weather.fabrication.unknown,
    );
  }
  final age = (now ?? DateTime.now()).difference(produiteLe);

  // UN BULLETIN FABRIQUE DANS LE FUTUR EST TRAITE COMME FRAIS, ET C EST LE BON
  // ARBITRAGE. Cela arrive quand l horloge du telephone retarde. Le dire « perime »
  // serait faux, et le refuser laisserait un ecran vide sur une donnee valide : on
  // choisit l erreur qui ne prive de rien, comme le fait #H5 de la spec 605 pour le
  // repere de synchronisation.
  if (age.isNegative || age < const Duration(minutes: 1)) {
    return WeatherFreshness(
      level: FreshnessLevel.fresh,
      label: t.weather.fabrication.justNow,
      age: age.isNegative ? Duration.zero : age,
    );
  }

  if (age >= plusAucunChiffreApres) {
    return WeatherFreshness(
      level: FreshnessLevel.tropVieux,
      label: t.weather.fabrication.expired(
        duration: formatFreshnessDuration(age, t),
      ),
      age: age,
    );
  }

  if (age >= peremptionDesJoursSuivants) {
    return WeatherFreshness(
      level: FreshnessLevel.stale,
      label: t.weather.fabrication.stale(
        duration: formatFreshnessDuration(age, t),
      ),
      age: age,
    );
  }

  if (age >= peremptionDuJourCourant) {
    return WeatherFreshness(
      level: FreshnessLevel.jourCourantPerime,
      label: t.weather.fabrication.todayStale(
        duration: formatFreshnessDuration(age, t),
        date: formatFetchedAt(produiteLe),
      ),
      age: age,
    );
  }

  return WeatherFreshness(
    level: FreshnessLevel.fresh,
    label: t.weather.fabrication.at(date: formatFetchedAt(produiteLe)),
    age: age,
  );
}
