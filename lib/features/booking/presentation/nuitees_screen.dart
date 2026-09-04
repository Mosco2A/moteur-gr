import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../planning/models/planned_day.dart';
import '../../planning/providers/planned_days_provider.dart';
import '../../trek/domain/models/stage_accommodation.dart';
import '../domain/models/nuitee_type.dart';
import '../providers/nuitee_selections_provider.dart';

/// Ecran NUITEES — assistant « Reserver vos nuits » (PARITE GR20
/// `RefugeAssistantScreen`).
///
/// Assistant par nuit : pour chaque nuit du PROGRAMME du sentier courant,
/// l'utilisateur choisit un TYPE de nuitee (refuge / gite / bivouac / autre) et
/// coche l'etat reserve / a reserver. Bandeau de progression en haut, recap en
/// bas. Les donnees d'hebergement (nom du lieu, telephone) proviennent des
/// donnees du sentier (module `booking` -> [StageAccommodation] via Drift),
/// avec fallback gracieux si le sentier n'a pas d'hebergement reference.
///
/// Ecarts de modele assumes vs GR20 (cf. rapport) : le [PlannedDay] StepWays ne
/// porte ni nuit N0 (veille du depart) ni `nightCount` multiple ; chaque jour de
/// marche = une nuit. StepWays n'a pas non plus de compteur de progression
/// « planning » (pas d'equivalent `planningProgressProvider`) : le bandeau
/// affiche la progression locale (reserve / total) mais ne coche pas d'etape de
/// preparation globale.
///
/// Generique multi-sentiers : ZERO hardcode de localite ; hors systeme de peaux
/// (couleurs semantiques d'AppTheme + colorScheme). Tout libelle passe par Slang
/// (`t.nuitees.*`).
class NuiteesScreen extends ConsumerWidget {
  const NuiteesScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on planifie les nuitees.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = ref.watch(plannedDaysProvider(trailId));
    final selections = ref.watch(nuiteeSelectionsProvider);

