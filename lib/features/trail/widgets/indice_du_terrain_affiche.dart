/// L'INDICE DE TERRAIN du sentier a l'allure choisie, avec sa demonstration —
/// et le temps de marche a cote, sous son propre nom.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/models/stage_duration.dart';
import '../../../core/models/stage_row.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/indice_du_terrain.dart';
import '../../../domain/journees_pesees.dart';
import '../../../domain/nuit_possible.dart';
import '../../../domain/profil_du_terrain.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
// LA FEATURE VOISINE SE LIT PAR SA PORTE, PAS PAR SON INTERIEUR
// (ARB-645-05-b, decision B de Christophe du 03/10). Le plafond des
// croisements entre features est a ZERO.
import '../../planning/planning_facade.dart';
import 'choix_des_jours.dart';

/// L'INDICE DE TERRAIN AFFICHE AVEC CE QUI LE PRODUIT (tache 858).
///
/// CE QUE CE BLOC A REMPLACE, ET POURQUOI. Jusqu'au 18/10/2026 il affichait un
/// « kilometre-effort » (tache 852) : la distance, plus un kilometre par
/// 100 m de montee, plus 0,30 fois autant pour la descente. Ce nombre etait
/// AFFICHE AUX CLIENTS et il etait faux — il cotait 26,5 la journee qui grimpe
/// 1 454 m depuis Calenzana et 21,4 la meme journee marchee a l'envers, qui les
/// DESCEND. Christophe l'a retire le 18/10 19:32, avec le compte de la tache
/// 856 qui n'etait que la duree deguisee. Il ne reste qu'un compte, celui de la
/// tache 857 : l'ENERGIE mesuree par Minetti, integree sur la trace.
///
/// DEUX NOMBRES, DEUX NOMS, A L'ECRAN COMME DANS LE CODE. L'INDICE DE TERRAIN
/// dit ce que le chemin demande ; LE TEMPS DE MARCHE dit combien d'heures il
/// prend. Ils ne se deduisent pas l'un de l'autre, et c'est verifiable ici
/// meme : sur le GR20 l'indice par heure va de 2,15 a 7,98 selon la journee.
/// La confusion des deux est exactement ce que ce lot repare.
///
/// AUCUN MOT DE NIVEAU N'EST AFFICHE, ET C'EST UNE CONSIGNE. Christophe,
/// 18/10 19:32 : « On tranchera les niveaux apres ». Les bandes facile / moyen
/// / difficile / tres difficile sont retirees avec le compte qui les
/// alimentait ; elles reviendront quand il aura donne ses seuils, et pas
/// avant. Trois endroits de l'application exigeaient un mot et ne l'ont plus :
/// la pastille de chaque etape dans la liste, celle de l'ecran d'etape, et la
/// jauge de repartition de cette fiche.
///
/// LES JOURNEES VIENNENT DU DECOUPAGE REEL, ET DU PLUS FIN DES DEUX. Quand le
/// sentier porte des NUITS RELEVEES (trente et une sur le GR20, tache 838), les
/// journees se posent dessus et chacune porte ses POINTS KILOMETRIQUES — ce
/// dont l'indice a besoin, puisqu'il s'integre sur le profil. Sans nuits
/// relevees, la mesure est ANNONCEE MANQUANTE plutot que remplacee par une
/// position interpolee entre deux etapes : c'est le reproche exact fait au
/// decoupage du lot 558, et il tient toujours.
class IndiceDuTerrainAffiche extends StatefulWidget {
  /// Les etapes mesurees, les allures proposees, le profil de la trace et les
  /// nuits relevees : tout ce qu'il faut pour deduire, rien de plus.
  const IndiceDuTerrainAffiche({
    super.key,
    required this.stages,
    required this.allures,
    required this.allureParDefaut,
    required this.profil,
    this.nuits,
  });

  /// Les etapes mesurees du sentier, dans l'ordre.
  final List<StageModel> stages;

  /// Les allures proposees par le sentier, en jours.
  final List<int> allures;

  /// L'allure CONSEILLEE, retenue a l'ouverture de la fiche.
  final int allureParDefaut;

