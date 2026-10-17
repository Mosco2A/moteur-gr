/// L'echelle de difficulte : les QUATRE bandes, l'effort d'une journee, et les
/// seuils qui les separent.
library;

/// LES QUATRE NIVEAUX, ET LEUR ORDRE. [rang] sert a prendre le PIRE.
///
/// ILS SONT QUATRE DEPUIS LE 17/10 17:25, verbatim de Christophe :
/// « facile/moyen/Difficile/tres difficile ». La bande « expert » qui existait
/// depuis le matin du meme jour est SUPPRIMEE et ce qu'elle portait retombe
/// dans [tresDifficile], qui est desormais la bande du HAUT, OUVERTE.
///
/// CE SONT LES CINQ BANDES DE LA FEDERATION, LES DEUX DU HAUT REPLIEES EN UNE.
/// L'axe EFFORT de la FFRandonnee porte cinq mots — facile, assez facile, peu
/// difficile, assez difficile, difficile — et le repli est rang pour rang :
///
///   | FFRandonnee (effort) | ici              |
///   | -------------------- | ---------------- |
///   | facile               | [facile]         |
///   | assez facile         | [moyen]          |
///   | peu difficile        | [difficile]      |
///   | assez difficile      | [tresDifficile]  |
///   | difficile            | [tresDifficile]  |
///
/// LE REPLI SE FAIT EN HAUT, ET LE CHOIX DU COTE N'EST PAS NEUTRE. Replier en
/// bas aurait elargi « facile » : deux bandes federales dans un seul mot
/// rassurant, donc une journee annoncee plus facile qu'elle n'est. Replier en
/// haut elargit la bande du haut : l'erreur restante annonce plus dur, pas plus
/// facile. On replie du cote ou se tromper PROTEGE le marcheur.
///
/// CE QUE NOUS NE PRETENDONS PAS. L'axe effort de la federation est l'indice
/// IBP, dont le bareme exact n'est PAS public — le depot l'ecrit deja
/// (`features/feasibility/domain/ibp_calculator.dart` : « le bareme IBP n'etant
/// pas public, c'est une approximation assumee »). Nous reprenons donc ses
/// INGREDIENTS et ses MOTS, pas ses nombres : aucun km-effort d'ici ne vaut un
/// point d'IBP de la-bas, et personne ici ne l'ecrira.
///
/// LE NIVEAU DU MILIEU S'APPELLE « MOYEN », quand la pastille d'etape du socle
/// dit « Modere » pour sa cle `moderate` : ce sont deux vocabulaires et ils ne
/// se recouvrent pas — voir [cleDuSocleApprochante].
enum NiveauDeDifficulte {
  /// Moins de [SeuilsDeDifficulte.effortMoyenKm] km-effort dans la journee.
  facile(0, 'Facile'),

  /// De [SeuilsDeDifficulte.effortMoyenKm] a
  /// [SeuilsDeDifficulte.effortDifficileKm] km-effort.
  moyen(1, 'Moyen'),

  /// De [SeuilsDeDifficulte.effortDifficileKm] a
  /// [SeuilsDeDifficulte.effortTresDifficileKm] km-effort.
  difficile(2, 'Difficile'),

  /// Au-dela de [SeuilsDeDifficulte.effortTresDifficileKm] km-effort. Bande du
  /// HAUT, OUVERTE : il n'y a plus rien au-dessus.
  tresDifficile(3, 'Tres difficile');

  const NiveauDeDifficulte(this.rang, this.libelle);

  /// Rang de severite, du plus facile au plus dur.
  final int rang;

  /// Le mot affiche, tel quel.
  final String libelle;

  /// VRAI pour les DEUX BANDES HAUTES — [difficile] et [tresDifficile].
  ///
  /// C'est le vocabulaire de Christophe (« combien d'etapes dans les deux
  /// bandes hautes »), et c'est l'ensemble que compte l'accumulation du
  /// verdict de troncon.
  bool get estUneBandeHaute => rang >= NiveauDeDifficulte.difficile.rang;

