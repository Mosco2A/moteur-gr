import '../../../i18n/translations.g.dart';

/// FRAICHEUR AFFICHABLE D'UN BULLETIN METEO (tache 572, U2/U3).
///
/// Source unique du « quand est-ce que ca a ete releve » pour les deux ecrans
/// (meteo et incendie) et pour le bandeau du HUB. Elle existe parce que les deux
/// ecrans repondaient a cette question CHACUN A SA FACON, et tous les deux de
/// travers : ils lisaient `forecast.days.first.date`, c'est-a-dire le JOUR DU
/// BULLETIN (aujourd'hui a 00:00), et l'affichaient comme un horodatage de mise
/// a jour. Consequence exacte du retour de Chris : rafraichir ne changeait pas
/// un caractere a l'ecran, donc « la mise a jour ne produit rien ».
///
/// Regle, et elle ne souffre pas d'exception : on affiche l'age REEL, ou on
/// declare qu'on ne le connait pas. Un bulletin de trois jours presente comme
/// frais est un mensonge dangereux en montagne.

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

/// Gravite de la fraicheur, pour la couleur du bandeau.
enum FreshnessLevel {
  /// Releve a l'instant (< 1 h) : donnee de confiance.
  fresh,

  /// Releve recemment (< [staleAfter]) : utilisable, age affiche.
  recent,

  /// Releve il y a longtemps : utilisable mais l'age est mis en avant.
  stale,

  /// Instant du releve inconnu (bulletin construit en memoire, seed de demo).
  unknown,
}

/// Seuil au-dela duquel l'age d'un bulletin passe au premier plan.
///
/// Trois heures : la meme fenetre que le TTL de re-telechargement
/// (`WeatherCacheDao.cacheTtlHours`). Passe cette borne, l'application a voulu
/// rafraichir et n'a pas pu — c'est exactement ce que le randonneur doit savoir.
const Duration staleAfter = Duration(hours: 3);

/// Fraicheur d'un bulletin : niveau + phrase prete a afficher.
class WeatherFreshness {
  const WeatherFreshness({required this.level, required this.label});

  final FreshnessLevel level;
  final String label;
}

/// Construit la fraicheur affichable d'un bulletin releve a [fetchedAt].
///
/// [now] est injectable pour rester deterministe en test.
WeatherFreshness weatherFreshness({
  required DateTime? fetchedAt,
  required Translations t,
  DateTime? now,
}) {
  if (fetchedAt == null) {
    return WeatherFreshness(
      level: FreshnessLevel.unknown,
      label: t.weather.freshness.never,
    );
  }
  final diff = (now ?? DateTime.now()).difference(fetchedAt);
  if (diff.inMinutes < 1) {
    return WeatherFreshness(
      level: FreshnessLevel.fresh,
      label: t.weather.freshness.justNow,
    );
  }
  if (diff < staleAfter) {
    return WeatherFreshness(
      level: FreshnessLevel.recent,
      label: t.weather.freshness.at(date: formatFetchedAt(fetchedAt)),
    );
  }
  return WeatherFreshness(
    level: FreshnessLevel.stale,
    label: t.weather.freshness
        .stale(duration: formatFreshnessDuration(diff, t)),
  );
}
