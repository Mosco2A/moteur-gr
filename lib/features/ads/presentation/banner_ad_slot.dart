import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/ads_providers.dart';

/// L'EMPLACEMENT DE LA BANNIERE — la chose qui manquait (tache 595, B1).
///
/// CE QUI EXISTAIT AVANT, ET CE QUI N'EXISTAIT PAS. La logique qui decide QUAND
/// afficher une banniere etait ecrite ET testee ([shouldShowBannerProvider],
/// `ads_gating_test.dart`) ; la banniere elle-meme n'a JAMAIS ete construite —
/// mesure faite ligne a ligne : zero `BannerAd`, zero `AdWidget` dans tout
/// `lib/`. Ce n'etait pas « la pub en mode test », c'etait un interrupteur sans
/// ampoule. Ce widget est l'ampoule, et il se branche sur l'interrupteur
/// existant sans en refaire la moindre regle.
///
/// TROIS PROPRIETES QUI COMPTENT, et qui sont toutes verifiees par test :
///
///  1. RIEN N'EST DEMANDE quand la regle d'or #99404 dit non. Le provider ne
///     charge pas puis ne cache pas : il ne charge PAS. Une publicite chargee
///     puis masquee a quand meme ete demandee — donc payee en donnees, en
///     batterie, et l'identifiant publicitaire de l'appareil est parti. Un
///     trek achete doit ETRE sans pub, pas SEMBLER sans pub.
///
///  2. ZERO HAUTEUR quand il n'y a pas de banniere. Pas de bandeau gris, pas
///     de « chargement… », pas de trou blanc en bas de l'ecran : un abonne ne
///     doit rien payer, pas meme en pixels.
///
///  3. LA BANNIERE DISPARAIT DANS L'INSTANT quand l'etat change. Acheter le
///     trek, regarder une video recompensee : la publicite s'en va et elle est
///     LIBEREE cote natif. Rien n'attend le prochain demarrage.
///
/// OU IL NE DOIT JAMAIS ETRE POSE : sur le chemin du secours. Le SOS ne porte
/// aucune publicite, nulle part, jamais — c'est la decision la mieux respectee
/// du modele et un test structurel la garde (`pub_v1_595_test.dart`, B5).
class BannerAdSlot extends ConsumerWidget {
  const BannerAdSlot({required this.trailId, super.key});

  /// L'emplacement d'un ecran SANS trek en contexte (catalogue, listes).
  ///
  /// Les deux volets APP-WIDE de la regle d'or s'y appliquent entierement —
  /// abonne actif et recompense de 24 h coupent la publicite partout. Seul
  /// « trek achete = sans pub sur CE trek » n'a rien a dire quand aucun trek
  /// n'est choisi (cf. [adContextHorsTrek]).
  const BannerAdSlot.horsTrek({super.key}) : trailId = adContextHorsTrek;

  /// Le trek dont depend le sans-pub (« trek achete = sans pub sur CE trek »).
  ///
  /// L'abonnement et la recompense de 24 h, eux, valent PARTOUT : ils sont lus
  /// par la meme source unique, quel que soit le trek passe ici.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banniere = ref.watch(bannerAdProvider(trailId)).value;
    if (banniere == null) return const SizedBox.shrink();

    // La hauteur est celle que la regie a reellement rendue : on ne devine
    // jamais la taille d'une banniere, on la reserve exactement.
    return SafeArea(
      top: false,
      child: SizedBox(
        height: banniere.height,
        width: double.infinity,
        child: Center(child: banniere.view),
      ),
    );
  }
}
