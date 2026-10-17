/// Les sentiers connus : ajouter un sentier est une ENTREE de donnee, pas une
/// modification du moteur. Y figurer ne suffit pas a etre VENDU — un sentier
/// qui se declare invente est ecarte du catalogue (tache 793).
library;

import 'gr20_nord_trail_config.dart';
import 'gr20_sud_trail_config.dart';
import 'gr20_trail_config.dart';
import 'mare_a_mare_centre_trail_config.dart';
import 'pyrenees_trail_config.dart';
import 'test_trail_config.dart';
import 'trail_config.dart';

/// Catalogue des sentiers connus du Moteur GR (F8D-01, Phase 8 P8-D).
///
/// Le moteur est GENERIQUE multi-sentiers (#84627) : il ne hardcode AUCUNE
/// localite (ni Corse, ni Mare a Mare). Chaque sentier est une [TrailConfig] —
/// une DONNEE — enregistree ici. Ajouter un sentier = ajouter une entree, sans
/// toucher au moteur.
///
/// En P2-P3, le catalogue est embarque (donnees fictives, #84627). En Phase 4,
/// le backend pourra fournir/mettre a jour la liste des sentiers disponibles.
///
/// Contient au moins DEUX sentiers de regions differentes pour prouver la
/// genericite : le sentier reel de Corse ([mareAMareCentreTrailConfig]) et un
/// premier sentier HORS Corse dans les Pyrenees ([pyreneesTrailConfig]).
///
/// DEUX LISTES, ET LA DIFFERENCE EST TOUT LE SUJET DE LA TACHE 793.
/// [_registre] est ce que le BINAIRE sait decrire, fictions comprises ;
/// [all] est ce que le RANDONNEUR voit et peut acheter. La seconde se deduit
/// de la premiere en ECARTANT ce qui se declare fictif
/// ([TrailConfig.isFictional]). Jusqu'ici il n'y avait qu'une liste, et un
/// sentier invente y vivait comme les autres.
abstract final class TrailCatalog {
  TrailCatalog._();

