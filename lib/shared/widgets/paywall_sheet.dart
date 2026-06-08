import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';

/// Ouvre l ecran paywall en bottom sheet (E4.17).
///
/// Propose le deblocage premium du trek [trailId] :
/// liste des avantages (#81774) + prix (1 EUR x etapes) + CTA.
/// L achat est un STUB (MonetizationService.purchaseTrail) —
/// aucun paiement reel n est declenche.
Future<void> showPaywallSheet(
  BuildContext context, {
  required String trailId,
  required int totalStages,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PaywallSheet(trailId: trailId, totalStages: totalStages),
  );
}

/// Contenu de l ecran paywall (E4.17, #81774).
///
/// Gratuit = preparation avec pub + demo. Premium a la carte =
/// trek complet sans pub. Textes via Slang (t.monetization.*).
class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({
    super.key,
    required this.trailId,
    required this.totalStages,
  });

  /// Trek a debloquer.
  final String trailId;

  /// Nombre d etapes (prix = etapes x 1 EUR, #81774).
  final int totalStages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monetization = ref.watch(monetizationServiceProvider);
    final price = monetization.priceForTrail(totalStages: totalStages);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingXl,
          AppTheme.spacingSm,
          AppTheme.spacingXl,
          AppTheme.spacingXl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              Icons.workspace_premium,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              t.monetization.paywallTitle,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.monetization.paywallBody,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            _FeatureLine(label: t.monetization.featureMap),
            _FeatureLine(label: t.monetization.featureJournal),
            _FeatureLine(label: t.monetization.featureDiploma),
            _FeatureLine(label: t.monetization.featureFollowers),
            _FeatureLine(label: t.monetization.featureNoAds),
            const SizedBox(height: AppTheme.spacingBase),
            ElevatedButton.icon(
              key: const Key('paywall-buy-button'),
              onPressed: () async {
                await ref
                    .read(monetizationServiceProvider)
                    .purchaseTrail(trailId);
                if (context.mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.lock_open),
              label: Text(
                totalStages > 0
                    ? t.monetization.buyCtaWithPrice(
                        price: price.toStringAsFixed(0),
                      )
                    : t.monetization.buyCta,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne d avantage premium avec coche.
class _FeatureLine extends StatelessWidget {
  const _FeatureLine({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          const Icon(Icons.check_circle,
              size: 18, color: AppTheme.vertFacile),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
