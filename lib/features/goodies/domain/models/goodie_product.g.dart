// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goodie_product.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_GoodieProduct _$GoodieProductFromJson(Map<String, dynamic> json) =>
    _GoodieProduct(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String,
      price: (json['price'] as num).toInt(),
      image: json['image'] as String?,
      personalizable: json['personalizable'] as bool? ?? false,
      trailSpecific: json['trailSpecific'] as bool? ?? false,
    );

Map<String, dynamic> _$GoodieProductToJson(_GoodieProduct instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': instance.type,
      'price': instance.price,
      'image': instance.image,
      'personalizable': instance.personalizable,
      'trailSpecific': instance.trailSpecific,
    };
