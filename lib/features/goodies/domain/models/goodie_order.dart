import 'package:freezed_annotation/freezed_annotation.dart';

part 'goodie_order.freezed.dart';
part 'goodie_order.g.dart';

/// Modele immutable representant une commande de goodie.
///
/// Regroupe le produit commande, la quantite, les donnees
/// de personnalisation et le statut de la commande.
/// status est un String extensible (JAMAIS enum).
@freezed
abstract class GoodieOrder with _$GoodieOrder {
  const GoodieOrder._();

  const factory GoodieOrder({
    /// Identifiant unique de la commande
    required String id,

    /// Identifiant du produit commande
    required String productId,

    /// Identifiant du sentier associe (ex: 'gr10')
    required String trailId,

    /// Quantite commandee
    @Default(1) int quantity,

    /// Prix total en centimes
    required int totalPrice,

    /// Statut de la commande -- String extensible (pending, confirmed, shipped, delivered, cancelled, ...)
    @Default('pending') String status,

    /// Date de creation de la commande
    required DateTime createdAt,

    /// Date de derniere mise a jour (null si jamais modifiee)
    DateTime? updatedAt,
  }) = _GoodieOrder;

  /// Deserialisation depuis JSON
  factory GoodieOrder.fromJson(Map<String, dynamic> json) =>
      _$GoodieOrderFromJson(json);
}
