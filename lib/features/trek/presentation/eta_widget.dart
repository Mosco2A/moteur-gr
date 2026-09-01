import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../domain/eta_service.dart';
import '../providers/eta_providers.dart';

/// Widget d'affichage de l'ETA temps réel (F6B-02, F6.6).
///
/// Écoute [etaControllerProvider] dont l'estimation est recalculée UNIQUEMENT
/// sur événement (franchissement de waypoint, changement de segment, tick lent)
/// — JAMAIS à chaque frame ni à chaque position GPS (économie batterie, A1-4e).
/// Affiche le temps restant jusqu'au prochain point et jusqu'à la fin d'étape,
/// plus un indicateur de confiance (fiable / approx en zone GPS faible).
/// AUCUNE logique de calcul ici : tout est délégué à [EtaService] via le
/// contrôleur. Textes via Slang, accessibilité via [Semantics].
class EtaWidget extends ConsumerWidget {
  const EtaWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final estimate = ref.watch(etaControllerProvider);

    if (estimate == null) {
      // Pas encore d'estimation (aucun événement reçu).
      return const SizedBox.shrink();
    }

    final low = estimate.confidence == EtaConfidence.low;
    final confidenceLabel = low ? t.eta.confidenceLow : t.eta.confidenceHigh;

    return Semantics(
      label:
          '${t.eta.toNextWaypoint} ${_fmt(t, estimate.toNextWaypoint)}, '
          '${t.eta.toStageEnd} ${_fmt(t, estimate.toStageEnd)}, $confidenceLabel',
      // SW-SKIN-L3c : Card Material -> AppCard. Le Padding interne (spacingMd)
      // est porte par le parametre `padding` d'AppCard -> rendu identique.
      child: AppCard(
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(t.eta.title, style: theme.textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            _EtaRow(
              label: t.eta.toNextWaypoint,
              value: _fmt(t, estimate.toNextWaypoint),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            _EtaRow(
              label: t.eta.toStageEnd,
              value: _fmt(t, estimate.toStageEnd),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // Indicateur de confiance.
            Row(
              children: [
                Icon(
                  low ? Icons.gps_off : Icons.gps_fixed,
                  size: 14,
                  color: low
                      ? theme.colorScheme.error
                      : AppTheme.grisTexteSecondaire,
                ),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  confidenceLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: low
                        ? theme.colorScheme.error
                        : AppTheme.grisTexteSecondaire,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Formate une durée en `h min` via Slang (jamais de logique métier ici).
  String _fmt(Translations t, Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return t.eta.durationHm(h: h, m: m);
    return t.eta.durationM(m: m);
  }
}

/// Ligne label + valeur d'ETA.
class _EtaRow extends StatelessWidget {
  const _EtaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
