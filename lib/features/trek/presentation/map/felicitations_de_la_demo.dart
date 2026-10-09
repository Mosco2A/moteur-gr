/// LES FELICITATIONS DE LA DEMONSTRATION — l'arrivee est un MOMENT
/// (tache 747).
///
/// RETOUR DE CHRISTOPHE DU 09/10 08:59, mot pour mot : « A la fin il manque les
/// felicitations ». A l'arrivee de la randonnee simulee, rien ne celebrait :
/// les chiffres s'arretaient de monter, et c'etait tout.
///
/// ---------------------------------------------------------------------------
/// POURQUOI UNE FIN PROPRE A LA DEMO, ET NON L'APRES-TREK REEL
/// ---------------------------------------------------------------------------
///
/// Les deux options etaient ouvertes. Le releve d'Artemis avait montre qu'en
/// demo le cockpit n'offre AUCUNE section « Apres », et que « Mon aventure »
/// repond « Disponible a la fin du trek » MEME APRES la fin.
///
/// LA CAUSE EST STRUCTURELLE, PAS UN OUBLI. Tout l'apres-trek — recapitulatif,
/// diplome, journal — lit `latestTrekSessionProvider`, c'est-a-dire LA BASE. Or
/// la demo n'ecrit RIEN, et ce n'est pas un defaut : c'est sa promesse, tenue
/// par deux barrieres explicites (`_persistSession` et `_onSessionPersist`
/// sortent en demo depuis la tache 634) et verifiee par les gardes des taches
/// 742 et 744. Ouvrir l'apres-trek en demo demanderait donc, au choix :
///   * d'ECRIRE la session de demonstration en base — ce qui casse la promesse
///     et laisserait une fausse randonnee dans l'historique de quelqu'un ;
///   * ou de rebrancher TOUT l'apres-trek sur une source memoire, soit
///     plusieurs ecrans hors du perimetre de ce lot.
///
/// D'OU CE CHOIX : LA DEMO A SA PROPRE FIN, CELEBREE. Elle arrive LA OU
/// L'ARRIVEE A LIEU — l'ecran de navigation — et elle porte LES CHIFFRES DU
/// PARCOURS. Elle ne pretend pas etre un diplome : elle dit clairement que
/// rien n'a ete enregistre, ce qui est la verite et ce que la demo promet.
///
/// AUCUN CHIFFRE N'EST RECALCULE ICI. La distance est l'abscisse du marcheur
/// sur la trace ([stageDistanceCoveredProvider]), et la duree, le denivele et
/// la vitesse moyenne viennent de [liveTrekStatsProvider] — les MEMES
/// providers que la barre de la carte. Un second calcul donnerait deux
/// deniveles differents pour la meme demonstration.
///
/// CE N'EST PAS UN DIALOGUE, ET C'EST VOLONTAIRE. La garde
/// `aucun_dialogue_hors_routeur_645` plafonne les `showDialog` hors routeur :
/// cette fin est une surcouche DANS la pile de la carte, posee par
/// `map_content.dart`. Elle ne pousse aucune route et n'empile aucun
/// `Navigator`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../core/services/session_demo.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../map/map_facade.dart' show stageDistanceCoveredProvider;
import '../../data/marcheur_simule_providers.dart';
import '../../providers/live_trek_stats_provider.dart';

/// La fin celebree de la randonnee simulee, posee sur la carte.
///
/// INVISIBLE hors demo, invisible avant l'arrivee, et refermable : une fois
/// fermee elle ne revient pas, parce que le randonneur a dit qu'il avait lu.
class FelicitationsDeLaDemo extends ConsumerStatefulWidget {
  /// Cree la surcouche de fin de demonstration.
  const FelicitationsDeLaDemo({super.key});

  @override
  ConsumerState<FelicitationsDeLaDemo> createState() =>
      _FelicitationsDeLaDemoState();
}

class _FelicitationsDeLaDemoState extends ConsumerState<FelicitationsDeLaDemo> {
  /// Vrai quand le randonneur a ferme les felicitations.
  ///
  /// UN ETAT LOCAL SUFFIT, et c'est voulu : rien de la demonstration ne doit
  /// survivre ailleurs. Quitter la demo detruit cet ecran, donc cet etat.
  bool _ferme = false;

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(enDemoProvider)) return const SizedBox.shrink();
    final etat = ref.watch(etatDuMarcheurSimuleProvider);
    if (etat != EtatDuMarcheur.arrive || _ferme) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final mesures = ref.watch(liveTrekStatsProvider).value;
    final mesurable = mesures != null && mesures.hasData;
    final parcouruKm = ref.watch(stageDistanceCoveredProvider) / 1000;

    return Positioned.fill(
      child: ColoredBox(
        // UN VOILE, PAS UN ECRAN NOIR : la carte et le point d'arrivee restent
        // visibles derriere. L'arrivee se fete DEVANT l'endroit ou elle a eu
        // lieu.
        color: Colors.black.withAlpha(120),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Card(
              key: const ValueKey('demo-felicitations'),
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const StepIcon(
                      StepwaysIcons.diploma,
                      size: 48,
                      color: AppTheme.orangeDifficile,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      t.demo.arriveeTitre,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    Text(
                      t.demo.arriveeTexte,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    Text(
                      t.demo.arriveeChiffres,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingXs),
                    // LES CHIFFRES DU PARCOURS, repris tels quels des providers
                    // de la barre. Une valeur non mesurable ne s'affiche pas —
                    // jamais un zero qui aurait l'air d'une mesure (regle du
                    // correctif L5-6).
                    _Chiffre(
                      icon: StepwaysIcons.distance,
                      label: t.tracking.covered,
                      valeur: '${parcouruKm.toStringAsFixed(1)} km',
                    ),
                    if (mesurable)
                      _Chiffre(
                        icon: StepwaysIcons.denivelePlus,
                        label: t.tracking.dPlus,
                        valeur: '${mesures.elevationGainM} m',
                      ),
                    if (mesurable)
                      _Chiffre(
                        icon: StepwaysIcons.deniveleMoins,
                        label: t.tracking.dMinus,
                        valeur: '${mesures.elevationLossM} m',
                      ),
                    if (mesurable && mesures.averageSpeedKmh != null)
                      _Chiffre(
                        icon: StepwaysIcons.vitesse,
                        label: t.tracking.avgSpeed,
                        valeur:
                            '${mesures.averageSpeedKmh!.toStringAsFixed(1)}'
                            ' km/h',
                      ),
                    const SizedBox(height: AppTheme.spacingMd),
                    AppButton(
                      label: t.demo.arriveeFermer,
                      onPressed: () => setState(() => _ferme = true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une ligne « icone, libelle, valeur » du recapitulatif de fin.
class _Chiffre extends StatelessWidget {
  const _Chiffre({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final String icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StepIcon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text('$label ', style: theme.textTheme.bodySmall),
          Text(
            valeur,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
