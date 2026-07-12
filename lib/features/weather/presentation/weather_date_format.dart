import 'package:intl/intl.dart';

/// Formatage de date robuste pour la météo (LOT-B).
///
/// `DateFormat(pattern, locale)` lève `LocaleDataException` si les données de
/// locale ne sont pas initialisées (l'app n'appelle pas `initializeDateFormatting`).
/// Ce helper tente le format localisé et retombe proprement sur un format
/// indépendant de la locale en cas d'échec — jamais d'exception à l'affichage.
String formatWeatherDate(DateTime date, String pattern, String languageCode) {
  try {
    return DateFormat(pattern, languageCode).format(date);
  } on Exception {
    // Locale non initialisée : format par défaut (en_US) sans données locale.
    return DateFormat(pattern).format(date);
  }
}