  /// LA CLE DU SOCLE LA PLUS PROCHE (`easy`, `moderate`, `hard`), POUR LES
  /// ECRANS QUI NE SAVENT PARLER QUE CE VOCABULAIRE-LA.
  ///
  /// C'EST UNE APPROXIMATION, ET ELLE EST NOMMEE COMME TELLE. Le socle porte
  /// des etiquettes calculees sur des seuils plus anciens
  /// (`tool/gr20_dans_stepways.py`) ; « Tres difficile » n'y a pas de cle et
  /// tombe donc sur `hard`, le cran du dessous.
  ///
  /// CETTE ECHELLE NE DEMANDE PLUS JAMAIS `expert` NI `extreme` AU SOCLE, et
  /// c'est la fin d'un defaut visible : jusqu'a la tache 848 une etape classee
  /// au-dela de 1 500 m s'affichait en GRIS avec le mot « extreme » brut a
  /// l'ecran, parce que la table des couleurs ignorait cette cle. La bande qui
  /// menait la n'existe plus ; les deux mots du socle au-dessus de `hard` sont
  /// desormais inatteignables depuis ici, par construction et non par chance.
  ///
  /// A N'EMPLOYER QUE POUR UNE COULEUR DE SECOURS. Ce qui s'affiche sur la
  /// fiche, c'est [libelle] et la couleur de la jauge, pas cette cle.
  String get cleDuSocleApprochante => switch (this) {
    NiveauDeDifficulte.facile => 'easy',
    NiveauDeDifficulte.moyen => 'moderate',
    NiveauDeDifficulte.difficile => 'hard',
    NiveauDeDifficulte.tresDifficile => 'hard',
  };
}

/// L'EFFORT D'UNE JOURNEE, LES SEUILS, ET D'OU CHAQUE NOMBRE VIENT — AUCUN
/// N'EST INVENTE ICI.
abstract final class SeuilsDeDifficulte {
  SeuilsDeDifficulte._();

  /// 100 M DE MONTEE VALENT 1 KM DE PLAT.
  ///
  /// C'est l'equivalence d'effort que le depot emploie DEJA, et elle n'est pas
  /// nouvelle ici : le moteur de faisabilite la porte depuis le lot 3
  /// (`km-effort = distance_km + D+_m/100`, decision du 17/09, memoire #100068,
  /// adossee a `data/apport_stepways/BP_faisabilite_entrainement.md` §A) et le
  /// calculateur d'effort la reprend (`IbpCalculator` et son equivalence de
  /// reference). La reprendre ici est la seule facon que deux ecrans du meme
  /// produit ne chiffrent pas la meme journee differemment.
  static const int metresDeMonteeParKmDePlat = 100;

  /// LA DESCENTE PESE 0,30 DE LA MONTEE, PAS ZERO ET PAS AUTANT.
  ///
  /// Zero serait faux : une journee qui descend 1 200 m fatigue, et c'est une
  /// sollicitation EXCENTRIQUE que le quadriceps paie (BP §B). Autant que la
  /// montee serait faux aussi : personne ne met une heure a descendre ce qu'il
  /// met une heure a monter. Le coefficient n'est pas choisi ici : c'est le
  /// poids de descente d'`IbpCalculator`, deja en production dans le moteur de
  /// faisabilite et deja adosse a la meme bonne pratique.
  static const double poidsDeLaDescente = 0.30;

  /// L'EFFORT D'UNE JOURNEE, EN KILOMETRES-EFFORT.
  ///
  /// Un kilometre-effort est un kilometre de PLAT. La formule dit donc une
  /// chose simple et verifiable a la main : la journee vaut sa distance, plus
  /// un kilometre par [metresDeMonteeParKmDePlat] metres de montee, plus
  /// [poidsDeLaDescente] de la meme chose pour la descente.
  ///
  ///   effort = km + D+ / 100 + 0,30 x D- / 100
  ///
  /// EXEMPLE MESURE, celui de la fiche du GR20 : la premiere journee fait
  /// 11,349 km, monte 1 455 m et descend 194 m, soit
  /// 11,349 + 14,55 + 0,582 = 26,5 km-effort.
  static double effortDeLaJournee({
    required double km,
    required int deniveleM,
    required int descenteM,
  }) {
    final distance = km < 0 ? 0.0 : km;
    final montee = deniveleM < 0 ? 0 : deniveleM;
    final descente = descenteM < 0 ? 0 : descenteM;
    return distance +
        montee / metresDeMonteeParKmDePlat +
        poidsDeLaDescente * descente / metresDeMonteeParKmDePlat;
  }

