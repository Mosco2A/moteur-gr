/// Saison de reference du Sac adaptatif (StepWays LOT 5, sous-ensemble B).
///
/// Valeurs STABLES (cles i18n + cles JSON) : `winter`/`spring`/`summer`/`autumn`.
/// String extensible (jamais un enum en donnee) — coherent avec le patron du
/// reste du moteur. Derivee d'une DATE (depart du Calendrier si posee, sinon la
/// date du jour) sur l'hemisphere NORD (le catalogue actuel est europeen ; une
/// donnee d'hemisphere par sentier pourra affiner plus tard, sans changer l'API).
abstract class Season {
  static const String winter = 'winter';
  static const String spring = 'spring';
  static const String summer = 'summer';
  static const String autumn = 'autumn';

  static const List<String> values = [winter, spring, summer, autumn];

  /// Saison (hemisphere nord) d'une [date] a partir de son mois.
  ///
  /// Repere meteorologique simple (mois) : hiver DJF, printemps MAM, ete JJA,
  /// automne SON. Suffisant pour adapter le Sac ; jamais de localite en dur.
  static String fromDate(DateTime date) {
    switch (date.month) {
      case 12:
      case 1:
      case 2:
        return winter;
      case 3:
      case 4:
      case 5:
        return spring;
      case 6:
      case 7:
      case 8:
        return summer;
      default:
        return autumn;
    }
  }
}
