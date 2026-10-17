/// La difficulte du sentier en DEUX jauges — la repartition des journees et le
/// verdict de la pire — avec la regle qui les produit.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/difficulte_du_sentier.dart';
import '../../../domain/nuit_possible.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
// LA FEATURE VOISINE SE LIT PAR SA PORTE, PAS PAR SON INTERIEUR
// (ARB-645-05-b, decision B de Christophe du 03/10). Le plafond des
// croisements entre features est a ZERO : un import visant
// `planning/domain/planning_calculator.dart` fait rougir
// `couches_respectees_645_test.dart`. `PlanningCalculator` et, depuis la tache
// 848, `DecoupageSurLesNuits` figurent au `show` de la facade.
import '../../planning/planning_facade.dart';
import 'difficulty_badge.dart';

/// LA DIFFICULTE AFFICHEE AVEC SA DEMONSTRATION, EN DEUX JAUGES.
///
/// CE QUE CET ECRAN NE FAIT PAS : affirmer. Il ne porte aucune etiquette venue
/// d'une configuration. Il prend les journees REELLES du sentier a l'allure
/// choisie ici meme, classe chacune par son denivele, et montre les deux choses
/// que Christophe a demandees le 17/10 11:07-11:08, verbatim : « ou alors une
/// jauge avec le nombre d'etape facile a expert et une jauge moyenne (mais qui
/// se base aussi sur la plus difficile) ».
///
///  - LA REPARTITION repond a « dur une fois ou dur tous les jours ». Seize
///    journees dont deux tres difficiles ne se marchent pas comme seize
///    journees toutes tres difficiles, et un seul mot ne sait pas le dire.
///  - LE VERDICT repond a « il faut savoir faire ca ». C'est le niveau de la
///    PIRE journee, jamais une moyenne : « un sentier qui a 5 etapes a moins de
///    1000 metre et une a plus de 1500 est classe expert ».
///
/// LE NOMBRE DE JOURS EST UN CONSEIL, ET L'ECRAN LE DIT (Christophe, 17/10
/// 11:02, verbatim : « mais le nombre de jour, c'est du conseille, apres le
/// client le fait dans le nombre de jours qu'il veut »). Ce n'est pas une
/// nuance de vocabulaire : la difficulte n'est pas une propriete du sentier
/// mais du sentier A L'ALLURE CHOISIE, et le GR20 passe de tres difficile a
/// expert entre seize jours et sept. Le randonneur voit donc la consequence de
/// son propre choix AVANT de payer.
///
/// LES JOURNEES VIENNENT DU DECOUPAGE REEL, ET DU PLUS FIN DES DEUX. Quand le
/// sentier porte des NUITS RELEVEES (trente et une sur le GR20, tache 838), les
/// journees se posent dessus : chaque fin de journee est un refuge, une
/// bergerie ou un bivouac qui existe dans OpenStreetMap. Sinon elles viennent
/// du regroupement des etapes (`PlanningCalculator`, le meme calculateur que le
/// programme). L'ecart se MESURE : sur douze jours de GR20, les etapes de la
/// federation laissent une journee a 1 824 m de montee la ou les nuits relevees
/// descendent a 1 455 m. Annoncer la plus dure des deux serait annoncer une
/// journee que la preparation ne posera pas.
class DifficulteCalculee extends StatefulWidget {
  /// Les etapes mesurees, les allures proposees et les nuits relevees :
  /// tout ce qu'il faut pour deduire, rien de plus.
  const DifficulteCalculee({
    super.key,
    required this.stages,
    required this.allures,
    required this.allureParDefaut,
    this.nuits,
  });

  /// Les etapes mesurees du sentier, dans l'ordre.
  final List<StageModel> stages;

  /// Les allures proposees par le sentier, en jours.
  final List<int> allures;

  /// L'allure CONSEILLEE, retenue a l'ouverture de la fiche.
  final int allureParDefaut;

  /// Les nuits RELEVEES du sentier, quand il en a. Nulles sinon, et alors les
  /// journees viennent du regroupement des etapes.
  final DecoupageDeNuits? nuits;

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

