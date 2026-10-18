/// LES JOURNEES D UN SENTIER A UNE ALLURE DONNEE — posees UNE SEULE FOIS, pour
/// la fiche de vente ET pour le programme du client.
library;

import '../../../core/models/stage_row.dart';
import '../../../domain/difficulte_du_sentier.dart';
import '../../../domain/mesure_de_la_journee.dart';
import '../../../domain/nuit_possible.dart';
import '../../../domain/planned_day.dart';
import 'decoupage_sur_les_nuits.dart';
import 'planning_calculator.dart';

/// UNE JOURNEE POSEE : ce qu elle traverse, ce qu elle mesure, et rien de plus.
///
/// C est le produit INTERMEDIAIRE de [JourneesDuSentier], et son interet est
/// qu il n y en ait qu UN : la fiche en tire ses [JourneeMesuree], le programme
/// en tire ses [PlannedDay]. Deux projections d un meme calcul ne peuvent pas
/// divergerentre elles.
class JourneePosee {
  /// Construit une journee posee.
  const JourneePosee({
    required this.numero,
    required this.etapes,
    required this.segments,
    required this.mesure,
  });

  /// Numero de la journee de MARCHE (1-indexed, repos non comptes).
  final int numero;

  /// Les etapes TOUCHEES par la journee, dans l ordre de marche.
  ///
  /// Une seule et partiellement quand la journee s arrete a une nuit interieure
  /// a l etape ; plusieurs quand elle en groupe. La MEME etape peut apparaitre
  /// dans deux journees consecutives — c est le modele de Christophe, « 16
  /// etape en 17 jours ».
  final List<StageModel> etapes;

  /// Les segments entre nuits relevees que la journee reunit. Vides quand la
  /// journee vient du regroupement d etapes entieres.
  final List<SegmentEntreNuits> segments;

  /// Les quatre chiffres de la journee.
  ///
  /// ELLE VOYAGE TOUJOURS, MEME QUAND LA JOURNEE COUVRE DES ETAPES ENTIERES.
  /// Ce modele a porte un instant un drapeau `couvreDesEtapesEntieres` qui
  /// servait a NE PAS transmettre la mesure dans ce cas, au motif qu elle
  /// repetait la somme des etapes. LE MOTIF ETAIT FAUX et le test l a montre :
  /// la somme des trente et un segments entre nuits vaut 183,585 km et la somme
  /// des seize etapes 183,59 km, parce que chaque tranche mesuree est ancree a
  /// ses deux bouts (tache 854). Les deux ne disent pas la meme chose, donc la
  /// mesure POSEE est la seule qui vaille — c est elle que la fiche annonce.
  final MesureDeLaJournee mesure;
}

/// LE SEUL ENDROIT DU DEPOT QUI DECIDE OU LES JOURNEES TOMBENT.
///
/// LE DEFAUT QUE CETTE CLASSE FERME, ET IL ETAIT LIVRE AUX CLIENTS. Jusqu a la
/// tache 855, deux calculs independants posaient les journees du MEME sentier a
/// la MEME allure, et ils ne tombaient pas d accord :
///
///  - la FICHE de vente (`difficulte_calculee.dart`, l.141-164) posait les
///    journees sur les TRENTE ET UNE NUITS relevees du GR20 (tache 838), donc
///    EN COUPANT a l interieur des etapes ;
///  - le PROGRAMME (`PlanningCalculator.distribute`, l.92) ne coupait JAMAIS :
///    en dessous du nombre d etapes il les groupait, au-dela tout jour de plus
///    etait du REPOS.
///
/// A SEIZE JOURS LA FICHE ANNONCAIT UNE PIRE JOURNEE DE 26,48 KM-EFFORT QUAND
/// LE PROGRAMME EN PRODUISAIT UNE DE 36,45. Neuf km-effort d ecart, du cote qui
/// RASSURE A TORT, sur un sentier de haute montagne : le randonneur lisait,
/// AVANT d acheter, une journee plus legere que celle qu il marcherait. Le
/// « mode facile » etait ANNONCE et PAS IMPLEMENTE — la donnee le permettait,
/// la fiche l affichait, le programme ne le faisait pas.
///
/// CE QUI REND LA DIVERGENCE IMPOSSIBLE DESORMAIS, ET CE N EST PAS UN TEST.
/// C est la STRUCTURE : il n y a plus deux calculs qui doivent s accorder, il y
/// a UN calcul et DEUX PROJECTIONS. [poser] pose les journees ; [mesurees] les
/// rend a la fiche, [programme] les rend au client. Un test existe
/// (`la_fiche_et_le_programme_disent_pareil_855_test.dart`) et il rougit si
/// elles divergent, mais il garde un invariant que le code rend deja vrai — ce
/// qui est la seule facon honnete d avoir les deux.
///
/// POURQUOI LE PROGRAMME A LE DROIT DE COUPER, alors que la tache 634 l avait
/// retire. Les deux griefs de Christophe du 29/09 etaient fondes, verbatim :
/// « Decouper les etapes en deux est une mauvaise idee... il n y a pas de
/// refuge et surtout JE N AI JAMAIS DEMANDE CA ». Les deux sont leves, et
/// separement :
///
///  1. LE POINT DE COUPE. Le lot 558 coupait par INTERPOLATION LINEAIRE entre
///     le depart et l arrivee de l etape — ni un lieu releve, ni un
///     hebergement, parfois ni eau ni abri. Ici chaque borne est une
///     [NuitPossible] : identifiant OpenStreetMap, detour aller et retour
///     mesures sur le reseau pieton, lits quand ils sont connus. Aucune coupe
///     n est calculee.
///  2. PERSONNE NE L AVAIT DEMANDE. Christophe l a demande depuis, 18/10 11:03,
///     verbatim : « les etapes du GR restent les etapes du GR. 16 c'et 16, si
///     le gars fait la premiere en 2 fois et bien c'est toujours 16 etape en
///     17 jours ».
///
/// ET LE COMPTE D ETAPES NE BOUGE PAS, CE QUI EST TOUTE LA CONDITION. Couper
/// une journee ne fabrique aucune dix-septieme etape :
/// [PlanningStats.stageCount] compte les numeros DISTINCTS et non les
/// entrees, donc seize etapes etalees
/// sur dix-sept journees restent seize — et le prix, qui est LU au catalogue,
/// n a jamais suivi les jours (garde
/// `le_prix_ne_suit_pas_les_jours_854_test.dart`).
abstract final class JourneesDuSentier {
  JourneesDuSentier._();

