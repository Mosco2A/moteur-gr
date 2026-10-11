/// Le geste d'achat UNIQUE d'un sentier, atteignable du catalogue comme de la
/// preparation, et plus seulement a l'instant de partir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/montant_en_euros.dart';
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
Future<void> buyTrail(
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
/// [buyTrail], et un test structurel refuse qu'un septieme apparaisse.
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
class PaywallSheet extends ConsumerStatefulWidget {
  const PaywallSheet({super.key, required this.trailId});

  /// Trek a debloquer.
  final String trailId;

  @override
  ConsumerState<PaywallSheet> createState() => _PaywallSheetState();
}

class _PaywallSheetState extends ConsumerState<PaywallSheet> {
  /// Le devis qui MANQUE D'ETAPES, quand le randonneur a demande a acheter.
  ///
  /// `null` tant qu'il n'a rien demande, ou tant que sa cagnotte suffit : la
  /// vitrine montre alors son bouton d'achat habituel. Des qu'il bute, ce champ
  /// porte le devis et la vitrine montre LES DEUX PORTES a la place du bouton.
  ///
  /// POURQUOI CE N'EST PAS AFFICHE D'EMBLEE. Une cagnotte vide est le cas du
  /// premier jour : annoncer « il te manque sept etapes » avant meme que le
  /// randonneur ait dit qu'il voulait acheter transformerait la vitrine en
  /// reproche. Le constat arrive quand il compte, c'est-a-dire quand il appuie.
  TrailQuote? _rupture;

  String get trailId => widget.trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monetization = ref.watch(monetizationServiceProvider);
    // LE PRIX EST EN ETAPES (tache 806) — il ne depend que du sentier. Le prix
    // en euros, lui, depend de la facon dont la cagnotte a ete remplie.
    final totalStages = monetization.stagesOfTrail(trailId);

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
            if (_rupture != null)
              _LesDeuxPortes(devis: _rupture!)
            else
              AppButton(
                key: const Key('paywall-buy-button'),
                icon: StepwaysIcons.cadenasOuvert,
                label: totalStages > 0
                    ? t.monetization.buyCtaWithSteps(n: totalStages)
                    : t.monetization.buyCta,
                onPressed: _acheter,
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

  /// Le geste d'achat : il COMPTE d'abord, et il ne choisit plus a la place du
  /// randonneur quand il manque des etapes (tache 806).
  ///
  /// CE QUI SE PASSAIT. Le bouton appelait `buyTrail`, qui, le compte-etapes
  /// insuffisant, prenait D'AUTORITE le plus petit pack couvrant le manque
  /// (`smallestPackCovering`). Pour sept etapes et une cagnotte vide, cela
  /// voulait dire le pack de 11 a 9,99 EUR — alors que le manque exact, sept
  /// etapes au tarif unite, vaut 6,93 EUR. L'application engageait donc la
  /// depense la plus grosse sans le demander, et sans jamais montrer l'autre
  /// terme de l'arbitrage.
  ///
  /// CE QUI SE PASSE. On demande un DEVIS, qui n'engage rien. S'il manque des
  /// etapes, on s'arrete et on montre les DEUX PORTES. Le choix revient au
  /// randonneur : le complement exact au tarif unite, ou un pack au tarif
  /// degressif. L'abonnement n'est PAS propose ici — decision de Christophe du
  /// 11/10 : il cagnotte des etapes chaque MOIS, il n'en depose pas a
  /// l'instant, donc il ne repond pas au besoin de celui a qui il manque trois
  /// etapes tout de suite. Sa place est le bloc de tarification.
  ///
  /// LA DEMO ET LES SENTIERS GRATUITS PASSENT DEVANT, inchanges : ils ont leurs
  /// propres refus, qui se disent, et un devis n'a rien a leur apprendre.
  Future<void> _acheter() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(monetizationServiceProvider);

    if (!service.enDemo && !service.isFreeTrail(trailId)) {
      final devis = await service.quoteTrail(trailId);
      if (!mounted) return;
      if (devis.complementSteps > 0) {
        setState(() => _rupture = devis);
        return;
      }
    }

    final outcome = await service.buyTrail(trailId);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(_messagePour(outcome))));
    if (outcome.isOwned ||
        outcome.status == PurchaseStatusResult.alreadyOwned) {
      Navigator.of(context).pop();
    }
  }
}

