/// LE SIGNAL DE LA DEMO ET SA SORTIE : UN BANDEAU ORANGE QUI PREND SA PROPRE
/// PLACE, ET UN « QUITTER » QUI REPOND DU PREMIER APPUI (tache 649).
///
/// ---------------------------------------------------------------------------
/// CE QUE CHRISTOPHE A VU SUR LE BUILD 8, ET LES DEUX DEFAUTS MESURES
/// ---------------------------------------------------------------------------
///
/// Passage sur emulateur du 30/09 (AAB 0.1.4+8, build release) :
///   1. la pastille orange RECOUVRAIT le titre de la barre sur tous les ecrans
///      — et, sur le cockpit, elle mordait aussi sur l'action « infos » ;
///   2. son « Quitter » ne repondait a AUCUN appui — trois appuis, deux
///      positions, deux ecrans, alors que tous les autres appuis marchaient.
///
/// LE BOUTON MUET, CAUSE MESUREE ET NON SUPPOSEE. A chaque appui, l'emulateur
/// n'ecrivait qu'une ligne : « FirebaseCrashlytics: Timeout exceeded while
/// awaiting app exception callback from Analytics listener ». L'appui ARRIVAIT
/// donc bien, une exception etait levee, Crashlytics l'enregistrait, et rien ne
/// s'affichait. Le harnais de `sortie_de_demo_649_test.dart` la nomme :
///
///     Navigator operation requested with a context that does not include a
///     Navigator.
///       Navigator.of         (navigator.dart:2936)
///       showDialog           (dialog.dart:1504)
///       afficherSortieDeDemo (cadre_demo.dart:169)
///       _PastilleDeSortie.build.<anonymous>  (cadre_demo.dart:117)
///       _InkResponseState.handleTap
///
/// C'EST LE DEFAUT DE LA TACHE 637, AU MEME ENDROIT DE L'ARBRE. `CadreDemo` est
/// pose dans le `builder` de `MaterialApp.router` (`main.dart`), et `WidgetsApp`
/// passe le `Router` EN ARGUMENT de ce `builder` : tout ce que le `builder`
/// enveloppe est AU-DESSUS du `Navigator` de GoRouter. `showDialog` remonte les
/// ANCETRES a la recherche d'un `Navigator` ; au-dessus du `Router`, il n'y en a
/// aucun. Le dialogue de fin de demo ne pouvait donc JAMAIS s'ouvrir. En debug
/// c'est l'assertion de `navigator.dart:2929` qui parle ; en release elle est
/// retiree et il ne reste que le `!` de la ligne 2936 — meme chemin, meme cause,
/// et un bouton mort sans un mot.
///
/// ---------------------------------------------------------------------------
/// CE QUE CE FICHIER FAIT MAINTENANT
/// ---------------------------------------------------------------------------
///
/// 1. LA SORTIE TIENT EN UN APPUI, ET NE PASSE PLUS PAR UN DIALOGUE. Il n'y a
///    plus de `showDialog` du tout : l'appui appelle [quitterLaDemo], qui est
///    deja la sortie atomique du lot 638 (six gestes) et finit par revenir a
///    « Mes treks ». Un dialogue depuis ce contexte etait, par construction,
///    impossible a ouvrir ; le supprimer n'est donc pas un choix de confort,
///    c'est la seule forme qui marche a cet endroit de l'arbre.
///
/// 2. LE CHOIX « CACHER LE MODE DEMO » N'EST PAS PERDU (bug 18, precision de
///    Christophe du 30/09 10:30). Il est propose APRES la sortie, dans un
///    bandeau de message qui ne bloque rien : on est deja sur « Mes treks »
///    quand la question se pose, et on peut l'ignorer. Il reste reversible dans
///    Mon compte, comme avant.
///
/// 3. LE BANDEAU PREND SA PROPRE PLACE — IL NE RECOUVRE PLUS RIEN. C'est le
///    changement de forme qui repond au defaut 1. L'ancienne pastille etait
///    PEINTE par-dessus l'arbre route (`Stack`) : elle ne deplacait rien, mais
///    elle masquait forcement ce qu'il y avait dessous, et au centre de la barre
///    il y a le TITRE. Le lot 638 assumait cet echange ; Christophe l'a refuse.
///    Le bandeau est donc pose AU-DESSUS de l'application, dans une `Column` :
///    il pousse l'ecran de sa hauteur au lieu de le couvrir, et plus un seul
///    pixel de l'application ne disparait. La barre de titre garde son titre,
///    son retour et ses actions, entiers.
///
///    LE DECALAGE EST LE PRIX, ET IL EST ASSUME : mieux vaut une application
///    poussee de [kHauteurBandeauDemo] pixels pendant la demo qu'un titre
///    illisible. Le haut de la zone sure est retire au sous-arbre
///    (`MediaQuery.removePadding`) : sans cela, l'application ajouterait une
///    SECONDE fois la marge de la barre d'etat, deja mangee par le bandeau.
///
/// HORS DEMO, CE WIDGET RESTE TRANSPARENT : il rend son enfant tel quel, sans
/// ajouter le moindre noeud a l'arbre.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/pilote_demo.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';

