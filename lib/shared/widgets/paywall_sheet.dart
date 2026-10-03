/// Le geste d'achat UNIQUE d'un sentier, atteignable du catalogue comme de la
/// preparation, et plus seulement a l'instant de partir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../features/ads/presentation/rewarded_no_ads_button.dart';
import '../../i18n/translations.g.dart';
import 'app_button.dart';
import '../../core/branding/stepways_icons.dart';

/// ACHETER UN SENTIER — LE GESTE UNIQUE (tache 614).
///
/// LE DEFAUT QUE CE GESTE FERME EST COMMERCIAL, PAS ERGONOMIQUE. Demande de
/// Christophe, 28/09 11:41 : « Il faut que l achat puisse se faire du catalogue
/// et depuis la preparation ». Mesure faite avant d'ecrire : le seul chemin
/// d'achat d'un sentier partait du bouton « Démarrer la randonnée »
/// ([HubStartTrekButton]) — on ne pouvait donc payer qu'a l'instant ou l'on
/// part. Celui qui decouvre un sentier au catalogue et veut l'acheter tout de
/// suite, celui qui prepare depuis trois semaines et se decide un soir :
/// aucun des deux n'avait de bouton. C'est de la vente perdue tous les jours.
///
/// UN SEUL GESTE, APPELE DEPUIS TROIS ENDROITS — exactement ce que
/// [chooseTrail] a fait pour la bascule de sentier au lot 606. Le catalogue
/// ([TrailCatalogScreen]), la preparation ([HubBuyTrekButton]) et le depart
/// ([HubStartTrekButton]) appellent CETTE fonction ; elle est la SEULE de tout
/// `lib/` a ouvrir la vitrine, et un test structurel le tient. Trois
/// implementations du meme achat auraient derive en trois prix.
///
/// ET LE PRIX N'EST PLUS DANS CE FICHIER NON PLUS (avenant 614). Le geste
/// resolvait lui-meme le nombre d'etapes depuis le catalogue effectif, ce qui
/// reglait les six ecrans — mais laissait `buyTrail` prendre un `totalStages`
/// REQUIS, donc un chemin par lequel un sentier payant devenait gratuit sur une
/// erreur d'argument. Le prix a donc descendu d'un etage : il est lu par le
/// SERVICE ([MonetizationService.stagesOfTrail]), qui est aussi celui qui
/// debite. Le montant affiche et le montant preleve ne peuvent plus diverger,
/// et ce geste n'a plus rien a transmettre qu'un identifiant.
Future<void> acheterSentier(
  BuildContext context,
  WidgetRef ref, {
  required String trailId,
}) {
  return _ouvrirLaVitrine(context, trailId: trailId);
}

/// Ouvre l ecran paywall en bottom sheet (E4.17, StepWays LOT 1).
///
/// PRIVEE DEPUIS LA TACHE 614, et c'est la garantie du « meme chemin ». Tant
/// qu'elle etait publique, chaque ecran pouvait ouvrir sa propre vitrine avec
/// son propre prix ; six le faisaient. Le seul appelant est desormais
/// [acheterSentier], et un test structurel refuse qu'un septieme apparaisse.
///
/// Propose le deblocage du trek [trailId] : liste des avantages (#81774) + prix
/// EUR indicatif (etapes x [kStepTierEur]) + CTA. L'achat passe par le
/// compte-etapes ([MonetizationService.buyTrail]) : wallet d'abord, complement
/// store. En mode stub IAP, aucun paiement reel n'est declenche.
Future<void> _ouvrirLaVitrine(BuildContext context, {required String trailId}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => PaywallSheet(trailId: trailId),
  );
}

/// Contenu de l ecran paywall (E4.17, #81774).
///
/// Gratuit = preparation avec pub + demo. Premium a la carte =
/// trek complet sans pub. Textes via Slang (t.monetization.*).
///
/// IL NE RECOIT PLUS DE NOMBRE D'ETAPES (avenant 614) : il DEMANDE le prix au
/// service, qui le lit au catalogue. C'est la meme lecture que celle du debit —
/// une vitrine qui affiche un montant et un service qui en preleve un autre
/// etait mecaniquement possible tant que les deux etaient passes separement.
class PaywallSheet extends ConsumerWidget {
  const PaywallSheet({super.key, required this.trailId});

