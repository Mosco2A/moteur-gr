import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/skin_theme.dart';

/// Bloc data "gros chiffre" reutilisable (SW-SKIN-L5).
///
/// Materialise le "moment data heros" de la Direction C (CCO §1.3) : une
/// [value] en role data tabular (Space Grotesk w700 + chiffres a chasse fixe,
/// role defini en L1 via [AppTheme.dataTextStyle]), une [unit] optionnelle plus
/// petite, et un [label] discret. Remplace les libelles plats du hub, de la
/// fiche etape et du HUD tracking.
///
/// Peau-aware (CCO §2.2) : lit `SkinTheme.of(context).usesMonoData` — quand la
/// peau l'exige (Topographique, cockpit instrument, L8), la valeur bascule en
/// fonte MONOSPACE tabular. Pour la peau par defaut (Sentier Vivant,
/// `usesMonoData == false`) le rendu reste STRICTEMENT le role data L1 : aucune
/// regression tant que L8 n'est pas livre.
///
/// A11y : la valeur, l'unite et le label forment UN seul noeud semantique
/// (`Semantics(label: "$label : $value $unit")`) et le visuel est masque aux
/// lecteurs d'ecran (`ExcludeSemantics`) — meme contrat que l'ancien `_StatTile`
/// du HUD tracking. Le texte visible reste soumis au [textScale].
class AppDataStat extends StatelessWidget {
  const AppDataStat({
    super.key,
    required this.value,
    required this.label,
    this.unit,
    this.icon,
    this.mono,
    this.valueColor,
    this.labelColor,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  /// Valeur mise en avant (ex. "12.4", "+840"). Peut deja contenir l'unite
  /// (ex. "12.4 km") si [unit] est laisse `null` : utile pour un iso-rendu du
  /// HUD tracking dont les valeurs formatees incluent deja l'unite.
  final String value;

  /// Libelle discret sous la valeur (ex. "Distance", "D+").
  final String label;

  /// Unite affichee plus petite a cote de la valeur (ex. "km", "m"). `null` =>
  /// pas d'unite separee (la valeur est rendue telle quelle).
  final String? unit;

  /// Icone optionnelle au-dessus de la valeur (teintee accent). Reprend le
  /// pictogramme des tuiles du HUD tracking ; `null` => pas d'icone (hub,
  /// fiche etape).
  final IconData? icon;

  /// Force le rendu mono tabular de la valeur. `null` => on suit la peau active
  /// (`SkinTheme.usesMonoData`). Expose pour tester / forcer le cockpit sans
  /// dependre d'une peau installee.
  final bool? mono;

  /// Couleur de la valeur. `null` => couleur du texte du theme (heritee).
  final Color? valueColor;

  /// Couleur du label. `null` => gris texte secondaire du theme.
  final Color? labelColor;

  /// Alignement horizontal de la colonne (valeur/unite/label). `center` pour le
  /// HUD (tuiles centrees), `start` pour les rangees alignees a gauche du hub.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skin = SkinTheme.of(context);
    final useMono = mono ?? skin.usesMonoData;

    // Role data L1 (Space Grotesk w700 tabular) resolu depuis le contexte, ou
    // bascule mono tabular quand la peau l'exige (Topographique, L8). Taille et
    // couleur restent celles du role data du theme.
    final baseData = AppTheme.dataTextStyle(context);
    final valueStyle =
        (useMono ? baseData.copyWith(fontFamily: 'monospace') : baseData)
            .copyWith(color: valueColor);

    // L'unite reprend la meme famille que la valeur (coherence tabular) mais
    // plus petite et en poids intermediaire : elle accompagne sans voler la
    // vedette (CCO : "unite plus petite").
    final unitStyle = valueStyle.copyWith(
      fontSize: (valueStyle.fontSize ?? 24) * 0.6,
      fontWeight: FontWeight.w600,
    );

    final labelStyle = theme.textTheme.bodySmall?.copyWith(
          color: labelColor ?? AppTheme.grisTexteSecondaire,
          fontSize: 12,
        ) ??
        TextStyle(color: labelColor ?? AppTheme.grisTexteSecondaire);

    // Semantique : un seul noeud "label : value unit" (unite incluse si fournie).
    final semanticsValue = unit == null ? value : '$value $unit';

    return Semantics(
      label: '$label : $semanticsValue',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18, color: theme.colorScheme.primary),
              const SizedBox(height: 2),
            ],
            // Valeur + unite sur la meme ligne de base : l'unite s'aligne sur la
            // base alphabetique de la valeur (Row baseline).
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: valueStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (unit != null) ...[
                  const SizedBox(width: 3),
                  Text(unit!, style: unitStyle),
                ],
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: labelStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: crossAxisAlignment == CrossAxisAlignment.center
                  ? TextAlign.center
                  : TextAlign.start,
            ),
          ],
        ),
      ),
    );
  }
}
