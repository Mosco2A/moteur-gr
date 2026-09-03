import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/models/stage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../models/planned_day.dart';
import '../providers/planned_days_provider.dart';

/// Ecran PROGRAMME (parite GR20 `PlanningScreen`).
///
/// Programme detaille jour par jour du sentier courant : chaque jour porte ses
/// etapes (nom, distance, D+, D-, duree), une pastille teintee par difficulte et
/// un acces au DETAIL de l'etape (tap -> `/stages/:num`). Le programme est
/// EDITABLE a l'identique de GR20 : reorganisation (drag & drop), regroupement /
/// separation d'etapes, ajout / suppression de jours de repos, replanification,
/// validation. En-tete de statistiques (distance, D+, jours, etapes), profil
/// altimetrique par jour et legende des difficultes completent l'ecran.
///
/// Generique : alimente par [plannedDaysProvider] (etapes du sentier actif),
/// ZERO hardcode de localite. Hors systeme de peaux (AppCard implicite via
/// Material du Scaffold, couleurs semantiques d'AppTheme et du colorScheme).
/// Tout libelle passe par Slang (t.programme.* / t.stage.*).
///
/// NOTE (ecart de modele assume, cf. rapport) : le modele de donnees StepWays
/// ([StageModel]) ne porte ni date de depart, ni mode de confort / hebergement,
/// ni sens de marche NS/SN. Les elements GR20 qui en dependent (chip
/// hebergement, date sous chaque jour, inversion NS/SN) n'ont donc pas
/// d'equivalent tant que le socle sentier ne fournit pas ces donnees.
class TrailPlanningScreen extends ConsumerWidget {
  const TrailPlanningScreen({super.key, required this.trailId});

  /// Identifiant du sentier a planifier.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(plannedDaysProvider(trailId));
    final stats = ref.watch(planningStatsProvider(trailId));

    return Scaffold(
      appBar: AppBar(
        title: Text(t.programme.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoSheet(context),
            tooltip: t.programme.helpTooltip,
          ),
        ],
      ),
      body: SafeArea(
        child: days.isEmpty
            ? _EmptyState(trailId: trailId)
            : _PlanningContent(trailId: trailId, days: days, stats: stats),
      ),
    );
  }

  /// (i) riche — guide du programme au format structure (parite GR20).
  void _showInfoSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: scheme.primary, size: 24),
                const SizedBox(width: 8),
                Text(
                  t.programme.info.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _richInfoItem(theme, Icons.view_list, t.programme.info.days.title,
                t.programme.info.days.body, scheme.primary),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.drag_handle,
                t.programme.info.reorder.title, t.programme.info.reorder.body,
                AppTheme.vertFacile),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.hotel, t.programme.info.rest.title,
                t.programme.info.rest.body, AppTheme.orangeDifficile),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.link, t.programme.info.mergeSplit.title,
                t.programme.info.mergeSplit.body, scheme.primary),
            const SizedBox(height: 12),
            _richInfoItem(theme, Icons.circle, t.programme.info.colors.title,
                t.programme.info.colors.body, AppTheme.vertFacile),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: scheme.primary.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.show_chart, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.programme.info.note,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(t.programme.info.close,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _richInfoItem(ThemeData theme, IconData icon, String title,
      String description, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 22, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Contenu principal du programme : en-tete, profil, legende, liste editable,
/// boutons replanifier + valider (parite GR20 `_buildPlanningContent`).
class _PlanningContent extends ConsumerWidget {
  const _PlanningContent({
    required this.trailId,
    required this.days,
    required this.stats,
  });

  final String trailId;
  final List<PlannedDay> days;
  final PlanningStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(plannedDaysProvider(trailId).notifier);

    return Column(
      children: [
        _StatsHeader(stats: stats),
        if (days.any((d) => !d.isRestDay)) _ElevationProfile(days: days),
        const _DifficultyLegend(),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingBase,
              vertical: AppTheme.spacingSm,
            ),
            itemCount: days.length,
            onReorder: notifier.reorder,
            itemBuilder: (context, index) {
              final day = days[index];
              return _DayCard(
                key: ValueKey('day_${day.dayNumber}_$index'),
                trailId: trailId,
                day: day,
                onAddRestDay: () => notifier.addRestDay(index),
                onRemoveRestDay:
                    day.isRestDay ? () => notifier.removeRestDay(index) : null,
                canSplit: notifier.canSplit(index),
                canMerge: notifier.canMergeWithNext(index),
                mergeBlockedReason:
                    !day.isRestDay ? notifier.mergeBlockedReason(index) : null,
                onSplit: () => notifier.splitDay(index),
                onMerge: () => notifier.mergeWithNext(index),
              );
            },
          ),
        ),
        if (notifier.hasManualRestDays)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingLg),
            child: OutlinedButton.icon(
              onPressed: () => _showReplanConfirmation(context, ref),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(t.programme.replanButton),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: ElevatedButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            child: Text(t.programme.validate),
          ),
        ),
      ],
    );
  }

  void _showReplanConfirmation(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.programme.replanDialog.title),
        content: Text(t.programme.replanDialog.message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.programme.replanDialog.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(plannedDaysProvider(trailId).notifier)
                  .regeneratePreservingRestDays();
            },
            child: Text(t.programme.replanDialog.confirm),
          ),
        ],
      ),
    );
  }
}

