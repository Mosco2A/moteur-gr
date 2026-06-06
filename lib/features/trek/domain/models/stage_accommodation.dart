import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage_accommodation.freezed.dart';
part 'stage_accommodation.g.dart';

/// Type d'hebergement le long d'un sentier.
/// Utilise String pour extensibilite (#81752) — chaque sentier peut definir
/// ses propres types dans son JSON. Une valeur inconnue est PRESERVEE telle
/// quelle (jamais ecrasee) ; seul son AFFICHAGE passe par un fallback
/// generique (voir accommodation_type_ui.dart).
typedef AccommodationType = String;

/// Valeurs connues pour AccommodationType (mapping label/icone dedie).
abstract class AccommodationTypeValues {
  static const String refuge = 'refuge';
  static const String bergerie = 'bergerie';
  static const String gite = 'gite';
  static const String hotel = 'hotel';
  static const String camping = 'camping';
  static const String bivouac = 'bivouac';
  static const List<String> values = [
    refuge,
    bergerie,
    gite,
    hotel,
    camping,
    bivouac,
  ];
}

/// Hebergement rattache a une etape — modele domaine.
///
/// Provient EXCLUSIVEMENT de la base Drift (table trail_accommodations),
/// seedee par le seeder generique depuis les assets JSON du sentier.
/// Aucune donnee d'hebergement n'est hardcodee dans le moteur.
@freezed
abstract class StageAccommodation with _$StageAccommodation {
  const StageAccommodation._();

  const factory StageAccommodation({
    /// Identifiant unique (UUID du JSON sentier)
    required String id,

    /// Reference vers l'etape (trail_stages.id)
    required String stageId,

    /// Numero de l'etape (depuis la jointure trail_stages)
    required int stageNumber,

    /// Nom en francais
    required String nameFr,

    /// Nom en anglais
    @Default('') String nameEn,

    /// Type d'hebergement
    required AccommodationType type,

    /// Latitude WGS84
    required double lat,

    /// Longitude WGS84
    required double lng,

    /// Telephone (nullable)
    String? phone,

    /// Email (nullable)
    String? email,

    /// Site web (nullable)
    String? website,

    /// Capacite d'accueil (nullable)
    int? capacity,

    /// Fourchette de prix (nullable, ex: '30-50EUR')
    String? priceRange,

    /// URL de reservation (nullable)
    String? bookingUrl,
  }) = _StageAccommodation;

  /// Nom d'affichage (francais par defaut).
  String get name => nameFr;

  factory StageAccommodation.fromJson(Map<String, dynamic> json) =>
      _$StageAccommodationFromJson(json);
}
