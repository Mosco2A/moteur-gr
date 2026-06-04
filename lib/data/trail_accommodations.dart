/// Catalogue des hebergements peripheriques des sentiers de randonnee.
///
/// V6.4.2 — Catalogue trail-agnostique pour refuges, gites, bergeries,
/// hotels, campings et zones de bivouac.
///
/// Ce fichier fournit :
/// - Les enums [AccommodationType] et [ComfortMode]
/// - Le modele [TrailAccommodationEntry] avec serialisation JSON/Drift
/// - Le catalogue complet GR20 (16 etapes, Nord -> Sud)
/// - Les helpers de filtrage par etape, type, confort et proximite
///
/// Coordonnees GPS WGS84 verifiees B60v4 (sources croisees).
/// Compatible Drift TrailAccommodations table (Phase 4 v7).
library trail_accommodations;

import 'dart:math' show sqrt, cos, pi;

// ---------------------------------------------------------------------------
// ENUMS
// ---------------------------------------------------------------------------

/// Types d'hebergement reconnus par le Moteur GR.
enum AccommodationType {
  /// Refuge PNRC (ou equivalent parc regional).
  refuge,

  /// Bergerie corse — hebergement pastoral rustique.
  bergerie,

  /// Gite d'etape — dortoir avec services.
  gite,

  /// Hotel / auberge — chambre privee.
  hotel,

  /// Camping amenage.
  camping,

  /// Zone de bivouac officielle ou toleree.
  bivouac;

  /// Label court pour l'UI (FR).
  String get labelFr {
    switch (this) {
      case AccommodationType.refuge:
        return 'Refuge';
      case AccommodationType.bergerie:
        return 'Bergerie';
      case AccommodationType.gite:
        return 'Gite';
      case AccommodationType.hotel:
        return 'Hotel';
      case AccommodationType.camping:
        return 'Camping';
      case AccommodationType.bivouac:
        return 'Bivouac';
    }
  }

  /// Label court pour l'UI (EN).
  String get labelEn {
    switch (this) {
      case AccommodationType.refuge:
        return 'Mountain hut';
      case AccommodationType.bergerie:
        return 'Sheepfold';
      case AccommodationType.gite:
        return 'Lodge';
      case AccommodationType.hotel:
        return 'Hotel';
      case AccommodationType.camping:
        return 'Campsite';
      case AccommodationType.bivouac:
        return 'Bivouac';
    }
  }
}

/// Modes de confort (du plus spartiate au plus confortable).
///
/// Utilises pour filtrer les hebergements selon le profil du randonneur.
enum ComfortMode {
  /// Bivouac / tente, autonomie complete.
  baroudeur,

  /// Refuge PNRC, dortoir collectif.
  standard,

  /// Bergerie / gite, un peu plus de confort.
  confort,

  /// Hotel, chambre privee, restaurant.
  premium;

  /// Label court pour l'UI (FR).
  String get labelFr {
    switch (this) {
      case ComfortMode.baroudeur:
        return 'Baroudeur';
      case ComfortMode.standard:
        return 'Standard';
      case ComfortMode.confort:
        return 'Confort';
      case ComfortMode.premium:
        return 'Premium';
    }
  }

  /// Label court pour l'UI (EN).
  String get labelEn {
    switch (this) {
      case ComfortMode.baroudeur:
        return 'Backpacker';
      case ComfortMode.standard:
        return 'Standard';
      case ComfortMode.confort:
        return 'Comfort';
      case ComfortMode.premium:
        return 'Premium';
    }
  }
}

// ---------------------------------------------------------------------------
// MODELE
// ---------------------------------------------------------------------------

/// Entree du catalogue hebergements.
///
/// Immutable. Compatible avec la table Drift [TrailAccommodations]
/// et le format JSON Firebase Storage / cache local.
class TrailAccommodationEntry {
  const TrailAccommodationEntry({
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
    this.website,
    this.capacity,
    this.bookingUrl,
    this.openFrom,
    this.openTo,
  });

  /// Identifiant du sentier (ex: 'gr20', 'tmb', 'hrp').
  final String trailId;

  /// Nom de l'hebergement.
  final String name;

  /// Type d'hebergement.
  final AccommodationType type;

