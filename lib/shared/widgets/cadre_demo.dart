/// LE TOUR DE L'ECRAN DEVIENT ORANGE (tache 634, DEM-260929-1123).
///
/// Retour de Christophe du 29/09 11:23, verbatim : « il faut mettre demo en
/// haut des sentiers juste un bouton "paasez en mode demo", le tour des ecran
/// devient orange ». Et, precise ensuite : pendant la demo, « un moyen de
/// sortir est toujours visible ».
///
/// CE QUI SIGNALAIT LA DEMO AVANT : RIEN, MESURE. Le depot portait bien un
/// bandeau « Mode demo — touchez pour debloquer » ([PurchaseGateWidget]), mais
/// son propre en-tete disait deja qu'il n'etait « MONTE NULLE PART DANS lib/ » :
/// il n'existait qu'en test. Sur le telephone de Christophe, un sentier non
/// achete ouvrait son cockpit avec la publicite et pas un mot d'explication.
///
/// POURQUOI UN `Stack` ET NON UN CADRE QUI PREND DE LA PLACE. Un `Padding` ou
/// une `SafeArea` autour de l'arbre route decalerait chaque ecran de quelques
/// pixels et fausserait les encoches que les `Scaffold` calculent eux-memes.
/// Le cadre est donc PEINT PAR-DESSUS, dans un `IgnorePointer` : aucun ecran
/// n'est deplace d'un pixel, et aucun geste n'est intercepte. Seule la pastille
/// de sortie recoit les taps.
///
/// HORS DEMO, CE WIDGET EST TRANSPARENT : il rend son enfant tel quel, sans
/// ajouter le moindre noeud a l'arbre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import 'barre_simulation_demo.dart';
import '../../i18n/translations.g.dart';

/// Epaisseur du liston orange, en pixels logiques.
///
/// Assez large pour se voir d'un coup d'oeil sur un telephone tenu a bout de
/// bras, assez fin pour ne rien masquer de l'ecran.
const double kEpaisseurCadreDemo = 5;

/// Enveloppe l'arbre route : cadre orange et sortie visible pendant la demo.
class CadreDemo extends ConsumerWidget {
  const CadreDemo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return child;

    return Stack(
      children: [
        Positioned.fill(child: child),

        // LE TOUR DE L'ECRAN. Peint par-dessus, sans rien deplacer, et sans
        // intercepter le moindre geste.
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('demo-cadre'),
              decoration: BoxDecoration(
                border: Border.all(
                  color: AppTheme.orangeDifficile,
                  width: kEpaisseurCadreDemo,
                ),
              ),
            ),
          ),
        ),

        // LA SORTIE, TOUJOURS VISIBLE. En haut au centre : c'est la zone que
        // le regard balaie en premier, et elle ne recouvre ni le retour (en
        // haut a gauche) ni les actions d'en-tete (en haut a droite).
        const Positioned(
          top: kEpaisseurCadreDemo,
          left: 0,
          right: 0,
          child: SafeArea(bottom: false, child: _PastilleDeSortie()),
        ),

        // LA SIMULATION DU TREK, EN BAS. « simuler le trek ca serait bien »
        // (Christophe, 29/09) : c'est ce qui permet de montrer l'application de
        // A a Z sans marcher. Elle porte aussi la phrase qui doit rester sous
        // les yeux du randonneur : rien de ce qu'il fait ici n'est enregistre.
        const Positioned(
          left: kEpaisseurCadreDemo,
          right: kEpaisseurCadreDemo,
          bottom: kEpaisseurCadreDemo,
          child: BarreSimulationDemo(),
        ),
      ],
    );
  }
}

class _PastilleDeSortie extends ConsumerWidget {
  const _PastilleDeSortie();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Center(
      child: Material(
        color: AppTheme.orangeDifficile,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        elevation: 3,
        child: InkWell(
          key: const ValueKey('demo-sortie'),
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          onTap: () => ref.read(sessionDemoProvider.notifier).sortir(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const StepIcon(
                  StepwaysIcons.eprouvette,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  t.demo.bandeau,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  t.demo.quitter,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    decoration: TextDecoration.underline,
                    decorationColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 4),
                const StepIcon(
                  StepwaysIcons.croix,
                  size: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
