import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/eta_service.dart';

/// Provider du service d'ETA temps reel (F6B-01).
///
/// Par defaut sans flux d'entree branche : le flux d'estimations est cable au
/// niveau de l'ecran de navigation (F6B-02) qui fournit l'[EtaInput] courant.
final etaServiceProvider = Provider<EtaService>((ref) {
  return EtaService();
});

/// Contrôleur d'ETA piloté par ÉVÉNEMENT (F6B-02).
///
/// L'estimation n'est recalculée que sur un événement DISCRET (franchissement
/// de waypoint, changement de segment, ou tick lent) — JAMAIS à chaque frame ni
/// à chaque position GPS (économie batterie, A1-4e). Un intervalle minimal
/// ([minRecalcInterval]) débounce les recalculs trop rapprochés ; un événement
/// `force` (ex. waypoint franchi) ignore ce débounce.
class EtaController extends Notifier<EtaEstimate?> {
  DateTime? _lastComputeAt;

  /// Intervalle minimal entre deux recalculs non forcés (anti-spin batterie).
  static const Duration minRecalcInterval = Duration(seconds: 30);

  @override
  EtaEstimate? build() => null;

  /// Recalcule l'ETA à partir de [input], sur ÉVÉNEMENT uniquement.
  ///
  /// Si [force] est faux et que moins de [minRecalcInterval] s'est écoulé depuis
  /// le dernier calcul, l'appel est ignoré (debounce). [now] est injectable pour
  /// les tests. Retourne `true` si un recalcul a effectivement eu lieu.
  bool onEvent(EtaInput input, {bool force = false, DateTime? now}) {
    final current = now ?? DateTime.now();
    final last = _lastComputeAt;
    if (!force && last != null && current.difference(last) < minRecalcInterval) {
      return false;
    }
    _lastComputeAt = current;
    state = EtaService.estimate(input);
    return true;
  }

  /// Réinitialise l'estimation (ex. fin d'étape).
  void reset() {
    _lastComputeAt = null;
    state = null;
  }
}

/// Estimation d'ETA courante, recalculée sur événement (F6B-02).
final etaControllerProvider =
    NotifierProvider<EtaController, EtaEstimate?>(EtaController.new);
