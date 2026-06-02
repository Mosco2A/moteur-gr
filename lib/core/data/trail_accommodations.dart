/// Tous les hébergements le long d'un sentier.
/// Consolide refuges PNRC, bergeries, gites, hotels et campings.
///
/// Chaque hébergement est associe a un ou plusieurs modes de confort
/// (baroudeur, standard, confort, premium).
class TrailAccommodation {
  const TrailAccommodation({
    required this.trailId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.stageNumber,
    required this.priceRange,
    required this.amenities,
    required this.comfortModes,
    this.phone,
    this.email,
  });

  /// Identifiant du sentier (ex: 'gr20', 'tmb', 'hrp').
  final String trailId;

  /// Nom de l'hébergement.
  final String name;

  /// Type d'hébergement.
  final AccommodationType type;

  /// Latitude WGS84.
  final double latitude;

  /// Longitude WGS84.
  final double longitude;

  /// Altitude en metres.
  final int altitude;

  /// Numero de l'étape GR20 (fin d'étape).
  final int stageNumber;

  /// Fourchette de prix (ex: "7-14 EUR").
  final String priceRange;

  /// Numero de téléphone.
  final String? phone;

  /// Adresse email de contact.
  final String? email;

  /// Liste des équipements (douche, repas, électricité, etc.).
  final List<String> amenities;

  /// Modes de confort compatibles.
  final List<ComfortMode> comfortModes;

  /// Deserialise un TrailAccommodation depuis un JSON (Firebase Storage).
  factory TrailAccommodation.fromJson(Map<String, dynamic> json) {
    return TrailAccommodation(
      trailId: json['trailId'] as String? ?? '',
      name: json['name'] as String,
      type: AccommodationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => AccommodationType.refuge,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] as int,
      stageNumber: json['stageNumber'] as int,
      priceRange: json['priceRange'] as String,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      amenities: (json['amenities'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      comfortModes: (json['comfortModes'] as List<dynamic>)
          .map((e) => ComfortMode.values.firstWhere(
                (m) => m.name == e,
                orElse: () => ComfortMode.standard,
              ))
          .toList(),
    );
  }

  /// Serialise en JSON pour le cache Hive.
  Map<String, dynamic> toJson() {
    return {
      'trailId': trailId,
      'name': name,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'stageNumber': stageNumber,
      'priceRange': priceRange,
      'phone': phone,
      'email': email,
      'amenities': amenities,
      'comfortModes': comfortModes.map((m) => m.name).toList(),
    };
  }
}

/// Types d'hébergement.
enum AccommodationType {
  refuge,
  bergerie,
  gite,
  hotel,
  camping,
  bivouac,
}

/// Modes de confort (du plus spartiate au plus confortable).
enum ComfortMode {
  /// Bivouac / tente, autonomie complete.
  baroudeur,

  /// Refuge, dortoir collectif.
  standard,

  /// Bergerie / gite, un peu plus de confort.
  confort,

