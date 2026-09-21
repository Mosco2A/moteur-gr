import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/monetization_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/category_icon_colors.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';

/// Solde du COMPTE-ÉTAPES en tête du cockpit (correctif L7-1).
///
/// LE PORTEFEUILLE N'EST PAS CONSTRUIT ICI : la table Drift, le DAO, le
/// `WalletStore`, la recharge et le débit existaient déjà en entier. Ce qui
/// manquait était son AFFICHAGE — le randonneur dépensait des étapes pour
/// débloquer un sentier sans jamais voir ce qu'il lui en restait. Ce widget
/// est donc un branchement sur [walletStepsProvider], rien de plus.
///
/// RIEN TANT QUE LE SOLDE N'EST PAS CONNU : pendant l'hydratation (et en cas
/// d'erreur de chargement), la carte ne se rend pas du tout. Afficher « 0 »
/// en attendant reviendrait à annoncer un compte vide à quelqu'un qui a des
/// étapes — un chiffre faux est pire qu'un chiffre absent.
class HubWalletCard extends ConsumerWidget {
  const HubWalletCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final solde = ref.watch(walletStepsProvider).value;
    if (solde == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final accent = CategoryIconColors.of(context).green;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      child: Semantics(
        label: '${t.monetization.walletTitle} $solde ${t.monetization.walletUnit}',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, color: accent),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.monetization.walletTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    t.monetization.walletSubtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$solde',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
                Text(
                  t.monetization.walletUnit,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
