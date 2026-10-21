/// LA NOTE DE RAIDEUR D'UNE JOURNEE : sa pente moyenne, graduee sur les
/// bandes publiees de l'IMBA.
library;

import 'niveau_des_icones.dart';

/// LA JAUGE DE RAIDEUR, FIGEE LE 20/10/2026 (tache 861), ET ELLE TIENT EN UNE
/// LIGNE : raideur sur vingt = (denivele positif par kilometre) / 10, plafonnee
/// a vingt.
///
/// POURQUOI UN SECOND AXE EXISTE. On a cherche pendant deux jours une formule
/// unique qui distingue 30 km de plat de 1 400 m de montee en 11 km. La
/// recherche des bonnes pratiques a rendu un resultat qui condamnait cette
/// recherche : PERSONNE AU MONDE NE RESOUT CA DANS UN CHIFFRE UNIQUE. Le MIDE
/// espagnol affiche quatre axes, la FFRandonnee trois, Komoot deux, le SAC et
/// le CAI cotent la technique SEPAREMENT de l'effort. Le seul chiffre unique
/// qui internalise la concentration est l'IBP, et sa formule n'est pas
/// publique. Notre probleme etait un vrai probleme du metier, et la solution
/// du metier est DE NE PAS COMBINER.
///
/// D'OU VIENT LE DIVISEUR DIX, ET IL N'EST PAS CHOISI. L'IMBA (International
/// Mountain Bicycling Association) publie quatre bandes de PENTE MOYENNE pour
/// classer un sentier : 5 % ou moins, 10 % ou moins, 15 % ou moins, 20 % et
/// plus — soit [vertM], [bleuM], [noirM] et [doubleNoirM] metres par
/// kilometre. Diviser par dix fait tomber ces quatre bandes EXACTEMENT sur
/// 5, 10, 15 et 20 sur vingt. Le dix tombe des bandes publiees. Sources :
/// parks.act.gov.au (reprise officielle du systeme IMBA), scouting.org
/// Mountain Biking Design Guideline.
///
/// LA RESERVE D'ATHENA, ET ELLE EST POSEE ICI EN TOUTES LETTRES PARCE QU'ELLE
/// EST IMPORTANTE : CES SEUILS VIENNENT DU VTT, PAS DE LA RANDONNEE. Ils ne
/// sont pas presentes comme une mesure de la difficulte a pied. Ce qu'ils
/// donnent est une GRADUATION DE LA PENTE MOYENNE, et la pente moyenne est la
/// meme grandeur physique quel que soit l'engin — mais ce n'est pas une source
/// randonnee, et aucune federation de randonnee n'en publie. La FFRandonnee,
/// le MIDE, le SAC, le CAI et Komoot n'ont pas de bareme de pente moyenne :
/// leurs axes techniques sont qualitatifs (obstacles, exposition, usage des
/// mains) et non quantifies en pourcentage.
///
/// UN SEUL INDICE CONVERGENT COTE RANDONNEE, faible mais reel : les sources
/// francaises (table-marmottes, besoindaventure, montagnetrekking) disent
/// qu'une pente jusqu'a 10 a 15 % ne pose pas de probleme majeur a pied, ce
/// qui tombe exactement sur la frontiere [bleuM] / [noirM] de l'IMBA.
///
/// L'AVANTAGE DECISIF SUR UN PERCENTILE DE CORPUS : l'ancrage est ABSOLU. La
/// raideur d'une journee ne dependra JAMAIS de notre releve, et elle est
/// transportable a n'importe quel sentier du monde sans rien refiger. Un
/// percentile sur notre corpus donnerait des notes plus hautes et plus
/// flatteuses — Calenzana sortirait a 18,33 au lieu de 12,81 — au prix de
/// redevenir dependant du corpus, exactement ce qu'on vient de supprimer sur
/// l'axe effort.
///
/// LA RESERVE QUE CET AXE PORTE LUI-MEME : LA PENTE MOYENNE NE VOIT PAS LES
/// MURS. Elle melange la montee et le plat, donc une etape de 20 km dont 5
/// sont un mur et 15 un faux plat sort au meme endroit qu'une etape de 20 km
/// qui monte regulierement. Cet axe dit « ca monte beaucoup pour la distance »,
/// il ne dit pas « il y a un mur dedans ». Pour dire le mur il faudrait un
/// troisieme axe sur la plus grosse montee continue — ce lot ne le fait pas,
/// et c'est pour cela que la plus grosse montee continue reste affichee A COTE
/// des notes comme un FAIT.
///
/// ET UNE SECONDE RESERVE, D'ATHENA AUSSI : une note sur vingt sur la raideur
/// suggere une precision au dixieme que la grandeur n'a pas. C'est pour cela
/// que le chiffre brut en metres par kilometre est affiche A COTE de la note,
/// et pas a la place. Les deux ensemble, jamais l'un sans l'autre.
abstract final class NoteDeRaideur {
  /// La date du releve des bandes publiees. Elle fait partie de la loi.
  static const String dateDuCalage = '20/10/2026';

