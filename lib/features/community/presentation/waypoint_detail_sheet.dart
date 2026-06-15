import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../data/waypoint_service.dart';
import '../domain/waypoint_type_config.dart';
import '../providers/waypoint_ui_providers.dart';
import 'waypoint_freshness.dart';

/// Feuille de DETAIL d'un waypoint communautaire (F8A-04).
///
/// Affiche : le titre + type, la FRAICHEUR (« maj il y a X », R3), les
/// COMMENTAIRES de condition (lus du CACHE offline, 'removed' masque cote DAO
/// DSA), et un bouton « Signaler » (notice-and-action DSA art. 16, lien design
/// Securite D4). Tout fonctionne OFFLINE (R3).
///
/// ZERO logique reseau dans le widget : lecture via [waypointCommentsProvider]
/// (cache), signalement delegue au callback [onReport].
class WaypointDetailSheet extends ConsumerWidget {
  const WaypointDetailSheet({
    super.key,
    required this.waypoint,
    this.onReport,
    this.now,
  });

  /// Le waypoint a detailler.
  final WaypointView waypoint;

  /// Callback du bouton « Signaler » (notice-and-action DSA). Si null, le bouton
  /// affiche un accuse de prise en compte par defaut.
  final void Function(WaypointView waypoint)? onReport;

  /// Horloge injectable (tests) pour la fraicheur.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final style = WaypointTypeConfig.getStyle(waypoint.type);
    final commentsAsync = ref.watch(waypointCommentsProvider(waypoint.id));
    final age = waypoint.freshness(now: now);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // En-tete : icone type + titre.
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: style.color,
                  child: Icon(style.icon, color: Colors.white),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Text(
                    waypoint.titre,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Fraicheur de la donnee (R3).
            Semantics(
              label: formatFreshness(t, age),
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppTheme.grisTexteSecondaire,
                  ),
                  const SizedBox(width: AppTheme.spacingXs),
                  Text(
                    formatFreshness(t, age),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              t.waypoints.detail.conditionsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Commentaires de condition (cache offline-first).
            commentsAsync.when(
              data: (comments) => comments.isEmpty
                  ? Text(
                      t.waypoints.detail.noComments,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: comments
                          .map((c) => _CommentTile(comment: c))
                          .toList(),
                    ),
              loading: () => const Padding(
                padding: EdgeInsets.all(AppTheme.spacingSm),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => Text(
                t.waypoints.detail.commentsError,
                style: theme.textTheme.bodySmall,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // Bouton « Signaler » (notice-and-action DSA art. 16, lien D4).
            Semantics(
              button: true,
              label: t.waypoints.detail.report,
              child: OutlinedButton.icon(
                key: const ValueKey('waypoint-report-button'),
                onPressed: () => _onReport(context, t),
                icon: const Icon(Icons.flag_outlined),
                label: Text(t.waypoints.detail.report),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onReport(BuildContext context, Translations t) {
    AppHaptics.medium();
    if (onReport != null) {
      onReport!(waypoint);
      return;
    }
    // Accuse de prise en compte par defaut (notice enregistree, moderation a
    // posteriori cote serveur — D4).
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.waypoints.detail.reportAck)),
    );
  }
}

/// Tuile d'un commentaire de condition (texte + condition + etat de sync).
class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final WaypointCommentView comment;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final condition = comment.condition;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            comment.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
            size: 16,
            color: comment.synced
                ? theme.colorScheme.primary
                : AppTheme.grisTexteSecondaire,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.texte, style: theme.textTheme.bodyMedium),
                if (condition != null && condition.isNotEmpty)
                  Text(
                    condition,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (!comment.synced)
                  Text(
                    t.waypoints.detail.pendingSync,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
