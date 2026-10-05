/// Un titre puis une grille de deux colonnes de cartes, non scrollable elle-
/// meme : c'est la page qui scrolle, pas la section.
library;

import 'package:flutter/material.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';
import 'quick_access_card.dart';

/// Section thematique du HUB (RF-6/8/9/10).
///
/// Affiche un en-tete (icone + titre de section) suivi d'une grille de
/// [QuickAccessCard]. La grille est fixe a 2 colonnes (mise en page mobile),
/// avec une hauteur de cellule reglee pour accueillir icone + titre + sous-titre
/// sans debordement. Non scrollable elle-meme : c'est le [ListView] de
/// [HubScreen] qui scrolle (grille en `shrinkWrap`, physique desactivee).
class HubSection extends StatelessWidget {
  const HubSection({
    super.key,
    required this.title,
    this.icon,
    this.rubrique,
    required this.cards,
    this.iconColor,
    this.showHeader = true,
  }) : assert(
         !showHeader || (icon == null) != (rubrique == null),
         'un en-tete de section porte UNE icone : une rubrique (bicolore) ou '
         'une icone Stepways (monochrome)',
       );

  /// L'une des 20 rubriques de l'application (tache 632). Voie normale.
  final RubriqueStepways? rubrique;

  /// Titre de la section (libelle localise).
  final String title;

  /// Affiche l'en-tete (icone + titre) au-dessus de la grille. Defaut true
  /// (comportement historique du hub). Le cockpit par phases (nav V2, R11) passe
  /// `false` : le bandeau d'en-tete de phase porte deja le titre « Préparer /
  /// Randonner / Après », inutile de le repeter juste en dessous (fin doublon).
  final bool showHeader;

  /// Chemin d'une icone Stepways ([StepwaysIcons]) — pour les sections qui ne
  /// sont pas l'une des 20 rubriques. Exclusif avec [rubrique].
  ///
  /// TACHE 639 : ce chemin N'IMPOSE PLUS le monochrome (voir
  /// [iconeBicolorePour]). Un en-tete de section est un sujet : si le dessin a un
  /// trace bicolore, il sort en bicolore.
  final String? icon;

  /// Couleur categorielle de l'icone d'en-tete (retour Chris 09/09, reco
  /// #IR02, parite `SectionHeader.iconColor` de GR20). Fournie par l'appelant
  /// depuis [CategoryIconColors] — jamais en dur. Si `null`, repli sur
  /// l'accent-sentier (`colorScheme.primary`).
  final Color? iconColor;

  /// Cartes d'acces rapide de la section.
  final List<QuickAccessCard> cards;

  /// Le dessin de l'en-tete (tache 632, regle unifiee par la tache 639).
  ///
  /// UN EN-TETE DE SECTION EST UN SUJET : il sort en bicolore des que son dessin
  /// a un trace duo, que l'appelant ait nomme la [rubrique] ou passe le chemin a
  /// plat dans [icon]. C'etait la faute mesuree du bug 3 : seul le cockpit
  /// nommait la rubrique, donc seul le cockpit etait bicolore. La regle vit
  /// maintenant dans [iconeBicolorePour] ; ici on ne fait que la consulter.
  ///
  /// Une couleur categorielle imposee bascule sur le trace monochrome, sinon
  /// elle serait simplement ignoree.
  Widget _icone(Color couleur) {
    final dessin = rubrique ?? (icon != null ? iconeBicolorePour(icon!) : null);
    if (dessin != null) {
      return IconeStepways(
        dessin,
        taille: 22,
        couleur: iconColor != null ? couleur : null,
      );
    }
    return StepIcon(icon!, color: couleur, size: 22);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tete de section (masquable — R11 pour le cockpit par phases).
        if (showHeader) ...[
          Row(
            children: [
              // TACHE 632 — l'en-tete de section porte 22 px, pas 24 : les
              // rubriques les plus chargees (itineraire, programme) y sont
              // encore lisibles, mesure faite au rendu reel.
              _icone(iconColor ?? theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              // Flexible + ellipsis : le titre de section s'ajuste a la largeur
              // (mobile 360 px) au lieu de deborder la Row a droite.
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        // Grille 2 colonnes non scrollable (le HUB scrolle pour elle).
        //
        // Hauteur d'item FIXE ([mainAxisExtent]) plutot qu'un ratio largeur/hauteur :
        // le contenu d'une [QuickAccessCard] (icone 28 + titre + sous-titre 2
        // lignes + espacements + padding) ne depend pas de la largeur de cellule.
        // Un [childAspectRatio] fixe rendait la cellule trop plate aux largeurs
        // mobiles (~115 px a 390 px logiques) -> RenderFlex overflow.
        // [mainAxisExtent] supprime cette dependance a la largeur.
        //
        // Finitions V1 (point 6) : 150 -> 180 px pour accueillir un TITRE sur 2
        // lignes (les titres longs « Découvrir des sentiers » etaient tronques a
        // 1 ligne) SANS overflow quand le sous-titre occupe aussi 2 lignes
        // (icone 36 + titre 2 lignes + sous-titre 2 lignes + espacements +
        // padding). 164 debordait de 12 px sur la carte « Découvrir » (titre ET
        // sous-titre longs) — 180 laisse la marge.
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spacingMd,
            crossAxisSpacing: AppTheme.spacingMd,
            mainAxisExtent: 180,
          ),
          itemBuilder: (context, index) => cards[index],
        ),
      ],
    );
  }
}
