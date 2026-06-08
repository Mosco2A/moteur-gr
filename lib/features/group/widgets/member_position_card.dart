import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/group_member.dart';

/// Carte affichant la position d un membre du groupe.
/// Couleur de fraicheur : vert < 1h, orange < 3h, rouge > 3h.
class MemberPositionCard extends StatelessWidget {
  const MemberPositionCard({super.key, required this.member});
  final GroupMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final freshness = _computeFreshness(member.lastUpdate);
    return Card(child: Padding(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Row(children: [
        Container(width: 12, height: 12,
          decoration: BoxDecoration(shape: BoxShape.circle, color: freshness.color)),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(member.displayName ?? 'Randonneur anonyme', style: theme.textTheme.titleSmall),
          const SizedBox(height: AppTheme.spacingXs),
          Text(_formatCoordinates(member.lastLat, member.lastLng),
            style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.grisTexteSecondaire)),
          if (member.currentStageId != null) Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXs),
            child: Text('Etape: ${member.currentStageId}', style: theme.textTheme.bodySmall)),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Icon(Icons.access_time, size: 16, color: freshness.color),
          const SizedBox(height: AppTheme.spacingXs),
          Text(freshness.label, style: theme.textTheme.bodySmall?.copyWith(color: freshness.color)),
        ]),
      ]),
    ));
  }

  String _formatCoordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    return '${lat.abs().toStringAsFixed(4)}$latDir '
        '${lng.abs().toStringAsFixed(4)}$lngDir';
  }

  _Freshness _computeFreshness(String lastUpdate) {
    try {
      final lastTime = DateTime.parse(lastUpdate);
      final diff = DateTime.now().difference(lastTime);
      if (diff.inMinutes < 60) return _Freshness(color: AppTheme.vertFacile, label: '${diff.inMinutes}min');
      if (diff.inHours < 3) return _Freshness(color: AppTheme.orangeDifficile, label: '${diff.inHours}h');
      return _Freshness(color: AppTheme.rougeExtreme, label: '${diff.inHours}h');
    } catch (_) { return const _Freshness(color: AppTheme.grisGranite, label: '?'); }
  }
}

class _Freshness {
  const _Freshness({required this.color, required this.label});
  final Color color;
  final String label;
}
