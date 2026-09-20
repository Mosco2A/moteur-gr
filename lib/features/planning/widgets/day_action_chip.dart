import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Gris de texte secondaire REELLEMENT LISIBLE sur le fond courant.
///
/// Le moteur a deja paye cette lecon (retour R1, audit a11y E5.3a) :
/// [AppTheme.grisGranite] (0xFF616161) convient aux fonds clairs mais tombe a
/// ~2.6:1 sur les surfaces sombres du theme — echec WCAG AA. Sur fond sombre on
/// prend donc [AppTheme.grisTexteSecondaire] (~7:1), le token que le theme
/// reserve precisement a cet usage. Une seule regle, un seul endroit.
Color dayNeutralColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? AppTheme.grisTexteSecondaire
        : AppTheme.grisGranite;

/// Role semantique d'une action de jour — la COULEUR en est derivee.
///
/// StepWays est un moteur MULTI-SENTIERS : la couleur d'un chip ne peut pas
/// etre une valeur en dur. GR20, lui, est mono-sentier — ses chips ecrivent
/// `AppTheme.bleuLight` / `AppTheme.orangeLight` en dur parce que cette palette
/// EST sa palette, la seule qu'il aura jamais. Transposer le code tel quel ici
/// donnait des chips bleus au milieu d'un sentier brun et orange. On reprend
/// donc de GR20 non pas ses valeurs mais son PARTAGE DES ROLES : deux tons, le
/// principal pour regrouper et le repos, le second pour separer — et on les
/// lit dans le theme du sentier actif.
enum DayActionTone {
  /// Action principale (« Regrouper », « Repos ») -> `colorScheme.primary`.
  principal,

  /// Action differenciee (« Separer ») -> `colorScheme.secondary`.
  secondaire,
}

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
    required this.tone,
    required this.onPressed,
    this.enabled = true,
  });

  final IconData icon;
  final String label;

  /// Role de l'action : la couleur est resolue depuis le theme, jamais fournie
  /// en dur par l'appelant (cf. [DayActionTone]).
  final DayActionTone tone;

  final VoidCallback onPressed;

  /// Action disponible : quand `false`, le chip est grise (mais reste tappable
  /// pour afficher la raison via un snackbar) — parite GR20.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Couleur ACTIVE : celle du sentier actif, via le theme. Bruns/orange sur
    // le Sentier des Volcans, verts sur un sentier vert — sans une ligne de
    // code par sentier.
    final activeColor = tone == DayActionTone.secondaire
        ? scheme.secondary
        : scheme.primary;

    // Couleur INDISPONIBLE : un gris qui reste LISIBLE (cf. [dayNeutralColor]).
    // L'ancien `grisGranite.withAlpha(120)` cumulait les deux fautes — un gris
    // deja non conforme sur fond sombre, encore attenue a 47 % d'opacite.
    final effectiveColor = enabled ? activeColor : dayNeutralColor(context);

    // C'est le FOND et la BORDURE qui portent l'etat, pas la lisibilite du
    // texte : un chip desactive s'aplatit visuellement mais son libelle reste
    // parfaitement lisible.
    final fillAlpha = enabled ? 20 : 10;
    final borderAlpha = enabled ? 60 : 40;

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
              color: effectiveColor.withAlpha(fillAlpha),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              border: Border.all(color: effectiveColor.withAlpha(borderAlpha)),
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
    // Meme lecon de contraste que les chips : sans couleur semantique imposee
    // (D+ en rouge, etc.), l'icone prend le gris LISIBLE du fond courant et non
    // `grisGranite` en dur, illisible sur le theme sombre.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color ?? dayNeutralColor(context)),
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
