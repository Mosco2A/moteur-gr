/// UNE RANGEE DE ZERO A QUATRE ICONES, aux couleurs des pistes.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/niveau_des_icones.dart';

/// LA PALETTE DES NIVEAUX, AUX COULEURS DES PISTES, MESUREE ET NON CHOISIE.
///
/// POURQUOI LES COULEURS DES PISTES. Christophe, 21/10/2026 08:16 : « ou en
/// prend la meme chose que les pistes de ski vert, bleu, rouge, noir ». C'est
/// la convention que tout le monde connait en France, et nos quatre bandes
/// publiees sont deja celles du VTT — donc la meme famille de graduation d'une
/// pente.
///
/// POURQUOI DEUX PALETTES. WCAG 1.4.11 « Non-text Contrast », niveau AA,
/// exige qu'un objet graphique porteur de sens ait AU MOINS 3:1 CONTRE LA
/// COULEUR ADJACENTE. Aucune palette unique ne tient sur les deux themes, et
/// la mesure est sans appel : LE NOIR DES PISTES TOMBE A 1,15:1 SUR LA CARTE
/// SOMBRE, donc il est INVISIBLE — et ce serait le niveau le PLUS ELEVE qu'on
/// cacherait. Pour une application de montagne c'est le seul defaut qu'on ne
/// peut pas accepter. Le theme sombre est de surcroit le DEFAUT de
/// l'application, donc ce n'est pas un cas limite.
///
/// CE QUE DEVIENT LE NOIR SUR FOND SOMBRE, ET POURQUOI C'EST HONNETE. Les
/// cartes de pistes sont imprimees en noir SUR BLANC : le quatrieme niveau y
/// est la marque la plus CONTRASTEE, pas la plus foncee. Sur un fond sombre la
/// marque la plus contrastee est la plus claire. Et le niveau est de toute
/// facon identifie par le NOMBRE d'icones, donc inverser l'extreme ne coute
/// rien au sens.
///
/// LES RATIOS MESURES, contre la carte de chaque theme (`F5F5F5` en clair,
/// `2C2C2C` en sombre) :
///
///   niveau   clair              sombre
///   une      2E7D32  4,70:1     81C784  6,94:1
///   deux     1565C0  5,27:1     64B5F6  6,31:1
///   trois    E53935  3,88:1     EF5350  4,01:1
///   quatre   212121 14,77:1     EEEEEE 12,04:1
///
/// Les trois premieres teintes ont des luminances presque egales (0,155,
/// 0,133 et 0,161) : elles ne se distinguent donc PAS par la clarte. C'est le
/// COMPTAGE qui les distingue, et c'est exactement pour cela qu'il existe.
Color couleurDuNiveau(NiveauDIcone niveau, Brightness luminosite) {
  final sombre = luminosite == Brightness.dark;
  switch (niveau) {
    // AUCUNE ICONE N'EST DESSINEE A CE NIVEAU : cette couleur n'est jamais
    // peinte. Elle existe pour que la fonction soit totale.
    case NiveauDIcone.aucun:
      return sombre ? AppTheme.grisTexteSecondaire : AppTheme.grisGranite;
    case NiveauDIcone.une:
      return sombre ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
    case NiveauDIcone.deux:
      return sombre ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
    case NiveauDIcone.trois:
      return sombre ? const Color(0xFFEF5350) : const Color(0xFFE53935);
    case NiveauDIcone.quatre:
      return sombre ? const Color(0xFFEEEEEE) : const Color(0xFF212121);
  }
}

/// UNE RANGEE DE ZERO A QUATRE ICONES, QUI DIT UN NIVEAU (tache 862).
///
/// LE NOMBRE PORTE L'INFORMATION AUTANT QUE LA COULEUR, et c'est la trouvaille
/// de Christophe : une personne qui ne distingue pas le vert du rouge COMPTE
/// au lieu de distinguer une teinte. Cela satisfait WCAG 1.4.1 « Use of
/// Color », de niveau A, sans rien ajouter a l'ecran — et mieux qu'une
/// difference de forme, qu'il aurait fallu apprendre.
///
/// TROIS PORTEURS POUR UNE SEULE INFORMATION, et aucun n'est redondant pour
/// tout le monde : la COULEUR pour le coup d'oeil, le NOMBRE pour qui ne voit
/// pas les teintes, et le LIBELLE pour qui ne voit pas l'ecran du tout.
///
/// LA LARGEUR EST RESERVEE POUR QUATRE, TOUJOURS. Une colonne dont la largeur
/// change d'une ligne a l'autre se parcourt mal : le regard perd le bord sur
/// lequel il s'aligne, et c'est precisement ce qu'on vient demander a une
/// liste de seize etapes. On reserve donc la place du maximum et on y pose les
/// icones presentes, alignees a gauche.
class IconesDeNiveau extends StatelessWidget {
  /// Une rangee d'icones pour un niveau.
  const IconesDeNiveau({
    required this.niveau,
    required this.glyphe,
    required this.axe,
    required this.noteLue,
    required this.libelle,
    this.taille = 16,
    super.key,
  });

  /// Le niveau a montrer, donc le nombre d'icones.
  final NiveauDIcone niveau;

  /// Le dessin a repeter — la montagne pour la raideur, la chaussure pour
  /// l'effort.
  ///
  /// LES DEUX AXES N'ONT PAS LE MEME GLYPHE, et ce n'est pas decoratif : les
  /// couleurs de pistes graduent une PENTE, donc elles collent exactement a la
  /// raideur, alors que sur l'effort elles sont une metaphore empruntee. Un
  /// dessin different evite de laisser croire que les deux axes ont la meme
  /// fondation.
  final String glyphe;

  /// Le nom de l'axe, pour la voix : « Effort » ou « Raideur ».
  final String axe;

  /// La note sur vingt deja mise en forme, pour la voix.
  final String noteLue;

  /// Ce que la bande publiee dit, en mots et sans aucun mot de niveau.
  final String libelle;

  /// La taille d'une icone, en pixels logiques.
  final double taille;

  @override
  Widget build(BuildContext context) {
    final couleur = couleurDuNiveau(niveau, Theme.of(context).brightness);
    const ecart = AppTheme.spacingXs;
    return Semantics(
      // LE LECTEUR D'ECRAN ENTEND LA PHRASE UNE SEULE FOIS, pas une fois par
      // icone : les dessins sont exclus de l'arbre semantique et la rangee
      // porte un libelle unique.
      label: '$axe $noteLue sur 20, $libelle',
      excludeSemantics: true,
      child: SizedBox(
        width:
            NiveauDIcone.maximum * taille + (NiveauDIcone.maximum - 1) * ecart,
        height: taille,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            for (var i = 0; i < niveau.nombreDIcones; i++) ...<Widget>[
              if (i > 0) const SizedBox(width: ecart),
              StepIcon(glyphe, size: taille, color: couleur),
            ],
          ],
        ),
      ),
    );
  }
}