  /// LE REGISTRE — tout ce que le binaire sait decrire, DECORS DE TEST INCLUS.
  ///
  /// Ce n'est PAS le catalogue : rien ici n'est propose au randonneur du seul
  /// fait d'y figurer. Pour cela il faut encore passer [all], qui refuse les
  /// sentiers fictifs. Y ajouter une entree est une ENTREE DE DONNEE, pas une
  /// modification du moteur.
  ///
  /// `const` : la liste est figee a la compilation en P2-P3 (#84627). L'ordre
  /// fait foi pour le selecteur de sentier (F8D-02).
  static const List<TrailConfig> _registre = <TrailConfig>[
    // Sentier reel PAYANT de StepWays (#99423). EN TETE => devient
    // [defaultTrail] : l'app demarre dessus. Reste une DONNEE (TrailConfig), le
    // moteur ne hardcode aucune localite.
    mareAMareCentreTrailConfig,
    // LE GR20, DEUXIEME SENTIER REEL (tache 839), DEVENU UNE NUMEROTATION DE
    // REFERENCE (tache 841). Il reste au REGISTRE — ses seize etapes, sa trace
    // et ses trente et une nuits sont la donnee d'ou ses deux chapitres sont
    // decoupes, et la regle CH-10 veut que cette numerotation ne bouge jamais —
    // mais il ne passe plus [all] : il declare des chapitres, donc il n'est
    // plus un produit. Decision de Christophe du 15/10 17:45.
    //
    // CE QUI A CHANGE DEPUIS LA TACHE 839, EN UNE PHRASE : les deux moities
    // etaient de la DONNEE (`assets/data/gr20.json`, parcours NORD et SUD,
    // mesures a 91,80 et 91,79 km) ; ce sont desormais des PRODUITS, et c'est
    // le sentier entier qui n'en est plus un.
    gr20TrailConfig,
    // LES DEUX CHAPITRES DU GR20 (tache 841) — DEUX PRODUITS, PAS DEUX
    // MORCEAUX. Chacun est un sentier COMPLET au sens de la regle CH-11 du
    // design #101920 : son nom, sa trace decoupee, ses etapes renumerotees, ses
    // reperes, ses couchages, ses nuits, son prix en etapes. Ils entrent au
    // catalogue comme tous les autres, c'est-a-dire comme une ENTREE DE DONNEE.
    //
    // NEUF ETAPES AU NORD, SEPT AU SUD, SEIZE EN TOUT : le prix du sentier
    // entier est exactement la somme de ses deux chapitres. Qui veut tout
    // prend les deux, et paie ce qu'il aurait paye avant.
    //
    // APRES LE SENTIER MERE DANS LA LISTE, ET SANS CONSEQUENCE SUR LE DEMARRAGE
    // : [defaultTrail] est le premier d'[all], et le Mare a Mare Centre y reste
    // en tete.
    gr20NordTrailConfig,
    gr20SudTrailConfig,
    // IL N'Y A PLUS DE SENTIER « MARE A MARE CENTRE DEMO » (tache 638, bugs 1 et
    // 8 — DEM-260930-1005 et DEM-260930-1014). Le lot 601 avait ajoute ici un
    // SECOND Mare a Mare, gratuit et ampute a deux etapes, sur la decision de
    // Christophe du 27/09 : « il y a mare a mare ET mare a mare demo des le
    // catalogue ». Son test du 30/09 a renverse les deux moities de cette
    // decision, verbatim : « il reste Mare a Mare Centre Demo gratuite en doublon
    // avec Essayer la demo » (bug 1) et « la demo de Mare a Mare ce doit etre la
    // demo de Mare a Mare, pas un truc avec 2 etapes !! » (bug 8).
    //
    // LA DEMO N'EST DONC PLUS UN SENTIER, C'EST UN MODE, et il s'applique au
    // sentier ci-dessus — entier. Le doublon disparait du catalogue avec
    // l'entree, et le bouton orange « Essayer la demo » reste la seule porte
    // d'entree de la demonstration (cf. `session_demo.dart`).
    //
    // ET IL N'Y A PLUS AUCUN SENTIER GRATUIT AU CATALOGUE. C'est une decision de
    // Christophe, pas une consequence : son scenario d'acceptation du 29/09
    // 14:17 dit, verbatim, « la prochaine fois que j'ouvre l'application je n'ai
    // droit a rien ». Un sentier gratuit au catalogue lui donnerait droit a
    // quelque chose sans qu'il ait rien achete — exactement ce qu'il refuse.
    //
    // LE NIVEAU GRATUIT DU MODELE ECO, C'EST LA DEMO, PAS UN SENTIER. Le modele
    // du lot 601 — « un sentier gratuit est une ENTREE du modele, dont le prix
    // est nul ; une exemption serait un trou » — reste ecrit et teste
    // ([TrailConfig.isFreeTrail], [freeIds]) : il n'a simplement plus d'instance,
    // et c'est un etat legitime. Ce que le randonneur qui n'a rien achete peut
    // faire, il le fait par le bouton orange : il VOIT tout, il n'ACQUIERT rien.
    //
    // COROLLAIRE ASSUME : « Mes treks » est VIDE au premier lancement, et il le
    // DIT (cf. `my_treks_screen.dart`, etat vide) en renvoyant vers le catalogue
    // et vers la demo. Un accueil vide qui explique n'est pas une panne ; un
    // sentier offert pour eviter un ecran vide serait un cadeau que personne n'a
    // decide.
    // DECOR DE TEST, ECARTE DU CATALOGUE PAR [all] (tache 793). Il reste au
    // REGISTRE parce que soixante-six fichiers de test s'en servent de decor —
    // sortir du catalogue n'est pas sortir du depot. Mais il se declare fictif
    // (`isFictional: true`), donc [all] ne le laisse pas passer : le randonneur
    // ne le voit plus et ne peut plus l'acheter.
    testTrailConfig,
    pyreneesTrailConfig,
  ];