  /// Le profil de la trace, ou [ProfilDuTerrain.vide] tant qu'il n'est pas la.
  final ProfilDuTerrain profil;

  /// Les nuits RELEVEES du sentier, quand il en a.
  final DecoupageDeNuits? nuits;

  @override
  State<IndiceDuTerrainAffiche> createState() => _IndiceDuTerrainAfficheState();
}

class _IndiceDuTerrainAfficheState extends State<IndiceDuTerrainAffiche> {
  late int _jours;

  @override
  void initState() {
    super.initState();
    _jours = widget.allureParDefaut;
  }

  /// L'INDICE DE LA PIRE JOURNEE, ALLURE PAR ALLURE — calcule une seule fois.
  ///
  /// Le decoupage d'une allure donnee rend toujours le meme resultat, et la
  /// ligne des allures les redemande toutes a chaque image alors que seule la
  /// selection a bouge. Le cache est vide quand le profil arrive : il est pose
  /// a la construction et le widget est reconstruit avec un profil different.
  final _indiceParAllure = <int, double>{};

  /// Le nombre maximal de journees de MARCHE que ce sentier sait poser.
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

  /// LES JOURNEES DE L'ALLURE [jours], AVEC LEURS BORNES SUR LA TRACE.
  ///
  /// LES BORNES VIENNENT DES NUITS RELEVEES, et d'elles seules : le point
  /// kilometrique d'un refuge est une MESURE (tache 838), pas une proportion.
  /// La borne de depart d'une journee est l'arrivee de la precedente, et celle
  /// de la premiere est la tete de sentier.
  List<JourneeAPeser> _journeesDuSentier(int jours) {
    final nuits = widget.nuits;
    if (nuits == null || nuits.vide) {
      // SANS NUITS RELEVEES, AUCUNE BORNE : les journees sont annoncees non
      // pesables et la fiche DIT la mesure manquante. Les etapes donnent quand
      // meme le compte des journees, qui reste juste.
      return PlanningCalculator.distribute(widget.stages, jours)
          .where((jour) => !jour.isRestDay)
          .map(
            (jour) => JourneeAPeser(
              depart: '',
              arrivee: '',
              km: jour.totalDistanceKm,
              deniveleM: jour.totalElevationGainM,
              descenteM: jour.totalElevationLossM,
              minutes: (jour.estimatedDurationHours * 60).round(),
              pkDebutKm: 0,
              pkFinKm: 0,
            ),
          )
          .toList(growable: false);
    }

    final journees = <JourneeAPeser>[];
    var pkPrecedent = 0.0;
    var departPrecedent = nuits.teteDeSentier;
    for (final journee in DecoupageSurLesNuits.repartir(nuits, jours)) {
      final arrivee = journee.arrivee;
      final pkArrivee = arrivee?.pkKm ?? pkPrecedent;
      journees.add(
        JourneeAPeser(
          depart: departPrecedent,
          arrivee: journee.arriveeNom,
          km: journee.km,
          deniveleM: journee.deniveleM,
          descenteM: journee.descenteM,
          minutes: journee.minutes,
          pkDebutKm: pkPrecedent,
          pkFinKm: pkArrivee,
        ),
      );
      pkPrecedent = pkArrivee;
      departPrecedent = journee.arriveeNom;
    }
    return journees;
  }

  /// Le sentier pese a l'allure [jours], ou `null`.
  SentierPese? _peser(int jours) => SentierPese.peser(
    jours: jours,
    profil: widget.profil,
    journees: _journeesDuSentier(jours),
  );

  /// L'indice de terrain de la pire journee d'une allure, ou `null` quand il
  /// n'est pas mesurable — jamais zero, qui passerait pour une journee facile.
  double? _indiceDeLaPireJournee(int jours) {
    final deja = _indiceParAllure[jours];
    if (deja != null) return deja;
    final pire = _peser(jours)?.pireJournee;
    if (pire == null) return null;
    return _indiceParAllure[jours] = pire.indiceDuTerrain;
  }

