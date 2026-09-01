import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../i18n/translations.g.dart';
import '../providers/activity_feed_providers.dart';
import '../providers/kudos_providers.dart';

/// Ecran du fil d'activite (F7B-04, Phase 7 social).
///
/// Liste les activites LUES DEPUIS LE CACHE LOCAL (visibleActivities,
/// offline-first R2). Chaque carte affiche un PSEUDONYME (jamais nom reel,
/// #85383), un bouton "Encourager" (KudosService F7B-02) et un bouton
/// "Signaler" (notice-and-action DSA art. 16, design Securite D4 — ici le
/// bouton + le formulaire de motif ; l'envoi reel est porte par D4).
///
/// AUCUNE logique reseau/moderation dans le widget : tout est delegue aux
/// services/providers. a11y via [Semantics], Slang t.social.* (aucune cle
/// "anonyme", R1). [currentUserUidHash] = UID HACHE de l'utilisateur courant.
class ActivityFeedScreen extends ConsumerWidget {
  const ActivityFeedScreen({
    required this.currentUserUidHash,
    this.onReport,
    super.key,
  });

  /// UID HACHE de l'utilisateur courant (auteur des kudos qu'il pose).
  final String currentUserUidHash;

  /// Callback de signalement (notice-and-action DSA). L'envoi reel est porte
  /// par le design Securite D4 ; injecte ici pour la testabilite. Recoit
  /// l'id de l'activite signalee et le motif choisi.
  final void Function(String activityId, String reason)? onReport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final feedAsync = ref.watch(visibleActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(t.social.feedTitle)),
      body: SafeArea(
        child: feedAsync.when(
          data: (activities) {
            if (activities.isEmpty) {
              return _EmptyFeed(message: t.social.empty);
            }
            return ListView.separated(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              itemCount: activities.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppTheme.spacingMd),
              itemBuilder: (context, i) => _ActivityCard(
                activity: activities[i],
                currentUserUidHash: currentUserUidHash,
                onReport: () =>
                    _openReportSheet(context, ref, activities[i].id),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => _EmptyFeed(message: t.social.empty),
        ),
      ),
    );
  }

  /// Ouvre le formulaire notice-and-action DSA (motif + envoi).
  Future<void> _openReportSheet(
    BuildContext context,
    WidgetRef ref,
    String activityId,
  ) async {
    final t = Translations.of(context);
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportSheet(),
    );
    if (reason == null) return;
    onReport?.call(activityId, reason);
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.social.reportSent)));
  }
}

/// Carte d'une activite : pseudonyme, libelle, kudos, signaler, etat sync.
class _ActivityCard extends ConsumerWidget {
  const _ActivityCard({
    required this.activity,
    required this.currentUserUidHash,
    required this.onReport,
  });

  final ActivityFeedCacheData activity;
  final String currentUserUidHash;
  final VoidCallback onReport;

  /// Libelle PSEUDONYME derive de l'UID hache (jamais nom reel, jamais
  /// "anonyme", #85383).
  String get _pseudonym {
    final h = activity.authorUidHash;
    final short = h.length >= 8 ? h.substring(0, 8) : h;
    return 'rndr-$short';
  }

  String _activityLabel(Translations t) {
    switch (activity.type) {
      case 'badge':
        return t.social.activityBadge;
      case 'defi':
        return t.social.activityDefi;
      case 'segment_effort':
      default:
        return t.social.activitySegment;
    }
  }

  Future<void> _giveKudo(WidgetRef ref) async {
    final service = ref.read(kudosServiceProvider);
    await service.giveKudo(
      fromUidHash: currentUserUidHash,
      targetActivityId: activity.id,
    );
    ref.invalidate(kudosCountProvider(activity.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final kudosAsync = ref.watch(kudosCountProvider(activity.id));

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Entete : pseudonyme + libelle d'activite.
          Semantics(
            label: '$_pseudonym ${_activityLabel(t)}',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person_outline,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_pseudonym, style: theme.textTheme.titleSmall),
                      Text(
                        _activityLabel(t),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisTexteSecondaire,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Row(
            children: [
              // Bouton Encourager (kudos).
              Semantics(
                button: true,
                label: t.social.kudos,
                child: TextButton.icon(
                  key: ValueKey('kudos-${activity.id}'),
                  onPressed: () => _giveKudo(ref),
                  icon: const Icon(Icons.favorite_border, size: 18),
                  label: kudosAsync.when(
                    data: (n) => Text(t.social.kudosCount(n: n)),
                    loading: () => Text(t.social.kudos),
                    error: (_, __) => Text(t.social.kudos),
                  ),
                ),
              ),
              const Spacer(),
              // Bouton Signaler (notice-and-action DSA art. 16).
              Semantics(
                button: true,
                label: t.social.report,
                child: TextButton.icon(
                  key: ValueKey('report-${activity.id}'),
                  onPressed: onReport,
                  icon: const Icon(Icons.flag_outlined, size: 18),
                  label: Text(t.social.report),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulaire notice-and-action DSA : choix d'un motif + envoi.
class _ReportSheet extends StatefulWidget {
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String _reason = 'spam';

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.spacingBase,
        right: AppTheme.spacingBase,
        top: AppTheme.spacingBase,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.spacingBase,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.social.reportTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingMd),
          Text(t.social.reportReasonLabel, style: theme.textTheme.bodyMedium),
          RadioGroup<String>(
            groupValue: _reason,
            onChanged: (v) => setState(() => _reason = v ?? _reason),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<String>(
                  value: 'spam',
                  title: Text(t.social.reasonSpam),
                ),
                RadioListTile<String>(
                  value: 'abuse',
                  title: Text(t.social.reasonAbuse),
                ),
                RadioListTile<String>(
                  value: 'other',
                  title: Text(t.social.reasonOther),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // SW-SKIN-L3e : ElevatedButton -> AppButton primary, pleine largeur
          // (Column crossAxisAlignment.stretch). Semantics(button+label) gardee.
          Semantics(
            button: true,
            label: t.social.reportSend,
            child: AppButton(
              label: t.social.reportSend,
              onPressed: () => Navigator.of(context).pop(_reason),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etat vide du fil.
class _EmptyFeed extends StatelessWidget {
  const _EmptyFeed({required this.message});

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
              Icons.forum_outlined,
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