  /// LE CATALOGUE — ce que le randonneur VOIT et peut ACHETER.
  ///
  /// LA GARDE EST ICI, ET ELLE REFUSE AU LIEU DE SIGNALER (tache 793). Tout
  /// sentier du [_registre] qui se declare invente ([TrailConfig.isFictional])
  /// est ECARTE, sans condition et sans exception nommable. Un test peut
  /// constater une faute ; ce filtre, lui, l'empeche : meme un binaire livre
  /// avec un decor de test fraichement ajoute au registre ne le proposera pas.
  ///
  /// POURQUOI SUR LA PROPRIETE ET NON SUR L'IDENTIFIANT. `id != 'test-trail'`
  /// aurait ferme la porte derriere ce sentier-ci et rouverte pour le suivant.
  /// Dans six mois, quelqu'un ajoutera un autre decor de test : il n'aura rien
  /// a savoir de cette garde, il devra seulement dire la verite dans sa
  /// configuration — et la verite suffira.
  ///
  /// TOUT LE RESTE EN DECOULE, ET C'EST VOULU. [ids], [freeIds], [byId],
  /// [contains], [resolveOrDefault] et [defaultTrail] derivent de CETTE liste,
  /// pas du registre : un sentier fictif devient donc introuvable par
  /// identifiant, non resoluble, et une selection qui le viserait retombe sur
  /// [defaultTrail]. Le chainage distant lit lui aussi [all]
  /// (`trail_catalog_provider.dart`), aussi bien comme secours hors ligne que
  /// comme matiere de fusion : la garde couvre les deux portes d'un coup.
  ///
  /// `final` et non `const` : le filtre est evalue UNE fois, au premier acces.
  /// Les donnees restent compilees — c'est la selection qui ne peut plus l'etre.
  ///
  /// LA SECONDE GARDE EST ARRIVEE AVEC LE CHAPITRE (tache 841), ET ELLE NE
  /// RESSEMBLE PAS A LA PREMIERE. Un sentier qui a des CHAPITRES
  /// ([TrailConfig.aDesChapitres]) est ecarte lui aussi, sur la decision de
  /// Christophe du 15/10 17:45 : « on achete le sentier seulement si il n y a
  /// pas de chapitres ». Mais la raison est opposee a celle du sentier fictif.
  /// Le fictif est un MENSONGE : on le rend introuvable, et c'est pour cela que
  /// [byId] ne le voit pas. Le sentier mere est une VERITE qui n'est pas un
  /// produit : il doit rester resolvable (voir [byId] et [referentiel]), parce
  /// que ses donnees sont celles d'ou ses chapitres sont decoupes et que sa
  /// numerotation de reference ne doit JAMAIS bouger (regle CH-10). Les deux
  /// gardes vivent donc ensemble, et elles ne se confondent pas.
  static final List<TrailConfig> all = _registre
      .where((c) => !c.isFictional && !c.aDesChapitres)
      .toList(growable: false);

  /// LE REFERENTIEL — tout ce qui existe VRAIMENT, produits et sentiers meres.
  ///
  /// C'est [all] plus les sentiers meres : ce qui doit rester RESOLVABLE par
  /// identifiant sans pour autant etre a vendre. Les sentiers fictifs n'y sont
  /// pas — eux n'existent pas.
  ///
  /// A QUOI IL SERT, CONCRETEMENT. Le decoupage d'un chapitre lit les donnees
  /// de son sentier mere ; la numerotation de reference de la regle CH-10 doit
  /// pouvoir etre interrogee ; et un droit vendu hier sur un sentier devenu
  /// mere aujourd'hui doit encore pouvoir etre LU, meme si plus personne ne
  /// peut l'acheter. C'est la liste que [byId] consulte.
  static final List<TrailConfig> referentiel = _registre
      .where((c) => !c.isFictional)
      .toList(growable: false);

  /// Les sentiers du referentiel qui ne sont PLUS a vendre parce qu'ils ont des
  /// chapitres — l'absence est NOMMEE, jamais silencieuse.
  static List<TrailConfig> get sentiersMeres =>
      referentiel.where((c) => c.aDesChapitres).toList(growable: false);

  /// Les CHAPITRES du sentier [id], dans l'ordre de sa declaration.
  ///
  /// Vide quand ce sentier n'a pas de chapitres. L'ordre vient de
  /// [TrailConfig.chapterIds] et il ne se renumerote jamais (regle CH-10).
  static List<TrailConfig> chapitresDe(String id) {
    final mere = byId(id);
    if (mere == null) return const [];
    return mere.chapterIds
        .map(byId)
        .whereType<TrailConfig>()
        .toList(growable: false);
  }

