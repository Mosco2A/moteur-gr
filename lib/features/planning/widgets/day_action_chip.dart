import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Petit bouton compact icone + label pour les actions d'un jour de programme
/// (parite GR20 `_ActionChip` de `planning_screen.dart`).
///
/// EXTRAIT de `trail_planning_screen.dart` au LOT L9 (R12) pour etre partage
/// avec l'ecran « Adapter l'itineraire » : le GESTE d'edition d'un jour doit
/// etre STRICTEMENT le meme en preparation et en rando (memes icones, memes
/// libelles, meme grisage, meme explication au tap) — pas deux ergonomies
/// paralleles qui divergeraient.
class DayActionChip extends StatelessWidget {
  const DayActionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  /// Action disponible : quand `false`, le chip est grise (mais reste tappable
  /// pour afficher la raison via un snackbar) — parite GR20.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    // Grise quand indisponible : couleur neutre, mais le chip reste visible et
    // tappable pour expliquer pourquoi l'action est bloquee.
    final effectiveColor =
        enabled ? color : AppTheme.grisGranite.withAlpha(120);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Semantics(
        button: true,
        enabled: enabled,
        label: label,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: effectiveColor.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              border: Border.all(color: effectiveColor.withAlpha(60)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: effectiveColor),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: effectiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Mini statistique (icone + valeur) d'une carte jour (parite GR20 `_MiniStat`).
///
/// Extraite au meme titre que [DayActionChip] : la carte jour de la rando
/// affiche exactement les memes mini-stats que celle de la preparation.
class DayMiniStat extends StatelessWidget {
  const DayMiniStat({
    super.key,
    required this.icon,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? AppTheme.grisGranite),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 14,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
