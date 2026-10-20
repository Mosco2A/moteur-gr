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
import '../../../domain/note_d_effort.dart';
import '../../../domain/note_de_raideur.dart';
import '../../../domain/nuit_possible.dart';
import '../../../domain/profil_du_terrain.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
// LA FEATURE VOISINE SE LIT PAR SA PORTE, PAS PAR SON INTERIEUR
// (ARB-645-05-b, decision B de Christophe du 03/10). Le plafond des
// croisements entre features est a ZERO.
import '../../planning/planning_facade.dart';
import 'choix_des_jours.dart';
import 'lectures_du_plan_affichees.dart';
import 'les_deux_notes.dart';

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
    for (final journee in DecoupageSurLesNuits.repartir(
      nuits,
      jours,
      effortDuGroupe: _effortDuGroupe(nuits),
    )) {
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

  /// L'EFFORT D'UN GROUPE DE SEGMENTS — ce que le repartiteur egalise depuis
  /// la tache 860.
  ///
  /// Christophe, verbatim 19/10 : « Oui a l'effort pas au temps ». La charge
  /// rendue est l'INDICE REEL de la journee, celui que l'ecran affiche, et pas
  /// une somme d'indices de morceaux : l'indice est sous-additif quand une
  /// coupure tombe dans une montee, donc une somme optimiserait un chiffre que
  /// personne ne voit. `null` quand le sentier n'a pas de profil — le
  /// repartiteur retombe alors sur le temps de marche.
  double Function(int, int)? _effortDuGroupe(DecoupageDeNuits nuits) {
    if (widget.profil.estVide) return null;
    final pkParNom = <String, double>{
      for (final nuit in nuits.nuits) nuit.nom: nuit.pkKm,
    };
    double pkDeFin(int segment) =>
        pkParNom[nuits.segments[segment].arrivee] ?? 0.0;
    return (debut, fin) {
      final pkDebut = debut == 0 ? 0.0 : pkDeFin(debut - 1);
      final pkFin = pkDeFin(fin - 1);
      if (pkFin <= pkDebut) return 0.0;
      return IndiceDuTerrain.calculer(
        terrain: widget.profil.tranche(
          pkDebutM: pkDebut * 1000.0,
          pkFinM: pkFin * 1000.0,
        ),
      ).indice;
    };
  }

  /// Le sentier pese a l'allure [jours], ou `null`.
  SentierPese? _peser(int jours) => SentierPese.peser(
    jours: jours,
    profil: widget.profil,
    journees: _journeesDuSentier(jours),
  );

  /// La NOTE D'EFFORT de la pire journee d'une allure, ou `null` quand elle
  /// n'est pas mesurable — jamais zero, qui passerait pour une journee facile.
  ///
  /// C'EST L'EFFORT QUI ETIQUETTE L'ALLURE, et pas la raideur : le
  /// repartiteur equilibre les journees a l'effort, donc c'est l'effort que le
  /// choix du nombre de jours fait bouger. La raideur d'un sentier est
  /// largement imposee par son relief et un jour de plus n'y change presque
  /// rien.
  double? _noteDeLaPireJournee(int jours) {
    final deja = _indiceParAllure[jours];
    if (deja != null) return deja;
    final pire = _peser(jours)?.pireJournee;
    if (pire == null) return null;
    return _indiceParAllure[jours] = pire.noteDEffort;
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
    final km = pire == null ? '' : nombreAUneDecimale(pire.km);
    final montee = pire == null
        ? ''
        : pire.plusGrosseMonteeM.round().toString();
    final temps = pire == null ? '' : formatDurationMinutes(pire.minutes);
    final seuilDuSeize = nombreAUneDecimale(
      NoteDEffort.indiceDuDernierSeuilPublie,
    );
    final bandeDuDix = NoteDeRaideur.bleuM.round().toString();

    return Padding(
      key: const ValueKey('indice-du-terrain'),
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Difficulte, journee par journee',
            icon: StepwaysIcons.difficulte,
          ),
          ChoixDesJours(
            allures: _alluresUtiles,
            choisie: _jours,
            conseillee: widget.allureParDefaut,
            noteDeLaPireJournee: _noteDeLaPireJournee,
            onChoisi: (jours) => setState(() => _jours = jours),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pire != null) ...[
                  // LES QUATRE LECTURES DU PLAN, ET LE NOMBRE DE JOURS EN
                  // PREMIER : sans lui, « journee la plus dure 18,9 » ne veut
                  // rien dire.
                  LecturesDuPlanAffichees(lectures: pese.lectures),
                  const SizedBox(height: AppTheme.spacingSm),
                  // LES DEUX NOTES DE LA PIRE JOURNEE. Ce sont les seuls
                  // nombres NOTES du produit : une journee en a deux, un
                  // troncon et un sentier n'en ont aucune.
                  LesDeuxNotes(
                    titre: 'Journee la plus dure de ce plan',
                    effort: pire.noteDEffort,
                    raideur: pire.noteDeRaideur,
                    metresParKm: pire.metresParKmDeMontee,
                  ),
                  if (pire.estEcretee) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    // UNE NOTE ECRETEE NE DIT PAS LA MEME CHOSE QU'UN VINGT
                    // QUI TOMBE PILE, et le taire serait trompeur : cette
                    // journee groupe plusieurs etapes, donc elle depasse la
                    // plus dure etape officielle connue. Ce sont les deux
                    // faits ci-dessous qui la distinguent alors.
                    Text(
                      'Vingt est le plafond de l\'effort : cette journee '
                      'demande plus que la plus dure etape officielle connue. '
                      'Ce sont les deux chiffres ci-dessous qui la decrivent '
                      'vraiment.',
                      key: const ValueKey('note-ecretee'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  ],
                  if (pire.raideurEcretee) ...[
                    const SizedBox(height: AppTheme.spacingXs),
                    // LE PLAFOND DE RAIDEUR EST UN SEUIL PUBLIE, donc on peut
                    // dire exactement ce qu'il veut dire.
                    Text(
                      'Vingt est aussi le plafond de la raideur : au-dela de '
                      '${NoteDeRaideur.doubleNoirM.round()} m de montee par '
                      'kilometre, les bandes publiees ne graduent plus.',
                      key: const ValueKey('raideur-ecretee'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.grisTexteSecondaire,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.spacingXs),
                  // LES DEUX FAITS SANS ECHELLE, A COTE DE LA NOTE. Ce ne sont
                  // PAS des notes : la plus grosse montee continue et le
                  // kilometrage portent ce que la note ne dit pas, et eux ne
                  // s'ecretent jamais. Mesure du GR20 a huit jours : un jour a
                  // 1 162 m d'un seul tenant note MOINS qu'un jour a 739 m qui
                  // fait 38 km.
                  Text(
                    'Journee ${pire.numero} sur ${pese.journeesDeMarche} : '
                    'une montee de $montee m d\'un seul tenant, $km km de '
                    'marche.',
                    key: const ValueKey('les-deux-faits'),
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Text(
                    '${pire.deniveleM} m de montee et ${pire.descenteM} m de '
                    'descente au total, pour un indice de terrain de $indice.',
                    key: const ValueKey('pire-journee'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppTheme.grisTexteSecondaire,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  // LE TEMPS DE MARCHE, SOUS SON PROPRE NOM ET A PART. C'est
                  // un AUTRE nombre que la note, calcule par un AUTRE modele
                  // (celui du depot, source unique depuis la tache 839).
                  Text(
                    'Temps de marche de cette journee : $temps. C\'est un '
                    'autre nombre que la note, et il ne s\'en deduit pas : '
                    'deux journees de meme duree n\'ont pas la meme note.',
                    key: const ValueKey('temps-de-marche'),
                    style: theme.textTheme.bodyMedium,
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
                  'Effort : 16 sur 20, c\'est le dernier seuil publie du '
                  'bareme francais de randonnee, 25 km et 1 000 m de montee '
                  '(indice $seuilDuSeize). Au-dela, aucun bareme du monde ne '
                  'gradue, et 20 est la plus dure etape officielle connue.',
                  key: const ValueKey('ce-que-la-note-veut-dire'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  'Raideur : c\'est la montee par kilometre divisee par dix. '
                  '10 sur 20 vaut $bandeDuDix m par kilometre, soit 10 % de '
                  'pente moyenne. Les paliers viennent des bandes publiees de '
                  'l\'IMBA, qui classent des sentiers de VTT : la pente '
                  'moyenne est la meme grandeur a pied, mais ce n\'est pas '
                  'une source randonnee et nous n\'en avons trouve aucune.',
                  key: const ValueKey('ce-que-la-raideur-veut-dire'),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.grisTexteSecondaire,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
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
