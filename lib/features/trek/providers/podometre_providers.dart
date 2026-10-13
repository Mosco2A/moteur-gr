/// LE PODOMETRE, LU EN UN SEUL ENDROIT (lot 671-02) : le compte consolide, la
/// longueur de pas courante, sa dispersion, le statut d'autorisation, et ce
/// que tout cela permet a l'estime. Le lot 671-03 et les suivants lisent ICI,
/// et nulle part ailleurs.
///
/// CE PROVIDER NE FAIT AVANCER AUCUN POINT, et il n'ouvre pas le podometre :
/// le seul abonnement au capteur vit dans l'isolate de fond, qui reste eveille
/// ecran eteint. L'interface lit son travail par le canal des preferences
/// partagees, celui du profil GPS : c'est le seul qui survive a l'interface
/// endormie et a une fermeture de l'application, la ou le battement de
/// l'isolate se perd quand personne ne l'ecoute.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/podometre_permission_service.dart';
import '../data/podometre_preferences.dart';
import '../domain/accumulateur_de_pas.dart';
import '../domain/longueur_de_pas.dart';

/// Ce que le podometre dit, a un instant.
class PodometerState {
  /// Un releve complet.
  const PodometerState({
    required this.steps,
    required this.stride,
    required this.access,
    required this.readiness,
  });

  /// Le total de pas consolide de la session ; nul sans podometre utilisable.
  final int? steps;

  /// La calibration de la longueur de pas.
  final StrideCalibration stride;

  /// L'autorisation d'activite physique.
  final PodometerAccess access;

  /// Ce que le podometre permet a l'estime, et sinon pourquoi.
  final EstimateReadiness readiness;

  /// La longueur de pas courante, en metres.
  double get strideMeters => stride.meters;

  /// La dispersion des longueurs retenues, en pour cent ; nulle sous deux.
  double? get strideSpreadPercent => stride.spreadPercent;
}

/// L'estime est-elle possible, et sinon pourquoi : l'autorisation d'abord,
/// puis ce que l'isolate de fond a vu du flux.
EstimateReadiness estimateReadinessOf(
  PodometerAccess access,
  EstimateReadiness? seenByBackground,
) => switch (access) {
  PodometerAccess.unavailable => EstimateReadiness.podometerUnavailable,
  PodometerAccess.denied ||
  PodometerAccess.permanentlyDenied => EstimateReadiness.permissionRefused,
  PodometerAccess.granted => switch (seenByBackground) {
    EstimateReadiness.streamError ||
    EstimateReadiness.podometerUnavailable => seenByBackground!,
    _ => EstimateReadiness.possible,
  },
};

/// Le podometre, relu a chaque lecture ; `ref.invalidate` le rafraichit.
final podometerProvider = FutureProvider<PodometerState>((ref) async {
  final store = ref.watch(podometerStoreProvider);
  final access = await ref.watch(podometerPermissionServiceProvider).status();
  final readiness = estimateReadinessOf(access, await store.readReadiness());
  return PodometerState(
    steps: readiness == EstimateReadiness.possible
        ? await store.readSteps()
        : null,
    stride: await store.readStride(),
    access: access,
    readiness: readiness,
  );
});
