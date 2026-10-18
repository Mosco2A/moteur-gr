/// LE FACTEUR DE PENTE DE L'INDICE DE TERRAIN : UNE MESURE DE LABORATOIRE,
/// RELUE A LA SOURCE, ET TROIS PENTES QUI N'Y SONT PAS MESUREES.
library;

/// LE COUT ENERGETIQUE DE LA MARCHE SELON LA PENTE, MESURE (tache 857).
///
/// SOURCE, ET ELLE EST UNIQUE. Minetti AE, Moia C, Roi GS, Susta D,
/// Ferretti G. « Energy cost of walking and running at extreme uphill and
/// downhill slopes ». Journal of Applied Physiology 93:1039-1046, 2002,
/// TABLE 2 — cout MINIMAL de la marche, en joules par kilogramme et par metre
/// de TRAJET. Treize pentes y sont mesurees, de -45 % a +45 %, et treize
/// seulement.
///
/// CE QUI EST MESURE, ET CE QUI NE L'EST PAS — A LIRE AVANT TOUTE REPRISE.
/// Les treize pentes de [pentesMesurees] sont des MESURES. Toute autre pente
/// est INTERPOLEE par [coutJParKgParM], et les trois pentes que le mandat
/// nommait — 5 %, 15 % et 25 % — SONT DE CELLES-LA : elles n'ont pas ete
/// mesurees par l'article. Leurs valeurs interpolees valent 1,782, 3,880 et
/// 5,925 point par kilometre ; elles sont le prolongement regulier de la
/// courbe mesuree, pas une observation. 1,6 % du trajet du GR20 depasse meme
/// 45 % de pente : la courbe y est PROLONGEE, ce que l'article autorise en
/// montee — il dit le cout proportionnel a la pente au-dela de 15 % — et ce
/// qui reste une extrapolation en descente.
///
/// LE POLYNOME PUBLIE N'EST PAS EMPLOYE, ET LA RAISON SE VERIFIE EN DEUX
/// LIGNES. Le meme article publie, dans la meme figure,
/// `Cw(i) = 280,5 i^5 - 58,7 i^4 - 76,8 i^3 + 51,9 i^2 + 19,6 i + 2,5`
/// (R2 = 0,999). A plat il rend 2,50 quand la Table 2 du MEME article mesure
/// 1,64 : CINQUANTE-DEUX POUR CENT DE TROP. A -10 % il rend 1,13 quand la
/// table mesure 0,81, trente-neuf pour cent de trop. Il est excellent au-dela
/// de 10 % et faux sur le terrain doux — qui est justement la ou un grand
/// itineraire passe le plus de kilometres. Ce fichier retient donc les POINTS
/// MESURES, relies par une interpolation cubique monotone (Fritsch-Carlson,
/// aucun depassement), et le polynome ne sert nulle part.
///
/// L'UNITE : UN POINT EST UN KILOMETRE DE PLAT. [pointsParKmDeTrajet] divise
/// le cout mesure par celui du plat, donc le plat vaut 1,000 point par
/// kilometre par construction. Ce qui en decoule, et qui corrige deux idees
/// recues du metier :
///
///   - LA DESCENTE DOUCE COUTE MOINS QUE LE PLAT : 0,494 point par kilometre a
///     -10 %, soit LA MOITIE du plat. Elle ne redevient aussi chere que le plat
///     qu'a [penteOuLaDescenteCouteLePlat], et ce seuil est LU sur la courbe,
///     pas choisi.
///   - CENT METRES DE MONTEE COUTENT ENVIRON DEUX POINTS, donc DEUX kilometres
///     de plat et non un. La regle du metier — 100 m de D+ = 1 km de plat — est
///     une equivalence de TEMPS, pas d'energie : 100 m a 400 m/h et 1 km a
///     4 km/h font tous deux un quart d'heure. C'EST LA RAISON DE FOND POUR
///     LAQUELLE L'INDICE DE TERRAIN ET LE TEMPS DE MARCHE SONT DEUX NOMBRES
///     DISTINCTS, portant deux noms distincts, dans ce depot.
///
/// LES LIMITES DE LA SOURCE, PARCE QU'ELLES SONT REELLES. Le Cw de la Table 2
/// est le cout MINIMAL, atteint a la vitesse OPTIMALE de chaque pente, et ces
/// vitesses ne sont pas celles d'un randonneur : 3,14 m/s a -10 %, 0,69 m/s a
/// +45 %. Dix coureurs, sans sac, sur tapis roulant. C'est du METABOLIQUE et
/// non du mecanique : l'oxygene, pas les degats aux genoux. L'ORDRE des couts
/// tient donc ; le chiffre exact d'une descente douce marchee avec un sac de
/// dix kilos ne tient pas.
abstract final class FacteurDePenteMinetti {
  /// LE COUT DU PLAT, QUI DONNE SON UNITE A L'INDICE : 1,64 J/kg/m (Table 2).
  static const double coutDuPlatJParKgParM = 1.64;

