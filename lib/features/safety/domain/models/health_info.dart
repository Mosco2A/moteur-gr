// E5.16 — Modele informations sante LOCAL ONLY.
//
// Stocke les donnees medicales du randonneur :
// groupe sanguin, allergies, traitements, medecin, assurance.
// Ces donnees restent UNIQUEMENT sur le telephone (Drift).
// JAMAIS envoyees vers Firestore ou un serveur distant.
// Freezed : immutable, copyWith, ==/hashCode, JSON generes.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_info.freezed.dart';
part 'health_info.g.dart';

/// Informations de sante du randonneur — LOCAL ONLY.
///
/// Ces donnees sont stockees exclusivement sur le telephone
/// via Drift (pas de Firestore, pas de cloud). Elles sont
/// accessibles depuis l'ecran d'urgence pour transmission
/// orale aux secours en cas de besoin.
@freezed
abstract class HealthInfo with _$HealthInfo {
  const HealthInfo._();

  const factory HealthInfo({
    /// Groupe sanguin (ex: 'A+', 'O-', 'AB+').
    @Default('') String bloodType,

    /// Allergies connues (texte libre, ex: 'Penicilline, arachides').
    @Default('') String allergies,

    /// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
    @Default('') String treatments,

    /// Contact du medecin traitant (nom + telephone).
    @Default('') String doctorContact,

    /// Numero d'assurance / mutuelle / carte europeenne.
    @Default('') String insuranceNumber,
  }) = _HealthInfo;

  /// Verifie si au moins un champ est renseigne.
  bool get hasData =>
      bloodType.isNotEmpty ||
      allergies.isNotEmpty ||
      treatments.isNotEmpty ||
      doctorContact.isNotEmpty ||
      insuranceNumber.isNotEmpty;

  /// Conversion depuis JSON (Drift cache local).
  factory HealthInfo.fromJson(Map<String, dynamic> json) =>
      _$HealthInfoFromJson(json);
}
