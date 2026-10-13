/// LA PLACE QU'IL FAUT POUR ECRIRE UN TEXTE EN ENTIER (tache 749).
///
/// POURQUOI CE FICHIER EXISTE. La regle du lot 749 est : aucun texte n'est
/// coupe. Quand un texte vit dans une tuile dont la hauteur est la meme pour
/// toutes les tuiles — une grille — la seule facon de tenir cette regle est de
/// savoir, AVANT de poser la grille, combien de place le texte le plus long
/// reclame. Ecrire ce nombre a la main est precisement ce qui a produit le
/// defaut : la grille du cockpit portait `mainAxisExtent: 180`, un budget
/// calcule a la main, et tout texte qui n'y rentrait pas etait coupe pour
/// tenir. Un budget fixe pour du texte traduit en cinq langues, a une taille de
/// police que le randonneur peut grossir, ne peut pas etre juste.
///
/// Ce fichier remplace le calcul mental par une MESURE. Il ne contient aucun
/// widget : des textes, des styles, une largeur, et il rend une hauteur. C'est
/// ce qui le rend interrogeable par la garde du lot, langue par langue et
/// largeur par largeur — comme la tache 634 avait rendu testable la taille de
/// police d'un libelle de tuile.
library;

import 'package:flutter/material.dart';

/// Un texte a mesurer : ce qu'il dit, dans quel style, et le nombre de lignes
/// qu'on lui accorde.
///
/// [maxLignes] a `null` veut dire « autant de lignes qu'il en demande » — c'est
/// le cas normal depuis le lot 749. Une valeur n'est legitime que la ou un
/// autre dispositif garantit par ailleurs que le texte tiendra ENTIER dans ce
/// nombre de lignes : typiquement [TexteAjuste], qui reduit la police juste
/// assez plutot que de couper.
typedef BlocDeTexte = ({String texte, TextStyle style, int? maxLignes});

/// LA HAUTEUR QU'IL FAUT POUR ECRIRE [blocs] EN ENTIER DANS [largeurTexte].
///
/// Somme des hauteurs reelles des textes, mesurees au [TextPainter] a la
/// largeur offerte et a l'echelle de texte du randonneur. Rend 0 si la largeur
/// n'est pas exploitable (non bornee, ou nulle) : l'appelant retombe alors sur
/// son plancher.
double hauteurDesTextes({
  required List<BlocDeTexte> blocs,
  required double largeurTexte,
  TextScaler echelle = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
  TextAlign alignement = TextAlign.start,
}) {
  if (!largeurTexte.isFinite || largeurTexte <= 0) return 0;

  var total = 0.0;
  for (final bloc in blocs) {
    final peintre = TextPainter(
      text: TextSpan(text: bloc.texte, style: bloc.style),
      textDirection: direction,
      textAlign: alignement,
      maxLines: bloc.maxLignes,
      textScaler: echelle,
    )..layout(maxWidth: largeurTexte);
    total += peintre.height;
  }
  return total;
}

/// LA HAUTEUR DE CELLULE D'UNE GRILLE DE TUILES, MESUREE SUR SES TEXTES.
///
/// [tuiles] donne, pour chaque tuile de la grille, les textes qu'elle empile.
/// [hauteurHorsTexte] est tout ce qui n'est pas du texte dans la tuile et ne
/// depend pas de lui : paddings, icones, espacements, coches. [plancher] est la
/// hauteur en dessous de laquelle on ne descend pas — c'est par lui qu'une
/// grille garde l'allure qu'elle avait avant d'etre mesuree.
///
/// La hauteur rendue est celle de la tuile la PLUS EXIGEANTE : dans une grille,
/// toutes les cellules ont la meme hauteur, et c'est la plus bavarde qui la
/// decide. Lui donner moins, c'est la couper.
double hauteurDeCelluleMesuree({
  required List<List<BlocDeTexte>> tuiles,
  required double largeurTexte,
  required double hauteurHorsTexte,
  required double plancher,
  TextScaler echelle = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
  TextAlign alignement = TextAlign.start,
}) {
  if (!largeurTexte.isFinite || largeurTexte <= 0) return plancher;

  var requise = plancher;
  for (final tuile in tuiles) {
    final hauteur =
        hauteurHorsTexte +
        hauteurDesTextes(
          blocs: tuile,
          largeurTexte: largeurTexte,
          echelle: echelle,
          direction: direction,
          alignement: alignement,
        ) +
        margeDArrondiDuPeintre;
    if (hauteur > requise) requise = hauteur;
  }
  return requise;
}

/// Un point de garde pour l'arrondi au pixel du peintre de texte.
///
/// Un demi-pixel de retard suffirait a rallumer un debordement, et un
/// debordement repasserait par la case « on coupe pour tenir » — c'est-a-dire
/// par le defaut que ce lot corrige.
const double margeDArrondiDuPeintre = 2;
