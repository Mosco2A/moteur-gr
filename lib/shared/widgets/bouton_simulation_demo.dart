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
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../features/trek/providers/gps_providers.dart';
import '../../features/trek/providers/tracking_providers.dart';
import '../../i18n/translations.g.dart';
import 'app_button.dart';

/// Bouton « Simuler l'etape suivante » / « Simuler l'arrivee ».
///
/// INVISIBLE hors demo, et invisible en demo tant qu'aucune randonnee simulee
/// n'est en cours : il n'y a rien a faire avancer avant d'etre parti.
class BoutonSimulationDemo extends ConsumerWidget {
  const BoutonSimulationDemo({super.key, this.compact = false});

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

    final plan = ref.watch(currentTrekPlanProvider);
    if (plan == null) return const SizedBox.shrink();
    if (etat.session?.parcoursFullyWalked ?? false) {
      return const SizedBox.shrink();
    }

    final faites = etat.session?.completedStages.toSet() ?? const <String>{};
    final restantes = <String>[
      for (final id in plan.orderedStageIds)
        if (!faites.contains(id)) id,
    ];

    final String libelle;
    final VoidCallback geste;
    if (restantes.isNotEmpty) {
      final prochaine = restantes.first;
      libelle = t.demo.simulerEtape;
      geste = () => ref
          .read(trekSessionManagerProvider.notifier)
          .recordStageCompleted(prochaine);
    } else {
      libelle = t.demo.simulerFin;
      geste = () => ref
          .read(trekSessionManagerProvider.notifier)
          .completeOnArrival(fullyWalked: true);
    }

    if (compact) {
      return IconButton(
        key: const ValueKey('demo-simuler'),
        onPressed: geste,
        tooltip: libelle,
        icon: const StepIcon(
          StepwaysIcons.flecheAvant,
          size: 22,
          color: AppTheme.orangeDifficile,
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
