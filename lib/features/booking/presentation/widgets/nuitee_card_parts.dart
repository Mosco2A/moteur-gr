/// La carte d'une nuit, en sous-widgets nommes : chacun recoit ses donnees en
/// parametres nommes, donc chacun se reconstruit independamment des autres
/// (ECR-28) — ce qu'une methode privee de l'ecran ne sait pas faire.
///
/// L'ETAT RESTE CHEZ L'ECRAN : aucun de ces widgets ne lit un provider ni ne
/// garde d'etat. Ils affichent ce qu'on leur passe et rappellent les callbacks
/// de la carte parente.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../domain/planned_day.dart';
import '../../../../domain/stage_accommodation.dart';
import '../../../../i18n/translations.g.dart';
import '../../domain/models/nuitee_type.dart';
import 'nuitee_card_badges.dart';

/// Le contenu de la carte d'une nuit : la ligne principale, l'adresse du lieu
/// et l'action d'appel.
///
/// Les hebergements arrivent DEJA LUS de l'ecran ([accommodations]) : c'est lui
/// qui garde le `ref` et la lecture du provider.
class NuiteeCardContents extends StatelessWidget {
  const NuiteeCardContents({
    required this.day,
    required this.accommodations,
    required this.nuiteeType,
    required this.isBooked,
    required this.isEveOfDeparture,
    required this.onNuiteeTypeChanged,
    super.key,
  });

  /// Le jour du programme auquel cette nuit se rattache.
  final PlannedDay day;

  /// Les hebergements de l'etape de couchage, lus par l'ecran.
  final List<StageAccommodation> accommodations;

  /// Le type de nuitee choisi pour cette nuit.
  final NuiteeType nuiteeType;

  /// Vrai quand la nuit est cochee « reserve ».
  final bool isBooked;

  /// Nuit N0, la veille du depart (correctif L7-2).
  final bool isEveOfDeparture;

  /// Rappele quand le randonneur change de type de nuitee.
  final void Function(NuiteeType) onNuiteeTypeChanged;

  @override
  Widget build(BuildContext context) {
    // Hebergement correspondant au type choisi (sinon 1er dispo = fallback).
    final selectedAccom = _findForType(accommodations, nuiteeType);
    final accom =
        selectedAccom ??
        (accommodations.isNotEmpty ? accommodations.first : null);

    // Nom du lieu (donnees sentier) sinon libelle generique (fallback).
    final placeName = accom?.name ?? t.nuitees.card.noPlace;
    final phone = accom?.phone ?? '';

    // Types proposes : ceux presents dans les donnees + « Autre » toujours,
    // + bivouac en repli s'il ne reste qu'un choix (parite GR20).
    final availableTypes = _availableTypes(accommodations);

    // L7-2 : la nuit N0 n'est pas le « jour 0 », c'est la veille. Elle porte
    // son propre badge plutot qu'un « J0 » qui ne veut rien dire.
    final dayLabel = isEveOfDeparture
        ? t.nuitees.card.eveBadge
        : t.nuitees.card.dayLabel.replaceAll('{n}', day.dayNumber.toString());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NuiteeCardRow(
          dayLabel: dayLabel,
          isBooked: isBooked,
          placeName: placeName,
          isRestDay: day.isRestDay,
          isEveOfDeparture: isEveOfDeparture,
          nuiteeType: nuiteeType,
          availableTypes: availableTypes,
          onNuiteeTypeChanged: onNuiteeTypeChanged,
          accommodationCount: accommodations.length,
        ),
        if (accom != null && nuiteeType != NuiteeType.autreHebergement)
          NuiteeAddressLine(accom: accom),
        if (phone.isNotEmpty && nuiteeType != NuiteeType.autreHebergement) ...[
          const SizedBox(height: AppTheme.spacingSm),
          NuiteeCallRow(phone: phone),
        ],
      ],
    );
  }
}

/// La ligne principale de la carte : le badge du jour, le bloc du lieu et la
/// case « reserve ».
class _NuiteeCardRow extends StatelessWidget {
  const _NuiteeCardRow({
    required this.dayLabel,
    required this.isBooked,
    required this.placeName,
    required this.isRestDay,
    required this.isEveOfDeparture,
    required this.nuiteeType,
    required this.availableTypes,
    required this.onNuiteeTypeChanged,
    required this.accommodationCount,
    super.key,
  });

  /// « J3 » ou le libelle de la veille du depart.
  final String dayLabel;

  /// Vrai quand la nuit est cochee « reserve ».
  final bool isBooked;

  /// Le nom du lieu de couchage, ou le libelle « aucun lieu ».
  final String placeName;

  /// Vrai pour un jour de repos (R5, LOT L10).
  final bool isRestDay;

  /// Nuit N0, la veille du depart (correctif L7-2).
  final bool isEveOfDeparture;

