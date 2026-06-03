// E5.14a — Service de contacts d'urgence.
//
// Retourne les contacts personnels ordonnes par priorite
// + les numeros de secours automatiques (112, PGHM).
// Les numeros automatiques sont toujours presents en fin de liste.

import '../domain/models/emergency_contact.dart';

/// Numeros de secours automatiques — toujours presents.
///
/// Ces contacts ne sont pas modifiables par l'utilisateur.
/// Ils apparaissent toujours apres les contacts personnels.
const List<EmergencyContact> kAutomaticEmergencyContacts = [
  EmergencyContact(
    id: 'auto-112',
    name: 'Urgences europeennes',
    phone: '112',
    priority: 900,
    isAutomatic: true,
  ),
  EmergencyContact(
    id: 'auto-pghm',
    name: 'PGHM Corse (secours montagne)',
    phone: '04 92 22 22 22',
    priority: 901,
    isAutomatic: true,
  ),
];

/// Service de gestion des contacts d'urgence.
///
/// Combine contacts personnels (utilisateur) et numeros de secours
/// automatiques. Les contacts sont ordonnes par priorite croissante.
class EmergencyContactsService {
  EmergencyContactsService();

  /// Contacts personnels de l'utilisateur.
  final List<EmergencyContact> _personalContacts = [];

  /// Retourne tous les contacts : personnels tries + automatiques.
  ///
  /// Les contacts personnels sont ordonnes par priorite croissante.
  /// Les numeros de secours automatiques viennent toujours en dernier.
  List<EmergencyContact> getContacts() {
    final sorted = List<EmergencyContact>.from(_personalContacts)
      ..sort((a, b) => a.priority.compareTo(b.priority));
    return [...sorted, ...kAutomaticEmergencyContacts];
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
    return List.unmodifiable(kAutomaticEmergencyContacts);
  }
}
