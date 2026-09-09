import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Une action de la [ContextualActionBar] (barre d'ACTIONS, pas d'onglets).
///
/// [salient] = action mise en avant (ex. SOS) : rendue en pastille pleine
/// accentuee ([color], defaut `AppTheme.rougeUrgence` cote SOS) pour ne JAMAIS
/// se noyer parmi les autres (AUDIT §M-2, enjeu securite).
@immutable
class ContextualAction {
  const ContextualAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.salient = false,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  /// Action saillante (accentuee, pleine) — ex. SOS. Defaut false.
  final bool salient;

  /// Couleur de l'accent quand [salient] (defaut `AppTheme.rougeUrgence`).
  final Color? color;

  /// Label semantique explicite (a11y) si le [label] visuel ne suffit pas.
  final String? semanticLabel;
}

/// Barre d'ACTIONS contextuelle StepWays (LOT 3 — refonte nav).
///
/// GARDE-FOU CARDINAL (AUDIT §2 / §3 / §4-G4, §M-1) : ce composant porte des
/// ACTIONS de l'ecran courant, PAS des destinations. Ce n'est donc PAS une
/// `NavigationBar` d'onglets : on la construit en `BottomAppBar` (barre
/// d'actions Material), VISUELLEMENT DISTINCTE d'une barre d'onglets, pour
/// eviter la dissonance HIG (« tab bar buttons should not perform actions ») et
/// le malentendu « les onglets sont revenus ». Les items ne sont PAS des
/// destinations egales : ils s'affichent en boutons d'action (icone + label),
/// et l'action saillante ([ContextualAction.salient], ex. SOS) est accentuee.
///
/// LOOK & FEEL : styles derives du THEME (surface de la `BottomAppBar`,
/// `colorScheme` pour les libelles, tokens `AppTheme` pour l'espacement). Aucun
/// token de design redefini (G3). Coherent sur tous les ecrans (un composant
/// unique, G4).
///
/// SOS (AUDIT §M-2) : passe une [ContextualAction] `salient` avec l'icone
/// urgence et `AppTheme.rougeUrgence` — la barre le rend en pastille pleine
/// accentuee, jamais un item de nav parmi d'autres.
class ContextualActionBar extends StatelessWidget {
  const ContextualActionBar({
    super.key,
    required this.actions,
  });

  /// Actions a afficher (max 3-4 recommande, AUDIT §3). Barre absente si vide.
  final List<ContextualAction> actions;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();

    return BottomAppBar(
      // Style herite du BottomAppBarTheme / surface du theme (aucune couleur en
      // dur). La BottomAppBar est visuellement distincte d'une NavigationBar
      // (barre d'actions, pas d'onglets) — garde-fou G4.
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final action in actions)
            Expanded(
              child: _ActionButton(action: action),
            ),
        ],
      ),
    );
  }
}

/// Bouton d'action interne : rendu accentue si [ContextualAction.salient],
/// sinon rendu discret (icone + label sur la surface de la barre).
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final ContextualAction action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (action.salient) {
      // Action saillante (SOS) : pastille pleine accentuee — impossible a
      // confondre avec un item de nav (AUDIT §M-2).
      final accent = action.color ?? AppTheme.rougeUrgence;
      return Semantics(
        button: true,
        label: action.semanticLabel ?? action.label,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
          child: Material(
            color: accent,
            borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
              onTap: action.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingSm,
                  horizontal: AppTheme.spacingXs,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, color: Colors.white, size: 22),
                    const SizedBox(height: AppTheme.spacingXs),
                    Text(
                      action.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Action standard : bouton discret (icone + label) sur la surface.
    return Semantics(
      button: true,
      label: action.semanticLabel ?? action.label,
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        onTap: action.onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppTheme.spacingSm,
            horizontal: AppTheme.spacingXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, color: scheme.onSurface, size: 22),
              const SizedBox(height: AppTheme.spacingXs),
              Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
