/// LE SIGNAL DE LA DEMO ET SA SORTIE : UNE PASTILLE ORANGE, EN HAUT, ET RIEN
/// D'AUTRE (tache 638, bug 11 — DEM-260930-1020).
///
/// Retour de test de Christophe du 30/09 10:20, verbatim : « le bandeau du bas du
/// mode demo cache une partie de l appli. En haut un Quitter orange suffirait et
/// il ne faut pas qu il pete le visuel de la page ».
///
/// CE QU'IL Y AVAIT, ET CE QUI PART. Le lot 634 posait TROIS choses par-dessus
/// l'arbre route : un liston orange de 5 px sur les quatre bords, une pastille de
/// sortie en haut, et une BARRE DE SIMULATION en bas (« Simuler l'etape
/// suivante » + la phrase « rien n'est enregistre »). La barre du bas masquait le
/// bas de chaque ecran — c'est le defaut signale — et le liston rognait les
/// bords. Les deux disparaissent :
///   * `barre_simulation_demo.dart` est SUPPRIME. La simulation vit desormais
///     dans le cockpit et sur la carte ([BoutonSimulationDemo]), la ou le
///     randonneur regarde quand il marche ;
///   * le liston orange est SUPPRIME. Il ne reste qu'une pastille.
///
/// OU SE POSE LA PASTILLE, ET POURQUOI LA. Elle est peinte par-dessus l'arbre
/// route (`Stack`), donc AUCUN ecran n'est deplace d'un pixel : ni marge, ni
/// `SafeArea` ajoutee, ni encoche faussee. Elle est CENTREE EN HAUT, a la hauteur
/// de la barre de titre :
///   * a gauche de la barre vit le RETOUR, a droite les ACTIONS et l'ACCUEIL —
///     tous actifs. La pastille ne les atteint jamais : elle est centree et
///     bornee en largeur, et un test le mesure sur les trois tailles de
///     reference (iPhone SE 375x667, petit Android 360x640, Pixel 5 393x851) ;
///   * au centre il n'y a que le TITRE de l'ecran, qui ne se touche pas. C'est
///     le seul endroit de l'ecran ou l'on peut poser un signal permanent sans
///     recouvrir une commande.
/// Le titre cede donc sa place au signal pendant la demo, et c'est un echange
/// voulu : le bug 19 disait « on est toujours en mode demo sans le savoir » — le
/// signal doit etre a l'endroit que l'oeil balaie en premier.
///
/// LA SORTIE PASSE PAR UN DIALOGUE, ET IL PORTE LA CASE A COCHER (bug 18,
/// precision de Christophe du 30/09 10:30) : « Cacher le mode demo ». Cochee, le
/// bouton orange quitte le catalogue et se retrouve dans Mon compte ; decochee,
/// il reste en tete du catalogue. Le message dit OU la retrouver, et il change
/// avec la case — jamais une phrase qui annonce autre chose que ce que le reglage
/// va faire.
///
/// HORS DEMO, CE WIDGET EST TRANSPARENT : il rend son enfant tel quel, sans
/// ajouter le moindre noeud a l'arbre.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/pilote_demo.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';

/// Largeur MAXIMALE de la pastille de sortie, en pixels logiques.
///
/// Bornee pour ne jamais atteindre les zones actives de la barre de titre : le
/// retour occupe les 56 px de gauche, l'accueil et les actions les 56 px (ou
/// plus) de droite. 180 px centres laissent au moins 90 px de marge de chaque
/// cote sur la plus petite largeur de reference (360 px).
const double kLargeurMaxPastilleDemo = 180;

/// Decalage vertical de la pastille sous le haut de la zone sure.
///
/// La barre de titre Material fait 56 px de haut ; la pastille en fait environ
/// 30 : 13 px la centrent dessus.
const double kDecalagePastilleDemo = 13;

/// Enveloppe l'arbre route : pendant la demo, une pastille « Quitter » orange.
class CadreDemo extends ConsumerWidget {
  const CadreDemo({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return child;

    return Stack(
      children: [
        Positioned.fill(child: child),
        // LA SORTIE, TOUJOURS VISIBLE, ET SEULE. Centree en haut, bornee en
        // largeur : elle ne recouvre ni le retour ni les actions d'en-tete.
        Positioned(
          top: kDecalagePastilleDemo,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: kLargeurMaxPastilleDemo,
                ),
                child: const _PastilleDeSortie(),
              ),
            ),
          ),
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
    return Material(
      color: AppTheme.orangeDifficile,
      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      elevation: 3,
      child: InkWell(
        key: const ValueKey('demo-sortie'),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        onTap: () => afficherSortieDeDemo(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const StepIcon(
                StepwaysIcons.eprouvette,
                size: 14,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  t.demo.bandeau,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                t.demo.quitter,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  decoration: TextDecoration.underline,
                  decorationColor: Colors.white,
                ),
              ),
              const SizedBox(width: 3),
              const StepIcon(
                StepwaysIcons.croix,
                size: 12,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// LE DIALOGUE DE FIN DE DEMO : ou la retrouver, et veut-on la cacher.
///
/// Un seul endroit dans l'application demande a quitter la demo, et c'est lui :
/// il porte le message du bug 18 et la case a cocher du 30/09 10:30. La sortie
/// elle-meme est faite par [quitterLaDemo] (bug 19, atomique).
Future<void> afficherSortieDeDemo(BuildContext context, WidgetRef ref) async {
  final choix = await showDialog<bool>(
    context: context,
    builder: (ctx) => const _DialogueSortieDemo(),
  );
  if (choix == null || !context.mounted) return;
  // `choix` porte la case a cocher : on ne quitte que si le dialogue a ete
  // confirme (il rend `null` sur annulation).
  await quitterLaDemo(ref, context: context, cacherBouton: choix);
}

class _DialogueSortieDemo extends StatefulWidget {
  const _DialogueSortieDemo();

  @override
  State<_DialogueSortieDemo> createState() => _DialogueSortieDemoState();
}

class _DialogueSortieDemoState extends State<_DialogueSortieDemo> {
  bool _cacher = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      key: const ValueKey('demo-dialogue-sortie'),
      icon: const StepIcon(StepwaysIcons.eprouvette),
      title: Text(t.demo.sortieTitre),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LE MESSAGE SUIT LA CASE : cochee, la demo se retrouve dans Mon
          // compte ; decochee, en tete du catalogue. Un message fixe mentirait
          // dans l'un des deux cas.
          Text(
            _cacher ? t.demo.sortieDansMonCompte : t.demo.sortieEnTeteCatalogue,
            key: const ValueKey('demo-sortie-message'),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          CheckboxListTile(
            key: const ValueKey('demo-sortie-cacher'),
            value: _cacher,
            onChanged: (v) => setState(() => _cacher = v ?? false),
            title: Text(t.demo.cacherLabel),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          key: const ValueKey('demo-sortie-annuler'),
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.demo.sortieAnnuler),
        ),
        FilledButton(
          key: const ValueKey('demo-sortie-confirmer'),
          onPressed: () => Navigator.of(context).pop(_cacher),
          child: Text(t.demo.sortieConfirmer),
        ),
      ],
    );
  }
}
