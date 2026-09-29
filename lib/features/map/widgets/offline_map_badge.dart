import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/offline_map_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// Badge discret affichant le statut de la carte offline.
///
/// S'affiche en overlay sur la carte. Couleur selon le statut :
/// - Vert : carte offline disponible (offlineAvailable ou offlineOnly).
/// - Orange : en ligne uniquement, pas de tuiles locales.
/// - Rouge : hors-ligne sans tuiles locales, pas de carte.
class OfflineMapBadge extends ConsumerWidget {
  const OfflineMapBadge({super.key, required this.trailId});

  /// Identifiant du sentier pour lequel afficher le statut.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(offlineMapStatusProvider(trailId));

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) => _buildBadge(context, status),
    );
  }

  Widget _buildBadge(BuildContext context, OfflineMapStatus status) {
    final (icon, label, color) = _statusConfig(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepIcon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Configuration visuelle selon le statut.
  (String, String, Color) _statusConfig(OfflineMapStatus status) {
    switch (status) {
      case OfflineMapStatusValues.online:
        return (StepwaysIcons.horsLigne, 'En ligne', Colors.orange);
      case OfflineMapStatusValues.offlineAvailable:
        return (StepwaysIcons.synchronise, 'Offline OK', Colors.green);
      case OfflineMapStatusValues.offlineOnly:
        return (StepwaysIcons.horsLigne, 'Offline', Colors.green.shade700);
      case OfflineMapStatusValues.noMap:
        return (StepwaysIcons.horsLigne, 'Pas de carte', Colors.red);
      default:
        return (StepwaysIcons.aide, status, Colors.grey);
    }
  }
}
