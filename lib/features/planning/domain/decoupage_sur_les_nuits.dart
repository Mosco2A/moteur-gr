/// Le decoupage d'un sentier en journees qui FINISSENT TOUTES sur un lieu
/// releve : un refuge, une bergerie, un gite — jamais un point calcule.
library;

import '../../../domain/nuit_possible.dart';
import '../../../domain/repartition_equilibree.dart';

/// UNE JOURNEE DE MARCHE DONT L'ARRIVEE EST UN LIEU QUI EXISTE.
///
/// Elle reunit un ou plusieurs [SegmentEntreNuits] consecutifs ; ses chiffres
/// sont la SOMME de segments mesures sur la trace, et son arrivee est un lieu
/// releve dans OpenStreetMap — une [NuitPossible] quand on y dort, la tete de
/// sentier quand la journee y revient.
class JourneeSurLesNuits {
  /// Construit une journee a partir de ses segments (deja consecutifs).
  const JourneeSurLesNuits({
    required this.numero,
    required this.depart,
    required this.arriveeNom,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
    required this.deniveleDuDetourM,
    required this.descenteDuDetourM,
    required this.segments,
  });

  /// Numero du jour (1-indexed).
  final int numero;

  /// Nom du lieu de depart de la journee.
  final String depart;

  /// LE NOM DU LIEU OU LA JOURNEE SE TERMINE — toujours connu (tache 853).
  ///
  /// Il vient du segment, qui le porte toujours. [arrivee] peut etre nulle (le
  /// lieu n'est pas une nuit RELEVEE), le nom jamais : une journee s'arrete
  /// quelque part, et ce quelque part a un nom.
  final String arriveeNom;

  /// LA NUIT RELEVEE OU LA JOURNEE SE TERMINE, ou `null` quand le lieu
  /// d'arrivee n'en est pas une.
  ///
  /// LE CAS REEL, ET IL ETAIT UN DEFAUT LIVRE : LA TETE DE SENTIER. En sens
  /// inverse, la derniere journee du GR20 arrive a Calenzana — qui n'est pas
  /// une nuit relevee, parce qu'on y dort AVANT de partir et pas pendant. Le
  /// repartiteur laissait alors tomber cette journee EN SILENCE et rendait
  /// QUINZE journees pour SEIZE demandees, en contredisant la garantie ecrite
  /// deux lignes au-dessus de lui.
  ///
  /// Nulle veut dire « pas de nuit relevee ici, donc aucun detour a compter »,
  /// et c'est exact : la tete de sentier est SUR la trace, au point
  /// kilometrique zero.
  final NuitPossible? arrivee;

  /// Longueur de la journee, en km (somme des segments).
  final double km;

  /// Denivele positif de la journee, en metres (somme des segments).
  final int deniveleM;

  /// Denivele negatif de la journee, en metres (somme des segments).
  final int descenteM;

  /// Temps de marche de la journee, detour vers le couchage COMPRIS.
  ///
  /// Le detour compte : une nuit a vingt-deux minutes de la trace, c'est
  /// vingt-deux minutes de marche de plus ce soir-la, et seize de plus le
  /// lendemain matin. Les taire ferait passer une journee pour plus courte
  /// qu'elle n'est, ce qui est exactement ce qu'on ne veut pas annoncer.
  final int minutes;

  /// Montee du DETOUR seul, en metres : y descendre le soir, en remonter le
  /// matin. Zero quand les deux nuits concernees sont sur la trace.
  ///
  /// Elle est deja COMPRISE dans [deniveleM] ; elle est exposee a part pour
  /// qu'on puisse dire au marcheur d'ou viennent ses metres, et pour qu'un test
  /// puisse la mesurer sans refaire la somme.
  final int deniveleDuDetourM;

  /// Descente du DETOUR seul, en metres. Deja comprise dans [descenteM].
  final int descenteDuDetourM;

  /// Les segments mesures que cette journee reunit.
  final List<SegmentEntreNuits> segments;

  /// Nombre de segments reunis dans la journee.
  int get segmentCount => segments.length;
}

