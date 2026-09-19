import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import 'hub_section.dart';
import 'quick_access_card.dart';

/// Section « Préparer » repliable en ACCORDÉON (StepWays refonte nav — D3, R8+R13).
///
/// Parité GR20 « modèle A » (toutes les sections dans UN scroll) : la préparation
/// reste TOUJOURS présente et accessible, mais son encombrement s'adapte à la
/// PHASE. Une fois parti (Randonner) ou de retour (Après le trek), la longue
/// grille de cartes de prépa n'a plus à occuper le haut du cockpit : elle est
/// REPLIÉE par défaut (en-tête tappable « Préparer ▸ »), le randonneur la déplie
/// s'il veut revoir un point (R13 : jamais masquée, juste repliée). En phase de
/// préparation (owned/prepared) et à la maison, elle est DÉPLIÉE d'emblée : c'est
/// le cœur de l'activité à ce moment (R8).
///
/// L'état déplié/replié est LOCAL à l'écran (pas de persistance) : il s'initialise
/// sur [initiallyExpanded] à chaque montage, dérivé de la phase par l'appelant
/// (déplié en Préparer, replié en Randonner/Après). Réutilise [HubSection] (grille
/// 2 colonnes, look inchangé) pour le corps déplié — aucun style réinventé, tokens
/// [AppTheme]. Zéro texte en dur (Slang `t.hub.*`).
class CollapsiblePrepareSection extends StatefulWidget {
  const CollapsiblePrepareSection({
    super.key,
    required this.cards,
    required this.initiallyExpanded,
  });

  /// Cartes d'accès de la section (identiques à une [HubSection] classique).
  final List<QuickAccessCard> cards;

  /// État initial de l'accordéon au montage : déplié (préparation/maison) ou
  /// replié (Randonner/Après). Dérivé de la phase par l'appelant.
  final bool initiallyExpanded;

  @override
  State<CollapsiblePrepareSection> createState() =>
      _CollapsiblePrepareSectionState();
}

class _CollapsiblePrepareSectionState extends State<CollapsiblePrepareSection> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête tappable de l'accordéon : icône + titre + chevron d'état.
        // Cible tactile pleine largeur >= 48 dp (InkWell + padding). Sémantique
        // « bouton, développé/réduit » pour l'accessibilité.
        Semantics(
          button: true,
          expanded: _expanded,
          label: t.hub.sections.prepare,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
              child: Row(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      t.hub.sections.prepare,
                      style: theme.textTheme.titleLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Chevron d'état (haut = déplié, bas = replié) + libellé court
                  // d'action (Réduire / Voir la préparation) pour lever toute
                  // ambiguïté (parité affordance accordéon).
                  Text(
                    _expanded ? t.hub.prepareCollapse : t.hub.prepareExpand,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Corps déplié : la grille de cartes (HubSection sans son propre en-tête,
        // l'accordéon porte déjà le titre « Préparer »). Replié -> rien.
        if (_expanded) ...[
          const SizedBox(height: AppTheme.spacingMd),
          HubSection(
            title: t.hub.sections.prepare,
            showHeader: false,
            icon: Icons.assignment_outlined,
            cards: widget.cards,
          ),
        ],
      ],
    );
  }
}
