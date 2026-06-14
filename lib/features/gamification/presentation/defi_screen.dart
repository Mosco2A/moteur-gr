import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/defi_ranking.dart';
import '../domain/defi_saisonnier.dart';
import '../providers/gamification_providers.dart';

/// Ecran d'un defi saisonnier (F7C-03, Phase 7 gamification).
///
/// Affiche : le defi en cours, la PROGRESSION personnelle (calcul LOCAL,
/// offline-first R2), et le CLASSEMENT du defi PAR TRANCHE lu du serveur
/// (cache local, F7C-02) avec libelles PSEUDONYMES. Si une tranche compte
/// moins de [DefiRanking.kMin] participants, message de k-anonymat.
///
/// REGLE R1 : JAMAIS le mot "anonyme" (Slang t.gamification.defi.*, aucune cle
/// "anonyme"). a11y via [Semantics]. AUCUNE evaluation dans le widget (vient du
/// moteur/serveur).
class DefiScreen extends ConsumerWidget {
  const DefiScreen({required this.defi, super.key});

  final DefiSaisonnier defi;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final stats = ref.watch(userStatsProvider);
    final service = ref.watch(defiServiceProvider);
    final progress = service.localProgress(defi, stats);
    final rankingAsync = ref.watch(_defiRankingProvider(defi.id));

    return Scaffold(
      appBar: AppBar(title: Text(defi.titre)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            Text(defi.description, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: AppTheme.spacingMd),
            _ProgressCard(progress: progress),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.gamification.defi.rankingTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Semantics(
              label: t.gamification.defi.pseudonymNotice,
              child: _Notice(message: t.gamification.defi.pseudonymNotice),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            rankingAsync.when(
              data: (ranking) => _DefiRankingView(ranking: ranking),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => _Notice(message: t.gamification.defi.noDefi),
            ),
          ],
        ),
      ),
    );
  }
}

/// Classement du defi, indexe par defiId (lecture cache, R2).
final _defiRankingProvider =
    FutureProvider.family<DefiRanking?, String>((ref, defiId) {
  return ref.watch(defiServiceProvider).ranking(defiId);
});

/// Carte de progression personnelle (locale).
class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.progress});

  final DefiProgress progress;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      label: t.gamification.defi.progressLabel(
        current: progress.current.toStringAsFixed(0),
        target: progress.target.toStringAsFixed(0),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.gamification.defi.inProgress,
                style: theme.textTheme.labelMedium),
            const SizedBox(height: AppTheme.spacingSm),
            LinearProgressIndicator(value: progress.ratio),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.gamification.defi.progressLabel(
                current: progress.current.toStringAsFixed(0),
                target: progress.target.toStringAsFixed(0),
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Vue du classement du defi par tranche (pseudonyme, k-anonymat).
class _DefiRankingView extends StatelessWidget {
  const _DefiRankingView({required this.ranking});

  final DefiRanking? ranking;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = ranking;
    if (r == null || r.isEmpty) {
      return _Notice(message: t.gamification.defi.noDefi);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final tranche in r.tranches) ...[
          if (!tranche.published)
            Semantics(
              label: t.gamification.defi.notEnoughParticipants,
              child: _Notice(
                message: t.gamification.defi.notEnoughParticipants,
              ),
            )
          else
            ...tranche.entries.map(
              (e) => _DefiEntryRow(entry: e),
            ),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ],
    );
  }
}

/// Une ligne de classement de defi : rang, pseudonyme, score.
class _DefiEntryRow extends StatelessWidget {
  const _DefiEntryRow({required this.entry});

  final DefiRankingEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '${entry.rank} ${entry.pseudonym} ${entry.value.toStringAsFixed(0)}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '${entry.rank}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(entry.pseudonym,
                  style: theme.textTheme.bodyLarge,
                  overflow: TextOverflow.ellipsis),
            ),
            Text(entry.value.toStringAsFixed(0),
                style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Bandeau d'information neutre (notice pseudonyme, k-anonymat, etat vide).
class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(50),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              size: 18, color: theme.colorScheme.onSecondaryContainer),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
