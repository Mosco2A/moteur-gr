/// LES JOURNEES D'UN SENTIER, CHACUNE PESEE PAR SON INDICE DE TERRAIN — et
/// jamais par un mot.
library;

import 'indice_du_terrain.dart';
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
