/// Un titre puis une grille de deux colonnes de cartes, non scrollable elle-
/// meme : c'est la page qui scrolle, pas la section.
library;

import 'package:flutter/material.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';
import 'mesure_de_texte.dart';
import 'quick_access_card.dart';

/// HAUTEUR DE TUILE D'AVANT LE LOT 749 — DEVENUE UN PLANCHER.
///
/// C'etait la hauteur de cellule FIXE de la grille du cockpit, et c'est la
/// cause mesuree des textes coupes : un budget en pixels dans lequel du texte
/// traduit en cinq langues devait rentrer. Elle ne commande plus la grille,
/// mais on la garde comme MINIMUM — la ou le texte tenait deja, le cockpit
/// garde exactement l'allure que Christophe connait, et une tuile a libelle
/// court ne rapetrisse pas a cote de sa voisine.
const double hauteurMinimaleDeTuile = 180;

/// LA HAUTEUR QU'IL FAUT POUR QUE RIEN NE SOIT COUPE (tache 749).
///
/// Fonction PURE, sans widget et sans contexte : elle prend des textes, des
/// styles et une largeur, et rend une hauteur. C'est elle que la garde du lot
/// interroge, langue par langue et largeur par largeur — comme la tache 634
/// avait rendu testable la taille de police d'un libelle de tuile.
///
/// CE QU'ELLE ADDITIONNE, dans l'ordre ou la tuile les empile :
/// le padding haut et bas de la carte, la pastille de l'icone, l'espace sous
/// l'icone, LA HAUTEUR REELLE DU TITRE (au plus [lignesDeTitre] lignes : c'est
/// [TexteAjuste] qui tient cette promesse en rapetissant la police si besoin),
/// l'espace sous le titre, LA HAUTEUR REELLE DU SOUS-TITRE (autant de lignes
/// qu'il en demande — c'est tout l'objet du lot), et enfin la coche de
/// preparation quand il y en a une.
///
/// La hauteur rendue n'est jamais inferieure a [hauteurMinimaleDeTuile].
double hauteurDeTuileRequise({
  required List<({String titre, String sousTitre, bool avecCoche})> tuiles,
  required double largeurCellule,
  required TextStyle styleTitre,
  required TextStyle styleSousTitre,
  TextScaler echelle = TextScaler.noScaling,
  TextDirection direction = TextDirection.ltr,
}) {
  // Largeur non bornee (section hors mise en page, ou banc de test qui ne pose
  // pas de contrainte) : rien a mesurer, on rend le plancher.
  if (!largeurCellule.isFinite || largeurCellule <= 0) {
    return hauteurMinimaleDeTuile;
  }

  // La largeur OFFERTE AU TEXTE, pas celle de la cellule : la carte porte un
  // padding sur ses quatre cotes.
  final largeurTexte = largeurCellule - _paddingDeCarte * 2;
  if (largeurTexte <= 0) return hauteurMinimaleDeTuile;

  // UNE COCHE DE PREPARATION CHANGE LA HAUTEUR HORS TEXTE, donc les tuiles qui
  // en portent une et celles qui n'en portent pas sont mesurees separement, et
  // on garde la plus exigeante des deux mesures. Melanger les deux ferait
  // retomber dans le defaut d'origine : c'est l'arrivee de la coche qui avait
  // fait deborder le budget, et donc coupe les sous-titres.
  double mesure({required bool avecCoche}) {
    final concernees = tuiles.where((t) => t.avecCoche == avecCoche).toList();
    if (concernees.isEmpty) return hauteurMinimaleDeTuile;
    return hauteurDeCelluleMesuree(
      tuiles: [
        for (final tuile in concernees)
          [
            // Le titre tient ENTIER sur au plus deux lignes : c'est
            // [TexteAjuste] qui le garantit en reduisant la police (tache 634).
            (texte: tuile.titre, style: styleTitre, maxLignes: lignesDeTitre),
            // Le sous-titre prend autant de lignes qu'il en demande : c'est
            // tout l'objet du lot 749.
            (texte: tuile.sousTitre, style: styleSousTitre, maxLignes: null),
          ],
      ],
      largeurTexte: largeurTexte,
      hauteurHorsTexte:
          _paddingDeCarte * 2 +
          _hauteurDeLaPastille +
          AppTheme.spacingSm +
          AppTheme.spacingXs +
          (avecCoche ? AppTheme.spacingXs + _hauteurDeLaCoche : 0),
      plancher: hauteurMinimaleDeTuile,
      echelle: echelle,
      direction: direction,
      alignement: TextAlign.center,
    );
  }

  final avec = mesure(avecCoche: true);
  final sans = mesure(avecCoche: false);
  return avec > sans ? avec : sans;
}

