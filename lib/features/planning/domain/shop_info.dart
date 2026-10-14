/// Modele de donnees RAVITAILLEMENT d'un sentier (parite GR20
/// `ShopDetailScreen` + `Gr20Shop`, data-driven — regle « donnees en externe »
/// de Christophe #99460).
///
/// GR20 stocke ses commerces EN DUR (`const List<Gr20Shop> gr20Shops`, ~20
/// entrees de localites corses). Cote StepWays, le moteur reste GENERIQUE
/// multi-sentiers (#84627, #99460) : les commerces ne sont PAS codes en dur dans
/// le moteur mais fournis en DONNEE, par sentier (`trailId`). Le backend
/// (Phase 4) remplacera le catalogue embarque par le contenu reel rapatrie dans
/// le pack — meme principe que [TrailTransport] / les town guides.
///
/// Modele PUR (aucune dependance Flutter/Slang) : les libelles d'INTERFACE
/// (titres de section, filtres, alertes) sont resolus cote UI via Slang
/// (5 langues) ; les DONNEES propres au sentier (noms de commerces, produits,
/// horaires) restent dans la langue de la donnee. Le TYPE de commerce est une
/// CLE stable ([ShopKind]) resolue en `IconData`/`Color`/libelle cote widget
/// (le domaine ne connait pas Material) — parite GR20 `ShopType`.
library;

/// Type / famille de commerce — CLE stable, resolue en icone/couleur/libelle
/// cote UI (parite GR20 `enum ShopType`).
///
/// Le widget mappe chaque valeur vers un `IconData` et une couleur semantique
/// (parite GR20 : `Icons.shopping_cart`, `Icons.restaurant`...) et vers un
/// libelle traduit (Slang). Une valeur inconnue retombe sur [epicerie] cote
/// desserialisation (aucun crash, tolerant a un futur catalogue serveur).
enum ShopKind {
  /// Epicerie / alimentation generale (parite GR20 `ShopType.epicerie`).
  epicerie,

  /// Bar / restaurant / snack (parite GR20 `ShopType.bar`).
  bar,

  /// Pharmacie (parite GR20 `ShopType.pharmacie`).
  pharmacie,

  /// Point de vente gaz / materiel de randonnee (parite GR20 `ShopType.gaz`).
  gaz,
}

/// Un COMMERCE / point de ravitaillement (parite GR20 `Gr20Shop`).
///
/// Porte les memes champs que le modele GR20 : nom, type, coordonnees GPS,
/// numero d'etape la plus proche, produits/services disponibles, horaires
/// indicatifs. ETENDU (optionnel, non presents dans GR20) : [phone] et [website]
/// — cables `url_launcher` (tel:/site) cote UI comme sur Transport quand ils
/// sont renseignes, sinon masques. Aucun texte d'INTERFACE ici : ce sont des
/// DONNEES du sentier (langue de la donnee).
///
/// HONNETETE DES DONNEES (regle Chris #99460) : quand une coordonnee ou un
/// horaire precis n'est pas verifiable, ON NE L'ECRIT PAS — ni faux, ni marque.
/// [latitude]/[longitude] restent a `null` et l'UI masque la ligne GPS au lieu
/// d'afficher un 0,0 qui est un point reel au large de l'Afrique ;
/// [openingHours] reste vide et la ligne d'horaire disparait.
///
/// CE PARAGRAPHE DISAIT L'INVERSE JUSQU'AU LOT 645-08, et il faut le dire ici
/// pour que personne ne retablisse l'ancienne regle de bonne foi : il
/// prescrivait « une entree explicite a completer plutot qu'un horaire faux »,
/// et renvoyait a un `needsCompletion` qui n'a jamais existe sur ce modele. Le
/// marqueur evitait le mensonge et gardait le bruit : onze commerces du Mare a
/// Mare Centre montraient au randonneur, sous une icone d'horloge, un mot
/// destine a l'editeur. Christophe a tranche le 02/10/2026 (voie V2) : le champ
/// absent n'affiche RIEN — pas de tiret, pas de « non renseigne », pas
/// d'espace reserve, la ligne disparait.
class Shop {
  const Shop({
    required this.name,
    required this.type,
    required this.stageNumber,
    this.products = const <String>[],
    this.openingHours = '',
    this.latitude,
    this.longitude,
    this.phone = '',
    this.website,
    this.address,
    this.providesResupply = false,
  });

  /// Nom du commerce (donnee du sentier).
  final String name;

  /// Type / famille (icone/couleur/libelle resolus cote widget).
  final ShopKind type;

  /// Numero de l'etape la plus proche (regroupement + calcul de gap).
  final int stageNumber;

  /// Produits / services disponibles (donnee du sentier). Peut etre vide.
  final List<String> products;

