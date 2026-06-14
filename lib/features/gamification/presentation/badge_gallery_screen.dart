import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/badge.dart';
import '../domain/badge_catalog.dart';
import '../domain/badge_engine.dart';
import '../providers/gamification_providers.dart';

/// Galerie de badges (F7C-03, Phase 7 gamification).
///
/// Affiche les badges OBTENUS vs VERROUILLES, avec leur condition d'obtention.
/// Le catalogue (libelles localises via Slang) est evalue LOCALEMENT par
/// [BadgeEngine] contre les stats de l'utilisateur (offline-first, R2). Le
/// widget NE FAIT AUCUNE evaluation : il rend le resultat du moteur. a11y via
/// [Semantics], Slang t.gamification.* (aucune cle "anonyme").
class BadgeGalleryScreen extends ConsumerWidget {
  const BadgeGalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final stats = ref.watch(userStatsProvider);
    final catalog = BadgeCatalog.build(t);
    final badges = const BadgeEngine().evaluateBadges(stats, catalog);

    return Scaffold(
      appBar: AppBar(title: Text(t.gamification.galleryTitle)),
      body: SafeArea(
        child: GridView.builder(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: AppTheme.spacingMd,
            crossAxisSpacing: AppTheme.spacingMd,
            childAspectRatio: 0.85,
          ),
          itemCount: badges.length,
          itemBuilder: (context, i) => _BadgeTile(badge: badges[i]),
        ),
      ),
    );
  }
}

/// Tuile d'un badge : icone, titre, etat (obtenu/verrouille), description.
class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge});

  final Badge badge;

  IconData get _icon {
    switch (badge.iconRef) {
      case 'hiking':
        return Icons.hiking;
      case 'timeline':
        return Icons.timeline;
      case 'terrain':
        return Icons.terrain;
      case 'military_tech':
        return Icons.military_tech;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'flag':
      default:
        return Icons.flag;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final obtained = badge.isObtained;
    final stateLabel =
        obtained ? t.gamification.obtained : t.gamification.locked;
    final tierLabel = badge.tier == BadgeTier.expert
        ? t.gamification.tierExpert
        : t.gamification.tierDebutant;

    return Semantics(
      label: '${badge.titre}, $tierLabel, $stateLabel',
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        decoration: BoxDecoration(
          color: obtained
              ? theme.colorScheme.primaryContainer.withAlpha(60)
              : theme.colorScheme.surfaceContainerHighest.withAlpha(40),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: obtained
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _icon,
                  size: 32,
                  color: obtained
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
                const Spacer(),
                Icon(
                  obtained ? Icons.check_circle : Icons.lock_outline,
                  size: 18,
                  color: obtained
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              badge.titre,
              style: theme.textTheme.titleSmall,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Expanded(
              child: Text(
                badge.description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Row(
              children: [
                Text(
                  tierLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  stateLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: obtained
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