  /// Le nombre maximal de journees de MARCHE que ce sentier sait poser.
  ///
  /// Les nuits relevees quand il en a plus que d'etapes — c'est le cas du GR20,
  /// trente et une contre seize —, le nombre d'etapes sinon. Au-dela, un jour
  /// de plus serait du REPOS, qui ne change aucune journee de marche donc aucun
  /// niveau : l'offrir ici serait proposer un choix sans effet.
  int get _journeesMaximales {
    final nuits = widget.nuits;
    final parLesNuits = nuits == null ? 0 : nuits.journeesMaximales;
    final parLesEtapes = widget.stages.length;
    final maximum = parLesNuits > parLesEtapes ? parLesNuits : parLesEtapes;
    return maximum > 0 ? maximum : widget.allureParDefaut;
  }

  /// Les allures offertes, triees, sans doublon, et sans celles qui n'ont pas
  /// de sens pour ce sentier.
  List<int> get _alluresUtiles {
    final maximum = _journeesMaximales;
    final retenues = <int>{
      for (final jours in widget.allures)
        if (jours > 0 && jours <= maximum) jours,
    };
    if (widget.allureParDefaut > 0 && widget.allureParDefaut <= maximum) {
      retenues.add(widget.allureParDefaut);
    }
    return retenues.toList()..sort();
  }

