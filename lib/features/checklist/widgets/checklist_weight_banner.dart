import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Volet POIDS du sac (parite GR20 « Materiel & Sac », #99433).
///
/// Reintegre cote StepWays l'ecart connu vs GR20 : le poids du sac etait
/// absent de la checklist. Ce bandeau affiche, comme GR20 :
///   * le poids TOTAL du sac (somme des articles coches) ;
///   * un conseil colore selon le ratio poids sac / poids corporel ;
///   * la saisie du poids corporel + le ratio (%) ;
///   * une jauge visuelle du ratio (seuils 12 / 15 / 20 / 25 %).
///
/// Generique (aucune localite en dur), hors systeme de peaux (couleurs
/// semantiques via [AppTheme], comme le reste de l'app). Tout texte via Slang.
class ChecklistWeightBanner extends StatefulWidget {
  const ChecklistWeightBanner({
    super.key,
    required this.checkedWeightGrams,
    required this.bodyWeightKg,
    required this.backpackRatio,
    required this.onBodyWeightChanged,
  });

  /// Poids total du sac en grammes (articles coches).
  final int checkedWeightGrams;

  /// Poids corporel courant en kg (denominateur du ratio).
  final double bodyWeightKg;

  /// Ratio sac / corps (0..1+).
  final double backpackRatio;

  /// Notifie un nouveau poids corporel (kg) saisi par l'utilisateur.
  final void Function(double kg) onBodyWeightChanged;

  @override
  State<ChecklistWeightBanner> createState() => _ChecklistWeightBannerState();
}

class _ChecklistWeightBannerState extends State<ChecklistWeightBanner> {
  late final TextEditingController _bodyWeightController;

  @override
  void initState() {
    super.initState();
    _bodyWeightController = TextEditingController(
      text: widget.bodyWeightKg.toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _bodyWeightController.dispose();
    super.dispose();
  }

  /// Formate un poids en grammes -> "1,2 kg" ou "350 g" (parite GR20).
  String _formatWeight(int grams) {
    if (grams >= 1000) {
      final kg = grams / 1000.0;
      final rounded = kg.truncateToDouble() == kg ? 0 : 1;
      return '${kg.toStringAsFixed(rounded)} ${t.checklist.weight.kilograms}';
    }
    return '$grams ${t.checklist.weight.grams}';
  }

  /// Couleur + conseil selon le ratio (memes seuils que GR20).
  ({Color color, String advice, IconData icon}) _advice() {
    final ratio = widget.backpackRatio;
    final w = t.checklist.weight;
    if (ratio < 0.12) {
      return (
        color: AppTheme.vertFacile,
        advice: w.adviceLight,
        icon: Icons.check_circle,
      );
    } else if (ratio < 0.15) {
      return (
        color: const Color(0xFF9ACD32),
        advice: w.adviceOk,
        icon: Icons.check_circle,
      );
    } else if (ratio < 0.20) {
      return (
        color: AppTheme.orangeDifficile,
        advice: w.adviceHeavy,
        icon: Icons.warning_amber,
      );
    } else {
      return (
        color: AppTheme.rougeUrgence,
        advice: w.adviceTooHeavy,
        icon: Icons.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightT = t.checklist.weight;
    final a = _advice();
    final pct = (widget.backpackRatio * 100).toStringAsFixed(0);

    return Column(
      children: [
        // --- Bandeau poids total + conseil colore ---
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          color: a.color.withAlpha(25),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: a.color.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Icon(Icons.backpack_outlined, size: 30, color: a.color),
              ),
              const SizedBox(width: AppTheme.spacingBase),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatWeight(widget.checkedWeightGrams),
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: a.color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Icon(a.icon, size: 18, color: a.color),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a.advice,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: a.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- Poids corporel (saisie) + ratio ---
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          child: Row(
            children: [
              Icon(Icons.monitor_weight_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(
                child: Text(
                  weightT.bodyWeight,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              SizedBox(
                width: 96,
                child: TextField(
                  controller: _bodyWeightController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    suffixText: weightT.kilograms,
                  ),
                  onChanged: (val) {
                    final kg = double.tryParse(val);
                    if (kg != null && kg > 0) {
                      widget.onBodyWeightChanged(kg);
                    }
                  },
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              _RatioChip(ratio: widget.backpackRatio, label: '$pct%'),
            ],
          ),
        ),

        // --- Jauge visuelle du ratio ---
        Padding(
          padding: const EdgeInsets.only(
            left: AppTheme.spacingBase,
            right: AppTheme.spacingBase,
            bottom: AppTheme.spacingSm,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              // Plein a 25 % de ratio (zone rouge), comme GR20.
              value: (widget.backpackRatio / 0.25).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.onSurface.withAlpha(30),
              valueColor: AlwaysStoppedAnimation(a.color),
            ),
          ),
        ),
      ],
    );
  }
}

/// Chip du ratio sac / corps (couleur coherente avec la jauge).
class _RatioChip extends StatelessWidget {
  const _RatioChip({required this.ratio, required this.label});

  final double ratio;
  final String label;

  @override
  Widget build(BuildContext context) {
    Color color;
    if (ratio < 0.12) {
      color = AppTheme.vertFacile;
    } else if (ratio < 0.15) {
      color = const Color(0xFF9ACD32);
    } else if (ratio < 0.20) {
      color = AppTheme.orangeDifficile;
    } else {
      color = AppTheme.rougeUrgence;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