/// Hauteur UTILE du bandeau de demo, hors marge de la barre d'etat.
///
/// 44 px : la taille de cible tactile recommandee. Le « Quitter » du build 8
/// etait dans une pastille de 30 px de haut, centree sur la barre de titre — et
/// c'est cette meme hauteur qui la faisait chevaucher le titre.
const double kHauteurBandeauDemo = 44;

/// Largeur MAXIMALE du bouton de sortie, en pixels logiques.
///
/// Conserve du lot 638 : le bouton reste borne, meme quand la police du
/// telephone est agrandie. Il n'a plus a se tenir loin des bords — il ne
/// partage plus sa ligne avec la barre de titre.
const double kLargeurMaxPastilleDemo = 180;

/// Enveloppe l'arbre route : pendant la demo, un bandeau orange en tete.
class CadreDemo extends ConsumerWidget {
  const CadreDemo({super.key, required this.child, this.sousLeBandeau});

  final Widget child;

  /// CE QUE LA DEMO AJOUTE SOUS LE BANDEAU, quand elle a quelque chose a dire
  /// (tache 742 : la mention « marche simulee » pendant la simulation).
  ///
  /// POURQUOI UN PARAMETRE ET PAS UN IMPORT. Ce fichier vit dans `shared/`, et
  /// le socle ne connait pas ses clients (ARB-645-05-a) : importer un widget de
  /// `features/trek` depuis ici aurait ajoute une fleche du socle vers une
  /// feature, celle que la garde `couches_respectees_645_test.dart` plafonne —
  /// elle est a son plafond, et on n'assouplit pas une garde pour poser un
  /// libelle. Le bandeau ne sait donc pas CE QU'il montre ; `main.dart`, qui
  /// compose l'application et n'est ni `core`, ni `shared`, ni une feature, le
  /// lui donne.
  ///
  /// Nul par defaut : le cadre reste alors exactement celui du lot 649, et la
  /// hauteur poussee a l'application ne change pas d'un pixel.
  final Widget? sousLeBandeau;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return child;

    return Column(
      children: [
        const _BandeauDemo(),
        if (sousLeBandeau != null) sousLeBandeau!,
        Expanded(
          // LE HAUT DE LA ZONE SURE EST DEJA MANGE PAR LE BANDEAU. Sans ce
          // retrait, chaque `Scaffold` du dessous ajouterait une seconde fois
          // la marge de la barre d'etat, et l'application descendrait deux fois
          // trop bas.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: child,
          ),
        ),
      ],
    );
  }
}

