import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_data_stat.dart';
import '../../../treks/domain/trek_lifecycle_state.dart';
import '../../../treks/presentation/widgets/active_trek_conflict_dialog.dart';
import '../../../treks/providers/my_treks_provider.dart';
import '../../../trek/providers/tracking_providers.dart';

/// Carte principale du trek (RF-4 / #ET-1 / #ET-2), enrichie du cycle de vie
/// multi-trek (StepWays LOT 2, Phase 5).
///
/// Reflete l'[TrekLifecycleState] DERIVE du sentier actif
/// ([currentTrailSummaryProvider]) — plus seulement l'etat en memoire du
/// tracking :
///   * inProgress (session `active`|`paused`) : carte « en cours » avec stats
///     temps reel du jour + CTA « Reprendre la navigation » (#R08) ;
///   * completed (finisher legitime) : carte de fin avec « Revoir »
///     (`/trail/:id/recap`) + « Diplôme » (`/trail/:id/diploma`) ;
///   * owned / prepared : CTA « Démarrer » qui passe par la GARDE d'unicite C4
///     ([TrekSessionManagerNotifier.ensureSingleActiveThenStart]) — un dialog
///     Terminer/Abandonner s'interpose si un AUTRE trek est deja en cours.
///
/// La bascule inProgress prend en compte L'ETAT VIVANT du tracking en priorite
/// (stats du jour disponibles) et RETOMBE sur l'etat derive (session persistee
/// non encore reprise en memoire, ex. apres redemarrage). D1 (arbitrage
/// #94902) : le mode demo reste masque — la carte ne connait que le trek reel.
class HubTrekCard extends ConsumerWidget {
  const HubTrekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trekSessionManagerProvider);
    final liveActive =
        tracking.status == TrackingSessionStatus.recording ||
        tracking.status == TrackingSessionStatus.paused;

    // Une session vivante prime : stats du jour disponibles -> carte active.
    if (liveActive) {
      return _ActiveTrekCard(tracking: tracking);
    }

    // Sinon on suit l'etat DERIVE du sentier actif (session persistee /
    // progression). Pendant le calcul ou en erreur, on retombe sur la carte
    // « aucun trek » (invite a demarrer) — jamais d'ecran casse.
    final summaryAsync = ref.watch(currentTrailSummaryProvider);
    final state = summaryAsync.asData?.value?.state;

    switch (state) {
      case TrekLifecycleState.inProgress:
        // Session persistee en cours mais tracking en memoire pas (encore)
        // repris : on montre la carte active avec l'etat courant (stats a 0
        // jusqu'a reprise de la navigation).
        return _ActiveTrekCard(tracking: tracking);
      case TrekLifecycleState.completed:
        return const _CompletedTrekCard();
      case TrekLifecycleState.owned:
      case TrekLifecycleState.prepared:
      case null:
        return const _StartTrekCard();
    }
  }
}

/// Etat « trek en cours » : stats du jour + progression + reprise navigation.
class _ActiveTrekCard extends ConsumerWidget {
  const _ActiveTrekCard({required this.tracking});

  final TrackingSessionState tracking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final totalKm = ref.watch(
      trailConfigProvider.select((c) => c.totalDistanceKm),
    );
    final progress = totalKm > 0
        ? (tracking.distanceKm / totalKm).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();

