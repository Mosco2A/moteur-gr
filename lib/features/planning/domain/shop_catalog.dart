import 'shop_catalog_mare_a_mare_centre.dart';
import 'shop_info.dart';

/// Catalogue de donnees RAVITAILLEMENT par sentier (parite GR20
/// `ShopDetailScreen` + `gr20_shops.dart`, data-driven — regle « donnees en
/// externe » de Christophe #99460).
///
/// Equivalent structurel du GR20 `const List<Gr20Shop> gr20Shops` (commerces
/// corses codes en dur), mais cote StepWays le contenu est une DONNEE parametree
/// par sentier (genericite #84627) : AUCUNE localite n'est codee en dur DANS LE
/// MOTEUR (le mapping id -> donnees est une simple table de donnees embarquees).
/// Ce catalogue joue le role du contenu offline rapatrie dans le pack (comme le
/// [TransportCatalog]) ; le backend (Phase 4) le remplacera par le contenu reel.
///
/// Fonctions PURES (aucune dependance Flutter/Slang). Le contenu par sentier est
/// dans la langue de la donnee (ici FR pour le sentier corse) ; l'INTERFACE de
/// l'ecran (filtres, alertes, sections) est traduite cote UI via Slang.
///
/// ---------------------------------------------------------------------------
/// TACHE 844 — CE CATALOGUE DOCUMENTAIT UN ITINERAIRE QUE LE SENTIER NE SUIT
/// PLUS, ET C'EST UN INSTRUMENT QUI DEVENAIT FAUX
/// ---------------------------------------------------------------------------
///
/// CE QUI ETAIT MESURE (Athena, memoire #101828, 13/10/2026). Les quinze
/// entrees de ce fichier decrivaient les commerces de ZICAVO (7 mentions),
/// BASTELICA (7) et CUTTOLI-CORTICCHIATO (4) — trois villages que le Mare a
/// Mare Centre NE TRAVERSE PLUS — et les trois villages reellement desservis,
/// QUASQUARA, SANTA-MARIA-SICHE et BISINAO, n'avaient AUCUNE entree. Un quart
/// des adresses etait hors trace, et trois villages sur huit etaient muets.
///
/// LES HUIT LOCALITES DE L'ITINERAIRE A JOUR, relues dans
/// `assets/data/mare_a_mare_centre/stages.json` (7 etapes, 87,3 km, 4 274 m de
/// montee) : Ghisonaccia, Catastaghju, Cozzano, Guitera-les-Bains, Quasquara,
/// Santa-Maria-Siche, Bisinao, Porticcio. Chaque commerce porte l'etape de SA
/// localite — l'etape dont elle est l'ARRIVEE, et l'etape 1 pour Ghisonaccia
/// qui en est le DEPART. Les huit y sont donc, et les sept etapes aussi.
///
/// D'OU VIENT CHAQUE ADRESSE, ET POURQUOI C'EST ECRIT ICI. Les commerces de ce
/// catalogue sont RELEVES DANS OPENSTREETMAP le 14/10/2026 — chacun porte en
/// commentaire son identifiant d'objet OSM (`node/...`, `way/...`), ce qui rend
/// l'adresse verifiable par n'importe qui et re-interrogeable plus tard. AUCUN
/// commerce n'est invente, et aucun commerce n'est recopie d'un autre sentier.
/// Les coordonnees sont celles de l'objet OSM lui-meme, pas un centre de
/// village approche : c'est la difference avec l'etat precedent, ou toutes les
/// entrees d'une localite partageaient un meme point. Les donnees
/// OpenStreetMap sont sous licence ODbL ; l'attribution est posee sur chaque
/// carte de l'application (`lib/shared/widgets/attribution_osm.dart`) et
/// rappelee dans [TrailShops.limitedSupplyNote], qui est affiche sur cet ecran.
///
/// UN VILLAGE SANS COMMERCE LE DIT, IL NE DISPARAIT PAS. L'ecran ne montre que
/// les etapes qui portent une entree : un village absent du catalogue est un
/// village INVISIBLE, et le randonneur ne peut pas distinguer « rien ici » de
/// « on n'a pas regarde ». Chaque localite ou OpenStreetMap ne releve NI
/// epicerie NI pharmacie porte donc une entree qui l'enonce, avec le point du
/// village et le dernier ravitaillement utile. C'est un FAIT, pas un marqueur
/// d'editeur : rien n'y est a completer, et rien n'y est imagine.
///
/// CE QUE L'INSTRUMENT DE « GAP » MESURE VRAIMENT, ET IL FAUT LE SAVOIR.
/// [TrailShops.gapAfter] compte les etapes sans AUCUNE entree, tous types
/// confondus. Les sept etapes en portent au moins une — parce que les quatre
/// villages du milieu ont bien un bar ou un restaurant releve dans OSM — donc
/// cet instrument-la ne se declenche jamais sur ce sentier, et c'est EXACT :
/// on trouve a manger partout. La vraie rarete est l'EPICERIE.
///
/// TACHE 834 — ET C'EST POURQUOI L'ALERTE NE COMPTE PLUS LES ENTREES MAIS LES
/// RAVITAILLEMENTS. La note ci-dessous disait deja la verite en francais ;
/// l'alerte de la carte, elle, restait muette, parce qu'elle mesurait « une
/// entree existe » au lieu de « on peut recharger son sac ». Trois entrees du
/// catalogue auraient suffi a la tromper : un constat d'absence porte un
/// [ShopKind], donc « Guitera-les-Bains — aucune epicerie relevee » comptait
/// comme une epicerie. L'alerte lit maintenant
/// [TrailShops.resupplyStages], qui ne retient que les entrees portant
/// [Shop.providesResupply] : les neuf vraies epiceries des etapes 1, 2 et 7.
/// Le trou reel — CINQ etapes et 52,5 km entre Cozzano et Porticcio — se
/// declenche enfin, et c'est le meme chiffre que celui de la note.
///
/// CE QUI NE PORTE PAS [Shop.providesResupply], ET LA RAISON DE CHACUN :
///  - les CINQ constats d'absence : ils constatent, ils n'approvisionnent pas ;
///  - les QUATRE pharmacies : on n'y achete pas trois jours de vivres ;
///  - les QUATRE bars et restaurants (Guitera, Frasseto, Campo,
///    Santa-Maria-Siche, Bisinao) : on y mange une fois, on n'en repart pas
///    charge ;
///  - la BOUCHERIE L'ALTA STRADA, et c'est le seul arbitrage discutable de la
///    liste : elle est REELLE, mais a Frasseto, dans une AUTRE COMMUNE, a 1 km
///    du trace. C'est une option de detour, pas un ravitaillement qu'on
///    planifie — et la note du sentier, ecrite sur le releve OSM du 14/10,
///    affirme deja qu'aucune epicerie ne dessert les cinq etapes entre Cozzano
///    et Porticcio. La compter aurait coupe le trou en deux (3 etapes puis 2)
///    et fait taire l'alerte au seuil de 2. Elle reste visible sur l'ecran
///    « Ravitaillement » : le randonneur la trouve, l'alerte ne s'y fie pas.
///    Sous-alerter sur la nourriture se paye en kilos portes pour rien ;
///    sur-alerter se paye en kilos portes. On choisit le second.
///
/// LA RARETE SE LIT DONC TROIS FOIS, ET PLUS DEUX : par le filtre « Epicerie »
/// de l'ecran, par [TrailShops.limitedSupplyNote] qui l'enonce en clair, et
/// desormais par l'alerte de la carte, pendant la marche, au moment ou l'on
/// quitte la derniere epicerie.
///
/// UN HORAIRE QU'ON N'A PAS N'EST PAS ECRIT DU TOUT (lot 645-08, voie V2
/// arbitree par Christophe le 02/10/2026). [Shop.openingHours] porte un
/// horaire, ou il est absent : la ligne disparait de la carte comme de la fiche
/// (`shop_screen.dart` la garde par `openingHours.isNotEmpty`). Rien ne la
/// remplace — pas de tiret, pas de « non renseigne », pas d'espace reserve. Les
/// horaires ci-dessous sont ceux du champ `opening_hours` d'OpenStreetMap,
/// TRADUITS EN FRANCAIS LISIBLE et sans rien ajouter : une entree dont OSM ne
/// porte pas l'horaire n'en affiche aucun. Les quatre horaires creux d'une
/// autre famille que le lot 645-08 signalait (« a verifier sur place »,
/// « ouvert a l'annee (a confirmer) ») ont disparu avec les entrees qui les
/// portaient : ils decrivaient des commerces hors trace.
abstract final class ShopCatalog {
  /// Retourne les donnees ravitaillement du sentier [trailId], ou `null` si le
  /// sentier n'en fournit pas (l'ecran affiche alors un fallback informatif).
  ///
  /// Le moteur reste generique : le mapping id -> donnees est une simple table de
  /// DONNEES embarquees, jamais une localite codee dans la logique du moteur.
  static TrailShops? forTrail(String trailId) {
    switch (trailId) {
      case 'mare-a-mare-centre':
        return mareAMareCentreShops;
      default:
        return null;
    }
  }
}
