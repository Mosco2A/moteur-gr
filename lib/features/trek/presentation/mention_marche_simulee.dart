/// LA MENTION « MARCHE SIMULEE », SOUS LE BANDEAU DE DEMO, PENDANT TOUTE LA
/// MARCHE SIMULEE (tache 742).
///
/// POURQUOI ELLE EXISTE. La demonstration fait avancer un randonneur sur le
/// sentier en ACCELERANT LE TEMPS : une seconde d'ecran vaut une minute de
/// marche. Les chiffres qui montent sont donc justes — ils sont mesures par le
/// meme moteur qu'en randonnee, sur des releves coherents — mais ils decrivent
/// une marche QUI N'A PAS EU LIEU. Personne ne doit croire a une vraie marche,
/// et le bandeau « MODE DEMO » seul ne le dit pas : il dit qu'on visite
/// l'application, pas que ces kilometres sont simules ni que le temps court
/// soixante fois plus vite. Cette ligne le dit, et elle porte le facteur en
/// clair.
///
/// POURQUOI UNE LIGNE A PART, ET PAS UN MOT DE PLUS DANS LE BANDEAU. Le bandeau
/// partage deja sa largeur entre son libelle et le « Quitter » : sur un
/// telephone etroit, y ajouter cette phrase aurait tronque l'un ou l'autre. Et
/// il est TESTE AU TEXTE (`persona_s8_demo_test.dart` cherche `t.demo.bandeau`)
/// — le laisser intact evite de troquer un signal contre un autre. Les deux
/// coexistent donc, l'un au-dessus de l'autre.
///
/// POURQUOI ELLE VIT DANS `trek` ET PAS A COTE DU BANDEAU. Le bandeau est dans
/// `shared/`, et le socle ne connait pas ses clients (ARB-645-05-a) : lire
/// l'etat du marcheur depuis la-bas aurait ajoute une fleche du socle vers une
/// feature, celle que `couches_respectees_645_test.dart` plafonne — et ce
/// plafond est atteint. Elle est donc posee ici, ou lire le marcheur est
/// naturel, et c'est `main.dart` qui la donne au cadre
/// (`CadreDemo.sousLeBandeau`).
///
/// ELLE NE PREND AUCUNE PLACE QUAND RIEN NE MARCHE : hors demo et tant que la
/// simulation n'avance pas, elle rend `SizedBox.shrink()`. La hauteur poussee a
/// l'application reste celle que le lot 649 a mesuree.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/demo_simulation_button.dart';
import '../data/marcheur_simule_providers.dart';

/// La ligne d'honnetete de la marche simulee, au-dessus de tous les ecrans.
class MentionMarcheSimulee extends ConsumerWidget {
  /// Invisible hors demo et hors simulation en cours.
  const MentionMarcheSimulee({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return const SizedBox.shrink();

    // ELLE SUIT LA MARCHE, PAS LA SESSION. En pause, la marche ne progresse
    // plus mais elle n'est pas terminee et les chiffres a l'ecran restent ceux
    // d'une simulation : la mention doit rester. Elle disparait a l'arrivee et
    // a l'arret, quand plus aucun chiffre ne bouge.
    final etat = ref.watch(etatDuMarcheurSimuleProvider);
    if (etat != EtatDuMarcheur.enMarche && etat != EtatDuMarcheur.enPause) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Material(
      key: const ValueKey('demo-marche-simulee'),
      color: AppTheme.orangeDifficile.withValues(alpha: 0.16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingSm + 4,
          vertical: 3,
        ),
        child: Row(
          children: [
            const StepIcon(
              StepwaysIcons.eprouvette,
              size: 13,
              color: AppTheme.orangeDifficile,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                t.demo.marcheSimulee(facteur: MarcheurSimule.kFacteurTemps),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.orangeDifficile,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // LA COMMANDE DE SIMULATION EST ICI, ET NULLE PART AILLEURS SUR LA
            // CARTE (tache 747).
            //
            // Retour de Christophe du 09/10 08:48 : « bouton simuler l'etape
            // suivant mal place ». Elle etait dans l'en-tete de la carte, au
            // milieu des commandes de TERRAIN (SOS, photo, calques, zoom,
            // guide) — comme si faire avancer une demonstration etait un outil
            // de navigation. Ce bandeau, lui, ne parle QUE de la
            // demonstration : il dit deja « marche simulee, temps accelere ».
            // La commande qui fait avancer cette marche est a sa place a cote
            // de cette phrase, et elle disparait avec elle.
            const DemoSimulationButton(compact: true),
          ],
        ),
      ),
    );
  }
}
