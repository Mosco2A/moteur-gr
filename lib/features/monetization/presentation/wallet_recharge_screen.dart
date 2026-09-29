import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monetization_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/category_icon_colors.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/branding/stepways_icons.dart';

/// ECRAN DE RECHARGE DU COMPTE-ETAPES (tache 594, A3).
///
/// CE QUI MANQUAIT. La grille officielle du modele eco — 11 etapes = 9,99 EUR,
/// 25 = 19,99, 50 = 34,99 — etait ecrite AU CENTIME dans [kStepPacks] depuis
/// le LOT 1, et AFFICHEE NULLE PART (inventaire 593 §M1). Le seul prix qui
/// sortait a l'ecran etait celui d'UN trek, dans le paywall. Il n'existait
/// aucun chemin pour recharger : le portefeuille se vidait, rien ne le
/// remplissait.
///
/// CET ECRAN NE DECIDE RIEN. Il lit [kStepPacks] — la grille reste sa source
/// unique — et delegue l'achat a [MonetizationService.rechargeWallet]. Aucun
/// prix n'est recopie ici.
///
/// ET IL DIT SES REFUS. Tant que le paiement in-app n'est pas ouvert
/// (kill-switch `kWalletIapRealModeEnabled`), l'achat ne part pas : le bouton
/// le DIT au lieu de se taire. Un bouton qui ne produit rien est un mensonge
/// (regle du LOT X, tache 579).
class WalletRechargeScreen extends ConsumerWidget {
  const WalletRechargeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final accent = CategoryIconColors.of(context).green;
    final solde = ref.watch(walletStepsProvider).value;

    return Scaffold(
      appBar: AppHeader(title: t.monetization.rechargeTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            Text(
              t.monetization.rechargeSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            // RIEN PLUTOT QU'UN ZERO FAUX : meme prudence que la carte du
            // cockpit — pendant l'hydratation on n'annonce pas un compte vide.
            if (solde != null)
              AppCard(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Row(
                  children: [
                    StepIcon(StepwaysIcons.portefeuille, color: accent),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(
                        t.monetization.rechargeBalance,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                    Text(
                      '$solde',
                      key: const ValueKey('recharge-solde'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accent,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingXs),
                    Text(
                      t.monetization.walletUnit,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppTheme.spacingBase),
            for (final pack in kStepPacks) _PackTile(pack: pack),
          ],
        ),
      ),
    );
  }
}

/// Une ligne de la grille : N etapes, son prix, et un achat qui repond.
class _PackTile extends ConsumerStatefulWidget {
  const _PackTile({required this.pack});

  final StepPack pack;

  @override
  ConsumerState<_PackTile> createState() => _PackTileState();
}

class _PackTileState extends ConsumerState<_PackTile> {
  bool _occupe = false;

  Future<void> _acheter() async {
    if (_occupe) return;
    setState(() => _occupe = true);
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(monetizationServiceProvider);
    final initie = await service.rechargeWallet(widget.pack);
    if (!mounted) return;
    setState(() => _occupe = false);
    // L'ACHAT QUI NE PART PAS LE DIT. `rechargeWallet` renvoie false en mode
    // stub (kill-switch ferme) : sans ce message, l'appui n'aurait produit
    // rien du tout, ni credit ni explication.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          initie
              ? t.monetization.restoreRequested
              : t.monetization.storeUnavailable,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pack = widget.pack;
    return AppCard(
      key: ValueKey('pack-etapes-${pack.steps}'),
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: EdgeInsets.zero,
      child: InkWell(
        onTap: _occupe ? null : _acheter,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Row(
            children: [
              StepIcon(StepwaysIcons.plus, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Text(
                  t.monetization.packSteps(steps: pack.steps),
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                t.monetization.packPrice(
                  price: pack.priceEur.toStringAsFixed(2).replaceAll('.', ','),
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
