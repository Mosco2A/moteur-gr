/// L'INDICE DE TERRAIN : ce que le CHEMIN demande, en un nombre, sans aucun
/// mot de niveau et sans rien savoir de celui qui le marche.
library;

import 'dart:math' as math;

import 'facteur_de_pente_minetti.dart';
import 'profil_du_terrain.dart';

/// LES PARAMETRES DE LA LOI — ce qui est MESURE n'est pas ici, ce qui est
/// ASSUME l'est (tache 858).
///
/// TOUT CE QUI EST REGLABLE DANS L'INDICE TIENT DANS CETTE CLASSE, et c'est
/// voulu : la part non mesuree de l'indice doit se voir d'un coup d'oeil, se
/// chiffrer, et pouvoir etre ETEINTE. Le socle, lui, n'a aucun parametre : il
/// est l'integrale du cout mesure par Minetti sur le profil
/// ([FacteurDePenteMinetti]).
class LoiDeLIndice {
  /// Construit une loi. Les valeurs par defaut sont celles que Christophe a
  /// tranchees le 18/10/2026 ; [LoiDeLIndice.retenue] les porte.
  const LoiDeLIndice({
    this.beta = 1.08,
    this.deniveleDeReferenceM = 550.0,
    this.repitQuiCoupeUneMonteeMinutes = 15.0,
    this.allureSurTerrainReposantKmH = 4.0,
    this.secondesParMetreDeDescente = 5.0,
  });

  /// LA LOI RETENUE : les quatre arbitrages du 18/10/2026, avec l'exposant
  /// mesure du 19/10 (tache 860).
  static const LoiDeLIndice retenue = LoiDeLIndice();

  /// LA LOI SANS AUCUNE PART ASSUMEE : l'indice entierement mesure.
  ///
  /// A beta = 1 la majoration de continuite est IDENTIQUEMENT NULLE, donc
  /// l'indice se reduit a son socle Minetti. Elle existe pour qu'on puisse
  /// toujours repondre a la question « et sans la part inventee, ca donne
  /// quoi ? » — et un test prouve que la reponse est exactement le socle, sur
  /// le GR20 entier comme sur une montee isolee.
  static const LoiDeLIndice entierementMesuree = LoiDeLIndice(beta: 1.0);

  /// L'EXPOSANT DE LA MAJORATION DE CONTINUITE : 1,08. C'EST LA SEULE PART
  /// ASSUMEE DE L'INDICE, ET ELLE EST DESORMAIS ADOSSEE A UNE MESURE PUBLIEE.
  ///
  /// IL VALAIT 1,25 JUSQU'AU 19/10/2026, ET CE 1,25 N'AVAIT AUCUNE FONDATION
  /// PUBLIEE. Il avait ete choisi pour produire « franchement plus que le
  /// double », ce que Christophe demandait, et c'est tout ce qu'on pouvait en
  /// dire. Athena est rentree avec la seule mesure solide qui existe sur la
  /// super-linearite d'un effort d'endurance :
  ///
  ///   - RIEGEL (1977, et sa litterature de reprise) : l'exposant de fatigue
  ///     vaut 1,06 pour l'elite et 1,08 a 1,10 pour le coureur RECREATIF.
  ///     1,08 est la borne basse du recreatif, donc le choix le plus prudent
  ///     du domaine le plus proche de notre marcheur.
  ///   - DRAKE, FINKE et FERGUSON (2023, European Journal of Applied
  ///     Physiology) : ils fondent la FORME en loi de puissance, c'est-a-dire
  ///     exactement la forme `(D+/D_ref)^(beta-1)` employee ici.
  ///
  /// LA RESERVE, ET ELLE EST D'ATHENA ELLE-MEME : LES EXPOSANTS PUBLIES PORTENT
  /// SUR LA DUREE D'UN EFFORT ENTIER, PAS SUR LA HAUTEUR D'UNE COTE. On
  /// applique donc une loi mesuree sur un objet (le temps d'une course) a un
  /// autre objet (le denivele d'une montee continue), PAR ANALOGIE. Cette
  /// analogie n'est pas mesuree, elle est assumee, et c'est la derniere chose
  /// non mesuree qui reste dans l'indice. La forme est fondee ; la
  /// transposition d'objet ne l'est pas.
  ///
  /// CE QUE LE CHANGEMENT COUTE, MESURE SUR LES SEIZE ETAPES DU GR20 : le total
  /// passe de 397,37 a 394,30, soit -0,8 %, avec un Spearman de 0,9912 et six
  /// changements de rang d'un cran. CHANGER L'EXPOSANT EST PRESQUE UN
  /// NON-EVENEMENT sur le classement. Ce qu'il change vraiment, c'est la PART
  /// ASSUMEE : de 9,73 % a 3,28 % de l'indice en brut (somme des majorations en
  /// valeur absolue sur somme des indices), et de 0,53 % a 0,25 % en net.
  ///
  /// QUI Y PERD : l'etape 1 du GR20, celle qui a la plus grosse montee continue
  /// du sentier (1 453 m d'un seul tenant). Son indice tombe de 50,03 a 42,58
  /// et son percentile dans le corpus mondial de 83,0 a 77,4 % — c'est elle qui
  /// avait le plus a perdre d'une courbe moins raide. Sa note d'effort, elle,
  /// MONTE, parce que la jauge a change de question ([NoteDEffort]) : un
  /// probleme de REPERE ne se corrige pas par un changement de MAGNITUDE.
  final double beta;

