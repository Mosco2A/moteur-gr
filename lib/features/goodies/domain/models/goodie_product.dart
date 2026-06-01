import 'package:freezed_annotation/freezed_annotation.dart';

part 'goodie_product.freezed.dart';
part 'goodie_product.g.dart';

/// Modele immutable representant un produit goodie personnalisable.
///
/// type est un String extensible (JAMAIS enum) pour permettre
/// l'ajout de types (tshirt, mug, patch, sticker, etc.) sans recompilation.
@freezed
abstract class GoodieProduct with _$GoodieProduct {
  const GoodieProduct._();

  const factory GoodieProduct({
    /// Identifiant unique du produit
    required String id,

    /// Nom du produit (cle i18n pour resolution via Slang)
    required String name,

    /// Description du produit (cle i18n pour resolution via Slang)
    @Default('') String description,

    /// Type de produit -- String extensible (tshirt, mug, patch, sticker, poster, ...)
    required String type,

    /// Prix en centimes (ex: 1990 = 19.90 EUR)
    required int price,

    /// Chemin vers l'image du produit (asset ou URL)
    String? image,

    /// Indique si le produit est personnalisable (nom, date, etape, etc.)
    @Default(false) bool personalizable,

    /// Indique si le produit est specifique a un sentier
    @Default(false) bool trailSpecific,
  }) = _GoodieProduct;

  /// Deserialisation depuis JSON
  factory GoodieProduct.fromJson(Map<String, dynamic> json) =>
      _$GoodieProductFromJson(json);
}