  /// Le denivele POSITIF de chaque journee de marche, a l'allure [jours].
  List<int> _denivelesParJournee(int jours) {
    final nuits = widget.nuits;
    if (nuits != null && !nuits.vide) {
      return DecoupageSurLesNuits.repartir(
        nuits,
        jours,
      ).map((journee) => journee.deniveleM).toList(growable: false);
    }
    return PlanningCalculator.distribute(widget.stages, jours)
        .where((jour) => !jour.isRestDay)
        .map((jour) => jour.totalElevationGainM)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final nuits = widget.nuits;
    final sansJournee = widget.stages.isEmpty && (nuits == null || nuits.vide);
    if (sansJournee) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final difficulte = DifficulteDuSentier.calculer(
      jours: _jours,
      denivelesParJournee: _denivelesParJournee(_jours),
    );
    final verdict = difficulte?.verdict;
    final pire = difficulte?.pireJournee;
    if (difficulte == null || verdict == null || pire == null) {
      return const SizedBox.shrink();
    }

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
          _ChoixDesJours(
            allures: _alluresUtiles,
            choisie: _jours,
            conseillee: widget.allureParDefaut,
            onChoisi: (jours) => setState(() => _jours = jours),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // JAUGE 1 — LE VERDICT, sur l'echelle entiere : le randonneur
                // voit le niveau ET ou il se situe entre facile et expert.
                _JaugeDuVerdict(verdict: verdict),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Journee la plus dure : ${pire.deniveleM} m de montee '
                  '(journee ${pire.numero} sur '
                  '${difficulte.journeesDeMarche})',
                  key: const ValueKey('pire-journee'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingBase),
                // JAUGE 2 — LA REPARTITION des journees par niveau.
                _JaugeDeRepartition(difficulte: difficulte),
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

/// LA JAUGE DU VERDICT : les cinq niveaux, celui du sentier allume.
///
/// POURQUOI L'ECHELLE ENTIERE ET PAS SEULEMENT LE MOT. « Tres difficile » tout
/// seul ne dit pas s'il reste un cran au-dessus. Les cinq cases le disent d'un
/// coup d'oeil, et elles disent aussi que ce sentier n'est pas le plus dur
/// possible — ou qu'il l'est.
class _JaugeDuVerdict extends StatelessWidget {
  const _JaugeDuVerdict({required this.verdict});

  final NiveauDeDifficulte verdict;

  @override
  Widget build(BuildContext context) {
    final couleur = DifficultyBadge.couleurDe(verdict);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          key: const ValueKey('jauge-du-verdict'),
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                      // Les crans non retenus restent LISIBLES mais eteints :
                      // ils donnent l'echelle sans se disputer le regard.
                      color: DifficultyBadge.couleurDe(
                        niveau,
                      ).withAlpha(niveau == verdict ? 255 : 48),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          children: [
            DifficultyBadge(niveau: verdict),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: Text(
                'le niveau de la journee la plus dure',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: couleur,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// LA JAUGE DE REPARTITION : combien de journees a chaque niveau.
///
/// La barre est proportionnelle au NOMBRE de journees, et chaque niveau present
/// est nomme avec son compte en dessous. Les niveaux absents n'ont pas de
/// segment — mais la ligne de comptes les cite a zero, pour qu'on voie qu'un
/// sentier n'a AUCUNE journee facile quand c'est le cas.
class _JaugeDeRepartition extends StatelessWidget {
  const _JaugeDeRepartition({required this.difficulte});

  final DifficulteDuSentier difficulte;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repartition = difficulte.repartition;
    final total = difficulte.journeesDeMarche;
    if (total == 0) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repartition des $total journees de marche',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Row(
          key: const ValueKey('jauge-de-repartition'),
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              if ((repartition[niveau] ?? 0) > 0)
                Expanded(
                  flex: repartition[niveau] ?? 0,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        color: DifficultyBadge.couleurDe(niveau),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Wrap(
          key: const ValueKey('comptes-par-niveau'),
          spacing: AppTheme.spacingSm,
          runSpacing: 2,
          children: [
            for (final niveau in NiveauDeDifficulte.values)
              _CompteDUnNiveau(
                niveau: niveau,
                journees: repartition[niveau] ?? 0,
              ),
          ],
        ),
      ],
    );
  }
}

/// « 7 moyennes » — un niveau, son compte, et sa couleur en pastille de 8 px.
class _CompteDUnNiveau extends StatelessWidget {
  const _CompteDUnNiveau({required this.niveau, required this.journees});

  final NiveauDeDifficulte niveau;
  final int journees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final absent = journees == 0;
    final couleur = DifficultyBadge.couleurDe(niveau);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: couleur.withAlpha(absent ? 48 : 255),
            shape: BoxShape.circle,
          ),
        ),
        Text(
          '$journees ${niveau.libelle.toLowerCase()}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: absent ? AppTheme.grisTexteSecondaire : couleur,
            fontWeight: absent ? FontWeight.w400 : FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

/// LE NOMBRE DE JOURS, ET LE MOT « CONSEILLE » QUI VA AVEC.
///
/// Christophe, 17/10 11:02 : « mais le nombre de jour, c'est du conseille,
/// apres le client le fait dans le nombre de jours qu'il veut ». Le mot est
/// donc AFFICHE, et l'allure du sentier est marquee comme le conseil qu'elle
/// est — pas comme une caracteristique du chemin.
class _ChoixDesJours extends StatelessWidget {
  const _ChoixDesJours({
    required this.allures,
    required this.choisie,
    required this.conseillee,
    required this.onChoisi,
  });

  final List<int> allures;
  final int choisie;
  final int conseillee;
  final ValueChanged<int> onChoisi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nombre de jours CONSEILLE : $conseillee jours',
          key: const ValueKey('jours-conseilles'),
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          'C\'est un conseil, pas une caracteristique du sentier : vous le '
          'marchez dans le nombre de jours que vous voulez, et le niveau '
          'ci-dessous suit votre choix.',
          key: const ValueKey('les-jours-sont-un-conseil'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
        if (allures.length >= 2) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Wrap(
            spacing: AppTheme.spacingSm,
            runSpacing: AppTheme.spacingXs,
            children: [
              for (final jours in allures)
                ChoiceChip(
                  key: ValueKey('allure-$jours'),
                  label: Text(
                    jours == conseillee
                        ? '$jours jours (conseille)'
                        : '$jours jours',
                  ),
                  selected: jours == choisie,
                  labelStyle: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: jours == choisie
                        ? FontWeight.w700
                        : FontWeight.w400,
                  ),
                  onSelected: (_) => onChoisi(jours),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
