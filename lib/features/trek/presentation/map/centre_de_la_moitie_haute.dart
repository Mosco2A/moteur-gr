/// LE CENTRE VISIBLE DE LA CARTE : LE MILIEU DE LA MOITIE HAUTE (tache 790).
///
/// RETOUR DE CHRISTOPHE DU 10/10 16:17, mot pour mot : « On a toujours ce
/// point qui n est pas centre quand on centre la carte ». Puis la regle, de
/// sa main, le 10/10 16:18 : « Il est centré sur la carte mais comme est
/// cachée par le panneau de stat on croit qu'elle est en bas. Il faut la
/// centrer sur les 50% de l'écran du haut ».
///
/// CE QUE CELA VEUT DIRE, ET C'EST TOUT. Le point recentre ne tombe plus au
/// milieu de la carte, mais au milieu de sa MOITIE HAUTE — donc au QUART de
/// la hauteur depuis le haut. La moitie basse de la carte est celle que le
/// panneau de chiffres et les boutons recouvrent : un point pose au milieu
/// geometrique y tombe derriere eux, et l'oeil le croit « en bas » alors
/// qu'il est, lui, parfaitement centre.
///
/// POURQUOI UNE FRACTION FIXE ET NON LA HAUTEUR DES BANDEAUX. La premiere
/// piste etait de mesurer ce que les surcouches occupent reellement, puis de
/// viser le milieu de la bande degagee. Christophe a tranche plus court : la
/// moitie haute, toujours. Cette regle-ci ne demande rien a personne, elle ne
/// depend d'aucun bandeau conditionnel — mode demo, marche simulee,
/// hors-trace — et elle donne donc le MEME resultat quel que soit le nombre
/// de bandeaux affiches. C'est precisement ce que sa garde mesure.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// La fraction de la hauteur, COMPTEE DEPUIS LE HAUT, ou le point recentre
/// doit apparaitre. 0.25, c'est le centre de la moitie haute.
const double fractionDuCentreHaut = 0.25;

/// Le decalage a passer a [MapController.move] pour que le point vise
/// apparaisse a [fractionDuCentreHaut] de la hauteur de [taille], au lieu du
/// centre geometrique.
///
/// LE SIGNE, ET POURQUOI IL EST NEGATIF. `move` pose le point vise a
/// `hauteur / 2 + dy` du haut : un `dy` POSITIF le descend. Pour le remonter
/// au quart, il faut donc `dy = hauteur * (fraction - 0.5)`, soit un quart de
/// hauteur NEGATIF. La camera, elle, part vers le sud d'autant — c'est la
/// contrepartie exacte, et c'est `flutter_map` qui la calcule.
///
/// POURQUOI CE DECALAGE EST EN PIXELS ET NON EN DEGRES. Un quart d'ecran ne
/// vaut pas le meme nombre de degres de latitude a Porto-Vecchio et au
/// Monte Cinto, ni au zoom 12 et au zoom 16. On ne convertit donc RIEN a la
/// main : `move` prend un decalage en pixels logiques, le reporte dans la
/// projection AU ZOOM COURANT (`projectAtZoom` / `unprojectAtZoom`) et le
/// fait tourner avec la camera si elle est tournee (`rotatePoint`). La regle
/// de trois sur les degres, elle, aurait ete fausse partout sauf a
/// l'equateur.
///
/// REPLI EXPLICITE, JAMAIS D'EXCEPTION (meme regle que `cadrageDOuverture`).
/// Avant sa premiere mise en page, une camera porte `kImpossibleSize`, une
/// taille INFINIE NEGATIVE : un quart d'infini n'est pas un decalage, et le
/// mouvement partirait a l'infini. Tant que la hauteur n'est pas une mesure
/// utilisable, on rend [Offset.zero] — le recentrage retombe alors sur le
/// centre geometrique, qui est imparfait mais juste.
Offset decalageVersLeCentreHaut(Size taille) {
  final hauteur = taille.height;
  if (!hauteur.isFinite || hauteur <= 0) return Offset.zero;
  return Offset(0, hauteur * (fractionDuCentreHaut - 0.5));
}
