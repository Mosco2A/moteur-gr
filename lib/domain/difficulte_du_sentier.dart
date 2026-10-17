/// La difficulte d'un sentier : les seuils classent LA JOURNEE, le verdict est
/// celui de la PIRE — et la regle est dite avec le resultat.
library;

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
/// LA REGLE EST CELLE DE CHRISTOPHE, EN TROIS TEMPS (17/10 11:04 puis
/// 11:07-11:08, memoires #102127 et #102130).
///
///  1. LES SEUILS CLASSENT LA JOURNEE, PAS LE SENTIER. Verbatim : « ca c'st
///     pour classer les etapes ». Une journee de marche se voit attribuer un
///     niveau par son DENIVELE POSITIF, et rien d'autre.
///
///  2. LE VERDICT DU SENTIER EST CELUI DE SA PIRE JOURNEE, JAMAIS UNE MOYENNE.
///     Verbatim : « Mais un sentier qui a 5 etapes a moins de 1000 metre et une
///     a plus de 1500 est classe expert ». Une seule journee suffit a classer
///     tout le sentier, parce que c'est elle qui casse le marcheur. C'est aussi
///     la regle du verdict de faisabilite, qui vaut la PIRE journee et elle
///     seule (GO-61) : deux ecrans qui se contrediraient sur ce point
///     n'auraient aucune chance d'etre crus tous les deux.
///
///  3. L'AFFICHAGE EST UNE JAUGE DOUBLE, PAS UN MOT. Verbatim : « ou alors une
///     jauge avec le nombre d'etape facile a expert et une jauge moyenne (mais
///     qui se base aussi sur la plus difficile) ». La REPARTITION dit « dur une
///     fois ou dur tous les jours », le VERDICT dit « il faut savoir faire
///     ca ». Les deux ensemble : [repartition] et [verdict].
///
/// CE QUI EST SORTI DU CALCUL LE 17/10, ET IL FAUT LE DIRE. La version de la
/// tache 846 retenait TROIS mesures — le denivele moyen par journee, la
/// journee la plus dure, et l'altitude maximale de la trace — et prenait le
/// pire des trois. Christophe a tranche : « non la difficulte c'est surtout
/// base sur l'etape la plus compliquee et le denivele le plus fort ».
///   - LA MOYENNE PAR JOURNEE SORT : elle noie exactement ce qu'il faut voir.
///   - L'ALTITUDE MAXIMALE SORT : il ne la retient pas. Elle reste MESUREE et
///     la fiche la cite dans sa description (2 578 m sur le GR20), mais elle ne
///     produit plus de niveau. Consequence CHIFFREE, et c'est pour ca qu'on la
///     nomme : le GR20 en seize jours etait annonce EXPERT par la seule
///     altitude ; il est TRES DIFFICILE par sa pire journee (1 455 m). Le
///     verdict de la 846 etait donc trop dur d'un cran sur deux des quatre
///     allures mesurees.
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

  /// Les journees de MARCHE, dans l'ordre, chacune avec son niveau.
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
  /// douze (mesure de la tache 846, #102125). Ce champ existait pour ne pas
  /// recopier ce defaut dans une moyenne annoncee « sur sept jours » alors
  /// qu'elle portait sur six. Le defaut est repare ([RepartitionEquilibree]) et
  /// le champ reste : c'est lui qui le dira si quiconque le reintroduit.
  int get journeesDeMarche => journees.length;

  /// LE VERDICT : le niveau de la PIRE journee, jamais une moyenne.
  ///
  /// `null` quand aucune journee n'a pu etre classee — la fiche n'affiche alors
  /// aucune difficulte plutot qu'un mot sans mesure.
  NiveauDeDifficulte? get verdict => pireJournee?.niveau;

  /// LA JOURNEE QUI DECIDE DU VERDICT : la plus forte en denivele.
  ///
  /// A denivele egal, la PREMIERE de l'itineraire : le marcheur rencontre
  /// celle-la d'abord, et nommer la seconde serait arbitraire.
  JourneeClassee? get pireJournee {
    JourneeClassee? pire;
    for (final journee in journees) {
      if (pire == null || journee.deniveleM > pire.deniveleM) pire = journee;
    }
    return pire;
  }

  /// LA REPARTITION : combien de journees par niveau, du plus facile au plus
  /// dur, TOUS les niveaux presents meme a zero.
  ///
  /// Les zeros sont gardes exprés : une jauge dont les cases vides disparaissent
  /// change de forme d'un sentier a l'autre, et on ne peut plus comparer deux
  /// sentiers d'un coup d'oeil — ni voir que celui-ci n'a AUCUNE journee facile.
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
  /// [denivelesParJournee] est le denivele POSITIF de chaque journee de MARCHE,
  /// en metres. Il vient du decoupage reel du sentier sur l'allure choisie —
  /// les trente et une nuits relevees quand le sentier en a (tache 838), ses
  /// etapes sinon —, jamais d'une division : regrouper six etapes sur trois
  /// jours ne fait pas trois journees egales.
  ///
  /// Retourne null quand [jours] est nul ou negatif : il n'y a pas de
  /// difficulte d'un sentier qu'on ne marche pas.
  static DifficulteDuSentier? calculer({
    required int jours,
    required List<int> denivelesParJournee,
  }) {
    if (jours <= 0) return null;

    final journees = <JourneeClassee>[];
    var numero = 1;
    for (final denivele in denivelesParJournee) {
      if (denivele < 0) continue;
      journees.add(
        JourneeClassee(
          numero: numero,
          deniveleM: denivele,
          niveau: SeuilsDeDifficulte.pourDenivele(denivele),
        ),
      );
      numero++;
    }

    return DifficulteDuSentier(
      joursChoisis: jours,
      journees: List<JourneeClassee>.unmodifiable(journees),
      mesuresManquantes: List<String>.unmodifiable(
        journees.isEmpty
            ? const <String>['le denivele des journees']
            : const <String>[],
      ),
    );
  }
}