  /// Hotel, chambre privee, restaurant.
  premium,
}

/// Hébergements GR20 (Nord → Sud) — données de référence.
/// D'autres sentiers ajouteront leurs propres listes via le même modèle.
const List<TrailAccommodation> gr20Accommodations = [
  // ====== ETAPE 1 : Calenzana → Ortu di u Piobbu ======
  // B60v3: coords verifiees refuges.info + Google Maps
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge d\'Ortu di u Piobbu',
    type: AccommodationType.refuge,
    latitude: 42.4653,
    longitude: 8.9069,
    altitude: 1520,
    stageNumber: 1,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité', 'WC'],
    comfortModes: [ComfortMode.standard],
  ),
  // B60v3: bivouac pres du refuge
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Ortu di u Piobbu',
    type: AccommodationType.bivouac,
    latitude: 42.4651,
    longitude: 8.9071,
    altitude: 1520,
    stageNumber: 1,
    priceRange: '7 EUR',
    amenities: ['Aire amenagee', 'WC (refuge)', 'Douche (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 2 : Ortu di u Piobbu → Carrozzu ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Carrozzu',
    type: AccommodationType.refuge,
    // B60v4: confirme mapcarta + corse-randos + gr20-infos
    latitude: 42.4261,
    longitude: 8.9004,
    altitude: 1270,
    stageNumber: 2,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Carrozzu',
    type: AccommodationType.bivouac,
    // B60v4: pres du refuge Carrozzu
    latitude: 42.4259,
    longitude: 8.9006,
    altitude: 1270,
    stageNumber: 2,
    priceRange: '7 EUR',
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 3 : Carrozzu → Haut-Asco ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de l\'Asco Stagnu',
    type: AccommodationType.refuge,
    latitude: 42.4035,
    longitude: 8.9223,
    altitude: 1422,
    stageNumber: 3,
    priceRange: '14 EUR',
    phone: '04 95 47 82 04',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Hotel Le Chalet (Haut-Asco)',
    type: AccommodationType.hotel,
    latitude: 42.4033,
    longitude: 8.9236,
    altitude: 1450,
    stageNumber: 3,
    priceRange: '60-90 EUR',
    phone: '04 95 47 81 08',
    amenities: ['Chambre privee', 'Douche', 'Restaurant', 'Bar', 'Électricité', 'Wi-Fi'],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Camping Haut-Asco',
    type: AccommodationType.camping,
    latitude: 42.4030,
    longitude: 8.9230,
    altitude: 1440,
    stageNumber: 3,
    priceRange: '8-10 EUR',
    amenities: ['Emplacements', 'WC', 'Douche'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 4 : Haut-Asco → Tighjettu ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Tighjettu',
    type: AccommodationType.refuge,
    // B60v2: coords verifiees Google Maps / corse-randos (42.3623, 8.9088)
    latitude: 42.3623,
    longitude: 8.9088,
    altitude: 1683,
    stageNumber: 4,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Tighjettu',
    type: AccommodationType.bivouac,
    // B60v2: pres du refuge Tighjettu
    latitude: 42.3621,
    longitude: 8.9091,
    altitude: 1683,
    stageNumber: 4,
    priceRange: '7 EUR',
    amenities: ['Aire amenagee (limitee)', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 5 : Tighjettu → Ciottulu di i Mori ======
  // B60v4: confirme Wikipedia + corse-randos + gr20-infos
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Ciottulu di i Mori',
    type: AccommodationType.refuge,
    latitude: 42.3350,
    longitude: 8.8680,
    altitude: 1991,
    stageNumber: 5,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité', 'Vue panoramique'],
    comfortModes: [ComfortMode.standard],
  ),
  // B60v4: confirme Booking.com + trip.com + le-gr20.fr (42.2875, 8.8919)
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Hotel Castel di Vergio',
    type: AccommodationType.hotel,
    latitude: 42.2875,
    longitude: 8.8919,
    altitude: 1404,
    stageNumber: 5,
    priceRange: '70-120 EUR',
    phone: '04 95 48 00 01',
    amenities: ['Chambre privee', 'Douche', 'Restaurant', 'Bar', 'Piscine', 'Électricité'],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),

  // ====== ETAPE 6 : Ciottulu → Manganu ======
  // B60v3: coords verifiees
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Manganu',
    type: AccommodationType.refuge,
    latitude: 42.2199,
    longitude: 8.9804,
    altitude: 1601,
    stageNumber: 6,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bergerie de Vaccaghja',
    type: AccommodationType.bergerie,
    // B60v3: coords verifiees corse-randos + objectif-gr20
    latitude: 42.2368,
    longitude: 8.9742,
    altitude: 1621,
    stageNumber: 6,
    priceRange: '25-35 EUR',
    amenities: ['Dortoir rustique', 'Repas corses', 'Fromage maison'],
    comfortModes: [ComfortMode.confort],
  ),
  // B60v3: bivouac pres du refuge Manganu
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Manganu',
    type: AccommodationType.bivouac,
    latitude: 42.2197,
    longitude: 8.9806,
    altitude: 1601,
    stageNumber: 6,
    priceRange: '7 EUR',
    amenities: ['Aire plate', 'WC (refuge)', 'Vue lac de Ninu'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 7 : Manganu → Petra Piana ======
  // B60v3: coords verifiees
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Petra Piana',
    type: AccommodationType.refuge,
    latitude: 42.1981,
    longitude: 9.0523,
    altitude: 1842,
    stageNumber: 7,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité', 'Vue exceptionnelle'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bergeries de Grotelle',
    type: AccommodationType.bergerie,
    // B60v3: coords verifiees wikiloc + gps-viewer + corse-randos
    latitude: 42.2290,
    longitude: 9.0305,
    altitude: 1370,
    stageNumber: 7,
    priceRange: '20-30 EUR',
    amenities: ['Dortoir', 'Repas corses'],
    comfortModes: [ComfortMode.confort],
  ),