  /// La source des quatre bandes, pour que la note se raconte.
  static const String sourceDesBandes =
      'Bandes de pente moyenne de l IMBA, International Mountain Bicycling '
      'Association (parks.act.gov.au, scouting.org) - SEUILS VENUS DU VTT, '
      'PAS DE LA RANDONNEE';

  /// La bande « vert » de l'IMBA : 5 % de pente moyenne, soit 50 m/km.
  static const double vertM = 50.0;

  /// La bande « bleu » de l'IMBA : 10 % de pente moyenne, soit 100 m/km.
  ///
  /// C'est la frontiere sur laquelle les sources francaises de randonnee
  /// convergent (« jusqu'a 10 a 15 % pas de probleme majeur a pied »).
  static const double bleuM = 100.0;

  /// La bande « noir » de l'IMBA : 15 % de pente moyenne, soit 150 m/km.
  static const double noirM = 150.0;

  /// La bande « double noir » de l'IMBA : 20 % de pente moyenne, 200 m/km.
  ///
  /// C'est le PLAFOND de l'axe : au-dela, la note est vingt.
  static const double doubleNoirM = 200.0;

  /// Combien de metres par kilometre valent UN point de note.
  ///
  /// Dix. Il n'est pas choisi : il fait tomber les quatre bandes publiees sur
  /// 5, 10, 15 et 20 sur vingt.
  static const double metresParKmParPointDeNote = 10.0;

  /// La note la plus haute : au-dessus, c'est elle.
  static const double noteMaximale = 20.0;

  /// LE DENIVELE POSITIF PAR KILOMETRE — le chiffre brut, celui qu'on affiche
  /// a cote de la note.
  ///
  /// LE KILOMETRAGE EST CELUI DE LA CARTE, PAS LA LONGUEUR DE TRAJET, et ce
  /// n'est pas un detail : une pente moyenne est une denivelee sur une
  /// distance HORIZONTALE. Mesuree sur la longueur inclinee, une vraie pente
  /// de 20 % sort a 196 m/km au lieu de 200 et les quatre bandes de l'IMBA ne
  /// tombent plus sur 5, 10, 15 et 20 mais sur 4,99, 9,95, 14,83 et 19,61 —
  /// l'ecart grandit justement la ou la pente est la plus forte. La
  /// convention horizontale est donc la seule qui rende vrai l'argument
  /// fondant le diviseur dix. C'est aussi le kilometrage que l'application
  /// affiche par ailleurs, donc le seul avec lequel le client peut refaire la
  /// division lui-meme.
  static double metresParKm({required double deniveleM, required double km}) {
    if (km <= 0) return 0.0;
    return deniveleM / km;
  }

