/// LA SIMULATION DU TREK, PENDANT LA DEMO (tache 634, DEM-260929-1123).
///
/// Christophe, le 29/09 : « un bouton demo qui montre comment marche l appli de
/// A a Z » ; « simuler le trek ca serait bien » ; « le randonneur avance sur
/// les etapes sans GPS, voit le journal, le sac, la faisabilite, l arrivee ».
///
/// CE QUI MANQUAIT, MESURE. Avancer d'une etape n'etait possible que PAR LE
/// GPS : `TrekSessionManagerNotifier.recordStageCompleted` n'avait qu'UN SEUL
/// appelant dans tout le depot, le pont d'arrivee
/// (`arrivalCompletionListenerProvider`), lui-meme alimente par le flux de
/// positions. Il n'existait aucun geste manuel, aucun ecran de debug, aucune
/// triche : on ne pouvait donc PAS montrer une randonnee sans marcher.
///
/// CE QUE FAIT CETTE BARRE. Elle rejoue EXACTEMENT ce que fait le GPS a
/// l'arrivee d'une etape, par le meme chemin et sur le meme moteur :
///   * « Simuler l'etape suivante » appelle `recordStageCompleted` sur la
///     premiere etape du plan qui n'est pas encore faite ;
///   * quand il n'en reste plus, « Simuler l'arrivee » appelle
///     `completeOnArrival(fullyWalked: true)` — le geste exact du pont
///     d'arrivee sur le dernier `trailEnd`.
/// Aucune branche speciale dans le moteur : la demo emprunte le chemin de
/// production, et c'est la barriere d'ecriture qui fait la difference.
///
/// ELLE NE DEMARRE PAS LA RANDONNEE, ET C'EST VOULU. Le demarrage passe par le
/// bouton du cockpit, qui verifie l'unicite de la rando active ET le droit
/// d'acces (`canRealizeTrail`). Doubler ce chemin ici aurait cree une seconde
/// porte d'entree dans le trek — c'est-a-dire exactement la sorte de trou que
/// le lot 601 a ferme. La demo emprunte la porte de tout le monde.
///
/// RIEN DE CE QU'ELLE PROVOQUE N'EST ECRIT. La session simulee vit en memoire :
/// les deux persistances de session sont barrees en demo
/// (`tracking_providers.dart`), comme le journal, le sac, la trace GPS, le
/// portefeuille et les droits.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../features/trek/providers/gps_providers.dart';
import '../../features/trek/providers/tracking_providers.dart';
import '../../i18n/translations.g.dart';

/// La barre de simulation, posee en bas de l'ecran pendant une demo.
class BarreSimulationDemo extends ConsumerWidget {
  const BarreSimulationDemo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final etat = ref.watch(trekSessionManagerProvider);
    final enMarche =
        etat.status == TrackingSessionStatus.recording ||
        etat.status == TrackingSessionStatus.paused;

    final plan = ref.watch(currentTrekPlanProvider);
    final faites = etat.session?.completedStages.toSet() ?? const <String>{};
    final restantes = <String>[
      if (plan != null)
        for (final id in plan.orderedStageIds)
          if (!faites.contains(id)) id,
    ];
    final deja = etat.session?.parcoursFullyWalked ?? false;

    // Ce qui est proposable depend de l'avancement, et rien d'autre.
    final String? libelle;
    final VoidCallback? geste;
    if (!enMarche || plan == null || deja) {
      libelle = null;
      geste = null;
    } else if (restantes.isNotEmpty) {
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

    return Material(
      key: const ValueKey('demo-barre-simulation'),
      color: AppTheme.orangeDifficile,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // LA PHRASE QUI COMPTE, ET QUI RESTE A L'ECRAN.
              Text(
                t.demo.rienNeCompte,
                key: const ValueKey('demo-rien-ne-compte'),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (libelle != null) ...[
                const SizedBox(height: 4),
                TextButton.icon(
                  key: const ValueKey('demo-simuler'),
                  onPressed: geste,
                  icon: const StepIcon(
                    StepwaysIcons.flecheAvant,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    libelle,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