  /// Horaires d'ouverture indicatifs (donnee du sentier).
  ///
  /// VIDE QUAND ON NE LES CONNAIT PAS, et jamais autre chose (lot 645-08, voie
  /// V2) : ni « a completer », ni un tiret, ni un espace. C'est le vide, et lui
  /// seul, que `shop_screen.dart` reconnait pour ne construire NI l'icone
  /// d'horloge, NI le libelle « Horaires », NI la valeur a cote — aux deux
  /// endroits ou il les montre, l'apercu de la carte et la fiche detail.
  final String openingHours;

  /// Latitude WGS84, ou `null` si non verifiee (honnetete #99460 : on ne met
  /// pas un 0,0 faux). L'UI masque alors la ligne GPS.
  final double? latitude;

  /// Longitude WGS84, ou `null` si non verifiee (honnetete #99460).
  final double? longitude;

  /// Telephone (tel:), extension StepWays absente de GR20. Vide = pas de contact
  /// (l'UI masque le bloc). Format national/international.
  final String phone;

  /// Site web optionnel (extension StepWays), ouvert en application externe.
  /// Null/vide = pas de bouton site.
  final String? website;

  /// ADRESSE POSTALE (nullable, tache 641, bug 15).
  ///
  /// « appliquer la meme regle a tout lieu physique (ravitaillement, point d eau,
  /// depart/arrivee, transport) : une adresse + un point GPS cliquable partout ou
  /// il y a un lieu » (Christophe, 30/09 10:23). Un commerce dont on connait
  /// l adresse mais pas les coordonnees exactes se rejoint par l adresse — et
  /// c est le cas le plus frequent dans les villages corses.
  final String? address;

  /// VRAI QUAND ON PEUT REFAIRE SES VIVRES ICI (tache 834).
  ///
  /// POURQUOI CE CHAMP EXISTE, ET POURQUOI [type] NE SUFFISAIT PAS. L'alerte de
  /// la carte doit repondre a UNE question : « a combien d'etapes est le
  /// prochain endroit ou je peux recharger mon sac ? ». Trois raisons
  /// interdisent de la deduire du seul [type] :
  ///
  ///  1. UNE ENTREE QUI CONSTATE UNE ABSENCE PORTE UN TYPE. « Guitera-les-Bains
  ///     — aucune epicerie relevee » est rangee en [ShopKind.epicerie] parce
  ///     que c'est sous le filtre « Epicerie » que le randonneur doit trouver
  ///     (tache 844). Compter son type comme un ravitaillement, c'est compter
  ///     une absence comme une presence : l'alerte se taisait PRECISEMENT la ou
  ///     elle devait parler.
  ///  2. UN BAR N'EST PAS UN RAVITAILLEMENT. On y mange une fois ; on n'en
  ///     repart pas avec trois jours de vivres. L'application de reference
  ///     (Fra li Monti) comptait bar, pharmacie et point gaz comme des
  ///     ravitaillements : une pharmacie y suffisait a eteindre l'alerte.
  ///  3. UN COMMERCE A UN KILOMETRE, DANS UNE AUTRE COMMUNE, N'EST PAS SUR LE
  ///     CHEMIN. C'est une option, pas un ravitaillement qu'on planifie.
  ///
  /// LE DEFAUT EST `false`, ET C'EST VOULU : un catalogue qui ne dit rien
  /// ne declenche AUCUNE alerte (l'ecart devient nul, cf. [TrailShops.gapAfter]
  /// et [TrailShops.resupplyGapAfter]). L'alerte ne s'invente pas — elle
  /// n'apparait que sur une donnee qui l'affirme.
  final bool providesResupply;

  /// Vrai si des coordonnees GPS exploitables sont disponibles.
  bool get hasCoordinates => latitude != null && longitude != null;

  /// Vrai si un contact telephonique est disponible.
  bool get hasPhone => phone.isNotEmpty;

  /// Vrai si un site web est disponible (bouton « site » affiche).
  bool get hasWebsite => website != null && website!.isNotEmpty;

  /// Vrai si des produits sont listes.
  bool get hasProducts => products.isNotEmpty;

  /// Desserialise un [Shop] depuis un JSON (backend / catalogue rapatrie).
  ///
  /// Tolerant : un `type` inconnu retombe sur [ShopKind.epicerie] (aucun crash,
  /// parite GR20 `Gr20Shop.fromJson`). GPS absents -> `null` (honnetete #99460).
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      name: json['name'] as String? ?? '',
      type: ShopKind.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ShopKind.epicerie,
      ),
      stageNumber: (json['stageNumber'] as num?)?.toInt() ?? 0,
      products:
          (json['products'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      openingHours: json['openingHours'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String?,
      address: json['address'] as String?,
      providesResupply: json['providesResupply'] as bool? ?? false,
    );
  }

  /// Serialise en JSON (cache / debug).
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'stageNumber': stageNumber,
      'products': products,
      'openingHours': openingHours,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (phone.isNotEmpty) 'phone': phone,
      if (website != null) 'website': website,
      if (address != null) 'address': address,
      if (providesResupply) 'providesResupply': true,
    };
  }
}

