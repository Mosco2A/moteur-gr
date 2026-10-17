/// La difficulte d'un sentier : QUATRE bandes, un effort par JOURNEE calcule
/// sur la distance et les deux deniveles, et un verdict de TRONCON qui part de
/// la pire journee — avec la regle dite a cote du resultat.
library;

import 'echelle_de_difficulte.dart';

/// LA DIFFICULTE NE S'AFFIRME PAS, ELLE SE CALCULE — ET ON DIT DE QUOI.
///
/// POURQUOI CE FICHIER EXISTE. La fiche d'un sentier ne portait AUCUNE
/// difficulte (mesure du 17/10). La facon la plus simple de la lui donner
/// aurait ete une etiquette dans la configuration — `difficulte: 'hard'` — et
/// c'est exactement ce qu'il ne faut pas faire : une etiquette est une OPINION
/// que rien ne contredit, elle se recopie d'un sentier a l'autre, et elle ne
/// bouge pas quand le randonneur choisit de marcher le meme chemin en sept
/// jours au lieu de seize. Le depot a deja paye ce genre d'affirmation : seize
/// longueurs d'etape venues d'un topo et remises a l'echelle, justes au total
/// et fausses partout ailleurs (tache 839).
///
/// DEUX METHODES, PARCE QU'UNE JOURNEE ET UN TRONCON NE SE MESURENT PAS PAREIL.
/// Christophe, 17/10 17:25, verbatim : « facile/moyen/Difficile/tres difficile
/// === et tu mets une methode de calcul par etape et une par troncon »
/// (memoire #102180).
///
///  1. PAR JOURNEE — [SeuilsDeDifficulte.effortDeLaJournee]. L'effort d'UNE
///     journee se calcule sur les TROIS ingredients qu'il a nommes : la
///     distance, le denivele POSITIF et le denivele NEGATIF. Pas sur le seul
///     D+, qui disait « difficile » d'une journee de 25 km.
///  2. PAR TRONCON — [DifficulteDuSentier.verdict]. Ni la somme ni la moyenne :
///     la PIRE journee donne le PLANCHER, et l'ACCUMULATION peut le monter d'un
///     cran. « Un troncon avec une journee dure n'est pas un troncon avec six
///     journees dures d'affilee. »
///
/// QUATRE BANDES, PLUS CINQ — ET LA FEDERATION N'EN A JAMAIS EU CINQ NON PLUS.
/// La bande « expert » a vecu une journee (17/10 11:04 au 17/10 17:25) et elle
/// est SUPPRIMEE. Ce n'est pas un retrait de confort : l'echelle d'effort de la
/// FFRandonnee s'arrete elle aussi a « difficile » et n'a jamais porte de bande
/// expert. Tout ce qui etait annonce expert retombe dans TRES DIFFICILE, qui
/// devient la bande du haut, OUVERTE — il n'y a plus de cran au-dessus.
///
/// CE QUI EST SORTI DU CALCUL, ET IL FAUT LE DIRE. La version de la tache 846
/// retenait le denivele MOYEN par journee et l'ALTITUDE MAXIMALE ; Christophe
/// les a sortis le 17/10 11:04 (« non la difficulte c'est surtout base sur
/// l'etape la plus compliquee et le denivele le plus fort »). Ils restent
/// sortis. L'altitude reste MESUREE et la fiche la cite (2 578 m sur le GR20),
/// mais elle ne produit aucun niveau.
///
/// CE QUI EST ABSENT EST DIT, PAS DEVINE. Une mesure manquante ne produit pas
/// un critere neutre silencieux : le critere disparait et la fiche ANNONCE
/// qu'il manque ([DifficulteDuSentier.mesuresManquantes]). C'est la discipline
/// de `TrekConditions` : « aucun coefficient invente ; l'absence de source
/// produit un facteur NEUTRE qui est DIT, pas un facteur devine ».
class DifficulteDuSentier {
  /// Le resultat d'un calcul : on passe par [calculer], pas par ici, sauf
  /// pour fabriquer un cas de test.
  const DifficulteDuSentier({
    required this.joursChoisis,
    required this.journees,
    required this.mesuresManquantes,
  });

