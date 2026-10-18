/// La difficulte du sentier en DEUX jauges — la repartition des journees et le
/// verdict du troncon — avec les deux regles qui les produisent.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/difficulte_du_sentier.dart';
import '../../../domain/echelle_de_difficulte.dart';
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
import 'jauges_de_difficulte.dart';

/// LA DIFFICULTE AFFICHEE AVEC SA DEMONSTRATION, EN DEUX JAUGES.
///
/// CE QUE CET ECRAN NE FAIT PAS : affirmer. Il ne porte aucune etiquette venue
/// d'une configuration. Il prend les journees REELLES du sentier a l'allure
/// choisie ici meme, classe chacune par son EFFORT, et montre les deux choses
/// que Christophe a demandees le 17/10 11:07-11:08, verbatim : « ou alors une
/// jauge avec le nombre d'etape facile a expert et une jauge moyenne (mais qui
/// se base aussi sur la plus difficile) ».
///
///  - LA REPARTITION repond a « dur une fois ou dur tous les jours ». Seize
///    journees dont deux tres difficiles ne se marchent pas comme seize
///    journees toutes tres difficiles, et un seul mot ne sait pas le dire.
///  - LE VERDICT repond a « il faut savoir faire ca ». Il part de la PIRE
///    journee, jamais d'une moyenne, et il monte d'un cran quand les journees
///    dures se SUIVENT (tache 852, memoire #102180).
///
/// LES DEUX JAUGES PORTENT QUATRE BANDES DEPUIS LA TACHE 852, plus cinq : la
/// bande « expert » est supprimee et ce qu'elle portait est dans « tres
/// difficile », qui est la bande du haut.
///
/// LE NOMBRE DE JOURS EST UN CONSEIL, ET L'ECRAN LE DIT (Christophe, 17/10
/// 11:02, verbatim : « mais le nombre de jour, c'est du conseille, apres le
/// client le fait dans le nombre de jours qu'il veut »). Ce n'est pas une
/// nuance de vocabulaire : la difficulte n'est pas une propriete du sentier
/// mais du sentier A L'ALLURE CHOISIE. Le randonneur voit donc la consequence
/// de son propre choix AVANT de payer — et sur le GR20 il voit aussi que son
/// choix ne le sauve pas : le sentier est tres difficile de sept a trente et un
/// jours, dans les deux sens (mesure de la tache 852).
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
    this.lesJoursSontUnConseil = '',
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

  /// La phrase de la FICHE qui dit que le nombre de jours est un conseil
  /// ([DescriptionDeSentier.lesJoursSontUnConseil]). Vide : rien ne s'affiche.
  final String lesJoursSontUnConseil;

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

  /// L'EFFORT DE LA PIRE JOURNEE, ALLURE PAR ALLURE — calcule une seule fois.
  ///
  /// Les etapes et les nuits ne changent pas pendant la vie de cet ecran : le
  /// decoupage d'une allure donnee rend toujours le meme resultat. On le garde
  /// donc, parce que la ligne des allures redemande les QUATRE a chaque image
  /// alors que seule la selection a bouge.
  final _effortParAllure = <int, double>{};

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

  /// LES TROIS MESURES DE CHAQUE JOURNEE DE MARCHE, a l'allure [jours].
  ///
  /// Les TROIS, et plus le seul denivele positif : c'est la decision de
  /// Christophe du 17/10 17:25.
  ///
  /// TACHE 855 — CE CALCUL N'EST PLUS ICI, ET C'ETAIT LE DEFAUT LE PLUS GRAVE
  /// DU PRODUIT. Ces lignes posaient les journees de la FICHE sur les trente et
  /// une nuits relevees, donc EN COUPANT les etapes ; le PROGRAMME du client,
  /// lui, ne coupait jamais. A seize jours la fiche annonçait une pire journee
  /// de 26,48 km-effort quand le programme en produisait une de 36,45 — neuf
  /// km-effort d'ecart, du cote qui RASSURE A TORT, sur un sentier de haute
  /// montagne. Le « mode facile » etait ANNONCE et PAS IMPLEMENTE.
  ///
  /// Les journees sont desormais posees par [JourneesDuSentier], le SEUL
  /// endroit du depot qui en decide, et le programme lit le MEME calcul. La
  /// divergence n'est plus surveillee par un test : elle est devenue
  /// impossible a ecrire.
  List<JourneeMesuree> _journeesDuSentier(int jours) =>
      JourneesDuSentier.mesurees(
        JourneesDuSentier.poser(
          etapes: widget.stages,
          nuitsDansLeSensDeLaTrace: widget.nuits,
          // LA FICHE MONTRE LE SENTIER DANS LE SENS DE SA TRACE. Le choix du
          // sens vit dans le PROGRAMME (`selectedDirectionProvider`) et la
          // fiche n'en porte aucun selecteur : lui en inventer un ici
          // afficherait un sens que le client n'a pas choisi.
          aLEnvers: false,
          jours: jours,
        ),
      );

  /// CE QUE CHAQUE ALLURE COUTE, EN KILOMETRES-EFFORT DE SA PIRE JOURNEE.
  ///
  /// POURQUOI UN CHIFFRE ET PLUS UN MOT. Christophe presentait une echelle de
  /// mots le 17/10 11:05, verbatim : « 7 jours= experts, 9jours = tres
  /// difficile, 12 jours Difficile, 16 jours = Difficile ». La mesure de la
  /// tache 852 l'a tuee : la bande expert n'existe plus, et les QUATRE allures
  /// sortent TRES DIFFICILE — ecrire quatre fois le meme mot a cote de quatre
  /// nombres de jours differents ne dit RIEN au lecteur, et pire, lui laisse
  /// croire que les quatre se valent.
  ///
  /// LE MOT NE BOUGE PAS, LE CHIFFRE SI, et c'est le chiffre qui porte
  /// l'information de vente : 55,3 km-effort a sept jours contre 26,5 a seize,
  /// soit DEUX FOIS la journee la plus dure. Voila ce que serrer l'allure
  /// coute, et aucun mot de l'echelle a quatre bandes ne sait le dire.
  ///
  /// C'est la pire journee et non la moyenne, pour la meme raison que le
  /// verdict ([DifficulteDuSentier.pireJournee]) : c'est elle qui decide si le
  /// marcheur arrive au bout.
  ///
  /// `null` pour une allure dont aucune journee n'est mesurable — la ligne
  /// affiche alors le nombre de jours seul, jamais un zero qui passerait pour
  /// une journee facile.
  double? _effortDeLaPireJournee(int jours) {
    final deja = _effortParAllure[jours];
    if (deja != null) return deja;
    final difficulte = DifficulteDuSentier.calculer(
      jours: jours,
      journees: _journeesDuSentier(jours),
    );
    final pire = difficulte?.pireJournee;
    if (pire == null) return null;
    return _effortParAllure[jours] = pire.kmEffort;
  }

  @override
  Widget build(BuildContext context) {
    final nuits = widget.nuits;
    final sansJournee = widget.stages.isEmpty && (nuits == null || nuits.vide);
    if (sansJournee) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final difficulte = DifficulteDuSentier.calculer(
      jours: _jours,
      journees: _journeesDuSentier(_jours),
    );
    final verdict = difficulte?.verdict;
    final pire = difficulte?.pireJournee;
    if (difficulte == null || verdict == null || pire == null) {
      return const SizedBox.shrink();
    }

    // LES DEUX NOMBRES SONT MIS EN FORME AVANT LA PHRASE, et pas dans son
    // interpolation : `aucun_code_mort_645_test` lit les identifiants du code
    // APRES avoir retire les chaines, donc un appel ecrit dans un `${...}` est
    // invisible pour lui — et `nombreAUneDecimale` passait pour un symbole sans
    // appelant. La garde a raison de ne pas lire les chaines ; c'est a l'appel
    // de sortir de la chaine.
    final km = nombreAUneDecimale(pire.km);
    final effort = nombreAUneDecimale(pire.kmEffort);

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
          ChoixDesJours(
            allures: _alluresUtiles,
            choisie: _jours,
            conseillee: widget.allureParDefaut,
            effortDeLaPireJournee: _effortDeLaPireJournee,
            lesJoursSontUnConseil: widget.lesJoursSontUnConseil,
            onChoisi: (jours) => setState(() => _jours = jours),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // JAUGE 1 — LE VERDICT, sur l'echelle entiere : le randonneur
                // voit le niveau ET ou il se situe entre facile et tres
                // difficile.
                JaugeDuVerdict(verdict: verdict),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Journee la plus dure : $km km, ${pire.deniveleM} m de '
                  'montee et ${pire.descenteM} m de descente, soit '
                  '$effort km-effort (journee ${pire.numero} sur '
                  '${difficulte.journeesDeMarche})',
                  key: const ValueKey('pire-journee'),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingXs),
                CeQueLAccumulationFait(difficulte: difficulte),
                const SizedBox(height: AppTheme.spacingBase),
                // JAUGE 2 — LA REPARTITION des journees par niveau.
                JaugeDeRepartition(difficulte: difficulte),
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
                // LES DEUX REGLES, SOUS LE RESULTAT. Elles viennent du socle
                // qui les a appliquees et ne sont pas reecrites ici : une regle
                // affichee qui n'est pas la regle appliquee est pire que pas de
                // regle du tout.
                Text(
                  SeuilsDeDifficulte.regleAffichee,
                  key: const ValueKey('regle-de-difficulte'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  SeuilsDeDifficulte.regleDuTronconAffichee,
                  key: const ValueKey('regle-du-troncon'),
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