/// En-tete de statistiques (parite GR20 `_StatsHeader`) : distance, D+, jours
/// (avec repos), etapes.
class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.stats});

  final PlanningStats stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final joursLabel = stats.restDays > 0
        ? '${stats.totalDays} (${t.programme.stats.restCount.replaceAll('{count}', '${stats.restDays}')})'
        : '${stats.totalDays}';

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      color: theme.colorScheme.primary.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Flexible(
            child: _StatItem(
              label: t.programme.stats.distance,
              value: '${stats.totalDistance.toStringAsFixed(0)} km',
            ),
          ),
          Flexible(
            child: _StatItem(
              label: t.programme.stats.elevation,
              value: '${stats.totalElevationGain} m',
            ),
          ),
          Flexible(
            child: _StatItem(
              label: t.programme.stats.days,
              value: joursLabel,
            ),
          ),
          Flexible(
            child: _StatItem(
              label: t.programme.stats.stages,
              value: '${stats.stageCount}',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Legende des couleurs de difficulte (parite GR20 `_DifficultyLegend`).
class _DifficultyLegend extends StatelessWidget {
  const _DifficultyLegend();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingXs,
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppTheme.spacingBase,
        runSpacing: AppTheme.spacingXs,
        children: [
          _LegendItem(color: AppTheme.vertFacile, label: t.programme.legend.easy),
          _LegendItem(
              color: AppTheme.jauneModere, label: t.programme.legend.moderate),
          _LegendItem(
              color: AppTheme.orangeDifficile, label: t.programme.legend.hard),
          _LegendItem(
              color: AppTheme.rougeExtreme, label: t.programme.legend.extreme),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 14)),
      ],
    );
  }
}

/// Profil altimetrique simplifie par jour (parite GR20 `_ElevationProfile`).
/// Barre par jour, hauteur ~ D+, couleur ~ difficulte ; repos = barre basse "R".
class _ElevationProfile extends StatelessWidget {
  const _ElevationProfile({required this.days});

