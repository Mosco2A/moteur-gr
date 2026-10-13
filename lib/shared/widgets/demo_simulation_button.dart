/// LA SIMULATION DE LA RANDONNEE, LA OU ON MARCHE (tache 638, bugs 11 et 16).
///
/// DEUX RETOURS DE TEST DU 30/09 SE RENCONTRENT ICI.
///   * Bug 11 (DEM-260930-1020) : « le bandeau du bas du mode demo cache une
///     partie de l appli ». La barre de simulation du lot 634 etait posee en bas
///     de TOUS les ecrans, en permanence, et masquait le bas de chacun. Elle est
///     supprimee ; ce bouton-ci prend sa place, et il ne s'affiche QUE la ou il
///     sert : le cockpit et la carte de navigation.
///   * Bug 16 (DEM-260930-1024) : « le bouton demarrer la rando doit etre
///     accessible en mode demo ! ». Le depart est desormais actif en demo
///     ([HubStartTrekButton]) et il lance une SIMULATION : c'est ce bouton-ci qui
///     la fait avancer, etape par etape, jusqu'a l'arrivee.
///
/// CE QU'IL FAIT, ET PAR QUEL CHEMIN. Il rejoue EXACTEMENT ce que fait le GPS a
/// l'arrivee d'une etape, par le meme chemin et sur le meme moteur :
///   * « Simuler l'etape suivante » appelle `recordStageCompleted` sur la
///     premiere etape du plan qui n'est pas encore faite ;
///   * quand il n'en reste plus, « Simuler l'arrivee » appelle
///     `completeOnArrival(fullyWalked: true)` — le geste exact du pont d'arrivee
///     sur le dernier `trailEnd`.
/// Aucune branche speciale dans le moteur : la demo emprunte le chemin de
/// production, et c'est la barriere d'ecriture qui fait la difference.
///
/// SEPT ETAPES, PAS DEUX (bug 8, DEM-260930-1014). La simulation parcourt le plan
/// du Mare a Mare Centre COMPLET : le sentier ampute du lot 601 n'existe plus.
///
/// RIEN DE CE QU'IL PROVOQUE N'EST ECRIT. La session simulee vit en memoire : les
/// deux persistances de session sont barrees en demo (`tracking_providers.dart`),
/// comme le journal, le sac, la trace GPS, le portefeuille et les droits. Et la
/// sortie de demo l'efface d'un bloc (`quitterLaDemo`).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/engine/trail_engine.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../features/map/map_facade.dart'
    show
        jalonsDesEtapesProvider,
        prochaineFinDEtape,
        stageDistanceCoveredProvider;
import '../../features/trek/providers/tracking_providers.dart';
import '../../i18n/translations.g.dart';
import 'app_button.dart';

/// Bouton « Simuler l'etape suivante » / « Simuler l'arrivee ».
///
/// INVISIBLE hors demo, et invisible en demo tant qu'aucune randonnee simulee
/// n'est en cours : il n'y a rien a faire avancer avant d'etre parti.
class DemoSimulationButton extends ConsumerWidget {
  const DemoSimulationButton({super.key, this.compact = false});

  /// Version compacte (barre de titre de la carte) : icone + libelle court.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return const SizedBox.shrink();

    final etat = ref.watch(trekSessionManagerProvider);
    final enMarche =
        etat.status == TrackingSessionStatus.recording ||
        etat.status == TrackingSessionStatus.paused;
    if (!enMarche) return const SizedBox.shrink();

    if (etat.session?.parcoursFullyWalked ?? false) {
      return const SizedBox.shrink();
    }

    // CE QUI RESTE A FRANCHIR SE LIT SUR LA TRACE, PLUS SUR UN COMPTEUR
    // (tache 747).
    //
    // Ce bouton se reglait sur `completedStages` — l'ensemble qu'il remplissait
    // lui-meme. Il etait donc le seul a savoir ou on en etait, et la carte n'en
    // voyait rien : retours de Christophe du 09/10, « la fleche orange ... ne
    // fonctionne pas » et « simuler ne fonctionne pas du tout ». Il lit
    // desormais la MEME chose que la barre et la carte : l'abscisse du marcheur
    // sur la trace, et les bornes des etapes.
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final jalons = ref.watch(jalonsDesEtapesProvider(trailId));
    final abscisseM = ref.watch(stageDistanceCoveredProvider);
    final ilResteUneEtape = prochaineFinDEtape(jalons, abscisseM) != null;

