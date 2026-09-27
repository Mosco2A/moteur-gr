import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/monetization_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';

/// ECRAN D'ABONNEMENT SANS PUBLICITE + RESTAURATION DES ACHATS (tache 594, A3).
///
/// CE QUI MANQUAIT. L'abo light est l'un des TROIS niveaux du modele eco, et
/// il n'avait aucun ecran : `subscribe()` existait dans le service, personne ne
/// l'appelait. Il n'existait pas davantage de bouton « Restaurer mes achats »,
/// alors que les deux boutiques l'EXIGENT pour publier.
///
/// CET ECRAN DIT AUSSI CE QUE L'ABO NE DONNE PAS. C'est le point qui a ete
/// contredit par le code pendant tout ce temps : l'arbitrage du 08/09, qui
/// prime sur #99405, dit que l'abonne « NE debloque PAS les outils complets ni
/// la realisation ». Un ecran qui vendrait l'abo sans l'ecrire vendrait autre
/// chose que ce qui a ete decide.
///
/// LA CAGNOTTE EST ANNONCEE, SON MONTANT NE L'EST PAS : il n'est chiffre ni
/// dans le modele ni dans le code ([kSubscriberStepsAllowance] vaut `null`).
/// L'ecran le dit au lieu d'inventer un nombre.
class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  bool _occupe = false;

  Future<void> _souscrire() async {
    if (_occupe) return;
    setState(() => _occupe = true);
    final messenger = ScaffoldMessenger.of(context);
    final initie = await ref.read(monetizationServiceProvider).subscribe();
    if (!mounted) return;
    setState(() => _occupe = false);
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

  Future<void> _restaurer() async {
    if (_occupe) return;
    setState(() => _occupe = true);
    final messenger = ScaffoldMessenger.of(context);
    final issue = await ref.read(monetizationServiceProvider).restorePurchases();
    if (!mounted) return;
    setState(() => _occupe = false);
    // LE BOUTON REPOND TOUJOURS. `restorePurchases` etait un `Future<void>`
    // qui ne faisait rien en mode stub : l'appui n'avait aucune consequence
    // visible. Il rend desormais un resultat type, et on le NOMME.
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          switch (issue.status) {
            PurchaseRestoreStatus.requested =>
              t.monetization.restoreRequested,
            PurchaseRestoreStatus.storeUnavailable =>
              t.monetization.restoreUnavailable,
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final service = ref.watch(monetizationServiceProvider);

    return Scaffold(
      appBar: AppHeader(title: t.monetization.subscriptionTitle),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          children: [
            // Le titre est porte par l'en-tete : le repeter ici ferait deux
            // fois la meme phrase a l'ecran.
            Text(
              t.monetization.subscriptionSubtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),

            // --- Etat courant : actif jusqu'a QUAND, ou inactif -------------
            FutureBuilder<DateTime?>(
              future: service.subscriptionExpiresAt(),
              builder: (context, snap) {
                final echeance = snap.data;
                final actif = echeance != null;
                return AppCard(
                  key: const ValueKey('abo-etat'),
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  child: Row(
                    children: [
                      Icon(
                        actif ? Icons.verified : Icons.remove_circle_outline,
                        color: actif
                            ? AppTheme.vertFacile
                            : AppTheme.grisTexteSecondaire,
                      ),
                      const SizedBox(width: AppTheme.spacingMd),
                      Expanded(
                        child: Text(
                          actif
                              ? t.monetization.subscriptionActiveUntil(
                                  date: _jour(echeance),
                                )
                              : t.monetization.subscriptionInactive,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: AppTheme.spacingBase),

            // --- Ce que l'abo DONNE ----------------------------------------
            _Ligne(
              icon: Icons.block,
              label: t.monetization.subscriptionIncludesNoAds,
            ),
            _Ligne(
              icon: Icons.savings_outlined,
              label: t.monetization.subscriptionIncludesAllowance,
            ),
            // Montant NON DECIDE : on le dit, on ne l'invente pas.
            if (kSubscriberStepsAllowance == null)
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingXl),
                child: Text(
                  t.monetization.subscriptionAllowancePending,
                  key: const ValueKey('abo-cagnotte-en-attente'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
              ),
            const SizedBox(height: AppTheme.spacingBase),

            // --- Ce que l'abo NE DONNE PAS ---------------------------------
            AppCard(
              key: const ValueKey('abo-exclusions'),
              backgroundColor: theme.colorScheme.error.withAlpha(14),
              borderColor: theme.colorScheme.error.withAlpha(60),
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: theme.colorScheme.error),
                  const SizedBox(width: AppTheme.spacingSm),
                  Expanded(
                    child: Text(
                      t.monetization.subscriptionExcludes,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),

            AppButton(
              key: const ValueKey('souscrire-abo'),
              icon: Icons.workspace_premium,
              label: t.monetization.subscriptionCta,
              isLoading: _occupe,
              onPressed: _occupe ? null : _souscrire,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            AppButton(
              key: const ValueKey('restaurer-achats'),
              variant: AppButtonVariant.outline,
              icon: Icons.restore,
              label: t.monetization.restoreCta,
              onPressed: _occupe ? null : _restaurer,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // CE QUE LA RESTAURATION COUVRE, ET CE QU'ELLE NE COUVRE PAS.
            // Les randonnees debloquees avec le compte-etapes ne sont pas des
            // produits store : elles vivent dans la base locale. Le dire evite
            // de promettre une restauration qui ne viendra pas.
            Text(
              t.monetization.restoreWhatItCovers,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Date courte, sans dependance a une locale de formatage.
  String _jour(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Une ligne « ce que l'abo donne » (coche + libelle).
class _Ligne extends StatelessWidget {
  const _Ligne({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.vertFacile),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