  /// LA TAILLE DE MONTEE OU LA MAJORATION EST NULLE : 550 m.
  ///
  /// En dessous elle fait une REMISE, au-dessus un SURCOUT. Elle est calee pour
  /// que le total de l'itineraire de reference soit le meme qu'a beta = 1 (la
  /// valeur exacte est 536 m, arrondie au demi-cent) : LA MAJORATION DEPLACE DE
  /// LA SEVERITE ENTRE JOURNEES, ELLE N'EN FABRIQUE PAS. C'est ce qui empeche
  /// un facteur sans source de gonfler l'echelle entiere.
  final double deniveleDeReferenceM;

  /// LE REPIT QUI COUPE UNE MONTEE : UN QUART D'HEURE DE TERRAIN REPOSANT.
  ///
  /// DECISION DE CHRISTOPHE, 18/10/2026 19:36 (memoire #102252), en reponse a sa
  /// propre question du 15:33 : « 500 metres de plat ou de descente entre deux
  /// pentes de 700 metres, on considere ca comme une pente de 1,4 km ? ». La
  /// reponse mesuree est OUI : 500 m de plat font moins de huit minutes, donc
  /// moins d'un quart d'heure, donc UNE montee de 1 400 m.
  ///
  /// POURQUOI QUINZE ET PAS DIX NI TRENTE, mesure sur le GR20 : a dix minutes
  /// le sentier compte 48 montees continues dont la plus grosse fait 1 378 m ;
  /// a quinze, 35 montees et 2 060 m ; a trente, 19 montees et une montee de
  /// 2 091 m qui n'existe comme epreuve unique pour personne. Quinze est le
  /// plus petit seuil qui coud le cas de Christophe avec de la marge, et le
  /// plus grand qui ne fabrique pas de montee de plus de deux kilometres de
  /// denivele.
  final double repitQuiCoupeUneMonteeMinutes;

  /// L'ALLURE QUI CONVERTIT LE REPIT EN TERRAIN : 4 km/h.
  ///
  /// CE N'EST PAS UN TEMPS DE MARCHE ET CA NE DOIT JAMAIS S'AFFICHER COMME TEL.
  /// Le seul temps de marche de ce depot est celui de
  /// `core/models/stage_duration.dart` (source unique depuis la tache 839), et
  /// c'est lui qui annonce les heures d'une journee. Les deux constantes
  /// ci-dessous ne servent QU'A UNE CHOSE : decider ou une montee s'arrete,
  /// puisque le seuil que Christophe a pose est un TEMPS de repit et que le
  /// terrain, lui, se mesure en metres. L'allure a plat est la meme que celle
  /// du modele du depot, pour ne pas introduire un second chiffre.
  final double allureSurTerrainReposantKmH;