  /// POSE LES JOURNEES de [jours] jours de marche, et du plus FIN des deux
  /// decoupages.
  ///
  /// Quand le sentier porte des NUITS RELEVEES, les journees se posent dessus :
  /// chaque fin de journee est un lieu qui existe. Sinon elles viennent du
  /// regroupement des etapes ([PlanningCalculator]). L ecart se MESURE : sur
  /// douze jours de GR20, les etapes de la federation laissent une journee a
  /// 1 824 m de montee la ou les nuits relevees descendent a 1 455 m.
  ///
  /// [etapes] doit DEJA etre oriente dans le sens de marche
  /// ([etapesDansLeSens]) : ce calcul ne permute aucun denivele, la permutation
  /// vit en un seul endroit du depot et ce n est pas ici.
  ///
  /// [nuitsDansLeSensDeLaTrace] est le decoupage tel que la DONNEE le porte,
  /// jamais deja retourne, et [aLEnvers] dit s il faut le retourner. LES DEUX
  /// VOYAGENT ENSEMBLE EXPRES : l attribution d un segment a son etape se fait
  /// sur l ordre de la TRACE (c est la que `finDEtape` a un sens), et recevoir
  /// un decoupage deja retourne rendrait cette attribution indecidable — rien
  /// dans un [DecoupageDeNuits] ne dit s il a deja ete inverse.
  static List<JourneePosee> poser({
    required List<StageModel> etapes,
    required DecoupageDeNuits? nuitsDansLeSensDeLaTrace,
    required bool aLEnvers,
    required int jours,
  }) {
    if (jours <= 0) return const <JourneePosee>[];

    final nuits = nuitsDansLeSensDeLaTrace;
    if (nuits != null && !nuits.vide) {
      return _surLesNuits(
        etapes: etapes,
        nuits: nuits,
        aLEnvers: aLEnvers,
        jours: jours,
      );
    }
    return _surLesEtapes(etapes: etapes, jours: jours);
  }

  /// LES MESURES DES JOURNEES, pour la FICHE de vente.
  ///
  /// C est la projection que [DifficulteDuSentier.calculer] attend.
  static List<JourneeMesuree> mesurees(List<JourneePosee> journees) => [
    for (final journee in journees)
      JourneeMesuree(
        km: journee.mesure.km,
        deniveleM: journee.mesure.deniveleM,
        descenteM: journee.mesure.descenteM,
      ),
  ];

  /// LES JOURNEES EDITABLES, pour le PROGRAMME du client.
  ///
  /// Les jours de REPOS sont ajoutes a la fin du calcul et non ici : ce sont
  /// les journees de MARCHE qui se posent, le repos se glisse entre elles
  /// ([PlanningCalculator] le repartit deja).
  static List<PlannedDay> programme(List<JourneePosee> journees) => [
    for (final journee in journees)
      PlannedDay(
        dayNumber: journee.numero,
        stages: journee.etapes,
        segments: journee.segments,
        // LA MESURE POSEE VOYAGE TOUJOURS, MEME QUAND LA JOURNEE COUVRE DES
        // ETAPES ENTIERES — ET C'EST UNE CORRECTION QUE LE TEST A IMPOSEE.
        //
        // J'avais d'abord laisse tomber la mesure dans ce cas, au motif qu'un
        // champ qui repete ce que `stages` dit deja pourrait un jour le
        // contredire. LE RAISONNEMENT ETAIT FAUX, parce que les deux ne disent
        // PAS la meme chose : la somme des trente et un segments entre nuits
        // vaut 183,585 km et la somme des seize etapes 183,59 km. L'ecart vient
        // de l'ancrage des deux bouts de chaque tranche mesuree — la tache 854
        // l'avait nomme (jusqu'a 0,21 km-effort sur une etape) et il ne
        // disparait pas parce qu'il est petit.
        //
        // Laisser tomber la mesure reintroduisait donc EXACTEMENT le defaut que
        // ce lot ferme : a une journee, la fiche annonçait 183,585 km et le
        // programme 183,59. `la_fiche_et_le_programme_disent_pareil_855_test`
        // l'a attrape au premier passage.
        mesure: journee.mesure,
      ),
  ];

