/// La difficulte d'un sentier, DEDUITE de trois mesures et de l'allure choisie
/// — et la regle est dite avec le resultat.
library;

import 'dart:math' as math;

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
/// TROIS MESURES ENTRENT, UN MOT SORT, ET LES TROIS SONT AFFICHEES :
///   1. LE DENIVELE PAR JOURNEE A L'ALLURE CHOISIE. C'est la seule des trois
///      qui depend du randonneur : les memes 11 644 m de montee font 728 m par
///      jour en seize jours et 1 663 m par jour en sept. La difficulte d'un
///      sentier n'existe pas sans une allure.
///   2. LA JOURNEE LA PLUS DURE. Une moyenne confortable peut cacher une
///      journee de 1 453 m de montee, et c'est celle-la qui decide si le
///      randonneur arrive. C'est la meme regle que le verdict de faisabilite,
///      qui vaut la PIRE journee et elle seule (GO-61).
///   3. L'ALTITUDE MAXIMALE. Elle ne se deduit ni de la distance ni du
///      denivele : 2 578 m sur le GR20 contre 1 512 m sur le Mare a Mare
///      Centre, pour des chemins de meme famille.
///
/// LE NIVEAU RETENU EST LE PIRE DES TROIS, jamais une moyenne. Moyenner
/// reviendrait a dire qu'une altitude basse rachete une journee de 1 500 m de
/// montee : sur le terrain, elle ne rachete rien.
///
/// CE QUI EST ABSENT EST DIT, PAS DEVINE. Une mesure manquante — un sentier
/// dont la trace ne porte pas d'altitude, par exemple — ne produit pas un
/// critere neutre silencieux : le critere disparait et la fiche ANNONCE qu'il
/// manque ([DifficulteDuSentier.mesuresManquantes]). C'est la discipline de
/// `TrekConditions` : « aucun coefficient invente ; l'absence de source produit
/// un facteur NEUTRE qui est DIT, pas un facteur devine ».
class DifficulteDuSentier {
  /// Le resultat d'un calcul : on passe par [calculer], pas par ici, sauf
  /// pour fabriquer un cas de test.
  const DifficulteDuSentier({
    required this.joursChoisis,
    required this.journeesDeMarche,
    required this.criteres,
    required this.mesuresManquantes,
  });

  /// Nombre de jours DEMANDE — l'allure que le randonneur a choisie.
  final int joursChoisis;

  /// Nombre de journees de MARCHE que le decoupage a reellement produites.
  ///
  /// IL N'EST PAS TOUJOURS EGAL A [joursChoisis], ET C'EST MESURE PLUTOT QUE
  /// SUPPOSE. `PlanningCalculator._distributeGreedy` ne coupe que lorsque le
  /// score accumule franchit sa cible : sur le GR20, demander SEPT jours rend
  /// SIX journees de marche, dix en rendent sept, douze en rendent huit. Le
  /// defaut est dans le decoupage, pas ici — et c'est precisement pour ne pas
  /// le recopier que ce champ existe. Une moyenne annoncee « sur sept jours »
  /// alors qu'elle porte sur six serait une affirmation fausse d'un metre, et
  /// cette classe existe pour ne plus en produire.
  final int journeesDeMarche;

  /// Les criteres RETENUS, dans l'ordre d'affichage. Un critere dont la mesure
  /// manque n'y figure pas — il figure dans [mesuresManquantes].
  final List<CritereDeDifficulte> criteres;

  /// Les mesures qui MANQUENT, nommees, pour que la fiche le dise.
  final List<String> mesuresManquantes;

  /// Le niveau retenu : LE PIRE des criteres. `null` quand aucun critere n'a pu
  /// etre calcule — la fiche n'affiche alors aucune difficulte.
  NiveauDeDifficulte? get niveau {
    NiveauDeDifficulte? pire;
    for (final critere in criteres) {
      if (pire == null || critere.niveau.rang > pire.rang) {
        pire = critere.niveau;
      }
    }
    return pire;
  }

  /// La cle de difficulte du socle (`easy`, `moderate`, `hard`, `expert`) —
  /// celle que `DifficultyBadge` sait colorer. `null` sans critere.
  ///
  /// On ne redefinit NI les couleurs NI les libelles ici : la table unique vit
  /// dans la pastille, et un second choix de couleur finirait par dire autre
  /// chose qu'elle.
  String? get cleDuSocle => niveau?.cle;

