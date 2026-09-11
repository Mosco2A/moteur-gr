import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../domain/walk_test_result.dart';
import '../providers/walk_test_provider.dart';

/// Ecran du test de marche 6 minutes (StepWays LOT 4, Ph2).
///
/// Mode chrono LIBRE : compte a rebours, distance live via GPS, arret auto a
/// 6:00, resultat date + niveau objectif, rappel mensuel. Tous les textes via
/// Slang (`t.walkTest.*`) — zero texte en dur.
class WalkTestScreen extends ConsumerWidget {
  const WalkTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(walkTestControllerProvider);
    final wt = t.walkTest;

    Widget body;
    switch (state.phase) {
      case WalkTestPhase.idle:
        body = const _IdleView();
        break;
      case WalkTestPhase.countdown:
        body = _CountdownView(seconds: state.countdownRemaining.inSeconds);
        break;
      case WalkTestPhase.running:
        body = _RunningView(
          remaining: state.remaining,
          distanceMeters: state.distanceMeters,
        );
        break;
      case WalkTestPhase.done:
        body = _ResultView(result: state.result!);
        break;
      case WalkTestPhase.gpsDenied:
        body = const _GpsDeniedView();
        break;
    }

    return Scaffold(
      appBar: AppHeader(title: wt.title),
      body: SafeArea(child: body),
    );
  }
}

/// Formate mm:ss.
String _fmt(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _IdleView extends ConsumerWidget {
  const _IdleView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final wt = t.walkTest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.directions_walk, size: 64, color: colors.primary),
          const SizedBox(height: AppTheme.spacingBase),
          Text(wt.intro, style: theme.textTheme.bodyLarge),
          const SizedBox(height: AppTheme.spacingLg),
          // Rappel securite cardiaque (bandeau attention).
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(30),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(90)),
            ),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppTheme.orangeDifficile),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    wt.safetyWarning,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          AppButton(
            minHeight: 52,
            icon: Icons.play_arrow,
            label: wt.start,
            onPressed: () =>
                ref.read(walkTestControllerProvider.notifier).start(
                      reminderTitle: wt.title,
                      reminderBody: wt.monthlyReminderBody,
                    ),
          ),
        ],
      ),
    );
  }
}

class _CountdownView extends StatelessWidget {
  const _CountdownView({required this.seconds});
  final int seconds;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(t.walkTest.countdown, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingLg),
          Text(
            '$seconds',
            style: theme.textTheme.displayLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunningView extends ConsumerWidget {
  const _RunningView({required this.remaining, required this.distanceMeters});
  final Duration remaining;
  final double distanceMeters;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final wt = t.walkTest;
    final progress =
        1.0 - (remaining.inSeconds / (6 * 60)).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(wt.timeLeft, style: theme.textTheme.labelLarge),
          const SizedBox(height: AppTheme.spacingSm),
          SizedBox(
            width: 200,
            height: 200,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 14,
                  backgroundColor: colors.onSurface.withAlpha(25),
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
                Center(
                  child: Text(
                    _fmt(remaining),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          Text(wt.liveDistance, style: theme.textTheme.labelLarge),
          Text(
            '${distanceMeters.round()} ${wt.meters}',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.stop,
            label: wt.cancel,
            onPressed: () =>
                ref.read(walkTestControllerProvider.notifier).cancel(),
          ),
        ],
      ),
    );
  }
}

class _ResultView extends ConsumerWidget {
  const _ResultView({required this.result});
  final WalkTestResult result;

  String _resolveLevel(String level) {
    final resolved = t['walkTest.levels.$level'];
    return resolved is String ? resolved : level;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final wt = t.walkTest;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.emoji_events, size: 56, color: colors.primary),
          const SizedBox(height: AppTheme.spacingBase),
          Text(
            wt.resultTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: AppTheme.spacingLg),
          AppCard(
            child: Column(
              children: [
                _ResultRow(
                  label: wt.resultDistance,
                  value: '${result.distanceMeters.round()} ${wt.meters}',
                ),
                const Divider(),
                _ResultRow(
                  label: wt.resultLevel,
                  value: _resolveLevel(result.level),
                  emphasize: true,
                ),
                const Divider(),
                _ResultRow(
                  label: '',
                  value: wt.resultDate(date: _formatDate(result.takenAt)),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Info rappel mensuel (planifie a la fin du test).
          Row(
            children: [
              Icon(Icons.event_repeat, size: 18, color: colors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  wt.monthlyReminderBody,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXl),
          AppButton(
            variant: AppButtonVariant.outline,
            icon: Icons.refresh,
            label: wt.doneAgain,
            onPressed: () =>
                ref.read(walkTestControllerProvider.notifier).reset(),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });
  final String label;
  final String value;
  final bool emphasize;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: emphasize
                ? theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _GpsDeniedView extends ConsumerWidget {
  const _GpsDeniedView();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final wt = t.walkTest;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.location_off,
                size: 56, color: theme.colorScheme.error),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              wt.gpsDenied,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            AppButton(
              variant: AppButtonVariant.outline,
              icon: Icons.arrow_back,
              label: wt.cancel,
              onPressed: () =>
                  ref.read(walkTestControllerProvider.notifier).reset(),
            ),
          ],
        ),
      ),
    );
  }
}
