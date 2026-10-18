/// LE TEMPS DE MARCHE PAR NAISMITH (1892), CORRIGE PAR LANGMUIR (1984) — un
/// modele PUBLIC et verifiable, et l unite dans laquelle la difficulte se
/// comptera.
library;

import 'dart:math' as math;

/// NAISMITH PLUS LANGMUIR : DEUX REFERENCES PUBLIQUES, ET VOILA POURQUOI.
///
/// CE QUI A ETE DEMANDE, ET POURQUOI. Christophe a demande d ou sortait le
/// calculateur de difficulte. La reponse honnete etait mauvaise :
///
///  - l echelle d effort du depot ([SeuilsDeDifficulte]) reprend les
///    INGREDIENTS de l indice IBP, dont le bareme exact n est PAS public — le
///    depot l ecrit lui-meme (`ibp_calculator.dart` : « le bareme IBP n etant
///    pas public, c est une approximation assumee ») ;
///  - l equivalence « 100 m de montee valent 1 km de plat » est citee partout
///    sans etude primaire ;
///  - le poids 0,30 de la descente n est source nulle part.
///
/// Decision du 18/10 11:33, verbatim : « prend NAISMITH pour tes calculs ».
///
/// NAISMITH EST PUBLIC. W. W. Naismith, Scottish Mountaineering Club Journal,
/// 1892 : UNE HEURE POUR CINQ KILOMETRES, PLUS UNE HEURE POUR SIX CENTS METRES
/// DE MONTEE. Deux nombres, une phrase, verifiable par quiconque. Elle est
/// aussi plus GENEREUSE que ce que le depot appliquait : 100 m de montee y
/// valent 0,83 km de plat, quand l ancien calcul en demandait 1,00 — nous
/// etions vingt pour cent plus severes que la reference que nous citions.
///
/// NAISMITH PUR NE COMPTE PAS LA DESCENTE, ET C EST SON DEFAUT. L adopter tel
/// quel effacerait ce que Christophe avait demande la veille — que le negatif
/// et les kilometres comptent. D ou LANGMUIR (E. Langmuir, *Mountaincraft and
/// Leadership*, 1984), publique, de la meme lignee et enseignee avec Naismith :
///
///  - rien sous [penteDouceDeg] : c est du plat, que Naismith paie deja ;
///  - MOINS [langmuirMinutes] minutes par [langmuirParMetres] metres de
///    descente entre [penteDouceDeg] et [penteRaideDeg] degres — on descend
///    plus vite qu on ne marche a plat ;
///  - PLUS [langmuirMinutes] minutes par [langmuirParMetres] metres au-dela de
///    [penteRaideDeg] degres — une dalle raide se descend lentement.
///
/// CE QUE LA MESURE DIT DE CETTE CORRECTION, ET IL FAUT LE DIRE EN PREMIER.
/// Sur le GR20 mesure segment par segment (tache 855,
/// `assets/data/gr20/naismith_855.json`), la correction de Langmuir pese
/// +21 MINUTES SUR 56 h 07, soit 0,6 %. Elle retire 157 minutes sur les pentes
/// douces et en ajoute 177 sur les raides : les deux se compensent presque,
/// parce que la descente du sentier se repartit en 40 % de pente douce, 45 % de
/// pente raide et 14 % sous le seuil. SUR L ETAPE 6 — la plus dure des seize —
/// Langmuir accorde meme une REMISE de 17 minutes.
///
/// DONC : « que le negatif compte » N EST PAS OBTENU par Langmuir, et personne
/// ici n ecrira le contraire. Ce qui fait de l etape 6 la plus dure sous ce
/// modele, ce sont ses VINGT-CINQ KILOMETRES (5 h 00 des 6 h 01), pas ses
/// 1 191 m de descente. Les kilometres comptent, et beaucoup ; le negatif, a
/// peine. C est un arbitrage ouvert, pas un resultat a cacher.
///
/// LA PENTE SE CLASSE SUR LA TRACE, JAMAIS SUR UNE MOYENNE, ET C EST LE POINT
/// QUI DECIDE. L etape 6 descend 1 190 m sur 25 km, soit 2,7 degres de
/// moyenne : classee sur sa moyenne elle serait « sous le seuil » et ne
/// toucherait aucune correction. Mesuree segment par segment, elle porte 723 m
/// de pente douce et 200 m de pente raide. La moyenne et la mesure ne disent
/// pas seulement des nombres differents, elles disent le CONTRAIRE l une de
/// l autre. C est pourquoi cette classe reçoit la descente DEJA CLASSEE : le
/// classement demande les 9 128 points de la trace, qui vivent dans l outil de
/// mesure (`tool/naismith_langmuir_855.py`), pas dans le telephone.
///
/// CE QUE CETTE CLASSE NE FAIT PAS, ET CE N EST PAS UN OUBLI.
///
///  1. ELLE NE FIXE AUCUN SEUIL ET NE CLASSE RIEN. Christophe, 18/10 11:33 :
///     « ensuite on discutera du positionnement facile/moyen/difficile/tres
///     difficile ». Les quatre bandes de [SeuilsDeDifficulte] restent donc en
///     kilometres-effort jusqu a ce qu il tranche en heures. Les deux calculs
///     vivent cote a cote exprès, et la mesure donne l intervalle : ses deux
///     ancres — Calenzana-Ortu « tres difficile », Vizzavona-E Capanelle « sous
///     le seuil » — valent 4 h 41 et 4 h 18, et AUCUNE des seize etapes ne
///     tombe entre les deux. Tout seuil dans l intervalle ouvert
///     (4 h 18 ; 4 h 41] reproduit ses deux verdicts. Le choix est a lui.
///
///  2. ELLE NE REMPLACE PAS LE MODELE DE TEMPS OPERATIONNEL du depot
///     (`lib/core/models/stage_duration.dart` : 4 km/h a plat, 400 m de montee
///     a l heure, descente payee 1,67 s par metre), ET L ECART ENTRE LES DEUX
///     EST LE FAIT LE PLUS GENANT DE CETTE TACHE.
///
///     SUR LE GR20 ENTIER : 56 h 27 par Naismith-Langmuir contre 80 h 24 par le
///     modele maison. VINGT-QUATRE HEURES, soit 30 % de moins. Par etape
///     l ecart est du meme ordre, et il porte sur la journee qui compte :
///     L ETAPE 6 FAIT 8 h 46 POUR LE MODELE MAISON ET 6 h 01 POUR
///     NAISMITH-LANGMUIR. Or 8 h 46 est le chiffre que l application AFFICHE
///     DEJA pour cette etape (`stages.json`, `estimatedDurationMinutes`).
///     Compter la difficulte en heures de Naismith mettrait donc DEUX NOMBRES
///     D HEURES DIFFERENTS SUR LA MEME JOURNEE, a deux ecrans d intervalle, et
///     l ecart serait de deux heures quarante-cinq sur la pire etape du
///     sentier. C est exactement le defaut que la tache 839 avait paye pour
///     fermer (« 29 % d ecart entre le programme qu on prepare et l heure qu on
///     annonce »), et il reviendrait par l autre bout.
///
///     POURQUOI NAISMITH EST PLUS RAPIDE, ET POURQUOI CE N EST PAS UN BUG : ses
///     deux allures sont celles d un marcheur ENTRAINE — 5 km/h a plat contre
///     4, et 600 m de montee a l heure contre 400. La tache 839 avait choisi
///     les valeurs PRUDENTES en toute connaissance, verbatim : « en montagne on
///     n annonce pas des horaires optimistes : une estimation trop courte se
///     paie a la tombee de la nuit ». Adopter Naismith pour les horaires
///     AFFICHES serait donc revenir sur une decision de securite documentee.
///
///     CE QUI EST FAIT ICI, ET CE QUI RESTE A ARBITRER. Le modele public sert a
///     MESURER ET A CLASSER (il ordonne les seize etapes presque exactement
///     comme l ancien : les six plus dures gardent le meme ordre, et seules
///     trois paires du milieu de tableau s echangent). Le modele prudent
///     continue d ANNONCER les horaires. Deux modeles de temps coexistent donc,
///     la doctrine « un seul modele de temps de marche » de la tache 839 est
///     ENTAMEE, et personne ici ne fera semblant du contraire : c est un
///     arbitrage a rendre a Christophe, pas une chose a trancher dans un
///     commentaire.
abstract final class TempsNaismithLangmuir {
  TempsNaismithLangmuir._();

