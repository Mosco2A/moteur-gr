import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/stage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/models/itinerary_day.dart';
import '../../providers/itinerary_providers.dart';

/// Ecran ITINERAIRE (parite GR20).
///
/// Reproduit le role de l'ecran « Itineraire » de GR20 cote StepWays : le
/// DEROULE des etapes du sentier courant, jour par jour, avec les infos par
/// etape (distance, D+, D-, duree estimee, difficulte) et des ACTIONS (voir le
/// detail de l'etape, voir sur la carte). Avant ce lot, la carte « Itineraire »
/// du HUB faisait `context.go('/map')` : la pile de navigation etait remplacee
/// (bascule d'onglet du shell) et le retour depuis la carte plantait
/// (`currentConfiguration.isNotEmpty`). Cet ecran est desormais une route
/// hors-shell atteinte par `context.push` -> retour propre vers le HUB.
///
/// Generique : alimente par [itineraryProvider] (etapes du sentier actif +
/// config), ZERO hardcode de localite. Hors systeme de peaux (AppCard, couleurs
/// semantiques d'AppTheme). Tout texte via Slang (t.itinerary.* / t.stage.*).
class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on affiche l'itineraire.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(itineraryProvider.select((a) => a));

    return Scaffold(
      appBar: AppBar(title: Text(t.itinerary.title)),
      body: itineraryAsync.when(
        loading: () => LoadingView(message: t.itinerary.loading),
        error: (error, _) => ErrorView(
          message: t.itinerary.error,
          onRetry: () => ref.invalidate(itineraryProvider),
        ),
        data: (days) {
          if (days.isEmpty) {
            return _EmptyItinerary();
          }
          return _ItineraryContent(days: days);
        },
      ),
    );
  }
}

/// Etat vide : aucune etape chargee pour le sentier.
class _EmptyItinerary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.route_outlined,
                size: 72, color: theme.colorScheme.onSurface.withAlpha(80)),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.itinerary.empty,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.itinerary.emptyHint,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(160),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu : en-tete de totaux + liste des jours (deroule des etapes).
class _ItineraryContent extends StatelessWidget {
  const _ItineraryContent({required this.days});

  final List<ItineraryDay> days;

  @override
  Widget build(BuildContext context) {
    final totalKm = days.fold<double>(0, (s, d) => s + d.totalDistance);
    final totalGain = days.fold<int>(0, (s, d) => s + d.totalElevation);
    final stageCount = days.fold<int>(0, (s, d) => s + d.stageCount);

    return Column(
      children: [
        _ItineraryStatsHeader(
          totalKm: totalKm,
          totalGain: totalGain,
          dayCount: days.length,
          stageCount: stageCount,
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
            itemCount: days.length,
            itemBuilder: (context, index) => _DayCard(day: days[index]),
          ),
        ),
      ],
    );
  }
}

/// En-tete de statistiques globales (parite GR20 _StatsHeader).
class _ItineraryStatsHeader extends StatelessWidget {
  const _ItineraryStatsHeader({
    required this.totalKm,
    required this.totalGain,
    required this.dayCount,
    required this.stageCount,
  });

  final double totalKm;
  final int totalGain;
  final int dayCount;
  final int stageCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      color: theme.colorScheme.primary.withAlpha(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(
              label: t.itinerary.totalDistance,
              value: '${totalKm.toStringAsFixed(0)} km'),
          _Stat(
              label: t.itinerary.totalElevation, value: '$totalGain m'),
          _Stat(label: t.itinerary.day, value: '$dayCount'),
          _Stat(label: t.itinerary.stages, value: '$stageCount'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}

/// Carte d'un jour : en-tete (Jour N, nb etapes, distance) + etapes du jour.
///
/// Parite GR20 : les etapes du jour sont deroulees avec leurs infos et une
/// action (tap -> detail de l'etape). Un jour sans etape (repos) est signale.
class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingXs,
      ),
      padding: EdgeInsets.zero,
      child: ExpansionTile(
        initiallyExpanded: day.dayNumber == 1,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Text('${day.dayNumber}'),
        ),
        title: Text('${t.itinerary.day} ${day.dayNumber}'),
        subtitle: Text(
          day.stageCount == 0
              ? t.itinerary.restDay
              : '${t.itinerary.stageCount.replaceAll('{count}', '${day.stageCount}')}'
                  '  -  ${day.totalDistance.toStringAsFixed(1)} km'
                  '  -  D+ ${day.totalElevation} m',
        ),
        children: day.stages
            .map((stage) => _StageTile(stage: stage))
            .toList(growable: false),
      ),
    );
  }
}

/// Tuile d'une etape : infos (distance, D+, D-, duree) + chip difficulte +
/// actions (voir l'etape, voir sur la carte). Tap = detail de l'etape.
class _StageTile extends StatelessWidget {
  const _StageTile({required this.stage});

  final StageModel stage;

  String _difficultyLabel() {
    switch (stage.difficulty) {
      case 'easy':
        return t.stage.difficulty.easy;
      case 'moderate':
        return t.stage.difficulty.moderate;
      case 'hard':
        return t.stage.difficulty.hard;
      case 'extreme':
        return t.stage.difficulty.extreme;
      default:
        return stage.difficulty;
    }
  }

  Color _difficultyColor() {
    switch (stage.difficulty) {
      case 'easy':
        return AppTheme.vertFacile;
      case 'moderate':
        return AppTheme.jauneModere;
      case 'hard':
        return AppTheme.orangeDifficile;
      case 'extreme':
        return AppTheme.rougeExtreme;
      default:
        return AppTheme.grisGranite;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diffColor = _difficultyColor();

    return InkWell(
      onTap: () => context.push('/stages/${stage.stageNumber}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          AppTheme.spacingSm,
          AppTheme.spacingBase,
          AppTheme.spacingSm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pastille numero d'etape teintee par difficulte.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: diffColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                border: Border.all(color: diffColor, width: 2),
              ),
              alignment: Alignment.center,
              child: Text(
                '${stage.stageNumber}',
                style: theme.textTheme.labelLarge?.copyWith(color: diffColor),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  // Infos par etape (parite GR20 : distance, D+, D-).
                  Wrap(
                    spacing: AppTheme.spacingMd,
                    runSpacing: AppTheme.spacingXs,
                    children: [
                      _MiniStat(
                        icon: Icons.straighten,
                        label: '${stage.distanceKm.toStringAsFixed(1)} km',
                      ),
                      _MiniStat(
                        icon: Icons.arrow_upward,
                        label: '${stage.elevationGainM} m',
                        color: AppTheme.rougeExtreme,
                      ),
                      _MiniStat(
                        icon: Icons.arrow_downward,
                        label: '${stage.elevationLossM} m',
                        color: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingXs),
                  Row(
                    children: [
                      // Chip difficulte (semantique).
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.spacingSm,
                          vertical: AppTheme.spacingXs,
                        ),
                        decoration: BoxDecoration(
                          color: diffColor.withAlpha(40),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusChip),
                          border: Border.all(color: diffColor),
                        ),
                        child: Text(
                          _difficultyLabel(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: diffColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Action (parite GR20) : ouvrir le detail de l'etape.
                      // Affordance de navigation vers le detail.
                      Icon(Icons.chevron_right,
                          color: theme.colorScheme.onSurface.withAlpha(120)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini statistique (icone + valeur) pour les infos d'une etape.
class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = color ?? theme.colorScheme.onSurface.withAlpha(160);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 3),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
