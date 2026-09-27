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
/// IL DIT MAINTENANT CE QU'IL COUTE (tache 601). Chris a donne le chiffre le
/// 27/09 12:26 : « Le prix on l'avait fixe a 2 euros mous = pub nul part et 2
/// etapes cagnottes par mois ». L'ecran annoncait ce que l'abo donne et ce qu'il
/// ne donne pas, sans jamais dire son PRIX — une page d'abonnement sans prix ne
/// vend rien, et le prix vivait a l'oral, donc nulle part.
///
/// LA CAGNOTTE EST CHIFFREE, ET SA NATURE EST ECRITE : un versement MENSUEL, pas
/// un cadeau de bienvenue. Les etapes creditees restent acquises a vie meme
/// apres l'arret de l'abonnement (regle d'or #99404 : credits a vie, sans-pub lie
/// a un etat actif) — l'ecran le dit, parce que c'est exactement la question que
/// se pose quelqu'un qui hesite a se desabonner.
///
/// LE MECANISME « MONTANT NON DECIDE » RESTE CABLE : si un jour un chiffre
/// repasse en attente ([kSubscriberStepsAllowance] a `null`), l'ecran le dit au
/// lieu d'inventer un nombre.
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
    // Copie locale : une variable de haut niveau ne se promeut pas, et on veut
    // lire le montant SANS le relire deux fois ni le recopier a l'ecran.
    const cagnotte = kSubscriberStepsAllowance;

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

            // --- LE PRIX --------------------------------------------------
            // Une page d'abonnement sans prix ne vend rien. Il est lu dans la
            // SOURCE UNIQUE (kSubscriptionPriceEur), jamais recopie a l'ecran.
            AppCard(
              key: const ValueKey('abo-prix'),
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Row(
                children: [
                  Icon(Icons.sell_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      t.monetization.subscriptionPrice(
                        price: t.monetization
                            .packPrice(price: _euros(kSubscriptionPriceEur)),
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),

            // --- Ce que l'abo DONNE ----------------------------------------
            _Ligne(
              icon: Icons.block,
              label: t.monetization.subscriptionIncludesNoAds,
            ),
            // Montant NON DECIDE : on le dit, on ne l'invente pas. Decide
            // (27/09) : on l'annonce avec son nombre et sa periodicite.
            if (cagnotte == null)
              _Ligne(
                icon: Icons.savings_outlined,
                label: t.monetization.subscriptionAllowancePending,
              )
            else ...[
              _Ligne(
                key: const ValueKey('abo-cagnotte'),
                icon: Icons.savings_outlined,
                label: t.monetization.subscriptionIncludesAllowance(
                  steps: cagnotte,
                ),
              ),
              // LE POINT QUI DECIDE UN DESABONNEMENT : les etapes creditees
              // restent acquises, seul le sans-pub s'arrete.
              Padding(
                padding: const EdgeInsets.only(left: AppTheme.spacingXl),
                child: Text(
                  t.monetization.subscriptionAllowanceForLife,
                  key: const ValueKey('abo-cagnotte-a-vie'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
              ),
            ],
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

  /// Montant en euros, sans decimale inutile (« 2 » et non « 2.0 »).
  ///
  /// Meme regle d'ecriture que la grille des packs : le symbole monetaire est
  /// porte par la traduction (`monetization.packPrice`), qui le place du bon cote
  /// selon la langue.
  static String _euros(double montant) => montant == montant.roundToDouble()
      ? montant.toStringAsFixed(0)
      : montant.toStringAsFixed(2);

  /// Date courte, sans dependance a une locale de formatage.
  String _jour(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/${d.year}';
}

/// Une ligne « ce que l'abo donne » (coche + libelle).
class _Ligne extends StatelessWidget {
  const _Ligne({super.key, required this.icon, required this.label});

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
