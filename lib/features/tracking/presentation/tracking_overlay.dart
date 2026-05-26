import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../models/tracking_status.dart';
import '../providers/tracking_provider.dart';

/// Overlay de tracking affiche en bas de la carte.
class TrackingOverlay extends ConsumerWidget {
  const TrackingOverlay({super.key, required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tracking = ref.watch(trackingProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withAlpha(230),
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
          if (tracking.status == TrackingStatus.recording ||
              tracking.status == TrackingStatus.paused)
            _buildStats(context, tracking),
          const SizedBox(height: AppTheme.spacingSm),
          _buildButtons(context, ref, tracking),
        ],
      ),
    );
  }

  Widget _buildStats(BuildContext context, TrackingState tracking) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            icon: Icons.timer_outlined,
            value: _formatDuration(tracking.durationSec),
            label: 'Temps',
          ),
          _StatTile(
            icon: Icons.straighten,
            value: _formatDistance(tracking.distanceM),
            label: 'Distance',
          ),
          _StatTile(
            icon: Icons.trending_up,
            value: '${tracking.elevationGainM} m',
            label: 'D+',
          ),
          _StatTile(
            icon: Icons.speed,
            value: '${tracking.speedKmh.toStringAsFixed(1)} km/h',
            label: 'Vitesse',
          ),
        ],
      ),
    );
  }

  Widget _buildButtons(
    BuildContext context,
    WidgetRef ref,
    TrackingState tracking,
  ) {
    final notifier = ref.read(trackingProvider.notifier);

    switch (tracking.status) {
      case TrackingStatus.idle:
      case TrackingStatus.stopped:
        return _ActionButton(
          label: 'Demarrer',
          icon: Icons.play_arrow,
          color: Colors.green,
          onPressed: () => notifier.start(trailId),
        );
      case TrackingStatus.recording:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Pause',
                icon: Icons.pause,
                color: Colors.orange,
                onPressed: notifier.pause,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _ActionButton(
                label: 'Stop',
                icon: Icons.stop,
                color: AppTheme.rougeUrgence,
                onPressed: () => _confirmStop(context, notifier),
              ),
            ),
          ],
        );
      case TrackingStatus.paused:
        return Row(
          children: [
            Expanded(
              child: _ActionButton(
                label: 'Reprendre',
                icon: Icons.play_arrow,
                color: Colors.green,
                onPressed: notifier.resume,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _ActionButton(
                label: 'Stop',
                icon: Icons.stop,
                color: AppTheme.rougeUrgence,
                onPressed: () => _confirmStop(context, notifier),
              ),
            ),
          ],
        );
    }
  }

  void _confirmStop(BuildContext context, TrackingNotifier notifier) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Arreter le tracking ?'),
        content: const Text('La progression sera sauvegardee.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              notifier.stop();
            },
            child: const Text('Arreter'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  String _formatDistance(double meters) {
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }
}

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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(height: 2),
        Text(value, style: theme.textTheme.labelLarge),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisGranite,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
        ),
      ),
    );
  }
}
