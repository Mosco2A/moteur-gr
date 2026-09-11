import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../../core/config/ad_config.dart';
import '../../../core/error/error_handler.dart';
import '../providers/ads_providers.dart';

/// Bannière publicitaire AdMob gated sans-pub (StepWays L6/A6).
///
/// Affiche une BANNIÈRE (format AUTORISÉ, avec la rewarded) UNIQUEMENT si
/// [shouldShowBannerProvider] est vrai pour [trailId] : trek non sans-pub
/// (source unique #99404) ET consentement pub obtenu (UMP). Sinon : rien
/// ([SizedBox.shrink]) — pas de réservation de hauteur, pas de pub sur le
/// terrain, jamais d'interstitiel. La bannière n'existe qu'en préparation
/// gratuite, conformément à la « frontière d'or ».
///
/// Le chargement natif est géré en interne (dispose propre). Aucune donnée
/// personnelle : la bannière repose sur le consentement UMP résolu en amont.
class AdBanner extends ConsumerWidget {
  const AdBanner({required this.trailId, super.key});

  /// Sentier courant — clé de la décision sans-pub (source unique).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(shouldShowBannerProvider(trailId));
    return show.maybeWhen(
      data: (visible) =>
          visible ? const _BannerLoader() : const SizedBox.shrink(),
      // En attente / erreur : rien (jamais d'espace pub vide ni de crash).
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Charge et affiche une [BannerAd] AdMob (cycle de vie interne).
class _BannerLoader extends StatefulWidget {
  const _BannerLoader();

  @override
  State<_BannerLoader> createState() => _BannerLoaderState();
}

class _BannerLoaderState extends State<_BannerLoader> {
  BannerAd? _banner;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final banner = BannerAd(
      size: AdSize.banner,
      adUnitId: AdConfig.bannerUnitId(),
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          ErrorHandler.log(
            StateError('banner load failed: ${error.message}'),
            context: 'AdBanner.load',
          );
          if (mounted) setState(() => _loaded = false);
        },
      ),
    );
    _banner = banner;
    banner.load();
  }

  @override
  void dispose() {
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (!_loaded || banner == null) return const SizedBox.shrink();
    return SizedBox(
      width: banner.size.width.toDouble(),
      height: banner.size.height.toDouble(),
      child: AdWidget(ad: banner),
    );
  }
}
