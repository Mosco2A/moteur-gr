import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/empty_state.dart';
import '../models/day_plan.dart';
import '../providers/planning_provider.dart';
import '../widgets/day_plan_card.dart';
import '../widgets/duration_selector.dart';

/// Écran de planification du trek.
///
/// Permet de choisir la durée du trek parmi les options
/// disponibles et affiche la répartition des étapes par jour.
/// Le planning se recalcule automatiquement à chaque
/// changement de durée.
class TrailPlanningScreen extends ConsumerWidget {
  const TrailPlanningScreen({super.key, required this.trailId});

  /// Identifiant du sentier à planifier
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(trailConfigProvider);
    final selectedDuration = ref.watch(selectedDurationProvider);
    final planningAsync = ref.watch(planningProvider(trailId));

    return Scaffold(
      appBar: AppBar(title: const Text('Planning')),
      body: Column(
        children: [
          // Sélecteur de durée
          DurationSelector(
            availableDurations: config.availableDurations,
            selectedDuration: selectedDuration,
            onDurationChanged: (duration) {
              ref.read(selectedDurationProvider.notifier).set(
                  duration);
            },
          ),
          const Divider(height: 1),
          // Liste des jours
          Expanded(
            child: planningAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => EmptyState(
                icon: Icons.error_outline,
                title: 'Impossible de calculer le planning',
                subtitle: error.toString(),
              ),
              data: (days) => _PlanningContent(
                days: days,
                trailId: trailId,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Contenu principal : liste des jours + résumé en bas
class _PlanningContent extends StatelessWidget {
  const _PlanningContent({
    required this.days,
    required this.trailId,
  });

  final List<DayPlan> days;
  final String trailId;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const EmptyState(
        icon: Icons.calendar_today,
        title: 'Aucun planning disponible',
        subtitle: 'Les données du sentier ne sont pas chargées.',
      );
    }

    return Column(
      children: [
        // Liste scrollable des cartes de jours
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              top: AppTheme.spacingSm,
              bottom: AppTheme.spacingSm,
            ),
            itemCount: days.length,
            itemBuilder: (context, index) {
              return DayPlanCard(dayPlan: days[index]);
            },
          ),
        ),
        // Résumé en bas
        _PlanningSummary(days: days),
      ],
    );
  }
}

/// Barre de résumé en bas de l'écran (totaux)
class _PlanningSummary extends StatelessWidget {
  const _PlanningSummary({required this.days});

  final List<DayPlan> days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walkDays = days.where((d) => !d.isRestDay).length;
    final restDays = days.where((d) => d.isRestDay).length;
    final totalKm = days.fold<double>(
      0,
      (sum, d) => sum + d.totalDistanceKm,
    );
    final totalGain = days.fold<int>(
      0,
      (sum, d) => sum + d.totalElevationGainM,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withAlpha(60),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _SummaryItem(
              label: '${totalKm.toStringAsFixed(1)} km',
              icon: Icons.straighten,
              theme: theme,
            ),
            _SummaryItem(
              label: '$totalGain m D+',
              icon: Icons.trending_up,
              theme: theme,
            ),
            _SummaryItem(
              label: '$walkDays j. marche',
              icon: Icons.hiking,
              theme: theme,
            ),
            if (restDays > 0)
              _SummaryItem(
                label: '$restDays j. repos',
                icon: Icons.self_improvement,
                theme: theme,
              ),
          ],
        ),
      ),
    );
  }
}

/// Item du résumé (icône + label)
class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.icon,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
