/// LE PORTEUR DE L'INTERSTITIEL : il ecoute les changements d'ecran et demande
/// a la cadence si l'heure est venue (tache 838, D2).
///
/// ---------------------------------------------------------------------------
/// POURQUOI UN WIDGET, ET POURQUOI ICI
/// ---------------------------------------------------------------------------
///
/// IL FAUT UN DECLENCHEUR QUI NE SE DEMONTE JAMAIS. Un interstitiel se decide a
/// l'ARRIVEE SUR UN ECRAN ; si le declencheur vivait DANS un ecran, il
/// disparaitrait a chaque navigation — c'est-a-dire au moment meme ou il doit
/// agir. Ce widget est pose dans les enveloppes de `main.dart`, au-dessus du
/// `Navigator`, a cote du cadre de demo : il est monte une fois et ne se
/// demonte plus.
///
/// POURQUOI IL NE CONNAIT PAS LE ROUTEUR, ET C'EST UNE CONTRAINTE REELLE. Le
/// routeur vit dans `lib/core/routing/`, c'est-a-dire le SOCLE. Un socle a le
/// droit de connaitre les features (`plafondSocleVersFeature`), mais ce plafond
/// est SERRE CONTRE LA MESURE et ne remonte jamais : brancher cet observateur
/// depuis `app_router.dart` aurait ajoute une fleche de plus et fait rougir
/// `couches_respectees_645_test.dart`.
///
/// ON INJECTE DONC LES DEUX SEULS FAITS DONT CE WIDGET A BESOIN — « quelque
/// chose a change » ([navigation]) et « ou sommes-nous » ([chemin]) — et c'est
/// `main.dart` qui les fournit depuis le routeur. `main.dart` compose
/// l'application : il n'est ni `core`, ni `shared`, ni une feature, et c'est
/// exactement la place de ce genre de noeud (meme raison que
/// `CadreDemo.sousLeBandeau`).
///
/// ET CELA LE REND MESURABLE SANS APPLICATION. Un test passe un
/// `ChangeNotifier` et une fermeture qui rend le chemin qu'il veut : il peut
/// donc faire arriver le randonneur sur l'ecran d'urgence, ou en pleine
/// marche, sans monter un routeur.
///
/// HORS CADENCE, IL EST TRANSPARENT : il rend son enfant tel quel et n'ajoute
/// aucun noeud visible a l'arbre.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/interstitiel_providers.dart';

/// Enveloppe l'application : a chaque changement d'ecran, la cadence est
/// consultee.
class PorteurDInterstitiel extends ConsumerStatefulWidget {
  /// [navigation] previent du changement d'ecran, [chemin] dit lequel.
  const PorteurDInterstitiel({
    super.key,
    required this.child,
    required this.navigation,
    required this.chemin,
  });

  /// L'arbre route, rendu tel quel.
  final Widget child;

  /// CE QUI PREVIENT QU'ON A CHANGE D'ECRAN.
  ///
  /// En production, c'est le delegue du routeur (`appRouter.routerDelegate`),
  /// qui est un `Listenable` et previent a chaque navigation.
  final Listenable navigation;

  /// OU SOMMES-NOUS, lu au moment ou l'on demande.
  ///
  /// Une fermeture et non une chaine : le chemin change APRES que la navigation
  /// a prevenu, et une valeur capturee a la construction serait toujours celle
  /// de l'ecran precedent.
  final String Function() chemin;

  @override
  ConsumerState<PorteurDInterstitiel> createState() =>
      _PorteurDInterstitielState();
}

class _PorteurDInterstitielState extends ConsumerState<PorteurDInterstitiel> {
  @override
  void initState() {
    super.initState();
    widget.navigation.addListener(_onNavigation);
  }

  @override
  void didUpdateWidget(PorteurDInterstitiel ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.navigation == widget.navigation) return;
    ancien.navigation.removeListener(_onNavigation);
    widget.navigation.addListener(_onNavigation);
  }

  @override
  void dispose() {
    widget.navigation.removeListener(_onNavigation);
    super.dispose();
  }

  /// UN ECRAN VIENT D'ARRIVER : on demande, on n'attend pas, on ne bloque rien.
  ///
  /// APRES LA FRAME, ET C'EST UNE CONTRAINTE DU FRAMEWORK. Le routeur previent
  /// ses auditeurs PENDANT qu'il reconstruit : lire un provider et ouvrir une
  /// vue plein ecran a cet instant, c'est demander un rendu en pleine phase de
  /// rendu — « setState() or markNeedsBuild() called during build », le defaut
  /// que la tache 601 a mesure quatre fois par bascule de sentier. La frame
  /// passee, l'ecran est pose et le chemin est le bon.
  ///
  /// RIEN N'EST ATTENDU PAR LA NAVIGATION : le geste part et rend la main tout
  /// de suite. Une publicite ne doit jamais faire patienter un ecran.
  ///
  /// ET LA FRAME EST DEMANDEE EXPLICITEMENT, SANS QUOI CE REPORT POUVAIT NE
  /// JAMAIS ARRIVER — defaut mesure en ecrivant le test de ce lot.
  /// `addPostFrameCallback` met une fermeture en file mais NE DEMANDE PAS de
  /// frame : si rien d'autre ne salit l'arbre, aucune frame n'est produite et
  /// la fermeture attend indefiniment. Le test l'a montre noir sur blanc —
  /// trois navigations, zero demande — parce qu'on ne dessine que si une frame
  /// a ete PROGRAMMEE.
  ///
  /// EN PRODUCTION LE DEFAUT EST LATENT PLUTOT QUE CERTAIN : une navigation
  /// reconstruit normalement l'arbre, donc une frame est deja programmee et la
  /// fermeture part. Mais « normalement » n'est pas une garantie, et un format
  /// qui prend tout l'ecran ne doit pas dependre de ce que quelqu'un d'autre
  /// salisse l'arbre au bon moment. `ensureVisualUpdate` rend le report
  /// DETERMINISTE : elle programme une frame s'il n'y en a pas, et ne fait rien
  /// s'il y en a deja une.
  void _onNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        ref.read(interstitielProvider).siLHeureEstVenue(widget.chemin()),
      );
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
