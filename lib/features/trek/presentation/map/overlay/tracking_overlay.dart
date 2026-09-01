import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../../i18n/translations.g.dart';
import '../../../../../shared/widgets/app_button.dart';
import '../../../../map/providers/track_position_provider.dart';
import '../../../providers/tracking_providers.dart';

/// Overlay de tracking temps reel affiche sur la carte.
///
/// Affiche 4 stats (distance, temps, D+, vitesse) et 3 boutons
/// (start vert, pause orange, stop rouge).
/// Utilise Consumer + select() pour ne rebuilder que le champ change.
class TrackingOverlay extends StatelessWidget {
  const TrackingOverlay({super.key, required this.trailId});

  /// Identifiant du sentier en cours de tracking.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withAlpha(230),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(80),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const _StatsRow(key: Key('tracking_stats_row')),
          const SizedBox(height: AppTheme.spacingSm),
          _ButtonsRow(key: const Key('tracking_buttons_row'), trailId: trailId),
        ],
      ),
    );
  }
}

/// Ligne des 4 statistiques avec Consumer + select() par champ.
///
/// Chaque stat est dans un Consumer separe pour ne rebuilder
/// que la tuile dont la valeur change.
class _StatsRow extends StatelessWidget {
  const _StatsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final status = ref.watch(
          trekSessionManagerProvider.select((s) => s.status),
        );

        // Ne rien afficher si pas en recording/paused
        if (status != TrackingSessionStatus.recording &&
            status != TrackingSessionStatus.paused) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Distance parcourue = source PROJETEE sur le trace
              // (correctif build 117 : un aller-retour ne gonfle plus la
              // valeur ; meme provider que la barre de progression, le HUB
              // et l'accueil). JAMAIS le cumul GPS brut (distanceKm).
              Consumer(
                builder: (context, ref, _) {
                  final coveredM = ref.watch(stageDistanceCoveredProvider);
                  return _StatTile(
                    icon: Icons.straighten,
                    value: _formatDistance(coveredM / 1000),
                    label: t.tracking.distance,
                  );
                },
              ),
              // Temps
              Consumer(
                builder: (context, ref, _) {
                  final duration = ref.watch(
                    trekSessionManagerProvider.select((s) => s.elapsedDuration),
                  );
                  return _StatTile(
                    icon: Icons.timer_outlined,
                    value: _formatDuration(duration),
                    label: t.tracking.time,
                  );
                },
              ),
              // D+
              Consumer(
                builder: (context, ref, _) {
                  final elevGain = ref.watch(
                    trekSessionManagerProvider.select((s) => s.elevationGainM),
                  );
                  return _StatTile(
                    icon: Icons.trending_up,
                    value: '${elevGain.round()} m',
                    label: t.tracking.dPlus,
                  );
                },
              ),
              // Vitesse
              Consumer(
                builder: (context, ref, _) {
                  final speed = ref.watch(
                    trekSessionManagerProvider.select((s) => s.currentSpeedKmh),
                  );
                  return _StatTile(
                    icon: Icons.speed,
                    value: '${speed.toStringAsFixed(1)} km/h',
                    label: t.tracking.speed,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDistance(double km) {
    return '${km.toStringAsFixed(1)} km';
  }

  String _formatDuration(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    final s = duration.inSeconds.remainder(60);
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
}

/// Ligne des boutons start/pause/stop.
///
/// Adapte les boutons affiches selon le statut de la session.
class _ButtonsRow extends StatelessWidget {
  const _ButtonsRow({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final status = ref.watch(
          trekSessionManagerProvider.select((s) => s.status),
        );
        final notifier = ref.read(trekSessionManagerProvider.notifier);

        switch (status) {
          case TrackingSessionStatus.idle:
          case TrackingSessionStatus.stopped:
            return _ActionButton(
              label: t.tracking.start,
              icon: Icons.play_arrow,
              color: AppTheme.actionStart,
              semanticLabel: t.a11y.startTracking,
              onPressed: () => notifier.start(trailId),
            );
          case TrackingSessionStatus.recording:
            return Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: t.tracking.pause,
                    icon: Icons.pause,
                    color: AppTheme.actionPause,
                    semanticLabel: t.a11y.pauseTracking,
                    onPressed: notifier.pause,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _ActionButton(
                    label: t.tracking.stopButton,
                    icon: Icons.stop,
                    color: AppTheme.rougeUrgence,
                    semanticLabel: t.a11y.stopTracking,
                    onPressed: () => _confirmStop(context, notifier),
                  ),
                ),
              ],
            );
          case TrackingSessionStatus.paused:
            return Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: t.tracking.resume,
                    icon: Icons.play_arrow,
                    color: AppTheme.actionStart,
                    semanticLabel: t.a11y.resumeTracking,
                    onPressed: notifier.resume,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: _ActionButton(
                    label: t.tracking.stopButton,
                    icon: Icons.stop,
                    color: AppTheme.rougeUrgence,
                    semanticLabel: t.a11y.stopTracking,
                    onPressed: () => _confirmStop(context, notifier),
                  ),
                ),
              ],
            );
        }
      },
    );
  }

  void _confirmStop(BuildContext context, TrekSessionManagerNotifier notifier) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.tracking.confirmStop),
        content: Text(t.tracking.stopSaveProgress),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.tracking.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              notifier.stop();
            },
            child: Text(t.tracking.stop),
          ),
        ],
      ),
    );
  }
}

/// Tuile d'une statistique individuelle.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label : $value',
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.labelLarge),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bouton d'action (start/pause/stop/reprendre).
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.semanticLabel,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  /// Label d'accessibilite (Slang) decrivant l'action ; remplace le libelle
  /// visuel pour les lecteurs d'ecran. Null -> on lit le libelle visible.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // AppButton variante filledTone : meme rendu qu'un ElevatedButton.icon a
    // fond semantique (backgroundColor=color, texte/icone blancs, hauteur 44,
    // rayon radiusButton) — SW-SKIN-L3c unifie la grammaire du bouton sans
    // changer le visuel de ce HUD actif. Le Semantics(button, excludeSemantics)
    // externe est conserve : c'est lui qui porte le label a11y d'action.
    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: true,
      child: AppButton(
        label: label,
        icon: icon,
        onPressed: onPressed,
        variant: AppButtonVariant.filledTone,
        tone: color,
        isFullWidth: false,
        minHeight: 44,
      ),
    );
  }
}