  /// Nombre de jours DEMANDE — l'allure que le randonneur a choisie.
  ///
  /// C'est un CONSEIL, pas une propriete du sentier (Christophe, 17/10 11:02 :
  /// « mais le nombre de jour, c'est du conseille, apres le client le fait dans
  /// le nombre de jours qu'il veut »). Le niveau se recalcule a chaque fois
  /// qu'il change d'avis : il voit la consequence de son choix AVANT de payer.
  final int joursChoisis;

  /// Les journees de MARCHE, dans l'ordre, chacune avec son effort et son
  /// niveau.
  ///
  /// Les jours de REPOS n'y figurent pas : une journee sans marche n'est pas
  /// une journee facile, c'est une journee absente. La compter facile ferait
  /// basculer la repartition vers le vert a chaque jour de repos ajoute.
  final List<JourneeClassee> journees;

  /// Les mesures qui MANQUENT, nommees, pour que la fiche le dise.
  final List<String> mesuresManquantes;

  /// Nombre de journees de MARCHE que le decoupage a reellement produites.
  ///
  /// IL DOIT ETRE EGAL A [joursChoisis], ET C'EST VERIFIE PLUTOT QUE SUPPOSE.
  /// Jusqu'a la tache 848 il ne l'etait pas : le repartiteur rendait six
  /// journees pour sept jours demandes, six pour neuf, sept pour dix, huit pour
  /// douze (mesure de la tache 846, #102125). Le defaut est repare
  /// ([RepartitionEquilibree]) et le champ reste : c'est lui qui le dira si
  /// quiconque le reintroduit.
  int get journeesDeMarche => journees.length;

  /// LE PLANCHER DU VERDICT : le niveau de la PIRE journee, jamais une moyenne.
  ///
  /// `null` quand aucune journee n'a pu etre classee — la fiche n'affiche alors
  /// aucune difficulte plutot qu'un mot sans mesure.
  NiveauDeDifficulte? get plancher => pireJournee?.niveau;

  /// LA JOURNEE QUI DECIDE DU PLANCHER : la plus forte en EFFORT.
  ///
  /// C'EST UN CHANGEMENT MESURE, PAS UN DETAIL DE VOCABULAIRE. Jusqu'au 17/10
  /// cette journee etait la plus forte en DENIVELE POSITIF. Sur les seize
  /// etapes du GR20, les deux ne designent pas la meme : par le seul D+ c'est
  /// Calenzana - l'Ortu di u Piobbu (1 453 m, 11,35 km) ; par l'effort complet
  /// c'est l'etape 6, Ciottulu di i Mori - Manganu, qui ne monte que 786 m mais
  /// fait 25,02 km et descend 1 191 m — 36,5 km-effort contre 26,5. Une journee
  /// de vingt-cinq kilometres n'est pas une journee facile parce qu'elle monte
  /// peu.
  ///
  /// A effort egal, la PREMIERE de l'itineraire : le marcheur rencontre
  /// celle-la d'abord, et nommer la seconde serait arbitraire.
  JourneeClassee? get pireJournee {
    JourneeClassee? pire;
    for (final journee in journees) {
      if (pire == null || journee.kmEffort > pire.kmEffort) pire = journee;
    }
    return pire;
  }

  /// LE VERDICT DU TRONCON : le plancher, monte d'un cran si l'accumulation le
  /// justifie.
  ///
  /// NI LA SOMME NI LA MOYENNE, ET VOICI POURQUOI AUCUNE DES DEUX NE MARCHE.
  /// La somme ferait d'un sentier long un sentier dur : marcher cent journees
  /// faciles n'a jamais demande de savoir faire ce qu'une journee tres
  /// difficile demande. La moyenne noie exactement ce qu'il faut voir : cinq
  /// journees faciles et une qui casse le marcheur donneraient « moyen », et
  /// c'est la sixieme qui decide s'il arrive.
  ///
  /// LE PLANCHER VIENT DE LA PIRE JOURNEE (Christophe, 17/10 11:07, verbatim :
  /// « un sentier qui a 5 etapes a moins de 1000 metre et une a plus de 1500
  /// est classe expert »). C'est aussi la regle du verdict de faisabilite, qui
  /// vaut la PIRE journee et elle seule (GO-61) : deux ecrans qui se
  /// contrediraient sur ce point n'auraient aucune chance d'etre crus tous les
  /// deux.
  ///
  /// L'ACCUMULATION PEUT LE MONTER D'UN CRAN, ET UN SEUL
  /// ([verdictMonteParLAccumulation]).
  NiveauDeDifficulte? get verdict {
    final plancherDuVerdict = plancher;
    if (plancherDuVerdict == null) return null;
    if (!verdictMonteParLAccumulation) return plancherDuVerdict;
    return NiveauDeDifficulte.values[plancherDuVerdict.rang + 1];
  }