/// LE BANDEAU : le signal a gauche, la sortie a droite, et rien dessous.
class _BandeauDemo extends StatelessWidget {
  const _BandeauDemo();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('demo-bandeau'),
      color: AppTheme.orangeDifficile,
      // L'ORANGE MONTE JUSQUE DERRIERE LA BARRE D'ETAT — « en demo le tour de
      // l'ecran devient orange » — mais le CONTENU, lui, reste sous les icones
      // du systeme.
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kHauteurBandeauDemo,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSm + 4,
            ),
            child: Row(
              children: [
                const StepIcon(
                  StepwaysIcons.eprouvette,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    t.demo.bandeau,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: kLargeurMaxPastilleDemo,
                  ),
                  child: const _BoutonDeSortie(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LE « QUITTER » : blanc sur orange, et il sort du premier appui.
class _BoutonDeSortie extends ConsumerWidget {
  const _BoutonDeSortie();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      child: InkWell(
        key: const ValueKey('demo-sortie'),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        onTap: () => sortirDeLaDemoDUnAppui(ref, context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  t.demo.quitter,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppTheme.orangeDifficile,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const StepIcon(
                StepwaysIcons.croix,
                size: 13,
                color: AppTheme.orangeDifficile,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LA SORTIE D'UN SEUL APPUI, ET L'OFFRE QUI NE BLOQUE PAS (tache 649).
///
/// Un appui, et c'est fini : [quitterLaDemo] coupe la demo, remet le sentier
/// d'avant, jette ce qui n'a vecu qu'en memoire et ramene a « Mes treks ». La
/// question « cacher le bouton demo ? » (bug 18) est posee APRES, dans un
/// bandeau de message, et le randonneur peut l'ignorer.
///
/// LE MESSAGER ET LE CONTENEUR SONT PRIS AVANT LA SORTIE, ET C'EST LE POINT
/// DELICAT : des que la demo s'arrete, [CadreDemo] rend son enfant tel quel et
/// ce bouton est DEMONTE. Son `context` et son `ref` ne valent plus rien apres.
/// Le messager (`ScaffoldMessengerState`) et le conteneur Riverpod, eux, vivent
/// au-dessus de toute l'application : ils survivent a ce demontage.
Future<void> sortirDeLaDemoDUnAppui(WidgetRef ref, BuildContext context) async {
  final messager = ScaffoldMessenger.maybeOf(context);
  final conteneur = ProviderScope.containerOf(context, listen: false);

  await quitterLaDemo(ref, context: context);

  if (messager == null) return;
  messager.hideCurrentSnackBar();
  final controleur = messager.showSnackBar(
    SnackBar(
      key: const ValueKey('demo-sortie-faite'),
      content: Text(t.demo.sortieFaite),
      duration: kDureeMessageSortieDemo,
      action: SnackBarAction(
        label: t.demo.cacherLabel,
        onPressed: () =>
            conteneur.read(boutonDemoCacheProvider.notifier).definir(true),
      ),
    ),
  );

  // LE MESSAGE SE FERME TOUT SEUL, ET C'EST NOUS QUI LE FERMONS — MESURE.
  //
  // Sur l'emulateur, le message pose juste apres le changement d'ecran est
  // reste affiche DEUX MINUTES : `ScaffoldMessenger` n'arme son minuteur de
  // fermeture qu'a la fin de l'animation d'entree, et cette animation est
  // interrompue par la transition de route qui part au meme instant. Le
  // `duration` ci-dessus n'a donc jamais ete lu.
  //
  // UN BANDEAU QUI NE PART PAS EST EXACTEMENT LE BUG 11 : « le bandeau du bas
  // du mode demo cache une partie de l'appli ». On ne s'en remet donc pas au
  // cadre : on ferme nous-memes.
  //
  // LE MINUTEUR EST ANNULE DES QUE LE MESSAGE SE FERME, d'ou qu'il vienne — le
  // randonneur a repondu, il l'a balaye, ou un autre message l'a chasse. C'est
  // ce qui interdit de fermer deux fois, et ce qui evite de laisser un minuteur
  // courir derriere un message qui n'existe plus.
  final minuteur = Timer(kDureeMessageSortieDemo, controleur.close);
  unawaited(controleur.closed.then((_) => minuteur.cancel()));
}

/// Duree d'affichage du message de fin de demo.
const Duration kDureeMessageSortieDemo = Duration(seconds: 6);