  /// UNE HEURE POUR CINQ KILOMETRES — soit 12 minutes du kilometre.
  ///
  /// Derivee et non ecrite : [kmParHeure] est le nombre de Naismith, les
  /// minutes s en deduisent. Deux constantes pour une seule vitesse, c est la
  /// garantie qu un jour l une changera sans l autre — le depot a deja paye
  /// cette erreur (4,0 km/h d un cote, 1,1 m/s soit 3,96 de l autre).
  static const double kmParHeure = 5.0;

  /// UNE HEURE POUR SIX CENTS METRES DE MONTEE — soit 0,1 minute du metre.
  static const double monteeMetresParHeure = 600.0;

  /// Sous cette pente, en degres, la descente ne corrige RIEN.
  static const double penteDouceDeg = 5.0;

  /// Au-dela de cette pente, en degres, la descente COUTE au lieu de rapporter.
  static const double penteRaideDeg = 12.0;

  /// Les minutes que Langmuir retire (pente douce) ou ajoute (pente raide)...
  static const double langmuirMinutes = 10.0;

  /// ... par cette quantite de metres de descente.
  static const double langmuirParMetres = 300.0;

  /// Minutes par kilometre de plat, DERIVEE de [kmParHeure].
  static const double minutesParKm = 60.0 / kmParHeure;

