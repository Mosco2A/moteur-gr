import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// Formate un poids en grammes avec separateur de milliers (parite GR20).
/// Ex: 1600 -> "1 600 g", 350 -> "350 g".
String formatChecklistGrams(int grams) {
  final unit = t.checklist.weight.grams;
  if (grams < 1000) return '$grams $unit';
  final str = grams.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '${buffer.toString()} $unit';
}

/// Couleur / conseil / icone selon le ratio poids sac / corps.
///
/// Memes seuils que GR20 « Materiel & Sac » : 12 / 15 / 20 / 25 %. Couleurs
/// semantiques via [AppTheme] (hors systeme de peaux) — les paliers
/// intermediaires (jaune-vert, rouge fonce) sont des couleurs fixes comme GR20.
({Color color, String advice, IconData icon}) checklistRatioAdvice(
    double ratio) {
  final w = t.checklist.weight;
  if (ratio < 0.12) {
    return (
      color: AppTheme.vertFacile,
      advice: w.adviceUltraLight,
      icon: Icons.check_circle,
    );
  } else if (ratio < 0.15) {
    return (
      color: const Color(0xFF9ACD32), // jaune-vert (parite GR20)
      advice: w.adviceOk,
      icon: Icons.check_circle,
    );
  } else if (ratio < 0.20) {
    return (
      color: AppTheme.orangeDifficile,
      advice: w.adviceHeavy,
      icon: Icons.warning_amber,
    );
  } else if (ratio < 0.25) {
    return (
      color: AppTheme.rougeUrgence,
      advice: w.adviceTooHeavy,
      icon: Icons.error,
    );
  } else {
    return (
      color: const Color(0xFF8B0000), // rouge fonce (parite GR20)
      advice: w.adviceDanger,
      icon: Icons.error,
    );
  }
}

/// Bandeau en haut avec le poids total du sac + conseil colore + compteur
/// d'articles coches (parite GR20 « Materiel & Sac » — _WeightBanner).
class ChecklistWeightBanner extends StatelessWidget {
  const ChecklistWeightBanner({
    super.key,
    required this.checkedWeightGrams,
    required this.backpackRatio,
    required this.checkedCount,
    required this.totalCount,
  });

  /// Poids total du sac en grammes (articles coches, quantite comprise).
  final int checkedWeightGrams;

  /// Ratio sac / corps (0..1+), pilote la couleur (meme referentiel que jauge).
  final double backpackRatio;

  /// Nombre d'articles coches / total (compteur GR20).
  final int checkedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = checklistRatioAdvice(backpackRatio);
    final itemsLabel = t.checklist.weight.itemsChecked
        .replaceAll('{checked}', '$checkedCount')
        .replaceAll('{total}', '$totalCount');

    return Container(
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
            child: Icon(Icons.luggage, size: 32, color: a.color),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatChecklistGrams(checkedWeightGrams),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: a.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Icon(a.icon, size: 20, color: a.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  a.advice,
                  style: theme.textTheme.bodySmall?.copyWith(color: a.color),
                ),
                Text(
                  itemsLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de saisie du poids corporel + chip ratio (parite GR20).
class ChecklistBodyWeightRow extends StatefulWidget {
  const ChecklistBodyWeightRow({
    super.key,
    required this.bodyWeightKg,
    required this.backpackRatio,
    required this.onBodyWeightChanged,
  });

  final double bodyWeightKg;
  final double backpackRatio;
  final void Function(double kg) onBodyWeightChanged;

  @override
  State<ChecklistBodyWeightRow> createState() => _ChecklistBodyWeightRowState();
}

class _ChecklistBodyWeightRowState extends State<ChecklistBodyWeightRow> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.bodyWeightKg.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightT = t.checklist.weight;

    return Padding(
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
            width: 120,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                isDense: true,
                suffixText: weightT.kilograms,
              ),
              onTap: () {
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
              onChanged: (val) {
                final kg = double.tryParse(val);
                if (kg != null && kg > 0) {
                  widget.onBodyWeightChanged(kg);
                }
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Flexible(child: _RatioChip(ratio: widget.backpackRatio)),
        ],
      ),
    );
  }
}

/// Chip indicateur du ratio sac / poids corporel (parite GR20).
class _RatioChip extends StatelessWidget {
  const _RatioChip({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).toStringAsFixed(0);
    final color = checklistRatioAdvice(ratio).color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$pct%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Jauge visuelle du poids relatif (% poids corporel) — parite GR20
/// (_WeightGauge). Seuils 12 / 15 / 20 / 25 %, marqueurs 15 / 20 / 25 %,
/// texte d'objectif.
class ChecklistWeightGauge extends StatelessWidget {
  const ChecklistWeightGauge({super.key, required this.backpackRatio});

  final double backpackRatio;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = t.checklist.weight;
    final pct = backpackRatio * 100;

    Color gaugeColor;
    String gaugeLabel;
    if (pct < 12) {
      gaugeColor = AppTheme.vertFacile;
      gaugeLabel = w.gaugeUltraLight;
    } else if (pct < 15) {
      gaugeColor = const Color(0xFF9ACD32);
      gaugeLabel = w.gaugeOk;
    } else if (pct < 20) {
      gaugeColor = AppTheme.orangeDifficile;
      gaugeLabel = w.gaugeHeavy;
    } else if (pct < 25) {
      gaugeColor = AppTheme.rougeUrgence;
      gaugeLabel = w.gaugeWarn;
    } else {
      gaugeColor = const Color(0xFF8B0000);
      gaugeLabel = w.gaugeDanger;
    }

    final pctLabel = w.percentOfWeight
        .replaceAll('{pct}', pct.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  pctLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: gaugeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Text(
                  gaugeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: gaugeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.grisGranite.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (pct / 30).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: gaugeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (15 / 30) - 16,
                top: 14,
                child: Text('15%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (20 / 30) - 16,
                top: 14,
                child: Text('20%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (25 / 30) - 16,
                top: 14,
                child: Text('25%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            w.gaugeObjective,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 14, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
