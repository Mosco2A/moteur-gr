import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../providers/ads_providers.dart';

/// LE BOUTON « UN JOUR SANS PUBLICITE » (tache 614, demande de Christophe du
/// 28/09 11:41 : « un bouton 1 jour sans pub : regarder la video »).
///
/// CE QUI EXISTAIT, ET CE QUI MANQUAIT. Le moteur etait ENTIER : le service de
/// pub recompensee ([RewardedAdService]), l'octroi de 24 h en base
/// ([MonetizationService.grantRewardNoAds], avec son echeance), la lecture de
/// l'etat ([MonetizationService.isRewardNoAdsActive]) et l'identifiant d'unite
/// publicitaire. Une seule entree existait — au fond de la vitrine d'achat
/// ([PaywallSheet]) — c'est-a-dire a l'endroit ou l'on vient pour PAYER, pas a
/// l'endroit ou la publicite gene. Ce widget est l'entree, et il est UNIQUE :
/// la vitrine et la banniere posent le MEME bouton, il n'y en a pas deux.
///
/// LE LIBELLE DIT CE QU'ON OBTIENT, PAS CE QU'ON FAIT (arbitrage Christophe).
/// « Un jour sans publicite » d'abord, « regarder une video » ensuite : c'est
/// la contrepartie qui decide, pas le geste. `monetization.rewardedCta` porte
/// cet ordre dans les cinq langues.
///
/// IL NE S'AFFICHE PAS QUAND IL N'A RIEN A PROPOSER, et c'est structurel aux
/// deux endroits ou il vit :
///  * ICI, il s'efface si la publicite n'est meme pas disponible
///    ([adsReadyProvider] : SDK initialise + consentement UMP). Pas de bouton
///    mort qui declencherait une video inexistante.
///  * SUR LA BANNIERE ([BannerAdSlot]), il ne peut pas apparaitre quand le
///    sans-pub est deja actif : la banniere elle-meme n'existe alors pas
///    ([shouldShowBannerProvider] lit la source unique `isNoAdsActive`). Un
///    bouton qui propose ce qu'on a deja est un bouton qui ment ; ici il ne
///    peut pas mentir, parce qu'il vit sur la chose qu'il promet d'eteindre.
///
/// AUCUNE MECANIQUE NEUVE. Le clic passe par [watchRewardedForNoAdsProvider],
/// qui joue la video puis credite les 24 h par la SOURCE UNIQUE. Aucune regle
/// de publicite n'est recalculee ici, aucune garde n'est ajoutee : la regle de
/// Christophe du 27/09 14:41 (tout porte la pub sauf abonne et sauf trek
/// achete, plus la recompense de 24 h) reste exactement ou elle est.
class RewardedNoAdsButton extends ConsumerStatefulWidget {
  const RewardedNoAdsButton({this.compact = false, super.key});

  /// Rendu COMPACT pour la banniere : le bouton se pose au-dessus d'une
  /// publicite, en bas de l'ecran, la ou chaque pixel est deja pris. Il garde
  /// la hauteur de cible tactile minimale (44, plancher AA) et perd seulement
  /// sa marge haute. La vitrine, elle, garde le rendu plein.
  final bool compact;

  @override
  ConsumerState<RewardedNoAdsButton> createState() =>
      _RewardedNoAdsButtonState();
}

class _RewardedNoAdsButtonState extends ConsumerState<RewardedNoAdsButton> {
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
      padding: EdgeInsets.only(
        top: widget.compact ? 0 : AppTheme.spacingSm,
      ),
      child: AppButton(
        key: const Key('rewarded-no-ads-button'),
        variant: AppButtonVariant.outline,
        isLoading: _busy,
        minHeight: widget.compact ? 44 : 48,
        icon: Icons.ondemand_video_outlined,
        label: t.monetization.rewardedCta,
        onPressed: _busy ? null : _watch,
      ),
    );
  }
}
