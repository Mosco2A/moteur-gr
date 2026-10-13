/// Le pont d arrivee de la carte : detection d etape, arrivee et finisher,
/// vivants pendant un trek.
///
/// Bibliotheque de l'ecran `map_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/gps_providers.dart';
import '../../providers/tracking_providers.dart';

/// Monte le pipeline « detection d'etape -> arrivee -> complétion/finisher »
/// tant qu'un trek est en cours (PARITE GR20, LOT 2, #99433).
///
/// Au LOT 1, [arrivalCompletionListenerProvider] et [currentStageIdProvider]
/// n'etaient observes par AUCUN ecran : la chaine terrain etait INERTE (aucune
/// arrivee detectee, finisher jamais declenche). Cet element, monte dans l'ecran
/// carte (terrain actif), les rend vivants — mais UNIQUEMENT quand une session
/// est `recording`/`paused`, pour ne pas ouvrir le flux GPS hors trek (et rester
/// neutre dans les tests d'ecran a l'arret). Ne rend rien a l'ecran.
class ArrivalPipelineMount extends ConsumerWidget {
  const ArrivalPipelineMount({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;

    if (trekActive) {
      // Rend le pont d'arrivee -> etapes completees -> porte du finisher ACTIF
      // (il s'auto-abonne a arrivalEventsProvider). Sans achat cote vitrine, le
      // GPS est jouable (2.A) : le cycle complet peut donc se derouler.
      ref.watch(arrivalCompletionListenerProvider);
      // Alimente aussi la detection d'etape courante pendant la nav (parite
      // GR20) : etape affichee coherente avec la position.
      // L3-1 : l'etape detectee est notee au gestionnaire de session, qui
      // l'inscrit sur chaque point de trace — c'est ce qui permet de rendre
      // le trace ETAPE PAR ETAPE dans le recap.
      final stageId = ref.watch(currentStageIdProvider).value;
      ref.read(trekSessionManagerProvider.notifier).noteCurrentStage(stageId);
    }

    return const SizedBox.shrink();
  }
}