/// Nombre de lignes accordees au TITRE d'une tuile.
///
/// Le titre n'a pas besoin de plus : [TexteAjuste] garantit qu'il tient ENTIER
/// sur deux lignes en reduisant la police juste assez, et sans jamais casser un
/// mot en plein milieu (tache 634). C'est le sous-titre, lui, qui prend autant
/// de lignes qu'il en demande.
const int lignesDeTitre = 2;

/// Padding de la carte, de chaque cote (`AppCard` recoit
/// `EdgeInsets.all(AppTheme.spacingBase)` depuis [QuickAccessCard]).
const double _paddingDeCarte = AppTheme.spacingBase;

/// La pastille teintee qui porte l'icone : 6 px de padding de chaque cote
/// autour d'un dessin de 24 px.
const double _hauteurDeLaPastille = 24 + 6 * 2;

/// La coche « sujet traite » posee sous le sous-titre ([StepStatusIcon], 18
/// px).
const double _hauteurDeLaCoche = 18;

/// La hauteur de tuile de cette section, mesuree sur les textes de SES cartes.
///
/// Prend les styles et l'echelle de texte dans le [context] — la ou
/// [hauteurDeTuileRequise] reste pure — puis delegue.
double hauteurDeTuilePour(
  BuildContext context, {
  required List<QuickAccessCard> cards,
  required double largeurCellule,
}) {
  final theme = Theme.of(context);
  final styleTitre = theme.textTheme.titleMedium;
  final styleSousTitre = theme.textTheme.bodySmall;
  if (styleTitre == null || styleSousTitre == null) {
    return hauteurMinimaleDeTuile;
  }
  return hauteurDeTuileRequise(
    tuiles: [
      for (final carte in cards)
        (
          titre: carte.title,
          sousTitre: carte.texteDuSousTitre,
          avecCoche: carte.stepStatus != null,
        ),
    ],
    largeurCellule: largeurCellule,
    styleTitre: styleTitre,
    styleSousTitre: styleSousTitre,
    echelle: MediaQuery.textScalerOf(context),
    direction: Directionality.of(context),
  );
}

