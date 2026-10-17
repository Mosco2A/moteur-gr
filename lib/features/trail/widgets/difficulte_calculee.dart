/// La difficulte du sentier, avec les trois mesures qui la produisent et la
/// regle qui les transforme en un mot.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/difficulte_du_sentier.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
// LA FEATURE VOISINE SE LIT PAR SA PORTE, PAS PAR SON INTERIEUR
// (ARB-645-05-b, decision B de Christophe du 03/10). Le plafond des
// croisements entre features est a ZERO : un import visant
// `planning/domain/planning_calculator.dart` fait rougir
// `couches_respectees_645_test.dart`, et il l a fait pendant l ecriture de
// ce lot. `PlanningCalculator` figure deja au `show` de la facade — le
// contrat de `planning` n a donc pas eu a s elargir.
import '../../planning/planning_facade.dart';
import 'difficulty_badge.dart';

/// LA DIFFICULTE AFFICHEE AVEC SA DEMONSTRATION.
///
/// CE QUE CET ECRAN NE FAIT PAS : affirmer. Il ne porte aucune etiquette venue
/// d'une configuration. Il prend les etapes MESUREES du sentier, les repartit
/// sur l'allure que le randonneur choisit ici meme, et montre les trois mesures
/// qui decident du mot — puis la regle, en clair, sous le resultat.
///
/// L'ALLURE EST UN CHOIX, ET C'EST POURQUOI ELLE EST UN BOUTON. La difficulte
/// d'un sentier n'existe pas sans un nombre de jours : les memes 11 644 m de
/// montee du GR20 font 728 m par jour en seize jours et 1 663 m en sept.
/// Christophe l'a dit le 15/10 18:00, verbatim : « Beaucoup font tout le GR en
/// 7 jours. D'autre en 10/12 » — et le nombre de jours « n'est pas une
/// propriete du sentier ». Le selecteur part donc de l'allure par defaut du
/// sentier et laisse changer d'avis AVANT d'entrer en preparation.
///
/// LE DECOUPAGE N'EST PAS UNE DIVISION. Regrouper seize etapes sur sept jours
/// ne fait pas sept journees egales : ce sont les etapes existantes qui se
/// reunissent, par le MEME calculateur que le programme
/// (`PlanningCalculator`). La fiche annonce donc exactement les journees que la
/// preparation posera — un second algorithme ici aurait fini par annoncer
/// autre chose que ce que le randonneur trouve ensuite.
class DifficulteCalculee extends StatefulWidget {
  /// Les etapes mesurees, les allures proposees et l'altitude maximale :
  /// tout ce qu'il faut pour deduire, rien de plus.
  const DifficulteCalculee({
    super.key,
    required this.stages,
    required this.allures,
    required this.allureParDefaut,
    this.altitudeMaxM,
  });

  /// Les etapes mesurees du sentier, dans l'ordre.
  final List<StageModel> stages;

  /// Les allures proposees par le sentier, en jours.
  final List<int> allures;

  /// L'allure retenue a l'ouverture de la fiche.
  final int allureParDefaut;

  /// Altitude maximale mesuree de la trace, ou null.
  final int? altitudeMaxM;

  @override
  State<DifficulteCalculee> createState() => _DifficulteCalculeeState();
}

class _DifficulteCalculeeState extends State<DifficulteCalculee> {
  late int _jours;

  @override
  void initState() {
    super.initState();
    _jours = widget.allureParDefaut;
  }

  /// Les allures offertes, triees, sans doublon, et sans celles qui n'ont pas
  /// de sens pour ce sentier : zero jour, ou plus de jours que d'etapes
  /// (au-dela, les jours de plus sont du REPOS et ne changent plus aucune
  /// journee de marche — l'afficher serait proposer un choix sans effet).
  List<int> get _alluresUtiles {
    final maximum = widget.stages.isEmpty
        ? widget.allureParDefaut
        : widget.stages.length;
    final retenues = <int>{
      for (final jours in widget.allures)
        if (jours > 0 && jours <= maximum) jours,
    };
    if (widget.allureParDefaut > 0 && widget.allureParDefaut <= maximum) {
      retenues.add(widget.allureParDefaut);
    }
    return retenues.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.stages.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);

    final journees = PlanningCalculator.distribute(widget.stages, _jours)
        .where((jour) => !jour.isRestDay)
        .map((jour) => jour.totalElevationGainM)
        .toList(growable: false);

    final difficulte = DifficulteDuSentier.calculer(
      jours: _jours,
      denivelesParJournee: journees,
      altitudeMaxM: widget.altitudeMaxM,
    );
    final cle = difficulte?.cleDuSocle;
    if (difficulte == null || cle == null) return const SizedBox.shrink();

    return Padding(
      key: const ValueKey('difficulte-calculee'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Difficulte',
            icon: StepwaysIcons.difficulte,
          ),
          _SelecteurDAllure(
            allures: _alluresUtiles,
            choisie: _jours,
            onChoisi: (jours) => setState(() => _jours = jours),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    DifficultyBadge(difficulty: cle),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        'sur ${difficulte.journeesDeMarche} '
                        'journees de marche',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.grisTexteSecondaire,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingSm),
                for (final critere in difficulte.criteres)
                  _LigneDeCritere(critere: critere),
                if (difficulte.mesuresManquantes.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Non mesure sur ce sentier : '
                    '${difficulte.mesuresManquantes.join(', ')}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingSm),
                // LA REGLE, SOUS LE RESULTAT. Elle vient du socle qui l'a
                // appliquee (`SeuilsDeDifficulte.regleAffichee`) et n'est pas
                // reecrite ici : une regle affichee qui n'est pas la regle
                // appliquee est pire que pas de regle du tout.
                Text(
                  SeuilsDeDifficulte.regleAffichee,
                  key: const ValueKey('regle-de-difficulte'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une mesure, son niveau, et rien d'implicite entre les deux.
class _LigneDeCritere extends StatelessWidget {
  const _LigneDeCritere({required this.critere});

  final CritereDeDifficulte critere;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = DifficultyBadge.colorFor(critere.niveau.cle);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: AppTheme.spacingSm),
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${critere.nom} : ',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: critere.mesure,
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextSpan(
                    text: ' — ${DifficultyBadge.labelFor(critere.niveau.cle)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: couleur,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// LE CHOIX DE L'ALLURE, EN JOURS — un bouton par allure proposee.
class _SelecteurDAllure extends StatelessWidget {
  const _SelecteurDAllure({
    required this.allures,
    required this.choisie,
    required this.onChoisi,
  });

  final List<int> allures;
  final int choisie;
  final ValueChanged<int> onChoisi;

  @override
  Widget build(BuildContext context) {
    if (allures.length < 2) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppTheme.spacingSm,
      runSpacing: AppTheme.spacingXs,
      children: [
        for (final jours in allures)
          ChoiceChip(
            key: ValueKey('allure-$jours'),
            label: Text('$jours jours'),
            selected: jours == choisie,
            labelStyle: theme.textTheme.bodySmall?.copyWith(
              fontWeight: jours == choisie ? FontWeight.w700 : FontWeight.w400,
            ),
            onSelected: (_) => onChoisi(jours),
          ),
      ],
    );
  }
}