  /// Latitude WGS84.
  final double latitude;

  /// Longitude WGS84.
  final double longitude;

  /// Altitude en metres.
  final int altitude;

  /// Numero de l'etape (fin d'etape).
  final int stageNumber;

  /// Fourchette de prix (ex: '14 EUR', '30-50 EUR').
  final String priceRange;

  /// Numero de telephone.
  final String? phone;

  /// Adresse email de contact.
  final String? email;

  /// Site web.
  final String? website;

  /// Capacite d'accueil (nombre de places).
  final int? capacity;

  /// URL de reservation en ligne.
  final String? bookingUrl;

  /// Mois d'ouverture (1-12), null = toute l'annee.
  final int? openFrom;

  /// Mois de fermeture (1-12), null = toute l'annee.
  final int? openTo;

  /// Liste des equipements (douche, repas, electricite, etc.).
  final List<String> amenities;

  /// Modes de confort compatibles.
  final List<ComfortMode> comfortModes;

  /// Verifie si l'hebergement est ouvert a une date donnee.
  ///
  /// Si [openFrom] et [openTo] sont null, l'hebergement est considere
  /// ouvert toute l'annee. Gere le cas ou la periode enjambe decembre.
  bool isOpenAt(DateTime date) {
    if (openFrom == null || openTo == null) return true;
    final month = date.month;
    if (openFrom! <= openTo!) {
      return month >= openFrom! && month <= openTo!;
    }
    // Periode a cheval sur l'annee (ex: nov-mars)
    return month >= openFrom! || month <= openTo!;
  }

  /// Distance approximative en km vers un point GPS donne.
  ///
  /// Utilise la formule equirectangulaire (suffisante pour des distances
  /// < 50 km en Corse, latitude ~42 degres).
  double distanceToKm(double lat, double lng) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat - latitude);
    final dLng = _toRadians(lng - longitude);
    final avgLat = _toRadians((latitude + lat) / 2);
    final x = dLng * cos(avgLat);
    return earthRadiusKm * sqrt(dLat * dLat + x * x);
  }

  static double _toRadians(double degrees) => degrees * pi / 180;

  /// Deserialise depuis JSON (Firebase Storage / cache local).
  factory TrailAccommodationEntry.fromJson(Map<String, dynamic> json) {
    return TrailAccommodationEntry(
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
      website: json['website'] as String?,
      capacity: json['capacity'] as int?,
      bookingUrl: json['bookingUrl'] as String?,
      openFrom: json['openFrom'] as int?,
      openTo: json['openTo'] as int?,
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

  /// Serialise en JSON pour le cache local / Firebase.
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
      'website': website,
      'capacity': capacity,
      'bookingUrl': bookingUrl,
      'openFrom': openFrom,
      'openTo': openTo,
      'amenities': amenities,
      'comfortModes': comfortModes.map((m) => m.name).toList(),
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TrailAccommodationEntry &&
        other.trailId == trailId &&
        other.name == name &&
        other.stageNumber == stageNumber;
  }

  @override
  int get hashCode => Object.hash(trailId, name, stageNumber);

  @override
  String toString() =>
      'TrailAccommodationEntry($name, etape $stageNumber, ${type.name})';
}

// ---------------------------------------------------------------------------
// CATALOGUE GR20 — 16 etapes, Nord -> Sud
// ---------------------------------------------------------------------------
// Coordonnees GPS verifiees B60v4 (refuges.info, Google Maps,
// corse-randos, gr20-infos, objectif-gr20, mapcarta, wikiloc).
// Saison standard : juin a octobre (refuges PNRC).
// ---------------------------------------------------------------------------