  /// VRAI quand l'accumulation monte le verdict d'un cran au-dessus du
  /// plancher.
  ///
  /// LA CONDITION, EN UN SEUL NOMBRE : la plus longue SUITE de journees
  /// consecutives dans les deux bandes hautes atteint
  /// [SeuilsDeDifficulte.suiteQuiMonteLeVerdict]. Christophe, 17/10 17:25 :
  /// « combien d'etapes dans les deux bandes hautes et surtout combien se
  /// SUIVENT, parce qu'un troncon avec une journee dure n'est pas un troncon
  /// avec six journees dures d'affilee ».
  ///
  /// C'EST LA SUITE QUI COMPTE, PAS LE COMPTE — et le compte est quand meme
  /// affiche. [journeesEnBandesHautes] est deja LISIBLE sur la fiche : c'est la
  /// jauge de repartition. La SUITE ne l'est pas, et c'est elle que Christophe
  /// a soulignee : six journees dures etalees sur trois semaines se marchent,
  /// six journees dures d'affilee se subissent.
  ///
  /// SEUL « DIFFICILE » PEUT MONTER, ET C'EST UNE CONSEQUENCE ASSUMEE DE SES
  /// MOTS. La suite compte les journees des DEUX BANDES HAUTES : un troncon
  /// dont la pire journee est facile ou moyenne n'en a aucune, sa suite vaut
  /// zero, et son verdict ne bouge pas. Au-dessus, « tres difficile » est la
  /// bande du haut : il n'y a aucun cran ou monter. L'accumulation ne deplace
  /// donc qu'une seule frontiere — difficile vers tres difficile — et c'est
  /// exactement la frontiere ou elle se joue sur le GR20 : le chapitre SUD,
  /// dont la pire journee est difficile, est tres difficile marche en sept
  /// jours (sept journees hautes d'affilee) et reste difficile des huit (trois
  /// d'affilee).
  bool get verdictMonteParLAccumulation {
    final plancherDuVerdict = plancher;
    if (plancherDuVerdict == null) return false;
    if (plancherDuVerdict.rang >= NiveauDeDifficulte.values.length - 1) {
      return false;
    }
    return plusLongueSuiteEnBandesHautes >=
        SeuilsDeDifficulte.suiteQuiMonteLeVerdict;
  }

  /// Combien de journees tombent dans les DEUX BANDES HAUTES (difficile et
  /// tres difficile), ou qu'elles soient dans l'itineraire.
  int get journeesEnBandesHautes =>
      journees.where((journee) => journee.niveau.estUneBandeHaute).length;

  /// La plus longue SUITE de journees consecutives dans les deux bandes
  /// hautes.
  ///
  /// Zero quand aucune journee n'y tombe. C'est le nombre que
  /// [verdictMonteParLAccumulation] compare a son seuil, et celui que la fiche
  /// affiche a cote du verdict : « dont 6 d'affilee » est une information que
  /// la jauge de repartition ne sait pas donner.
  int get plusLongueSuiteEnBandesHautes {
    var plusLongue = 0;
    var courante = 0;
    for (final journee in journees) {
      courante = journee.niveau.estUneBandeHaute ? courante + 1 : 0;
      if (courante > plusLongue) plusLongue = courante;
    }
    return plusLongue;
  }

  /// LA REPARTITION : combien de journees par niveau, du plus facile au plus
  /// dur, TOUS les niveaux presents meme a zero.
  ///
  /// Les zeros sont gardes expres : une jauge dont les cases vides
  /// disparaissent change de forme d'un sentier a l'autre, et on ne peut plus
  /// comparer deux sentiers d'un coup d'oeil — ni voir que celui-ci n'a AUCUNE
  /// journee facile.
  Map<NiveauDeDifficulte, int> get repartition {
    final compte = <NiveauDeDifficulte, int>{
      for (final niveau in NiveauDeDifficulte.values) niveau: 0,
    };
    for (final journee in journees) {
      compte[journee.niveau] = (compte[journee.niveau] ?? 0) + 1;
    }
    return Map<NiveauDeDifficulte, int>.unmodifiable(compte);
  }

