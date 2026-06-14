import '../../../i18n/translations.g.dart';

/// Met en forme la FRAICHEUR d'une donnee (F8A-04, R3) : « maj il y a X ».
///
/// Convertit une [Duration] d'anciennete en libelle i18n (Slang 5 langues)
/// sous le namespace `waypoints.freshness.*`. Aucune logique reseau : prend en
/// entree l'anciennete deja calculee par [WaypointView.freshness].
String formatFreshness(Translations t, Duration age) {
  if (age.inMinutes < 1) {
    return t.waypoints.freshness.justNow;
  }
  if (age.inMinutes < 60) {
    return t.waypoints.freshness.minutes(n: age.inMinutes);
  }
  if (age.inHours < 24) {
    return t.waypoints.freshness.hours(n: age.inHours);
  }
  return t.waypoints.freshness.days(n: age.inDays);
}