  /// Les sentiers du registre ECARTES du catalogue parce qu'ils se declarent
  /// fictifs — l'absence est NOMMEE, jamais silencieuse.
  ///
  /// Un sentier qui disparait sans explication est indiagnosticable, c'est la
  /// lecon de la tache 604 et c'est pourquoi l'etat du catalogue distant porte
  /// deja ses `ignores`. Ce retrait-ci se dit de la meme facon : la garde
  /// d'[all] peut etre interrogee sur ce qu'elle a refuse, et son test l'est.
  static List<TrailConfig> get fictifsEcartes =>
      _registre.where((c) => c.isFictional).toList(growable: false);

  /// Sentier par defaut (premier du catalogue) — jamais une localite hardcodee,
  /// toujours derive des donnees. Sert de selection initiale (F8D-02).
  ///
  /// INCHANGE PAR LE RETRAIT DU SENTIER FICTIF (tache 793) : celui-ci etait en
  /// DEUXIEME position, derriere [mareAMareCentreTrailConfig]. Le defaut reste
  /// donc `mare-a-mare-centre`, l'app demarre au meme endroit, et un test le
  /// verifie nommement plutot que par deduction.
  static TrailConfig get defaultTrail => all.first;

  /// Identifiants de tous les sentiers du catalogue (ordre d'affichage).
  static List<String> get ids => all.map((c) => c.id).toList(growable: false);

  /// Identifiants des sentiers GRATUITS — ceux dont le PRIX est nul.
  ///
  /// Dérivé du PRIX porté par la donnée ([TrailConfig.priceStages] à 0), jamais
  /// d'un id de localité codé en dur. Remplace l'ancien `showcaseIds`, qui
  /// dérivait d'un drapeau d'EXEMPTION (`isShowcaseTrail`) au lieu d'un prix :
  /// la différence est de fond et pas de forme (tâche 601). Une exemption est un
  /// trou dans le modèle ; un prix nul est une entrée du modèle, dont tout le
  /// reste — accès, réalisation, publicité — se déduit.
  static Set<String> get freeIds =>
      all.where((c) => c.isFreeTrail).map((c) => c.id).toSet();

  /// Vrai si [id] est un sentier GRATUIT (prix nul, donc rien à débloquer).
  static bool isFree(String? id) => id != null && freeIds.contains(id);

  /// Retourne la config du sentier [id], ou null si inconnu.
  ///
  /// IL CHERCHE DANS LE [referentiel], PAS DANS [all] (tache 841). Un sentier
  /// mere n'est plus a vendre mais il existe : ses donnees portent la
  /// numerotation de reference d'ou ses chapitres sont decoupes, et un droit
  /// vendu avant qu'il ait des chapitres doit encore pouvoir etre lu. Un
  /// sentier FICTIF, lui, reste introuvable — c'est tout l'objet de la tache
  /// 793 et rien n'y change.
  ///
  /// CE QU'IL FAUT EN DEDUIRE, ET C'EST LE PIEGE A CONNAITRE : trouver un
  /// sentier par cette methode ne dit PAS qu'il est a vendre. La vente se
  /// demande a [TrailConfig.estVendable], et [TrailPurchases] la refuse
  /// nommement.
  static TrailConfig? byId(String id) {
    for (final config in referentiel) {
      if (config.id == id) return config;
    }
    return null;
  }

  /// Vrai si [id] correspond a un sentier connu — produit OU sentier mere.
  static bool contains(String id) => byId(id) != null;

  /// Vrai si [id] a des CHAPITRES, donc s'il ne se vend plus en bloc.
  static bool aDesChapitres(String id) => byId(id)?.aDesChapitres ?? false;

  /// Resout [id] vers une config connue, ou retombe sur [defaultTrail].
  ///
  /// Garantit qu'une selection invalide (sentier retire, id obsolete) ne casse
  /// jamais le moteur : on retombe sur un sentier valide (genericite robuste).
  static TrailConfig resolveOrDefault(String? id) {
    if (id == null) return defaultTrail;
    return byId(id) ?? defaultTrail;
  }
}
