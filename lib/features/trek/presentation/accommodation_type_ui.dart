import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';
import '../domain/models/stage_accommodation.dart';

/// Mapping UI des types d'hebergement (#81752).
///
/// Le type est un String libre defini par le JSON du sentier : les valeurs
/// connues ([AccommodationTypeValues]) ont un label i18n et une icone dedies,
/// toute valeur inconnue est affichee avec un fallback GENERIQUE — la valeur
/// d'origine n'est jamais alteree.

/// Icone associee au type d'hebergement.
IconData accommodationTypeIcon(AccommodationType type) {
  switch (type) {
    case AccommodationTypeValues.refuge:
      return Icons.house;
    case AccommodationTypeValues.bergerie:
      return Icons.cabin;
    case AccommodationTypeValues.gite:
      return Icons.cottage;
    case AccommodationTypeValues.hotel:
      return Icons.hotel;
    case AccommodationTypeValues.camping:
      return Icons.park;
    case AccommodationTypeValues.bivouac:
      return Icons.nights_stay;
    default:
      // Type inconnu : icone generique hebergement.
      return Icons.holiday_village;
  }
}

/// Libelle i18n du type d'hebergement.
///
/// Fallback generique : un type inconnu est affiche tel quel (donnee
/// preservee du JSON sentier), jamais remplace par un type connu.
String accommodationTypeLabel(AccommodationType type) {
  final types = t.accommodation.types;
  switch (type) {
    case AccommodationTypeValues.refuge:
      return types.refuge;
    case AccommodationTypeValues.bergerie:
      return types.bergerie;
    case AccommodationTypeValues.gite:
      return types.gite;
    case AccommodationTypeValues.hotel:
      return types.hotel;
    case AccommodationTypeValues.camping:
      return types.camping;
    case AccommodationTypeValues.bivouac:
      return types.bivouac;
    default:
      return type;
  }
}