  /// Calcule la difficulte d'un sentier marche en [jours] journees.
  ///
  /// [denivelesParJournee] est le denivele POSITIF de chaque journee de MARCHE,
  /// en metres — les jours de repos n'y figurent pas, une journee sans marche
  /// n'etant pas une journee facile mais une journee absente. Il vient du
  /// decoupage reel des etapes sur l'allure choisie (`PlanningCalculator`), pas
  /// d'une division : regrouper six etapes sur trois jours ne fait pas trois
  /// journees egales.
  ///
  /// [altitudeMaxM] est l'altitude maximale MESUREE de la trace, ou null quand
  /// le sentier ne la fournit pas.
  ///
  /// Retourne null quand [jours] est nul ou negatif : il n'y a pas de
  /// difficulte d'un sentier qu'on ne marche pas.
  static DifficulteDuSentier? calculer({
    required int jours,
    required List<int> denivelesParJournee,
    int? altitudeMaxM,
  }) {
    if (jours <= 0) return null;

    final criteres = <CritereDeDifficulte>[];
    final manquantes = <String>[];

    final journees = denivelesParJournee
        .where((d) => d >= 0)
        .toList(growable: false);
    if (journees.isEmpty) {
      manquantes.add('le denivele des journees');
    } else {
      final total = journees.fold<int>(0, (s, d) => s + d);
      final moyenne = (total / journees.length).round();
      final pire = journees.reduce(math.max);
      criteres.add(
        CritereDeDifficulte(
          nom: 'Denivele par journee',
          mesure:
              '$moyenne m de montee par jour, '
              'sur ${journees.length} journees de marche',
          niveau: SeuilsDeDifficulte.pourDenivele(moyenne),
        ),
      );
      criteres.add(
        CritereDeDifficulte(
          nom: 'Journee la plus dure',
          mesure: '$pire m de montee en une seule journee',
          niveau: SeuilsDeDifficulte.pourDenivele(pire),
        ),
      );
    }

    if (altitudeMaxM == null) {
      manquantes.add("l'altitude maximale de la trace");
    } else {
      criteres.add(
        CritereDeDifficulte(
          nom: 'Altitude maximale',
          mesure: '$altitudeMaxM m au point le plus haut',
          niveau: SeuilsDeDifficulte.pourAltitude(altitudeMaxM),
        ),
      );
    }

    return DifficulteDuSentier(
      joursChoisis: jours,
      journeesDeMarche: journees.length,
      criteres: List<CritereDeDifficulte>.unmodifiable(criteres),
      mesuresManquantes: List<String>.unmodifiable(manquantes),
    );
  }
}

/// UN CRITERE : son nom, la mesure qui l'etablit, et le niveau qu'elle rend.
///
/// Les trois voyagent ENSEMBLE, et c'est voulu : la fiche affiche la mesure a
/// cote du mot. « Difficile » tout seul est une affirmation ; « Difficile —
/// 1 453 m de montee en une seule journee » est une deduction que le randonneur
/// peut refaire.
class CritereDeDifficulte {
  /// Les trois ne se separent pas : un niveau sans sa mesure redevient une
  /// affirmation.
  const CritereDeDifficulte({
    required this.nom,
    required this.mesure,
    required this.niveau,
  });

  /// Nom du critere, tel qu'il s'affiche.
  final String nom;

  /// La mesure, en clair et avec son unite.
  final String mesure;

  /// Le niveau que cette mesure rend, par les seuils du socle.
  final NiveauDeDifficulte niveau;
}

/// LES QUATRE NIVEAUX, ET LEUR ORDRE. [rang] sert a prendre le PIRE.
enum NiveauDeDifficulte {
  /// Facile.
  facile('easy', 0),

  /// Modere.
  modere('moderate', 1),

  /// Difficile.
  difficile('hard', 2),

  /// Expert.
  expert('expert', 3);

  const NiveauDeDifficulte(this.cle, this.rang);

  /// La cle du socle (`easy`, `moderate`, `hard`, `expert`), celle que la
  /// pastille de difficulte sait colorer et traduire.
  final String cle;

  /// Rang de severite, du plus facile au plus dur.
  final int rang;
}

