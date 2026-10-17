/// LE SENS DE MARCHE, APPLIQUE AUX ETAPES ELLES-MEMES — ordre ET deniveles.
library;

import '../core/models/stage_row.dart';

/// LES ETAPES ORIENTEES DANS LE SENS CHOISI.
///
/// LE DEFAUT QUE CETTE FONCTION REPARE, ET IL ETAIT LIVRE. Jusqu'ici, inverser
/// le sens de marche n'etait rien d'autre qu'un `.reversed` sur la liste des
/// etapes, recopie a l'identique en trois endroits. L'ORDRE etait donc inverse
/// et les DENIVELES ne l'etaient JAMAIS : la montee restait la montee du sens
/// de la trace. Conca vers i Paliri monte 1 097 m et descend 300 m ; dans
/// l'autre sens c'est l'inverse, et l'application annoncait 300 m de montee a
/// un marcheur qui en avait 1 097 devant lui. Sur une journee de montagne, ce
/// n'est pas un ecart d'affichage, c'est une erreur de preparation.
///
/// CE QUI S'ECHANGE, ET CE QUI NE S'ECHANGE PAS. La distance, la duree et le
/// nombre d'etapes sont INVARIANTS au sens : le meme chemin fait la meme
/// longueur dans les deux sens. La montee et la descente, elles, PERMUTENT —
/// ce qu'on monte dans un sens, on le descend dans l'autre. C'est la seule
/// chose que cette fonction echange, avec l'ordre.
///
/// LES NOMS DE DEPART ET D'ARRIVEE NE SONT PAS TOUCHES ICI, ET C'EST VOULU :
/// `directionalStageTitle` (ecran Resume) les lit deja a l'envers quand il
/// faut. Les permuter aussi ferait une DOUBLE inversion, qui est exactement le
/// piege que ce lot vient defaire ailleurs.
///
/// UN SEUL ENDROIT, PARCE QUE TROIS ENDROITS ONT SUFFI A LE PERDRE. Le defaut
/// ne venait pas d'un oubli isole : il venait de ce que « inverser » etait
/// ecrit trois fois, chaque fois comme une inversion de LISTE, sans qu'aucun
/// des trois ne porte la permutation des deux deniveles. Les appelants
/// demandent desormais des etapes ORIENTEES, et tout l'aval — le programme,
/// les journees, l'itineraire, la faisabilite, les tuiles d'etape — devient
/// juste sans etre touche.
///
/// [aLEnvers] faux rend la liste telle quelle, sans copie inutile : le sens de
/// reference est le sens de la trace, et il n'y a rien a corriger.
List<StageModel> etapesDansLeSens(
  List<StageModel> etapes, {
  required bool aLEnvers,
}) {
  if (!aLEnvers) return etapes;
  return [
    for (final etape in etapes.reversed)
      etape.copyWith(
        elevationGainM: etape.elevationLossM,
        elevationLossM: etape.elevationGainM,
      ),
  ];
}

/// VRAI quand le sens retenu n'est pas le sens de reference du sentier.
///
/// LE SENS DE REFERENCE EST LE PREMIER QUE LE SENTIER DECLARE, jamais un
/// nombre en dur ni une convention devinee (`TrailConfig.directions`, le GR20
/// declare `['NS', 'SN']`). Sans sens declare, ou sans choix du marcheur, on
/// reste dans le sens de la trace : on ne retourne pas un sentier par defaut.
///
/// CETTE QUESTION ETAIT POSEE CINQ FOIS DANS LE DEPOT, mot pour mot, et c'est
/// la moitie de la raison pour laquelle la permutation des deniveles a pu
/// manquer dans trois d'entre elles sans que personne le voie.
bool marcheALEnvers({
  required String? sensDeReference,
  required String? choisi,
}) => sensDeReference != null && choisi != null && choisi != sensDeReference;
