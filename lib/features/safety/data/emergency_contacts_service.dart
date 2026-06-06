// E5.14a — Service de contacts d'urgence.
//
// Retourne les contacts personnels ordonnes par priorite
// + le 112 universel + les secours regionaux du sentier actif
// (fournis par TrailConfig.emergencyNumbers, jamais hardcodes).

import '../../../core/config/trail_config.dart';
import '../domain/models/emergency_contact.dart';

/// Numeros de secours universels — toujours presents.
///
/// Seul le 112 (urgences europeennes) est universel : il est
/// valable quel que soit le sentier. Les secours regionaux
/// (secours montagne local, etc.) viennent de la configuration
/// du sentier actif via [TrailConfig.emergencyNumbers].
const List<EmergencyContact> kUniversalEmergencyContacts = [
  EmergencyContact(
    id: 'auto-112',
    name: 'Urgences europeennes',
    phone: '112',
    priority: 900,
    isAutomatic: true,
  ),
];

/// Service de gestion des contacts d'urgence.
///
/// Combine contacts personnels (utilisateur), 112 universel et
/// secours regionaux du sentier actif. Les contacts personnels
/// sont ordonnes par priorite croissante ; les numeros de secours
/// automatiques viennent toujours en dernier.
class EmergencyContactsService {
  EmergencyContactsService({
    List<TrailEmergencyNumber> trailEmergencyNumbers = const [],
  }) : _trailContacts = [
          for (var i = 0; i < trailEmergencyNumbers.length; i++)
            EmergencyContact(
              id: 'auto-trail-$i',
              name: trailEmergencyNumbers[i].name,
              phone: trailEmergencyNumbers[i].phone,
              priority: 901 + i,
              isAutomatic: true,
            ),
        ];

  /// Secours regionaux du sentier actif (depuis TrailConfig).
  final List<EmergencyContact> _trailContacts;

  /// Contacts personnels de l'utilisateur.
  final List<EmergencyContact> _personalContacts = [];

  /// Retourne tous les contacts : personnels tries + automatiques.
  ///
  /// Les contacts personnels sont ordonnes par priorite croissante.
  /// Les numeros de secours automatiques (112 puis secours
  /// regionaux du sentier) viennent toujours en dernier.
  List<EmergencyContact> getContacts() {
    final sorted = List<EmergencyContact>.from(_personalContacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return [...sorted, ...kUniversalEmergencyContacts, ..._trailContacts];
  }

  /// Ajoute un contact personnel.
  void addContact(EmergencyContact contact) {
    _personalContacts.add(contact);
  }

  /// Supprime un contact personnel par id.
  void removeContact(String id) {
    _personalContacts.removeWhere((c) => c.id == id);
  }

  /// Retourne uniquement les contacts de secours automatiques.
  List<EmergencyContact> getAutomaticContacts() {
    return List.unmodifiable(
      [...kUniversalEmergencyContacts, ..._trailContacts],
    );
  }
}