/// LES SEUILS, ET D'OU ILS VIENNENT — AUCUN N'EST INVENTE ICI.
abstract final class SeuilsDeDifficulte {
  SeuilsDeDifficulte._();

  /// Denivele d'une journee : 400 m, 1 000 m, 1 500 m.
  ///
  /// CE SONT LES SEUILS DEJA EMPLOYES PAR LE DEPOT POUR QUALIFIER UNE JOURNEE
  /// DE MARCHE, et c'est tout l'interet de les reprendre : la fonction qui
  /// etiquette les seize etapes du GR20 dans `tool/gr20_dans_stepways.py`
  /// declare une journee `extreme` au-dela de 1 500 m de montee, `hard` au-dela
  /// de 1 000 m, et `easy` en dessous de 400 m. Une journee de 1 200 m est donc
  /// dite difficile par la fiche du sentier ET par la fiche de l'etape. Des
  /// seuils propres a cet ecran auraient fabrique la contradiction que la tache
  /// 839 a passe trois lots a retirer sur les temps de marche.
  static const int denivelFacileM = 400;

  /// Au-dela, la journee est difficile (meme seuil que l'etiquetage d'etape).
  static const int denivelDifficileM = 1000;

  /// Au-dela, la journee est d'expert (le `extreme` de l'etiquetage d'etape).
  static const int denivelExpertM = 1500;

  /// Altitude : 1 500 m, 2 000 m, 2 500 m.
  ///
  /// LE PREMIER SEUIL EST SOURCE, LES DEUX AUTRES SONT SON PAS. 1 500 m est le
  /// seuil publie employe par le verdict de faisabilite (`TrekConditions`,
  /// facteur d'altitude #2-h, source #S8-e MOVE 2026 : 1 % de capacite en moins
  /// par tranche de 100 m au-dessus de 1 500 m) — en dessous, l'altitude ne
  /// coute rien, et le dire autrement ici contredirait l'ecran de faisabilite.
  /// Les deux suivants prolongent ce seuil par tranches de 500 m, soit 5 % de
  /// capacite par tranche selon la meme source : 2 000 m et 2 500 m. Aucune
  /// autre source n'a ete trouvee pour decouper l'altitude en niveaux, et c'est
  /// dit plutot que maquille.
  static const int altitudeFacileM = 1500;

  /// Au-dela, l'altitude rend le sentier difficile.
  static const int altitudeDifficileM = 2000;

  /// Au-dela, l'altitude rend le sentier d'expert.
  static const int altitudeExpertM = 2500;

  /// LA REGLE, EN UNE PHRASE, TELLE QU'ELLE S'AFFICHE SOUS LE RESULTAT.
  ///
  /// Elle est ICI et pas dans l'ecran : la regle affichee et la regle appliquee
  /// doivent etre le meme texte, sinon l'une derive. Un test le verifie.
  static const String regleAffichee =
      'Niveau deduit de trois mesures, jamais affirme : le denivele par '
      'journee a l\'allure choisie, la journee la plus dure, et l\'altitude '
      'maximale de la trace. Le niveau retenu est le PIRE des trois. '
      'Une journee passe difficile au-dela de '
      '$denivelDifficileM m de montee et expert au-dela de $denivelExpertM m ; '
      'l\'altitude compte a partir de $altitudeFacileM m.';

  /// Le niveau rendu par un denivele de journee, en metres.
  static NiveauDeDifficulte pourDenivele(int deniveleM) {
    if (deniveleM >= denivelExpertM) return NiveauDeDifficulte.expert;
    if (deniveleM >= denivelDifficileM) return NiveauDeDifficulte.difficile;
    if (deniveleM <= denivelFacileM) return NiveauDeDifficulte.facile;
    return NiveauDeDifficulte.modere;
  }

  /// Le niveau rendu par une altitude maximale, en metres.
  static NiveauDeDifficulte pourAltitude(int altitudeM) {
    if (altitudeM >= altitudeExpertM) return NiveauDeDifficulte.expert;
    if (altitudeM >= altitudeDifficileM) return NiveauDeDifficulte.difficile;
    if (altitudeM < altitudeFacileM) return NiveauDeDifficulte.facile;
    return NiveauDeDifficulte.modere;
  }
}