/// La prochaine etape, STRICTEMENT apres [stageNumber], qui porte le point
/// cherche — ou `null` quand il n'y en a plus (tache 834).
///
/// [pointStages] est l'ensemble des numeros d'etape qui portent le point : des
/// epiceries pour la nourriture, des points d'eau pour l'eau. Il n'a pas besoin
/// d'etre trie.
int? nextStageWithPointAfter(Iterable<int> pointStages, int stageNumber) {
  int? next;
  for (final s in pointStages) {
    if (s > stageNumber && (next == null || s < next)) next = s;
  }
  return next;
}

/// L'ecart, EN NOMBRE D'ETAPES, entre [stageNumber] et le prochain point.
/// Vaut 0 quand il n'y a plus de point apres — le dernier du sentier n'ouvre
/// pas un trou, il ferme la liste (tache 834).
///
/// UNE SEULE IMPLEMENTATION POUR LES DEUX SUJETS, et c'est le correctif : dans
/// l'application de reference ce calcul etait ecrit DEUX FOIS, dans un service
/// et dans un ecran, avec DEUX seuils differents (`gap < 2` sur la carte,
/// `gap > 2` sur l'ecran ravitaillement). Deux copies divergent toujours.
int stageGapToNextPoint(Iterable<int> pointStages, int stageNumber) {
  final next = nextStageWithPointAfter(pointStages, stageNumber);
  return next != null ? next - stageNumber : 0;
}

/// Donnees RAVITAILLEMENT COMPLETES d'un sentier (parite GR20 `gr20Shops` +
/// `SupplyAlertService`).
///
/// Rattachees a un [trailId] (genericite #84627). Fournit la liste des commerces
/// du sentier et la logique de calcul de « gap » de ravitaillement (nombre
/// d'etapes sans commerce avant le prochain point), GENERIQUE et sans hardcode.
/// Le [gapThreshold] est configurable par sentier (defaut raisonnable = 2,
/// parite GR20 ou l'alerte se declenche pour un ecart > 2). Le contenu est
/// consultable 100 % OFFLINE (embarque, comme les town guides / le transport).
class TrailShops {
  const TrailShops({
    required this.trailId,
    this.shops = const <Shop>[],
    this.gapThreshold = 2,
    this.waterGapThreshold = 1,
    this.limitedSupplyNote = '',
  });

  /// Identifiant du sentier.
  final String trailId;

  /// Commerces du sentier (donnee, non hardcodee dans le moteur).
  final List<Shop> shops;

  /// Seuil de gap : au-dela de ce nombre d'etapes sans commerce, l'alerte « gap »
  /// s'affiche sur la carte / le detail (parite GR20 : `gap > 2`). Configurable
  /// par sentier pour rester generique (un sentier tres desservi peut le relever,
  /// un sentier isole l'abaisser).
  final int gapThreshold;

  /// SEUIL DE L'EAU, ET IL EST PLUS SEVERE QUE CELUI DE LA NOURRITURE
  /// (tache 834). Au-dela de ce nombre d'etapes sans point d'eau, l'alerte de
  /// la carte parle. Defaut `1` : DEUX etapes sans eau alertent, la ou il faut
  /// TROIS etapes sans epicerie ([gapThreshold] = 2) pour le meme bruit.
  ///
  /// POURQUOI DEUX SEUILS ET PAS UN. « Un trou d'eau de deux etapes est plus
  /// grave qu'un trou de nourriture de deux etapes » (Christophe, 14/10/2026).
  /// On marche trois jours sur ses reserves de nourriture ; on ne marche pas
  /// deux jours sans boire. En Corse au mois d'aout, c'est le trou d'eau qui
  /// declenche les secours — pas le trou d'epicerie.
  ///
  /// IL VIT DANS LA DONNEE DU SENTIER, comme [gapThreshold] : un sentier de
  /// crete sans source l'abaisse a zero (toute etape sans eau alerte), un
  /// sentier de vallee le releve. Le moteur ne decide pas a la place de la
  /// donnee.
  final int waterGapThreshold;

