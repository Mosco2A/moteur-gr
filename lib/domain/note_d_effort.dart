/// LA NOTE D'EFFORT D'UNE JOURNEE : sa place par rapport aux SEUILS PUBLIES
/// du bareme francais de randonnee, et non plus parmi les etapes d'un corpus.
library;

import 'niveau_des_icones.dart';

/// LA JAUGE D'EFFORT, FIGEE LE 20/10/2026 (tache 861).
///
/// POURQUOI ELLE A CHANGE, ET C'EST LE COEUR DU LOT. La jauge de la 860 etait
/// calee sur les DECILES d'un corpus de 106 etapes officielles relevees par
/// nous. Elle marchait, mais elle avait deux defauts qu'aucun reglage ne
/// corrigeait : le corpus CALIBRAIT l'echelle, donc toute l'echelle dependait
/// de notre releve ; et ses paliers etaient tres inegaux — le plus raide
/// depensait 19,5 fois plus de note par kilometre de plat que le plus plat,
/// ce qui ecrasait toute la resolution en bas.
///
/// LA JAUGE SE CALE MAINTENANT SUR DES SEUILS PUBLIES. Les quatre premiers
/// reperes sont les frontieres du bareme francais commun de randonnee
/// (comites departementaux, Randonner Malin, Decathlon, cdfpi.fr), relevees
/// le [dateDuCalage]. Ce ne sont pas nos chiffres : ce sont ceux du metier.
///
/// LE CONTROLE CROISE QUI N'ETAIT PAS CHERCHE, et c'est la meilleure
/// validation que l'indice ait recue. AllTrails place sa frontiere au milieu
/// de son echelle a 11 km et 450 m de montee, ce qui donne un indice de
/// 17,80 ; le bareme francais place la sienne a 12 km et 450 m, ce qui donne
/// 18,80. DEUX SOURCES INDEPENDANTES, DEUX PAYS, CINQ POUR CENT D'ECART sur
/// la meme frontiere. Personne n'avait prevu ce recoupement.
///
/// LES DEUX GAINS, MESURES. Le rapport du palier le plus raide au plus plat
/// tombe a 5,3 contre 19,5 pour la jauge sur les deciles : les pentes des
/// cinq paliers sont 0,4603 / 0,3956 / 0,3520 / 0,3420 / 0,0877 point de note
/// par kilometre de plat, et les QUATRE PREMIERES SONT PRESQUE EGALES. Le bas
/// de l'echelle depense 0,46 point la ou il depensait 0,16 : le probleme de
/// resolution en bas est regle. Et le corpus NE SERT PLUS A CALIBRER — il ne
/// sert plus qu'a illustrer, donc la fragilite qu'on redoutait disparait.
///
/// LE VINGT RESTE L'ANCRE DE CHRISTOPHE, ET C'EST UNE DECISION ASSUMEE. Le
/// dernier seuil publie est celui du bareme francais a 25 km et 1 000 m de
/// montee, soit notre note 16. AU-DELA, AUCUN NOMBRE PUBLIE N'EXISTE : la
/// derniere bande du bareme est OUVERTE, comme celle de toutes les methodes
/// du monde (MIDE, Komoot, AllTrails, FFRandonnee). Faire dire au vingt
/// « au-dela de tout seuil publie » ne supprimerait pas le chiffre assume, il
/// faudrait quand meme un nombre pour interpoler entre 16 et 20 : cela le
/// CACHERAIT. Le vingt reste donc la plus dure etape officielle connue
/// ([etapeDuVingt]), et ce qui change est sa PORTEE : l'ancre ne gouverne plus
/// que LE DERNIER PALIER, soit vingt pour cent de l'echelle, contre cent pour
/// cent dans la 860. Les seize premiers points viennent de seuils publies.
///
/// CE QU'ON SAIT QUI CLOCHE ENCORE. L'axe effort reste TASSE EN HAUT : sur une
/// semaine de GR20 il ne porte que 1,65 point d'etendue, consequence directe
/// du vingt pose si loin. Ce n'est pas repare ici, c'est mesure et dit — et
/// c'est precisement pour cela que la raideur est un SECOND AXE et pas une
/// correction de celui-ci : elle porte dix points d'etendue sur la meme
/// semaine.
abstract final class NoteDEffort {
  /// La date du releve des seuils publies. Elle fait partie de la loi.
  static const String dateDuCalage = '20/10/2026';

