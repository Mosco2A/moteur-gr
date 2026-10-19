/// LES JOURNEES D'UN SENTIER, CHACUNE PESEE PAR SON INDICE DE TERRAIN — et
/// jamais par un mot.
library;

import 'indice_du_terrain.dart';
import 'note_sur_vingt.dart';
import 'profil_du_terrain.dart';

/// UNE JOURNEE A PESER : ses bornes SUR LA TRACE et ses mesures.
///
/// POURQUOI LES BORNES SONT INDISPENSABLES, ET C'EST LE CHANGEMENT DE FOND DE
/// CE LOT. L'indice de terrain est une integrale sur le profil : il ne se
/// deduit pas de (distance, D+, D-). Une journee est donc un COUPLE DE POINTS
/// KILOMETRIQUES sur la trace, et ses trois mesures ne servent plus qu'a
/// l'affichage. Le compte precedent — le kilometre-effort de la tache 852 — ne
/// lisait que les trois totaux, et c'est exactement pour cela qu'il cotait
/// 26,5 la journee qui grimpe 1 454 m et 21,4 celle qui les descend.
class JourneeAPeser {
  /// Une journee telle que le decoupage la produit, bornes comprises.
  const JourneeAPeser({
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
    required this.pkDebutKm,
    required this.pkFinKm,
  });

  /// Nom du lieu de depart.
  final String depart;

  /// Nom du lieu d'arrivee.
  final String arrivee;

  /// Longueur de la journee, en kilometres.
  final double km;

  /// Denivele positif de la journee, en metres.
  final int deniveleM;

  /// Denivele negatif de la journee, en metres, compte positivement.
  final int descenteM;

  /// Temps de marche de la journee, en minutes, par LE modele de temps du
  /// depot.
  ///
  /// IL NE SERT PAS A CALCULER L'INDICE, et c'est tout l'interet de ce lot :
  /// l'indice vient du terrain, le temps vient du modele de marche, et les deux
  /// nombres portent deux noms distincts a l'ecran.
  final int minutes;

  /// Point kilometrique du depart sur la trace, en kilometres.
  final double pkDebutKm;

  /// Point kilometrique de l'arrivee sur la trace, en kilometres.
  final double pkFinKm;

  /// VRAI quand cette journee peut etre pesee : des bornes qui avancent.
  ///
  /// Une journee sans bornes n'est pas une journee mal mesuree, c'est une
  /// journee dont on NE SAIT PAS ou elle passe. On ne lui invente pas d'indice.
  bool get estPesable => pkFinKm > pkDebutKm;
}

/// UNE JOURNEE PESEE : ses mesures, SON INDICE DE TERRAIN, SON TEMPS DE MARCHE.
///
/// Les trois voyagent ensemble parce que l'ecran les montre ensemble, et les
/// deux derniers portent deux noms qu'on ne doit jamais confondre.
class JourneePesee {
  /// Une journee et son indice de terrain.
  const JourneePesee({
    required this.numero,
    required this.depart,
    required this.arrivee,
    required this.km,
    required this.deniveleM,
    required this.descenteM,
    required this.minutes,
    required this.terrain,
  });

  /// Numero de la journee de MARCHE (1-indexed, les repos non comptes).
  final int numero;

  /// Nom du lieu de depart.
  final String depart;

  /// Nom du lieu d'arrivee.
  final String arrivee;

  /// Longueur de la journee, en kilometres.
  final double km;

  /// Denivele positif, en metres.
  final int deniveleM;

  /// Denivele negatif, en metres, compte positivement.
  final int descenteM;

  /// Temps de marche, en minutes (modele de temps du depot).
  final int minutes;

  /// L'indice de terrain de la journee, et ce qui le compose.
  final IndiceDuTerrain terrain;

  /// L'INDICE DE TERRAIN de la journee, en points (un point = un km de plat).
  double get indiceDuTerrain => terrain.indice;

  /// LA NOTE DE LA JOURNEE, SUR VINGT : sa place parmi les etapes
  /// officielles du monde ([NoteSurVingt], jauge figee le 19/10/2026).
  ///
  /// C'est le seul nombre NOTE de tout le produit. Un troncon et un sentier
  /// n'en ont pas, et c'est une regle, pas un oubli ([LecturesDuPlan]).
  double get noteSurVingt => NoteSurVingt.pourIndice(indiceDuTerrain);

  /// VRAI quand la note est ECRETEE a vingt, donc quand la journee est plus
  /// dure que la plus dure etape officielle connue.
  ///
  /// Une journee qui cumule plusieurs etapes y arrive mecaniquement. Les deux
  /// faits qui accompagnent la note — [plusGrosseMonteeM] et [km] — ne
  /// s'ecretent pas, eux, et c'est a ce moment-la qu'ils deviennent
  /// indispensables.
  bool get estEcretee => NoteSurVingt.estEcretee(indiceDuTerrain);

