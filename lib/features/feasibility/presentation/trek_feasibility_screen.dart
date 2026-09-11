import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../domain/trek_feasibility_calculator.dart';
import '../providers/trek_feasibility_provider.dart';

/// Ecran de faisabilite OBJECTIVE profil x trek (StepWays LOT 4, Ph5).
///
/// Verdict base sur le profil reel (fiche + test 6 min + 5 randos) croise aux
/// exigences du trek (D+/j, km/j, jours, technicite, risque, effort). Affiche
/// le verdict + les points faibles POUR CE TREK, avec des acces rapides pour
/// completer le profil. Le questionnaire reste un fallback de dépannage
/// (accessible via /trail/:id/feasibility). Tous textes via Slang.
class TrekFeasibilityScreen extends ConsumerWidget {
  const TrekFeasibilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(trekFeasibilityResultProvider);
    final f = t.feasibility;

    return Scaffold(
      appBar: AppHeader(title: f.objectiveTitle),
      body: resultAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _FallbackToQuestionnaire(reason: f.objectiveIntro),
        data: (result) {
          if (result == null) {
            // Pas d'exigences trek (pas d'etapes) -> questionnaire de dépannage.
            return _FallbackToQuestionnaire(reason: f.sourceFallback);
          }
          return _VerdictView(result: result);
        },
      ),
    );
  }
}

class _VerdictView extends ConsumerWidget {
  const _VerdictView({required this.result});
  final TrekFeasibilityResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;
    final hasProfileAsync = ref.watch(hasObjectiveProfileProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(f.objectiveIntro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),
          _VerdictBadge(verdict: result.verdict),
          const SizedBox(height: AppTheme.spacingSm),
          // Source du verdict (objectif vs dépannage).
          Center(
            child: Text(
              result.usedObjectiveProfile
                  ? f.sourceObjective
                  : f.sourceFallback,
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          // Points faibles POUR CE TREK.
          if (result.gaps.isNotEmpty) ...[
            Text(f.weakPointsTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingSm),
            ...result.gaps.map((g) => _GapTile(gap: g)),
            const SizedBox(height: AppTheme.spacingLg),
          ],
          // Acces rapides pour completer / affiner le profil objectif.
          hasProfileAsync.maybeWhen(
            data: (has) => _ProfileShortcuts(trailId: trailId, complete: has),
            orElse: () => _ProfileShortcuts(trailId: trailId, complete: false),
          ),
        ],
      ),
    );
  }
}

/// Badge de verdict colore (reutilise la semantique de couleur du niveau).
class _VerdictBadge extends StatelessWidget {
  const _VerdictBadge({required this.verdict});
  final String verdict;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _verdictColor(verdict);
    final icon = _verdictIcon(verdict);
    final label = _resolveLevel(verdict);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingLg,
        vertical: AppTheme.spacingBase,
      ),
      decoration: BoxDecoration(
        color: color.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(90)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            label,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static String _resolveLevel(String verdict) {
    final resolved = t['feasibility.levels.$verdict'];
    return resolved is String ? resolved : verdict;
  }
}

/// Tuile d'un point faible (categorie i18n + severite coloree).
class _GapTile extends StatelessWidget {
  const _GapTile({required this.gap});
  final FeasibilityGapResult gap;

  String _resolveGap(String category) {
    final resolved = t['feasibility.gaps.$category'];
    return resolved is String ? resolved : category;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blocking = gap.severity == GapSeverity.blocking;
    final color =
        blocking ? AppTheme.rougeUrgence : AppTheme.orangeDifficile;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      backgroundColor: color.withAlpha(18),
      borderColor: color.withAlpha(70),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            blocking ? Icons.dangerous : Icons.warning_amber,
            color: color,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              _resolveGap(gap.category),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Acces rapides vers la fiche info, le test 6 min et les 5 randos.
class _ProfileShortcuts extends StatelessWidget {
  const _ProfileShortcuts({required this.trailId, required this.complete});
  final String trailId;
  final bool complete;
  @override
  Widget build(BuildContext context) {
    final f = t.feasibility;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ShortcutCard(
          icon: Icons.badge_outlined,
          label: f.openProfile,
          onTap: () => context.push('/trail/$trailId/hiker-profile'),
        ),
        _ShortcutCard(
          icon: Icons.directions_walk,
          label: f.openWalkTest,
          onTap: () => context.push('/trail/$trailId/walk-test'),
        ),
        _ShortcutCard(
          icon: Icons.history,
          label: f.openPastHikes,
          onTap: () => context.push('/trail/$trailId/past-hikes'),
        ),
      ],
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  const _ShortcutCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Text(label, style: theme.textTheme.titleSmall),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}

/// Vue de dépannage : pas de profil objectif exploitable -> questionnaire.
class _FallbackToQuestionnaire extends ConsumerWidget {
  const _FallbackToQuestionnaire({required this.reason});
  final String reason;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final f = t.feasibility;
    final trailId = ref.watch(trailConfigProvider).id;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(reason, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingLg),
          _ShortcutCard(
            icon: Icons.badge_outlined,
            label: f.openProfile,
            onTap: () => context.push('/trail/$trailId/hiker-profile'),
          ),
          _ShortcutCard(
            icon: Icons.directions_walk,
            label: f.openWalkTest,
            onTap: () => context.push('/trail/$trailId/walk-test'),
          ),
          _ShortcutCard(
            icon: Icons.history,
            label: f.openPastHikes,
            onTap: () => context.push('/trail/$trailId/past-hikes'),
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.quiz_outlined,
            label: f.sourceFallback,
            onPressed: () => context.push('/trail/$trailId/feasibility-quiz'),
          ),
        ],
      ),
    );
  }
}

Color _verdictColor(String verdict) {
  switch (verdict) {
    case TrekVerdict.danger:
      return AppTheme.rougeUrgence;
    case TrekVerdict.caution:
      return AppTheme.orangeDifficile;
    case TrekVerdict.go:
      return AppTheme.vertFacile;
    default:
      return AppTheme.grisGranite;
  }
}

IconData _verdictIcon(String verdict) {
  switch (verdict) {
    case TrekVerdict.danger:
      return Icons.dangerous;
    case TrekVerdict.caution:
      return Icons.warning;
    case TrekVerdict.go:
      return Icons.check_circle;
    default:
      return Icons.help;
  }
}
