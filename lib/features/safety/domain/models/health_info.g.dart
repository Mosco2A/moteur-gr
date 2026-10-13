// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HealthInfo _$HealthInfoFromJson(Map<String, dynamic> json) => _HealthInfo(
  fullName: json['fullName'] as String? ?? '',
  birthDate: json['birthDate'] as String? ?? '',
  address: json['address'] as String? ?? '',
  emergencyContacts:
      (json['emergencyContacts'] as List<dynamic>?)
          ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <EmergencyContact>[],
  allergies: json['allergies'] as String? ?? '',
  treatments: json['treatments'] as String? ?? '',
  conditions: json['conditions'] as String? ?? '',
  bloodType: json['bloodType'] as String? ?? '',
  organDonor: json['organDonor'] as String? ?? '',
  doctorContact: json['doctorContact'] as String? ?? '',
  insuranceNumber: json['insuranceNumber'] as String? ?? '',
  carteVitaleFichier: json['carteVitaleFichier'] as String? ?? '',
  carteMutuelleFichier: json['carteMutuelleFichier'] as String? ?? '',
);

Map<String, dynamic> _$HealthInfoToJson(_HealthInfo instance) =>
    <String, dynamic>{
      'fullName': instance.fullName,
      'birthDate': instance.birthDate,
      'address': instance.address,
      'emergencyContacts': instance.emergencyContacts
          .map((e) => e.toJson())
          .toList(),
      'allergies': instance.allergies,
      'treatments': instance.treatments,
      'conditions': instance.conditions,
      'bloodType': instance.bloodType,
      'organDonor': instance.organDonor,
      'doctorContact': instance.doctorContact,
      'insuranceNumber': instance.insuranceNumber,
      'carteVitaleFichier': instance.carteVitaleFichier,
      'carteMutuelleFichier': instance.carteMutuelleFichier,
    };
