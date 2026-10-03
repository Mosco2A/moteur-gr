/// La liste des etapes, triee par numero, avec ses trois etats traites :
/// chargement, erreur, donnee.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/stage_row.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_header.dart';
import '../../../trail/trail_facade.dart' show stagesProvider;

/// Ecran liste des etapes d'un sentier.
///
/// Consumer widget utilisant AsyncValue.when() sur stagesProvider.
/// Affiche LoadingView / ErrorView / ListView.builder avec _StageCard.
/// Les etapes sont triees par stageNumber (ordre d'affichage).
/// Utilise select() pour eviter un full rebuild.
class StageListScreen extends ConsumerWidget {
  const StageListScreen({super.key, required this.trailId});

  /// Identifiant du sentier dont on affiche les etapes.
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stagesAsync = ref.watch(
      stagesProvider(trailId).select((async) => async),
    );

    return Scaffold(
      // Ph5 (L6a) : AppHeader universel. Titre via Slang (t.nav.stages) au lieu
      // du 'Etapes' en dur (zero texte en dur). Ecran cœur -> barre absente (§4).
      appBar: AppHeader(title: t.nav.stages),
      body: stagesAsync.when(
        loading: () => LoadingView(message: t.stage.loadingList),
        error: (error, _) => ErrorView(
          message: t.common.cannotLoadStages,
          onRetry: () => ref.invalidate(stagesProvider(trailId)),
        ),
        data: (stages) {
          if (stages.isEmpty) {
            return Center(child: Text(t.common.noStages));
          }

          // Tri par stageNumber (orderIndex)
          final sorted = List.of(stages)
            ..sort((a, b) => a.stageNumber.compareTo(b.stageNumber));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: sorted.length,
            itemBuilder: (context, index) {
              return _StageCard(stage: sorted[index]);
            },
          );
        },
      ),
    );
  }
}

/// Carte placeholder pour une etape.
///
/// ListTile dans un Card -- sera remplacee par un widget riche en E2.4b.
class _StageCard extends StatelessWidget {
  const _StageCard({required this.stage});

  final StageModel stage;

  @override
  Widget build(BuildContext context) {
    // SW-SKIN-L3c : Card Material -> AppCard. padding zero pour garder la
    // ListTile bord a bord (elle porte son propre rembourrage).
    //
    // TACHE 639 (bug 4) — LE CHEVRON QUI MENTAIT EST RETIRE.
    //
    // Cette carte ne portait AUCUN geste — ni sur l'AppCard, ni sur la ListTile
    // — et affichait pourtant un chevron droit, c'est-a-dire la promesse
    // universelle « il y a quelque chose derriere ». Le randonneur appuyait, et
    // rien. C'est la faute symetrique de celle de Christophe sur « Pret a
    // partir » (DEM-260930-1010, verbatim : « il faut differencier visuellement
    // ce qui est clicable de ce qui ne l est pas ») : la, une information avait
    // le relief d'un bouton ; ici, elle en avait la fleche.
    //
    // ON RETIRE LA PROMESSE, ON N'INVENTE PAS LA DESTINATION : cet ecran est un
    // placeholder (« sera remplacee par un widget riche en E2.4b ») et la carte
    // d'etape CLIQUABLE existe deja ailleurs ([StageCard], qui porte son `onTap`
    // et garde donc son chevron a bon droit). Brancher une navigation ici serait
    // ajouter une fonction non demandee.
    return AppCard(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(child: Text('${stage.stageNumber}')),
        title: Text(stage.name),
        subtitle: Text(
          '${stage.distanceKm.toStringAsFixed(1)} km  '
          'D+ ${stage.elevationGainM} m',
        ),
      ),
    );
  }
}