/// REPARTIT UN SENTIER SUR N JOURNEES, EN NE S'ARRETANT QUE SUR DES LIEUX
/// RELEVES.
///
/// CE QUE CE CALCUL DEBLOQUE, ET CE QU'IL NE REOUVRE PAS. Le lot 558 avait
/// ajoute un decoupage d'etape que Christophe a refuse le 29/09, verbatim :
/// « Decouper les etapes en deux est une mauvaise idee... il n'y a pas de
/// refuge et surtout JE N'AI JAMAIS DEMANDE CA ». La tache 634 l'a retire,
/// et le grief etait double : le point de coupe etait une INTERPOLATION
/// entre le depart et l'arrivee de l'etape, et personne n'avait demande la
/// fonctionnalite.
///
/// Le premier grief tombe ici, et seulement ici : les points de coupe sont les
/// trente et une [NuitPossible] relevees par la tache 838 — identifiant
/// OpenStreetMap, temps de marche aller ET retour mesures sur le reseau pieton,
/// lits quand ils sont connus. Aucune coupe n'est calculee : chacune est un
/// endroit ou l'on dort. Le second grief reste entier et ce code n'y touche
/// pas : rien n'est impose, [PlanningCalculator] garde exactement son
/// comportement, et c'est le randonneur qui pousse le curseur.
///
/// POURQUOI LA CHARGE ET NON LA DISTANCE. On equilibre les journees sur leur
/// TEMPS DE MARCHE, calcule par le modele unique du depot (4 km/h a plat,
/// 400 m de montee a l'heure, descente payee 1,67 s par metre). Equilibrer les
/// kilometres donnerait des journees egales sur la carte et tres inegales dans
/// les jambes : sur le GR20, 11,35 km de Calenzana a Ortu di u Piobbu coutent
/// 6 h 34 quand 13,21 km de Paliri a Conca en coutent 4 h 34.
abstract final class DecoupageSurLesNuits {
  DecoupageSurLesNuits._();

  /// Repartit [decoupage] sur [journees] jours de marche.
  ///
  /// Rend une liste vide si le sentier n'offre aucune nuit, si [journees] est
  /// nul ou negatif. [journees] est RAMENE a
  /// [DecoupageDeNuits.journeesMaximales] : au-dela, il faudrait inventer un
  /// point d'arret, et ce calcul n'en invente aucun.
  ///
  /// Les segments gardent leur ordre : on ne marche pas l'etape 6 avant la 5.
  ///
  /// LA GARANTIE DE COMPTE TIENT DESORMAIS POUR DE BON (tache 853) : la liste
  /// rendue porte EXACTEMENT `min(journees, nombre de segments)` journees. Elle
  /// etait annoncee et elle ne tenait pas — une journee dont l'arrivee n'etait
  /// pas une nuit relevee disparaissait en silence, et c'est le cas de la
  /// derniere journee du sens inverse, qui revient a la tete de sentier.
  static List<JourneeSurLesNuits> repartir(
    DecoupageDeNuits decoupage,
    int journees, {
    double Function(int debutSegment, int finSegment)? effortDuGroupe,
  }) {
    if (decoupage.vide || journees <= 0) return const <JourneeSurLesNuits>[];
    final segments = decoupage.segments;
    final cible = journees > segments.length ? segments.length : journees;

    final coupes = _coupesEquilibrees(segments, cible, effortDuGroupe);
    final nuitsParNom = <String, NuitPossible>{
      for (final n in decoupage.nuits) n.nom: n,
    };

    final jours = <JourneeSurLesNuits>[];
    for (var j = 0; j < coupes.length; j++) {
      final debut = coupes[j];
      final fin = j + 1 < coupes.length ? coupes[j + 1] : segments.length;
      final tranche = segments.sublist(debut, fin);

      // L'ARRIVEE N'EST PAS TOUJOURS UNE NUIT RELEVEE, ET CE N'EST PAS UNE
      // DONNEE INCOHERENTE (tache 853). Ce code laissait tomber la journee
      // quand il ne retrouvait pas son arrivee dans la table des nuits, au nom
      // de « ne pas inventer un lieu ». Or le lieu n'est jamais invente : il
      // est ECRIT dans le segment. Le seul cas reel est la TETE DE SENTIER, ou
      // la derniere journee du sens inverse revient — Calenzana, qui n'est pas
      // une nuit relevee parce qu'on y dort avant de partir. Le repartiteur
      // rendait donc QUINZE journees pour SEIZE demandees, sans un mot, en
      // contredisant la garantie que `_coupesEquilibrees` annonce juste en
      // dessous : « AUTANT de journees que demande ».
      //
      // ON GARDE LA JOURNEE ET ON NE DEVINE RIEN : le nom vient du segment, et
      // l'absence de nuit relevee vaut DETOUR NUL — ce qui est exact pour une
      // tete de sentier, qui est sur la trace au kilometre zero.
      final arrivee = nuitsParNom[tranche.last.arrivee];
      final veille = debut == 0
          ? null
          : nuitsParNom[segments[debut - 1].arrivee];

      // LE DETOUR COMPTE AUSSI EN METRES, PLUS SEULEMENT EN MINUTES
      // (tache 853). Les minutes du detour entraient dans la journee depuis la
      // tache 838 ; ses metres, mesures par le meme releve, n'entraient dans
      // rien. Une journee qui finit au refuge Laparo descend 126 m le soir et
      // les remonte le lendemain matin avant d'avoir avance d'un metre sur la
      // trace. On ajoute donc, exactement comme pour le temps : le detour
      // ALLER de l'arrivee du jour, et le detour RETOUR de la nuit de la
      // veille.
      final deniveleDuDetour =
          (arrivee?.deniveleAllerM ?? 0) + (veille?.deniveleRetourM ?? 0);
      final descenteDuDetour =
          (arrivee?.descenteAllerM ?? 0) + (veille?.descenteRetourM ?? 0);

      jours.add(
        JourneeSurLesNuits(
          numero: jours.length + 1,
          depart: tranche.first.depart,
          arriveeNom: tranche.last.arrivee,
          arrivee: arrivee,
          km: tranche.fold<double>(0, (s, x) => s + x.km),
          deniveleM:
              tranche.fold<int>(0, (s, x) => s + x.deniveleM) +
              deniveleDuDetour,
          descenteM:
              tranche.fold<int>(0, (s, x) => s + x.descenteM) +
              descenteDuDetour,
          minutes:
              tranche.fold<int>(0, (s, x) => s + x.minutes) +
              (arrivee?.minutesAller ?? 0) +
              (veille?.minutesRetour ?? 0),
          deniveleDuDetourM: deniveleDuDetour,
          descenteDuDetourM: descenteDuDetour,
          segments: tranche,
        ),
      );
    }
    return jours;
  }

