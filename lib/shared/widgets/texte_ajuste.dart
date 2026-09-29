/// TEXTE QUI SE REDUIT POUR TENIR, PLUTOT QUE DE SE COUPER (tache 634, DEM-1325).
///
/// LE DEFAUT QU'IL CORRIGE. Retour de Christophe du 29/09 13:25, verbatim :
/// « ravitaillement est ecrit sur 2 lignes ». Les tuiles du cockpit reservent
/// 126 px de texte sur un telephone de 360 px de large, et « Ravitaillement »
/// ecrit en 18 px gras en demande environ 145. Flutter fait alors la seule
/// chose qu'il sait faire d'un mot trop long : il le COUPE en plein milieu
/// (« Ravitailleme / nt »). Aucune exception n'est levee — c'est pourquoi les
/// trois dispositifs anti-debordement du depot etaient verts malgre le defaut.
///
/// POURQUOI CE N'EST PAS UN PROBLEME DE MOT FRANCAIS. Raccourcir « Ravitaille-
/// ment » n'aurait corrige qu'un cas sur six. Mesure faite sur les libelles des
/// tuiles dans les cinq langues, mot insecable le plus long par langue :
/// allemand « Zusammenfassung » (15) et « Ubernachtungen » (14), espagnol
/// « Avituallamiento » (15) et « Pernoctaciones » (14), italien
/// « Pernottamenti » (13), francais « Ravitaillement » (14). L'allemand est le
/// pire cas, et il l'est sur des tuiles que Christophe n'a pas encore ouvertes.
/// C'est donc la TUILE qu'il fallait corriger, pas le mot.
///
/// CE QUE FAIT CE WIDGET. Il cherche la plus grande taille de police, en
/// partant de celle du style demande et sans jamais descendre sous [tailleMin],
/// a laquelle le texte tient dans la largeur disponible :
///  * sur au plus [maxLines] lignes, ET
///  * SANS QU'AUCUN MOT SOIT COUPE.
/// La seconde condition est celle qui compte : c'est elle, et elle seule, qui
/// distingue « Korperliche Vorbereitung » (deux mots, se replie proprement sur
/// deux lignes, taille inchangee) de « Ravitaillement » (un seul mot, qui ne
/// peut que se casser).
///
/// Si meme [tailleMin] ne suffit pas, le texte est rendu a [tailleMin] avec les
/// points de suspension habituels : on prefere un libelle abrege a un libelle
/// illisible. Un seul libelle des cinq langues etait dans ce cas — l'allemand
/// « Zusammenfassung » — et il a ete change plutot que rapetisse : voir le
/// commit de la tache 634.
///
/// LE REGLAGE D'ACCESSIBILITE EST RESPECTE. La mesure se fait avec le
/// `TextScaler` du systeme : un randonneur qui a grossi les textes de son
/// telephone garde son agrandissement, la tuile s'ajuste autour.
library;

import 'package:flutter/material.dart';

/// Vrai si [texte] tient dans [largeur] sur au plus [maxLines] lignes SANS
/// qu'aucun de ses mots soit coupe.
///
/// Fonction pure, sans widget : c'est elle que les tests interrogent, langue
/// par langue et largeur par largeur.
bool texteTientSansCouperDeMot({
  required String texte,
  required TextStyle style,
  required double largeur,
  required int maxLines,
  TextScaler echelle = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
}) {
  if (largeur <= 0 || texte.isEmpty) return true;

  double largeurDe(String morceau, {int lignes = 1}) {
    final peintre = TextPainter(
      text: TextSpan(text: morceau, style: style),
      textDirection: direction,
      maxLines: lignes,
      textScaler: echelle,
    )..layout(maxWidth: double.infinity);
    return peintre.width;
  }

  // 1. AUCUN MOT NE DOIT DEBORDER A LUI SEUL. C'est le cas « Ravitaillement » :
  //    un mot plus large que la colonne sera casse en deux, quel que soit le
  //    nombre de lignes autorise.
  for (final mot in texte.split(RegExp(r'\s+'))) {
    if (mot.isEmpty) continue;
    if (largeurDe(mot) > largeur) return false;
  }

  // 2. L'ENSEMBLE DOIT TENIR DANS LE NOMBRE DE LIGNES ACCORDE.
  final peintre = TextPainter(
    text: TextSpan(text: texte, style: style),
    textDirection: direction,
    maxLines: maxLines,
    textScaler: echelle,
  )..layout(maxWidth: largeur);
  return !peintre.didExceedMaxLines;
}

/// LA PLUS GRANDE TAILLE DE POLICE A LAQUELLE [texte] TIENT.
///
/// Descend par demi-points depuis `style.fontSize` jusqu'a [tailleMin] ; rend
/// [tailleMin] si rien ne tient (le texte sera alors abrege).
double tailleQuiTient({
  required String texte,
  required TextStyle style,
  required double largeur,
  required int maxLines,
  required double tailleMin,
  TextScaler echelle = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
}) {
  final depart = style.fontSize ?? 14;
  if (depart <= tailleMin) return depart;
  for (var taille = depart; taille >= tailleMin; taille -= 0.5) {
    final tient = texteTientSansCouperDeMot(
      texte: texte,
      style: style.copyWith(fontSize: taille),
      largeur: largeur,
      maxLines: maxLines,
      echelle: echelle,
      direction: direction,
    );
    if (tient) return taille;
  }
  return tailleMin;
}

/// Le widget a poser la ou un libelle traduit doit tenir dans une place fixe.
class TexteAjuste extends StatelessWidget {
  const TexteAjuste(
    this.texte, {
    super.key,
    this.style,
    this.maxLines = 2,
    this.tailleMin = 13,
    this.textAlign = TextAlign.center,
  });

  final String texte;
  final TextStyle? style;
  final int maxLines;

  /// Plancher de lisibilite. En dessous, on abrege plutot que de reduire :
  /// un libelle de tuile illisible ne rend service a personne.
  final double tailleMin;

  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final styleBase = style ?? DefaultTextStyle.of(context).style;
    final echelle = MediaQuery.textScalerOf(context);

    return LayoutBuilder(
      builder: (context, contraintes) {
        final taille = contraintes.maxWidth.isFinite
            ? tailleQuiTient(
                texte: texte,
                style: styleBase,
                largeur: contraintes.maxWidth,
                maxLines: maxLines,
                tailleMin: tailleMin,
                echelle: echelle,
                direction: Directionality.of(context),
              )
            : (styleBase.fontSize ?? 14);

        return Text(
          texte,
          style: styleBase.copyWith(fontSize: taille),
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