  /// LES TREIZE PENTES MESUREES, en fraction (0,10 = 10 %), croissantes.
  ///
  /// Noter les absences : ni -0,25, ni -0,15, ni -0,05, ni +0,05, ni +0,15, ni
  /// +0,25. L'article ne les a pas mesurees.
  static const List<double> pentesMesurees = <double>[
    -0.45,
    -0.40,
    -0.35,
    -0.30,
    -0.20,
    -0.10,
    0.0,
    0.10,
    0.20,
    0.30,
    0.35,
    0.40,
    0.45,
  ];

  /// LES TREIZE COUTS MESURES, en J/kg par metre de trajet, dans l'ordre de
  /// [pentesMesurees] (Table 2, relue sur l'article).
  static const List<double> coutsMesuresJParKgParM = <double>[
    3.46,
    3.23,
    2.65,
    2.18,
    1.30,
    0.81,
    1.64,
    4.68,
    8.07,
    11.29,
    12.72,
    14.75,
    17.33,
  ];

  /// LA PENTE OU UNE DESCENTE REDEVIENT AUSSI CHERE QUE LE PLAT : -24,3 %.
  ///
  /// CE SEUIL EST LU SUR LA COURBE MESUREE, IL N'EST PAS CHOISI. Plus douce que
  /// cette raideur, une descente coute MOINS qu'un kilometre de plat ; plus
  /// raide, elle coute PLUS. C'est lui qui definit [terrainReposant], donc ce
  /// qui donne du repit a une montee et ce qui n'en donne pas : la descente
  /// douce repose, la descente raide fatigue. Un test le reverifie en resolvant
  /// `coutJParKgParM(pente) == coutDuPlatJParKgParM` sur la courbe, pour que ce
  /// nombre ne puisse pas deriver de la mesure qui le produit.
  static const double penteOuLaDescenteCouteLePlat = -0.243;

  /// LE COUT MESURE OU INTERPOLE D'UNE PENTE, en J/kg par metre de trajet.
  ///
  /// Interpolation cubique monotone de Fritsch-Carlson (1980) entre les treize
  /// points mesures : elle passe EXACTEMENT par chaque mesure et ne fabrique
  /// aucun depassement entre deux d'entre elles — une spline ordinaire
  /// inventerait un creux sous 0,81 J/kg/m autour de -10 %, donc une descente
  /// moins couteuse que la plus economique jamais mesuree.
  ///
  /// AU-DELA DES BORNES MESUREES la courbe est PROLONGEE PAR SA TANGENTE, donc
  /// lineairement. Ce n'est plus une mesure : c'est la continuation la plus
  /// sobre de la derniere pente mesuree.
  static double coutJParKgParM(double pente) {
    const x = pentesMesurees;
    const y = coutsMesuresJParKgParM;
    final m = _tangentes;
    if (pente <= x.first) return y.first + m.first * (pente - x.first);
    if (pente >= x.last) return y.last + m.last * (pente - x.last);
    var i = 0;
    while (x[i + 1] < pente) {
      i++;
    }
    final h = x[i + 1] - x[i];
    final t = (pente - x[i]) / h;
    final t2 = t * t;
    final t3 = t2 * t;
    return (2 * t3 - 3 * t2 + 1) * y[i] +
        (t3 - 2 * t2 + t) * h * m[i] +
        (-2 * t3 + 3 * t2) * y[i + 1] +
        (t3 - t2) * h * m[i + 1];
  }

