import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../domain/models/stage.dart';
import '../../providers/trail_providers.dart';
import '../widgets/stage_card.dart';

/// Ecran liste des etapes du mode trek.
///
/// Consumer widget qui observe [trekStagesProvider] via [AsyncValue.when].
/// Les etapes sont triees par [Stage.orderIndex] avant affichage.
/// Chaque etape est rendue par un [StageCard].
///
/// Optimisation Riverpod :
/// - select() sur trailConfigProvider pour le nom du sentier (AppBar)
/// - AsyncValue.when pour les 3 etats : loading, error, data
class StageListScreen extends ConsumerWidget {
  const StageListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // select() sur le displayName — rebuild uniquement si le nom change
    final trailName = ref.watch(
      trailConfigProvider.select((config) => config.displayName),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(trailName),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _StageListBody(),
    );
  }
}

/// Corps de la liste — isole pour que l'AppBar ne rebuild pas
/// quand les donnees async changent.
class _StageListBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(trekStagesProvider);

    return stagesAsync.when(
      loading: () => const LoadingView(message: 'Chargement des etapes...'),
      error: (error, _) => ErrorView(
        error: error,
        onRetry: () => ref.invalidate(trekStagesProvider),
      ),
      data: (stages) {
        if (stages.isEmpty) {
          return const Center(
            child: Text('Aucune etape disponible'),
          );
        }

        // Tri par orderIndex
        final sorted = List<Stage>.of(stages)
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: sorted.length,
          itemBuilder: (context, index) {
            return StageCard(stage: sorted[index]);
          },
        );
      },
    );
  }
}