  /// Minutes par metre de montee, DERIVEE de [monteeMetresParHeure].
  static const double minutesParMetreDeMontee = 60.0 / monteeMetresParHeure;

  /// Minutes par metre de descente corrigee, DERIVEE des deux constantes de
  /// Langmuir.
  static const double minutesParMetreDeDescenteCorrigee =
      langmuirMinutes / langmuirParMetres;

  /// LE TEMPS DE MARCHE, EN MINUTES, D UNE UNITE DEJA MESUREE SUR LA TRACE.
  ///
  ///   minutes = km x 12
  ///           + montee x 0,1
  ///           - descenteDouce / 300 x 10
  ///           + descenteRaide / 300 x 10
  ///
  /// [descenteEnPenteDouceM] et [descenteEnPenteRaideM] sont les metres de
  /// descente DEJA CLASSES par pente, segment par segment, par l outil de
  /// mesure. La descente sous [penteDouceDeg] n entre pas : elle ne corrige
  /// rien, et la passer ici serait l occasion de la compter par erreur.
  ///
  /// EXEMPLE MESURE, l etape 6 du GR20 (la plus dure des seize) : 25,014 km,
  /// 786 m de montee, 723 m de descente en pente douce et 200 m en pente
  /// raide, soit 300,2 + 78,6 - 24,1 + 6,7 = 361,4 minutes, donc 6 h 01.
  ///
  /// RAMENE A ZERO SI LE TOTAL EST NEGATIF, parce qu une duree de marche
  /// negative n est pas une duree. Le cas ne se produit sur aucune des
  /// quatre-vingt-quatorze unites mesurees du GR20 (seize etapes et trente et
  /// un segments, dans les deux sens), et la garde est la pour le sentier qui
  /// ne descendrait que des pentes douces. Fonction PURE.
  ///
  /// Toute entree negative ou non finie compte pour ZERO : une mesure absente
  /// ne doit jamais devenir une duree inventee — c est la discipline de
  /// [walkingSeconds], et elle vaut ici mot pour mot.
  static double minutes({
    required double km,
    required double deniveleM,
    required double descenteEnPenteDouceM,
    required double descenteEnPenteRaideM,
  }) {
    final plat = _mesurable(km);
    final montee = _mesurable(deniveleM);
    final douce = _mesurable(descenteEnPenteDouceM);
    final raide = _mesurable(descenteEnPenteRaideM);

    final total =
        plat * minutesParKm +
        montee * minutesParMetreDeMontee -
        douce * minutesParMetreDeDescenteCorrigee +
        raide * minutesParMetreDeDescenteCorrigee;

    return total < 0 ? 0 : total;
  }

