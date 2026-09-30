import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../domain/etat_publicite.dart';
import '../providers/ads_providers.dart';

/// LE BOUTON « RETIRER LES PUBS », ET SES DEUX CHOIX.
///
/// LA DEMANDE DE CHRISTOPHE, MOT POUR MOT (30/09 12:24, DEM-260930-1224) : « Ou
/// un retirer le mode pub en bouton, qui amene a 2 choix : 1 s abonner, 2 voir
/// une video pour etre sans pub 24h ».
///
/// CE QUI EXISTAIT, ET CE QUI MANQUAIT. Les DEUX mecanismes etaient entiers et
/// branches : l'abonnement ([MonetizationService.subscribe], son ecran, son
/// prix) et la recompense video ([RewardedAdService] plus
/// [MonetizationService.grantRewardNoAds], 24 h en base avec son echeance). Ce
/// qui manquait etait le CHOIX : la video avait son bouton
/// ([RewardedNoAdsButton], pose sur la banniere par la tache 614), l'abonnement
/// vivait dans un ecran qu'il fallait aller chercher, et rien ne disait au
/// randonneur gene par une publicite qu'il avait DEUX facons de l'eteindre. Ce
/// widget est ce choix, et il ne fabrique aucune mecanique neuve.
///
/// IL NE PEUT PAS MENTIR, PAR CONSTRUCTION. Il lit
/// [etatPubliciteProvider] — la meme decision que la banniere, prise a la source
/// unique — et s'efface des qu'une publicite ne va PAS s'afficher. Proposer de
/// retirer ce qui est deja retire est exactement le genre de bouton mort que le
/// projet refuse depuis la tache 579.
class RetirerLesPubsButton extends ConsumerWidget {
  const RetirerLesPubsButton({
    required this.trailId,
    this.compact = false,
    super.key,
  });

  /// Le sentier dont on parle. Chaine vide = hors trek (catalogue, listes) :
  /// seuls l'abonnement et la recompense de 24 h y ont un sens, et ce sont
  /// justement les deux choix proposes ici.
  final String trailId;

  /// Rendu COMPACT pour la banniere : meme hauteur de cible tactile (44,
  /// plancher AA), sans la marge haute.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // La publicite est-elle seulement possible ? (consentement UMP + SDK). Sans
    // cela, la video n'existe pas et la banniere ne s'affiche pas : on ne
    // propose pas d'eteindre ce qui n'est pas allume.
    final adsReady = ref.watch(adsReadyProvider).value ?? false;
    if (!adsReady) return const SizedBox.shrink();
    final etat = ref.watch(etatPubliciteProvider(trailId)).value;
    if (etat == null || !etat.pubAffichee) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: compact ? 0 : AppTheme.spacingSm),
      // GRISE EN DEMO (integration 647, decision de Christophe du 30/09). Cette
      // porte n ouvre que deux chemins — l abonnement et la video des 24 h — et
      // les deux engagent quelque chose de reel. En demo on la montre, on ne la
      // franchit pas.
      child: GriseEnDemo(
        child: AppButton(
          key: const Key('retirer-les-pubs-button'),
          variant: AppButtonVariant.outline,
          minHeight: compact ? 44 : 48,
          icon: StepwaysIcons.interdit,
          label: t.monetization.removeAdsCta,
          onPressed: () => ouvrirLeChoixSansPub(context, trailId: trailId),
        ),
      ),
    );
  }
}

/// Ouvre le choix a deux entrees : s'abonner, ou regarder une video.
///
/// UN SEUL CHEMIN, comme pour l'achat ([acheterSentier]). Tant qu'une feuille de
/// choix s'ouvre depuis plusieurs endroits, chaque endroit finit par proposer sa
/// propre version — c'est la faute que la tache 614 a payee sur la vitrine
/// d'achat, ouverte par six ecrans avec six prix possibles.
Future<void> ouvrirLeChoixSansPub(
  BuildContext context, {
  required String trailId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (_) => _FeuilleSansPub(trailId: trailId),
  );
}

/// LA FEUILLE DE CHOIX : deux entrees, et ce que chacune donne EXACTEMENT.
///
/// CHAQUE CHOIX DIT SA CONTREPARTIE, PAS SON GESTE. L'abonnement retire la
/// publicite PARTOUT tant qu'on paie ; la video la retire pendant 24 H, et rien
/// d'autre — verbatim de Christophe (DEM-260930-1241) : « video 24h retire la pub
/// prepa pendant 24h point ». Ni etapes, ni droits, ni realisation : le dire ici
/// evite qu'on le croie, et c'est exactement ce que la regle fait.
class _FeuilleSansPub extends ConsumerStatefulWidget {
  const _FeuilleSansPub({required this.trailId});

  final String trailId;

  @override
  ConsumerState<_FeuilleSansPub> createState() => _FeuilleSansPubState();
}

class _FeuilleSansPubState extends ConsumerState<_FeuilleSansPub> {
  bool _occupe = false;

  Future<void> _regarderLaVideo() async {
    if (_occupe) return;
    setState(() => _occupe = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final gagne = t.monetization.rewardedEarned;
    final rate = t.monetization.rewardedUnavailable;
    // Provider autoDispose : `refresh` force une nouvelle lecture, donc une
    // nouvelle publicite — sans quoi le second appui rejouerait le resultat du
    // premier.
    final obtenu = await ref.refresh(watchRewardedForNoAdsProvider.future);
    if (!mounted) return;
    setState(() => _occupe = false);
    if (navigator.canPop()) navigator.pop();
    messenger.showSnackBar(SnackBar(content: Text(obtenu ? gagne : rate)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          0,
          AppTheme.spacingBase,
          AppTheme.spacingBase,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.monetization.removeAdsTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // CHOIX 1 — S'ABONNER. On ne souscrit pas ici : on ouvre le parcours
            // d'abonnement qui existe (prix, conditions, resiliation en trois
            // clics). Un second chemin d'achat serait un second prix possible.
            AppButton(
              key: const Key('sans-pub-abonnement'),
              icon: StepwaysIcons.favori,
              label: t.monetization.removeAdsSubscribe,
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/subscription');
              },
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.monetization.removeAdsSubscribeBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            // CHOIX 2 — LA VIDEO. 24 h sans publicite, et RIEN D'AUTRE.
            AppButton(
              key: const Key('sans-pub-video'),
              variant: AppButtonVariant.outline,
              isLoading: _occupe,
              icon: StepwaysIcons.video,
              label: t.monetization.removeAdsWatch,
              onPressed: _occupe ? null : _regarderLaVideo,
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.monetization.removeAdsWatchBody,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
