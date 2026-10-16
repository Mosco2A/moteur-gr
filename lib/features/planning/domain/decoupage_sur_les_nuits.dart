/// Le decoupage d'un sentier en journees qui FINISSENT TOUTES sur un lieu
/// releve : un refuge, une bergerie, un gite — jamais un point calcule.
library;

import '../../../domain/nuit_possible.dart';

/// UNE JOURNEE DE MARCHE DONT L'ARRIVEE EST UN LIEU QUI EXISTE.
///
/// Elle reunit un ou plusieurs [SegmentEntreNuits] consecutifs ; ses chiffres
/// sont la SOMME de segments mesures sur la trace, et son arrivee est une
/// [NuitPossible] relevee dans OpenStreetMap.
class JourneeSurLesNuits {
  /// Construit une journee a partir de ses segments (deja consecutifs).
  const JourneeSurLesNuits({
    required this.numero,
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
    required this.segments,
  });

  /// Numero du jour (1-indexed).
  final int numero;

  /// Nom du lieu de depart de la journee.
  final String depart;

  /// La nuit ou la journee se termine.
  final NuitPossible arrivee;

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
  static List<JourneeSurLesNuits> repartir(
    DecoupageDeNuits decoupage,
    int journees,
  ) {
    if (decoupage.vide || journees <= 0) return const <JourneeSurLesNuits>[];
    final segments = decoupage.segments;
    final cible = journees > segments.length ? segments.length : journees;

    final coupes = _coupesEquilibrees(segments, cible);
    final nuitsParNom = <String, NuitPossible>{
      for (final n in decoupage.nuits) n.nom: n,
    };

    final jours = <JourneeSurLesNuits>[];
    for (var j = 0; j < coupes.length; j++) {
      final debut = coupes[j];
      final fin = j + 1 < coupes.length ? coupes[j + 1] : segments.length;
      final tranche = segments.sublist(debut, fin);
      final arrivee = nuitsParNom[tranche.last.arrivee];
      // Une arrivee introuvable signifierait une donnee incoherente (un segment
      // qui finit ailleurs que sur une nuit declaree) : on ne devine pas, on
      // laisse tomber la journee plutot que d'inventer un lieu.
      if (arrivee == null) continue;
      jours.add(
        JourneeSurLesNuits(
          numero: jours.length + 1,
          depart: tranche.first.depart,
          arrivee: arrivee,
          km: tranche.fold<double>(0, (s, x) => s + x.km),
          deniveleM: tranche.fold<int>(0, (s, x) => s + x.deniveleM),
          descenteM: tranche.fold<int>(0, (s, x) => s + x.descenteM),
          minutes:
              tranche.fold<int>(0, (s, x) => s + x.minutes) +
              arrivee.minutesAller +
              _retourDeLaVeille(segments, nuitsParNom, debut),
          segments: tranche,
        ),
      );
    }
    return jours;
  }

  /// Minutes pour REVENIR sur la trace depuis la nuit de la veille.
  ///
  /// Zero le premier jour (on part de la tete de sentier). Les autres jours
  /// commencent par remonter la ou l'on a quitte le sentier la veille — et
  /// c'est precisement le chiffre que la tache 838 a mesure separement, parce
  /// qu'il n'est pas symetrique (refuge Laparo : 10 minutes a l'aller,
  /// 28 minutes au retour).
  static int _retourDeLaVeille(
    List<SegmentEntreNuits> segments,
    Map<String, NuitPossible> nuits,
    int debut,
  ) {
    if (debut == 0) return 0;
    final veille = nuits[segments[debut - 1].arrivee];
    return veille?.minutesRetour ?? 0;
  }

  /// Les index de DEBUT de chaque journee, equilibres sur le temps de marche.
  ///
  /// Meme esprit que la repartition d'etapes de [PlanningCalculator] : on vise
  /// une charge moyenne par jour et on coupe des qu'on l'atteint, en gardant
  /// toujours assez de segments pour les jours restants. La garantie est forte
  /// et c'est elle qui compte : AUTANT de journees que demande, chacune non
  /// vide, et chacune terminee sur un lieu releve.
  static List<int> _coupesEquilibrees(
    List<SegmentEntreNuits> segments,
    int journees,
  ) {
    final n = segments.length;
    if (journees >= n) return List<int>.generate(n, (i) => i);

    final total = segments.fold<int>(0, (s, x) => s + x.minutes);
    final parJour = total / journees;

    final coupes = <int>[0];
    var cumul = 0.0;
    for (var i = 0; i < n && coupes.length < journees; i++) {
      cumul += segments[i].minutes;
      final joursRestants = journees - coupes.length;
      final segmentsRestants = n - i - 1;
      if (cumul >= parJour && segmentsRestants >= joursRestants) {
        coupes.add(i + 1);
        cumul = 0;
      }
    }
    // Si la charge s'est concentree en tete, la boucle peut sortir avec moins
    // de coupes que de journees demandees. On complete alors PAR LA FIN : les
    // dernieres journees prennent un segment chacune. Le COMPTE demande est
    // ainsi garanti sans jamais couper ailleurs qu'a une nuit relevee.
    if (coupes.length < journees) {
      final completes = <int>{...coupes};
      var position = n - 1;
      while (completes.length < journees && position > 0) {
        completes.add(position);
        position--;
      }
      final finales = completes.toList()..sort();
      return finales;
    }
    return coupes;
  }
}