  /// CE QUE COUTE UN METRE DE DESCENTE DANS L'HORLOGE DU REPIT : 5 secondes.
  ///
  /// POURQUOI PLUS QUE LA PENALITE DU MODELE DE DUREE (1,67 s/m). Cette
  /// constante est CALEE, et sur une seule chose : reproduire la carte des
  /// montees continues du bareme de la tache 857, celui que Christophe a lu.
  /// Elle y reussit — 2 060 m pour la plus grosse montee du GR20, et quatorze
  /// des seize etapes retrouvees au centieme de point. LE REGLAGE EST PLAT
  /// ENTRE 4,5 ET 6,5 SECONDES PAR METRE : tout ce segment rend exactement les
  /// memes montees, donc le chiffre exact ne porte aucune information et ne
  /// merite aucune defense. Ce qu'il dit, en clair : descendre mille metres
  /// repose moins longtemps que marcher la meme duree a plat.
  final double secondesParMetreDeDescente;

  /// LE FACTEUR DE MAJORATION D'UNE MONTEE DE [deniveleM] metres.
  ///
  /// `(D+ / D_ref) ^ (beta - 1) - 1`, donc EXACTEMENT ZERO quand beta vaut 1,
  /// quelle que soit la montee et quel que soit [deniveleDeReferenceM]. C'est
  /// la forme qui rend la part assumee extinguible par un seul reglage.
  double facteurDeContinuite(double deniveleM) =>
      math.pow(deniveleM / deniveleDeReferenceM, beta - 1).toDouble() - 1.0;

  /// LES MINUTES DE REPIT QU'UN MORCEAU DE TERRAIN REPOSANT DONNE.
  ///
  /// La longueur compte a [allureSurTerrainReposantKmH], et chaque metre de
  /// descente ajoute [secondesParMetreDeDescente]. La longueur employee est
  /// celle du TRAJET, comme pour le cout : on marche la pente, pas sa
  /// projection.
  double minutesDeRepit(SegmentDeProfil segment) {
    final minutesDeLongueur =
        segment.longueurDeTrajetM / 1000.0 / allureSurTerrainReposantKmH * 60.0;
    final descenteM = segment.deniveleM < 0 ? -segment.deniveleM : 0.0;
    return minutesDeLongueur + descenteM * secondesParMetreDeDescente / 60.0;
  }

  /// CE QUE VAUT UNE MONTEE DEUX FOIS PLUS GRANDE : 2 puissance beta.
  ///
  /// A pente egale l'indice d'une montee est proportionnel a son denivele
  /// puissance [beta], donc doubler le denivele multiplie l'indice par
  /// `2^beta` — 2,11 a beta = 1,08, et exactement 2 a beta = 1. C'est ce
  /// nombre que l'ecran affiche plutot que l'exposant, qui ne se lit pas :
  /// doubler la montee coute un peu plus que le double, et c'est tout ce que
  /// la mesure publiee autorise a dire.
  double get ratioDeDoublement => math.pow(2, beta).toDouble();

  /// LA LOI EN UNE PHRASE, TELLE QU'ELLE S'AFFICHE SOUS LE RESULTAT.
  ///
  /// Elle est ICI et pas dans l'ecran : la regle affichee et la regle appliquee
  /// doivent etre le meme texte, sinon l'une derive. Un test verifie que les
  /// nombres cites sont bien les constantes de cette classe.
  String get regleAffichee =>
      'L\'indice de terrain mesure l\'ENERGIE que le chemin demande : un point '
      'vaut un kilometre de plat. Il est lu sur la trace, pente par pente, '
      'avec les couts mesures en laboratoire par Minetti (2002) — cent metres '
      'de montee coutent environ deux points, et un kilometre de descente '
      'douce en coute un demi. Une montee reste CONTINUE tant qu\'elle n\'est '
      'pas coupee par ${_nombre(repitQuiCoupeUneMonteeMinutes)} minutes de '
      'terrain reposant, et plus elle est longue plus elle est majoree : '
      '1 000 m d\'un seul tenant valent ${_nombre(ratioDeDoublement)} fois '
      '500 m, et non deux fois. C\'est la seule part de l\'indice qu\'aucune '
      'mesure ne soutient. L\'indice decrit le TERRAIN seul : '
      'ni votre sac, ni votre forme. Le temps de marche, lui, est un autre '
      'nombre et il est annonce a part.';

