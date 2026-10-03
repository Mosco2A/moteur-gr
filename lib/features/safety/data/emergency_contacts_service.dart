/// Seul le 112 est universel ; les secours regionaux viennent de la
/// configuration du sentier, parce qu'ils changent avec le massif.
library;

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
  ///
  /// ILS NE SONT PLUS LA SOURCE DE VERITE (tache 630). Cette liste est un CACHE
  /// de ce que porte la fiche d'urgence, alimente par [loadFromSheet].
  ///
  /// CE QU'ELLE ETAIT AVANT, ET C'EST LA MESURE QUI A DECLENCHE LE CHANGEMENT :
  /// la SEULE copie. Elle vivait en memoire, personne ne la persistait, et
  /// `addContact` n'etait appele par AUCUNE ligne de `lib/`. Autrement dit les
  /// contacts a prevenir etaient un modele sans ecran de saisie et sans disque :
  /// meme remplis, ils mouraient avec le processus. Ils vivent maintenant dans la
  /// fiche (`HealthInfo.emergencyContacts`), donc dans le fichier du dossier
  /// exclu de la sauvegarde, avec le meme effacement que le reste.
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

  /// REMPLACE LES CONTACTS PERSONNELS PAR CEUX DE LA FICHE D'URGENCE (tache 630).
  ///
  /// REMPLACE, ET NE FUSIONNE PAS : la fiche est la source unique. Fusionner
  /// ferait survivre ici un contact que le randonneur vient de retirer de sa
  /// fiche — et un numero d'urgence perime est exactement ce qu'on ne veut pas
  /// laisser sur un ecran verrouille.
  void loadFromSheet(List<EmergencyContact> contacts) {
    _personalContacts
      ..clear()
      ..addAll(contacts);
  }

  /// Ajoute un contact personnel au cache.
  ///
  /// CONSERVE POUR LES TESTS ET LES APPELS EXISTANTS. En production, la saisie
  /// passe par l'ecran de la fiche puis par [loadFromSheet] : ce qui
  /// s'ajoute ici seulement ne serait pas persiste.
  void addContact(EmergencyContact contact) {
    _personalContacts.add(contact);
  }

  /// Supprime un contact personnel par id.
  void removeContact(String id) {
    _personalContacts.removeWhere((c) => c.id == id);
  }

  /// Retourne uniquement les contacts de secours automatiques.
  List<EmergencyContact> getAutomaticContacts() {
    return List.unmodifiable([
      ...kUniversalEmergencyContacts,
      ..._trailContacts,
    ]);
  }
}
