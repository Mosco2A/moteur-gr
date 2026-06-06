// E5.14a — Modele contact d'urgence.
//
// Represente un contact d'urgence avec nom, telephone, priorite
// et flag automatique (numeros secours universels/regionaux).
// Freezed : immutable, copyWith, ==/hashCode, JSON generes.

import 'package:freezed_annotation/freezed_annotation.dart';

part 'emergency_contact.freezed.dart';
part 'emergency_contact.g.dart';

/// Contact d'urgence pour le trek.
///
/// Peut etre un contact personnel (saisi par l'utilisateur)
/// ou un numero de secours automatique (112, secours regionaux
/// du sentier actif).
@freezed
abstract class EmergencyContact with _$EmergencyContact {
  const factory EmergencyContact({
    /// Identifiant unique du contact.
    required String id,

    /// Nom du contact (ex: 'Secours montagne', 'Maman').
    required String name,

    /// Numero de telephone (format international ou local).
    required String phone,

    /// Priorite d'affichage (1 = plus urgent, ordre croissant).
    required int priority,

    /// Contact automatique (secours) — non modifiable par l'utilisateur.
    @Default(false) bool isAutomatic,
  }) = _EmergencyContact;

  /// Conversion depuis JSON (Firestore / cache local).
  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      _$EmergencyContactFromJson(json);
}
