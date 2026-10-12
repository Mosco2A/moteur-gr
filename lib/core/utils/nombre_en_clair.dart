/// Le seul endroit du depot qui ecrit un NOMBRE MESURE a l'ecran.
library;

import 'package:intl/intl.dart';

/// Ecrit [valeur] avec [decimales] chiffres apres la virgule, dans la langue
/// [langue] : le SEPARATEUR DECIMAL est pris a la langue, jamais au code.
///
/// CE QUE CETTE FONCTION FERME (tache 835). La tache 806 avait traite le sujet
/// pour l'ARGENT et laisse dans `montant_en_euros.dart` la lecon ecrite noir
/// sur blanc : « `toStringAsFixed(2)` nu rend « 6.93 » avec un POINT — en
/// francais, en allemand, en espagnol et en italien, c'est une faute
/// d'ecriture ». Cette lecon n'avait jamais ete portee aux nombres qui ne sont
/// pas de l'argent, et le randonneur francais lisait donc :
///
///   « 19.9 km », « 27.0 Mo », « 2.7 km/h », « 1.6 % »
///
/// alors que les textes ecrits a la main, eux, etaient deja justes (les
/// fiches conseils ecrivent bien « 0,5 a 1 litre par heure »). L'ecart ne
/// venait donc pas de la langue : il venait de ce que le nombre CALCULE
/// n'etait pas formate du tout, juste interpole.
///
/// POURQUOI AU FORMATEUR ET PAS A LA MAIN. Le reflexe
/// `toStringAsFixed(1).replaceAll('.', ',')` est faux, et le dossier 806 dit
/// deja pourquoi : il impose la virgule FRANCAISE a tout le monde, donc il est
/// faux pour l'anglais et faux pour toute langue qu'on ajouterait ensuite. On
/// ne CHOISIT pas un separateur decimal, on le LIT dans la langue — comme on
/// lit deja le format des dates et la place du symbole monetaire. C'est la
/// table CLDR, portee par [NumberFormat], qui fait reference sur le sujet.
///
/// CE QU'ELLE NE FAIT PAS : elle n'ecrit PAS l'unite. « km », « Mo », « km/h »
/// et « % » restent dans les fichiers de langue, a cote du nombre, parce que
/// leur place dans la phrase change d'une langue a l'autre et que ce n'est pas
/// au formateur d'en decider.
///
/// ELLE NE SERT PAS AUX COORDONNEES GPS, volontairement. Une latitude s'ecrit
/// en notation internationale a point (42.1234), comme sur une carte ou sur un
/// recepteur GPS : la franciser serait une faute inverse. Les coordonnees
/// gardent donc `toStringAsFixed` nu, et c'est un choix, pas un oubli.
///
/// ELLE NE SERT PAS NON PLUS AUX JOURNAUX NI AUX CLES TECHNIQUES. Un
/// `_log.d('... 27.0 Mo')` n'est pas lu par un randonneur, et une valeur
/// rangee dans un fichier ne doit JAMAIS dependre de la langue active, sinon
/// elle devient illisible au prochain demarrage dans une autre langue.
String nombreEnClair(num valeur, String langue, {int decimales = 1}) =>
    NumberFormat.decimalPatternDigits(
      locale: langue,
      decimalDigits: decimales,
    ).format(valeur);
