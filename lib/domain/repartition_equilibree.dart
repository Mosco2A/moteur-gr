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
///   2. A EGALITE, LES JOURNEES SONT LES PLUS EGALES POSSIBLE. Le second temps
///      n'est pas une elegance, il repare une degenerescence MESUREE :
///      minimiser le seul maximum est indifferent entre toutes les coupes
///      qui partagent ce maximum. Sur les trente et un segments du GR20 repartis en seize
///      journees, l'objectif du seul maximum produisait une journee de
///      24 MINUTES et 1,2 km a cote d'une de 394 minutes — meme journee la
///      plus dure, et une journee qui n'en est pas une. Avec le second
///      temps, les seize journees tiennent entre 205 et 394 minutes
///      (3 h 25 a 6 h 34) et entre 4,9 et 15,3 km.
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

  /// Les index de DEBUT de chaque groupe, pour [groupes] groupes contigus.
  ///
  /// [charges] est la charge de chaque unite dans l'ordre de marche : le TEMPS
  /// DE MARCHE quand l'appelant l'a (le modele unique du depot), le score de
  /// regroupement sinon. Toute charge negative est ramenee a zero — une charge
  /// negative n'a pas de sens et la laisser passer ferait mentir les sommes.
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
    if (groupes >= n) return List<int>.generate(n, (i) => i);

    // Sommes de prefixes : la charge d'un groupe en temps constant.
    final prefixe = List<double>.filled(n + 1, 0);
    for (var i = 0; i < n; i++) {
      final double charge = charges[i] < 0 ? 0 : charges[i];
      prefixe[i + 1] = prefixe[i] + charge;
    }
    double somme(int debut, int fin) => prefixe[fin] - prefixe[debut];

    final double cible = prefixe[n] / groupes;

    // TEMPS 1 — le plus petit maximum atteignable avec exactement `groupes`
    // groupes. Programmation dynamique : `plafonds[i][j]` est le plus petit
    // maximum pour couvrir les i premieres unites en j groupes.
    final plafonds = _grille(n, groupes);
    plafonds[0][0] = 0;
    for (var j = 1; j <= groupes; j++) {
      for (var i = j; i <= n; i++) {
        for (var p = j - 1; p < i; p++) {
          final double precedent = plafonds[p][j - 1];
          if (precedent == double.infinity) continue;
          final double groupe = somme(p, i);
          final double pire = precedent > groupe ? precedent : groupe;
          if (pire < plafonds[i][j]) plafonds[i][j] = pire;
        }
      }
    }
    // Tolerance relative : les charges sont des doubles, et refuser un groupe
    // pour un milliardieme ferait echouer le second temps sans raison.
    final double plafond = plafonds[n][groupes] * (1 + 1e-9);

    // TEMPS 2 — a maximum egal, les journees les plus egales : on minimise la
    // somme des carres d'ecart a la cible, SOUS le plafond du temps 1.
    final ecarts = _grille(n, groupes);
    final origines = <List<int>>[
      for (var i = 0; i <= n; i++) List<int>.filled(groupes + 1, -1),
    ];
    ecarts[0][0] = 0;
    for (var j = 1; j <= groupes; j++) {
      for (var i = j; i <= n; i++) {
        for (var p = j - 1; p < i; p++) {
          final double precedent = ecarts[p][j - 1];
          if (precedent == double.infinity) continue;
          final double groupe = somme(p, i);
          if (groupe > plafond) continue;
          final double ecart = groupe - cible;
          final double total = precedent + ecart * ecart;
          if (total < ecarts[i][j]) {
            ecarts[i][j] = total;
            origines[i][j] = p;
          }
        }
      }
    }

    // Remontee. Si le second temps n'a pas abouti — ce qui ne devrait pas
    // arriver, le plafond venant d'une solution existante —, on ne devine pas :
    // on rend la coupe reguliere, qui tient toutes les garanties de compte.
    if (origines[n][groupes] < 0) return _coupesRegulieres(n, groupes);

    final debuts = <int>[];
    var i = n;
    var j = groupes;
    while (j > 0) {
      final int p = origines[i][j];
      if (p < 0) return _coupesRegulieres(n, groupes);
      debuts.add(p);
      i = p;
      j--;
    }
    return debuts.reversed.toList(growable: false);
  }

  /// Une grille `(n+1) x (groupes+1)` remplie d'infini.
  static List<List<double>> _grille(int n, int groupes) => <List<double>>[
    for (var i = 0; i <= n; i++)
      List<double>.filled(groupes + 1, double.infinity),
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
