// Modele de reservation d'hebergement.
//
// Represente une demande de reservation associee a un hebergement
// et un parcours (trail). Le statut suit le cycle :
// requested -> confirmed / cancelled.

/// Statut d'une reservation.
enum BookingStatus {
  /// Demande envoyee, en attente de confirmation.
  requested,

  /// Reservation confirmee par l'hebergeur.
  confirmed,

  /// Reservation annulee.
  cancelled;

  /// Label affiche dans l'UI.
  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmee';
      case BookingStatus.cancelled:
        return 'Annulee';
    }
  }
}

/// Methode de contact utilisee pour la reservation.
enum ContactMethod {
  /// Appel telephonique.
  phone,

  /// Email.
  email,

  /// Site web de l'hebergeur.
  web,

  /// API partenaire (reservation automatique).
  api;

  /// Label affiche dans l'UI.
  String get label {
    switch (this) {
      case ContactMethod.phone:
        return 'Telephone';
      case ContactMethod.email:
        return 'Email';
      case ContactMethod.web:
        return 'Site web';
      case ContactMethod.api:
        return 'Reservation en ligne';
    }
  }
}

/// Reservation d'un hebergement sur le sentier actif.
///
/// Immutable -- utiliser [copyWith] pour les modifications.
/// Serialisable JSON pour Firestore et cache local.
class AccommodationBooking {
  const AccommodationBooking({
    required this.id,
    required this.accommodationId,
    required this.trailId,
    required this.date,
    required this.status,
    required this.contactMethod,
    required this.bookedAt,
    this.notes,
  });

  /// Identifiant unique de la reservation (UUID).
  final String id;

  /// Identifiant de l'hebergement reserve (ref StageAccommodation).
  final String accommodationId;

  /// Identifiant du parcours / trek associe.
  final String trailId;

  /// Date de la nuitee reservee.
  final DateTime date;

  /// Statut de la reservation.
  final BookingStatus status;

  /// Methode de contact utilisee pour reserver.
  final ContactMethod contactMethod;

  /// Date/heure de creation de la reservation.
  final DateTime bookedAt;

  /// Notes libres (numero de confirmation, remarques, etc.).
  final String? notes;

  /// La reservation est-elle active (pas annulee) ?
  bool get isActive => status != BookingStatus.cancelled;

  /// La reservation est-elle confirmee ?
  bool get isConfirmed => status == BookingStatus.confirmed;

  /// Conversion depuis JSON (Firestore / cache local).
  factory AccommodationBooking.fromJson(Map<String, dynamic> json) {
    return AccommodationBooking(
      id: json['id'] as String,
      accommodationId: json['accommodationId'] as String,
      trailId: json['trailId'] as String,
      date: DateTime.parse(json['date'] as String),
      status: BookingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => BookingStatus.requested,
      ),
      contactMethod: ContactMethod.values.firstWhere(
        (m) => m.name == json['contactMethod'],
        orElse: () => ContactMethod.phone,
      ),
      bookedAt: DateTime.parse(json['bookedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  /// Conversion vers JSON (Firestore / cache local).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'accommodationId': accommodationId,
      'trailId': trailId,
      'date': date.toIso8601String(),
      'status': status.name,
      'contactMethod': contactMethod.name,
      'bookedAt': bookedAt.toIso8601String(),
      'notes': notes,
    };
  }

  /// Copie avec modification.
  AccommodationBooking copyWith({
    String? id,
    String? accommodationId,
    String? trailId,
    DateTime? date,
    BookingStatus? status,
    ContactMethod? contactMethod,
    DateTime? bookedAt,
    String? notes,
  }) {
    return AccommodationBooking(
      id: id ?? this.id,
      accommodationId: accommodationId ?? this.accommodationId,
      trailId: trailId ?? this.trailId,
      date: date ?? this.date,
      status: status ?? this.status,
      contactMethod: contactMethod ?? this.contactMethod,
      bookedAt: bookedAt ?? this.bookedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AccommodationBooking &&
        other.id == id &&
        other.accommodationId == accommodationId &&
        other.trailId == trailId &&
        other.date == date &&
        other.status == status &&
        other.contactMethod == contactMethod &&
        other.bookedAt == bookedAt &&
        other.notes == notes;
  }

  @override
  int get hashCode => Object.hash(
        id,
        accommodationId,
        trailId,
        date,
        status,
        contactMethod,
        bookedAt,
        notes,
      );

  @override
  String toString() =>
      'AccommodationBooking(id: $id, accommodation: $accommodationId, '
      'status: ${status.name}, date: ${date.toIso8601String()})';
}
