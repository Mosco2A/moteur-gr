/// LES BORNES DES ETAPES SUR LA TRACE, ET LES CHIFFRES D'UN PERIMETRE —
/// L'UNIQUE SOURCE DE VERITE DE « SUR QUELLE ETAPE SUIS-JE » (tache 747).
///
/// CE QUI NE MARCHAIT PAS, MESURE AVANT CORRECTIF. Retour de Christophe du
/// 09/10 08:55, mot pour mot : « Le changement d'etapes ne fonctionne pas,
/// c'est alleatoire le changement ». DEUX detecteurs geographiques tournaient
/// en parallele sur le MEME flux de positions, avec DEUX formules differentes,
/// et aucun des deux ne regardait l'abscisse du marcheur sur la trace :
///
///   * `StageDetector.detect` (`core/geo/stage_detector.dart`) — celui qui
///     nourrit le nom affiche par la barre — prend l'etape qui minimise
///     `distance(depart) + distance(arrivee)`. C'est une SOMME, donc un score
///     d'ellipse : il n'y a aucun test d'appartenance, aucun ordre, aucune
///     memoire. Une etape COURTE a toujours une petite somme : elle gagne donc
///     contre l'etape reellement sous les pieds des que le marcheur s'eloigne
///     de ses deux bornes.
///   * `StageDetectionService` (`features/trek/data/`) — celui qui etiquette
///     les points de trace — prend `min(distance(depart), distance(arrivee))`
///     avec 200 m d'hysteresis. `min` et `somme` ne classent pas les etapes
///     dans le meme ordre : les deux repondaient donc regulierement DEUX
///     etapes differentes pour la meme position.
///
/// REJOUE SUR LA TRACE REELLE DU SENTIER DE DEMONSTRATION (53 points,
/// 72,892 km), A L'ABSCISSE 63,0 km — celle de la capture de l'ecran de
/// Christophe : la verite par abscisse est l'etape 7 « Bastelica - Porticcio »,
/// et le detecteur par somme repondait l'etape 5
/// « Zicavo - Cuttoli-Corticchiato » — EXACTEMENT le nom affiche sur son
/// telephone. Le long du sentier, sa suite de reponses est
/// 1,1,2,2,3,3,4,5,6,6,6,6,5,5,5,7,7 : elle RECULE de 6 vers 5 avant de sauter
/// a 7. Un randonneur ne revient pas a l'etape d'hier en avancant.
///
/// CE QUE CE FICHIER MET A LA PLACE, ET POURQUOI C'EST LA BONNE QUANTITE.
/// L'ABSCISSE CURVILIGNE du marcheur sur la trace
/// (`TrackPositionState.distanceFromStartM`) etait DEJA calculee deux lignes
/// au-dessus de l'appel au detecteur, et elle etait jetee. Elle est
/// strictement croissante quand on avance, elle vaut un seul nombre, et elle
/// ne depend d'aucun seuil : comparee a des bornes elles-memes exprimees en
/// abscisse, elle ne peut NI hesiter NI reculer. Il n'y a donc plus besoin
/// d'hysteresis — il n'y a plus de clignotement a amortir.
///
/// AUCUN SECOND MOTEUR DE CALCUL N'EST INTRODUIT. Les abscisses ne sont pas
/// mesurees ici : chaque [TrackPoint] porte deja son `distanceFromStart`,
/// pose par le chargeur de trace. Ce fichier ne fait que LIRE ces distances
/// aux points de bornage et COMPARER. Pas de Haversine, pas de projection, pas
/// de cumul.
library;

import '../../../core/geo/trace_point.dart';
import '../../../core/models/stage_row.dart';
import 'stage_focus.dart' show nearestTrackPointIndex;

/// UNE ETAPE REDUITE A SA TRANCHE DE TRACE : son numero et ses deux bornes,
/// en metres depuis le depart du sentier.
class JalonDEtape {
  /// Cree un jalon. [finM] n'est jamais inferieur a [debutM] : c'est
  /// [jalonsDesEtapes] qui en repond.
  const JalonDEtape({
    required this.numero,
    required this.debutM,
    required this.finM,
  });

  /// Numero de l'etape (`StageModel.stageNumber`).
  final int numero;

