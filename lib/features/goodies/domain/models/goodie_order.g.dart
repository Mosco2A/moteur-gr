// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goodie_order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoodieOrder _$GoodieOrderFromJson(Map<String, dynamic> json) => _GoodieOrder(
  id: json['id'] as String,
  productId: json['productId'] as String,
  trailId: json['trailId'] as String,
  quantity: (json['quantity'] as num?)?.toInt() ?? 1,
  totalPrice: (json['totalPrice'] as num).toInt(),
  status: json['status'] as String? ?? 'pending',
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GoodieOrderToJson(_GoodieOrder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'productId': instance.productId,
      'trailId': instance.trailId,
      'quantity': instance.quantity,
      'totalPrice': instance.totalPrice,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
