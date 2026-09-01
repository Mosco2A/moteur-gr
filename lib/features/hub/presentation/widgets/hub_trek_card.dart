import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../trek/providers/tracking_providers.dart';

/// Carte principale du trek (RF-4 / #ET-1 / #ET-2) — 2 etats.
///
/// Etats (branches sur les providers StepWays REELS, #F04/#F05) :
///   * Trek en cours (statut `recording` ou `paused` de
///     [trekSessionManagerProvider]) : titre, stats projetees du jour
///     (distance parcourue, denivele, temps de marche), barre de progression
///     sur la distance totale du sentier, et CTA « Reprendre la navigation »
///     vers l'onglet Carte (#R08).
///   * Aucun trek actif : invite a planifier, CTA « Planifier mon trek » vers
///     le planning hors-shell (#R02, `/trail/:id/planning`).
///
/// D1 (arbitrage #94902) : le mode demo est MASQUE — AUCUN bandeau « trek demo
/// en cours » n'est rendu (RF-5 differe). La carte ne connait que le trek reel.
///
/// Les stats affichees proviennent directement de [TrackingSessionState]
/// (distance/denivele/duree temps reel). La progression est calculee vs la
/// distance totale du sentier ([TrailConfig.totalDistanceKm]).
class HubTrekCard extends ConsumerWidget {
  const HubTrekCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trekSessionManagerProvider);
    final isActive =
        tracking.status == TrackingSessionStatus.recording ||
        tracking.status == TrackingSessionStatus.paused;

    if (!isActive) {
      return const _NoTrekCard();
    }
    return _ActiveTrekCard(tracking: tracking);
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
          // Stats du jour (distance / denivele / temps).
          Row(
            children: [
              _Stat(
                label: t.hub.trekCard.distanceCovered,
                value: '${tracking.distanceKm.toStringAsFixed(1)} km',
              ),
              _Stat(
                label: t.hub.trekCard.elevationGain,
                value: '${tracking.elevationGainM.round()} m',
              ),
              _Stat(label: t.hub.trekCard.duration, value: durationText),
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

/// Etat « aucun trek » : invite a planifier.
class _NoTrekCard extends ConsumerWidget {
  const _NoTrekCard();

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
              Icon(Icons.map_outlined, color: scheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              // Flexible + ellipsis : le titre s'ajuste a la largeur (mobile
              // 360 px) au lieu de deborder la Row a droite (fix overflow).
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
          // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
          // largeur (SizedBox width infinity conserve). Libelle inchange.
          SizedBox(
            width: double.infinity,
            child: AppButton(
              icon: Icons.event_note_outlined,
              label: t.hub.trekCard.plan,
              onPressed: () => context.push('/trail/$trailId/planning'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cellule de statistique (valeur + libelle), repartie en largeur egale.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
