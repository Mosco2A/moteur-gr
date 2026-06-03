// E5.14a — Modele contact d'urgence.
//
// Represente un contact d'urgence avec nom, telephone, priorite
// et flag automatique (numeros secours nationaux).
// Immutable — utiliser copyWith pour les modifications.
// Serialisable JSON pour Firestore et cache local.

/// Contact d'urgence pour le trek.
///
/// Peut etre un contact personnel (saisi par l'utilisateur)
/// ou un numero de secours automatique (112, PGHM...).
class EmergencyContact {
  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.priority,
    this.isAutomatic = false,
  });

  /// Identifiant unique du contact.
  final String id;

  /// Nom du contact (ex: 'PGHM Corse', 'Maman').
  final String name;

  /// Numero de telephone (format international ou local).
  final String phone;

  /// Priorite d'affichage (1 = plus urgent, ordre croissant).
  final int priority;

  /// Contact automatique (secours nationaux) — non modifiable par l'utilisateur.
  final bool isAutomatic;

  /// Conversion depuis JSON (Firestore / cache local).
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      priority: json['priority'] as int? ?? 99,
      isAutomatic: json['isAutomatic'] as bool? ?? false,
    );
  }

  /// Conversion vers JSON (Firestore / cache local).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'priority': priority,
      'isAutomatic': isAutomatic,
    };
  }

  /// Copie avec modification.
  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    int? priority,
    bool? isAutomatic,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      priority: priority ?? this.priority,
      isAutomatic: isAutomatic ?? this.isAutomatic,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EmergencyContact &&
        other.id == id &&
        other.name == name &&
        other.phone == phone &&
        other.priority == priority &&
        other.isAutomatic == isAutomatic;
  }

  @override
  int get hashCode => Object.hash(id, name, phone, priority, isAutomatic);

  @override
  String toString() =>
      'EmergencyContact(id: $id, name: $name, phone: $phone, '
      'priority: $priority, auto: $isAutomatic)';
}
