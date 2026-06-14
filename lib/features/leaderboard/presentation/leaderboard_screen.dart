import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/segment_ranking.dart';
import '../providers/leaderboard_providers.dart';

/// Ecran leaderboard "Roi de l etape" PAR TRANCHE (F7A-04, Phase 7).
///
/// Affiche le classement d'un segment, LU depuis le cache local du document
/// calcule COTE SERVEUR (F7A-03) — lecture offline-first (R2). Le widget NE
/// CALCULE RIEN : il rend les tranches publiees et, pour les tranches sous le
/// seuil de k-anonymat, un message d'indisponibilite.
///
/// REGLE R1 : libelles PSEUDONYMES, JAMAIS le mot "anonyme" (textes via Slang
/// t.leaderboard.*, dont aucune cle ne contient "anonyme"). a11y via
/// [Semantics] (dette E5.3).
class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({
    required this.segmentId,
    this.segmentName,
    super.key,
  });

  /// Identifiant du segment dont on affiche le classement.
  final String segmentId;

  /// Nom lisible du segment (optionnel, pour le titre).
  final String? segmentName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final rankingAsync = ref.watch(segmentRankingProvider(segmentId));

    return Scaffold(
      appBar: AppBar(
        title: Text(segmentName ?? t.leaderboard.title),
      ),
      body: SafeArea(
        child: rankingAsync.when(
          data: (ranking) => _RankingBody(ranking: ranking),
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (_, __) => _EmptyState(message: t.leaderboard.unavailable),
        ),
      ),
    );
  }
}

/// Corps de l'ecran : entete pseudonyme + liste des tranches.
class _RankingBody extends StatelessWidget {
  const _RankingBody({required this.ranking});

  final SegmentRanking? ranking;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final r = ranking;
    if (r == null || r.isEmpty) {
      return _EmptyState(message: t.leaderboard.empty);
    }

    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      children: [
        // Rappel transparence : classement PAR TRANCHE, libelles pseudonymes.
        Semantics(
          label: t.leaderboard.pseudonymNotice,
          child: _PseudonymBanner(message: t.leaderboard.pseudonymNotice),
        ),
        const SizedBox(height: AppTheme.spacingMd),
        for (final tranche in r.tranches) ...[
          _TrancheSection(tranche: tranche),
          const SizedBox(height: AppTheme.spacingLg),
        ],
      ],
    );
  }
}

/// Section d'une tranche : titre + entrees publiees OU message k-anonymat.
class _TrancheSection extends StatelessWidget {
  const _TrancheSection({required this.tranche});

  final RankingTranche tranche;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.leaderboard.trancheLabel(tranche: tranche.tranche),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (!tranche.published)
          // k-anonymat : pas assez de participants pour publier ce classement.
          Semantics(
            label: t.leaderboard.notEnoughParticipants,
            child: _InfoCard(
              icon: Icons.groups_outlined,
              message: t.leaderboard.notEnoughParticipants,
            ),
          )
        else
          ...tranche.entries.map((e) => _EntryRow(entry: e)),
      ],
    );
  }
}

/// Une ligne de classement : rang, pseudonyme, temps.
class _EntryRow extends StatelessWidget {
  const _EntryRow({required this.entry});

  final RankingEntry entry;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    final ss = s.toString().padLeft(2, '0');
    return '$m:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final time = _formatDuration(entry.durationSeconds);

    return Semantics(
      label: t.leaderboard.entrySemantics(
        rank: entry.rank,
        pseudonym: entry.pseudonym,
        time: time,
      ),
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
              child: Text(
                entry.pseudonym,
                style: theme.textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(time, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Bandeau de transparence sur la nature pseudonyme du classement.
class _PseudonymBanner extends StatelessWidget {
  const _PseudonymBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(
            Icons.shield_outlined,
            size: 20,
            color: theme.colorScheme.onSecondaryContainer,
          ),
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

/// Carte d'information (k-anonymat, etat vide).
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(message, style: theme.textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

/// Etat vide / indisponible (jamais joue, ou cache vide hors-ligne).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.emoji_events_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              message,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
