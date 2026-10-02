/// La traduction d'un type d'hebergement libre vers un libelle et une icone,
/// avec repli generique — la valeur brute n'est jamais ecrasee.
library;

import '../../../i18n/translations.g.dart';
import '../domain/models/stage_accommodation.dart';
import '../../../core/branding/stepways_icons.dart';

/// Mapping UI des types d'hebergement (#81752).
///
/// Le type est un String libre defini par le JSON du sentier : les valeurs
/// connues ([AccommodationTypeValues]) ont un label i18n et une icone dedies,
/// toute valeur inconnue est affichee avec un fallback GENERIQUE — la valeur
/// d'origine n'est jamais alteree.

/// Icone associee au type d'hebergement.
String accommodationTypeIcon(AccommodationType type) {
  switch (type) {
    case AccommodationTypeValues.refuge:
      return StepwaysIcons.hebergement;
    case AccommodationTypeValues.bergerie:
      return StepwaysIcons.nuitees;
    case AccommodationTypeValues.gite:
      return StepwaysIcons.hebergement;
    case AccommodationTypeValues.hotel:
      return StepwaysIcons.hebergement;
    case AccommodationTypeValues.camping:
      return StepwaysIcons.foret;
    case AccommodationTypeValues.bivouac:
      return StepwaysIcons.nuitees;
    default:
      // Type inconnu : icone generique hebergement.
      return StepwaysIcons.hebergement;
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
