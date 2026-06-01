import 'package:freezed_annotation/freezed_annotation.dart';

part 'personalization_data.freezed.dart';
part 'personalization_data.g.dart';

/// Modele immutable representant les donnees de personnalisation d'un goodie.
///
/// Contient les informations saisies par l'utilisateur pour personnaliser
/// un produit (nom, date de trek, nom d'etape, texte libre, etc.).
/// Tous les champs sont optionnels car la personnalisation varie par produit.
@freezed
abstract class PersonalizationData with _$PersonalizationData {
  const PersonalizationData._();

  const factory PersonalizationData({
    /// Identifiant unique des donnees de personnalisation
    required String id,

    /// Identifiant de la commande associee
    required String orderId,

    /// Nom personnalise (ex: prenom du trekkeur)
    String? customName,

    /// Date de trek personnalisee (ex: 'Juin 2026')
    String? trekDate,

    /// Nom de l'etape commemoree (ex: 'Vizzavona')
    String? stageName,

    /// Texte libre supplementaire
    String? freeText,

    /// Chemin vers une image personnalisee uploadee par l'utilisateur
    String? customImagePath,
  }) = _PersonalizationData;

  /// Deserialisation depuis JSON
  factory PersonalizationData.fromJson(Map<String, dynamic> json) =>
      _$PersonalizationDataFromJson(json);
}
