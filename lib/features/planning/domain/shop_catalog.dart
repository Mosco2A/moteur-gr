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
/// l'alerte de gap ne se declenche jamais sur ce sentier, et c'est EXACT : on
/// trouve a manger partout. La vraie rarete est l'EPICERIE, et elle se lit
/// deux fois : par le filtre « Epicerie » de l'ecran, ou les entrees honnetes
/// ci-dessous apparaissent a leur juste place, et par
/// [TrailShops.limitedSupplyNote], qui l'enonce en clair. Un seuil de gap ne
/// sait pas dire « on mange mais on ne se ravitaille pas » : la note, elle,
/// sait.
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
        return _mareAMareCentre;
      default:
        return null;
    }
  }

  // ==========================================================================
  // Mare a Mare Centre (Corse) — sentier VITRINE de demonstration (#99423).
  //
  // Les sept etapes et les huit localites, lues dans
  // assets/data/mare_a_mare_centre/stages.json :
  //   1 Ghisonaccia -> Catastaghju        19,9 km  D+1058
  //   2 Catastaghju -> Cozzano            14,9 km  D+1044
  //   3 Cozzano -> Guitera-les-Bains      13,7 km  D+ 647
  //   4 Guitera-les-Bains -> Quasquara     9,7 km  D+ 524
  //   5 Quasquara -> Santa-Maria-Siche     8,1 km  D+ 617
  //   6 Santa-Maria-Siche -> Bisinao       9,9 km  D+ 330
  //   7 Bisinao -> Porticcio              11,1 km  D+  54
  //
  // UNE PRECISION QUI SE MESURE ET QUI SE DIT : le point de depart de l'etape 1
  // (41.9757, 9.3994) est a SERRA-DI-FIUMORBO, a 4,2 km du premier commerce de
  // Ghisonaccia et a 4,8 km du dernier. Les commerces de Ghisonaccia sont donc
  // donnes a leur VRAIE position (celle d'OSM), et la note du sentier dit que
  // les courses se font en ville, avant de rejoindre le depart.
  // ==========================================================================
  static const TrailShops _mareAMareCentre = TrailShops(
    trailId: 'mare-a-mare-centre',
    // Seuil de gap parite GR20 (alerte si plus de 2 etapes sans commerce).
    gapThreshold: 2,
    // Message « ravitaillement limite » PROPRE AU SENTIER, en langue de la
    // donnee (data-driven #99460, pas de chiffre GR20 en dur). Il porte aussi
    // l'attribution ODbL des commerces, qui viennent d'OpenStreetMap.
    //
    // AU TUTOIEMENT, COMME TOUTE L'APPLICATION (regle 757). L'ancienne note
    // disait « Faites vos courses » : la garde du tutoiement ne lit que les
    // cinq fichiers de langue, donc le vouvoiement survivait ici, dans une
    // DONNEE que le randonneur lit comme le reste. Le texte neuf tutoie.
    limitedSupplyNote:
        'On mange a chaque etape, mais on ne se ravitaille pas : seules '
        'Ghisonaccia (depart), Cozzano et Porticcio (arrivee) ont une '
        'epicerie sur le trace. Les cinq etapes entre Cozzano et Porticcio '
        '(52,5 km) n\'en ont aucune, et Catastaghju aucun commerce. Fais tes '
        'courses a Ghisonaccia — en ville, a 4 km du depart — puis a '
        'Cozzano. Commerces releves dans OpenStreetMap (ODbL).',
    shops: [
      // ====== ETAPE 1 — GHISONACCIA (depart, plaine orientale) ===============
      // Releve OSM du 14/10/2026, commune de Ghisonaccia (20240). Les cinq
      // entrees portent leur propre point : elles sont etalees sur 600 m de
      // ville, et toutes a plus de 4 km du point de depart de l'etape 1.
      Shop(
        // OSM way/30996848
        name: 'Centre commercial E. Leclerc (Ghisonaccia)',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 42.018341,
        longitude: 9.405123,
        address: 'N 198, 20240 Ghisonaccia',
        website: 'https://www.e.leclerc/mag/e-leclerc-ghisonaccia',
        products: [
          'Alimentation complete',
          'Fruits et legumes',
          'Pain / boulangerie',
          'Boissons',
          'Piles / batteries',
        ],
        openingHours: 'Lun-Sam 8h30-20h, Dim 8h30-13h',
      ),
      Shop(
        // OSM way/314116188
        name: 'Supermarche Spar (Ghisonaccia)',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 42.013221,
        longitude: 9.403511,
        address: '455 avenue du 9 Septembre, 20240 Ghisonaccia',
        website: 'https://magasins.spar.fr/fr/spar-supermarche-ghisonaccia',
        products: [
          'Alimentation generale',
          'Produits frais',
          'Pain',
          'Boissons',
        ],
        openingHours: 'Tous les jours 8h-20h',
      ),
      Shop(
        // OSM node/8602653690
        name: 'Epicerie Bio Ghisonaccia',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 42.018440,
        longitude: 9.403400,
        address: 'Route de Ghisoni, 20240 Ghisonaccia',
        phone: '+33 6 29 62 32 67',
        website: 'https://www.epiceriebio-ghisonaccia.fr',
        products: [
          'Alimentation biologique',
          'Fruits secs / barres energetiques',
          'Produits corses',
        ],
        openingHours:
            'Lun, Mar et Sam 8h-12h30 ; Jeu et Ven 8h-12h30 puis '
            '14h30-18h30 ; ferme Mer et Dim',
      ),
      Shop(
        // OSM node/836828941
        name: 'Pharmacie Beissy (Ghisonaccia)',
        type: ShopKind.pharmacie,
        stageNumber: 1,
        latitude: 42.013179,
        longitude: 9.404310,
        products: [
          'Medicaments',
          'Pansements / double peau',
          'Creme solaire',
          'Anti-moustiques',
          'Sels de rehydratation',
        ],
      ),
      Shop(
        // OSM node/4304894054
        name: 'Pharmacie Santoni (Ghisonaccia)',
        type: ShopKind.pharmacie,
        stageNumber: 1,
        latitude: 42.016154,
        longitude: 9.405215,
        products: [
          'Medicaments',
          'Soin des pieds / ampoules',
          'Materiel de premiers secours',
        ],
      ),

      // ====== ETAPE 1 — CATASTAGHJU (arrivee) ================================
      // RIEN. Releve OSM du 14/10/2026 dans un rayon de 2 km autour du point
      // d'arrivee (41.9628, 9.2595, hameau de la commune de
      // San-Gavino-di-Fiumorbo) : ZERO commerce, ZERO bar, ZERO pharmacie. Ce
      // n'est pas une donnee manquante, c'est un fait releve — et il se dit,
      // sinon l'etape 1 n'afficherait que Ghisonaccia et le randonneur croirait
      // son arrivee desservie.
      Shop(
        name: 'Catastaghju — aucun commerce releve',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 41.962821,
        longitude: 9.2595172,
        products: [
          'Aucune epicerie, aucun bar et aucune pharmacie releves dans '
              'OpenStreetMap a moins de 2 km',
          'Dernier ravitaillement : Ghisonaccia, au depart de l\'etape',
          'Prochain ravitaillement : Cozzano, a l\'arrivee de l\'etape 2',
        ],
      ),

      // ====== ETAPE 2 — COZZANO (haute vallee du Taravo) =====================
      // Releve OSM du 14/10/2026, commune de Cozzano (20148). Le village est le
      // SEUL ravitaillement entre Ghisonaccia et Porticcio : epicerie ouverte
      // tous les jours et pharmacie.
      Shop(
        // OSM way/568833856
        name: 'Spar (Cozzano)',
        type: ShopKind.epicerie,
        stageNumber: 2,
        latitude: 41.934802,
        longitude: 9.158518,
        address: '20148 Cozzano',
        phone: '+33 4 95 50 71 14',
        products: [
          'Alimentation generale',
          'Pain',
          'Produits frais',
          'Boissons',
          'Produits corses',
        ],
        openingHours: 'Tous les jours 7h-20h',
      ),
      Shop(
        // OSM node/7926179290
        name: 'Proxi (Cozzano)',
        type: ShopKind.epicerie,
        stageNumber: 2,
        latitude: 41.934979,
        longitude: 9.155364,
        address: '20148 Cozzano',
        products: ['Alimentation de depannage', 'Pain', 'Boissons'],
        openingHours: 'Tous les jours 7h-20h',
      ),
      Shop(
        // OSM way/568833958
        name: 'Pharmacie Alvau (Cozzano)',
        type: ShopKind.pharmacie,
        stageNumber: 2,
        latitude: 41.935050,
        longitude: 9.155019,
        address: '20148 Cozzano',
        phone: '+33 4 95 24 40 40',
        products: [
          'Medicaments',
          'Soin des pieds / ampoules',
          'Materiel de premiers secours',
        ],
      ),

      // ====== ETAPE 3 — GUITERA-LES-BAINS (hameau thermal) ===================
      // Releve OSM du 14/10/2026 (20153) : un bar a 182 m du point d'arrivee,
      // SANS NOM dans OpenStreetMap — on le donne pour ce qu'il est plutot que
      // de lui inventer une enseigne. Ni epicerie ni pharmacie.
      Shop(
        // OSM node/7902915054 — objet sans etiquette `name`
        name: 'Bar de Guitera-les-Bains (sans enseigne dans OpenStreetMap)',
        type: ShopKind.bar,
        stageNumber: 3,
        latitude: 41.913242,
        longitude: 9.085302,
        address: '20153 Guitera-les-Bains',
        products: ['Bar', 'Boissons'],
      ),
      Shop(
        name: 'Guitera-les-Bains — aucune epicerie relevee',
        type: ShopKind.epicerie,
        stageNumber: 3,
        latitude: 41.9143531,
        longitude: 9.0836797,
        products: [
          'Aucune epicerie et aucune pharmacie relevees dans OpenStreetMap',
          'Dernier ravitaillement : Cozzano, etape 2',
          'Prochaine epicerie : Porticcio, etape 7',
        ],
      ),

      // ====== ETAPE 4 — QUASQUARA ============================================
      // Releve OSM du 14/10/2026 : le village de Quasquara (20142) lui-meme ne
      // porte AUCUN commerce. Les trois enseignes ci-dessous sont reelles mais
      // dans les villages VOISINS, a environ un kilometre du point d'arrivee —
      // leur commune est donnee dans le nom pour que personne ne les croie sur
      // place.
      Shop(
        // OSM node/7902955478 — hameau de Vadi, commune de Frasseto
        name: 'Boucherie L\'alta strada (Frasseto, a 1 km)',
        type: ShopKind.epicerie,
        stageNumber: 4,
        latitude: 41.898871,
        longitude: 9.022481,
        address: 'Vadi, 20157 Frasseto',
        products: ['Viande et charcuterie corses'],
      ),
      Shop(
        // OSM node/7902915056 — hameau de Vadi, commune de Frasseto
        name: 'Bar a funtana (Frasseto, a 1,1 km)',
        type: ShopKind.bar,
        stageNumber: 4,
        latitude: 41.895820,
        longitude: 9.021812,
        address: 'Vadi, 20157 Frasseto',
        products: ['Bar', 'Boissons'],
      ),
      Shop(
        // OSM node/12101483405 — commune de Campo
        name: 'Cafe de la Poste (Campo, a 1,1 km)',
        type: ShopKind.bar,
        stageNumber: 4,
        latitude: 41.891979,
        longitude: 9.004229,
        address: '20142 Campo',
        products: ['Cafe / bar', 'Boissons'],
      ),
      Shop(
        name: 'Quasquara — aucun commerce dans le village',
        type: ShopKind.epicerie,
        stageNumber: 4,
        latitude: 41.9005724,
        longitude: 9.0100238,
        products: [
          'Aucun commerce releve dans OpenStreetMap a Quasquara meme',
          'Les plus proches sont a Frasseto et a Campo, a environ 1 km',
          'Prochaine epicerie : Porticcio, etape 7',
        ],
      ),

      // ====== ETAPE 5 — SANTA-MARIA-SICHE ====================================
      // Releve OSM du 14/10/2026 : un restaurant dans la commune de
      // Santa-Maria-Siche (20190), a 981 m du point d'arrivee de l'etape. Ni
      // epicerie ni pharmacie relevees.
      Shop(
        // OSM node/7106761294 — hameau de Canaso, Santa-Maria-Siche
        name: 'Restaurant U Fiumicellu (Santa-Maria-Siche)',
        type: ShopKind.bar,
        stageNumber: 5,
        latitude: 41.884135,
        longitude: 8.965307,
        address: 'Canaso, 20190 Santa-Maria-Siche',
        phone: '+33 4 95 25 78 38',
        products: ['Repas complets', 'Cuisine corse', 'Boissons'],
      ),
      Shop(
        name: 'Santa-Maria-Siche — aucune epicerie relevee',
        type: ShopKind.epicerie,
        stageNumber: 5,
        latitude: 41.8880952,
        longitude: 8.954724,
        products: [
          'Aucune epicerie et aucune pharmacie relevees dans OpenStreetMap',
          'On y mange, on ne s\'y ravitaille pas',
          'Prochaine epicerie : Porticcio, etape 7',
        ],
      ),

      // ====== ETAPE 6 — BISINAO ==============================================
      // Releve OSM du 14/10/2026 : un restaurant au hameau de Bisinao, commune
      // d'Albitreccia (20128), a 1,5 km du point d'arrivee. Rien d'autre.
      Shop(
        // OSM node/3612718790 — hameau de Bisinao, commune d'Albitreccia
        name: 'Restaurant A riserva di Bisina (Bisinao)',
        type: ShopKind.bar,
        stageNumber: 6,
        latitude: 41.839393,
        longitude: 8.869419,
        address: 'Bisinao, 20128 Albitreccia',
        products: ['Repas complets', 'Cuisine regionale', 'Boissons'],
      ),
      Shop(
        name: 'Bisinao — aucune epicerie relevee',
        type: ShopKind.epicerie,
        stageNumber: 6,
        latitude: 41.8507862,
        longitude: 8.8786054,
        products: [
          'Aucune epicerie et aucune pharmacie relevees dans OpenStreetMap',
          'Derniere nuit avant Porticcio : prevoir le repas ou reserver',
          'Prochaine epicerie : Porticcio, etape 7',
        ],
      ),

      // ====== ETAPE 7 — PORTICCIO (arrivee, golfe d'Ajaccio) =================
      // Releve OSM du 14/10/2026, commune de Grosseto-Prugna. Tout est a moins
      // de 450 m du point d'arrivee du sentier : supermarche, epiceries,
      // boulangerie et pharmacie.
      Shop(
        // OSM way/66843061
        name: 'Carrefour Market (Porticcio)',
        type: ShopKind.epicerie,
        stageNumber: 7,
        latitude: 41.887866,
        longitude: 8.803464,
        address: 'Les Marines de Porticcio, 20166 Grosseto-Prugna',
        website: 'https://www.carrefour.fr/magasin/market-marines-de-porticcio',
        products: [
          'Alimentation complete',
          'Fruits et legumes',
          'Boissons',
          'Tout ravitaillement retour',
        ],
        openingHours: 'Tous les jours 8h-20h',
      ),
      Shop(
        // OSM node/5978866588
        name: 'Epicerie U cintu (Porticcio)',
        type: ShopKind.epicerie,
        stageNumber: 7,
        latitude: 41.889403,
        longitude: 8.802388,
        address: '20166 Grosseto-Prugna',
        products: ['Alimentation de proximite', 'Boissons'],
      ),
      Shop(
        // OSM node/9198126817
        name: 'La Vie Claire (Porticcio)',
        type: ShopKind.epicerie,
        stageNumber: 7,
        latitude: 41.892463,
        longitude: 8.806534,
        address: 'Boulevard Rive Sud, 20166 Grosseto-Prugna',
        phone: '+33 4 95 72 08 67',
        products: [
          'Alimentation biologique',
          'Fruits secs / barres energetiques',
        ],
        openingHours: 'Lun-Sam 9h-13h puis 15h-19h30',
      ),
      Shop(
        // OSM node/11847455874
        name: 'Boulangerie Le Bon Pain de Purtichju (Porticcio)',
        type: ShopKind.epicerie,
        stageNumber: 7,
        latitude: 41.888579,
        longitude: 8.803174,
        address: '20166 Grosseto-Prugna',
        phone: '+33 4 95 23 29 38',
        products: ['Pain', 'Viennoiseries', 'Sandwichs'],
        openingHours: 'Lun-Ven 6h30-20h, Sam 7h-19h30, Dim 7h30-13h30',
      ),
      Shop(
        // OSM node/14023788301
        name: 'Aprium Pharmacie Neri (Porticcio)',
        type: ShopKind.pharmacie,
        stageNumber: 7,
        latitude: 41.888843,
        longitude: 8.803424,
        address: '20166 Grosseto-Prugna',
        products: [
          'Medicaments',
          'Soin des pieds / ampoules',
          'Materiel de premiers secours',
        ],
        openingHours:
            'Oct-Mai : Lun-Ven 8h30-19h30, Sam 8h30-19h. Juin-Sep : '
            'Lun-Sam 8h-20h, Dim et jours feries 9h-12h30 puis 15h-20h',
      ),
    ],
  );
}