  /// Abscisse du DEPART de l'etape sur la trace, en metres.
  final double debutM;

  /// Abscisse de l'ARRIVEE de l'etape sur la trace, en metres.
  final double finM;

  /// Longueur de la tranche, en metres. Jamais negative.
  double get longueurM => finM - debutM;

  /// Vrai si [abscisseM] tombe dans la tranche, borne de depart INCLUSE et
  /// borne d'arrivee EXCLUE.
  ///
  /// L'exclusion de la fin est ce qui empeche deux etapes voisines de se
  /// declarer toutes les deux courantes au refuge qui les separe — le defaut
  /// exact de l'ancien detecteur, qui rendait la premiere de la liste.
  /// L'arrivee du SENTIER est rattrapee a part par [jalonALAbscisse].
  bool contient(double abscisseM) => abscisseM >= debutM && abscisseM < finM;
}

/// LES BORNES DES ETAPES SUR LA TRACE — une PARTITION, sans trou ni
/// chevauchement.
///
/// COMMENT LES BORNES SONT TROUVEES. Une etape porte les coordonnees de son
/// depart et de son arrivee ; le point de trace le plus proche de ces
/// coordonnees porte, lui, son abscisse. On lit donc l'abscisse du point de
/// trace le plus proche du DEPART de chaque etape, et c'est tout — la fin
/// d'une etape est le debut de la suivante, par definition d'un sentier
/// continu. Les deux extremites sont posees d'office : le sentier commence a
/// zero et finit au bout de la trace, quoi que disent les coordonnees de la
/// premiere et de la derniere etape.
///
/// POURQUOI UNE PARTITION, ET PAS DES TRANCHES INDEPENDANTES. C'est ce qui
/// rend les chiffres RECONCILIABLES : les longueurs des tranches s'additionnent
/// EXACTEMENT a la longueur de la trace, donc la somme des etapes et le sentier
/// entier sont le meme sentier. Des tranches calculees chacune de son cote —
/// depart le plus proche ET arrivee la plus proche — laisseraient des trous aux
/// endroits ou la trace passe loin d'un village, et le total des etapes ne
/// vaudrait plus le total du sentier.
///
/// LES BORNES SONT FORCEES CROISSANTES. Sur une trace grossiere, le point le
/// plus proche du depart de l'etape N+1 peut tomber AVANT celui de l'etape N
/// (un lacet, deux villages proches). On relache alors la borne sur la
/// precedente : la tranche devient vide, mais l'ordre des etapes est preserve
/// et la progression ne peut pas reculer. Une tranche vide se lit comme une
/// etape deja franchie, ce qui est le moins faux.
///
/// Rend une liste VIDE quand il n'y a rien d'exploitable (moins de deux points
/// de trace, aucune etape, trace de longueur nulle) : l'appelant retombe alors
/// sur le sentier entier plutot que d'inventer un decoupage.
List<JalonDEtape> jalonsDesEtapes(
  List<TrackPoint> trace,
  List<StageModel> etapes,
) {
  if (trace.length < 2 || etapes.isEmpty) return const [];
  final longueurM = trace.last.distanceFromStart;
  if (longueurM <= 0) return const [];

  // L'ORDRE DU SENTIER, PAS CELUI DE LA BASE. La source rend les lignes dans
  // l'ordre qu'elle veut ; tout ce qui suit suppose des etapes croissantes.
  final ordonnees = [...etapes]
    ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

  // Les n+1 bornes : 0, les departs des etapes 2..n, puis le bout de la trace.
  final bornes = <double>[0];
  for (var i = 1; i < ordonnees.length; i++) {
    final etape = ordonnees[i];
    final index = nearestTrackPointIndex(trace, etape.startLat, etape.startLng);
    final abscisse = trace[index].distanceFromStart;
    // Croissance forcee, et jamais au-dela du bout de la trace.
    final plancher = bornes[i - 1];
    bornes.add(abscisse.clamp(plancher, longueurM));
  }
  bornes.add(longueurM);

  return [
    for (var i = 0; i < ordonnees.length; i++)
      JalonDEtape(
        numero: ordonnees[i].stageNumber,
        debutM: bornes[i],
        // La derniere borne est le bout de la trace : elle ne peut pas etre
        // inferieure a la precedente, le clamp s'en est assure.
        finM: bornes[i + 1] < bornes[i] ? bornes[i] : bornes[i + 1],
      ),
  ];
}

