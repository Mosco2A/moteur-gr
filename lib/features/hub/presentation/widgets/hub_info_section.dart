/// La section « Informations » du cockpit — toujours rendue, aucune garde
/// de phase.
library;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../i18n/translations.g.dart';
import 'hub_section.dart';
import 'quick_access_card.dart';

/// La section « Informations » du cockpit.
///
/// Les cartes restent litterales — [HubSection] exige une
/// `List<QuickAccessCard>`.
class HubInfoSection extends StatelessWidget {
  const HubInfoSection({required this.trailId, super.key});

  /// L'identifiant du sentier courant, pose dans chaque route ouverte.
  final String trailId;

  @override
  Widget build(BuildContext context) {
    return // --- Section Informations (RF-9) ---
    // TOUJOURS rendue (aucune garde de phase).
    HubSection(
      title: t.hub.sections.info,
      icon: StepwaysIcons.info,
      cards: [..._cartesAlire(context)],
    );
  }

  /// Les rubriques qu'on LIT : hebergements proches et fiche conseil.
  List<QuickAccessCard> _cartesAlire(BuildContext context) => [
    // JOURNAL : PLUS ICI (retour Chris #11, tache 553). Mot pour
    // mot : « journal est dans information dans preparation??? ».
    // La carte etait rendue ici hors rando (correctif d'acces R10 /
    // LOT L10) et dans « Randonner » en rando : elle changeait de
    // place selon le moment, et « Informations » est une rubrique
    // qu'on LIT, pas ou l'on ECRIT son carnet.
    // Depuis la tache 558 elle n'existe PLUS DU TOUT en phase de
    // preparation (decision Chris) : elle vit dans « Randonner »
    // pendant la rando, et juste au-dessus de cette section une
    // fois le trek termine.
    QuickAccessCard(
      rubrique: RubriqueStepways.hebergement,
      title: t.hub.cards.accommodations,
      subtitle: t.hub.cards.accommodationsSub,
      onTap: () => context.push('/accommodations-nearby'),
    ),
    QuickAccessCard(
      rubrique: RubriqueStepways.ficheConseil,
      title: t.hub.cards.tips,
      subtitle: t.hub.cards.tipsSub,
      onTap: () => context.push('/trail/$trailId/tips'),
    ),
    // « GUIDES DES VILLES » — CARTE MASQUEE SUR DECISION DE CHRIS
    // (retour #13, tache 553). Mot pour mot : « guide des villes, on
    // en a pas assez parle voire pas du tout tu cache pour
    // l'instant ». La feature a ete cablee en E33/E34 (LOT D/D2)
    // sans jamais avoir ete discutee : on retire la PORTE du
    // cockpit, le temps d'en parler.
    //
    // CE QUI RESTE EN PLACE, INTACT : les routes
    // `/trail/:id/guides` et `/guides/:guideId`, les ecrans, les
    // providers, les donnees et les tests de la feature. Rien n'est
    // supprime — seule la carte du cockpit disparait. Remettre ces
    // six lignes suffit a rouvrir la porte.
    //
    // CETTE DECISION SURCLASSE LA REGLE S8 « zero route morte » :
    // S8 interdit une carte SANS cible, pas une cible sans carte, et
    // c'est Chris qui arbitre ce qu'il montre de son application.
  ];
}
