/// Les valeurs de la fiche medicale en cours d'edition : ses controleurs de
/// champ, ses listes fermees et ses cartes, et leur correspondance avec la
/// fiche stockee.
///
/// Bibliotheque de l'ecran `health_info_screen.dart` (lot 645-06b).
///
/// POURQUOI CET ETAT N'EST PAS DESCENDU DANS LES SECTIONS. Chaque valeur
/// ci-dessous est lue par l'ecran pour ENREGISTRER la fiche, ecrite par lui au
/// CHARGEMENT, et remise a zero par lui a l'EFFACEMENT : aucune n'est locale a
/// la section qui l'affiche. Elles restent donc la propriete de l'etat de
/// l'ecran, qui cree cet objet, le modifie sous `setState` et le libere ; ce
/// fichier ne porte que la responsabilite « champs <-> fiche ».
library;

import 'package:flutter/widgets.dart';

import '../domain/health_bounds.dart';
import '../domain/models/emergency_contact.dart';
import '../domain/models/health_info.dart';
import 'health_info_inputs.dart';

/// Les valeurs de la fiche en cours d'edition, dans l'ordre ou un secouriste
/// les lit.
class HealthInfoFormData {
  // [1] QUI

  /// Nom et prenom.
  final fullNameController = TextEditingController();

  /// Adresse postale.
  final addressController = TextEditingController();

  /// Date de naissance, forme ISO `AAAA-MM-JJ` (vide si non renseignee).
  String birthDate = '';

  // [2] QUI PREVENIR

  /// Les contacts a prevenir, une ligne en edition par contact.
  final List<ContactLineDraft> contacts = [];

  // [3] VITAL

  /// Allergies.
  final allergiesController = TextEditingController();

  /// Traitements en cours.
  final treatmentsController = TextEditingController();

  /// Antecedents.
  final conditionsController = TextEditingController();

  /// Groupe sanguin, valeur de la liste fermee (null si non choisi).
  String? bloodType;

  /// Don d'organes, valeur de la liste fermee (null si non choisi).
  String? organDonor;

  /// LA VALEUR DE GROUPE SANGUIN LUE SUR LE DISQUE ET NON RECONNUE.
  ///
  /// Elle n'est PAS effacee : elle est montree au randonneur pour qu'il
  /// choisisse (consigne 630 : « les fiches deja saisies ne perdent RIEN »).
  String bloodTypeHerite = '';

  // [4] ADMINISTRATIF

  /// Medecin traitant.
  final doctorController = TextEditingController();

  /// Numero d'assurance.
  final insuranceController = TextEditingController();

  /// Fichier de la photo de la carte Vitale (vide si aucune).
  String carteVitale = '';

  /// Fichier de la photo de la carte de mutuelle (vide si aucune).
  String carteMutuelle = '';

  /// Remplit les champs avec la fiche [info] lue sur le disque.
  void fill(HealthInfo info) {
    fullNameController.text = info.fullName;
    addressController.text = info.address;
    birthDate = info.birthDate;
    contacts
      ..forEach((l) => l.dispose())
      ..clear()
      ..addAll(
        info.emergencyContacts.map(
          (c) => ContactLineDraft(nom: c.name, telephone: c.phone),
        ),
      );
    allergiesController.text = info.allergies;
    treatmentsController.text = info.treatments;
    conditionsController.text = info.conditions;
    bloodType = valeurListeGroupeSanguin(info.bloodType);
    bloodTypeHerite = estGroupeSanguinHerite(info.bloodType)
        ? info.bloodType
        : '';
    organDonor = valeurListeDonOrganes(info.organDonor);
    doctorController.text = info.doctorContact;
    insuranceController.text = info.insuranceNumber;
    carteVitale = info.carteVitaleFichier;
    carteMutuelle = info.carteMutuelleFichier;
  }

  /// Assemble la fiche a partir des champs de l'ecran.
  ///
  /// LES CONTACTS VIDES SONT JETES ICI, PAS AILLEURS : une ligne ouverte puis
  /// laissee blanche ne doit pas devenir un contact sans nom ni numero sur
  /// l'ecran verrouille d'un blesse.
  HealthInfo compose() {
    final composed = <EmergencyContact>[];
    for (var i = 0; i < contacts.length; i++) {
      final ligne = contacts[i];
      final nom = ligne.nomCtrl.text.trim();
      final tel = ligne.telCtrl.text.trim();
      if (nom.isEmpty && tel.isEmpty) continue;
      composed.add(
        EmergencyContact(
          // L'IDENTIFIANT EST LE RANG, ET C'EST SUFFISANT : ces contacts ne sont
          // references par rien d'autre que la fiche qui les porte.
          id: 'perso-$i',
          name: nom,
          phone: tel,
          // La priorite suit l'ordre de saisie : le premier nomme est le premier
          // appele. C'est ce que le randonneur croit en les rangeant.
          priority: i + 1,
        ),
      );
    }
    return HealthInfo(
      fullName: fullNameController.text.trim(),
      birthDate: birthDate,
      address: addressController.text.trim(),
      emergencyContacts: composed,
      allergies: allergiesController.text.trim(),
      treatments: treatmentsController.text.trim(),
      conditions: conditionsController.text.trim(),
      // PLUS DE NORMALISATION A FAIRE : la valeur vient d'une liste fermee, elle
      // est deja canonique. C'est tout l'interet de fermer la liste.
      bloodType: bloodType ?? '',
      organDonor: organDonor ?? '',
      doctorContact: doctorController.text.trim(),
      insuranceNumber: insuranceController.text.trim(),
      carteVitaleFichier: carteVitale,
      carteMutuelleFichier: carteMutuelle,
    );
  }

  /// Vide tous les champs (apres l'effacement de la fiche).
  void clear() {
    fullNameController.clear();
    addressController.clear();
    birthDate = '';
    for (final ligne in contacts) {
      ligne.dispose();
    }
    contacts.clear();
    allergiesController.clear();
    treatmentsController.clear();
    conditionsController.clear();
    bloodType = null;
    bloodTypeHerite = '';
    organDonor = null;
    doctorController.clear();
    insuranceController.clear();
    carteVitale = '';
    carteMutuelle = '';
  }

  /// Libere tous les controleurs.
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();
    for (final ligne in contacts) {
      ligne.dispose();
    }
    allergiesController.dispose();
    treatmentsController.dispose();
    conditionsController.dispose();
    doctorController.dispose();
    insuranceController.dispose();
  }
}