  /// LA NOTE DE RAIDEUR D'UNE PENTE MOYENNE, en metres par kilometre.
  static double pourMetresParKm(double parKm) {
    if (parKm <= 0) return 0.0;
    final note = parKm / metresParKmParPointDeNote;
    return note > noteMaximale ? noteMaximale : note;
  }

  /// LA NOTE DE RAIDEUR D'UNE JOURNEE, depuis sa montee et son kilometrage.
  static double pourJournee({required double deniveleM, required double km}) =>
      pourMetresParKm(metresParKm(deniveleM: deniveleM, km: km));

  /// VRAI quand la note est ECRETEE : la journee monte plus raide que la
  /// bande la plus raide que l'IMBA publie.
  ///
  /// Une seule etape des 108 du corpus d'illustration plafonne — Kita-dake,
  /// dans les Alpes japonaises, a 251,5 m/km. La mediane du corpus est a
  /// 35 m/km, soit une raideur de 3,5 : LES ETAPES PUBLIEES NE SONT PAS
  /// RAIDES, en moyenne. C'est vrai et c'est informatif.
  static bool estEcretee(double parKm) => parKm > doubleNoirM;

  /// LES QUATRE FRONTIERES DE LA RANGEE D'ICONES — les quatre bandes
  /// publiees de l'IMBA, dans l'ordre.
  ///
  /// CE SONT LES MEMES CONSTANTES QUE LA NOTE, et c'est une exigence : une
  /// icone ne doit jamais pouvoir contredire la note posee a cote d'elle. Les
  /// quatre frontieres tombent donc sur les notes 5, 10, 15 et 20 pile, ce
  /// qu'un test verifie.
  static const List<double> frontieresDesIcones = <double>[
    vertM,
    bleuM,
    noirM,
    doubleNoirM,
  ];

  /// LE NIVEAU DE LA RANGEE DE MONTAGNES, pour une pente moyenne.
  ///
  /// RIEN SOUS LA PREMIERE BANDE PUBLIEE (Christophe, 21/10 08:14 : « ou alors
  /// pas d'icone montagne du tout en dessous de 50 metres »). L'IMBA ne gradue
  /// rien en dessous, donc on n'affiche rien : la PRESENCE de la montagne veut
  /// dire quelque chose par elle-meme. Et une etape VRAIMENT PLATE existe —
  /// sept des seize etapes du GR20 sont sous 50 m/km — donc l'absence porte
  /// une information vraie, pas un manque.
  static NiveauDIcone niveauDIcone(double parKm) {
    var compte = 0;
    for (final frontiere in frontieresDesIcones) {
      if (parKm >= frontiere) compte++;
    }
    return NiveauDIcone.pourNombre(compte);
  }

  /// CE QUE LE NIVEAU DIT, EN MOTS ET SANS AUCUN MOT DE NIVEAU.
  ///
  /// Destine au lecteur d'ecran, et c'est la seconde moitie de WCAG 1.4.1 : la
  /// couleur et le comptage parlent a l'oeil, cette phrase parle a la voix.
  /// Elle decrit la BANDE PUBLIEE, factuellement, parce que les mots de niveau
  /// ne sont pas tranches (18/10 : « on tranchera les niveaux apres ») et
  /// qu'un chiffre sourcé vaut mieux qu'un adjectif invente.
  static String libelleDuNiveau(double parKm) {
    final niveau = niveauDIcone(parKm);
    switch (niveau) {
      case NiveauDIcone.aucun:
        return 'moins de ${vertM.round()} m de montee par kilometre';
      case NiveauDIcone.une:
        return 'de ${vertM.round()} a ${bleuM.round()} m par kilometre';
      case NiveauDIcone.deux:
        return 'de ${bleuM.round()} a ${noirM.round()} m par kilometre';
      case NiveauDIcone.trois:
        return 'de ${noirM.round()} a ${doubleNoirM.round()} m par kilometre';
      case NiveauDIcone.quatre:
        return 'plus de ${doubleNoirM.round()} m de montee par kilometre';
    }
  }
}