  /// Trek a debloquer.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final monetization = ref.watch(monetizationServiceProvider);
    // Prix EUR indicatif, lu au catalogue par la SOURCE UNIQUE du prix.
    final totalStages = monetization.stagesOfTrail(trailId);
    final price = monetization.eurPriceForTrail(trailId);

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
            StepIcon(
              StepwaysIcons.diploma,
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
            // LE BOUTON DIT CE QU'IL A FAIT (tache 594, A3).
            //
            // CE QU'IL FAISAIT : il appelait `buyTrail`, JETAIT le resultat et
            // fermait la feuille — succes, echec, hors-ligne, complement non
            // confirme, tout se terminait de la meme facon : la feuille se
            // referme, rien n'a change, et l'utilisateur ne sait pas pourquoi.
            // La boutique de packs de la MEME application dit son refus depuis
            // le LOT X : deux honnetetes dans un seul produit.
            //
            // CE QU'IL FAIT : il nomme chacune des quatre issues, et il ne
            // ferme la feuille QUE sur un succes — un echec laisse le chemin
            // d'achat ouvert plutot que de renvoyer l'utilisateur d'ou il
            // vient sans explication.
            AppButton(
              key: const Key('paywall-buy-button'),
              icon: StepwaysIcons.cadenasOuvert,
              label: totalStages > 0
                  ? t.monetization.buyCtaWithPrice(
                      price: price.toStringAsFixed(2),
                    )
                  : t.monetization.buyCta,
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final outcome = await ref
                    .read(monetizationServiceProvider)
                    .buyTrail(trailId);
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(_messagePour(outcome))),
                );
                if (outcome.isOwned ||
                    outcome.status == PurchaseStatusResult.alreadyOwned) {
                  Navigator.of(context).pop();
                }
              },
            ),
            // StepWays L6/A6 : voie sans-pub 24 h par pub RECOMPENSEE (rewarded).
            // Affichee seulement si le consentement pub est obtenu (adsReady) —
            // formats autorises = banniere + rewarded, PAS d'interstitiel.
            //
            // TACHE 614 — C'EST LE MEME BOUTON QUE CELUI DE LA BANNIERE. Il
            // vivait ici en widget PRIVE, donc inatteignable depuis l'endroit
            // ou la publicite gene reellement. Il est sorti dans
            // [RewardedNoAdsButton] et pose aux DEUX endroits : une seule
            // mecanique, un seul libelle, une seule facon d'obtenir les 24 h.
            const RewardedNoAdsButton(),
          ],
        ),
      ),
    );
  }
}

/// Traduit l'issue d'un achat en une phrase que l'utilisateur peut lire.
///
/// Les CINQ issues de [PurchaseStatusResult] sont distinctes et se disent
/// differemment : « c'est fait », « c'etait deja fait », « il faut du reseau »,
/// « le paiement n'a pas abouti », « ce sentier n'est pas en vente ». Les trois
/// dernieres precisent que RIEN n'a ete debite — le service fait bien le
/// rollback (ou n'engage rien du tout), il fallait encore le dire.
///
/// LA CINQUIEME EST NEE DE L'AVENANT 614, et elle doit se DIRE plutot que de se
/// taire : un sentier absent du catalogue n'a pas de prix, donc l'achat est
/// refuse. Le refus silencieux aurait ete un bouton qui ne produit rien — et
/// l'alternative, vendre a zero, aurait offert le sentier.
String _messagePour(PurchaseOutcome outcome) {
  final m = t.monetization;
  return switch (outcome.status) {
    PurchaseStatusResult.owned => m.buyOutcomeOwned,
    PurchaseStatusResult.alreadyOwned => m.buyOutcomeAlreadyOwned,
    PurchaseStatusResult.offlineComplementRequired => m.buyOutcomeOffline(
      steps: outcome.complementSteps,
    ),
    PurchaseStatusResult.complementFailed => m.buyOutcomeFailed,
    PurchaseStatusResult.unknownPrice => m.buyOutcomeUnknownPrice,
    // LA SIXIEME EST NEE DE LA TACHE 634 : en demo, rien ne s achete et rien
    // n est debite. Le refus se DIT, la ou un echec muet aurait ressemble a une
    // panne de la vitrine.
    PurchaseStatusResult.refuseEnDemo => m.buyOutcomeDemo,
  };
}

// LE CTA « UN JOUR SANS PUBLICITE » A QUITTE CE FICHIER (tache 614). Il y
// vivait en widget PRIVE (`_RewardedNoAdsButton`), donc utilisable nulle part
// ailleurs — et « ailleurs », c'etait justement le seul endroit ou il avait du
// sens : SUR la banniere, la ou la publicite gene. Il est devenu
// [RewardedNoAdsButton] (`features/ads/presentation/`), pose par la vitrine ET
// par l'emplacement publicitaire. Une seule mecanique, un seul libelle.

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
          const StepIcon(
            StepwaysIcons.cochePleine,
            size: 18,
            color: AppTheme.vertFacile,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
