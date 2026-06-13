import 'package:health/health.dart';

import '../error/error_handler.dart';

/// Instantane de donnees de sante lues sur un intervalle (F6F-03).
class HealthSnapshot {
  const HealthSnapshot({
    required this.authorized,
    this.steps = 0,
    this.avgHeartRate,
    this.distanceMeters = 0,
    this.activeCalories = 0,
  });

  /// Etat 'non autorise' : l'utilisateur n'a pas accorde l'acces sante.
  const HealthSnapshot.notAuthorized() : this(authorized: false);

  /// Vrai si la lecture a ete autorisee (permissions accordees).
  final bool authorized;

  /// Pas cumules sur l'intervalle.
  final int steps;

  /// Frequence cardiaque moyenne (bpm) sur l'intervalle, null si aucune mesure.
  final double? avgHeartRate;

  /// Distance parcourue (metres) sur l'intervalle.
  final double distanceMeters;

  /// Calories actives depensees (kcal) sur l'intervalle.
  final double activeCalories;
}

/// Service de LECTURE des donnees de la montre DU USER via HealthKit (iOS) /
/// Health Connect (Android) (F6F-03, Phase 6).
///
/// ALTERNATIVE PRAGMATIQUE au companion watch (audit A5-8 / A6-5) : le user
/// utilise SA montre habituelle, StepWays LIT (lecture seule) FC / pas /
/// distance / calories sans app montre proprietaire.
///
/// Donnees de SANTE = art. 9 RGPD : lecture UNIQUEMENT apres consentement
/// explicite gere a l'UX (design Securite D4) + minimisation (on ne lit que ce
/// qui est affiche, AUCUN stockage serveur). Degrade proprement si Health
/// Connect est absent (Android) ou si la permission est refusee (pas de crash).
///
/// Permissions a declarer :
/// - iOS : `NSHealthShareUsageDescription` (Info.plist).
/// - Android : permissions Health Connect (manifest, gerees par le plugin).
///
/// ZERO catch silencieux — toute erreur est loggee via [ErrorHandler].
class HealthReaderService {
  HealthReaderService({Health? health}) : _health = health ?? Health();

  final Health _health;

  /// Types de donnees lus (lecture seule), minimises a l'usage trek.
  static const List<HealthDataType> readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.DISTANCE_DELTA,
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  /// Agrege une liste de [HealthDataPoint] en un [HealthSnapshot].
  ///
  /// - STEPS / DISTANCE / CALORIES : somme des valeurs numeriques.
  /// - HEART_RATE : moyenne des valeurs (null si aucune mesure).
  /// Fonction PURE (sans effet de bord) — directement testable.
  static HealthSnapshot aggregate(List<HealthDataPoint> points) {
    var steps = 0.0;
    var distance = 0.0;
    var calories = 0.0;
    var hrSum = 0.0;
    var hrCount = 0;

    for (final p in points) {
      final value = p.value;
      if (value is! NumericHealthValue) continue;
      final n = value.numericValue.toDouble();
      switch (p.type) {
        case HealthDataType.STEPS:
          steps += n;
        case HealthDataType.DISTANCE_DELTA:
          distance += n;
        case HealthDataType.ACTIVE_ENERGY_BURNED:
          calories += n;
        case HealthDataType.HEART_RATE:
          hrSum += n;
          hrCount++;
        default:
          break;
      }
    }

    return HealthSnapshot(
      authorized: true,
      steps: steps.round(),
      avgHeartRate: hrCount > 0 ? hrSum / hrCount : null,
      distanceMeters: distance,
      activeCalories: calories,
    );
  }

  /// Lit les donnees de sante sur l'intervalle [start]..[end] (lecture seule).
  ///
  /// Demande les permissions (lecture) si necessaire. Retourne un
  /// [HealthSnapshot.notAuthorized] si Health Connect est indisponible
  /// (Android) ou si la permission est refusee — sans crash.
  Future<HealthSnapshot> readForInterval(DateTime start, DateTime end) async {
    try {
      // Android : Health Connect doit etre disponible, sinon degrade.
      final available = await _health.isHealthConnectAvailable();
      if (!available) {
        ErrorHandler.log(
          StateError('Health Connect indisponible — lecture sante degradee'),
          context: 'HealthReaderService.readForInterval',
        );
        return const HealthSnapshot.notAuthorized();
      }

      final granted = await _health.requestAuthorization(
        readTypes,
        permissions:
            readTypes.map((_) => HealthDataAccess.READ).toList(growable: false),
      );
      if (!granted) {
        return const HealthSnapshot.notAuthorized();
      }

      final points = await _health.getHealthDataFromTypes(
        types: readTypes,
        startTime: start,
        endTime: end,
      );
      return aggregate(points);
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'HealthReaderService.readForInterval');
      // Lecture sante non bloquante : degrade en 'non autorise' sans crash.
      return const HealthSnapshot.notAuthorized();
    }
  }
}