  /// LA PENTE D UN SEGMENT DE TRACE, EN DEGRES, descente comptee positivement.
  ///
  /// Une longueur horizontale nulle sous une chute d altitude est une falaise :
  /// quatre-vingt-dix degres, donc pente raide. Sans ce cas, la division
  /// rendrait un `NaN` qui contaminerait tout total l ayant croise.
  ///
  /// Elle vit ICI et non dans l outil de mesure pour une seule raison : la
  /// regle de classement et la regle de calcul doivent etre le MEME texte,
  /// sinon l une derive. L outil la recopie en Python et un test compare les
  /// deux resultats sur les quatre-vingt-quatorze unites du GR20.
  static double penteDeg({required double longueurM, required double chuteM}) {
    final chute = _mesurable(chuteM);
    final longueur = _mesurable(longueurM);
    if (chute == 0) return 0;
    if (longueur == 0) return 90;
    return math.atan(chute / longueur) * 180.0 / math.pi;
  }

  /// VRAI quand cette pente de descente doit etre CHARGEE par Langmuir.
  static bool penteRaide(double deg) => deg > penteRaideDeg;

  /// VRAI quand cette pente de descente doit etre ESCOMPTEE par Langmuir.
  static bool penteDouce(double deg) =>
      deg >= penteDouceDeg && deg <= penteRaideDeg;

  static double _mesurable(double valeur) =>
      valeur.isFinite && valeur > 0 ? valeur : 0.0;
}

/// LA FONCTION DE TOBLER (1993) — LA SEULE DES TROIS QUI VOIE LA RAIDEUR.
///
/// CE QUE CHRISTOPHE A VU, ET IL A RAISON. Verbatim le 18/10 11:56 : « quand
/// les montes sont pentue c'est pus dificile de monter 700 metres sur 1KM que
/// 700 metre sur 5 ». NAISMITH NE SAIT PAS LE DIRE : il est LINEAIRE en
/// denivele — une heure par six cents metres, quelle que soit la pente — donc
/// 700 m lui coutent exactement 1 h 10 qu ils soient etales sur 1 km ou sur 5.
/// Langmuir ne regarde la pente QUE pour la descente. Les deux sont donc
/// aveugles a la raideur d une montee.
///
/// TOBLER NE L EST PAS. Waldo Tobler, « Three Presentations on Geographical
/// Analysis and Modeling », NCGIA Technical Report 93-1, 1993 — publique, et
/// c est la fonction de marche des outils de cartographie :
///
///     vitesse = 6 x exp(-3,5 x |pente + 0,05|)   en km/h
///
/// La pente est le rapport du denivele a la distance HORIZONTALE, SIGNEE
/// (positive en montee), et la vitesse s applique a la distance horizontale.
///
/// CE QU ELLE REPOND A CHRISTOPHE, EN CHIFFRES :
///
///   | pente        | vitesse   | 700 m de montee coutent |
///   | ------------ | --------- | ----------------------- |
///   | 70 % (1 km)  | 0,43 km/h | 2 h 19                  |
///   | 14 % (5 km)  | 3,08 km/h | 1 h 37                  |
///
/// QUARANTE-DEUX MINUTES D ECART pour le meme denivele. Naismith dit 1 h 10
/// dans les deux cas.
///
/// CE QUE LA MESURE DIT DE TOBLER SUR LE GR20, ET C EST CONTRE-INTUITIF.
/// Teste sur le seul vecu dont nous disposons — Christophe a trouve
/// Paliri-Conca FACILE et Conca-Paliri ARRETANT, la meme etape dans les deux
/// sens —, TOBLER SEPARE LE MOINS BIEN LES DEUX SENS : rapport 1,17 contre
/// 1,43 pour Naismith et 1,44 pour Naismith-Langmuir. La raison est nette :
/// Tobler penalise aussi la DESCENTE raide, donc il alourdit le sens que
/// Christophe a trouve facile et rapproche les deux. Sur ce critere-la, la
/// recommandation de prendre Tobler ne tient pas — et personne ici ne la
/// maquillera.
///
/// ET AUCUN DES TROIS NE VOIT CE QUI L A REELLEMENT ARRETE. Tobler est SANS
/// MEMOIRE : il calcule une vitesse par segment et les additionne, donc trois
/// montees de 1 km separees par du plat et 3 km de raide d un seul tenant lui
/// donnent le MEME temps. Christophe l avait dit aussi (18/10 12:00 : « 3 fois
/// 1K de denivelle separe par 3K de plat ce n est pas pareil que 3 km de raide
/// d un seul tenant »), et la mesure de son arret le confirme : entre son point
/// « sans probleme » (trois cinquiemes de la montee) et son arret (quatre
/// cinquiemes) il n y a que 63 m de denivele et neuf minutes, mais LA PENTE
/// LOCALE PASSE DE 19,9 % A 26,9 %. Ce qui aurait predit son arret n est aucun
/// de ces trois temps : c est le descripteur de la MONTEE D UN SEUL TENANT
/// (294 m sur 1,61 km a 18,3 % de moyenne et 35,8 % de pointe, des le
/// kilometre 0,34), mesure par `tool/naismith_langmuir_855.py` et publie dans
/// `assets/data/gr20/naismith_855.json` sous la cle `raideur`.
abstract final class VitesseDeTobler {
  VitesseDeTobler._();