    final hours = tracking.elapsedDuration.inHours;
    final minutes = tracking.elapsedDuration.inMinutes.remainder(60);
    final durationText = hours > 0
        ? '${hours}h${minutes.toString().padLeft(2, '0')}'
        : '${minutes}min';

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_walk, color: scheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              // Flexible + ellipsis : le titre s'ajuste a la largeur (mobile
              // 360 px) au lieu de deborder la Row a droite (fix overflow).
              Expanded(
                child: Text(
                  t.hub.trekCard.activeTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Stats du jour (distance / denivele / temps) : gros chiffres data
          // via AppDataStat (SW-SKIN-L5), role data tabular L1. Chaque tuile est
          // `Expanded` (repartition en largeur egale, ex-`_Stat`), alignee a
          // gauche. Valeur formatee avec unite incluse -> iso-texte pour les
          // tests existants (find.text('12.5 km') / '640 m').
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.distanceCovered,
                  value: '${tracking.distanceKm.toStringAsFixed(1)} km',
                ),
              ),
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.elevationGain,
                  value: '${tracking.elevationGainM.round()} m',
                ),
              ),
              Expanded(
                child: AppDataStat(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  label: t.hub.trekCard.duration,
                  value: durationText,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Barre de progression sur la distance totale du sentier.
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.hub.trekCard.progressLabel(percent: percent),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
          // largeur (SizedBox width infinity conserve). Libelle inchange.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              icon: Icons.navigation_outlined,
              label: t.hub.trekCard.resume,
              onPressed: () => context.go('/map'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etat « owned / prepared » : invite a demarrer, via la GARDE d'unicite C4.
///
/// Remplace l'ancien `_NoTrekCard` : meme rendu (titre + invite + CTA pleine
/// largeur), mais le CTA « Démarrer » lance desormais
/// [TrekSessionManagerNotifier.ensureSingleActiveThenStart] — la garde C4
/// interpose un dialog Terminer/Abandonner si un AUTRE trek est deja en cours,
/// puis demarre. La planification reste atteignable par la carte « Programme »
/// de la section Preparer (inchangee).
class _StartTrekCard extends ConsumerStatefulWidget {
  const _StartTrekCard();

  @override
  ConsumerState<_StartTrekCard> createState() => _StartTrekCardState();
}

class _StartTrekCardState extends ConsumerState<_StartTrekCard> {
  bool _starting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: scheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.hub.trekCard.noTrekTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            t.hub.trekCard.noTrekBody,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // CTA « Démarrer » via la garde C4. Libelle Slang existant (startCta)
          // -> pas de nouvelle cle pour un CTA equivalent.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              icon: Icons.play_arrow,
              label: t.hub.startCta,
              isLoading: _starting,
              onPressed: _starting ? null : _startWithGuard,
            ),
          ),
        ],
      ),
    );
  }

  /// Demarre le sentier actif en passant par la garde d'unicite C4.
  ///
  /// La garde interroge la source d'unicite (sessions en cours cross-trail) et,
  /// si un AUTRE trek est en cours, delegue le choix a l'UI via le dialog
  /// [showActiveTrekConflictDialog] (Terminer/Abandonner/Annuler). Au succes,
  /// on bascule vers la carte (`/map`) pour naviguer.
  Future<void> _startWithGuard() async {
    final trailId = ref.read(trailConfigProvider).id;
    final notifier = ref.read(trekSessionManagerProvider.notifier);

    setState(() => _starting = true);
    try {
      final outcome = await notifier.ensureSingleActiveThenStart(
        trailId,
        resolve: (ongoingTrailId) =>
            showActiveTrekConflictDialog(context, ongoingTrailId),
      );
      if (!mounted) return;
      // Demarrage effectif -> on ouvre la navigation. Sur annulation ou meme
      // trek deja actif, on reste sur le HUB (la carte se re-derivera).
      if (outcome == StartOutcome.started) {
        context.go('/map');
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}

/// Etat « completed » (finisher legitime) : felicitations + acces Revoir /
/// Diplôme (StepWays LOT 2, Phase 5). Les deux routes existent deja (regle S8
/// « zero route morte ») ; la garde fine (recap/diplome) reste portee par les
/// ecrans cibles.
class _CompletedTrekCard extends ConsumerWidget {
  const _CompletedTrekCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));

    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.vertFacile),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.hub.trekCard.completedTitle,
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingBase),
          // Revoir « Mon aventure » (recap des stats de la session terminee).
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('completed-review'),
              icon: Icons.landscape_outlined,
              label: t.hub.cards.recap,
              onPressed: () => context.push('/trail/$trailId/recap'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Diplôme de fin de trek.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              key: const ValueKey('completed-diploma'),
              variant: AppButtonVariant.outline,
              icon: Icons.workspace_premium_outlined,
              label: t.hub.cards.diploma,
              onPressed: () => context.push('/trail/$trailId/diploma'),
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.hub.trekCard.progressLabel(percent: 100),
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