  /// Le type de nuitee choisi pour cette nuit.
  final NuiteeType nuiteeType;

  /// Les types proposes par les hebergements de l'etape.
  final Set<NuiteeType> availableTypes;

  /// Rappele quand le randonneur change de type de nuitee.
  final void Function(NuiteeType) onNuiteeTypeChanged;

  /// Combien d'hebergements l'etape propose, pour la mention « n disponibles ».
  final int accommodationCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NuiteeDayBadge(dayLabel: dayLabel, isBooked: isBooked),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NuiteeHeadline(
                placeName: placeName,
                isBooked: isBooked,
                isRestDay: isRestDay,
                isEveOfDeparture: isEveOfDeparture,
                nuiteeType: nuiteeType,
              ),
              NuiteeTypePicker(
                availableTypes: availableTypes,
                nuiteeType: nuiteeType,
                onNuiteeTypeChanged: onNuiteeTypeChanged,
                accommodationCount: accommodationCount,
              ),
            ],
          ),
        ),
        NuiteeBookedMark(isBooked: isBooked),
      ],
    );
  }
}

/// Le badge du numero de jour, a gauche de la carte.
class _NuiteeDayBadge extends StatelessWidget {
  const _NuiteeDayBadge({
    required this.dayLabel,
    required this.isBooked,
    super.key,
  });

  /// « J3 » ou le libelle de la veille du depart.
  final String dayLabel;

  /// Vrai quand la nuit est cochee « reserve ».
  final bool isBooked;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isBooked
            ? scheme.primary.withAlpha(30)
            : scheme.primary.withAlpha(40),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: isBooked ? scheme.primary : scheme.primary.withAlpha(80),
        ),
      ),
      child: Center(
        child: Text(
          dayLabel,
          style: theme.textTheme.labelLarge?.copyWith(
            color: scheme.primary,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Le haut du bloc du lieu : son nom, les badges de repos et de veille du
/// depart, et le badge du type courant.
class _NuiteeHeadline extends StatelessWidget {
  const _NuiteeHeadline({
    required this.placeName,
    required this.isBooked,
    required this.isRestDay,
    required this.isEveOfDeparture,
    required this.nuiteeType,
    super.key,
  });

  /// Le nom du lieu de couchage, ou le libelle « aucun lieu ».
  final String placeName;

  /// Vrai quand la nuit est cochee « reserve » — le nom est alors barre.
  final bool isBooked;

  /// Vrai pour un jour de repos (R5, LOT L10).
  final bool isRestDay;

  /// Nuit N0, la veille du depart (correctif L7-2).
  final bool isEveOfDeparture;

  /// Le type de nuitee choisi pour cette nuit.
  final NuiteeType nuiteeType;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          placeName,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            decoration: isBooked ? TextDecoration.lineThrough : null,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        if (isRestDay) ...[
          const NuiteeRestDayBadge(),
          const SizedBox(height: 2),
        ],
        if (isEveOfDeparture) ...[
          const NuiteeEveBadge(),
          const SizedBox(height: 2),
        ],
        NuiteeTypeBadge(nuiteeType: nuiteeType),
      ],
    );
  }
}

/// Cherche l'hebergement dont le type correspond au [NuiteeType] choisi.
/// Mappe les types de donnees (String libre du sentier) vers les 4 choix.
StageAccommodation? _findForType(
  List<StageAccommodation> accommodations,
  NuiteeType type,
) {
  if (accommodations.isEmpty) return null;
  for (final a in accommodations) {
    if (_mapType(a.type) == type) return a;
  }
  return null;
}

/// Types disponibles pour cette nuit (parite GR20 `availableTypes`) : ceux
/// presents dans les donnees + « Autre » toujours, + bivouac en repli si un
/// seul choix, garantissant au moins deux options.
Set<NuiteeType> _availableTypes(List<StageAccommodation> accommodations) {
  final types = <NuiteeType>{};
  for (final a in accommodations) {
    types.add(_mapType(a.type));
  }
  types.add(NuiteeType.autreHebergement);
  if (types.length == 1) types.add(NuiteeType.bivouac);
  return types;
}

/// Mappe un type de donnees d'hebergement (String libre) vers l'un des 4
/// [NuiteeType] de l'assistant (parite GR20 : hotel/camping/bergerie -> autre).
NuiteeType _mapType(AccommodationType type) {
  switch (type) {
    case AccommodationTypeValues.refuge:
      return NuiteeType.refuge;
    case AccommodationTypeValues.gite:
      return NuiteeType.gite;
    case AccommodationTypeValues.bivouac:
      return NuiteeType.bivouac;
    case AccommodationTypeValues.hotel:
    case AccommodationTypeValues.camping:
    case AccommodationTypeValues.bergerie:
      return NuiteeType.autreHebergement;
    default:
      return NuiteeType.autreHebergement;
  }
}