  /// Un nombre ecrit comme on l'ecrit en francais : virgule, pas de zero
  /// decimal inutile.
  static String _nombre(double valeur) {
    final texte = valeur == valeur.roundToDouble()
        ? valeur.toStringAsFixed(0)
        : valeur.toStringAsFixed(1);
    return texte.replaceAll('.', ',');
  }
}

/// L'INDICE DE TERRAIN D'UN MORCEAU DE SENTIER, ET CE QUI LE COMPOSE.
///
/// DEUX NOMBRES, DEUX NOMS, JAMAIS LE MEME MOT (tache 858, decision de
/// Christophe du 18/10 19:32). L'INDICE DE TERRAIN dit ce que le chemin
/// DEMANDE ; le TEMPS DE MARCHE dit combien d'heures il prend
/// (`core/models/stage_duration.dart`). Ce sont deux grandeurs differentes et
/// la confusion des deux est precisement ce que ce lot repare : le compte
/// precedent, celui de la tache 856, valait les minutes divisees par 13,64 dans
/// chacune de ses six lignes — son indice ETAIT sa duree, a un facteur pres.
/// Ici, deux journees de meme duree n'ont plus le meme indice : sur le GR20
/// l'indice par heure va de 2,15 a 7,98, soit un rapport de 3,7.
///
/// AUCUN MOT DE NIVEAU N'EST PRODUIT ICI, ET C'EST UNE CONSIGNE, PAS UN OUBLI.
/// Christophe, 18/10/2026 19:32 : « On tranchera les niveaux apres ». L'indice
/// sort en NOMBRE. Aucune bande facile / moyen / difficile / tres difficile
/// n'est posee tant qu'il n'a pas donne ses seuils, parce qu'un seuil invente
/// se recopie ensuite partout comme s'il avait ete mesure.
///
/// LA SECONDE COUCHE N'EST PAS ICI, ET SA PLACE EST LAISSEE PROPRE. Le poids du
/// sac, le surpoids de la personne et l'etat de ses genoux forment une seconde
/// couche qui MULTIPLIERA cet indice (Christophe, 18/10 19:38 et 19:40,
/// memoires #102253 et #102254). Elle n'est PAS codee : rien dans ce fichier ni
/// dans [LoiDeLIndice] ne lit une propriete du marcheur, et la signature de
/// [calculer] ne prend que du terrain. Le jour ou elle arrivera, elle
/// multipliera [indice] au-dehors, et l'indice de terrain restera lisible tel
/// quel. UN INDICE QUI INTEGRERAIT LE SAC NE SERAIT PLUS COMPARABLE ENTRE
/// CLIENTS — c'est exactement ce qui rend l'IBP inutilisable d'un randonneur a
/// l'autre.
class IndiceDuTerrain {
  /// Construit un resultat d'indice. On passe par [calculer].
  const IndiceDuTerrain({
    required this.socleMesure,
    required this.majorationDeContinuite,
    required this.monteesContinues,
    required this.plusGrosseMonteeM,
    required this.deniveleM,
    required this.descenteM,
    required this.kmDeTrajet,
    required this.kmDeCarte,
  });

  /// Un terrain vide : aucun morceau, aucun indice.
  static const IndiceDuTerrain aucun = IndiceDuTerrain(
    socleMesure: 0.0,
    majorationDeContinuite: 0.0,
    monteesContinues: 0,
    plusGrosseMonteeM: 0.0,
    deniveleM: 0.0,
    descenteM: 0.0,
    kmDeTrajet: 0.0,
    kmDeCarte: 0.0,
  );

  /// LE SOCLE MESURE, en points : l'integrale du cout de Minetti sur le profil.
  ///
  /// EXACTEMENT ADDITIF, PARTOUT. Couper le terrain n'importe ou et additionner
  /// les morceaux rend le meme nombre, a la precision de la machine pres (160
  /// coupures essayees, pire ecart 3 x 10^-14 point). C'est ce qui permet de
  /// chiffrer n'importe quel decoupage sans recalculer le sentier.
  final double socleMesure;

