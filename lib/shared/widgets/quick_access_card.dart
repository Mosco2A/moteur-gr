/// La brique des grilles du cockpit : icone, titre, sous-titre, une navigation
/// — et le style vient d'AppCard, jamais d'un style ad hoc.
library;

import 'package:flutter/material.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';
import 'app_card.dart';
import 'step_status_icon.dart';
import 'texte_ajuste.dart';

/// Carte d'acces rapide du HUB (RF-14).
///
/// Brique de base des grilles de sections (Preparer / Randonner / Informations
/// / Apres). Chaque carte porte une icone, un titre, un sous-titre court et une
/// action de navigation. Reutilise [AppCard] pour le style commun (radius,
/// surface, ombre) — aucun style ad hoc.
///
/// LOT-A (D2, arbitrage #94902) : cartes SIMPLES, sans appui long. L'indicateur
/// de statut de preparation ([stepStatus]) existait sans que personne le passe
/// — la coche etait ecrite et jamais affichee. Depuis le lot coche de
/// preparation (07/10), la section « Preparer » du cockpit le calcule depuis ce
/// qui est deja persiste (`statutDePreparationProvider`, cote `hub`).
///
/// Un etat [enabled] false rend la carte grisee et non cliquable (ex. Diplome
/// verrouille tant que le trek n'est pas termine, RF-10/RM-5) et expose alors
/// [lockedLabel] sous le titre a la place du sous-titre.
class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    this.icon,
    this.rubrique,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.enabled = true,
    this.lockedLabel,
    this.stepStatus,
  }) : assert(
         (icon == null) != (rubrique == null),
         'une carte porte UNE icone : une rubrique (bicolore) ou une icone '
         'Stepways (monochrome)',
       );

  /// Chemin d'une icone Stepways ([StepwaysIcons]) — pour les cartes qui ne sont
  /// pas l'une des 20 rubriques (secours, signaler, cartes hors ligne...).
  /// Exclusif avec [rubrique].
  ///
  /// TACHE 639 : ce chemin N'IMPOSE PLUS le monochrome. Si le dessin a un trace
  /// bicolore ([iconeBicolorePour]), la carte l'affiche — comme si la rubrique
  /// avait ete nommee. Passer par [rubrique] reste la voie explicite ; les deux
  /// donnent desormais le meme rendu.
  final String? icon;

  /// L'une des 20 rubriques de l'application. C'est la voie normale : la carte
  /// montre alors le dessin BICOLORE de Christophe, et retombe d'elle-meme sur
  /// le trace monochrome grise quand la carte est verrouillee — un dessin
  /// bicolore fige resterait vif a cote d'un titre eteint.
  final RubriqueStepways? rubrique;

  /// Couleur categorielle de l'icone (retour Chris 09/09, reco #IR02).
  ///
  /// Fournie par l'appelant depuis la palette [CategoryIconColors] du theme
  /// (variete GR20 : bleu / vert / orange / teal / rouge / jaune selon la
  /// nature de la carte) — JAMAIS une couleur en dur. Si `null`, on retombe sur
  /// l'accent-sentier (`colorScheme.primary`) : compatible avec les appels
  /// existants qui ne passent pas encore de categorie.
  final Color? iconColor;

  /// Titre de la carte (libelle localise).
  final String title;

  /// Sous-titre court (libelle localise).
  final String subtitle;

  /// Action de navigation au tap.
  final VoidCallback onTap;

  /// Carte active (cliquable). Si false : grisee + non cliquable.
  final bool enabled;

  /// Libelle affiche a la place du sous-titre quand [enabled] est false
  /// (ex. « Terminez votre trek pour debloquer »). Localise.
  final String? lockedLabel;

  /// Coche « sujet traite » (R5, clone GR20 `_buildStepStatusIcon`). Quand
  /// fournie, une petite icone de statut (notStarted/inProgress/completed) est
  /// posee sous le sous-titre — signal de progression sur les cartes de prepa.
  /// `null` -> aucune coche (cartes sans notion de progression).
  final PlanningStepStatus? stepStatus;

  /// Le dessin de la carte (tache 632).
  ///
  /// La rubrique s'affiche en BICOLORE tant que la carte est active et qu'aucune
  /// couleur categorielle n'est imposee. Des que l'une des deux conditions tombe
  /// — carte verrouillee, ou couleur demandee par l'appelant — on passe au trace
  /// monochrome : le bicolore fige ignorerait la couleur et la carte grisee
  /// garderait une icone vive, ce qui brouillerait le verrou.
  /// TACHE 639 (bug 3) : la carte d'acces est une TUILE PRINCIPALE, donc un
  /// sujet. Son dessin sort en bicolore qu'il ait ete nomme par [rubrique] ou
  /// passe a plat dans [icon] — c'est la regle de [iconeBicolorePour] qui
  /// repond, plus la forme de l'appel. Sans cela, les trois cartes du bandeau de
  /// « Mes treks » restaient monochromes alors que les seize du cockpit etaient
  /// bicolores : deux langages pour la meme carte.
  Widget _icone(Color couleurEffective) {
    final dessin = rubrique ?? (icon != null ? iconeBicolorePour(icon!) : null);
    if (dessin != null) {
      final impose = !enabled || iconColor != null;
      return IconeStepways(
        dessin,
        taille: 24,
        couleur: impose ? couleurEffective : null,
      );
    }
    return StepIcon(icon!, color: couleurEffective, size: 24);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Couleur categorielle (variete GR20) portee par le theme quand fournie,
    // sinon repli sur l'accent-sentier. Attenuee quand la carte est desactivee
    // (verrou).
    final accent = iconColor ?? scheme.primary;
    final effectiveIconColor = enabled
        ? accent
        : scheme.onSurface.withValues(alpha: 0.38);
    final titleColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final subtitleText = enabled ? subtitle : (lockedLabel ?? subtitle);

    return AppCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      // Parite GR20 (_QuickAccessCard L1128-1150, retour Chris 09/09) : contenu
      // CENTRE — icone (pastille teintee) au-dessus, titre centre dessous. Avant,
      // `crossAxisAlignment: start` collait l'icone a gauche (defaut du pilote) ;
      // GR20 centre l'ensemble (`MainAxisAlignment.center` + `CrossAxisAlignment
      // .center`, titre `textAlign: center`).
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icone dans une pastille teintee (accent.withAlpha ~30) — centree
          // horizontalement (GR20 _QuickAccessCard L1133-1141). Le verrou
          // eventuel (carte desactivee) se place a droite via un cadenas
          // superpose, sans decentrer la pastille.
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: effectiveIconColor.withAlpha(enabled ? 30 : 20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: _icone(effectiveIconColor),
              ),
              if (!enabled)
                Positioned(
                  right: 0,
                  top: 0,
                  child: StepIcon(
                    StepwaysIcons.cadenas,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // LE TITRE S'AJUSTE AU LIEU DE SE COUPER (tache 634, DEM-260929-1325).
          //
          // Finitions V1 (point 6) : titre sur 2 lignes. Les titres longs
          // (« Découvrir des sentiers ») etaient TRONQUES a 1 ligne sur les
          // cartes etroites (Mes treks). Le budget de hauteur de la cellule
          // ([HubSection] mainAxisExtent) est releve en consequence (2 lignes
          // titre + 2 lignes sous-titre) — plus de troncature, pas d'overflow.
          //
          // Ce que ces deux lignes ne reglaient PAS : un titre d'UN SEUL MOT
          // plus large que la colonne. Flutter le casse alors en plein milieu
          // — « Ravitailleme / nt », retour de Christophe du 29/09 13:25 — sans
          // lever la moindre exception. [TexteAjuste] reduit la police juste
          // assez pour que le mot tienne entier, dans les cinq langues — pire
          // cas mesure : l'espagnol « Avituallamiento », 15 caracteres.
          TexteAjuste(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            subtitleText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: enabled ? 0.7 : 0.38),
            ),
            textAlign: TextAlign.center,
            // Quand une coche de statut est presente, le sous-titre passe a 1
            // ligne : le budget de hauteur de la cellule (mainAxisExtent 150)
            // est calibre « titre 1 + sous-titre 2 » ; la coche prend la place
            // de la 2e ligne (clone GR20 : coche petite sous le libelle).
            maxLines: stepStatus != null ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          // Coche « sujet traite » (R5) sous le libelle, comme GR20.
          if (stepStatus != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            StepStatusIcon(status: stepStatus!, size: 18),
          ],
        ],
      ),
    );
  }
}
