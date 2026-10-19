/// LA REPARTITION D'UN SENTIER EN JOURNEES : autant de journees que demande,
/// chacune non vide, et la plus chargee aussi legere que possible.
library;

/// UNE SEULE REPARTITION DANS LE DEPOT, ET VOICI POURQUOI ELLE EXISTE.
///
/// LE DEFAUT QU'ELLE CORRIGE, MESURE SUR LE GR20 (tache 846, memoire #102125).
/// Deux repartiteurs vivaient dans le depot et tous deux coupaient de la meme
/// facon : « j'accumule la charge, je coupe des que j'atteins la cible ». Cette
/// regle a un defaut qui ne saute pas aux yeux et qui rend un compte FAUX :
/// une unite entiere fait souvent DEPASSER la cible, donc les premieres
/// journees prennent plus que leur part, donc il ne reste plus assez de charge
/// pour que les dernieres atteignent la leur, donc on ne coupe plus. Sur le
/// GR20 (seize etapes), `PlanningCalculator` rendait SIX journees pour sept
/// jours demandes, SIX pour neuf, SEPT pour dix, HUIT pour douze.
///
/// CE N'EST PAS UN DETAIL D'ARRONDI DEPUIS LE 17/10. Christophe a tranche,
/// verbatim : « mais le nombre de jour, c'est du conseille, apres le client le
/// fait dans le nombre de jours qu'il veut » (#102126). Une application qui
/// rend huit journees quand le client en demande douze ne respecte pas ce
/// choix : elle le corrige en silence.
///
/// L'OBJECTIF EST LEXICOGRAPHIQUE, EN DEUX TEMPS, ET LES DEUX SONT NECESSAIRES.
///   1. LA JOURNEE LA PLUS CHARGEE EST LA PLUS LEGERE POSSIBLE. C'est la seule
///      chose qui compte vraiment pour le marcheur : c'est la journee la plus
///      dure qui decide s'il arrive (meme regle que le verdict de faisabilite,
///      qui vaut la PIRE journee et elle seule, GO-61).
///   2. A EGALITE, LA PLUS PETITE JOURNEE EST LA PLUS GROSSE POSSIBLE. Le
///      second temps n'est pas une elegance, il repare une degenerescence
///      MESUREE : minimiser le seul maximum est indifferent entre toutes les
///      coupes qui partagent ce maximum, donc le calcul pouvait poser une
///      journee d'UNE HEURE si cela abaissait la pire d'un centieme. Mesure
///      d'Athena du 19/10 : trois plans sur douze portaient une journee sous
///      dix points de note, plus aucun apres — le Nord a huit jours passe
///      d'une journee a 0,96 point (Tighjettu vers la bergerie de Ballone, une
///      heure de marche) a 20,71, et LA PIRE JOURNEE EST IDENTIQUE DANS LES
///      DOUZE PLANS, verifie par assertion.
///
/// CE QUE CE SECOND TEMPS A REMPLACE (tache 860) : il minimisait la somme des
/// carres d'ecart a la cible. Cette regle equilibrait bien mais elle n'avait
/// aucune garantie sur la PLUS PETITE journee, qui est le defaut qu'on voulait
/// tuer. « Maximiser la plus petite » l'attaque de front, et c'est la regle
/// qu'Athena a mesuree.
///
/// CE QU'ELLE NE FAIT PAS : INVENTER UNE COUPE. Elle rend des index de DEBUT de
/// groupe parmi les unites qu'on lui donne ; c'est l'appelant qui garantit que
/// ces unites se terminent quelque part de reel. Sur le GR20, les unites sont
/// les trente et un segments entre NUITS RELEVEES (tache 838) : chaque coupe
/// est un refuge, une bergerie ou un bivouac qui existe dans OpenStreetMap.
/// Le grief de Christophe du 29/09 — « Decouper les etapes en deux est une
/// mauvaise idee... il n'y a pas de refuge » — porte sur le POINT DE COUPE, et
/// il reste entier : ce fichier ne cree aucun point d'arret.
///
/// L'ORDRE EST GARDE : les groupes sont CONTIGUS, on ne marche pas l'etape 6
/// avant la 5.
abstract final class RepartitionEquilibree {
  RepartitionEquilibree._();

  /// Tolerance relative sur le plafond du premier temps.
  ///
  /// Les charges sont des doubles : refuser un groupe pour un milliardieme
  /// ferait echouer le second temps sans aucune raison.
  static const double _tolerance = 1e-9;

  /// Les index de DEBUT de chaque groupe, pour [groupes] groupes contigus, avec
  /// une charge ADDITIVE par unite.
  ///
  /// [charges] est la charge de chaque unite dans l'ordre de marche. Toute
  /// charge negative est ramenee a zero — une charge negative n'a pas de sens
  /// et la laisser passer ferait mentir les sommes.
  ///
  /// GARANTIES, et elles sont testees :
  ///  - la liste rendue a EXACTEMENT `min(groupes, charges.length)` entrees :
  ///    on ne rend jamais moins de journees que demande, sauf a manquer
  ///    d'unites — et alors c'est une unite par journee ;
  ///  - elle commence par 0 et croit strictement : aucun groupe n'est vide ;
  ///  - vide quand [charges] est vide ou que [groupes] est nul ou negatif.
  static List<int> coupes(List<double> charges, int groupes) {
    final int n = charges.length;
    if (n == 0 || groupes <= 0) return const <int>[];

    // Sommes de prefixes : la charge d'un groupe en temps constant.
    final prefixe = List<double>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      final double charge = charges[i] < 0 ? 0 : charges[i];
      prefixe[i + 1] = prefixe[i] + charge;
    }