/// LES DEUX PORTES, et deux seulement (tache 806).
///
/// LE TEXTE EST CELUI DE CHRISTOPHE, du 11/10, a deux mots pres : « vous n avez
/// pas assez d etapes cagnottees pour acheter ce circuit. acheter le complement
/// ou achetez un pack ». Il est passe au TUTOIEMENT, parce que l'application
/// tutoie dans les cinq langues depuis le lot 757 et que le vouvoiement n'est
/// garde que sur les ecrans legaux ; et « circuit » est devenu « sentier »,
/// qui est le mot partout ailleurs dans l'application.
///
/// POURQUOI DEUX ET PAS TROIS. L'abonnement est ecarte NOMMEMENT par
/// Christophe : « on ne propose pas l abonnement pour le complement ». Il
/// cagnotte des etapes chaque mois, il n'en depose pas a l'instant — le
/// proposer a quelqu'un a qui il manque trois etapes maintenant serait une
/// reponse qui ne resout pas son probleme.
///
/// CHAQUE PORTE DIT SON PRIX EN EUROS, ET C'EST VOULU. C'est ici, et seulement
/// ici, que l'on paye avec de l'argent : le comptoir. Les deux montants cote a
/// cote sont exactement l'arbitrage — le tarif unite contre le tarif degressif
/// du pack, avec les etapes en trop qui restent acquises.
class _LesDeuxPortes extends ConsumerWidget {
  const _LesDeuxPortes({required this.devis});

  /// Le devis qui manque d'etapes : il porte le complement et le pack.
  final TrailQuote devis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.watch(monetizationServiceProvider);
    final langue = LocaleSettings.currentLocale.languageCode;
    final pack = devis.complementPack;

    return Column(
      key: const Key('paywall-deux-portes'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.monetization.complementTitle,
          style: theme.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          t.monetization.complementBody,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppTheme.spacingBase),

        // --- PORTE 1 : LE COMPLEMENT EXACT, au tarif unite ------------------
        AppButton(
          key: const Key('paywall-porte-complement'),
          variant: AppButtonVariant.outline,
          icon: StepwaysIcons.plus,
          label: t.monetization.complementDoorExact(n: devis.complementSteps),
          onPressed: () {
            // ON NE PROMET PAS CE QUE LA BOUTIQUE NE SAIT PAS ENCORE FAIRE.
            // Vendre exactement N etapes suppose un produit « une etape »
            // achete en quantite, ou un produit par nombre d'etapes ; aucun des
            // deux n'est declare a ce jour (les seuls consommables connus sont
            // les packs 11, 25 et 50). La porte existe, elle est honnete sur ce
            // qui lui manque, et elle ne debite rien.
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(t.monetization.complementExactPending)),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.spacingXs),
          child: Text(
            montantEnEuros(
              service.eurPriceForSteps(devis.complementSteps),
              langue,
            ),
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),

        // --- PORTE 2 : LE PACK, au tarif degressif --------------------------
        if (pack != null) ...[
          const SizedBox(height: AppTheme.spacingBase),
          AppButton(
            key: const Key('paywall-porte-pack'),
            icon: StepwaysIcons.panier,
            label: t.monetization.complementDoorPack(n: pack.steps),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await service.rechargeWallet(pack);
              if (!context.mounted) return;
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    ok
                        ? t.monetization.rechargeTitle
                        : t.monetization.storeUnavailable,
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppTheme.spacingXs),
            child: Text(
              montantEnEuros(pack.priceEur, langue),
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
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