  /// Calcule la difficulte d'un sentier marche en [jours] journees.
  ///
  /// [journees] est la liste des journees de MARCHE dans l'ordre, chacune avec
  /// ses trois mesures. Elle vient du decoupage reel du sentier sur l'allure
  /// choisie — les trente et une nuits relevees quand le sentier en a (tache
  /// 838), ses etapes sinon —, jamais d'une division : regrouper six etapes sur
  /// trois jours ne fait pas trois journees egales.
  ///
  /// Retourne null quand [jours] est nul ou negatif : il n'y a pas de
  /// difficulte d'un sentier qu'on ne marche pas.
  static DifficulteDuSentier? calculer({
    required int jours,
    required List<JourneeMesuree> journees,
  }) {
    if (jours <= 0) return null;

    final classees = <JourneeClassee>[];
    var numero = 1;
    for (final mesure in journees) {
      if (!mesure.estMesurable) continue;
      classees.add(
        JourneeClassee(
          numero: numero,
          km: mesure.km,
          deniveleM: mesure.deniveleM,
          descenteM: mesure.descenteM,
        ),
      );
      numero++;
    }

    return DifficulteDuSentier(
      joursChoisis: jours,
      journees: List<JourneeClassee>.unmodifiable(classees),
      mesuresManquantes: List<String>.unmodifiable(
        classees.isEmpty
            ? const <String>['la distance et le denivele des journees']
            : const <String>[],
      ),
    );
  }
}

/// LES TROIS MESURES D'UNE JOURNEE DE MARCHE — ce qui ENTRE dans le calcul.
///
/// Les trois voyagent ensemble parce que les trois comptent. Avant le 17/10
/// seul le denivele positif entrait, et une journee de 25 km qui ne monte que
/// 786 m sortait « difficile » a cote d'une journee de 11 km qui monte 1 453 m
/// et sortait « tres difficile ». Christophe a tranche : « l'effort d'une
/// journee calcule sur distance, D+ et D- ».
class JourneeMesuree {
  /// Une journee de marche telle que le decoupage la produit.
  const JourneeMesuree({
    required this.km,
    required this.deniveleM,
    required this.descenteM,
  });

  /// Longueur de la journee, en kilometres.
  final double km;

  /// Denivele POSITIF de la journee, en metres.
  final int deniveleM;

  /// Denivele NEGATIF de la journee, en metres, compte POSITIVEMENT.
  final int descenteM;

  /// VRAI quand les trois mesures tiennent debout.
  ///
  /// Une mesure negative n'est pas une mesure : la laisser passer ferait
  /// mentir l'effort, et le silence serait pire que l'exclusion — la journee
  /// ecartee fait baisser [DifficulteDuSentier.journeesDeMarche], qui est
  /// COMPARE a l'allure demandee et le dira.
  bool get estMesurable => km >= 0 && deniveleM >= 0 && descenteM >= 0;
}

/// UNE JOURNEE DE MARCHE, SES TROIS MESURES, SON EFFORT ET SON NIVEAU.
///
/// Tout voyage ENSEMBLE, et c'est voulu : la fiche affiche la mesure a cote du
/// mot. « Tres difficile » tout seul est une affirmation ; « Tres difficile —
/// 11,3 km, 1 455 m de montee, 194 m de descente, soit 26,5 km-effort » est une
/// deduction que le randonneur peut refaire.
class JourneeClassee {
  /// Les mesures et leur numero ; l'effort et le niveau s'en deduisent.
  const JourneeClassee({
    required this.numero,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
  });

  /// Numero de la journee de marche (1-indexed, les repos non comptes).
  final int numero;

  /// Longueur de la journee, en kilometres.
  final double km;

  /// Denivele positif de la journee, en metres.
  final int deniveleM;

  /// Denivele negatif de la journee, en metres, compte positivement.
  final int descenteM;

  /// L'effort de la journee, en KILOMETRES-EFFORT.
  double get kmEffort => SeuilsDeDifficulte.effortDeLaJournee(
    km: km,
    deniveleM: deniveleM,
    descenteM: descenteM,
  );

  /// Le niveau que cet effort rend, par les seuils de [SeuilsDeDifficulte].
  NiveauDeDifficulte get niveau => SeuilsDeDifficulte.pourEffort(kmEffort);
}