  /// Message d'avertissement « ravitaillement limite » PROPRE AU SENTIER (parite
  /// GR20 : « Seulement 8 points sur 180 km... »), en langue de la donnee.
  ///
  /// DATA-DRIVEN (#99460) : cote StepWays ce texte n'est PAS code en dur dans le
  /// moteur — il vient de la donnee du sentier. Vide => le bandeau d'alerte est
  /// masque proprement (pas de « 8 points sur 180 km » invente).
  final String limitedSupplyNote;

  /// Vrai s'il y a au moins un commerce (sinon l'ecran affiche un fallback).
  bool get hasShops => shops.isNotEmpty;

  /// Vrai si un message d'avertissement « ravitaillement limite » est fourni.
  bool get hasLimitedSupplyNote => limitedSupplyNote.isNotEmpty;

  /// Etapes UNIQUES portant au moins un commerce, triees (parite GR20
  /// `SupplyAlertService.supplyStages`). Source unique pour le calcul de gap.
  List<int> get supplyStages {
    final stages = shops.map((s) => s.stageNumber).toSet().toList()..sort();
    return stages;
  }

  /// Commerces d'une etape donnee (parite GR20 `shopsForStage`).
  List<Shop> shopsForStage(int stageNumber) =>
      shops.where((s) => s.stageNumber == stageNumber).toList();

  /// Numero de la prochaine etape (strictement) apres [stageNumber] portant un
  /// commerce, ou `null` si c'est le dernier point de ravitaillement du sentier
  /// (parite GR20 `_findNextShopStage`).
  int? nextSupplyStageAfter(int stageNumber) =>
      nextStageWithPointAfter(supplyStages, stageNumber);

  /// Ecart (« gap ») entre [stageNumber] et le prochain point de ravitaillement,
  /// en nombre d'etapes (parite GR20 : `nextShopStage - shop.stageNumber`).
  /// Retourne 0 s'il n'y a pas de prochain point (dernier commerce du sentier).
  int gapAfter(int stageNumber) =>
      stageGapToNextPoint(supplyStages, stageNumber);

  /// Vrai si le gap apres [stageNumber] depasse le seuil d'alerte configure
  /// (parite GR20 : `gap > 2`). Sert a afficher l'alerte « gap » (carte + detail).
  bool isGapAlert(int stageNumber) => gapAfter(stageNumber) > gapThreshold;

  /// Etapes ou l'on peut REELLEMENT refaire ses vivres, triees (tache 834).
  ///
  /// Ne retient que les entrees qui le declarent ([Shop.providesResupply]) :
  /// ni les bars, ni les pharmacies, ni les constats d'absence, ni les
  /// commerces d'une commune voisine. C'est la difference entre « on mange
  /// partout » et « on se ravitaille ici », et c'est celle qui compte quand on
  /// charge son sac.
  List<int> get resupplyStages {
    final stages =
        shops
            .where((s) => s.providesResupply)
            .map((s) => s.stageNumber)
            .toSet()
            .toList()
          ..sort();
    return stages;
  }

  /// Ecart, en nombre d'etapes, entre [stageNumber] et le prochain endroit ou
  /// l'on peut refaire ses vivres. Vaut 0 apres le dernier (tache 834).
  int resupplyGapAfter(int stageNumber) =>
      stageGapToNextPoint(resupplyStages, stageNumber);

  /// Vrai si le trou de RAVITAILLEMENT apres [stageNumber] depasse
  /// [gapThreshold] (tache 834).
  bool isResupplyGapAlert(int stageNumber) =>
      resupplyGapAfter(stageNumber) > gapThreshold;

  /// Ecart, en nombre d'etapes, entre [stageNumber] et la prochaine etape
  /// portant un point d'eau. [waterStages] vient des POI du sentier, pas de ce
  /// catalogue : l'eau n'est pas un commerce (tache 834).
  int waterGapAfter(int stageNumber, Iterable<int> waterStages) =>
      stageGapToNextPoint(waterStages, stageNumber);

  /// Vrai si le trou d'EAU apres [stageNumber] depasse [waterGapThreshold]
  /// (tache 834).
  bool isWaterGapAlert(int stageNumber, Iterable<int> waterStages) =>
      waterGapAfter(stageNumber, waterStages) > waterGapThreshold;

  /// Desserialise depuis un JSON (backend / catalogue rapatrie). Les commerces
  /// invalides sont ignores plutot que de faire planter le chargement.
  factory TrailShops.fromJson(Map<String, dynamic> json) {
    return TrailShops(
      trailId: json['trailId'] as String? ?? '',
      shops:
          (json['shops'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Shop.fromJson)
              .toList() ??
          const <Shop>[],
      gapThreshold: (json['gapThreshold'] as num?)?.toInt() ?? 2,
      waterGapThreshold: (json['waterGapThreshold'] as num?)?.toInt() ?? 1,
      limitedSupplyNote: json['limitedSupplyNote'] as String? ?? '',
    );
  }
}