  /// PREMIER FAIT SANS ECHELLE : la plus grosse montee continue, en metres.
  ///
  /// CE N'EST PAS UNE NOTE, C'EST UN FAIT, et il dit ce que la note ne dit pas.
  /// Mesure du GR20 a huit jours : le jour 3 porte la deuxieme plus grosse
  /// montee du plan (1 162 m d'un seul tenant) et note MOINS que le jour 7, qui
  /// ne monte que 739 m — parce que le jour 7 fait 31 km. Un marcheur qui
  /// redoute les grandes montees ne lit pas la meme colonne qu'un marcheur qui
  /// redoute les longues journees.
  double get plusGrosseMonteeM => terrain.plusGrosseMonteeM;
}

/// LES QUATRE LECTURES D'UN NIVEAU AU-DESSUS DE LA JOURNEE (tache 860).
///
/// LA REGLE EST ABSOLUE : ON NE SOMME JAMAIS, ON DECRIT. Un TRONCON et un
/// SENTIER ENTIER ne portent AUCUNE note. Ils portent les quatre lectures
/// ci-dessous, prises sur leurs journees, et comparables terme a terme d'un
/// niveau a l'autre.
///
/// POURQUOI C'EST UNE REGLE ET PAS UNE PREFERENCE. Une somme de notes n'a aucun
/// sens : en rampe droite, le GR20 entier sortait a 66 ou a 35 sur vingt,
/// absurde donc inoffensif — personne n'y aurait cru. Avec une jauge qui
/// plafonne a vingt, le meme calcul sortirait 20,00 sur 20 : CREDIBLE ET
/// COMPLETEMENT FAUX. C'est pour cela que cette classe n'expose aucun total, et
/// qu'une garde de test interdit d'en fabriquer un.
///
/// ET LES LECTURES D'UN SENTIER NE SONT PAS CELLES DE SES TRONCONS MISES BOUT A
/// BOUT. Le plan par defaut vaut sept a huit jours POUR CHAQUE PRODUIT : qui
/// achete les deux chapitres marche quatorze a seize jours, donc des journees
/// plus courtes. Mesure : la journee type tombe de 12,62 a 3,71 sur vingt entre
/// le sentier entier a sept jours et ses deux chapitres a sept jours chacun,
/// soit un facteur trois et demi, et l'enchainement de journees dures passe de
/// cinq a zero. Les deux chapitres additionnes sont un produit BEAUCOUP PLUS
/// FACILE que le sentier entier : c'est une information de vente, pas une
/// fuite.
class LecturesDuPlan {
  /// Les quatre lectures d'un plan.
  const LecturesDuPlan({
    required this.nombreDeJours,
    required this.pireJournee,
    required this.journeeType,
    required this.journeesDures,
    required this.plusLongEnchainementDeJourneesDures,
  });

  /// Aucune journee : aucune lecture.
  static const LecturesDuPlan aucune = LecturesDuPlan(
    nombreDeJours: 0,
    pireJournee: 0.0,
    journeeType: 0.0,
    journeesDures: 0,
    plusLongEnchainementDeJourneesDures: 0,
  );

  /// LE NOMBRE DE JOURS, et il s'affiche LE PREMIER.
  ///
  /// C'est la seule des quatre lectures qui ne se MESURE pas : c'est le reglage
  /// du client. Elle est pourtant indispensable au sens des trois autres — sans
  /// elle, « pire journee 18,86 » ne veut rien dire.
  final int nombreDeJours;

  /// LA NOTE DE LA PIRE JOURNEE du plan, sur vingt.
  ///
  /// C'est elle qui decide si le marcheur arrive au bout, et c'est deja la
  /// regle du verdict de faisabilite (GO-61).
  final double pireJournee;

  /// LA NOTE DE LA JOURNEE TYPE du plan, sur vingt : la MOYENNE des notes.
  ///
  /// LA MOYENNE ET PAS LA MEDIANE, ET IL FAUT LE NOMMER : sur sept journees la
  /// moyenne est sensible a l'extreme, et l'ecart se mesure — sur le GR20
  /// entier a sept jours, la mediane vaut 13,62 quand la moyenne vaut 12,62,
  /// soit un point d'ecart. La moyenne est retenue parce que c'est elle qui
  /// definit la journee dure ci-dessous : avec une mediane, la moitie des
  /// journees seraient dures PAR CONSTRUCTION, et la lecture ne renseignerait
  /// plus sur rien.
  final double journeeType;

