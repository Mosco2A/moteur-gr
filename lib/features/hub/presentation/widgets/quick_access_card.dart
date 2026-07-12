import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_card.dart';

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
    this.enabled = true,
    this.lockedLabel,
  });

  /// Icone illustrant la destination.
  final IconData icon;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    // Couleurs attenuees quand la carte est desactivee (verrou).
    final iconColor =
        enabled ? scheme.primary : scheme.onSurface.withValues(alpha: 0.38);
    final titleColor =
        enabled ? scheme.onSurface : scheme.onSurface.withValues(alpha: 0.38);
    final subtitleText = enabled ? subtitle : (lockedLabel ?? subtitle);

    return AppCard(
      onTap: enabled ? onTap : null,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              if (!enabled) ...[
                const Spacer(),
                Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: scheme.onSurface.withValues(alpha: 0.38),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            subtitleText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: enabled ? 0.7 : 0.38),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
