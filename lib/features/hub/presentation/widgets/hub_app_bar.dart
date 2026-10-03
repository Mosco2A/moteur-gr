/// L'en-tete du cockpit : le nom du sentier et les quatre portes du header
/// standard (Mes treks, Informations, Mon compte, Reglages).
library;

import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../i18n/translations.g.dart';

/// L'en-tete du cockpit.
///
/// L'ETAT RESTE CHEZ LE PARENT : le nom du sentier arrive par [trailTitle], et
/// l'ouverture de la feuille d'aide par [onInfoTap] — c'est l'ecran qui garde
/// son `context` et son `showModalBottomSheet`.
class HubAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HubAppBar({
    required this.trailTitle,
    required this.onInfoTap,
    super.key,
  });

  /// Le nom affichable du sentier courant.
  final String trailTitle;

  /// Ouvre la feuille d'aide, portee par le parent.
  final VoidCallback onInfoTap;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return // Parité GR20 pure (D1) : AUCUNE barre du bas sur le cockpit. Les sections
    // vivent dans le scroll ; la navigation est hub-and-push (push/pop).
    AppBar(
      title: Text(trailTitle),
      actions: [
        // StepWays LOT 2 (Phase 5) : retour a l'accueil « Mes treks » (option
        // A) — l'entree de l'onglet Accueil liste tous les treks possedes.
        IconButton(
          icon: const StepIcon(StepwaysIcons.chaussure),
          tooltip: t.nav.myTreks,
          onPressed: () => context.go('/my-treks'),
        ),
        IconButton(
          icon: const StepIcon(StepwaysIcons.info),
          tooltip: t.hub.infoTooltip,
          onPressed: onInfoTap,
        ),
        IconButton(
          icon: const StepIcon(StepwaysIcons.monCompte),
          tooltip: t.hub.profileTooltip,
          onPressed: () => context.push('/profile'),
        ),
        // Finitions V1 (point 1) : acces REGLAGES depuis le cockpit. Le
        // big-bang hub-and-push (L3) a supprime l'onglet « Plus » qui etait la
        // SEULE porte vers /settings -> langue/unites/theme/confidentialite
        // devenaient inatteignables apres l'onboarding. On retablit un acces
        // atteignable via le header standard du cockpit (SPEC §4 : « Mon compte
        // / reglages / ecrans info : header standard »). push -> retour propre.
        IconButton(
          icon: const StepIcon(StepwaysIcons.reglages),
          tooltip: t.nav.settings,
          onPressed: () => context.push('/settings'),
        ),
      ],
    );
  }
}