  /// Combien de journees sont DURES, c'est-a-dire au-dessus de [journeeType].
  ///
  /// LA DEFINITION EST RELATIVE AU PLAN LUI-MEME, et ce choix est assume faute
  /// de mieux : les deux seuils absolus mesures echouent. Celui cale sur la
  /// plus dure etape officielle du perimetre est DEGENERE sur les deux
  /// chapitres (l'enchainement y vaut zero dans les huit cas mesures) et il
  /// DEPEND DU SENS de marche, donc il rend les deux sens du meme produit
  /// incomparables. Celui cale sur la mediane mondiale SATURE sur le sentier
  /// entier, dont les sept ou huit journees sont alors toutes dures. Un seuil
  /// relatif au plan descend quand le plan s'allonge — c'est son defaut, assume
  /// — et il est le seul a graduer les trois produits sans jamais devenir muet.
  final int journeesDures;

  /// LE PLUS LONG ENCHAINEMENT de journees dures consecutives.
  ///
  /// C'est la lecture que Christophe a soulignee le 17/10 : « un troncon avec
  /// une journee dure n'est pas un troncon avec six journees dures d'affilee ».
  /// Six journees dures etalees sur trois semaines se marchent ; six d'affilee
  /// se subissent.
  final int plusLongEnchainementDeJourneesDures;

  /// LES QUATRE LECTURES D'UNE LISTE DE JOURNEES PESEES.
  static LecturesDuPlan desJournees(List<JourneePesee> journees) {
    if (journees.isEmpty) return aucune;
    var pire = 0.0;
    var somme = 0.0;
    for (final journee in journees) {
      final note = journee.noteSurVingt;
      if (note > pire) pire = note;
      somme += note;
    }
    final type = somme / journees.length;
    var dures = 0;
    var plusLong = 0;
    var courant = 0;
    for (final journee in journees) {
      if (journee.noteSurVingt > type) {
        dures++;
        courant++;
        if (courant > plusLong) plusLong = courant;
      } else {
        courant = 0;
      }
    }
    return LecturesDuPlan(
      nombreDeJours: journees.length,
      pireJournee: pire,
      journeeType: type,
      journeesDures: dures,
      plusLongEnchainementDeJourneesDures: plusLong,
    );
  }
}

/// LE SENTIER PESE A UNE ALLURE : ses journees, et la plus dure d'entre elles.
///
/// CE QUE CETTE CLASSE NE FAIT PLUS, ET C'EST VOULU (tache 858). Elle ne rend
/// AUCUN mot de niveau, aucune bande, aucun verdict de troncon, aucune
/// repartition par bande. Christophe, 18/10/2026 19:32 : « On tranchera les
/// niveaux apres ». Tant que ses seuils ne sont pas poses, l'ecran montre des
/// NOMBRES. Ce qui a ete retire est nommement : l'echelle a quatre bandes
/// (facile / moyen / difficile / tres difficile) et le verdict qui montait d'un
/// cran par accumulation, tous deux adosses au kilometre-effort de la tache
/// 852, qui etait FAUX et qui etait AFFICHE.
///
/// CE QUI RESTE, ET POURQUOI C'EST CELUI-LA. La PIRE JOURNEE, au sens de
/// l'indice de terrain. C'est elle qui decide si le marcheur arrive au bout, et
/// c'est deja la regle du verdict de faisabilite (GO-61) : deux ecrans qui se
/// contrediraient sur ce point n'auraient aucune chance d'etre crus tous les
/// deux.
class SentierPese {
  /// Le resultat d'une pesee ; on passe par [peser].
  const SentierPese({
    required this.joursChoisis,
    required this.journeesDeMarche,
    required this.journees,
    required this.mesuresManquantes,
  });

  /// Nombre de jours DEMANDE — l'allure choisie par le lecteur.
  ///
  /// C'est un CONSEIL, pas une propriete du sentier (Christophe, 17/10 11:02).
  /// L'indice se recalcule a chaque fois qu'il change d'avis : il voit la
  /// consequence de son choix AVANT de payer.
  final int joursChoisis;

  /// Les journees PESEES, dans l'ordre, chacune avec son indice.
  ///
  /// Les jours de REPOS n'y figurent pas : une journee sans marche n'est pas
  /// une journee facile, c'est une journee absente. VIDE quand le sentier n'a
  /// pas de quoi peser ([mesuresManquantes] le dit alors), auquel cas
  /// [journeesDeMarche] reste juste.
  final List<JourneePesee> journees;