    final String libelle;
    final VoidCallback geste;
    final notifier = ref.read(trekSessionManagerProvider.notifier);
    if (ilResteUneEtape) {
      libelle = t.demo.simulerEtape;
      // IL DEPLACE LE MARCHEUR, et c'est pour cela qu'on le voit : nom
      // d'etape, cinq chiffres, point bleu et cadrage se deduisent tous de
      // l'abscisse qu'il vient de changer.
      geste = notifier.simulerLEtapeSuivante;
    } else {
      libelle = t.demo.simulerFin;
      geste = () => notifier.completeOnArrival(fullyWalked: true);
    }

    if (compact) {
      // PAS DE BULLE D'AIDE ICI, ET CE N'EST PAS UN OUBLI D'ERGONOMIE
      // (tache 838, defaut mesure en ecrivant le test du volet D4).
      //
      // CE QUI A ETE MESURE, MOT POUR MOT, en montant l'application reelle
      // avec une marche simulee en cours :
      //
      //     The following assertion was thrown building RawTooltip(...):
      //     No Overlay widget found.
      //     RawTooltip widgets require an Overlay widget ancestor within the
      //     closest LookupBoundary.
      //     The relevant error-causing widget was:
      //       IconButton-[<'demo-simuler'>]
      //
      // LA CAUSE EST CELLE DE LA TACHE 637, AU MEME ENDROIT DE L'ARBRE. Cette
      // variante compacte etait concue pour la BARRE DE TITRE DE LA CARTE, donc
      // SOUS le `Navigator` — ou un `Overlay` existe. La tache 747 l'a deplacee
      // dans le bandeau de demonstration (`MentionMarcheSimulee`, passee a
      // `CadreDemo.sousLeBandeau`), c'est-a-dire dans le `builder` de
      // `MaterialApp.router` : AU-DESSUS du `Navigator`, ou il n'y a aucun
      // `Overlay`. Un `IconButton` qui recoit un `tooltip` se fabrique une
      // `Tooltip`, et une `Tooltip` sans `Overlay` ne peut pas se construire.
      //
      // C'est la MEME famille que le « Quitter » muet du build 8 (tache 649) :
      // un widget pose au-dessus du `Router` qui reclame ce qui ne vit qu'en
      // dessous. On ne corrige donc pas en remontant un `Overlay` jusqu'ici —
      // on retire ce qui ne peut pas marcher a cet endroit.
      //
      // ET LA PORTEE EST CELLE-CI, SANS EXAGERATION : `debugCheckHasOverlay`
      // est une assertion, donc retiree en release. Un paquet installe ne
      // plante pas pour autant — la bulle d'aide y echoue en silence au lieu de
      // s'afficher. Le defaut est donc visible en debug et muet en release, ce
      // qui est exactement la facon dont il a pu vivre sans etre vu.
      //
      // LE LIBELLE N'EST PAS PERDU : il part en semantique, donc il reste
      // annonce par les lecteurs d'ecran — c'est ce que la bulle apportait
      // vraiment, l'icone etant deja a cote de la phrase « marche simulee »
      // qui la nomme.
      return Semantics(
        label: libelle,
        button: true,
        child: IconButton(
          key: const ValueKey('demo-simuler'),
          onPressed: geste,
          icon: const StepIcon(
            StepwaysIcons.flecheAvant,
            size: 22,
            color: AppTheme.orangeDifficile,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingSm),
      child: SizedBox(
        width: double.infinity,
        child: AppButton(
          key: const ValueKey('demo-simuler'),
          variant: AppButtonVariant.filledTone,
          tone: AppTheme.orangeDifficile,
          icon: StepwaysIcons.flecheAvant,
          label: libelle,
          onPressed: geste,
        ),
      ),
    );
  }
}