/// Catalogue complet des hebergements du GR20.
const List<TrailAccommodationEntry> gr20Catalogue = [
  // ====== ETAPE 1 : Calenzana -> Ortu di u Piobbu ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge d\'Ortu di u Piobbu',
    type: AccommodationType.refuge,
    latitude: 42.4653,
    longitude: 8.9069,
    altitude: 1520,
    stageNumber: 1,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 30,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite', 'WC'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Ortu di u Piobbu',
    type: AccommodationType.bivouac,
    latitude: 42.4651,
    longitude: 8.9071,
    altitude: 1520,
    stageNumber: 1,
    priceRange: '7 EUR',
    capacity: 20,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)', 'Douche (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 2 : Ortu di u Piobbu -> Carrozzu ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Carrozzu',
    type: AccommodationType.refuge,
    latitude: 42.4261,
    longitude: 8.9004,
    altitude: 1270,
    stageNumber: 2,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 30,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Carrozzu',
    type: AccommodationType.bivouac,
    latitude: 42.4259,
    longitude: 8.9006,
    altitude: 1270,
    stageNumber: 2,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 3 : Carrozzu -> Haut-Asco ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de l\'Asco Stagnu',
    type: AccommodationType.refuge,
    latitude: 42.4035,
    longitude: 8.9223,
    altitude: 1422,
    stageNumber: 3,
    priceRange: '14 EUR',
    phone: '04 95 47 82 04',
    capacity: 28,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Hotel Le Chalet (Haut-Asco)',
    type: AccommodationType.hotel,
    latitude: 42.4033,
    longitude: 8.9236,
    altitude: 1450,
    stageNumber: 3,
    priceRange: '60-90 EUR',
    phone: '04 95 47 81 08',
    capacity: 40,
    openFrom: 5,
    openTo: 10,
    amenities: [
      'Chambre privee',
      'Douche',
      'Restaurant',
      'Bar',
      'Electricite',
      'Wi-Fi',
    ],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Camping Haut-Asco',
    type: AccommodationType.camping,
    latitude: 42.4030,
    longitude: 8.9230,
    altitude: 1440,
    stageNumber: 3,
    priceRange: '8-10 EUR',
    capacity: 30,
    openFrom: 6,
    openTo: 9,
    amenities: ['Emplacements', 'WC', 'Douche'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 4 : Haut-Asco -> Tighjettu ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Tighjettu',
    type: AccommodationType.refuge,
    latitude: 42.3623,
    longitude: 8.9088,
    altitude: 1683,
    stageNumber: 4,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 24,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Tighjettu',
    type: AccommodationType.bivouac,
    latitude: 42.3621,
    longitude: 8.9091,
    altitude: 1683,
    stageNumber: 4,
    priceRange: '7 EUR',
    capacity: 12,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee (limitee)', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 5 : Tighjettu -> Ciottulu di i Mori ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Ciottulu di i Mori',
    type: AccommodationType.refuge,
    latitude: 42.3350,
    longitude: 8.8680,
    altitude: 1991,
    stageNumber: 5,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 24,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite', 'Vue panoramique'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Ciottulu di i Mori',
    type: AccommodationType.bivouac,
    latitude: 42.3348,
    longitude: 8.8682,
    altitude: 1991,
    stageNumber: 5,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Hotel Castel di Vergio',
    type: AccommodationType.hotel,
    latitude: 42.2875,
    longitude: 8.8919,
    altitude: 1404,
    stageNumber: 5,
    priceRange: '70-120 EUR',
    phone: '04 95 48 00 01',
    capacity: 50,
    openFrom: 5,
    openTo: 10,
    amenities: [
      'Chambre privee',
      'Douche',
      'Restaurant',
      'Bar',
      'Piscine',
      'Electricite',
    ],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),

  // ====== ETAPE 6 : Ciottulu -> Manganu ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Manganu',
    type: AccommodationType.refuge,
    latitude: 42.2199,
    longitude: 8.9804,
    altitude: 1601,
    stageNumber: 6,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 28,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bergerie de Vaccaghja',
    type: AccommodationType.bergerie,
    latitude: 42.2368,
    longitude: 8.9742,
    altitude: 1621,
    stageNumber: 6,
    priceRange: '25-35 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 9,
    amenities: ['Dortoir rustique', 'Repas corses', 'Fromage maison'],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Manganu',
    type: AccommodationType.bivouac,
    latitude: 42.2197,
    longitude: 8.9806,
    altitude: 1601,
    stageNumber: 6,
    priceRange: '7 EUR',
    capacity: 20,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire plate', 'WC (refuge)', 'Vue lac de Ninu'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 7 : Manganu -> Petra Piana ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Petra Piana',
    type: AccommodationType.refuge,
    latitude: 42.1981,
    longitude: 9.0523,
    altitude: 1842,
    stageNumber: 7,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 28,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite', 'Vue exceptionnelle'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bergeries de Grotelle',
    type: AccommodationType.bergerie,
    latitude: 42.2290,
    longitude: 9.0305,
    altitude: 1370,
    stageNumber: 7,
    priceRange: '20-30 EUR',
    capacity: 12,
    openFrom: 6,
    openTo: 9,
    amenities: ['Dortoir', 'Repas corses'],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Petra Piana',
    type: AccommodationType.bivouac,
    latitude: 42.1979,
    longitude: 9.0525,
    altitude: 1842,
    stageNumber: 7,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)', 'Vue montagne'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 8 : Petra Piana -> l'Onda ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de l\'Onda',
    type: AccommodationType.refuge,
    latitude: 42.1523,
    longitude: 9.0981,
    altitude: 1431,
    stageNumber: 8,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 24,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite', 'Cadre forestier'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac l\'Onda',
    type: AccommodationType.bivouac,
    latitude: 42.1521,
    longitude: 9.0984,
    altitude: 1431,
    stageNumber: 8,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire ombragee', 'WC (refuge)', 'Foret de pins'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 9 : l'Onda -> Vizzavona ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Hotel Monte d\'Oro (Vizzavona)',
    type: AccommodationType.hotel,
    latitude: 42.1135,
    longitude: 9.1192,
    altitude: 920,
    stageNumber: 9,
    priceRange: '80-130 EUR',
    phone: '04 95 47 21 06',
    capacity: 30,
    openFrom: 4,
    openTo: 11,
    amenities: [
      'Chambre privee',
      'Douche',
      'Restaurant gastronomique',
      'Bar',
      'Jardin',
      'Wi-Fi',
    ],
    comfortModes: [ComfortMode.premium],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Gite d\'etape U Fugone',
    type: AccommodationType.gite,
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 910,
    stageNumber: 9,
    priceRange: '35-50 EUR',
    phone: '04 95 47 22 00',
    capacity: 24,
    openFrom: 5,
    openTo: 10,
    amenities: [
      'Dortoir',
      'Douche',
      'Repas',
      'Electricite',
      'Ambiance conviviale',
    ],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Camping de la Gare (Vizzavona)',
    type: AccommodationType.camping,
    latitude: 42.1278,
    longitude: 9.1340,
    altitude: 905,
    stageNumber: 9,
    priceRange: '8-12 EUR',
    capacity: 40,
    openFrom: 5,
    openTo: 10,
    amenities: [
      'Emplacements',
      'Douche',
      'WC',
      'Epicerie proche',
      'Gare SNCF',
    ],
    comfortModes: [ComfortMode.baroudeur, ComfortMode.standard],
  ),

  // ====== ETAPE 10 : Vizzavona -> E Capanelle ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge d\'E Capanelle',
    type: AccommodationType.refuge,
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1586,
    stageNumber: 10,
    priceRange: '14 EUR',
    phone: '04 95 57 01 81',
    capacity: 28,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bergeries d\'E Capanelle (Gite)',
    type: AccommodationType.bergerie,
    latitude: 42.0773,
    longitude: 9.1502,
    altitude: 1600,
    stageNumber: 10,
    priceRange: '35-50 EUR',
    phone: '04 95 57 01 81',
    capacity: 20,
    openFrom: 6,
    openTo: 9,
    amenities: [
      'Dortoir',
      'Douche',
      'Repas corses',
      'Electricite',
      'Ambiance montagne',
    ],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac E Capanelle',
    type: AccommodationType.bivouac,
    latitude: 42.0771,
    longitude: 9.1504,
    altitude: 1586,
    stageNumber: 10,
    priceRange: '7 EUR',
    capacity: 20,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 11 : E Capanelle -> Prati ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Prati',
    type: AccommodationType.refuge,
    latitude: 42.0086,
    longitude: 9.2183,
    altitude: 1820,
    stageNumber: 11,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 24,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite', 'Vue plaine orientale'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Prati',
    type: AccommodationType.bivouac,
    latitude: 42.0084,
    longitude: 9.2185,
    altitude: 1820,
    stageNumber: 11,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire amenagee', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 12 : Prati -> Usciolu ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge d\'Usciolu',
    type: AccommodationType.refuge,
    latitude: 41.9349,
    longitude: 9.2059,
    altitude: 1750,
    stageNumber: 12,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 28,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Electricite', 'Panorama 360'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Usciolu',
    type: AccommodationType.bivouac,
    latitude: 41.9347,
    longitude: 9.2061,
    altitude: 1750,
    stageNumber: 12,
    priceRange: '7 EUR',
    capacity: 12,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire sur la crete', 'Venteux', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 13 : Usciolu -> Asinao ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge d\'Asinao',
    type: AccommodationType.refuge,
    latitude: 41.8411,
    longitude: 9.2145,
    altitude: 1530,
    stageNumber: 13,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 30,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Douche', 'Repas', 'Electricite'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bergerie du Coscione',
    type: AccommodationType.bergerie,
    latitude: 41.8800,
    longitude: 9.1600,
    altitude: 1450,
    stageNumber: 13,
    priceRange: '20-30 EUR',
    capacity: 10,
    openFrom: 6,
    openTo: 9,
    amenities: ['Dortoir rustique', 'Fromage', 'Ambiance pastorale'],
    comfortModes: [ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Asinao',
    type: AccommodationType.bivouac,
    latitude: 41.8409,
    longitude: 9.2147,
    altitude: 1530,
    stageNumber: 13,
    priceRange: '7 EUR',
    capacity: 20,
    openFrom: 6,
    openTo: 10,
    amenities: ['Aire en foret', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 14 : Asinao -> Paliri ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Refuge de Paliri',
    type: AccommodationType.refuge,
    latitude: 41.7942,
    longitude: 9.2596,
    altitude: 1055,
    stageNumber: 14,
    priceRange: '14 EUR',
    phone: '04 95 65 28 09',
    capacity: 24,
    openFrom: 6,
    openTo: 10,
    amenities: ['Dortoir', 'Repas', 'Cadre granit'],
    comfortModes: [ComfortMode.standard],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Bivouac Paliri',
    type: AccommodationType.bivouac,
    latitude: 41.7940,
    longitude: 9.2598,
    altitude: 1055,
    stageNumber: 14,
    priceRange: '7 EUR',
    capacity: 15,
    openFrom: 6,
    openTo: 10,
    amenities: ['Emplacements en foret', 'WC (refuge)'],
    comfortModes: [ComfortMode.baroudeur],
  ),

  // ====== ETAPE 15 : Paliri -> Col de Bavella ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Auberge du Col de Bavella',
    type: AccommodationType.hotel,
    latitude: 41.7959,
    longitude: 9.2290,
    altitude: 1218,
    stageNumber: 15,
    priceRange: '55-90 EUR',
    phone: '04 95 72 09 87',
    capacity: 30,
    openFrom: 5,
    openTo: 10,
    amenities: [
      'Chambre',
      'Douche',
      'Restaurant',
      'Bar',
      'Electricite',
      'Vue Aiguilles',
    ],
    comfortModes: [ComfortMode.confort, ComfortMode.premium],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Camping du Col de Bavella',
    type: AccommodationType.camping,
    latitude: 41.7948,
    longitude: 9.2290,
    altitude: 1218,
    stageNumber: 15,
    priceRange: '8-12 EUR',
    capacity: 25,
    openFrom: 6,
    openTo: 9,
    amenities: ['Emplacements', 'WC', 'Restaurant/snack au col'],
    comfortModes: [ComfortMode.baroudeur, ComfortMode.standard],
  ),

  // ====== ETAPE 16 : Bavella -> Conca (arrivee) ======
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Gite d\'etape de Conca',
    type: AccommodationType.gite,
    latitude: 41.7349,
    longitude: 9.3339,
    altitude: 252,
    stageNumber: 16,
    priceRange: '30-45 EUR',
    phone: '04 95 71 46 54',
    capacity: 25,
    openFrom: 4,
    openTo: 11,
    amenities: [
      'Dortoir',
      'Douche',
      'Repas',
      'Electricite',
      'Feter l\'arrivee',
    ],
    comfortModes: [ComfortMode.standard, ComfortMode.confort],
  ),
  TrailAccommodationEntry(
    trailId: 'gr20',
    name: 'Camping de Conca',
    type: AccommodationType.camping,
    latitude: 41.7360,
    longitude: 9.3350,
    altitude: 252,
    stageNumber: 16,
    priceRange: '8-10 EUR',
    capacity: 20,
    openFrom: 5,
    openTo: 10,
    amenities: ['Emplacements', 'WC', 'Douche'],
    comfortModes: [ComfortMode.baroudeur],
  ),
];