  /// Les mesures qui MANQUENT, nommees, pour que l'ecran le DISE.
  ///
  /// Un sentier sans trace altimetrisee ou sans nuits relevees n'a pas
  /// d'indice de terrain, et l'ecran l'annonce plutot que d'afficher un nombre
  /// construit sur rien.
  final List<String> mesuresManquantes;

  /// Nombre de journees de MARCHE que le decoupage a reellement produites.
  ///
  /// IL DOIT ETRE EGAL A [joursChoisis], ET C'EST VERIFIE PLUTOT QUE SUPPOSE :
  /// jusqu'a la tache 848 le repartiteur rendait six journees pour sept jours
  /// demandes (mesure #102125). Le defaut est repare et le champ reste.
  ///
  /// IL COMPTE LES JOURNEES DU DECOUPAGE, PAS CELLES QUI ONT UN INDICE, et la
  /// distinction compte : un sentier sans trace altimetrisee a bien ses
  /// journees — on sait combien elles sont et ce qu'elles mesurent —, il n'a
  /// simplement pas d'indice. Confondre les deux ferait disparaitre le compte
  /// en meme temps que la mesure manquante, et c'est ce compte-la que la garde
  /// du repartiteur surveille.
  final int journeesDeMarche;

  /// LA JOURNEE LA PLUS DURE, au sens de l'indice de terrain.
  ///
  /// A indice egal, la PREMIERE de l'itineraire : le marcheur la rencontre
  /// d'abord, et nommer la seconde serait arbitraire.
  JourneePesee? get pireJournee {
    JourneePesee? pire;
    for (final journee in journees) {
      if (pire == null || journee.indiceDuTerrain > pire.indiceDuTerrain) {
        pire = journee;
      }
    }
    return pire;
  }

  /// LA SOMME DES INDICES DES JOURNEES, en points.
  ///
  /// CE N'EST PAS L'INDICE DU SENTIER MARCHE D'UN TRAIT, et l'ecart est une
  /// information commerciale, pas une erreur : sur le GR20, les seize journees
  /// valent 397 points contre 428 d'un seul tenant. Dormir seize fois rend le
  /// sentier 7 % moins dur, parce que chaque nuit coupe une montee.
  double get indiceDuTerrainCumule {
    var total = 0.0;
    for (final journee in journees) {
      total += journee.indiceDuTerrain;
    }
    return total;
  }

  /// LES QUATRE LECTURES DE CE PLAN ([LecturesDuPlan]).
  ///
  /// IL N'Y A VOLONTAIREMENT AUCUNE NOTE SUR CETTE CLASSE. Un plan n'a pas de
  /// note : il a quatre lectures prises sur ses journees. Une garde de test
  /// verifie qu'aucun symbole de note n'apparait a ce niveau.
  LecturesDuPlan get lectures => LecturesDuPlan.desJournees(journees);

  /// PESE LES JOURNEES D'UNE ALLURE SUR LE PROFIL DU SENTIER.
  ///
  /// Retourne `null` quand [jours] est nul ou negatif : il n'y a pas d'indice
  /// d'un sentier qu'on ne marche pas.
  ///
  /// UNE JOURNEE SANS BORNES OU UN SENTIER SANS PROFIL NE PRODUIT AUCUN
  /// INDICE — la mesure manquante est NOMMEE, jamais comblee.
  static SentierPese? peser({
    required int jours,
    required ProfilDuTerrain profil,
    required List<JourneeAPeser> journees,
    LoiDeLIndice loi = LoiDeLIndice.retenue,
  }) {
    if (jours <= 0) return null;

    final manquantes = <String>[];
    if (profil.estVide) {
      manquantes.add('la trace altimetrisee du sentier');
    }
    if (journees.any((journee) => !journee.estPesable)) {
      manquantes.add('les points kilometriques des journees');
    }

    final pesees = <JourneePesee>[];
    if (!profil.estVide) {
      var numero = 1;
      for (final journee in journees) {
        if (!journee.estPesable) continue;
        pesees.add(
          JourneePesee(
            numero: numero,
            depart: journee.depart,
            arrivee: journee.arrivee,
            km: journee.km,
            deniveleM: journee.deniveleM,
            descenteM: journee.descenteM,
            minutes: journee.minutes,
            terrain: IndiceDuTerrain.calculer(
              terrain: profil.tranche(
                pkDebutM: journee.pkDebutKm * 1000.0,
                pkFinM: journee.pkFinKm * 1000.0,
              ),
              loi: loi,
            ),
          ),
        );
        numero++;
      }
    }

    return SentierPese(
      joursChoisis: jours,
      journeesDeMarche: journees.length,
      journees: List<JourneePesee>.unmodifiable(pesees),
      mesuresManquantes: List<String>.unmodifiable(manquantes),
    );
  }
}