  /// LE FACTEUR QUI TRANSPOSE LES TROIS SEUILS DE CHRISTOPHE EN KILOMETRES-
  /// EFFORT : 40 METRES DE MONTEE PAR KILOMETRE-EFFORT.
  ///
  /// POURQUOI UN FACTEUR ET PAS TROIS SEUILS NEUFS. Christophe a donne ses
  /// seuils sur le seul denivele — 400, 700 et 1 000 m dans la journee (17/10
  /// 11:04 et 11:07, memoires #102127 et #102130) — et il les a valides sur les
  /// seize etapes du GR20. Les reecrire a la main aurait deplace ses verdicts
  /// sans le dire. Un facteur UNIQUE les transpose tous les trois et ne laisse
  /// qu'un nombre a justifier.
  ///
  /// COMMENT CE NOMBRE EST ENCADRE, PAR DEUX JOURNEES QU'IL A CLASSEES LUI-MEME
  /// ET NON PAR UNE INTUITION. Le seul seuil qu'il a prononce est 1 000 m =
  /// tres difficile. Deux etapes reelles l'encadrent, et il a tranche sur les
  /// deux le 17/10 11:04 :
  ///
  ///  - Calenzana - l'Ortu di u Piobbu, 11,35 km / D+ 1 453 / D- 194, qu'il
  ///    classe TRES DIFFICILE : 26,46 km-effort. Le seuil doit etre DESSOUS.
  ///  - Vizzavona - E Capanelle, 13,95 km / D+ 967 / D- 294, dont il dit qu'elle
  ///    est SOUS le seuil : 24,50 km-effort. Le seuil doit etre DESSUS.
  ///
  /// Le seuil vit donc dans l'intervalle ouvert (24,50 ; 26,46]. 25,0 tombe
  /// dedans et c'est un nombre rond, donc 1 000 / 25,0 = 40 metres de montee
  /// par kilometre-effort. Les deux autres seuils suivent sans aucun choix
  /// supplementaire : 700 / 40 = 17,5 et 400 / 40 = 10,0.
  static const int metresDeMonteeParKmEffort = 40;

  /// A PARTIR DE 10,0 KM-EFFORT, LA JOURNEE EST MOYENNE — en dessous elle est
  /// FACILE. (= 400 m de montee / [metresDeMonteeParKmEffort])
  ///
  /// UN SEUL NOM POUR UN SEUL NOMBRE : la borne haute du facile et la borne
  /// basse du moyen sont le MEME seuil, et lui donner deux noms serait le
  /// premier pas vers deux valeurs.
  static const double effortMoyenKm = 10;

  /// A partir de 17,5 km-effort, la journee est DIFFICILE.
  /// (= 700 m de montee / [metresDeMonteeParKmEffort])
  static const double effortDifficileKm = 17.5;

  /// A PARTIR DE 25,0 KM-EFFORT, LA JOURNEE EST TRES DIFFICILE, et il n'y a
  /// rien au-dessus. (= 1 000 m de montee / [metresDeMonteeParKmEffort], le
  /// seul seuil que Christophe ait prononce)
  static const double effortTresDifficileKm = 25;

  /// LA FENETRE SUR LAQUELLE CE PRODUIT JUGE DEJA UNE ACCUMULATION : SEPT
  /// JOURS.
  ///
  /// Elle n'est pas choisie ici. Le moteur de faisabilite mesure la monotonie
  /// de Foster (1998) sur une fenetre glissante de sept jours
  /// (`FeasibilityFormula.monotonyWindowDays`), et c'est deja ce qui declenche
  /// le conseil d'un jour de repos. Un test verifie que les deux nombres ne
  /// divergent pas.
  static const int fenetreDAccumulationJours = 7;

  /// LA SUITE QUI MONTE LE VERDICT D'UN CRAN : QUATRE JOURNEES CONSECUTIVES
  /// DANS LES DEUX BANDES HAUTES.
  ///
  /// C'EST LA PLUS PETITE MAJORITE DE LA FENETRE DE SEPT JOURS. Quatre sur
  /// sept : la moitie de la fenetre que ce produit emploie DEJA pour juger une
  /// accumulation, plus un. Aucun autre nombre n'est introduit.
  ///
  /// ET LA MESURE DIT QUE LE CHOIX EXACT NE CHANGE RIEN ICI, CE QUI EST LA
  /// SEULE FACON HONNETE DE LE JUSTIFIER. Sur les quatre-vingt-dix-neuf
  /// troncons mesures le 17/10 — le sentier entier de 7 a 31 jours DANS LES
  /// DEUX SENS, les deux chapitres a toutes leurs allures, et le sentier par la
  /// variante Bonifatu de 7 a 32 jours —, vingt-six seulement ont un plancher
  /// sous « tres difficile » : eux seuls peuvent monter. Leurs plus longues
  /// suites valent 1, 2, 3, 7 ou 8, et AUCUNE ne vaut 4, 5 ni 6. TOUT seuil de
  /// 4 a 7 rend donc EXACTEMENT les memes verdicts ; 3 ferait monter le
  /// chapitre sud a huit jours, 8 ne le ferait plus monter a sept. Le seuil est
  /// donc encadre par la mesure dans [4 ; 7], et par l'exemple de Christophe
  /// lui-meme (« six journees dures d'affilee », qui doivent monter le verdict)
  /// dans [4 ; 6]. On prend le bas de l'intervalle, qui est aussi la majorite
  /// de la fenetre : 4. Le calcul est refait a chaque passage de
  /// `test/assets/effort_et_troncon_852_test.dart`.
  static const int suiteQuiMonteLeVerdict = 4;