/// L'ETAPE SOUS LES PIEDS DU MARCHEUR, a l'abscisse [abscisseM].
///
/// MONOTONE PAR CONSTRUCTION : les tranches sont ordonnees et disjointes, donc
/// une abscisse qui croit ne peut designer qu'une etape de numero croissant.
/// C'est toute la difference avec l'ancien detecteur geographique.
///
/// LES DEUX BOUTS SONT RATTRAPES, et ce n'est pas un detail d'implementation :
///   * avant le depart (abscisse negative, ou trace qui commence plus loin),
///     c'est la PREMIERE etape — on n'est pas « nulle part », on n'est pas
///     parti ;
///   * AU BOUT EXACT de la trace, c'est la DERNIERE etape. Sans ce rattrapage
///     l'arrivee ne serait contenue par aucune tranche ([JalonDEtape.contient]
///     exclut sa borne de fin) et le marcheur « sortirait » du sentier au
///     moment precis ou il le termine — soit exactement quand l'ecran doit le
///     feliciter (retour de Christophe du 09/10 08:59).
///
/// `null` seulement si [jalons] est vide.
JalonDEtape? jalonALAbscisse(List<JalonDEtape> jalons, double abscisseM) {
  if (jalons.isEmpty) return null;
  for (final jalon in jalons) {
    if (jalon.contient(abscisseM)) return jalon;
  }
  // Hors de toutes les tranches : avant le debut, ou au bout exact.
  return abscisseM <= jalons.first.debutM ? jalons.first : jalons.last;
}

/// LA PROCHAINE FIN D'ETAPE DEVANT LE MARCHEUR, ou `null` s'il n'y en a plus.
///
/// C'EST LA CIBLE DU BOUTON « Simuler l'etape suivante » (tache 747) : la plus
/// petite borne d'arrivee STRICTEMENT devant [abscisseM].
///
/// POURQUOI « LA PLUS PETITE DEVANT » ET NON « LA FIN DE L'ETAPE COURANTE ».
/// Les deux coincident presque toujours, mais pas quand une tranche est VIDE —
/// ce que la croissance forcee des bornes peut produire sur une trace
/// grossiere (cf. [jalonsDesEtapes]). La fin de l'etape courante serait alors
/// derriere le marcheur, le saut n'avancerait rien, et le bouton redeviendrait
/// un geste mort. Chercher la premiere borne DEVANT enjambe ces tranches vides
/// sans cas particulier.
///
/// `null` signifie « plus rien a franchir » : le marcheur est au bout du
/// sentier, et c'est l'ARRIVEE qu'il reste a simuler.
double? prochaineFinDEtape(List<JalonDEtape> jalons, double abscisseM) {
  double? plusProche;
  for (final jalon in jalons) {
    if (jalon.finM <= abscisseM) continue;
    if (plusProche == null || jalon.finM < plusProche) plusProche = jalon.finM;
  }
  return plusProche;
}