/// UNE JOURNEE DE MARCHE, SON DENIVELE, ET LE NIVEAU QUE CE DENIVELE REND.
///
/// Les trois voyagent ENSEMBLE, et c'est voulu : la fiche affiche la mesure a
/// cote du mot. « Tres difficile » tout seul est une affirmation ; « Tres
/// difficile — 1 455 m de montee dans la journee » est une deduction que le
/// randonneur peut refaire.
class JourneeClassee {
  /// Les trois ne se separent pas : un niveau sans sa mesure redevient une
  /// affirmation.
  const JourneeClassee({
    required this.numero,
    required this.deniveleM,
    required this.niveau,
  });

  /// Numero de la journee de marche (1-indexed, les repos non comptes).
  final int numero;

  /// Denivele positif de la journee, en metres.
  final int deniveleM;

  /// Le niveau que ce denivele rend, par les seuils de [SeuilsDeDifficulte].
  final NiveauDeDifficulte niveau;
}

/// LES CINQ NIVEAUX, ET LEUR ORDRE. [rang] sert a prendre le PIRE.
///
/// ILS SONT CINQ ET NON QUATRE DEPUIS LE 17/10. Les deux seuils du haut sont de
/// Christophe (1 000 m et 1 500 m), les trois bandes du bas ont ete proposees
/// par Skynet et validees dans le meme echange (#102130). Le niveau du milieu
/// s'appelle « Moyen » ici, quand la pastille d'etape du socle dit « Modere »
/// pour sa cle `moderate` : ce sont deux vocabulaires et ils ne se recouvrent
/// pas — voir [cleDuSocleApprochante].
enum NiveauDeDifficulte {
  /// Moins de 400 m de montee dans la journee.
  facile(0, 'Facile'),

  /// De 400 a 700 m.
  moyen(1, 'Moyen'),

  /// De 700 a 1 000 m.
  difficile(2, 'Difficile'),

  /// De 1 000 a 1 500 m — premier seuil de Christophe.
  tresDifficile(3, 'Tres difficile'),

  /// Au-dela de 1 500 m — second seuil de Christophe.
  expert(4, 'Expert');

  const NiveauDeDifficulte(this.rang, this.libelle);

  /// Rang de severite, du plus facile au plus dur.
  final int rang;

  /// Le mot affiche, tel quel.
  final String libelle;

