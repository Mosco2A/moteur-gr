import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';
import 'step_status_icon.dart';

/// Carte d'acces rapide du HUB (RF-14).
///
/// Brique de base des grilles de sections (Preparer / Randonner / Informations
/// / Apres). Chaque carte porte une icone, un titre, un sous-titre court et une
/// action de navigation. Reutilise [AppCard] pour le style commun (radius,
/// surface, ombre) — aucun style ad hoc.
///
/// LOT-A (D2, arbitrage #94902) : cartes SIMPLES, sans indicateur de statut de
/// preparation ni appui long (le `planningProgressProvider` + Drift sont
/// DIFFERES). L'API reste volontairement minimale.
///
/// Un etat [enabled] false rend la carte grisee et non cliquable (ex. Diplome
/// verrouille tant que le trek n'est pas termine, RF-10/RM-5) et expose alors
/// [lockedLabel] sous le titre a la place du sous-titre.
class QuickAccessCard extends StatelessWidget {
  const QuickAccessCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.enabled = true,
    this.lockedLabel,
    this.stepStatus,
  });

  /// Icone illustrant la destination.
  final IconData icon;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Couleur categorielle (variete GR20) portee par le theme quand fournie,
    // sinon repli sur l'accent-sentier. Attenuee quand la carte est desactivee
    // (verrou).
    final accent = iconColor ?? scheme.primary;
    final effectiveIconColor =
        enabled ? accent : scheme.onSurface.withValues(alpha: 0.38);
    final titleColor =
        enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38);
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
                child: Icon(icon, color: effectiveIconColor, size: 24),
              ),
              if (!enabled)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Icon(
                    Icons.lock_outline,
                    size: 18,
                    color: scheme.onSurface.withValues(alpha: 0.38),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
            textAlign: TextAlign.center,
            // Finitions V1 (point 6) : titre sur 2 lignes. Les titres longs
            // (« Découvrir des sentiers ») etaient TRONQUES a 1 ligne sur les
            // cartes etroites (Mes treks). Le budget de hauteur de la cellule
            // ([HubSection] mainAxisExtent) est releve en consequence (2 lignes
            // titre + 2 lignes sous-titre) — plus de troncature, pas d'overflow.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