/// COMBIEN D'ETAPES SONT FAITES A L'ABSCISSE [abscisseM] (tache 762).
///
/// A QUOI ELLE SERT. La vue « sentier entier » montre le compte des etapes
/// faites a la place de l'altitude — decision de Christophe du 09/10 16:32,
/// forme « 3 / 7 ».
///
/// CE QU'ELLE NE LIT PAS, ET CE N'EST PAS UN DETAIL. Le chiffre existait DEJA
/// ailleurs sous une autre forme : `TrekSession.completedStages`, un ENSEMBLE
/// D'IDENTIFIANTS alimente par les evenements d'arrivee et par le bouton de
/// saut d'etape. Le compter aurait remis dans la barre exactement ce que la
/// tache 747 en a sorti — un compteur nourri par des EVENEMENTS a cote de
/// chiffres nourris par l'ABSCISSE, c'est-a-dire deux sources de verite.
///
/// ET CET ENSEMBLE PEUT DIRE FAUX, PAR CONSTRUCTION : le bouton de saut y
/// inscrit d'un coup TOUTES les etapes dont la borne est derriere la cible,
/// tranches vides comprises (`simulerLEtapeSuivante`), et les evenements GPS y
/// entrent dans l'ordre ou ils arrivent, pas dans l'ordre du sentier. Il ne
/// diminue jamais et il ne mesure rien.
///
/// LA DEFINITION RETENUE EST GEOMETRIQUE : UNE ETAPE EST FAITE QUAND L'ABSCISSE
/// DU MARCHEUR A DEPASSE SA BORNE DE FIN. Elle se lit sur la MEME source que
/// les cinq autres chiffres de la barre, elle ne peut pas reculer tant que
/// l'abscisse avance, et elle se reconcilie au bout : au bout exact de la
/// trace, toutes les bornes sont derriere, donc le compte vaut le total. Elle
/// compte du TERRAIN COUVERT, pas des evenements recus.
int etapesFaites(List<JalonDEtape> jalons, double abscisseM) {
  var faites = 0;
  for (final jalon in jalons) {
    if (abscisseM >= jalon.finM) faites++;
  }
  return faites;
}

/// LES CHIFFRES D'UN PERIMETRE : son total, ce qui est parcouru, ce qui reste.
///
/// L'INVARIANT EST TENU PAR CONSTRUCTION, ET C'EST LA RAISON D'ETRE DE CETTE
/// CLASSE. Retour de Christophe du 09/10, sur une barre qui affichait en meme
/// temps Total 84,0 km, Parcouru 63,0 km et « 9,9 km restants » : trois nombres
/// qui ne peuvent pas etre vrais ensemble, parce que 84 moins 63 font 21. La
/// cause mesuree : le total venait de la FICHE du sentier (somme des sept
/// etapes, 84,0 km) tandis que le restant et le pourcentage etaient mesures sur
/// la TRACE GPX (72,892 km). Deux totaux pour un seul sentier.
///
/// Ici il n'y a qu'UN total et qu'UNE mesure. [restantM] n'est pas mesure : il
/// est le total MOINS le parcouru, une seule soustraction. Il est donc
/// impossible que la somme ne retombe pas sur le total, et le pourcentage est
/// le rapport de ces memes deux nombres — pas d'un troisieme.
class ChiffresDuPerimetre {
  /// [totalM] est ramene a zero s'il est negatif, et [parcouruM] est borne
  /// dans [0, totalM] : une barre ne montre jamais 110 % ni un parcouru
  /// negatif, meme si une position aberrante arrive.
  factory ChiffresDuPerimetre({
    required double totalM,
    required double parcouruM,
  }) {
    final total = totalM > 0 ? totalM : 0.0;
    return ChiffresDuPerimetre._(
      totalM: total,
      parcouruM: parcouruM.clamp(0.0, total),
    );
  }

  /// Les chiffres d'une tranche `[debutM, finM]` ou le marcheur est a
  /// [abscisseM] : le total est la longueur de la tranche, le parcouru est ce
  /// qui separe le marcheur de son debut.
  factory ChiffresDuPerimetre.surLaTranche({
    required double debutM,
    required double finM,
    required double abscisseM,
  }) =>
      ChiffresDuPerimetre(totalM: finM - debutM, parcouruM: abscisseM - debutM);

  const ChiffresDuPerimetre._({required this.totalM, required this.parcouruM});

  /// Longueur du perimetre, en metres.
  final double totalM;

  /// Ce qui est parcouru dans ce perimetre, en metres.
  final double parcouruM;

  /// Ce qui RESTE : le total moins le parcouru, et rien d'autre.
  double get restantM => totalM - parcouruM;

  /// La part parcourue, de 0 a 1. Zero quand le perimetre est vide — un
  /// rapport sur un total nul n'a pas de valeur a montrer.
  double get ratio => totalM <= 0 ? 0 : parcouruM / totalM;

  /// Le total en kilometres.
  double get totalKm => totalM / 1000;

  /// Le parcouru en kilometres.
  double get parcouruKm => parcouruM / 1000;

  /// Le restant en kilometres.
  double get restantKm => restantM / 1000;
}