  /// LA CLE DU SOCLE LA PLUS PROCHE (`easy`, `moderate`, `hard`, `expert`),
  /// POUR LES ECRANS QUI NE SAVENT PARLER QUE CE VOCABULAIRE-LA.
  ///
  /// C'EST UNE APPROXIMATION, ET ELLE EST NOMMEE COMME TELLE. Le socle n'a que
  /// QUATRE valeurs, heritees de seuils plus anciens (400 / 1 000 / 1 500 m,
  /// cf. `tool/gr20_dans_stepways.py`), et cette echelle en a cinq : « Tres
  /// difficile » n'a pas de cle. Elle tombe donc sur `hard`, qui est le cran du
  /// dessous — jamais sur `expert`, qui serait un cran de trop et ferait passer
  /// pour expert un sentier qui ne l'est pas.
  ///
  /// A N'EMPLOYER QUE POUR UNE COULEUR DE SECOURS. Ce qui s'affiche sur la
  /// fiche, c'est [libelle] et la couleur de la jauge, pas cette cle : le jour
  /// ou le socle passera a cinq valeurs, cette approximation disparaitra.
  String get cleDuSocleApprochante => switch (this) {
    NiveauDeDifficulte.facile => 'easy',
    NiveauDeDifficulte.moyen => 'moderate',
    NiveauDeDifficulte.difficile => 'hard',
    NiveauDeDifficulte.tresDifficile => 'hard',
    NiveauDeDifficulte.expert => 'expert',
  };
}

/// LES SEUILS, ET D'OU ILS VIENNENT — AUCUN N'EST INVENTE ICI.
abstract final class SeuilsDeDifficulte {
  SeuilsDeDifficulte._();

  /// A PARTIR DE 400 M, LA JOURNEE EST MOYENNE — en dessous elle est FACILE.
  ///
  /// UN SEUL NOM POUR UN SEUL NOMBRE : la borne haute du facile et la borne
  /// basse du moyen sont le MEME seuil, et lui donner deux noms serait le
  /// premier pas vers deux valeurs.
  ///
  /// 400 m est aussi le seuil que le depot employait DEJA pour qualifier une
  /// journee facile (`tool/gr20_dans_stepways.py`) : le reprendre evite qu'une
  /// journee de 350 m soit dite facile par la fiche de l'etape et autrement par
  /// celle du sentier.
  static const int deniveleMoyenM = 400;

  /// A partir de 700 m, la journee est DIFFICILE.
  static const int deniveleDifficileM = 700;

  /// A PARTIR DE 1 000 M, LA JOURNEE EST TRES DIFFICILE. Seuil de Christophe,
  /// 17/10 11:04, verbatim : « 0 partir de 1000 metres de denivele par jour on
  /// passe a tres difficile ».
  static const int deniveleTresDifficileM = 1000;

  /// AU-DELA DE 1 500 M, LA JOURNEE EST D'EXPERT. Seuil de Christophe, meme
  /// phrase : « au dessus de 1500 a expert ».
  static const int deniveleExpertM = 1500;

  /// LA REGLE, EN UNE PHRASE, TELLE QU'ELLE S'AFFICHE SOUS LE RESULTAT.
  ///
  /// Elle est ICI et pas dans l'ecran : la regle affichee et la regle appliquee
  /// doivent etre le meme texte, sinon l'une derive. Un test le verifie, et il
  /// verifie aussi que les nombres cites sont les constantes ci-dessus.
  static String get regleAffichee =>
      'Le niveau se lit sur le DENIVELE de chaque journee : facile en dessous '
      'de $deniveleMoyenM m de montee, moyen de $deniveleMoyenM a '
      '$deniveleDifficileM m, difficile de $deniveleDifficileM a '
      '$deniveleTresDifficileM m, tres difficile de $deniveleTresDifficileM a '
      '$deniveleExpertM m, expert au-dela de $deniveleExpertM m. Le niveau du '
      'sentier est celui de sa journee la PLUS DURE, jamais une moyenne : une '
      'seule journee au-dessus du seuil suffit a le classer, parce que c\'est '
      'celle-la qui decide si on arrive.';

  /// Le niveau rendu par le denivele d'une journee, en metres.
  ///
  /// Les bornes sont INCLUSIVES EN BAS : 1 000 m est tres difficile, 1 500 m
  /// est expert. C'est la lettre de la phrase de Christophe (« a partir de
  /// 1000 »), et un seuil « strictement au-dessus » aurait classe la journee de
  /// 1 000 m pile un cran plus bas que celle de 1 001 m.
  static NiveauDeDifficulte pourDenivele(int deniveleM) {
    if (deniveleM >= deniveleExpertM) return NiveauDeDifficulte.expert;
    if (deniveleM >= deniveleTresDifficileM) {
      return NiveauDeDifficulte.tresDifficile;
    }
    if (deniveleM >= deniveleDifficileM) return NiveauDeDifficulte.difficile;
    if (deniveleM >= deniveleMoyenM) return NiveauDeDifficulte.moyen;
    return NiveauDeDifficulte.facile;
  }
}
