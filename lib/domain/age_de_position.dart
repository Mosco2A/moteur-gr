/// L'AGE D'UNE POSITION, DIT EN LANGAGE DE RANDONNEUR (lot 671-04).
///
/// Le dialogue SOS l'affiche sous la position connue, et le lot 671-05 (le
/// marquage d'un point sans reveiller le GPS) le reprendra : c'est ICI que se
/// decide comment un age se calcule et se dit, une fois pour toutes.
///
/// LA REGLE, NOMMEE : SOUS UNE MINUTE, « A L'INSTANT » ; AU-DELA, LES MINUTES
/// ENTIERES, ARRONDIES VERS LE BAS ; AU-DELA D'UNE HEURE, LES HEURES ET LES
/// MINUTES. Vers le bas, parce qu'annoncer deux minutes quand il y en a trois
/// est un mensonge dans une situation d'urgence ; arrondir vers le bas ne
/// peut que SOUS-estimer la fraicheur, jamais la vanter. 179 secondes font
/// donc deux minutes, jamais trois.
///
/// DART PUR : ni Flutter, ni horloge. L'age se calcule sur une heure
/// INJECTEE par l'appelant, jamais sur `DateTime.now()` appele ici.
library;

/// En deca, une position est « a l'instant ».
const Duration kAgeALInstant = Duration(minutes: 1);

/// Un age en heures et minutes entieres, arrondi vers le bas.
typedef AgeEnClair = ({int heures, int minutes});

/// L'age d'une position mesuree a [mesureeA], vu a [maintenant] : nul pour
/// « a l'instant » (sous [kAgeALInstant], ou une heure de mesure dans le
/// futur, que l'horloge d'un autre appareil peut donner).
AgeEnClair? ageEnClair({
  required DateTime mesureeA,
  required DateTime maintenant,
}) {
  final age = maintenant.difference(mesureeA);
  if (age < kAgeALInstant) return null;
  final minutes = age.inMinutes;
  return (heures: minutes ~/ 60, minutes: minutes % 60);
}
