/// LA REGLE DES ECRANS EN DEMO : ACTIF ET IDENTIQUE, OU GRISE ET VISIBLEMENT
/// INDISPONIBLE (tache 638, bug 14 — DEM-260930-1022).
///
/// Retour de test de Christophe du 30/09 10:22, verbatim : « sac ne fonctionne pas
/// en mode demo, laisser 2 menus et griser les autres sinon le comportement doit
/// rester le meme ».
///
/// LE DEFAUT MESURE. Le lot 634 avait pose la barriere d'ecriture DANS LES
/// PROVIDERS : `if (ref.read(enDemoProvider)) return;`. Cote ecran, rien n'avait
/// change — la case a cocher du sac, l'ajout d'article, le poids, la liste de
/// courses avaient tous l'air ACTIFS. On appuyait, et il ne se passait
/// strictement rien : ni effet, ni message. L'ecran paraissait casse, et c'est
/// exactement ce que Christophe a vu.
///
/// LA REGLE, DONC, ET ELLE N'A QUE DEUX BRANCHES :
///   * ACTIVE — la fonction se comporte EXACTEMENT comme en reel. Le changement
///     vit en memoire et il est jete a la sortie de la demo. C'est le cas des
///     coches du sac, du programme, de la date de depart, de la simulation.
///   * GRISEE — la fonction est visiblement indisponible, et elle DIT pourquoi
///     si on insiste. C'est le cas de tout ce qui engage de l'argent, des droits,
///     un fichier sur le telephone ou une donnee de personne.
/// Il n'y a pas de troisieme branche. Un bouton qui a l'air actif et ne fait rien
/// est un mensonge, et c'est le defaut que ce widget interdit.
///
/// CE WIDGET GRISE, IL NE BARRE PAS. La barriere d'ecriture reste ou elle est
/// (dans les providers) : elle est le dernier rempart, et elle doit survivre a un
/// ecran qui oublierait de griser. Ce widget est le PREMIER rempart, celui que le
/// randonneur voit.
///
/// HORS DEMO, IL EST TRANSPARENT : il rend son enfant tel quel.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/session_demo.dart';
import '../../i18n/translations.g.dart';

/// Opacite d'une fonction grisee — la meme que le gris « desactive » de Material
/// et que celui de [QuickAccessCard] (0.38), pour que l'indisponible ait UN seul
/// visage dans toute l'application.
const double kOpaciteGriseeDemo = 0.38;

/// Grise [child] pendant une demo, sauf si [actif].
///
/// [actif] existe pour les ecrans ou une PARTIE des fonctions reste vivante : le
/// sac garde ses coches actives et grise le reste, et c'est le meme widget qui
/// porte les deux cas — on lit la regle sur place.
class GriseEnDemo extends ConsumerWidget {
  const GriseEnDemo({super.key, required this.child, this.actif = false});

  final Widget child;

  /// La fonction reste ACTIVE en demo (comportement identique au reel).
  final bool actif;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (actif || !ref.watch(enDemoProvider)) return child;
    return Semantics(
      enabled: false,
      label: t.demo.indisponible,
      child: Opacity(
        opacity: kOpaciteGriseeDemo,
        child: Stack(
          children: [
            // L'enfant ne recoit plus aucun geste : il est grise, donc inerte.
            IgnorePointer(child: child),
            // ... mais un appui DIT pourquoi, plutot que de ne rien faire.
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => direIndisponibleEnDemo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dit, en une ligne, qu'une fonction est indisponible pendant la demo.
///
/// Expose separement pour les ecrans dont le bouton est deja grise par Material
/// (`onPressed: null`) et qui veulent quand meme expliquer, ou pour ceux dont la
/// mise en page ne supporte pas d'enveloppe.
void direIndisponibleEnDemo(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        key: const ValueKey('demo-indisponible'),
        content: Text(t.demo.indisponible),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
