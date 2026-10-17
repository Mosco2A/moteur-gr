/// La pastille de difficulte, et la table unique qui associe un niveau a sa
/// couleur : aucun ecran de la fiche ne refait ce choix.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/couleurs_semantiques.dart';
import '../../../domain/difficulte_du_sentier.dart';

/// PASTILLE D'UN NIVEAU DE DIFFICULTE, SUR L'ECHELLE A CINQ BANDES.
///
/// ELLE PREND UN NIVEAU MESURE, PLUS UNE ETIQUETTE STOCKEE (tache 848). Elle
/// recevait une CHAINE (`easy`, `moderate`, `hard`, `expert`) lue dans la
/// donnee du sentier. Deux raisons de ne plus le faire, et la seconde est une
/// faute visible :
///
///  1. LES SEUILS CLASSENT L'ETAPE, et ils le font sur son DENIVELE MESURE
///     (decision de Christophe du 17/10, cf. [SeuilsDeDifficulte]). L'etiquette
///     stockee dans `stages.json` a ete calculee par
///     `tool/gr20_dans_stepways.py` sur les ANCIENS seuils (400 / 1 000 /
///     1 500 m) : elle dit « Modere » pour une journee de 967 m que la nouvelle
///     echelle classe DIFFICILE. Une etiquette figee dans la donnee ne suit pas
///     un changement de regle ; une mesure, si.
///  2. L'ECHELLE A CINQ BANDES ET LE VOCABULAIRE STOCKE EN A QUATRE. « Tres
///     difficile » n'a pas de cle. Pire, la table precedente ne connaissait pas
///     la cle `extreme` que l'outil produit au-dela de 1 500 m : une etape
///     d'expert s'affichait donc en GRIS, avec le mot « extreme » brut a
///     l'ecran. Aucune etape du GR20 ne depasse 1 500 m, c'est pourquoi
///     personne ne l'avait vu — un test figeait meme ce trou comme le
///     comportement attendu.
///
/// LES CINQ COULEURS SONT CELLES DU DENIVELE, DEJA DECLAREES « UNIVERSELLES
/// POUR LE TREK » DANS LE THEME : vert, jaune, orange, rouge, puis le violet du
/// cran au-dela. Aucune n'est inventee ici, et l'echelle est enfin monotone —
/// la table precedente sautait le jaune et posait le rouge au milieu, ce qui ne
/// laissait aucune couleur disponible pour un cinquieme niveau.
///
/// LE RESTE DE L'APPLICATION N'EST PAS TOUCHE : les ecrans de la PREPARATION
/// (`features/trek`) lisent encore l'etiquette stockee et la traduisent par
/// leur propre table i18n a quatre valeurs. Ils diront donc « Modere » la ou la
/// fiche dit « Difficile » pour la meme etape de 967 m. C'est un ecart CONNU et
/// MESURE, pas un oubli : le fermer demande de porter l'echelle a cinq bandes
/// dans les cinq langues et dans les attentes de test qui figent l'etiquette,
/// et c'est un lot a soi.
class DifficultyBadge extends StatelessWidget {
  /// La pastille d'un niveau — jamais d'une chaine : voir l'en-tete.
  const DifficultyBadge({super.key, required this.niveau});

  /// Le niveau a afficher, deduit d'un denivele mesure.
  final NiveauDeDifficulte niveau;

  /// LA TABLE UNIQUE NIVEAU -> COULEUR. La jauge de la fiche l'emploie aussi :
  /// deux tables auraient fini par dire deux choses du meme niveau.
  static Color couleurDe(NiveauDeDifficulte niveau) => switch (niveau) {
    NiveauDeDifficulte.facile => AppTheme.vertFacile,
    NiveauDeDifficulte.moyen => AppTheme.jauneModere,
    NiveauDeDifficulte.difficile => AppTheme.orangeDifficile,
    NiveauDeDifficulte.tresDifficile => AppTheme.rougeExtreme,
    NiveauDeDifficulte.expert => CouleursSemantiques.violetDifficulteExpert,
  };

  @override
  Widget build(BuildContext context) {
    final color = couleurDe(niveau);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingSm,
        vertical: AppTheme.spacingXs,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        niveau.libelle,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