  /// LA REGLE DE LA JOURNEE, EN UNE PHRASE, TELLE QU'ELLE S'AFFICHE SOUS LE
  /// RESULTAT.
  ///
  /// Elle est ICI et pas dans l'ecran : la regle affichee et la regle appliquee
  /// doivent etre le meme texte, sinon l'une derive. Un test le verifie, et il
  /// verifie aussi que les nombres cites sont les constantes ci-dessus.
  static String get regleAffichee =>
      'L\'effort d\'une journee vaut sa distance, plus 1 km par '
      '$metresDeMonteeParKmDePlat m de montee, plus '
      '${_nombre(poidsDeLaDescente, decimales: 2)} fois autant pour la '
      'descente : 11,3 km, '
      '1 455 m de montee et 194 m de descente font 26,5 km-effort. La journee '
      'est facile en dessous de ${_nombre(effortMoyenKm)} km-effort, moyenne '
      'de ${_nombre(effortMoyenKm)} a ${_nombre(effortDifficileKm)}, difficile '
      'de ${_nombre(effortDifficileKm)} a ${_nombre(effortTresDifficileKm)}, '
      'tres difficile au-dela de ${_nombre(effortTresDifficileKm)} — et '
      'plus rien au-dessus.';

  /// LA REGLE DU TRONCON, EN UNE PHRASE, AFFICHEE A COTE DU VERDICT.
  static String get regleDuTronconAffichee =>
      'Le niveau d\'un sentier n\'est ni la somme ni la moyenne de ses '
      'journees : il part de sa journee la PLUS DURE, parce que c\'est '
      'celle-la qui decide si on arrive. Il monte d\'un cran, et d\'un seul, '
      'quand $suiteQuiMonteLeVerdict journees difficiles ou tres difficiles se '
      'SUIVENT : un sentier avec une journee dure ne se marche pas comme un '
      'sentier qui en aligne six.';

  /// Le niveau rendu par l'effort d'une journee, en kilometres-effort.
  ///
  /// Les bornes sont INCLUSIVES EN BAS : 25,0 km-effort est tres difficile.
  /// C'est la lettre de la phrase de Christophe (« a partir de 1000 »), et un
  /// seuil « strictement au-dessus » aurait classe la journee de 25,0 pile un
  /// cran plus bas que celle de 25,1.
  static NiveauDeDifficulte pourEffort(double kmEffort) {
    if (kmEffort >= effortTresDifficileKm) {
      return NiveauDeDifficulte.tresDifficile;
    }
    if (kmEffort >= effortDifficileKm) return NiveauDeDifficulte.difficile;
    if (kmEffort >= effortMoyenKm) return NiveauDeDifficulte.moyen;
    return NiveauDeDifficulte.facile;
  }

  /// Le niveau d'une journee depuis ses trois mesures — le chemin court.
  static NiveauDeDifficulte pourUneJournee({
    required double km,
    required int deniveleM,
    required int descenteM,
  }) => pourEffort(
    effortDeLaJournee(km: km, deniveleM: deniveleM, descenteM: descenteM),
  );

  /// Un nombre ecrit comme on l'ecrit en francais : virgule, et pas de zero
  /// decimal inutile. La regle affichee doit se lire, pas se decoder.
  ///
  /// [decimales] est DEMANDE par l'appelant et non devine depuis la valeur. Le
  /// deviner demandait de comparer la valeur a 1 avec un `.abs()`, et cette
  /// forme-la est exactement celle que `un_seul_moteur_de_denivele_671_test`
  /// surveille : un cumul de denivele compare a un seuil de bruit. Une mise en
  /// forme de texte n'a rien a voir avec un moteur de denivele, mais une garde
  /// qui lit des formes ne peut pas faire la difference — et c'est la garde qui
  /// a raison de ne pas essayer.
  static String _nombre(double valeur, {int decimales = 1}) {
    final rond = valeur == valeur.roundToDouble();
    final texte = rond && decimales == 1
        ? valeur.toStringAsFixed(0)
        : valeur.toStringAsFixed(decimales);
    return texte.replaceAll('.', ',');
  }
}