  /// LA MAJORATION DE CONTINUITE, en points : la seule part assumee.
  ///
  /// Positive quand les montees du morceau sont plus grosses que
  /// [LoiDeLIndice.deniveleDeReferenceM], NEGATIVE quand elles sont plus
  /// petites — une journee qui monte par petits paquets paie moins qu'une
  /// journee qui monte d'un trait le meme denivele.
  final double majorationDeContinuite;

  /// Combien de MONTEES CONTINUES le morceau contient.
  ///
  /// Une montee reste continue tant qu'elle n'est pas interrompue par
  /// [LoiDeLIndice.repitQuiCoupeUneMonteeMinutes] de terrain reposant.
  final int monteesContinues;

  /// Le denivele de la PLUS GROSSE montee continue du morceau, en metres.
  ///
  /// C'est l'epreuve la plus parlante d'une journee, et elle ne se lit pas dans
  /// le D+ total : l'etape 6 du GR20 monte 767 m en SEPT montees dont la plus
  /// grosse fait 606 m, la premiere etape monte 1 454 m D'UN SEUL TENANT.
  final double plusGrosseMonteeM;

  /// Denivele positif du morceau, en metres, lu sur le profil.
  final double deniveleM;

  /// Denivele negatif du morceau, en metres, compte POSITIVEMENT.
  final double descenteM;

  /// Longueur reellement parcourue, en kilometres (la pente, pas sa
  /// projection).
  ///
  /// C'est sur elle que le socle energetique s'integre : on depense l'energie
  /// du chemin qu'on fait, pas de son ombre sur la carte.
  final double kmDeTrajet;

  /// Longueur PROJETEE SUR LA CARTE, en kilometres.
  ///
  /// Elle existe pour la RAIDEUR et pour elle seule : une pente moyenne est
  /// une denivelee sur une distance HORIZONTALE, et c'est la seule convention
  /// qui fasse tomber les bandes publiees de l'IMBA sur des notes rondes
  /// (voir `NoteDeRaideur.metresParKm`). C'est aussi le kilometrage que
  /// l'application affiche par ailleurs. Sur le GR20 entier elle vaut
  /// 183,4 km contre 185,8 de trajet, soit 1,3 % de moins.
  final double kmDeCarte;

  /// L'INDICE DE TERRAIN : le socle mesure plus la majoration assumee.
  ///
  /// Un point vaut un kilometre de plat. La premiere journee du GR20 —
  /// Calenzana vers l'Ortu di u Piobbu, 11,3 km et 1 454 m de montee d'un seul
  /// tenant — vaut 50,0 ; la meme marchee a l'envers vaut 10,5.
  double get indice => socleMesure + majorationDeContinuite;

  /// LA PART ASSUMEE DE CET INDICE, en fraction de l'indice.
  ///
  /// A afficher partout ou l'indice est explique : c'est le seul chiffre qui
  /// dit au lecteur quelle confiance accorder au nombre. Zero quand l'indice
  /// est nul.
  double get partAssumee =>
      indice == 0 ? 0.0 : majorationDeContinuite.abs() / indice.abs();

