/// LA CALIBRATION DE LA LONGUEUR DE PAS EN MARCHANT (lot 671-02), cote
/// interface : la seule qui connaisse la distance SUR LE TRACE.
///
/// A chaque position projetee sur le trace, elle lit le total de pas que
/// l'isolate de fond a persiste ([PodometerStore]), ferme un intervalle, et
/// ecrit la calibration au point de calibration des qu'un intervalle est
/// accepte. ELLE NE FAIT AVANCER AUCUN POINT et n'ouvre aucun flux : elle lit
/// la position que la carte recoit deja, et le podometre par le canal.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/accumulateur_de_pas.dart';
import '../domain/longueur_de_pas.dart';
import 'podometre_preferences.dart';

/// Alimente la calibration au fil des positions projetees.
class StrideCalibrationFeed {
  /// [store] est le canal du podometre.
  StrideCalibrationFeed(this._store);

  final PodometerStore _store;
  StrideCalibrator? _calibrator;
  Future<StrideOutcome?> _queue = Future<StrideOutcome?>.value();

  /// Observe la distance depuis le depart [distanceFromStartMeters], dans
  /// l'ordre d'arrivee ; rend le sort de l'intervalle ferme, s'il y en a un.
  Future<StrideOutcome?> observe(double distanceFromStartMeters) =>
      _queue = _queue.then((_) => _observe(distanceFromStartMeters));

  Future<StrideOutcome?> _observe(double distanceFromStartMeters) async {
    final calibrator = _calibrator ??= StrideCalibrator(
      await _store.readStride(),
    );
    final readiness = await _store.readReadiness();
    final steps = readiness == EstimateReadiness.possible
        ? await _store.readSteps()
        : null;
    final outcome = calibrator.observe(
      distanceFromStartMeters: distanceFromStartMeters,
      steps: steps,
    );
    if (outcome != null && outcome.accepted) {
      await _store.saveStride(calibrator.calibration);
    }
    return outcome;
  }

  /// Oublie l'intervalle en cours (trek arrete ou en pause) ; la prochaine
  /// position relira la calibration persistee.
  void reset() => _calibrator = null;
}

/// La calibration de l'interface, une seule pour l'application.
final strideCalibrationFeedProvider = Provider<StrideCalibrationFeed>(
  (ref) => StrideCalibrationFeed(ref.watch(podometerStoreProvider)),
);
