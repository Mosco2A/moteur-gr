import 'package:freezed_annotation/freezed_annotation.dart';

part 'trail.freezed.dart';
part 'trail.g.dart';

/// Modele immutable representant un sentier.
///
/// Contient les metadonnees du sentier (nom, region, distance, etc.)
/// Utilisable pour la liste des sentiers et les ecrans de detail.
@freezed
abstract class Trail with _$Trail {
  const factory Trail({
    /// Identifiant unique (ex: 'mare_a_mare', 'tmb')
    required String id,

    /// Nom technique court (ex: 'Mare a Mare')
    required String name,

    /// Nom d'affichage dans l'app
    required String displayName,

    /// Accroche sous le nom
    @Default('') String tagline,

    /// Nombre total d'etapes
    required int totalStages,

    /// Distance totale en km
    required double totalDistanceKm,

    /// Denivele positif total en metres
    required int totalElevationGain,

    /// Region geographique
    required String region,

    /// Pays
    required String country,
  }) = _Trail;

  /// Deserialisation depuis JSON
  factory Trail.fromJson(Map<String, dynamic> json) => _$TrailFromJson(json);
}