    // Une nuit par jour de MARCHE (les jours de repos n'engendrent pas de nuit
    // a reserver differente : parite fonctionnelle GR20 qui exclut les repos).
    final nuiteesDays = days.where((d) => !d.isRestDay).toList();
    final totalNuitees = nuiteesDays.length;
    final bookedCount = nuiteesDays
        .where((d) => selections.isBooked(d.dayNumber))
        .length;
    final progress = totalNuitees > 0 ? bookedCount / totalNuitees : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(t.nuitees.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: t.nuitees.guideTooltip,
            onPressed: () => _showInfoSheet(context),
          ),
        ],
      ),
      body: SafeArea(
        child: nuiteesDays.isEmpty
            ? _EmptyState(trailId: trailId)
            : Column(
                children: [
                  _CompactInfoBar(
                    bookedCount: bookedCount,
                    totalNuitees: totalNuitees,
                    progress: progress,
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingBase,
                        vertical: AppTheme.spacingSm,
                      ),
                      itemCount: nuiteesDays.length,
                      itemBuilder: (context, index) {
                        final day = nuiteesDays[index];
                        return _NuiteeCard(
                          trailId: trailId,
                          day: day,
                          isBooked: selections.isBooked(day.dayNumber),
                          nuiteeType: selections.typeFor(day.dayNumber),
                          onToggle: () => ref
                              .read(nuiteeSelectionsProvider.notifier)
                              .toggleBooking(day.dayNumber),
                          onNuiteeTypeChanged: (type) => ref
                              .read(nuiteeSelectionsProvider.notifier)
                              .setNuiteeType(day.dayNumber, type),
                        );
                      },
                    ),
                  ),
                  _CompactSummary(
                    days: nuiteesDays,
                    selections: selections,
                    bookedCount: bookedCount,
                    totalNuitees: totalNuitees,
                  ),
                ],
              ),
      ),
    );
  }

  /// Guide des types de nuitees (parite GR20 `_showInfoSheet`) : fiche par type
  /// avec icone + description, en bottom-sheet.
  void _showInfoSheet(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusBottomSheet)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Row(
              children: [
                Icon(Icons.info_outline, color: scheme.primary, size: 24),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  t.nuitees.guide.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingBase),
            _infoItem(theme, NuiteeType.refuge, t.nuitees.guide.refuge),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(theme, NuiteeType.gite, t.nuitees.guide.gite),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(theme, NuiteeType.bivouac, t.nuitees.guide.bivouac),
            const SizedBox(height: AppTheme.spacingMd),
            _infoItem(
                theme, NuiteeType.autreHebergement, t.nuitees.guide.autre),
            const SizedBox(height: AppTheme.spacingLg),
            Center(
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(t.nuitees.guide.close,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoItem(ThemeData theme, NuiteeType type, String description) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingSm),
          decoration: BoxDecoration(
            color: scheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Icon(type.icon, size: 22, color: scheme.primary),
        ),
        const SizedBox(width: AppTheme.spacingMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type.label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bandeau compact en haut : rappel + progression (parite GR20
/// `_CompactInfoBar`).
class _CompactInfoBar extends StatelessWidget {
  const _CompactInfoBar({
    required this.bookedCount,
    required this.totalNuitees,
    required this.progress,
  });

  final int bookedCount;
  final int totalNuitees;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDone = bookedCount == totalNuitees && totalNuitees > 0;
    final barColor = isDone ? AppTheme.vertFacile : AppTheme.orangeDifficile;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      color: barColor.withAlpha(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.info_outline,
                  size: 20, color: theme.colorScheme.primary.withAlpha(180)),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.nuitees.infoBar,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: barColor.withAlpha(40),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  '$bookedCount / $totalNuitees',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: barColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: AppTheme.grisGranite.withAlpha(40),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'une nuit (parite GR20 `_RefugeCard`).
///
/// Affiche le nom reel de l'hebergement (donnees du sentier) selon le type
/// choisi, un selecteur de type (refuge / gite / bivouac / autre), l'etat
/// reserve (case), et une action Appeler quand un telephone est disponible.
/// Consomme les hebergements de l'etape via [nuiteeStageAccommodationsProvider]
/// (fallback gracieux : libelle generique si aucun hebergement reference).
class _NuiteeCard extends ConsumerWidget {
  const _NuiteeCard({
    required this.trailId,
    required this.day,
    required this.isBooked,
    required this.nuiteeType,
    required this.onToggle,
    required this.onNuiteeTypeChanged,
  });

  final String trailId;
  final PlannedDay day;
  final bool isBooked;
  final NuiteeType nuiteeType;
  final VoidCallback onToggle;
  final void Function(NuiteeType) onNuiteeTypeChanged;

  /// Etape d'arrivee du jour (sert a retrouver l'hebergement du lieu de nuit).
  int get _stageNumber =>
      day.stages.isNotEmpty ? day.stages.last.stageNumber : 0;

  Future<void> _callPhone(String phoneNumber) async {
    try {
      await launchUrl(Uri.parse('tel:${phoneNumber.replaceAll(' ', '')}'));
    } catch (_) {
      // Silencieux (parite GR20 : pas de blocage si l'appel echoue).
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accommodationsAsync = ref.watch(
      nuiteeStageAccommodationsProvider(
        (trailId: trailId, stageNumber: _stageNumber),
      ),
    );
    final accommodations = accommodationsAsync.maybeWhen(
      data: (l) => l,
      orElse: () => const <StageAccommodation>[],
    );

    // Hebergement correspondant au type choisi (sinon 1er dispo = fallback).
    final selectedAccom = _findForType(accommodations, nuiteeType);
    final accom = selectedAccom ??
        (accommodations.isNotEmpty ? accommodations.first : null);

    // Nom du lieu (donnees sentier) sinon libelle generique (fallback).
    final placeName = accom?.name ?? t.nuitees.card.noPlace;
    final phone = accom?.phone ?? '';

    // Types proposes : ceux presents dans les donnees + « Autre » toujours,
    // + bivouac en repli s'il ne reste qu'un choix (parite GR20).
    final availableTypes = _availableTypes(accommodations);

    final dayLabel = t.nuitees.card.dayLabel
        .replaceAll('{n}', day.dayNumber.toString());

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      color: isBooked ? scheme.primary.withAlpha(20) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        side: isBooked
            ? BorderSide(color: scheme.primary, width: 1.5)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge numero de jour.
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isBooked
                          ? scheme.primary.withAlpha(30)
                          : scheme.primary.withAlpha(40),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: isBooked
                            ? scheme.primary
                            : scheme.primary.withAlpha(80),
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
                  ),
                  const SizedBox(width: AppTheme.spacingMd),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          placeName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            decoration:
                                isBooked ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Badge type courant.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: scheme.secondary.withAlpha(30),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusChip),
                          ),
                          child: Text(
                            nuiteeType.label,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: scheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Selecteur de type (desactive quand la nuit est cochee,
                        // parite GR20 : decochez pour changer le type).
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: availableTypes.map((type) {
                            final isSelected = type == nuiteeType;
                            final isDisabled = isBooked && !isSelected;
                            return ConstrainedBox(
                              constraints: const BoxConstraints(
                                  minHeight: 48, minWidth: 48),
                              child: GestureDetector(
                                onTap:
                                    isBooked ? null : () => onNuiteeTypeChanged(type),
                                child: Tooltip(
                                  message: isDisabled
                                      ? t.nuitees.card.lockedHint
                                      : type.label,
                                  child: Opacity(
                                    opacity: isDisabled ? 0.35 : 1.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? scheme.primary.withAlpha(40)
                                            : AppTheme.grisGranite
                                                .withAlpha(15),
                                        borderRadius: BorderRadius.circular(
                                            AppTheme.radiusChip),
                                        border: Border.all(
                                          color: isSelected
                                              ? scheme.primary
                                              : AppTheme.grisGranite
                                                  .withAlpha(60),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            type.icon,
                                            size: 16,
                                            color: isSelected
                                                ? scheme.primary
                                                : AppTheme.grisGranite,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            type.label,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w400,
                                              color: isSelected
                                                  ? scheme.primary
                                                  : AppTheme.grisGranite,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        if (accommodations.length > 1) ...[
                          const SizedBox(height: 4),
                          Text(
                            t.nuitees.card.available.replaceAll(
                                '{count}', accommodations.length.toString()),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppTheme.grisGranite.withAlpha(150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Case reserve.
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isBooked
                          ? scheme.primary.withAlpha(30)
                          : AppTheme.orangeDifficile.withAlpha(20),
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusCard),
                      border: Border.all(
                        color: isBooked
                            ? scheme.primary
                            : AppTheme.orangeDifficile.withAlpha(80),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      isBooked ? Icons.check : Icons.radio_button_unchecked,
                      size: 20,
                      color: isBooked
                          ? scheme.primary
                          : AppTheme.orangeDifficile.withAlpha(120),
                    ),
                  ),
                ],
              ),
              // Action Appeler (masquee pour « autre hebergement », parite GR20).
              if (phone.isNotEmpty &&
                  nuiteeType != NuiteeType.autreHebergement) ...[
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () => _callPhone(phone),
                      icon: const Icon(Icons.phone, size: 18),
                      label: Text(
                        t.nuitees.card.call.replaceAll('{phone}', phone),
                        style: const TextStyle(fontSize: 14),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm),
                        foregroundColor: AppTheme.orangeDifficile,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
}

/// Recap compact en bas (parite GR20 `_CompactSummary`) : bouton de
/// confirmation si tout est reserve, sinon chips des nuits restantes.
class _CompactSummary extends StatelessWidget {
  const _CompactSummary({
    required this.days,
    required this.selections,
    required this.bookedCount,
    required this.totalNuitees,
  });

  final List<PlannedDay> days;
  final NuiteeSelectionsState selections;
  final int bookedCount;
  final int totalNuitees;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bookedCount == totalNuitees && totalNuitees > 0) {
      return Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: ElevatedButton.icon(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.check_circle),
          label: Text(t.nuitees.summary.allBooked),
        ),
      );
    }

    if (days.isEmpty) return const SizedBox.shrink();

    final missingDays =
        days.where((d) => !selections.isBooked(d.dayNumber)).toList();
    final bookedDays =
        days.where((d) => selections.isBooked(d.dayNumber)).toList();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.orangeDifficile.withAlpha(12),
        border: Border(
          top: BorderSide(color: AppTheme.grisGranite.withAlpha(40)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber,
                  size: 16, color: AppTheme.orangeDifficile),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                t.nuitees.summary.remaining
                    .replaceAll('{count}', missingDays.length.toString()),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.orangeDifficile,
                  fontSize: 14,
                ),
              ),
              if (bookedDays.isNotEmpty) ...[
                const Spacer(),
                Icon(Icons.check_circle,
                    size: 14, color: AppTheme.vertFacile.withAlpha(180)),
                const SizedBox(width: 4),
                Text(
                  t.nuitees.summary.done
                      .replaceAll('{count}', bookedDays.length.toString()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 14,
                    color: AppTheme.vertFacile,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: missingDays.map((day) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.orangeDifficile.withAlpha(20),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border:
                      Border.all(color: AppTheme.orangeDifficile.withAlpha(60)),
                ),
                child: Text(
                  t.nuitees.card.dayLabel
                      .replaceAll('{n}', day.dayNumber.toString()),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.orangeDifficile,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Etat vide — aucune nuit (programme non configure). Fallback gracieux :
/// invite a configurer l'itineraire (parite GR20 `_buildEmptyState`).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.trailId});

  final String trailId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cabin,
                size: 80, color: AppTheme.grisGranite.withAlpha(80)),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.nuitees.empty.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.nuitees.empty.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.grisGranite.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingXl),
            ElevatedButton.icon(
              onPressed: () => context.push('/trail/$trailId/itinerary'),
              icon: const Icon(Icons.route),
              label: Text(t.nuitees.empty.action),
            ),
          ],
        ),
      ),
    );
  }
}
