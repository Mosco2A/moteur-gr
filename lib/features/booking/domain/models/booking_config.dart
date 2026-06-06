// Configuration de reservation pour un parcours.
//
// Definit si la reservation est activee pour un trail,
// les methodes de contact disponibles, et les infos partenaire.
// Feature flag : desactive par defaut.

/// Configuration de reservation pour un trail.
///
/// Immutable -- utiliser [copyWith] pour les modifications.
/// Serialisable JSON pour Firestore et cache local.
class BookingConfig {
  const BookingConfig({
    required this.trailId,
    this.bookingEnabled = false,
    this.bookingMethods = const [],
    this.partnerUrl,
    this.partnerPhone,
    this.partnerEmail,
  });

  /// Identifiant du parcours / trek.
  final String trailId;

  /// Reservation activee pour ce trail (feature flag, defaut FALSE).
  final bool bookingEnabled;

  /// Methodes de reservation disponibles ('phone', 'email', 'web', 'api').
  final List<String> bookingMethods;

  /// URL du site partenaire de reservation.
  final String? partnerUrl;

  /// Telephone du partenaire.
  final String? partnerPhone;

  /// Email du partenaire.
  final String? partnerEmail;

  /// Au moins une methode de reservation est-elle configuree ?
  bool get hasBookingMethods => bookingMethods.isNotEmpty;

  /// Le booking est-il fonctionnel (active + au moins 1 methode) ?
  bool get isOperational => bookingEnabled && hasBookingMethods;

  /// Conversion depuis JSON (Firestore / cache local).
  factory BookingConfig.fromJson(Map<String, dynamic> json) {
    return BookingConfig(
      trailId: json['trailId'] as String,
      bookingEnabled: json['bookingEnabled'] as bool? ?? false,
      bookingMethods: (json['bookingMethods'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      partnerUrl: json['partnerUrl'] as String?,
      partnerPhone: json['partnerPhone'] as String?,
      partnerEmail: json['partnerEmail'] as String?,
    );
  }

  /// Conversion vers JSON (Firestore / cache local).
  Map<String, dynamic> toJson() {
    return {
      'trailId': trailId,
      'bookingEnabled': bookingEnabled,
      'bookingMethods': bookingMethods,
      'partnerUrl': partnerUrl,
      'partnerPhone': partnerPhone,
      'partnerEmail': partnerEmail,
    };
  }

  /// Copie avec modification.
  BookingConfig copyWith({
    String? trailId,
    bool? bookingEnabled,
    List<String>? bookingMethods,
    String? partnerUrl,
    String? partnerPhone,
    String? partnerEmail,
  }) {
    return BookingConfig(
      trailId: trailId ?? this.trailId,
      bookingEnabled: bookingEnabled ?? this.bookingEnabled,
      bookingMethods: bookingMethods ?? this.bookingMethods,
      partnerUrl: partnerUrl ?? this.partnerUrl,
      partnerPhone: partnerPhone ?? this.partnerPhone,
      partnerEmail: partnerEmail ?? this.partnerEmail,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! BookingConfig) return false;
    if (other.trailId != trailId) return false;
    if (other.bookingEnabled != bookingEnabled) return false;
    if (other.partnerUrl != partnerUrl) return false;
    if (other.partnerPhone != partnerPhone) return false;
    if (other.partnerEmail != partnerEmail) return false;
    if (other.bookingMethods.length != bookingMethods.length) return false;
    for (int i = 0; i < bookingMethods.length; i++) {
      if (other.bookingMethods[i] != bookingMethods[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        trailId,
        bookingEnabled,
        Object.hashAll(bookingMethods),
        partnerUrl,
        partnerPhone,
        partnerEmail,
      );

  @override
  String toString() =>
      'BookingConfig(trail: $trailId, enabled: $bookingEnabled, '
      'methods: $bookingMethods)';
}
