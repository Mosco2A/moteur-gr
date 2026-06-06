import 'package:freezed_annotation/freezed_annotation.dart';

part 'stage_accommodation.freezed.dart';
part 'stage_accommodation.g.dart';

/// Types d'hebergement le long d'un sentier.
enum AccommodationType {
  refuge,
  bergerie,
  gite,
  hotel,
  camping,
  bivouac;

  /// Parse depuis la valeur texte stockee en base.
  static AccommodationType fromDb(String value) {
    return AccommodationType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AccommodationType.refuge,
    );
  }
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
