/// L'abonnement sans publicite et la RESTAURATION des achats : le service
/// savait s'abonner, aucun ecran ne le proposait.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/store_subscription_links.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/services/wallet_iap_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../booking/booking_facade.dart' show deeplinkLauncherProvider;
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/branding/stepways_icons.dart';

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
    final issue = await ref
        .read(monetizationServiceProvider)
        .restorePurchases();
    if (!mounted) return;
    setState(() => _occupe = false);
    // LE BOUTON REPOND TOUJOURS. `restorePurchases` etait un `Future<void>`
    // qui ne faisait rien en mode stub : l'appui n'avait aucune consequence
    // visible. Il rend desormais un resultat type, et on le NOMME.
    messenger.showSnackBar(
      SnackBar(
        content: Text(switch (issue.status) {
          PurchaseRestoreStatus.requested => t.monetization.restoreRequested,
          PurchaseRestoreStatus.storeUnavailable =>
            t.monetization.restoreUnavailable,
        }),
      ),
    );
  }

  /// ARRETER L'ABONNEMENT : ouvrir la page de gestion de la boutique.
  ///
  /// CE QUE CETTE METHODE NE FAIT PAS, ET NE DOIT PAS FAIRE : annuler. Google
  /// Play et l'App Store facturent l'abonnement et interdisent un parcours
  /// d'annulation interne qui contournerait leur facturation. Le seul geste
  /// legitime — et celui que les deux documentations demandent — est d'OUVRIR
  /// leur page d'abonnements. Sources en base #100700.
  ///
  /// ET SI LA BOUTIQUE NE S'OUVRE PAS, ON LE DIT. Un appareil sans Play Store,
  /// un lien qu'aucune application ne sait ouvrir : le lanceur rend `false`, et
  /// le randonneur doit entendre quoi faire. Un bouton qui echouerait en silence
  /// sur une resiliation serait exactement le defaut que la loi vise.
  Future<void> _arreterAbonnement() async {
    final messenger = ScaffoldMessenger.of(context);
    final ouvert = await ref
        .read(deeplinkLauncherProvider)
        .open(StoreSubscriptionLinks.pour(productId: kWalletSubNoAdsMonthly));
    if (!mounted || ouvert) return;
    messenger.showSnackBar(
      SnackBar(content: Text(t.monetization.cancelStoreUnavailable)),
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
                      StepIcon(
                        actif ? StepwaysIcons.diplome : StepwaysIcons.moins,
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
                  StepIcon(
                    StepwaysIcons.prix,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Text(
                      t.monetization.subscriptionPrice(
                        price: t.monetization.packPrice(
                          price: _euros(kSubscriptionPriceEur),
                        ),
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
              icon: StepwaysIcons.interdit,
              label: t.monetization.subscriptionIncludesNoAds,
            ),
            // Montant NON DECIDE : on le dit, on ne l'invente pas. Decide
            // (27/09) : on l'annonce avec son nombre et sa periodicite.
            if (cagnotte == null)
              _Ligne(
                icon: StepwaysIcons.portefeuille,
                label: t.monetization.subscriptionAllowancePending,
              )
            else ...[
              _Ligne(
                key: const ValueKey('abo-cagnotte'),
                icon: StepwaysIcons.portefeuille,
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
                  StepIcon(
                    StepwaysIcons.info,
                    size: 20,
                    color: theme.colorScheme.error,
                  ),
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
              icon: StepwaysIcons.diplome,
              label: t.monetization.subscriptionCta,
              isLoading: _occupe,
              onPressed: _occupe ? null : _souscrire,
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // --- ARRETER L'ABONNEMENT ---------------------------------------
            //
            // ICI, ET PAS AU FIN FOND DE L'APPLI. Exigence de Chris, 27/09
            // 13:09 : « je veux un arreter votre abonnement en 3 clics comme le
            // prevoit la loi, et pas planque au fin fond de l appli ». Le bouton
            // est donc SOUS celui qui vend, a la MEME largeur, sur le MEME ecran
            // qui dit ce que l'abo donne et ce qu'il ne donne pas. Le compte fait
            // trois gestes depuis l'accueil : reglages, abonnement, arreter — et
            // il est VERROUILLE PAR UN TEST qui les compte
            // (`resiliation_trois_clics_601_test.dart`), parce qu'un nombre de
            // gestes se mesure et ne se promet pas.
            //
            // IL N'ANNULE PAS, IL CONDUIT — et c'est la seule chose honnete
            // qu'il puisse faire. L'abonnement est facture par la boutique, qui
            // interdit tout parcours d'annulation interne contournant sa
            // facturation. Un bouton qui pretendrait annuler en se contentant de
            // journaliser serait un faux succes sur le sujet le plus sensible.
            AppButton(
              key: const ValueKey('abo-arreter'),
              variant: AppButtonVariant.outline,
              icon: StepwaysIcons.croix,
              label: t.monetization.cancelCta,
              onPressed: _occupe ? null : _arreterAbonnement,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            // CE QUE LE BOUTON FAIT, DIT AVANT L'APPUI : ou se passe l'arret,
            // jusqu'a quand l'acces court, et ce qui reste acquis.
            Text(
              t.monetization.cancelExplains,
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),

            AppButton(
              key: const ValueKey('restaurer-achats'),
              variant: AppButtonVariant.outline,
              icon: StepwaysIcons.rafraichir,
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

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingXs),
      child: Row(
        children: [
          StepIcon(icon, size: 18, color: AppTheme.vertFacile),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
