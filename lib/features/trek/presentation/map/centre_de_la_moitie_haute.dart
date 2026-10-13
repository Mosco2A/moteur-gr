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
///
/// CE QUE LA TACHE 794 A AJOUTE ICI, ET POURQUOI DANS CE FICHIER. Une fois le
/// marcheur pose au quart du haut, le centre de la CAMERA n'est plus le
/// marcheur : il est un quart de hauteur plus bas, sous le panneau de
/// chiffres, et personne ne le voit. Les boutons + et −, eux, tournaient
/// autour de ce centre invisible et chassaient donc le marcheur de l'ecran a
/// chaque appui. Le remede demande le MEME point que le recentrage vise :
/// « le milieu de la moitie haute ». Deux definitions de ce point auraient
/// derive l'une de l'autre au premier reglage ; il n'y en a donc qu'une, ici,
/// et [fractionDuCentreHaut] la porte pour les deux gestes.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// La fraction de la hauteur, COMPTEE DEPUIS LE HAUT, ou le point recentre
/// doit apparaitre. 0.25, c'est le centre de la moitie haute.
const double fractionDuCentreHaut = 0.25;

/// Le cadre de carte porte-t-il une taille dont on peut prendre une fraction.
///
/// POURQUOI CETTE QUESTION A UNE REPONSE NOMMEE. Avant sa premiere mise en
/// page, une camera porte [MapCamera.kImpossibleSize] — une taille INFINIE
/// NEGATIVE, choisie par `flutter_map` precisement pour etre reconnaissable.
/// Les deux gestes qui visent le centre visible doivent se replier dans ce
/// cas-la, et se replier DE LA MEME FACON : d'ou une seule reponse pour les
/// deux. La largeur compte autant que la hauteur depuis que la tache 794
/// lit un point a `largeur / 2`.
bool cadreMesurable(Size taille) =>
    taille.width.isFinite &&
    taille.height.isFinite &&
    taille.width > 0 &&
    taille.height > 0;

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
  if (!cadreMesurable(taille)) return Offset.zero;
  return Offset(0, taille.height * (fractionDuCentreHaut - 0.5));
}

/// LE POINT DE LA CARTE QUI EST, EN CE MOMENT, AU CENTRE VISIBLE (tache 794).
///
/// C'est-a-dire : quel lieu se trouve sous le pixel situe au milieu de la
/// moitie haute du cadre. C'est l'ANCRE du zoom — le point que zoomer ne doit
/// pas deplacer.
///
/// CE QUE LES BOUTONS FAISAIENT AVANT, ET POURQUOI C'ETAIT FAUX. Ils
/// appelaient `move(camera.center, zoom ± 1)` : ils gardaient en place le
/// CENTRE DE LA CAMERA. Tant que le recentrage posait le marcheur au centre
/// geometrique, les deux se confondaient et le zoom semblait juste. Depuis la
/// tache 790 le marcheur est au quart du haut, donc un quart de hauteur
/// AU-DESSUS du centre de camera : chaque appui sur + doublait cet ecart et
/// l'eloignait du haut de l'ecran. Mesure sur un cadre de 390 x 844 : 211 px
/// du haut au depart, 0 px apres un zoom, −422 px apres deux — dehors.
///
/// POURQUOI L'ANCRE N'EST PAS « LE MARCHEUR ». C'etait la correction la plus
/// courte, et elle est fausse dans le cas general : des que le randonneur a
/// fait glisser la carte a la main, le marcheur peut etre a dix kilometres
/// hors du cadre. Zoomer autour d'un point qu'on ne voit pas, c'est le defaut
/// d'aujourd'hui avec un autre centre. L'ancre est donc un PIXEL, pas un
/// objet : le centre de ce qu'on regarde. Elle garde le marcheur immobile
/// juste apres un recentrage — parce que c'est exactement la que le
/// recentrage l'a pose — et elle garde le paysage immobile le reste du temps.
///
/// LE CHEMIN EST CELUI DE LA BIBLIOTHEQUE, ET IL EST SYMETRIQUE DE
/// [decalageVersLeCentreHaut]. `offsetToCrs` vaut
/// `unprojectAtZoom(projectAtZoom(centre) + (pixel − milieu).rotate(angle))` :
/// pour le pixel vise, `(pixel − milieu)` EST le decalage du 790, et la
/// bibliotheque le fait tourner avec la camera. On lit l'ancre avec ce
/// decalage, on la repose avec le meme : aucune trigonometrie a la main, et
/// un seul endroit a corriger si la fraction change un jour.
///
/// REPLI EXPLICITE, JAMAIS D'EXCEPTION. Tant que [cadreMesurable] dit non, il
/// n'y a pas de pixel a interroger : on rend `null`, et l'appelant retombe
/// sur l'ancien geste — autour du centre de camera, imparfait mais jamais a
/// l'infini.
LatLng? ancreDuCentreVisible(MapCamera camera) {
  final taille = camera.nonRotatedSize;
  if (!cadreMesurable(taille)) return null;
  return camera.offsetToCrs(
    Offset(taille.width / 2, taille.height * fractionDuCentreHaut),
  );
}
