/// L'unite de temperature choisie par le randonneur, et LA seule facon d'ecrire
/// une temperature a l'ecran : une table de symboles, une conversion, un
/// format.
library;

// P2 (#101255 point 2, defaut #101197 point 2) — POURQUOI CE FICHIER EST DANS
// `lib/domain/` ET PAS DANS `features/settings/`.
//
// CE QUI MANQUAIT. Le reglage Celsius / Fahrenheit existait, s'affichait, se
// persistait (lot 645-F1) — et AUCUN ecran ne s'en servait. Les endroits qui
// montrent une temperature ecrivaient tous `'${t.round()}°'`, c'est-a-dire un
// degre sans unite, toujours en Celsius. Le randonneur qui choisissait
// Fahrenheit changeait un bouton, rien d'autre.
//
// POURQUOI UNE SEULE FONCTION, ET POURQUOI ICI. La conversion et le symbole
// recopies dans six widgets, ce sont six endroits ou l'un peut diverger des
// cinq autres au premier correctif — et l'unite de temperature n'appartient a
// AUCUNE de ces features : `settings` la choisit, `weather` et `hub`
// l'affichent. Ce qui est lu par plusieurs features monte dans `lib/domain/`
// (conventions, regle 11, ARB-645-05-c du 03/10/2026) : le metier a le droit de
// lire le socle, le socle ne remonte jamais vers le metier, et ce fichier
// n'importe rien du tout.
//
// LE MODELE RESTE EN CELSIUS, LA CONVERSION EST A L'AFFICHAGE, ET C'EST UNE
// REGLE. `DayForecast.temperatureMax`, les paliers de couleur de la carte du
// jour, les seuils de risque incendie et la requete Open-Meteo sont tous en
// degres Celsius. Convertir dans le modele les casserait tous en silence ;
// convertir au dernier moment, une seule fois, ne casse rien.

/// Unites de temperature.
///
/// `String` extensible plutot qu'un enum, pour qu'une preference inconnue se
/// replie au lieu de casser (meme choix que la langue et la distance).
typedef TemperatureUnit = String;

/// Le vocabulaire de l'unite de temperature : valeurs, libelles, symboles.
abstract class TemperatureUnitValues {
  /// Degres Celsius — le defaut du produit, et l'unite du modele.
  static const String celsius = 'celsius';

  /// Degres Fahrenheit.
  static const String fahrenheit = 'fahrenheit';

  /// Repli sur valeur inconnue ou heritee.
  static const String fallback = celsius;

  /// Les unites proposees, dans l'ordre d'affichage des Reglages.
  static const List<String> values = [celsius, fahrenheit];

  /// Libelles des unites (ecran des Reglages).
  static const Map<String, String> labels = {
    celsius: 'Celsius',
    fahrenheit: 'Fahrenheit',
  };

  /// Symboles des unites — LA table, celle que [formatTemperature] lit.
  static const Map<String, String> symbols = {celsius: '°C', fahrenheit: '°F'};

  /// Libelle d'une unite (la valeur brute si elle est inconnue).
  static String labelFor(String unit) => labels[unit] ?? unit;

  /// Symbole d'une unite (la valeur brute si elle est inconnue).
  static String symbolFor(String unit) => symbols[unit] ?? unit;

  /// Normalise une valeur lue : inconnue ou heritee -> [fallback].
  static TemperatureUnit fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Convertit une temperature exprimee en degres Celsius vers [unit].
///
/// Celsius est l'unite du modele : la conversion ne fait quelque chose que pour
/// Fahrenheit, et une unite inconnue se replie sur Celsius (aucune supposition).
double temperatureInUnit(double celsius, TemperatureUnit unit) {
  return TemperatureUnitValues.fromString(unit) ==
          TemperatureUnitValues.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;
}

/// Ecrit une temperature dans l'unite choisie : « 18 °C », « 64 °F ».
///
/// [celsius] est la valeur du modele (toujours en degres Celsius). L'espace
/// avant le symbole est la regle du SI, et elle vaut pour les deux unites.
String formatTemperature(double celsius, TemperatureUnit unit) {
  final normalisee = TemperatureUnitValues.fromString(unit);
  final valeur = temperatureInUnit(celsius, normalisee).round();
  return '$valeur ${TemperatureUnitValues.symbolFor(normalisee)}';
}

/// Ecrit une plage de deux temperatures : « 18 / 9 °C », « 64 / 48 °F ».
///
/// L'unite ne se repete pas : le SI la porte UNE fois, apres le dernier nombre
/// (« de 10 a 20 °C »). Les deux valeurs sont en degres Celsius, et l'ordre est
/// celui de l'appelant — la carte du jour montre le maximum d'abord, le bandeau
/// du cockpit le minimum : ce format ne decide pas a leur place.
String formatTemperatureRange(
  double firstCelsius,
  double secondCelsius,
  TemperatureUnit unit,
) {
  final normalisee = TemperatureUnitValues.fromString(unit);
  final premier = temperatureInUnit(firstCelsius, normalisee).round();
  return '$premier / ${formatTemperature(secondCelsius, normalisee)}';
}