  // ====== ETAPE 8 : Petra Piana → l'Onda ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de l\'Onda',
    type: AccommodationType.refuge,
    // B60v2: coords verifiees Google Maps / gr20-infos (42.1523, 9.0981)
    latitude: 42.1523,
    longitude: 9.0981,
    altitude: 1431,
    stageNumber: 8,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité', 'Cadre forestier'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac l\'Onda',
    type: AccommodationType.bivouac,
    // B60v2: pres du refuge l'Onda
    latitude: 42.1521,
    longitude: 9.0984,
    altitude: 1431,
    stageNumber: 8,
    priceRange: '7 EUR',
    amenities: ['Aire ombragee', 'WC (refuge)', 'Foret de pins'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 9 : l'Onda → Vizzavona ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Hotel Monte d\'Oro (Vizzavona)',
    type: AccommodationType.hotel,
    // B60v2: coords verifiees Google Maps (42.1135, 9.1192)
    latitude: 42.1135,
    longitude: 9.1192,
    altitude: 920,
    stageNumber: 9,
    priceRange: '80-130 EUR',
    phone: '04 95 47 21 06',
    amenities: ['Chambre privee', 'Douche', 'Restaurant gastronomique', 'Bar', 'Jardin', 'Wi-Fi'],
    comfortModes: [ComfortMode.premium],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Gite d\'étape U Fugone',
    type: AccommodationType.gite,
    // B60v2: coords verifiees Google Maps (42.1278, 9.1340)
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 910,
    stageNumber: 9,
    priceRange: '35-50 EUR',
    phone: '04 95 47 22 00',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité', 'Ambiance conviviale'],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Camping de la Gare (Vizzavona)',
    type: AccommodationType.camping,
    // B60v2: coords verifiees Google Maps — zone gare Vizzavona
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 905,
    stageNumber: 9,
    priceRange: '8-12 EUR',
    amenities: ['Emplacements', 'Douche', 'WC', 'Épicerie proche', 'Gare SNCF'],
    comfortModes: [ComfortMode.baroudeur, ComfortMode.standard],
  ),