  @override
  Widget build(BuildContext context) {
    final nuits = widget.nuits;
    final sansJournee = widget.stages.isEmpty && (nuits == null || nuits.vide);
    if (sansJournee) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final pese = _peser(_jours);
    if (pese == null) return const SizedBox.shrink();
    final pire = pese.pireJournee;

    // LES NOMBRES SONT MIS EN FORME AVANT LA PHRASE, et pas dans son
    // interpolation : `aucun_code_mort_645_test` lit les identifiants du code
    // APRES avoir retire les chaines, donc un appel ecrit dans un `${...}` lui
    // est invisible. C'est a l'appel de sortir de la chaine.
    final indice = pire == null ? '' : nombreAUneDecimale(pire.indiceDuTerrain);
    final socle = pire == null
        ? ''
        : nombreAUneDecimale(pire.terrain.socleMesure);
    final majoration = pire == null
        ? ''
        : nombreAUneDecimale(pire.terrain.majorationDeContinuite);
    final km = pire == null ? '' : nombreAUneDecimale(pire.km);
    final montee = pire == null
        ? ''
        : pire.terrain.plusGrosseMonteeM.round().toString();
    final temps = pire == null ? '' : formatDurationMinutes(pire.minutes);

    return Padding(
      key: const ValueKey('indice-du-terrain'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Indice de terrain',
            icon: StepwaysIcons.difficulte,
          ),
          ChoixDesJours(
            allures: _alluresUtiles,
            choisie: _jours,
            conseillee: widget.allureParDefaut,
            indiceDeLaPireJournee: _indiceDeLaPireJournee,
            onChoisi: (jours) => setState(() => _jours = jours),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pire != null) ...[
                  Text(
                    'Journee la plus dure : indice $indice',
                    key: const ValueKey('indice-de-la-pire-journee'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Journee ${pire.numero} sur ${pese.journeesDeMarche} : '
                    '$km km, ${pire.deniveleM} m de montee et '
                    '${pire.descenteM} m de descente, dont une montee de '
                    '$montee m d\'un seul tenant.',
                    key: const ValueKey('pire-journee'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  // LE TEMPS DE MARCHE, SOUS SON PROPRE NOM ET A PART. C'est
                  // un AUTRE nombre que l'indice, calcule par un AUTRE modele
                  // (celui du depot, source unique depuis la tache 839).
                  Text(
                    'Temps de marche de cette journee : $temps. C\'est un '
                    'autre nombre que l\'indice, et il ne s\'en deduit pas : '
                    'deux journees de meme duree n\'ont pas le meme indice.',
                    key: const ValueKey('temps-de-marche'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  // CE QUI EST MESURE ET CE QUI EST ASSUME, CHIFFRE A COTE DU
                  // RESULTAT. C'est le seul chiffre qui dit au lecteur quelle
                  // confiance accorder au nombre.
                  Text(
                    'Dont $socle mesure sur la trace et $majoration de '
                    'majoration pour la continuite des montees, qui est la '
                    'seule part assumee.',
                    key: const ValueKey('part-mesuree-et-part-assumee'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                ],
                if (pese.mesuresManquantes.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingXs),
                  // LE COMPTE DES JOURNEES RESTE DIT MEME SANS INDICE : on
                  // sait combien elles sont et ce qu'elles mesurent, on ne sait
                  // simplement pas ce qu'elles coutent.
                  Text(
                    '${pese.journeesDeMarche} journees de marche a cette '
                    'allure.',
                    key: const ValueKey('journees-de-marche'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    'Pas d\'indice de terrain sur ce sentier, il manque : '
                    '${pese.mesuresManquantes.join(', ')}.',
                    key: const ValueKey('mesures-manquantes'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: AppTheme.spacingSm),
                // LA REGLE, SOUS LE RESULTAT. Elle vient du socle qui l'a
                // appliquee et n'est pas reecrite ici : une regle affichee qui
                // n'est pas la regle appliquee est pire que pas de regle.
                Text(
                  LoiDeLIndice.retenue.regleAffichee,
                  key: const ValueKey('regle-de-l-indice'),
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
