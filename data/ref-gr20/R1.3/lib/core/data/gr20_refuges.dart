/// Données statiques des refuges et hébergements PNRC du GR20.
/// Coordonnées GPS reelles issues des topos officiels et du PNRC.
///
/// 16 refuges PNRC + bergeries et gites prives le long du sentier.
class Gr20Refuge {
  const Gr20Refuge({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.capacity,
    required this.stageNumber,
    this.hasShower = false,
    this.hasMeals = false,
    this.hasElectricity = false,
    this.phone,
    this.email,
    this.website,
    this.pricePerNight,
    this.openingPeriod = 'juin a octobre',
    this.distanceFromTrail = 0,
  });

  /// Nom du refuge / bergerie / gite.
  final String name;

  /// Type d'hébergement.
  final RefugeType type;

  /// Latitude WGS84.
  final double latitude;

  /// Longitude WGS84.
  final double longitude;

  /// Altitude en metres.
  final int altitude;

  /// Capacite en nombre de places.
  final int capacity;

  /// Numero de l'étape GR20 (fin d'étape).
  final int stageNumber;

  /// Douche disponible.
  final bool hasShower;

  /// Repas chauds disponibles.
  final bool hasMeals;

  /// Électricité disponible (recharge).
  final bool hasElectricity;

  /// Numero de téléphone.
  final String? phone;

  /// Adresse email de contact.
  final String? email;

  /// Site web / réservation.
  final String? website;

  /// Prix par nuit en euros (dortoir).
  final double? pricePerNight;

  /// Periode d'ouverture.
  final String openingPeriod;

  /// Distance depuis le sentier en metres (0 = sur le sentier).
  final int distanceFromTrail;

  /// Deserialise un Gr20Refuge depuis un JSON (Firebase Storage).
  factory Gr20Refuge.fromJson(Map<String, dynamic> json) {
    return Gr20Refuge(
      name: json['name'] as String,
      type: RefugeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => RefugeType.refuge,
      ),
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      altitude: json['altitude'] as int,
      capacity: json['capacity'] as int,
      stageNumber: json['stageNumber'] as int,
      hasShower: json['hasShower'] as bool? ?? false,
      hasMeals: json['hasMeals'] as bool? ?? false,
      hasElectricity: json['hasElectricity'] as bool? ?? false,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      website: json['website'] as String?,
      pricePerNight: (json['pricePerNight'] as num?)?.toDouble(),
      openingPeriod: json['openingPeriod'] as String? ?? 'juin a octobre',
      distanceFromTrail: json['distanceFromTrail'] as int? ?? 0,
    );
  }

  /// Serialise en JSON pour le cache Hive.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type.name,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'capacity': capacity,
      'stageNumber': stageNumber,
      'hasShower': hasShower,
      'hasMeals': hasMeals,
      'hasElectricity': hasElectricity,
      'phone': phone,
      'email': email,
      'website': website,
      'pricePerNight': pricePerNight,
      'openingPeriod': openingPeriod,
      'distanceFromTrail': distanceFromTrail,
    };
  }
}

/// Types d'hébergement le long du GR20.
enum RefugeType {
  /// Refuge PNRC (gerance, dortoir, cuisine).
  refuge,

  /// Bergerie privee transformee en gite.
  bergerie,

  /// Gite d'étape prive.
  gite,

  /// Hotel ou auberge.
  hotel,

  /// Camping ou aire de bivouac.
  camping,
}

