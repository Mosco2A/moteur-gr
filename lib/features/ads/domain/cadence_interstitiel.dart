/// LA CADENCE DE L'INTERSTITIEL — une demi-heure d'utilisation entre deux,
/// jamais pendant la marche, jamais sur le chemin du secours (tache 838, D2).
///
/// ---------------------------------------------------------------------------
/// CE QUE CHRISTOPHE A DEMANDE, MOT POUR MOT
/// ---------------------------------------------------------------------------
///
/// « j en veu une toute les demi-heures heures d utilisation »
///
/// Et, dans le meme mouvement, la limite qui l'encadre :
/// « IL N Y A PAS DE PUB POSSIBLE EN MODE RANDO !!! »
///
/// ---------------------------------------------------------------------------
/// CE QUI EXISTAIT, ET POURQUOI CE N'ETAIT PAS UN INTERSTITIEL
/// ---------------------------------------------------------------------------
///
/// Le depot portait DEJA la mecanique d'un interstitiel — chargement,
/// affichage, liberation — dans `features/group/services/ad_service.dart`, pour
/// la monetisation des suiveurs au-dela du deuxieme. Elle n'avait AUCUN
/// appelant dans `lib/` : ni `showInterstitial`, ni `preloadInterstitial`
/// n'etaient appeles nulle part. Un format publicitaire que rien ne declenche
/// n'existe pas, exactement comme la banniere avant la tache 595 — « un
/// interrupteur sans ampoule ».
///
/// ET LA CONFIGURATION DISAIT L'INVERSE DE CE QU'ON LUI DEMANDE AUJOURD'HUI :
/// `ad_config.dart` affirmait « BANNIERES + RECOMPENSEES UNIQUEMENT. PAS
/// d'interstitiel », sans exposer d'identifiant interstitiel. Les deux morceaux
/// ne pouvaient donc pas se rencontrer.
///
/// ---------------------------------------------------------------------------
/// POURQUOI LA REGLE VIT ICI, SEULE, ET SANS RIEN SAVOIR DU MONDE
/// ---------------------------------------------------------------------------
///
/// Ce fichier ne lit aucune base, n'appelle aucun SDK, et ne connait ni
/// Riverpod ni Flutter. Il ne contient QUE la decision. C'est ce qui permet
/// de la mesurer exhaustivement — chaque refus a son test — sans monter
/// une application, et c'est ce qui evite la faute que la banniere a connue :
/// une regle eparpillee dans des conditions d'ecran, que le prochain
/// emplacement publicitaire n'herite pas.
///
/// LE RESTE — l'horloge d'utilisation, l'etat du dernier affichage, la regie —
/// est dans `providers/interstitiel_providers.dart`, et c'est lui qui apporte
/// les faits a cette decision.
library;

/// L'ECART MINIMAL ENTRE DEUX INTERSTITIELS, en TEMPS D'UTILISATION.
///
/// « toute les demi-heures heures d utilisation » : trente minutes.
///
/// EN TEMPS D'UTILISATION, ET PAS EN TEMPS DE CALENDRIER — c'est le mot que
/// Christophe a employe, et il change tout. Une application ouverte deux
/// minutes par jour ne doit pas montrer un interstitiel a chaque ouverture
/// parce qu'une demi-heure de MONTRE s'est ecoulee entre deux. Ce qui se compte
/// est le temps ou l'application est REELLEMENT devant les yeux du randonneur ;
/// l'horloge qui le mesure s'arrete quand l'application passe en arriere-plan.
const Duration kEcartEntreInterstitiels = Duration(minutes: 30);

/// LES CHEMINS OU UN INTERSTITIEL NE S'OUVRE JAMAIS — le chemin du secours.
///
/// « jamais sur un ecran de securite ni sur l urgence ». Ce n'est pas une
/// question de confort : un randonneur qui ouvre ces ecrans a, par hypothese,
/// un probleme. Lui prendre l'ecran entier pour une publicite serait au mieux
/// indecent, au pire dangereux.
///
/// LES TROIS ECRANS DU CHEMIN DU SECOURS, et ce sont les memes que ceux dont le
/// groupe B5 de `pub_v1_595_test.dart` interdit deja la BANNIERE :
///   * `/emergency` — les secours et les numeros d'urgence ;
///   * `/health` — la fiche d'informations sante, ouverte depuis l'urgence ;
///   * `/signalement` — le signalement terrain.
///
/// LE BOUTON SOS ET SA CONFIRMATION N'ONT PAS BESOIN D'Y FIGURER, et il faut
/// dire pourquoi plutot que de laisser croire a un oubli. Ce ne sont pas des
/// routes : le bouton vit sur la carte et sa confirmation est un dialogue. Un
/// interstitiel ne se declenche qu'a l'ARRIVEE SUR UNE ROUTE, donc ni l'un ni
/// l'autre ne peut en ouvrir un. Et ils ne vivent que pendant une randonnee,
/// ou la regle « jamais pendant la marche » couvre deja tout l'ecran.
const Set<String> kCheminsSansInterstitiel = {
  '/emergency',
  '/health',
  '/signalement',
};

