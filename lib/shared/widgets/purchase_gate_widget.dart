import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';
import 'paywall_sheet.dart';

/// Widget gate qui encapsule un ecran et verifie l'achat du trek (E4.17).
///
/// Si le trek n'a pas ete achete, affiche un bandeau mode demo
/// en haut de l'ecran (#81774 : gratuit = demo + pub). Le tap sur
/// le bandeau ouvre l ecran paywall ([PaywallSheet]) qui propose
/// le deblocage premium du trek (achat stub, aucun paiement reel).
///
/// isDemoMode est PAR TREK, pas par user (#81805 V7) :
/// un trek achete ne debloque que ce sentier.
///
/// Utilisation :
/// ```dart
/// PurchaseGateWidget(
///   trailId: trailConfig.id,
///   totalStages: trailConfig.totalStages,
///   child: MonEcranComplet(),
/// )
/// ```
class PurchaseGateWidget extends ConsumerWidget {
  const PurchaseGateWidget({
    super.key,
    required this.trailId,
    required this.child,
    this.totalStages = 0,
    this.demoBannerText,
    this.onPurchaseTap,
  });

  /// Identifiant du trek a verifier.
  final String trailId;

  /// Contenu de l'ecran encapsule.
  final Widget child;

  /// Nombre d etapes du trek (calcul du prix paywall, #81774).
  final int totalStages;

  /// Texte personnalise du bandeau demo (defaut: t.monetization.demoBanner).
  final String? demoBannerText;

  /// Callback quand l'utilisateur tape le bandeau d'achat.
  /// Si null, ouvre le [PaywallSheet] par defaut.
  final VoidCallback? onPurchaseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monetization = ref.watch(monetizationServiceProvider);
    final isDemo = monetization.isDemoMode(trailId);

    if (!isDemo) {
      // Trek achete : affichage normal, pas de gate.
      return child;
    }

    // Mode demo : bandeau + contenu
    return Column(
      children: [
        _DemoBanner(
          text: demoBannerText ?? t.monetization.demoBanner,
          onTap: onPurchaseTap ?? () => _openPaywall(context),
        ),
        Expanded(child: child),
      ],
    );
  }

  /// Ouvre l ecran paywall (deblocage premium du trek).
  void _openPaywall(BuildContext context) {
    showPaywallSheet(
      context,
      trailId: trailId,
      totalStages: totalStages,
    );
  }

  /// Verifie si un trek est en mode demo (statique, sans widget).
  ///
  /// Raccourci pour verifier depuis du code non-widget.
  /// PAR TREK, pas par user (#81805 V7).
  static bool isDemoMode(MonetizationService service, String trailId) {
    return service.isDemoMode(trailId);
  }
}

/// Bandeau affiche en mode demo.
///
/// Fond orange, texte blanc, tap = ouverture paywall.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.orangeDifficile,
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: Colors.white, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 14),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: banner);
    }
    return banner;
  }
}
