import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/models/stage.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../domain/models/itinerary_day.dart';
import '../../providers/itinerary_providers.dart';

/// Ecran de planning de l'itineraire (trek).
///
/// Consumer widget affichant les jours de l'itineraire
/// sous forme de ListView.builder. Chaque jour est un
/// ExpansionTile avec le nom du jour, le nombre d'etapes
/// et la distance totale. L'expansion montre les StageCards.
/// Tap sur une StageCard navigue vers /stages/:id.
class TrekPlanningScreen extends ConsumerWidget {
  const TrekPlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itineraryAsync = ref.watch(
      itineraryProvider.select((async) => async),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning'),
      ),
      body: itineraryAsync.when(
        loading: () => const LoadingView(
          message: 'Calcul du planning...',
        ),
        error: (error, _) => ErrorView(
          message: "Impossible de charger le planning",
          onRetry: () => ref.invalidate(itineraryProvider),
        ),
        data: (days) {
          if (days.isEmpty) {
            return const Center(
              child: Text('Aucun itineraire disponible'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: days.length,
            itemBuilder: (context, index) {
              return _DayTile(day: days[index]);
            },
          );
        },
      ),
    );
  }
}

/// Tuile extensible representant un jour d'itineraire.
///
/// Affiche en titre : "Jour N" avec le nombre d'etapes
/// et la distance totale. L'expansion montre les StageCards
/// de ce jour avec navigation vers /stages/:id au tap.
class _DayTile extends StatelessWidget {
  const _DayTile({required this.day});

  final ItineraryDay day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text('${day.dayNumber}'),
          ),
          title: Text('Jour ${day.dayNumber}'),
          subtitle: Text(
            '${day.stageCount} etape${day.stageCount > 1 ? 's' : ''}'
            '  -  '
            '${day.totalDistance.toStringAsFixed(1)} km',
          ),
          children: day.stages.map((stage) {
            return _PlanningStageCard(
              stage: stage,
              onTap: () {
                context.push('/stages/${stage.stageNumber}');
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Carte d'etape dans le planning.
///
/// Affiche le numero, le nom, la distance et le denivele
/// pour un StageModel. Tap navigue vers le detail.
class _PlanningStageCard extends StatelessWidget {
  const _PlanningStageCard({
    required this.stage,
    required this.onTap,
  });

  final StageModel stage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            child: Text('${stage.stageNumber}'),
          ),
          title: Text(stage.name),
          subtitle: Text(
            '${stage.distanceKm.toStringAsFixed(1)} km  '
            'D+ ${stage.elevationGainM} m',
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }
}