  // ====== ETAPE 10 : Vizzavona → E Capanelle ======
  // B60v3: coords verifiees
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge d\'E Capanelle',
    type: AccommodationType.refuge,
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1586,
    stageNumber: 10,
    priceRange: '14 EUR',
    phone: '04 95 57 01 81',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bergeries d\'E Capanelle (Gite)',
    type: AccommodationType.bergerie,
    // B60v2: coords verifiees Google Maps — pres du refuge E Capanelle
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1600,
    stageNumber: 10,
    priceRange: '35-50 EUR',
    phone: '04 95 57 01 81',
    amenities: ['Dortoir', 'Douche', 'Repas corses', 'Électricité', 'Ambiance montagne'],
    comfortModes: [ComfortMode.confort],
  ),

  // ====== ETAPE 11 : E Capanelle → Prati ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Prati',
    type: AccommodationType.refuge,
    latitude: 42.0086,
    longitude: 9.2183,
    altitude: 1820,
    stageNumber: 11,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité', 'Vue plaine orientale'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Prati',
    type: AccommodationType.bivouac,
    latitude: 42.0084,
    longitude: 9.2185,
    altitude: 1820,
    stageNumber: 11,
    priceRange: '7 EUR',
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 12 : Prati → Usciolu ======
  // B60v4: confirme corse-randos + objectif-gr20 + livre-gr20-corse
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge d\'Usciolu',
    type: AccommodationType.refuge,
    latitude: 41.9349,
    longitude: 9.2059,
    altitude: 1750,
    stageNumber: 12,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Électricité', 'Panorama 360'],
    comfortModes: [ComfortMode.standard],
  ),
  // B60v4: bivouac pres du refuge Usciolu
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Usciolu',
    type: AccommodationType.bivouac,
    latitude: 41.9347,
    longitude: 9.2061,
    altitude: 1750,
    stageNumber: 12,
    priceRange: '7 EUR',
    amenities: ['Aire sur la crête', 'Venteux', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 13 : Usciolu → Asinao ======
  // B60v3: coords verifiees
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge d\'Asinao',
    type: AccommodationType.refuge,
    latitude: 41.8411,
    longitude: 9.2145,
    altitude: 1530,
    stageNumber: 13,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bergerie du Coscione',
    type: AccommodationType.bergerie,
    // B60v2: coords verifiees — plateau du Coscione pres de l'étape 13
    latitude: 41.8800,
    longitude: 9.1600,
    altitude: 1450,
    stageNumber: 13,
    priceRange: '20-30 EUR',
    amenities: ['Dortoir rustique', 'Fromage', 'Ambiance pastorale'],
    comfortModes: [ComfortMode.confort],
  ),
  // B60v3: bivouac pres du refuge Asinao
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Asinao',
    type: AccommodationType.bivouac,
    latitude: 41.8409,
    longitude: 9.2147,
    altitude: 1530,
    stageNumber: 13,
    priceRange: '7 EUR',
    amenities: ['Aire en forêt', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 14 : Asinao → Paliri ======
  // B60v4: confirme le-gr20.fr + gps-viewer + corse-randos
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Refuge de Paliri',
    type: AccommodationType.refuge,
    latitude: 41.7942,
    longitude: 9.2596,
    altitude: 1055,
    stageNumber: 14,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    amenities: ['Dortoir', 'Repas', 'Cadre granit'],
    comfortModes: [ComfortMode.standard],
  ),
  // B60v4: bivouac pres du refuge Paliri
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Bivouac Paliri',
    type: AccommodationType.bivouac,
    latitude: 41.7940,
    longitude: 9.2598,
    altitude: 1055,
    stageNumber: 14,
    priceRange: '7 EUR',
    amenities: ['Emplacements en forêt', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 15 : Paliri → Col de Bavella ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Auberge du Col de Bavella',
    type: AccommodationType.hotel,
    // B60v4: confirme odyssea.eu + zonza-saintelucie.com + le-gr20.fr
    latitude: 41.7959,
    longitude: 9.2290,
    altitude: 1218,
    stageNumber: 15,
    priceRange: '55-90 EUR',
    phone: '04 95 72 09 87',
    amenities: ['Chambre', 'Douche', 'Restaurant', 'Bar', 'Électricité', 'Vue Aiguilles'],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Camping du Col de Bavella',
    type: AccommodationType.camping,
    // B60v2: pres de l'auberge Bavella
    latitude: 41.7948,
    longitude: 9.2290,
    altitude: 1218,
    stageNumber: 15,
    priceRange: '8-12 EUR',
    amenities: ['Emplacements', 'WC', 'Restaurant/snack au col'],
    comfortModes: [ComfortMode.baroudeur, ComfortMode.standard],
  ),

  // ====== ETAPE 16 : Bavella → Conca (arrivée) ======
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Gite d\'étape de Conca',
    type: AccommodationType.gite,
    latitude: 41.734906949702065,
    longitude: 9.333940028834876,
    altitude: 252,
    stageNumber: 16,
    priceRange: '30-45 EUR',
    phone: '04 95 71 46 54',
    amenities: ['Dortoir', 'Douche', 'Repas', 'Électricité', 'Feter l\'arrivée'],
    comfortModes: [ComfortMode.standard, ComfortMode.confort],
  ),
  TrailAccommodation(
    trailId: 'gr20',
    name: 'Camping de Conca',
    type: AccommodationType.camping,
    latitude: 41.7360,
    longitude: 9.3350,
    altitude: 252,
    stageNumber: 16,
    priceRange: '8-10 EUR',
    amenities: ['Emplacements', 'WC', 'Douche'],
    comfortModes: [ComfortMode.baroudeur],
  ),
];

/// Obtenir les hébergements pour une étape donnee.
List<TrailAccommodation> accommodationsForStage(int stageNumber) {
  return gr20Accommodations
      .where((a) => a.stageNumber == stageNumber)
      .toList();
}

/// Obtenir les hébergements filtres par mode de confort.
List<TrailAccommodation> accommodationsForComfort(ComfortMode mode) {
  return gr20Accommodations
      .where((a) => a.comfortModes.contains(mode))
      .toList();
}

/// Obtenir les hébergements pour une étape ET un mode de confort.
List<TrailAccommodation> accommodationsForStageAndComfort(
  String trailId,
  int stageNumber,
  ComfortMode mode,
) {
  return gr20Accommodations
      .where((a) =>
          a.trailId == trailId &&
          a.stageNumber == stageNumber &&
          a.comfortModes.contains(mode))
      .toList();
}