  final List<PlannedDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final dayElevations = <int>[];
    final dayDifficulties = <int>[];
    var maxElevation = 0;
    for (final day in days) {
      if (day.isRestDay || day.stages.isEmpty) {
        dayElevations.add(0);
        dayDifficulties.add(0);
        continue;
      }
      final gain = day.totalElevationGainM;
      dayElevations.add(gain);
      dayDifficulties.add(day.maxDifficulty);
      if (gain > maxElevation) maxElevation = gain;
    }
    if (maxElevation == 0) maxElevation = 1;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(dayElevations.length, (i) {
          final elevation = dayElevations[i];
          final difficulty = dayDifficulties[i];
          final heightRatio = elevation / maxElevation;
          final isRestDay = days[i].isRestDay;

          Color barColor;
          if (isRestDay) {
            barColor = theme.colorScheme.primary;
          } else if (elevation == 0) {
            barColor = AppTheme.grisGranite.withAlpha(30);
          } else if (difficulty <= 1) {
            barColor = AppTheme.vertFacile;
          } else if (difficulty <= 2) {
            barColor = AppTheme.jauneModere;
          } else if (difficulty <= 3) {
            barColor = AppTheme.orangeDifficile;
          } else {
            barColor = AppTheme.rougeExtreme;
          }

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1),
              child: FractionallySizedBox(
                heightFactor: isRestDay
                    ? 0.18
                    : (elevation == 0 ? 0.1 : heightRatio.clamp(0.1, 1.0)),
                child: Container(
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(2)),
                  ),
                  child: isRestDay
                      ? Center(
                          child: Text(
                            t.programme.restDayLabel,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Carte d'un jour du programme (parite GR20 `_DayCard`).
///
/// Jour de marche : pastille numero teintee par difficulte, nom(s) d'etape(s),
/// mini-stats (distance, D+, D-), duree ; tap -> detail de la 1re etape du jour ;
/// actions Regrouper / Separer / Repos + poignee de drag. Jour de repos : carte
/// dediee avec suppression.
class _DayCard extends ConsumerWidget {
  const _DayCard({
    super.key,
    required this.trailId,
    required this.day,
    required this.onAddRestDay,
    this.onRemoveRestDay,
    this.canSplit = false,
    this.canMerge = false,
    this.mergeBlockedReason,
    this.onSplit,
    this.onMerge,
  });

  final String trailId;
  final PlannedDay day;
  final VoidCallback onAddRestDay;
  final VoidCallback? onRemoveRestDay;
  final bool canSplit;
  final bool canMerge;
  final String? mergeBlockedReason;
  final VoidCallback? onSplit;
  final VoidCallback? onMerge;

  /// Traduit le code de blocage du notifier en libelle i18n (parite GR20).
  String _mergeBlockedLabel(String code) {
    switch (code) {
      case 'no-next':
        return t.programme.mergeBlocked.noNext;
      case 'rest':
        return t.programme.mergeBlocked.rest;
      case 'too-long':
        // Recalcul du nombre d'heures pour le message (comme GR20).
        final hours = day.estimatedHours;
        return t.programme.mergeBlocked.tooLong
            .replaceAll('{hours}', hours.toStringAsFixed(1))
            .replaceAll(
                '{max}', PlannedDaysNotifier.maxManualHoursPerDay.toInt().toString());
      default:
        return code;
    }
  }

  Color _difficultyColor(int rank) {
    if (rank <= 1) return AppTheme.vertFacile;
    if (rank <= 2) return AppTheme.jauneModere;
    if (rank <= 3) return AppTheme.orangeDifficile;
    return AppTheme.rougeExtreme;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (day.isRestDay) {
      return _buildRestDayCard(context, theme);
    }

    final durationStr = _formatDuration(day.estimatedHours);
    final difficultyColor = _difficultyColor(day.maxDifficulty);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      color: theme.colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: day.stages.isNotEmpty
            ? () => context.push('/stages/${day.stages.first.stageNumber}')
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMd),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pastille numero de jour teintee par difficulte.
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: difficultyColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  border: Border.all(color: difficultyColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    'J${day.dayNumber}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: difficultyColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom(s) d'etape(s) du jour.
                    ...day.stages.map(
                      (stage) => Text(
                        stage.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    // Mini-stats : distance, D+, D-.
                    Wrap(
                      spacing: AppTheme.spacingMd,
                      runSpacing: AppTheme.spacingXs,
                      children: [
                        _MiniStat(
                          icon: Icons.straighten,
                          value: '${day.totalDistanceKm.toStringAsFixed(1)} km',
                        ),
                        _MiniStat(
                          icon: Icons.arrow_upward,
                          value: '${day.totalElevationGainM} m D+',
                          color: AppTheme.rougeExtreme,
                        ),
                        _MiniStat(
                          icon: Icons.arrow_downward,
                          value: '${day.totalElevationLossM} m D-',
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    // Duree.
                    _MiniStat(icon: Icons.schedule, value: durationStr),
                  ],
                ),
              ),
              // Actions du jour + poignee de drag.
              Column(
                children: [
                  const Icon(Icons.drag_handle,
                      color: AppTheme.grisGranite, size: 20),
                  const SizedBox(height: 4),
                  _ActionChip(
                    icon: Icons.compress,
                    label: t.programme.actions.merge,
                    color: canMerge
                        ? theme.colorScheme.primary
                        : AppTheme.grisGranite.withAlpha(80),
                    onPressed: canMerge
                        ? onMerge!
                        : () {
                            final code = mergeBlockedReason;
                            if (code != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_mergeBlockedLabel(code)),
                                  duration: const Duration(seconds: 3),
                                ),
                              );
                            }
                          },
                  ),
                  if (canSplit)
                    _ActionChip(
                      icon: Icons.call_split,
                      label: t.programme.actions.split,
                      color: AppTheme.orangeDifficile,
                      onPressed: onSplit!,
                    ),
                  _ActionChip(
                    icon: Icons.self_improvement,
                    label: t.programme.actions.rest,
                    color: theme.colorScheme.primary,
                    onPressed: onAddRestDay,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carte de jour de repos (parite GR20 `_buildRestDayCard`).
  Widget _buildRestDayCard(BuildContext context, ThemeData theme) {
    final scheme = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: scheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: scheme.primary.withAlpha(80), width: 2),
              ),
              child: Center(
                child: Text(
                  'J${day.dayNumber}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Row(
                children: [
                  Icon(Icons.self_improvement, size: 20, color: scheme.primary),
                  const SizedBox(width: AppTheme.spacingSm),
                  Flexible(
                    child: Text(
                      t.programme.restDay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                const Icon(Icons.drag_handle,
                    color: AppTheme.grisGranite, size: 20),
                if (onRemoveRestDay != null) ...[
                  const SizedBox(height: 4),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    color: AppTheme.rougeUrgence,
                    tooltip: t.programme.actions.removeRest,
                    onPressed: onRemoveRestDay,
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 48, minHeight: 48),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formate une duree en heures decimales -> "Xh" ou "XhMM" (parite GR20).
  String _formatDuration(double totalHours) {
    final hours = totalHours.floor();
    final minutes = ((totalHours - hours) * 60).round();
    return minutes == 0
        ? '${hours}h'
        : '${hours}h${minutes.toString().padLeft(2, '0')}';
  }
}

/// Mini statistique (icone + valeur) (parite GR20 `_MiniStat`).
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value, this.color});

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

/// Petit bouton compact icone + label pour les actions jour (parite GR20
/// `_ActionChip`).
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            color: color.withAlpha(20),
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etat vide — aucune etape / itineraire non configure (parite GR20
/// `_buildEmptyState`).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route,
                size: 80, color: AppTheme.grisGranite.withAlpha(80)),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.programme.empty.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.programme.empty.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.grisGranite.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trail/$trailId/itinerary'),
              icon: const Icon(Icons.route),
              label: Text(t.programme.empty.action),
            ),
          ],
        ),
      ),
    );
  }
}
