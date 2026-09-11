import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ads/providers/ads_providers.dart';
import '../../i18n/translations.g.dart';
import 'app_button.dart';

/// Ouvre l ecran paywall en bottom sheet (E4.17, StepWays LOT 1).
///
/// Propose le deblocage du trek [trailId] : liste des avantages (#81774) + prix
/// EUR indicatif (etapes x [kStepTierEur]) + CTA. L'achat passe par le
/// compte-etapes ([MonetizationService.buyTrail]) : wallet d'abord, complement
/// store. En mode stub IAP, aucun paiement reel n'est declenche.
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
    // Prix EUR indicatif : nombre d'etapes x tarif palier (kStepTierEur).
    final steps = monetization.stepPriceForTrail(totalStages: totalStages);
    final price = monetization.eurPriceForSteps(steps);

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
            // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary, pleine
            // largeur (theme = minimumSize infinie, le bouton remplissait deja
            // la Column du sheet). Le libelle bascule prix/CTA selon le nombre
            // d'etapes (iso). key preservee.
            AppButton(
              key: const Key('paywall-buy-button'),
              icon: Icons.lock_open,
              label: totalStages > 0
                  ? t.monetization.buyCtaWithPrice(
                      price: price.toStringAsFixed(2),
                    )
                  : t.monetization.buyCta,
              onPressed: () async {
                await ref
                    .read(monetizationServiceProvider)
                    .buyTrail(trailId, totalStages: totalStages);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            // StepWays L6/A6 : voie sans-pub 24 h par pub RECOMPENSEE (rewarded).
            // Affichee seulement si le consentement pub est obtenu (adsReady) —
            // formats autorises = banniere + rewarded, PAS d'interstitiel.
            const _RewardedNoAdsButton(),
          ],
        ),
      ),
    );
  }
}

/// CTA « Regarder une pub → sans pub 24 h » (rewarded, StepWays L6/A6).
///
/// Visible uniquement si la pub est disponible ([adsReadyProvider] : SDK
/// initialise + consentement UMP obtenu). Au tap : joue une pub RECOMPENSEE et,
/// si l'utilisateur la regarde jusqu'a la recompense, crédite le sans-pub 24 h
/// via la SOURCE UNIQUE ([MonetizationService.grantRewardNoAds], encapsulee dans
/// [watchRewardedForNoAdsProvider]). Aucun interstitiel.
class _RewardedNoAdsButton extends ConsumerStatefulWidget {
  const _RewardedNoAdsButton();

  @override
  ConsumerState<_RewardedNoAdsButton> createState() =>
      _RewardedNoAdsButtonState();
}

class _RewardedNoAdsButtonState extends ConsumerState<_RewardedNoAdsButton> {
  bool _busy = false;

  Future<void> _watch() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    final earnedMsg = t.monetization.rewardedEarned;
    final failMsg = t.monetization.rewardedUnavailable;
    // Provider autoDispose : refresh force une nouvelle lecture (nouvelle pub).
    final earned = await ref.refresh(watchRewardedForNoAdsProvider.future);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(content: Text(earned ? earnedMsg : failMsg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // N'affiche le CTA que si la pub est reellement disponible (consentement +
    // SDK). Sinon rien (pas de bouton mort).
    final adsReady = ref.watch(adsReadyProvider).value ?? false;
    if (!adsReady) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: AppButton(
        key: const Key('paywall-rewarded-button'),
        variant: AppButtonVariant.outline,
        isLoading: _busy,
        icon: Icons.ondemand_video_outlined,
        label: t.monetization.rewardedCta,
        onPressed: _busy ? null : _watch,
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
          const Icon(Icons.check_circle, size: 18, color: AppTheme.vertFacile),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