  /// LE COUT D'UN KILOMETRE DE TRAJET A CETTE PENTE, EN POINTS D'INDICE.
  ///
  /// Un point est un kilometre de plat, donc cette fonction vaut 1,000 a plat,
  /// 0,494 a -10 %, 2,854 a +10 % et 10,567 a +45 %.
  ///
  /// LA LONGUEUR A LUI DONNER EST CELLE DU TRAJET REELLEMENT PARCOURU — la
  /// pente du terrain, pas sa projection sur la carte. C'est ce que l'article
  /// mesure (un metre de tapis incline) et l'ecart n'est pas negligeable sur un
  /// sentier de montagne : il vaut 2,6 % de l'indice du GR20.
  static double pointsParKmDeTrajet(double pente) =>
      coutJParKgParM(pente) / coutDuPlatJParKgParM;

  /// VRAI QUAND CE TERRAIN REPOSE, c'est-a-dire quand son cout mesure par
  /// kilometre n'excede pas celui du plat.
  ///
  /// Cela couvre LE PLAT et LA DESCENTE PLUS DOUCE QUE
  /// [penteOuLaDescenteCouteLePlat] — et cela EXCLUT la descente raide, qui
  /// coute plus qu'un kilometre de plat, ainsi que toute montee, aussi douce
  /// soit-elle. La definition est le cout lui-meme et non une borne recopiee :
  /// le jour ou la courbe bouge, le terrain reposant bouge avec elle.
  static bool terrainReposant(double pente) =>
      coutJParKgParM(pente) <= coutDuPlatJParKgParM;

  /// VRAI QUAND CETTE PENTE EST L'UNE DES TREIZE QUE L'ARTICLE A MESUREES.
  ///
  /// Sert a dire, partout ou un chiffre de pente est cite ou teste, s'il est
  /// une observation ou une interpolation. `terrainReposant(-0,05)` est vrai,
  /// mais -5 % n'a jamais ete mesure : les deux faits doivent pouvoir se dire
  /// ensemble.
  static bool mesuree(double pente) =>
      pentesMesurees.any((p) => (p - pente).abs() < 1e-9);

  /// Les tangentes de Fritsch-Carlson aux treize points mesures.
  ///
  /// Tangente NULLE a chaque changement de sens de la courbe — le minimum de
  /// -10 % —, moyenne harmonique ponderee ailleurs : c'est ce qui garantit
  /// qu'aucun morceau de courbe ne depasse les deux mesures qui l'encadrent.
  static final List<double> _tangentes = _calculerLesTangentes();

  static List<double> _calculerLesTangentes() {
    const x = pentesMesurees;
    const y = coutsMesuresJParKgParM;
    final n = x.length;
    final h = <double>[for (var i = 0; i < n - 1; i++) x[i + 1] - x[i]];
    final d = <double>[
      for (var i = 0; i < n - 1; i++) (y[i + 1] - y[i]) / h[i],
    ];
    final m = List<double>.filled(n, 0.0);
    m[0] = d.first;
    m[n - 1] = d.last;
    for (var i = 1; i < n - 1; i++) {
      if (d[i - 1] * d[i] <= 0) continue;
      final poidsGauche = 2 * h[i] + h[i - 1];
      final poidsDroit = h[i] + 2 * h[i - 1];
      m[i] =
          (poidsGauche + poidsDroit) /
          (poidsGauche / d[i - 1] + poidsDroit / d[i]);
    }
    return List<double>.unmodifiable(m);
  }
}