/// Section thematique du HUB (RF-6/8/9/10).
///
/// Affiche un en-tete (icone + titre de section) suivi d'une grille de
/// [QuickAccessCard]. La grille est fixe a 2 colonnes (mise en page mobile),
/// avec une hauteur de cellule reglee pour accueillir icone + titre +
/// sous-titre sans debordement. Non scrollable elle-meme : c'est le [ListView]
/// de [HubScreen] qui scrolle (grille en `shrinkWrap`, physique desactivee).
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
  /// (comportement historique du hub). Le cockpit par phases (nav V2, R11)
  /// passe `false` : le bandeau d'en-tete de phase porte deja le titre «
  /// Préparer / Randonner / Après », inutile de le repeter juste en dessous
  /// (fin doublon).
  final bool showHeader;

  /// Chemin d'une icone Stepways ([StepwaysIcons]) — pour les sections qui ne
  /// sont pas l'une des 20 rubriques. Exclusif avec [rubrique].
  ///
  /// TACHE 639 : ce chemin N'IMPOSE PLUS le monochrome (voir
  /// [iconeBicolorePour]). Un en-tete de section est un sujet : si le dessin a
  /// un trace bicolore, il sort en bicolore.
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
  /// UN EN-TETE DE SECTION EST UN SUJET : il sort en bicolore des que son
  /// dessin a un trace duo, que l'appelant ait nomme la [rubrique] ou passe le
  /// chemin a plat dans [icon]. C'etait la faute mesuree du bug 3 : seul le
  /// cockpit nommait la rubrique, donc seul le cockpit etait bicolore. La regle
  /// vit maintenant dans [iconeBicolorePour] ; ici on ne fait que la consulter.
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
              // LE TITRE DE SECTION S'ECRIT EN ENTIER (tache 749).
              //
              // Il disait `maxLines: 1` + ellipsis : un titre de section un peu
              // long etait coupe a droite aux largeurs mobiles. L'`Expanded`
              // lui donne la largeur de la Row ; la Row, elle, est dans une
              // Column libre en hauteur. Le titre peut donc simplement PASSER A
              // LA LIGNE — l'en-tete grandit de l'epaisseur d'une ligne, et
              // rien n'est coupe. C'est la regle du lot, appliquee au cas le
              // plus simple : de la largeur contrainte, de la hauteur libre.
              Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
        // LA CELLULE GRANDIT AVEC SON TEXTE (tache 749, REGLE DU LOT).
        //
        // CE QU'IL Y AVAIT, ET POURQUOI CA COUPAIT. La grille etait un
        // `GridView` a `mainAxisExtent: 180` — une hauteur de cellule FIXE, en
        // pixels, calculee a la main : « icone 36 + titre 2 lignes + sous-titre
        // 2 lignes + espacements + padding ». Un budget fixe pour du texte
        // traduit en cinq langues, c'est une boite dans laquelle le texte doit
        // RENTRER ; et quand il n'y rentre pas, la seule issue laissee a la
        // tuile etait de le couper. C'est exactement ce qui est arrive des que
        // la coche de preparation est apparue : elle a pris la place de la
        // deuxieme ligne du sous-titre, qui est donc passe a UNE ligne avec des
        // points de suspension (« Évaluez votre niv… »). Le commentaire de
        // l'epoque disait d'ailleurs le probleme a voix haute : « 164 debordait
        // de 12 px […] 180 laisse la marge ». On reglait un budget au pixel
        // pour un contenu qu'on ne controle pas.
        //
        // CE QU'IL Y A MAINTENANT : LA HAUTEUR EST MESUREE, PLUS DEVINEE. La
        // grille reste un `GridView` a hauteur de cellule uniforme — c'est ce
        // qui tient les tuiles alignees — mais cette hauteur n'est plus une
        // constante ecrite a la main : elle est CALCULEE par
        // [hauteurDeTuilePour] a partir des textes reels, a la largeur reelle
        // de la cellule, et a l'echelle de texte choisie par le randonneur. Si
        // un sous-titre demande trois lignes, les tuiles font trois lignes de
        // plus. Si le randonneur a grossi les textes de son telephone, elles
        // grandissent encore. Rien a recalculer a la main, et plus rien a
        // couper.
        //
        // POURQUOI PAS `IntrinsicHeight`, QUI AURAIT ETE PLUS DIRECT. Essaye,
        // et MESURE : la section vit dans le `ListView` du HUB, donc demander
        // une dimension intrinseque remonte jusqu'a un sliver, qui ne sait pas
        // la rendre. Le banc du hub est parti en 6016 exceptions
        // (`RenderSliverMultiBoxAdaptor` ne supporte pas les intrinseques, et
        // `hasSize` echoue dans la foulee). La mesure au `TextPainter` donne le
        // meme resultat sans jamais interroger l'arbre.
        //
        // LE PLANCHER DE 180 EST GARDE (voir [hauteurMinimaleDeTuile]). C'est
        // la hauteur d'aujourd'hui : la ou le texte tenait deja, le cockpit est
        // au pixel identique a ce que Christophe a sous les yeux, et une tuile
        // a libelle court ne devient pas un timbre-poste a cote de sa voisine.
        // La hauteur ne peut donc que MONTER, jamais descendre — un changement
        // de mise en page qui n'ajoute que de la place.
        //
        // Toujours non scrollable : c'est le [ListView] du HUB qui scrolle.
        LayoutBuilder(
          builder: (context, contraintes) {
            // Largeur d'une cellule : la largeur offerte, moins la gouttiere,
            // partagee en deux colonnes. C'est la largeur dans laquelle les
            // textes vont devoir s'ecrire, donc celle a laquelle on les mesure.
            final largeurCellule = contraintes.maxWidth.isFinite
                ? (contraintes.maxWidth - AppTheme.spacingMd) / 2
                : double.infinity;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cards.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: AppTheme.spacingMd,
                crossAxisSpacing: AppTheme.spacingMd,
                mainAxisExtent: hauteurDeTuilePour(
                  context,
                  cards: cards,
                  largeurCellule: largeurCellule,
                ),
              ),
              itemBuilder: (context, index) => cards[index],
            );
          },
        ),
      ],
    );
  }
}
