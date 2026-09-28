import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/monetization_service.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/paywall_sheet.dart';

/// ACHETER DEPUIS LA PREPARATION (tache 614) — deuxieme des trois points
/// d'entree de l'achat.
///
/// LE CAS DE CHRISTOPHE, VERBATIM DU 28/09 11:41 : « Il faut que l achat puisse
/// se faire du catalogue et depuis la preparation ». Le cockpit de preparation
/// est l'ecran ou vit le randonneur qui prepare son trek pendant des semaines —
/// et c'etait le seul ecran de l'application ou il passait du temps SANS jamais
/// rencontrer de bouton pour payer. Le seul chemin partait de « Démarrer la
/// randonnée », en bas, grise tant que les trois cartes coeur ne sont pas
/// faites : autrement dit, celui qui se decide un soir avant d'avoir fini sa
/// preparation n'avait AUCUN moyen d'acheter. C'est de la vente perdue.
///
/// LE MEME GESTE QUE LES DEUX AUTRES. Ce bouton appelle [acheterSentier], qui
/// est la seule fonction de `lib/` a ouvrir la vitrine et qui resout le prix
/// elle-meme. Aucun second chemin de paiement n'est cree ici.
///
/// IL DISPARAIT DES QU'IL N'A PLUS RIEN A VENDRE. La condition est la source
/// unique et REACTIVE [isDemoModeProvider] — faux des que le sentier est
/// possede, gratuit, ou couvert par un abonnement. Elle emet a chaque mutation
/// des droits : acheter ici fait disparaitre le bouton sans changer d'ecran.
class HubBuyTrekButton extends ConsumerWidget {
  const HubBuyTrekButton({required this.trailId, super.key});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final achetable = ref.watch(isDemoModeProvider(trailId)).value ?? false;
    if (!achetable) return const SizedBox.shrink();

    // LE PRIX VIENT DU SERVICE, QUI LE LIT AU CATALOGUE (avenant 614). Cet
    // ecran ne connait plus le nombre d'etapes du sentier et n'a pas a le
    // connaitre : c'est celui qui debite qui compte, une seule fois.
    final monetisation = ref.watch(monetizationServiceProvider);
    final etapes = monetisation.stagesOfTrail(trailId);
    final prix = monetisation.eurPriceForTrail(trailId);

    // L'ESPACEMENT EST PORTE PAR L'ECRAN, pas par le bouton : quand il
    // s'efface, le cockpit ne doit pas garder un blanc de la taille d'un
    // bouton absent (cf. `hub_screen.dart`, ou les deux espaces qui l'encadrent
    // valent ensemble l'espace unique qui etait la avant lui).
    return AppButton(
      key: const Key('hub-buy-trek-button'),
      variant: AppButtonVariant.outline,
      icon: Icons.lock_open,
      label: etapes > 0
          ? t.monetization.buyCtaWithPrice(price: prix.toStringAsFixed(2))
          : t.monetization.buyCta,
      onPressed: () => acheterSentier(context, ref, trailId: trailId),
    );
  }
}