  /// La source des quatre premiers paliers, pour que la note se raconte.
  static const String sourceDesSeuils =
      'Bareme francais commun de randonnee (comites departementaux, '
      'Randonner Malin, Decathlon, cdfpi.fr)';

  /// Le nom de l'etape qui vaut VINGT : le seul repere qui depende de nous.
  static const String etapeDuVingt =
      'Griesalp - Hohturli - Kandersteg (Via Alpina 1, Suisse)';

  /// L'indice du seuil publie « 6 km et 200 m de montee » : note 4.
  static const double indiceDe6km200m = 8.69;

  /// L'indice du seuil publie « 12 km et 450 m de montee » : note 8.
  ///
  /// C'est la frontiere sur laquelle AllTrails nous recoupe a 5 % pres.
  static const double indiceDe12km450m = 18.80;

  /// L'indice du seuil publie « 18 km et 750 m de montee » : note 12.
  static const double indiceDe18km750m = 30.16;

  /// L'indice du DERNIER seuil publie, « 25 km et 1 000 m » : note 16.
  ///
  /// Au-dela, le bareme ne dit plus rien : sa bande est ouverte.
  static const double indiceDuDernierSeuilPublie = 41.86;

  /// L'indice qui vaut VINGT — l'ancre de Christophe, dernier palier.
  static const double indiceDuVingt = 87.49;

  /// La note la plus haute : au-dessus, c'est elle.
  static const double noteMaximale = 20.0;

  /// L'indice d'AllTrails pour sa frontiere mediane, 11 km et 450 m.
  ///
  /// Gardee dans la loi parce qu'elle est la PREUVE du recoupement : deux
  /// pays, deux methodes, 17,80 contre 18,80 pour la meme frontiere.
  static const double indiceDeLaFrontiereAllTrails = 17.80;

  /// LES CINQ PALIERS DE LA JAUGE — (indice, note), interpolation LINEAIRE
  /// entre deux paliers consecutifs.
  ///
  /// Les quatre premiers sont des SEUILS PUBLIES ; seul le dernier depend de
  /// nous. Strictement croissante sur tout son domaine.
  static const List<(double, double)> paliers = <(double, double)>[
    (0.0, 0.0),
    (indiceDe6km200m, 4.0),
    (indiceDe12km450m, 8.0),
    (indiceDe18km750m, 12.0),
    (indiceDuDernierSeuilPublie, 16.0),
    (indiceDuVingt, noteMaximale),
  ];

  /// LA NOTE D'EFFORT D'UN INDICE DE TERRAIN.
  ///
  /// ELLE NE PREND QUE L'INDICE. Aucun contexte, aucun sentier, aucun
  /// catalogue, aucune date d'execution : deux journees de meme indice ont la
  /// meme note d'effort pour toujours.
  static double pourIndice(double indice) {
    if (indice <= 0) return 0.0;
    if (indice >= indiceDuVingt) return noteMaximale;
    var (basIndice, basNote) = paliers.first;
    for (final (hautIndice, hautNote) in paliers.skip(1)) {
      if (indice <= hautIndice) {
        final part = (indice - basIndice) / (hautIndice - basIndice);
        return basNote + (hautNote - basNote) * part;
      }
      basIndice = hautIndice;
      basNote = hautNote;
    }
    return noteMaximale;
  }

  /// VRAI quand la note est ECRETEE : la journee est plus dure que la plus
  /// dure etape officielle connue.
  ///
  /// Une journee qui groupe plusieurs etapes depasse MECANIQUEMENT la plus
  /// dure etape seule du monde. Ce n'est pas une anomalie, c'est ce que fait
  /// un marcheur qui groupe — mais il faut le dire, parce qu'un vingt plafond
  /// ne raconte pas la meme chose qu'un vingt qui tombe pile.
  static bool estEcretee(double indice) => indice > indiceDuVingt;