  // --- Les deux decoupages -------------------------------------------------

  static List<JourneePosee> _surLesNuits({
    required List<StageModel> etapes,
    required DecoupageDeNuits nuits,
    required bool aLEnvers,
    required int jours,
  }) {
    // L ATTRIBUTION SE CALCULE SUR L ORDRE DE LA TRACE, une fois pour toutes.
    final etapeDuSegment = _etapeParSegment(nuits);
    final total = nuits.segments.length;
    final parNumero = <int, StageModel>{
      for (final etape in etapes) etape.stageNumber: etape,
    };

    final oriente = aLEnvers ? nuits.aLEnvers : nuits;
    final posees = DecoupageSurLesNuits.repartir(oriente, jours);

    final journees = <JourneePosee>[];
    for (final journee in posees) {
      // LES ETAPES TOUCHEES, DANS L ORDRE DE MARCHE ET SANS DOUBLON. L ordre
      // vient des segments eux-memes : ils sont deja dans le sens choisi.
      final numeros = <int>[];
      for (final segment in journee.segments) {
        final index = aLEnvers ? total - segment.rang : segment.rang - 1;
        final numero = etapeDuSegment[index];
        if (numero != null && !numeros.contains(numero)) numeros.add(numero);
      }

      journees.add(
        JourneePosee(
          numero: journee.numero,
          etapes: [
            for (final numero in numeros)
              if (parNumero[numero] != null) parNumero[numero]!,
          ],
          segments: journee.segments,
          mesure: MesureDeLaJournee(
            km: journee.km,
            deniveleM: journee.deniveleM,
            descenteM: journee.descenteM,
            minutes: journee.minutes,
          ),
        ),
      );
    }
    return journees;
  }

  static List<JourneePosee> _surLesEtapes({
    required List<StageModel> etapes,
    required int jours,
  }) {
    final plans = PlanningCalculator.distribute(
      etapes,
      jours,
    ).where((jour) => !jour.isRestDay).toList(growable: false);

    return [
      for (var i = 0; i < plans.length; i++)
        JourneePosee(
          numero: i + 1,
          etapes: plans[i].stages,
          segments: const <SegmentEntreNuits>[],
          mesure: MesureDeLaJournee(
            km: plans[i].totalDistanceKm,
            deniveleM: plans[i].totalElevationGainM,
            descenteM: plans[i].totalElevationLossM,
            minutes: (plans[i].estimatedDurationHours * 60).round(),
          ),
        ),
    ];
  }

  /// POUR CHAQUE SEGMENT, LE NUMERO D ETAPE AUQUEL IL APPARTIENT.
  ///
  /// LA REGLE, ET ELLE EST DIRECTIONNELLE : un segment appartient a l etape
  /// dont la FIN est la premiere fin d etape rencontree en avancant dans le
  /// sens de la TRACE. Les quinze coupures nouvelles du GR20 tombent a
  /// l interieur d une etape ; le segment qui y arrive appartient donc a
  /// l etape qu il est
  /// en train de traverser, c est-a-dire a celle qui se terminera plus loin.
  ///
  /// L attribution est geometrique, donc INDEPENDANTE du sens de marche : le
  /// meme morceau de sentier appartient a la meme etape qu on le monte ou qu on
  /// le descende. C est pourquoi elle se calcule ici, sur la trace, et que
  /// l appelant ne fait plus que convertir son index.
  static List<int?> _etapeParSegment(DecoupageDeNuits nuits) {
    final finParNom = <String, int>{
      for (final nuit in nuits.nuits)
        if (nuit.finDEtape != null) nuit.nom: nuit.finDEtape!,
    };

    final numeros = List<int?>.filled(nuits.segments.length, null);
    // ON REMONTE DEPUIS LA FIN : le dernier numero d etape VU devient celui de
    // tous les segments qui le precedent et qui n ont pas de fin d etape a eux.
    int? courante;
    for (var i = nuits.segments.length - 1; i >= 0; i--) {
      final fin = finParNom[nuits.segments[i].arrivee];
      if (fin != null) courante = fin;
      numeros[i] = courante;
    }
    return numeros;
  }
}
