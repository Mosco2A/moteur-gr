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
/// HONNETETE DES DONNEES (regle Chris #99460) : les commerces listes sont ceux
/// des localites-etapes reellement traversees par le Mare a Mare Centre
/// (Ghisonaccia -> Porticcio). Quand un HORAIRE precis n'est pas verifiable, on
/// met « a completer » plutot qu'un horaire faux ; quand une COORDONNEE GPS
/// precise du commerce n'est pas verifiee, on rattache l'entree au centre de la
/// localite-etape (coordonnees d'etape verifiees du sentier) ET on le signale,
/// plutot que d'inventer un point GPS a la rue pres. AUCUN commerce corse du
/// GR20 (Calenzana, Vizzavona, Conca...) n'est recopie ici : ce sont d'autres
/// localites.
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
  // Localites-etapes (assets/data/mare_a_mare_centre/stages.json) :
  //   1 Ghisonaccia -> Catastaghju        (depart cote est, ville : Super U /
  //                                         Casino / pharmacie — RN198/T10)
  //   2 Catastaghju -> Cozzano            (Cozzano : epicerie, restaurants)
  //   3 Cozzano -> Guitera-les-Bains      (petit hameau thermal)
  //   4 Guitera-les-Bains -> Zicavo       (Zicavo : epicerie/tabac/gaz, bar,
  //                                         restaurant, hotels)
  //   5 Zicavo -> Cuttoli-Corticchiato    (village peri-ajaccien)
  //   6 Cuttoli-Corticchiato -> Bastelica (Bastelica : Proxi, restaurants/bars)
  //   7 Bastelica -> Porticcio            (arrivee, station balneaire : tous
  //                                         commerces et services)
  //
  // Les coordonnees rattachees a chaque commerce sont celles du CENTRE de la
  // localite-etape (endpoints d'etape verifies du sentier : startLat/startLng
  // ou endLat/endLng des etapes), l'adresse exacte a la rue n'etant pas
  // verifiee -> honnetete #99460 (pas de GPS invente au metre pres).
  // ==========================================================================
  static const TrailShops _mareAMareCentre = TrailShops(
    trailId: 'mare-a-mare-centre',
    // Seuil de gap parite GR20 (alerte si plus de 2 etapes sans commerce).
    gapThreshold: 2,
    // Message « ravitaillement limite » PROPRE AU SENTIER, en langue de la
    // donnee (data-driven #99460, pas de chiffre GR20 en dur). Ici, les etapes 3
    // et 5 (Guitera, Cuttoli) sont des points faibles a signaler.
    limitedSupplyNote:
        'Ravitaillement inegal sur le Mare a Mare Centre : Ghisonaccia (depart) '
        'et Porticcio/Ajaccio (arrivee) offrent tous les commerces, mais les '
        'villages intermediaires ont peu ou pas d\'epicerie. Faites vos courses '
        'a Ghisonaccia, Cozzano et Zicavo, et prevoyez 1 a 2 jours d\'autonomie '
        'entre ces points.',
    shops: [
      // ====== ETAPE 1 — GHISONACCIA (depart, cote est) =======================
      // Ville de la plaine orientale : commerces verifies (Super U, Casino,
      // pharmacie sur la RN198 / T10). GPS = centre-ville / depart d'etape.
      Shop(
        name: 'Supermarche Super U (Ghisonaccia)',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 42.0156,
        longitude: 9.4039,
        products: [
          'Alimentation complete',
          'Fruits et legumes',
          'Pain / boulangerie',
          'Boissons',
          'Cartouches de gaz (rayon camping, selon stock)',
          'Piles / batteries',
        ],
        openingHours: 'Horaires de supermarche (a verifier sur place)',
      ),
      Shop(
        name: 'Supermarche Casino (Ghisonaccia)',
        type: ShopKind.epicerie,
        stageNumber: 1,
        latitude: 42.0156,
        longitude: 9.4039,
        products: [
          'Alimentation generale',
          'Produits frais',
          'Boissons',
          'Depannage randonnee',
        ],
        openingHours: 'Horaires de supermarche (a verifier sur place)',
      ),
      Shop(
        name: 'Pharmacie de Ghisonaccia',
        type: ShopKind.pharmacie,
        stageNumber: 1,
        latitude: 42.0156,
        longitude: 9.4039,
        products: [
          'Medicaments',
          'Pansements / Compeed',
          'Creme solaire',
          'Anti-moustiques',
          'Sels de rehydratation',
        ],
        openingHours: 'Horaires d\'officine (a completer)',
      ),

      // ====== ETAPE 2 — COZZANO (haute vallee du Taravo) =====================
      // Village anime en saison : epicerie + restaurants (verifie). GPS = centre
      // du village (arrivee d'etape 2).
      Shop(
        name: 'Epicerie de Cozzano',
        type: ShopKind.epicerie,
        stageNumber: 2,
        latitude: 41.9392,
        longitude: 9.1978,
        products: [
          'Alimentation de base',
          'Pain',
          'Boissons',
          'Produits corses',
        ],
        openingHours: 'Ouvert en saison (horaires a completer)',
      ),
      Shop(
        name: 'Restaurant / gite d\'etape (Cozzano)',
        type: ShopKind.bar,
        stageNumber: 2,
        latitude: 41.9392,
        longitude: 9.1978,
        products: [
          'Repas complets',
          'Cuisine corse',
          'Petit-dejeuner (pour les hebergés)',
          'Boissons',
        ],
        openingHours: 'Service du soir en saison (a completer)',
      ),

      // ====== ETAPE 3 — GUITERA-LES-BAINS (petit hameau thermal) =============
      // Peu de commerce : entree honnete « a completer », GPS = centre du hameau
      // (arrivee d'etape 3). On NE INVENTE PAS d'epicerie non verifiee.
      Shop(
        name: 'Guitera-les-Bains — ravitaillement a verifier',
        type: ShopKind.epicerie,
        stageNumber: 3,
        latitude: 41.9147,
        longitude: 9.1411,
        products: [
          'Commerce non confirme sur place',
          'Prevoir un ravitaillement a Cozzano ou Zicavo',
        ],
        openingHours: 'a completer',
      ),

      // ====== ETAPE 4 — ZICAVO (coeur du Taravo, etape GR20) =================
      // Village dynamique : epicerie/tabac/presse/gaz, bar, restaurant, hotels
      // (verifie). GPS = centre du village (arrivee d'etape 4).
      Shop(
        name: 'Epicerie-Tabac A Traversa (Zicavo)',
        type: ShopKind.epicerie,
        stageNumber: 4,
        latitude: 41.8947,
        longitude: 9.0958,
        products: [
          'Alimentation generale',
          'Pain',
          'Boissons',
          'Tabac / presse',
          'Cartouches de gaz',
          'Depannage randonnee',
        ],
        openingHours: 'Commerce de proximite, ouvert a l\'annee (a confirmer)',
      ),
      Shop(
        name: 'Bar-Restaurant de Zicavo',
        type: ShopKind.bar,
        stageNumber: 4,
        latitude: 41.8947,
        longitude: 9.0958,
        products: [
          'Repas / plats du jour',
          'Cuisine corse',
          'Bar',
          'Boissons fraiches',
        ],
        openingHours: 'Service en saison (a completer)',
      ),

      // ====== ETAPE 5 — CUTTOLI-CORTICCHIATO (village peri-ajaccien) =========
      // Commerce non verifie precisement : entree honnete, GPS = centre
      // (arrivee d'etape 5). Ajaccio et sa peripherie sont proches en voiture.
      Shop(
        name: 'Cuttoli-Corticchiato — ravitaillement a verifier',
        type: ShopKind.epicerie,
        stageNumber: 5,
        latitude: 41.9283,
        longitude: 9.0086,
        products: [
          'Commerce de village non confirme',
          'Peripherie d\'Ajaccio proche (supermarches en voiture)',
        ],
        openingHours: 'a completer',
      ),

      // ====== ETAPE 6 — BASTELICA (vallee du Prunelli) =======================
      // Alimentation de depannage (Proxi) + plusieurs bars/restaurants/snacks
      // (verifie). GPS = centre du village (arrivee d'etape 6).
      Shop(
        name: 'Alimentation Proxi (Bastelica)',
        type: ShopKind.epicerie,
        stageNumber: 6,
        latitude: 42.0028,
        longitude: 9.0694,
        products: [
          'Alimentation de depannage',
          'Pain',
          'Boissons',
          'Produits de base',
        ],
        openingHours: 'Commerce de proximite (horaires a completer)',
      ),
      Shop(
        name: 'Snack-Bar Sampiero (Bastelica)',
        type: ShopKind.bar,
        stageNumber: 6,
        latitude: 42.0028,
        longitude: 9.0694,
        products: [
          'Petit-dejeuner',
          'Restauration rapide',
          'Bar',
          'Boissons',
        ],
        openingHours: 'Ouvert a l\'annee (horaires a completer)',
      ),
      Shop(
        name: 'Auberge U Pontu (Bastelica)',
        type: ShopKind.bar,
        stageNumber: 6,
        latitude: 42.0028,
        longitude: 9.0694,
        products: [
          'Repas complets',
          'Cuisine corse traditionnelle',
          'Charcuterie de Bastelica',
        ],
        openingHours: 'Service en saison (a completer)',
      ),

      // ====== ETAPE 7 — PORTICCIO (arrivee, golfe d'Ajaccio) =================
      // Station balneaire : tous commerces et services (supermarche, pharmacie).
      // GPS = arrivee du sentier (etape 7). Ajaccio complete l'offre a proximite.
      Shop(
        name: 'Supermarche de Porticcio',
        type: ShopKind.epicerie,
        stageNumber: 7,
        latitude: 41.8903,
        longitude: 8.8128,
        products: [
          'Alimentation complete',
          'Fruits et legumes',
          'Boissons',
          'Tout ravitaillement retour',
        ],
        openingHours: 'Horaires de supermarche (a verifier sur place)',
      ),
      Shop(
        name: 'Pharmacie de Porticcio',
        type: ShopKind.pharmacie,
        stageNumber: 7,
        latitude: 41.8903,
        longitude: 8.8128,
        products: [
          'Medicaments',
          'Soin des pieds / ampoules',
          'Creme solaire',
          'Materiel de premiers secours',
        ],
        openingHours: 'Horaires d\'officine (a completer)',
      ),
      Shop(
        name: 'Bars & restaurants de la plage (Porticcio)',
        type: ShopKind.bar,
        stageNumber: 7,
        latitude: 41.8903,
        longitude: 8.8128,
        products: [
          'Restauration',
          'Bar / glaces',
          'Boissons fraiches',
          'Celebrer l\'arrivee face au golfe !',
        ],
        openingHours: 'Ouvert en saison (a completer)',
      ),
    ],
  );
}