  /// L'INDICE QU'IL FAUT POUR ATTEINDRE UNE NOTE — la jauge lue a l'envers.
  ///
  /// Sert a garder la note explicable (« 16 sur 20, c'est le seuil publie de
  /// 25 km et 1 000 m de montee »). Hors domaine, elle rend les bornes.
  static double indicePourNote(double note) {
    if (note <= 0) return 0.0;
    if (note >= noteMaximale) return indiceDuVingt;
    var (basIndice, basNote) = paliers.first;
    for (final (hautIndice, hautNote) in paliers.skip(1)) {
      if (note <= hautNote) {
        final part = (note - basNote) / (hautNote - basNote);
        return basIndice + (hautIndice - basIndice) * part;
      }
      basIndice = hautIndice;
      basNote = hautNote;
    }
    return indiceDuVingt;
  }

  /// LES QUATRE FRONTIERES DE LA RANGEE D'ICONES — les quatre seuils publies
  /// du bareme francais, dans l'ordre.
  ///
  /// CE SONT LES MEMES CONSTANTES QUE LA NOTE : les quatre frontieres tombent
  /// donc sur les notes 4, 8, 12 et 16 pile, ce qu'un test verifie. Une icone
  /// ne peut pas contredire la note posee a cote d'elle.
  static const List<double> frontieresDesIcones = <double>[
    indiceDe6km200m,
    indiceDe12km450m,
    indiceDe18km750m,
    indiceDuDernierSeuilPublie,
  ];

  /// LE NIVEAU DE LA RANGEE DE CHAUSSURES, pour un indice de terrain.
  ///
  /// UNE ICONE AU MINIMUM, ET C'EST LA SEULE ASYMETRIE AVEC L'AXE RAIDEUR.
  /// Elle est mesuree, pas choisie : sur les 108 etapes officielles relevees,
  /// AUCUNE ne tombe sous la premiere frontiere (note 4), parce qu'une etape
  /// publiee EST une journee de marche et que personne ne publie sept
  /// kilometres. La bande basse de cet axe est donc pratiquement VIDE dans la
  /// nature — une seule des seize etapes du GR20 y tombe, et aucune a
  /// l'envers.
  ///
  /// CONSEQUENCE : une rangee d'effort VIDE serait lue comme une donnee
  /// manquante et jamais comme « aucun effort », parce que l'effort nul
  /// n'existe pas sur un sentier. La montagne, elle, peut legitimement
  /// disparaitre : une etape vraiment plate existe, et sept des seize en sont.
  static NiveauDIcone niveauDIcone(double indice) {
    var compte = 0;
    for (final frontiere in frontieresDesIcones) {
      if (indice >= frontiere) compte++;
    }
    return NiveauDIcone.pourNombre(compte < 1 ? 1 : compte);
  }

  /// CE QUE LE NIVEAU DIT, EN MOTS ET SANS AUCUN MOT DE NIVEAU.
  ///
  /// Pour le lecteur d'ecran. Elle cite la GEOMETRIE du seuil publie plutot
  /// qu'un adjectif, parce que c'est elle qui est sourcee.
  static String libelleDuNiveau(double indice) {
    final niveau = niveauDIcone(indice);
    switch (niveau) {
      case NiveauDIcone.aucun:
      case NiveauDIcone.une:
        return 'sous le seuil publie de 12 km et 450 m de montee';
      case NiveauDIcone.deux:
        return 'entre les seuils publies de 12 km et 450 m, et de 18 km '
            'et 750 m';
      case NiveauDIcone.trois:
        return 'entre les seuils publies de 18 km et 750 m, et de 25 km '
            'et 1 000 m';
      case NiveauDIcone.quatre:
        return 'au-dela du dernier seuil publie, 25 km et 1 000 m de montee';
    }
  }
}