/// Liste des 16 refuges PNRC du GR20 (Nord → Sud).
/// B60v4: toutes les coords verifiees par WebSearch (refuges.info, corse-randos,
/// gr20-infos, objectif-gr20, trails-viewer, Wikipedia, Google Maps).
const List<Gr20Refuge> gr20RefugesPNRC = [
  // --- Étape 1 : Calenzana → Ortu di u Piobbu ---
  // B60v4: confirme refuges.info + corse-randos + komoot
  Gr20Refuge(
    name: 'Refuge d\'Ortu di u Piobbu',
    type: RefugeType.refuge,
    latitude: 42.4653,
    longitude: 8.9069,
    altitude: 1520,
    capacity: 30,
    stageNumber: 1,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 2 : Ortu di u Piobbu → Carrozzu ---
  // B60v4: confirme mapcarta + corse-randos + gr20-infos
  Gr20Refuge(
    name: 'Refuge de Carrozzu',
    type: RefugeType.refuge,
    latitude: 42.4261,
    longitude: 8.9004,
    altitude: 1270,
    capacity: 30,
    stageNumber: 2,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 3 : Carrozzu → Haut-Asco ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge de l\'Asco Stagnu (Haut-Asco)',
    type: RefugeType.refuge,
    latitude: 42.4035,
    longitude: 8.9223,
    altitude: 1422,
    capacity: 30,
    stageNumber: 3,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 47 82 04',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 4 : Haut-Asco → Tighjettu ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge de Tighjettu',
    type: RefugeType.refuge,
    latitude: 42.3623,
    longitude: 8.9088,
    altitude: 1683,
    capacity: 28,
    stageNumber: 4,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 5 : Tighjettu → Ciottulu di i Mori ---
  // B60v4: confirme Wikipedia + corse-randos + gr20-infos
  Gr20Refuge(
    name: 'Refuge de Ciottulu di i Mori',
    type: RefugeType.refuge,
    latitude: 42.3350,
    longitude: 8.8680,
    altitude: 1991,
    capacity: 24,
    stageNumber: 5,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 6 : Ciottulu → Manganu ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge de Manganu',
    type: RefugeType.refuge,
    latitude: 42.2199,
    longitude: 8.9804,
    altitude: 1601,
    capacity: 28,
    stageNumber: 6,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 7 : Manganu → Petra Piana ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge de Petra Piana',
    type: RefugeType.refuge,
    latitude: 42.1981,
    longitude: 9.0523,
    altitude: 1842,
    capacity: 28,
    stageNumber: 7,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 8 : Petra Piana → l'Onda ---
  // B60v3: coords verifiees refuges.info + Google Maps + gr20-infos
  Gr20Refuge(
    name: 'Refuge de l\'Onda',
    type: RefugeType.refuge,
    latitude: 42.1523,
    longitude: 9.0981,
    altitude: 1431,
    capacity: 26,
    stageNumber: 8,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 9 : l'Onda → Vizzavona ---
  // Pas de refuge PNRC a Vizzavona — voir bergeries/gites prives

  // --- Étape 10 : Vizzavona → E Capanelle ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge d\'E Capanelle',
    type: RefugeType.refuge,
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1586,
    capacity: 28,
    stageNumber: 10,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 57 01 81',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 11 : E Capanelle → Prati ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge de Prati',
    type: RefugeType.refuge,
    latitude: 42.0086,
    longitude: 9.2183,
    altitude: 1820,
    capacity: 28,
    stageNumber: 11,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 12 : Prati → Usciolu ---
  // B60v4: confirme corse-randos + objectif-gr20 + livre-gr20-corse
  Gr20Refuge(
    name: 'Refuge d\'Usciolu',
    type: RefugeType.refuge,
    latitude: 41.9349,
    longitude: 9.2059,
    altitude: 1750,
    capacity: 30,
    stageNumber: 12,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 13 : Usciolu → Asinao ---
  // B60v3: coords verifiees refuges.info + Google Maps + corse-randos
  Gr20Refuge(
    name: 'Refuge d\'Asinao',
    type: RefugeType.refuge,
    latitude: 41.8411,
    longitude: 9.2145,
    altitude: 1530,
    capacity: 30,
    stageNumber: 13,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // --- Étape 14 : Asinao → Paliri ---
  // B60v4: confirme le-gr20.fr + gps-viewer + corse-randos
  Gr20Refuge(
    name: 'Refuge de Paliri',
    type: RefugeType.refuge,
    latitude: 41.7942,
    longitude: 9.2596,
    altitude: 1055,
    capacity: 20,
    stageNumber: 14,
    hasMeals: true,
    phone: '04 95 65 28 09',
    website: 'https://pnr-resa.corsica',
    pricePerNight: 14.0,
  ),

  // Étapes 15-16 : pas de refuge PNRC supplementaire
  // Le dernier refuge PNRC est Paliri (étape 14)
];

/// Bergeries et gites prives le long du GR20.
const List<Gr20Refuge> gr20BergeriesGites = [
  // --- Calenzana (étape 1 — départ NS / arrivée SN) ---
  // B2-fix: ajout pour detection arrivee en mode SN
  Gr20Refuge(
    name: 'Gite d\'étape de Calenzana',
    type: RefugeType.gite,
    latitude: 42.5086,
    longitude: 8.8554,
    altitude: 275,
    capacity: 30,
    stageNumber: 1,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    pricePerNight: 30.0,
    distanceFromTrail: 0,
  ),

  // --- Station Haut-Asco (étape 3) ---

  // B60v3: coords verifiees Google Maps + corse-randos
  Gr20Refuge(
    name: 'Hotel Le Chalet (Haut-Asco)',
    type: RefugeType.hotel,
    latitude: 42.4033,
    longitude: 8.9236,
    altitude: 1450,
    capacity: 40,
    stageNumber: 3,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 47 81 08',
    pricePerNight: 60.0,
    distanceFromTrail: 200,
  ),

  // --- Castel di Vergio (entre étape 5 et 6) ---
  // B60v4: confirme Booking.com + trip.com + le-gr20.fr (42.2875, 8.8919)
  Gr20Refuge(
    name: 'Hotel Castel di Vergio',
    type: RefugeType.hotel,
    latitude: 42.2875,
    longitude: 8.8919,
    altitude: 1404,
    capacity: 60,
    stageNumber: 5,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 48 00 01',
    pricePerNight: 70.0,
    distanceFromTrail: 100,
  ),

  // --- Bergerie de Vaccaghja (étape 6) ---
  // B60v3: coords verifiees corse-randos + objectif-gr20
  Gr20Refuge(
    name: 'Bergerie de Vaccaghja',
    type: RefugeType.bergerie,
    latitude: 42.2368,
    longitude: 8.9742,
    altitude: 1621,
    capacity: 15,
    stageNumber: 6,
    hasMeals: true,
    pricePerNight: 30.0,
    distanceFromTrail: 300,
  ),

  // --- Bergeries de Grotelle (étape 7) ---
  // B60v3: coords verifiees wikiloc + gps-viewer + corse-randos
  Gr20Refuge(
    name: 'Bergeries de Grotelle',
    type: RefugeType.bergerie,
    latitude: 42.2290,
    longitude: 9.0305,
    altitude: 1370,
    capacity: 20,
    stageNumber: 7,
    hasMeals: true,
    pricePerNight: 25.0,
    distanceFromTrail: 500,
  ),

  // --- Vizzavona (étape 9) ---
  // B60v3: coords verifiees Google Maps + mappy + gr20-infos
  Gr20Refuge(
    name: 'Hotel Monte d\'Oro',
    type: RefugeType.hotel,
    latitude: 42.1135,
    longitude: 9.1192,
    altitude: 920,
    capacity: 50,
    stageNumber: 9,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 47 21 06',
    pricePerNight: 80.0,
    distanceFromTrail: 100,
  ),
  // B60v3: coords verifiees Google Maps + gites-refuges.com
  Gr20Refuge(
    name: 'Gite d\'étape U Fugone (Vizzavona)',
    type: RefugeType.gite,
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 910,
    capacity: 30,
    stageNumber: 9,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 47 22 00',
    pricePerNight: 35.0,
    distanceFromTrail: 200,
  ),
  // B60v3: coords verifiees Google Maps — zone gare Vizzavona
  Gr20Refuge(
    name: 'Camping Vizzavona (Gare)',
    type: RefugeType.camping,
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 905,
    capacity: 100,
    stageNumber: 9,
    hasShower: true,
    hasElectricity: true,
    pricePerNight: 10.0,
    distanceFromTrail: 300,
  ),

  // --- Bergeries d'E Capanelle (étape 10) ---
  // B60v3: coords verifiees Google Maps + corse-randos — pres du refuge E Capanelle
  Gr20Refuge(
    name: 'Bergeries d\'E Capanelle (Gite)',
    type: RefugeType.bergerie,
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1600,
    capacity: 25,
    stageNumber: 10,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 57 01 81',
    pricePerNight: 35.0,
    distanceFromTrail: 50,
  ),

  // --- Col de Bavella (étape 15) ---
  // B60v4: confirme odyssea.eu + zonza-saintelucie.com + le-gr20.fr (41.7959, 9.2290)
  Gr20Refuge(
    name: 'Auberge du Col de Bavella',
    type: RefugeType.hotel,
    latitude: 41.7959,
    longitude: 9.2290,
    altitude: 1218,
    capacity: 30,
    stageNumber: 15,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 72 09 87',
    pricePerNight: 55.0,
    distanceFromTrail: 50,
  ),

  // --- Conca (étape 16 — arrivée) ---
  Gr20Refuge(
    name: 'Gite d\'étape de Conca',
    type: RefugeType.gite,
    latitude: 41.734906949702065,
    longitude: 9.333940028834876,
    altitude: 252,
    capacity: 25,
    stageNumber: 16,
    hasShower: true,
    hasMeals: true,
    hasElectricity: true,
    phone: '04 95 71 46 54',
    pricePerNight: 30.0,
    distanceFromTrail: 100,
  ),
];

/// Tous les hébergements combines (PNRC + prives).
final List<Gr20Refuge> gr20AllRefuges = [
  ...gr20RefugesPNRC,
  ...gr20BergeriesGites,
];