// ---------------------------------------------------------------------------
// HELPERS DE FILTRAGE
// ---------------------------------------------------------------------------

/// Obtenir tous les hebergements d'un sentier donne.
///
/// [catalogue] par defaut [gr20Catalogue]. Passer un autre catalogue
/// pour d'autres sentiers (TMB, HRP, Mare a Mare, etc.).
List<TrailAccommodationEntry> accommodationsForTrail(
  String trailId, {
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  return catalogue.where((a) => a.trailId == trailId).toList();
}

/// Obtenir les hebergements pour une etape donnee.
List<TrailAccommodationEntry> accommodationsForStage(
  int stageNumber, {
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  return catalogue.where((a) => a.stageNumber == stageNumber).toList();
}

/// Obtenir les hebergements filtres par type.
List<TrailAccommodationEntry> accommodationsForType(
  AccommodationType type, {
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  return catalogue.where((a) => a.type == type).toList();
}

/// Obtenir les hebergements filtres par mode de confort.
List<TrailAccommodationEntry> accommodationsForComfort(
  ComfortMode mode, {
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  return catalogue.where((a) => a.comfortModes.contains(mode)).toList();
}

/// Obtenir les hebergements pour une etape ET un mode de confort.
List<TrailAccommodationEntry> accommodationsForStageAndComfort(
  String trailId,
  int stageNumber,
  ComfortMode mode, {
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  return catalogue
      .where((a) =>
          a.trailId == trailId &&
          a.stageNumber == stageNumber &&
          a.comfortModes.contains(mode))
      .toList();
}

/// Obtenir les hebergements les plus proches d'un point GPS.
///
/// Retourne les [limit] hebergements les plus proches, tries par distance.
/// Optionnellement filtrer par [trailId] et/ou [maxDistanceKm].
List<TrailAccommodationEntry> accommodationsNearby(
  double latitude,
  double longitude, {
  int limit = 5,
  double? maxDistanceKm,
  String? trailId,
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  var entries = trailId != null
      ? catalogue.where((a) => a.trailId == trailId).toList()
      : catalogue.toList();

  entries.sort((a, b) {
    final distA = a.distanceToKm(latitude, longitude);
    final distB = b.distanceToKm(latitude, longitude);
    return distA.compareTo(distB);
  });

  if (maxDistanceKm != null) {
    entries = entries
        .where((a) => a.distanceToKm(latitude, longitude) <= maxDistanceKm)
        .toList();
  }

  return entries.take(limit).toList();
}

/// Obtenir les hebergements ouverts a une date donnee.
List<TrailAccommodationEntry> accommodationsOpenAt(
  DateTime date, {
  int? stageNumber,
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  var entries = catalogue.where((a) => a.isOpenAt(date));
  if (stageNumber != null) {
    entries = entries.where((a) => a.stageNumber == stageNumber);
  }
  return entries.toList();
}

/// Statistiques rapides sur le catalogue.
///
/// Retourne un Map avec le nombre d'hebergements par type
/// et le nombre total d'hebergements.
Map<String, dynamic> catalogueStats({
  List<TrailAccommodationEntry> catalogue = gr20Catalogue,
}) {
  final byType = <AccommodationType, int>{};
  final byStage = <int, int>{};
  for (final entry in catalogue) {
    byType[entry.type] = (byType[entry.type] ?? 0) + 1;
    byStage[entry.stageNumber] = (byStage[entry.stageNumber] ?? 0) + 1;
  }
  return {
    'total': catalogue.length,
    'byType': byType.map((k, v) => MapEntry(k.name, v)),
    'byStage': byStage,
    'stages': byStage.keys.toList()..sort(),
  };
}