  /// L'INDICE D'UN MORCEAU DE TERRAIN, mesure sur son profil.
  ///
  /// [terrain] est la suite des morceaux du morceau de sentier a peser — en
  /// pratique `ProfilDuTerrain.tranche(...)` entre deux couchages. La signature
  /// ne prend RIEN D'AUTRE que du terrain, et c'est la garde la plus simple
  /// contre le melange des deux couches.
  ///
  /// LES MONTEES SONT DETECTEES DANS LE MORCEAU, PAS SUR LE SENTIER ENTIER, et
  /// c'est ce qui donne a l'indice sa propriete la plus utile commercialement.
  /// L'additivite est EXACTE quand on coupe a la fin d'une montee (33 coupures
  /// essayees, pire ecart 0,0000 %) ; elle est SOUS-ADDITIVE quand on coupe a
  /// l'interieur d'une montee, et c'est VOULU : la premiere montee continue du
  /// GR20 va du kilometre 0 au kilometre 15,3 et cumule 2 060 m, la frontiere
  /// de l'Ortu di u Piobbu tombe dedans a 74 % de son denivele. Calenzana vers
  /// Carozzu d'un trait vaut 80,8 ; les deux journees reelles additionnees
  /// valent 70,7, soit 12,5 % de MOINS. CE DEFICIT EST L'INFORMATION : dormir a
  /// mi-pente rend le chemin reellement plus facile, et c'est la valeur d'une
  /// nuit bien posee. Sur le sentier entier, les seize journees valent 397
  /// points contre 428 d'un seul tenant : dormir seize fois rend le GR20 7 %
  /// moins dur que de le marcher d'un trait.
  ///
  /// IL EXISTE UNE FACON D'AVOIR L'ADDITIVITE PARTOUT et elle est refusee : on
  /// calculerait la carte des montees UNE FOIS sur le sentier, puis on
  /// repartirait le cout de chaque montee au prorata du denivele que la journee
  /// en prend. La somme serait exacte pour toute coupure — et elle facturerait
  /// a la journee qui s'arrete a mi-cote la severite d'une montee de 1 400 m
  /// qu'elle ne fait pas, donc elle dirait que dormir a mi-pente ne sert a
  /// rien. C'est faux, et aucune exactitude arithmetique ne vaut un chiffre qui
  /// ment.
  static IndiceDuTerrain calculer({
    required List<SegmentDeProfil> terrain,
    LoiDeLIndice loi = LoiDeLIndice.retenue,
  }) {
    if (terrain.isEmpty) return aucun;

    var socle = 0.0;
    var majoration = 0.0;
    var denivele = 0.0;
    var descente = 0.0;
    var kmDeTrajet = 0.0;
    var kmDeCarte = 0.0;
    var montees = 0;
    var plusGrosseMontee = 0.0;

    // LA MONTEE EN COURS : son energie MONTANTE (celle que la majoration
    // majore) et son denivele. La majoration ne porte que sur l'energie
    // depensee EN MONTANT : c'est la fatigue d'une longue montee qu'elle
    // represente, pas celle du plat qui la precede.
    var energieMontante = 0.0;
    var deniveleDeLaMontee = 0.0;
    var repitMinutes = 0.0;

    void fermerLaMontee() {
      if (deniveleDeLaMontee > 0) {
        majoration +=
            energieMontante * loi.facteurDeContinuite(deniveleDeLaMontee);
        montees++;
        if (deniveleDeLaMontee > plusGrosseMontee) {
          plusGrosseMontee = deniveleDeLaMontee;
        }
      }
      energieMontante = 0.0;
      deniveleDeLaMontee = 0.0;
      repitMinutes = 0.0;
    }

    for (final segment in terrain) {
      final pente = segment.pente;
      final kmDuSegment = segment.longueurDeTrajetM / 1000.0;
      final points =
          FacteurDePenteMinetti.pointsParKmDeTrajet(pente) * kmDuSegment;
      socle += points;
      kmDeTrajet += kmDuSegment;
      kmDeCarte += segment.longueurM / 1000.0;

      if (segment.monte) {
        denivele += segment.deniveleM;
        // LA MONTEE REPREND : le compteur de repit repart de zero. Un morceau
        // qui monte, meme de trois metres, n'est pas du repos.
        repitMinutes = 0.0;
        energieMontante += points;
        deniveleDeLaMontee += segment.deniveleM;
        continue;
      }

      descente -= segment.deniveleM;
      // LA DESCENTE RAIDE NE DONNE AUCUN REPIT, et ce n'est pas une opinion :
      // au-dela de 24,3 % elle coute PLUS qu'un kilometre de plat
      // (FacteurDePenteMinetti.penteOuLaDescenteCouteLePlat, lu sur la courbe).
      // Le mandat de la 857 disait la descente neutre ; la mesure dit mieux, et
      // c'est elle qui tranche.
      if (!FacteurDePenteMinetti.terrainReposant(pente)) continue;
      repitMinutes += loi.minutesDeRepit(segment);
      if (repitMinutes >= loi.repitQuiCoupeUneMonteeMinutes) fermerLaMontee();
    }
    fermerLaMontee();

    return IndiceDuTerrain(
      socleMesure: socle,
      majorationDeContinuite: majoration,
      monteesContinues: montees,
      plusGrosseMonteeM: plusGrosseMontee,
      deniveleM: denivele,
      descenteM: descente,
      kmDeTrajet: kmDeTrajet,
      kmDeCarte: kmDeCarte,
    );
  }
}
