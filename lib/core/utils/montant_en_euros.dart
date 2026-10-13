/// Le seul endroit du depot qui ecrit un montant d'argent a l'ecran.
library;

import 'package:intl/intl.dart';

/// Ecrit [montant] euros dans la langue [langue] : separateur ET place du
/// symbole, tous deux pris a la langue et non au code.
///
/// CE QUE CETTE FONCTION FERME (tache 806). Cinq endroits de `lib/` affichaient
/// un montant, et ils l'ecrivaient de TROIS facons differentes :
///
///   1. `toStringAsFixed(2)` nu, qui rend « 6.93 » avec un POINT — en francais,
///      en allemand, en espagnol et en italien, c'est une faute d'ecriture ;
///   2. `toStringAsFixed(2).replaceAll('.', ',')`, qui impose la virgule
///      FRANCAISE a tout le monde — juste pour quatre langues sur cinq, faux
///      pour l'anglais, et faux pour toute langue qu'on ajouterait ensuite ;
///   3. un `_euros()` prive a l'ecran d'abonnement, qui retirait la decimale
///      inutile mais gardait le point.
///
/// Aucune des trois ne regardait la langue active. Le remplacement a la main
/// d'un separateur est le signe que personne n'avait traite le sujet au fond :
/// on ne choisit pas un separateur decimal, on le LIT dans la langue, comme on
/// lit deja le format des dates.
///
/// POURQUOI LE SYMBOLE EST ICI ET PLUS DANS LA TRADUCTION. Il y vivait, et il
/// y etait juste : « 9,99 € » en francais, « €9.99 » en anglais. Mais cela
/// voulait dire que sa place etait recopiee dans CINQ fichiers, a la main, et
/// qu'elle pouvait diverger du separateur decimal — ce qui etait precisement
/// en train d'arriver. [NumberFormat.currency] tient les deux ensemble, et il
/// les tient depuis la table CLDR, qui fait reference sur le sujet. Une langue
/// de plus n'aura rien a declarer.
///
/// L'ESPACE QUI PRECEDE LE SYMBOLE EST INSECABLE (U+00A0), mesure a l'unite de
/// code. Les cinq traductions ecrivaient une espace ORDINAIRE : un prix
/// pouvait se couper entre le nombre et le symbole en bout de ligne.
///
/// LA DECIMALE INUTILE EST CONSERVEE COMME REGLE, parce que c'etait deja la
/// regle du depot : un montant rond s'ecrit « 2 € » et non « 2,00 € » (c'est ce
/// que faisait `_euros()` a l'ecran d'abonnement). Elle est seulement passee
/// d'un ecran a tous. Les prix de la grille (9,99 / 19,99 / 34,99) ont une
/// decimale et la gardent.
///
/// CE QU'ELLE N'ECRIT PAS, ET C'EST LE FOND DE LA TACHE 806 : le prix d'un
/// SENTIER. Un sentier ne coute pas d'euros, il coute des ETAPES, et le prix
/// d'une etape en euros depend de la facon dont le randonneur a rempli sa
/// cagnotte — a l'unite, par pack, ou par cagnotage de l'abonnement. Cette
/// fonction sert le COMPTOIR (la cagnotte, l'abonnement), la ou l'on paye
/// vraiment avec de l'argent. Une garde refuse qu'elle remonte sur une carte de
/// sentier : `test/structurel/un_sentier_se_paye_en_etapes_806_test.dart`.
String montantEnEuros(double montant, String langue) {
  // UN MONTANT ROND N'AFFICHE PAS SES CENTIMES (regle reprise de l'ecran
  // d'abonnement, ou l'abonnement a 2,0 s'ecrivait « 2 »).
  final decimales = montant == montant.roundToDouble() ? 0 : 2;
  return NumberFormat.currency(
    locale: langue,
    symbol: '€',
    decimalDigits: decimales,
  ).format(montant);
}