    return coupesSelon(
      unites: n,
      groupes: groupes,
      chargeDuGroupe: (debut, fin) => prefixe[fin] - prefixe[debut],
    );
  }

  /// LES COUPES POUR UNE CHARGE DE GROUPE QUELCONQUE — le chemin de l'EFFORT.
  ///
  /// [chargeDuGroupe] rend la charge de la journee faite des unites `debut`
  /// (inclus) a `fin` (exclu). ELLE N'A PAS BESOIN D'ETRE ADDITIVE, et c'est
  /// tout l'interet : l'indice de terrain d'une journee N'EST PAS la somme des
  /// indices de ses morceaux (la majoration de continuite est sous-additive
  /// quand on coupe dans une montee). Avec cette porte, le decoupage optimise
  /// le chiffre qu'on AFFICHE, et pas une approximation de ce chiffre.
  ///
  /// LES DEUX TEMPS LEXICOGRAPHIQUES RESTENT VALIDES POUR UNE CHARGE NON
  /// ADDITIVE : le minimum et le maximum se decomposent sur une partition
  /// contigue, donc la programmation dynamique reste exacte. Une somme, elle,
  /// ne resisterait pas.
  ///
  /// Chaque charge est evaluee UNE SEULE FOIS puis gardee : les deux temps
  /// parcourent les memes groupes, et une charge d'effort coute un calcul de
  /// profil.
  static List<int> coupesSelon({
    required int unites,
    required int groupes,
    required double Function(int debut, int fin) chargeDuGroupe,
  }) {
    if (unites <= 0 || groupes <= 0) return const <int>[];
    if (groupes >= unites) return List<int>.generate(unites, (i) => i);

    final gardees = <int, double>{};
    double charge(int debut, int fin) =>
        gardees[debut * (unites + 1) + fin] ??= chargeDuGroupe(debut, fin);

    // TEMPS 1 — le plus petit maximum atteignable avec exactement `groupes`
    // groupes. `plafonds[i][j]` est le plus petit maximum pour couvrir les i
    // premieres unites en j groupes.
    final plafonds = _grille(unites, groupes, double.infinity);
    plafonds[0][0] = 0;
    for (var j = 1; j <= groupes; j++) {
      for (var i = j; i <= unites; i++) {
        for (var p = j - 1; p < i; p++) {
          final double precedent = plafonds[p][j - 1];
          if (precedent == double.infinity) continue;
          final double groupe = charge(p, i);
          final double pire = precedent > groupe ? precedent : groupe;
          if (pire < plafonds[i][j]) plafonds[i][j] = pire;
        }
      }
    }
    final double plafond = plafonds[unites][groupes] * (1 + _tolerance);

    // TEMPS 2 — a maximum egal, la PLUS PETITE journee la plus grosse possible.
    // `planchers[i][j]` est le plus grand minimum atteignable, tous les groupes
    // restant sous le plafond du premier temps.
    final planchers = _grille(unites, groupes, double.negativeInfinity);
    final origines = <List<int>>[
      for (var i = 0; i <= unites; i++) List<int>.filled(groupes + 1, -1),
    ];
    planchers[0][0] = double.infinity;
    for (var j = 1; j <= groupes; j++) {
      for (var i = j; i <= unites; i++) {
        for (var p = j - 1; p < i; p++) {
          final double precedent = planchers[p][j - 1];
          if (precedent == double.negativeInfinity) continue;
          final double groupe = charge(p, i);
          if (groupe > plafond) continue;
          final double plusPetite = precedent < groupe ? precedent : groupe;
          if (plusPetite > planchers[i][j]) {
            planchers[i][j] = plusPetite;
            origines[i][j] = p;
          }
        }
      }
    }

    // Remontee. Si le second temps n'a pas abouti — ce qui ne devrait pas
    // arriver, le plafond venant d'une solution existante —, on ne devine pas :
    // on rend la coupe reguliere, qui tient toutes les garanties de compte.
    if (origines[unites][groupes] < 0) {
      return _coupesRegulieres(unites, groupes);
    }

    final debuts = <int>[];
    var i = unites;
    var j = groupes;
    while (j > 0) {
      final int p = origines[i][j];
      if (p < 0) return _coupesRegulieres(unites, groupes);
      debuts.add(p);
      i = p;
      j--;
    }
    return debuts.reversed.toList(growable: false);
  }

  /// Une grille `(unites+1) x (groupes+1)` remplie de [valeur].
  static List<List<double>> _grille(
    int unites,
    int groupes,
    double valeur,
  ) => <List<double>>[
    for (var i = 0; i <= unites; i++) List<double>.filled(groupes + 1, valeur),
  ];

  /// Coupe REGULIERE : [groupes] groupes non vides de tailles aussi egales que
  /// possible, sans regarder la charge. Filet de securite uniquement.
  static List<int> _coupesRegulieres(int n, int groupes) {
    final debuts = <int>[];
    for (var g = 0; g < groupes; g++) {
      debuts.add((g * n / groupes).floor());
    }
    // Deux groupes ne peuvent pas commencer au meme endroit : on decale.
    for (var g = 1; g < debuts.length; g++) {
      if (debuts[g] <= debuts[g - 1]) debuts[g] = debuts[g - 1] + 1;
    }
    return List<int>.unmodifiable(debuts);
  }
}