  /// Vitesse de pointe, en km/h, atteinte a [penteLaPlusRapide].
  static const double vitesseKmH = 6.0;

  /// Le coefficient d amortissement de la pente.
  static const double amortissement = 3.5;

  /// LA PENTE LA PLUS RAPIDE : -5 %, soit une LEGERE DESCENTE.
  ///
  /// Ce n est pas le plat, et c est l une des choses que Tobler apporte : on
  /// marche plus vite en descendant doucement qu a l horizontale.
  static const double penteLaPlusRapide = 0.05;

  /// LA VITESSE DE MARCHE, EN KM/H, POUR UNE PENTE SIGNEE (positive en montee).
  ///
  /// [pente] est un RAPPORT et non un pourcentage : 0,14 pour 14 %. Une pente
  /// non finie compte pour zero — une mesure absente ne doit jamais devenir une
  /// vitesse inventee.
  ///
  /// La vitesse rendue est strictement positive, donc un temps calcule avec
  /// elle ne divise jamais par zero : `exp` d un reel fini l est toujours.
  /// Fonction PURE.
  static double kmH(double pente) {
    final valeur = pente.isFinite ? pente : 0.0;
    return vitesseKmH *
        math.exp(-amortissement * (valeur + penteLaPlusRapide).abs());
  }

  /// LE TEMPS, EN MINUTES, POUR FRANCHIR UN SEGMENT DE TRACE.
  ///
  /// [longueurHorizontaleM] est la distance de carte, [deniveleM] la variation
  /// d altitude SIGNEE (negative en descente). La pente s en deduit : c est
  /// exactement la facon dont Tobler a publie sa fonction, et la seule qui
  /// permette de l appliquer SEGMENT PAR SEGMENT sur une trace.
  ///
  /// Zero pour une longueur nulle : sans longueur il n y a pas de chemin, donc
  /// pas de temps — et la pente serait infinie.
  static double minutes({
    required double longueurHorizontaleM,
    required double deniveleM,
  }) {
    if (!longueurHorizontaleM.isFinite || longueurHorizontaleM <= 0) return 0;
    final denivele = deniveleM.isFinite ? deniveleM : 0.0;
    final pente = denivele / longueurHorizontaleM;
    return longueurHorizontaleM / 1000.0 / kmH(pente) * 60.0;
  }
}