/// L'ETAT DU MONDE a l'instant ou un interstitiel pourrait s'ouvrir.
///
/// Tout ce que la decision a besoin de savoir, et rien de plus. Les faits
/// arrivent d'ailleurs ; ici on ne fait que les lire.
class MomentDInterstitiel {
  /// Les faits du moment, tous requis : la decision n'en devine aucun.
  const MomentDInterstitiel({
    required this.utilisation,
    required this.utilisationAuDernier,
    required this.enRando,
    required this.chemin,
    required this.sansPub,
    required this.pubAutorisee,
  });

  /// Le temps d'utilisation accumule par l'horloge qui le compte.
  ///
  /// ELLE DEMARRE A LA PREMIERE CONSULTATION DE LA CADENCE, et pas a l'allumage
  /// de l'application : l'horloge est un provider, donc construite a sa
  /// premiere lecture. La difference joue en faveur du randonneur — le premier
  /// interstitiel tombe un peu plus tard, jamais plus tot — et il valait mieux
  /// l'ecrire que laisser croire a un compteur parti au splash.
  final Duration utilisation;

  /// La valeur de [utilisation] quand le dernier interstitiel s'est ouvert.
  ///
  /// `Duration.zero` au lancement, et c'est un choix : le premier interstitiel
  /// tombe apres une demi-heure d'utilisation, pas au premier ecran. Un
  /// interstitiel sur l'ecran d'accueil d'une application qu'on vient
  /// d'installer est la meilleure facon de la faire desinstaller.
  final Duration utilisationAuDernier;

  /// Une realisation est-elle en cours ? (source unique : `enModeTrekProvider`)
  final bool enRando;

  /// Le chemin de l'ecran sur lequel on vient d'arriver.
  final String chemin;

  /// Le randonneur est-il sans-pub ? (abonne, sentier achete, recompense 24 h)
  final bool sansPub;

  /// Le consentement publicitaire autorise-t-il a DEMANDER une pub ? (CMP)
  final bool pubAutorisee;

  /// Le temps d'utilisation ecoule depuis le dernier interstitiel.
  Duration get depuisLeDernier => utilisation - utilisationAuDernier;

  /// L'HEURE EST-ELLE VENUE ? Les cinq conditions, et elles sont TOUTES
  /// necessaires.
  ///
  /// L'ORDRE DES REFUS N'EST PAS INDIFFERENT : les deux limites qui ne se
  /// discutent pas passent d'abord — la marche et le secours — parce que ce
  /// sont les seules ou l'on prefere ne meme pas avoir pose la question.
  bool get autorise {
    // 1. JAMAIS PENDANT LA MARCHE. « IL N Y A PAS DE PUB POSSIBLE EN MODE
    //    RANDO !!! » : un interstitiel prend TOUT l'ecran, donc la carte, la
    //    trace, le prochain virage et le bouton SOS avec. C'est le refus le
    //    plus facile a justifier du fichier.
    if (enRando) return false;

    // 2. JAMAIS SUR LE CHEMIN DU SECOURS.
    if (kCheminsSansInterstitiel.contains(chemin)) return false;

    // 3. JAMAIS SI LE RANDONNEUR A PAYE LE SILENCE. Aucune regle sans-pub
    //    n'est recalculee ici : on lit la source unique (#99404), exactement
    //    comme la banniere.
    if (sansPub) return false;

    // 4. JAMAIS SANS LE DROIT DE DEMANDER UNE PUB (CMP/UMP). Hors ligne, ce
    //    droit tombe de lui-meme — donc pas d'interstitiel sur le sentier,
    //    meme en dehors d'une marche.
    if (!pubAutorisee) return false;

    // 5. ET LA CADENCE, EN DERNIER. C'est la seule des cinq conditions qui
    //    redeviendra vraie toute seule avec le temps.
    return depuisLeDernier >= kEcartEntreInterstitiels;
  }
}
