// E5.16 — Modele informations sante LOCAL ONLY.
//
// Stocke les donnees medicales du randonneur :
// groupe sanguin, allergies, traitements, medecin, assurance.
// Ces donnees restent UNIQUEMENT sur le telephone (Hive).
// JAMAIS envoyees vers Firestore ou un serveur distant.
// Immutable — utiliser copyWith pour les modifications.

/// Informations de sante du randonneur — LOCAL ONLY.
///
/// Ces donnees sont stockees exclusivement sur le telephone
/// via Hive (pas de Firestore, pas de cloud). Elles sont
/// accessibles depuis l'ecran d'urgence pour transmission
/// orale aux secours en cas de besoin.
class HealthInfo {
  const HealthInfo({
    this.bloodType = '',
    this.allergies = '',
    this.treatments = '',
    this.doctorContact = '',
    this.insuranceNumber = '',
  });

  /// Groupe sanguin (ex: 'A+', 'O-', 'AB+').
  final String bloodType;

  /// Allergies connues (texte libre, ex: 'Penicilline, arachides').
  final String allergies;

  /// Traitements en cours (texte libre, ex: 'Levothyrox 50mg/j').
  final String treatments;

  /// Contact du medecin traitant (nom + telephone).
  final String doctorContact;

  /// Numero d'assurance / mutuelle / carte europeenne.
  final String insuranceNumber;

  /// Conversion depuis JSON (Hive cache local).
  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      bloodType: json['bloodType'] as String? ?? '',
      allergies: json['allergies'] as String? ?? '',
      treatments: json['treatments'] as String? ?? '',
      doctorContact: json['doctorContact'] as String? ?? '',
      insuranceNumber: json['insuranceNumber'] as String? ?? '',
    );
  }

  /// Conversion vers JSON (Hive cache local).
  Map<String, dynamic> toJson() {
    return {
      'bloodType': bloodType,
      'allergies': allergies,
      'treatments': treatments,
      'doctorContact': doctorContact,
      'insuranceNumber': insuranceNumber,
    };
  }

  /// Copie avec modification.
  HealthInfo copyWith({
    String? bloodType,
    String? allergies,
    String? treatments,
    String? doctorContact,
    String? insuranceNumber,
  }) {
    return HealthInfo(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      treatments: treatments ?? this.treatments,
      doctorContact: doctorContact ?? this.doctorContact,
      insuranceNumber: insuranceNumber ?? this.insuranceNumber,
    );
  }

  /// Verifie si au moins un champ est renseigne.
  bool get hasData =>
      bloodType.isNotEmpty ||
      allergies.isNotEmpty ||
      treatments.isNotEmpty ||
      doctorContact.isNotEmpty ||
      insuranceNumber.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HealthInfo &&
        other.bloodType == bloodType &&
        other.allergies == allergies &&
        other.treatments == treatments &&
        other.doctorContact == doctorContact &&
        other.insuranceNumber == insuranceNumber;
  }

  @override
  int get hashCode => Object.hash(
        bloodType,
        allergies,
        treatments,
        doctorContact,
        insuranceNumber,
      );

  @override
  String toString() =>
      'HealthInfo(blood: $bloodType, allergies: $allergies, '
      'treatments: $treatments, doctor: $doctorContact, '
      'insurance: $insuranceNumber)';
}
