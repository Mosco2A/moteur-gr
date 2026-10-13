/// LE CANAL DU PODOMETRE (lot 671-02) : ce que l'isolate de fond et
/// l'interface se disent du podometre, par les preferences partagees, le meme
/// canal que le profil GPS du lot 671-00 (`kPrefsBgProfile`).
///
/// UN SEUL ECRIVAIN PAR CLE. L'isolate de fond, seul a ouvrir le flux du
/// podometre, ecrit le total de pas et l'etat du flux. L'interface, seule a
/// connaitre le trace, ecrit la calibration de la longueur de pas. Chacun relit
/// ce que l'autre ecrit, apres un `reload()`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/accumulateur_de_pas.dart';
import '../domain/longueur_de_pas.dart';

/// La session a laquelle appartiennent le total et la derniere valeur brute :
/// un trek qui REPREND la retrouve et repart de son total, un trek neuf repart
/// de zero.
const String kPrefsStepsSessionId = 'bg_steps_session_id';

/// Le total de pas consolide de la session ([StepAccumulator.banked]).
const String kPrefsStepsTotal = 'bg_steps_total';

/// La derniere valeur brute du capteur ([StepAccumulator.lastRaw]).
const String kPrefsStepsLastRaw = 'bg_steps_last_raw';

/// L'etat du flux vu par l'isolate de fond ([EstimateReadiness.word]).
const String kPrefsStepsReadiness = 'bg_steps_readiness';

/// LE POINT DE CALIBRATION DE LA LONGUEUR DE PAS : les dernieres longueurs
/// acceptees, en metres, une par entree, la plus recente en dernier. La
/// longueur retenue est leur moyenne ([StrideCalibration.meters]).
///
/// C'EST ICI QU'UNE MESURE FUTURE REMPLACE LA VALEUR DE DEPART, SANS QU'UNE
/// LIGNE DE CODE CHANGE : la calibration y ecrit chaque intervalle accepte,
/// l'interface et l'isolate de fond la relisent au demarrage d'un trek, et
/// la ligne de compteurs du journal l'imprime (`longueur_de_pas_m=`). Absente,
/// illisible ou hors du garde-fou, elle retombe sur [kStrideDefaultMeters].
const String kPrefsStrideWindow = 'bg_stride_window_m';

/// Le rythme d'ecriture du total pendant la marche : au plus une fois toutes
/// les 10 s, en plus de chaque point GPS, de chaque ligne de compteurs et de
/// l'arret. A 2 pas par seconde, le total lu par l'interface a donc au plus
/// 20 pas de retard, soit 1,1 % d'un intervalle de 3 minutes (1 800 pas) ; et
/// ce retard ne s'additionne pas d'un intervalle a l'autre, puisque la fin de
/// l'un est le debut du suivant.
const Duration kStepsSavePeriod = Duration(seconds: 10);

/// Lit et ecrit le canal du podometre. Ne leve jamais : une preference
/// illisible vaut une valeur absente, et le suivi continue.
class PodometerStore {
  /// [preferences] rend les preferences partagees (injectable en test).
  PodometerStore({Future<SharedPreferences> Function()? preferences})
    : _preferences = preferences ?? SharedPreferences.getInstance;

  final Future<SharedPreferences> Function() _preferences;

  Future<SharedPreferences?> _fresh() async {
    try {
      final prefs = await _preferences();
      await prefs.reload();
      return prefs;
    } on Object {
      return null;
    }
  }

  Future<T?> _read<T>(T? Function(SharedPreferences p) read) async {
    final prefs = await _fresh();
    if (prefs == null) return null;
    try {
      return read(prefs);
    } on Object {
      return null;
    }
  }

  Future<void> _write(Future<void> Function(SharedPreferences p) write) async {
    final prefs = await _fresh();
    if (prefs == null) return;
    try {
      await write(prefs);
    } on Object {
      // Une ecriture perdue ne coupe jamais le suivi : la suivante la remplace.
      return;
    }
  }

  /// Le total de la session [sessionId] s'il est persiste, sinon un neuf.
  Future<StepAccumulator> restoreSteps(String sessionId) async =>
      await _read((p) {
        if (sessionId.isEmpty) return null;
        if (p.getString(kPrefsStepsSessionId) != sessionId) return null;
        final total = p.getInt(kPrefsStepsTotal);
        if (total == null || total < 0) return null;
        return StepAccumulator.resumed(
          total: total,
          lastRaw: p.getInt(kPrefsStepsLastRaw),
        );
      }) ??
      StepAccumulator();

  /// Persiste le total de [steps] pour la session [sessionId].
  Future<void> saveSteps(String sessionId, StepAccumulator steps) =>
      _write((p) async {
        await p.setString(kPrefsStepsSessionId, sessionId);
        await p.setInt(kPrefsStepsTotal, steps.banked);
        final raw = steps.lastRaw;
        if (raw == null) {
          await p.remove(kPrefsStepsLastRaw);
        } else {
          await p.setInt(kPrefsStepsLastRaw, raw);
        }
      });

  /// Le total de pas persiste, nul s'il n'y en a pas.
  Future<int?> readSteps() => _read((p) => p.getInt(kPrefsStepsTotal));

  /// L'etat du flux vu par l'isolate de fond, nul s'il n'y en a pas.
  Future<EstimateReadiness?> readReadiness() => _read(
    (p) => EstimateReadiness.fromWord(p.getString(kPrefsStepsReadiness)),
  );

  /// Persiste l'etat du flux.
  Future<void> saveReadiness(EstimateReadiness readiness) =>
      _write((p) => p.setString(kPrefsStepsReadiness, readiness.word));

  /// La calibration persistee, lue avec tolerance.
  Future<StrideCalibration> readStride() async => StrideCalibration.fromStored(
    await _read((p) => p.getStringList(kPrefsStrideWindow)),
  );

  /// Persiste [calibration] au point de calibration.
  Future<void> saveStride(StrideCalibration calibration) => _write(
    (p) => p.setStringList(kPrefsStrideWindow, calibration.toStored()),
  );
}

/// Le canal du podometre cote interface.
final podometerStoreProvider = Provider<PodometerStore>(
  (ref) => PodometerStore(),
);