  /// Les index de DEBUT de chaque journee, equilibres sur l'EFFORT quand
  /// l'appelant sait le chiffrer, sur le temps de marche sinon.
  ///
  /// La garantie est forte et c'est elle qui compte : AUTANT de journees que
  /// demande, chacune non vide, et chacune terminee sur un lieu releve.
  ///
  /// TACHE 848 — LE COMPTE ETAIT TENU, L'EQUILIBRE NE L'ETAIT PAS. Ce calcul
  /// visait la charge moyenne et coupait des qu'il l'atteignait ; quand la
  /// charge se concentrait en tete — et sur le GR20 elle s'y concentre, le nord
  /// porte 7 401 m de montee contre 4 243 m au sud —, il sortait avec moins de
  /// coupes que de journees et se completait PAR LA FIN, une journee par
  /// segment. Le compte etait juste et les journees fausses : sur douze jours,
  /// la journee la plus dure du GR20 pesait 2 088 m de montee alors que le
  /// decoupage le PERMETTAIT a 1 455 m — 633 m de montee de trop, le tiers
  /// d'une journee, pose sur le dos du marcheur par un defaut d'algorithme.
  ///
  /// [RepartitionEquilibree] rend les deux : le compte ET la journee la plus
  /// chargee aussi legere que possible. Elle est partagee avec le regroupement
  /// d'etapes de [PlanningCalculator] — un seul algorithme de repartition dans
  /// le depot, comme il n'y a qu'un seul modele de temps de marche.
  static List<int> _coupesEquilibrees(
    List<SegmentEntreNuits> segments,
    int journees,
    double Function(int debutSegment, int finSegment)? effortDuGroupe,
  ) {
    // LE DECOUPAGE SE FAIT A L'EFFORT DES QUE L'APPELANT SAIT LE DIRE
    // (tache 860). Christophe, verbatim 19/10 : « Oui a l'effort pas au
    // temps ». L'ecart n'est pas cosmetique : egaliser les MINUTES fabrique
    // des journees de meme duree et d'effort tres inegal, parce qu'une heure
    // de montee raide et une heure de plat ne demandent pas la meme chose.
    if (effortDuGroupe != null) {
      return RepartitionEquilibree.coupesSelon(
        unites: segments.length,
        groupes: journees,
        chargeDuGroupe: effortDuGroupe,
      );
    }
    // SANS PROFIL, ON RETOMBE SUR LE TEMPS DE MARCHE, et c'est le bon repli :
    // un sentier sans trace altimetrisee n'a pas d'indice de terrain, donc
    // aucun effort a egaliser. Le compte des journees, lui, reste garanti.
    return RepartitionEquilibree.coupes(
      segments.map((s) => s.minutes.toDouble()).toList(growable: false),
      journees,
    );
  }
}
