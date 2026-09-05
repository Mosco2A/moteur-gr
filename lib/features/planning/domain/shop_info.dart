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
/// HONNETETE DES DONNEES (regle Chris #99460) : quand une coordonnee, un horaire
/// ou un commerce precis n'est pas verifiable, on met une entree explicite « a
/// completer » (via [needsCompletion] / horaire « a completer ») PLUTOT qu'un
/// GPS ou un horaire faux. [latitude]/[longitude] sont alors laisses a `null`
/// (l'UI masque la ligne GPS au lieu d'afficher 0,0).
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
  });

  /// Nom du commerce (donnee du sentier).
  final String name;

  /// Type / famille (icone/couleur/libelle resolus cote widget).
  final ShopKind type;

  /// Numero de l'etape la plus proche (regroupement + calcul de gap).
  final int stageNumber;

  /// Produits / services disponibles (donnee du sentier). Peut etre vide.
  final List<String> products;

  /// Horaires d'ouverture indicatifs (donnee du sentier). Peut etre vide (ou
  /// « a completer » quand l'info n'est pas verifiee — honnetete #99460).
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
      products: (json['products'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      openingHours: json['openingHours'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      phone: json['phone'] as String? ?? '',
      website: json['website'] as String?,
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
    };
  }
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
  int? nextSupplyStageAfter(int stageNumber) {
    for (final s in supplyStages) {
      if (s > stageNumber) return s;
    }
    return null;
  }

  /// Ecart (« gap ») entre [stageNumber] et le prochain point de ravitaillement,
  /// en nombre d'etapes (parite GR20 : `nextShopStage - shop.stageNumber`).
  /// Retourne 0 s'il n'y a pas de prochain point (dernier commerce du sentier).
  int gapAfter(int stageNumber) {
    final next = nextSupplyStageAfter(stageNumber);
    return next != null ? next - stageNumber : 0;
  }

  /// Vrai si le gap apres [stageNumber] depasse le seuil d'alerte configure
  /// (parite GR20 : `gap > 2`). Sert a afficher l'alerte « gap » (carte + detail).
  bool isGapAlert(int stageNumber) => gapAfter(stageNumber) > gapThreshold;

  /// Desserialise depuis un JSON (backend / catalogue rapatrie). Les commerces
  /// invalides sont ignores plutot que de faire planter le chargement.
  factory TrailShops.fromJson(Map<String, dynamic> json) {
    return TrailShops(
      trailId: json['trailId'] as String? ?? '',
      shops: (json['shops'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(Shop.fromJson)
              .toList() ??
          const <Shop>[],
      gapThreshold: (json['gapThreshold'] as num?)?.toInt() ?? 2,
      limitedSupplyNote: json['limitedSupplyNote'] as String? ?? '',
    );
  }
}
