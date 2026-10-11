/// Le deuxieme des trois points d'entree de l'achat : le cockpit, seul ecran ou
/// le marcheur passait des semaines sans pouvoir payer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/monetization_service.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/paywall_sheet.dart';
import '../../../../core/branding/stepways_icons.dart';
import '../cockpit_phase.dart';

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
/// LE MEME GESTE QUE LES DEUX AUTRES. Ce bouton appelle [buyTrail], qui
/// est la seule fonction de `lib/` a ouvrir la vitrine et qui resout le prix
/// elle-meme. Aucun second chemin de paiement n'est cree ici.
///
/// IL DISPARAIT DES QU'IL N'A PLUS RIEN A VENDRE. La condition est la source
/// unique et REACTIVE [isDemoModeProvider] — faux des que le sentier est
/// possede, gratuit, ou couvert par un abonnement. Elle emet a chaque mutation
/// des droits : acheter ici fait disparaitre le bouton sans changer d'ecran.
///
/// ET IL DISPARAIT AUSSI QUAND LA VENTE N'A PLUS DE SENS (tache 809).
///
/// Christophe, 10/10, verbatim : « enlever le bouton acheter quand on est en
/// trek et en post dtrek car le circuit a forcement ete achete ».
///
/// CE BOUTON ETAIT LE SEUL DES TROIS A VIVRE ENTIEREMENT HORS DU MECANISME DE
/// PHASE, et c'est pour cela qu'il restait visible pendant et apres la marche.
/// Il ne consultait que la POSSESSION — « ce sentier est-il encore a vendre ? »
/// — et jamais LA MARCHE. Il n'a donc rien su de la randonnee, ni en
/// demonstration ni ailleurs.
///
/// LA PHASE D'ABORD, LE DROIT ENSUITE. L'ordre compte : la phase est un fait
/// synchrone et local, la possession une lecture de base. Un sentier qu'on est
/// en train de marcher ne se vend plus, quelle que soit la reponse des droits.
///
/// POURQUOI LA PHASE ET NON LA POSSESSION, ALORS QUE CHRISTOPHE DIT « LE
/// CIRCUIT A FORCEMENT ETE ACHETE ». Parce que cette phrase decrit son
/// INTENTION, pas l'etat technique — et qu'il a fait tous ses constats EN MODE
/// DEMO, ou precisement rien n'est acquis : `ownsTrail` et `canRealizeTrail`
/// repondent exactement la meme chose pendant une demonstration et hors demo
/// (garde-fou du lot 601, en-tete de `session_demo.dart`). Attendre la
/// possession aurait donc laisse le bouton exactement la ou Christophe l'a vu.
/// On lit la MARCHE, qui est vraie dans les deux mondes — et la demo n'engage
/// rien, elle le dit deja sous le bouton de depart (« départ simulé »).
///
/// L'ACHAT N'EST PAS PERDU POUR AUTANT. Des trois points d'entree de la vente
/// (catalogue, preparation, depart), seul CELUI-CI se tait pendant et apres la
/// marche. Le catalogue garde le sien, intact : un marcheur qui veut payer son
/// sentier apres l'avoir essaye en demonstration y trouve toujours son bouton.
class HubBuyTrekButton extends ConsumerWidget {
  const HubBuyTrekButton({required this.trailId, super.key});

  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(cockpitPhaseProvider) != CockpitPhase.prepare) {
      return const SizedBox.shrink();
    }

    final achetable = ref.watch(isDemoModeProvider(trailId)).value ?? false;
    if (!achetable) return const SizedBox.shrink();

    // LE PRIX VIENT DU SERVICE, QUI LE LIT AU CATALOGUE (avenant 614). Cet
    // ecran ne connait plus le nombre d'etapes du sentier et n'a pas a le
    // connaitre : c'est celui qui debite qui compte, une seule fois.
    final monetisation = ref.watch(monetizationServiceProvider);
    final stages = monetisation.stagesOfTrail(trailId);

    // L'ESPACEMENT EST PORTE PAR L'ECRAN, pas par le bouton : quand il
    // s'efface, le cockpit ne doit pas garder un blanc de la taille d'un
    // bouton absent (cf. `hub_screen.dart`, ou les deux espaces qui l'encadrent
    // valent ensemble l'espace unique qui etait la avant lui).
    return AppButton(
      key: const Key('hub-buy-trek-button'),
      variant: AppButtonVariant.outline,
      icon: StepwaysIcons.cadenasOuvert,
      // EN ETAPES, PAS EN EUROS (tache 806). Le nombre d'etapes est le prix du
      // sentier et il ne depend pas de l'acheteur ; le montant en euros, lui,
      // depend de la facon dont la cagnotte a ete remplie, et ne peut donc pas
      // s'ecrire sur un sentier.
      label: stages > 0
          ? t.monetization.buyCtaWithSteps(n: stages)
          : t.monetization.buyCta,
      onPressed: () => buyTrail(context, ref, trailId: trailId),
    );
  }
}
