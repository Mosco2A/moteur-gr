import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

/// Niveau de confiance d'une estimation d'ETA (F6B-01).
enum EtaConfidence {
  /// GPS fiable, vitesse observee exploitable.
  high,

  /// GPS degrade : estimation appuyee sur podometre/pente, marge plus large.
  low,
}

/// Estimation d'ETA fusionnee (F6.6).
@immutable
class EtaEstimate {
  const EtaEstimate({
    required this.toNextWaypoint,
    required this.toStageEnd,
    required this.confidence,
  });

  /// Temps estime jusqu'au prochain waypoint.
  final Duration toNextWaypoint;

  /// Temps estime jusqu'a la fin de l'etape.
  final Duration toStageEnd;

  /// Niveau de confiance de l'estimation.
  final EtaConfidence confidence;

  @override
  bool operator ==(Object other) =>
      other is EtaEstimate &&
      other.toNextWaypoint == toNextWaypoint &&
      other.toStageEnd == toStageEnd &&
      other.confidence == confidence;

  @override
  int get hashCode => Object.hash(toNextWaypoint, toStageEnd, confidence);
}

/// Entree de calcul d'ETA : etat instantane de la progression.
@immutable
class EtaInput {
  const EtaInput({
    required this.distanceToWaypointM,
    required this.ascentToWaypointM,
    required this.descentToWaypointM,
    required this.distanceToStageEndM,
    required this.ascentToStageEndM,
    required this.descentToStageEndM,
    required this.observedPaceMps,
    required this.gpsDegraded,
  });

  final double distanceToWaypointM;
  final double ascentToWaypointM;
  final double descentToWaypointM;
  final double distanceToStageEndM;
  final double ascentToStageEndM;
  final double descentToStageEndM;

  /// Vitesse de marche a plat REELLE observee (moyenne glissante, m/s).
  /// 0 si indisponible (GPS perdu) -> on retombe sur une vitesse plancher.
  final double observedPaceMps;

  /// Vrai si le GPS est degrade (confiance basse, fusion podometre/pente).
  final bool gpsDegraded;
}

/// Service de calcul d'ETA temps reel (F6B-01, F6.6).
///
/// Fusionne : vitesse GPS lissee (observee), pente issue de l'altitude
/// barometrique (F6A-02), cadence (podometre, robustesse en zone GPS degradee)
/// et profil GPX a venir (denivele restant). Le socle algorithmique est la
/// regle de NAISMITH (temps a plat + 1 h par 600 m de montee, descente raide
/// penalisee), RAFFINEE par la vitesse reelle observee de l'utilisateur plutot
/// qu'une constante (audit A6-6).
///
/// La fonction [naismithEta] est PURE et statique -> directement testable.
class EtaService {
  EtaService({Stream<EtaInput>? inputStream}) : _inputStream = inputStream;

  final Stream<EtaInput>? _inputStream;

  /// Vitesse de marche a plat par defaut (m/s) si aucune observation fiable.
  /// ~4 km/h (randonneur), coherent avec [ItineraryCalculator].
  static const double defaultFlatPaceMps = 1.1;

  /// Vitesse plancher (m/s) : evite des ETA infinies si la vitesse observee
  /// tombe a 0 (on suppose une marche lente residuelle).
  static const double floorPaceMps = 0.5;

  /// Naismith : 1 h (3600 s) ajoutee par 600 m de montee.
  static const double ascentSecondsPerMetre = 3600.0 / 600.0; // 6 s / m

  /// Descente raide : penalite douce (Tranter/Langmuir simplifie) :
  /// +10 s par metre de descente au-dela de la composante a plat.
  static const double descentSecondsPerMetre = 10.0 / 6.0; // ~1.67 s / m

  /// Calcule l'ETA Naismith RAFFINEE pour un segment.
  ///
  /// [distanceMetres] : distance a plat du segment.
  /// [ascentMetres]   : denivele positif du segment.
  /// [descentMetres]  : denivele negatif (valeur positive) du segment.
  /// [observedPaceMps]: vitesse a plat observee (m/s). Si <= 0, on utilise
  ///                    [defaultFlatPaceMps] ; bornee a [floorPaceMps].
  ///
  /// Temps = distance / vitessePlat + montee * [ascentSecondsPerMetre]
  ///         + descente * [descentSecondsPerMetre].
  /// Fonction PURE (sans effet de bord).
  static Duration naismithEta({
    required double distanceMetres,
    required double ascentMetres,
    required double descentMetres,
    required double observedPaceMps,
  }) {
    final pace = observedPaceMps.isFinite && observedPaceMps > 0
        ? math.max(observedPaceMps, floorPaceMps)
        : defaultFlatPaceMps;
    final distance = distanceMetres.isFinite && distanceMetres > 0
        ? distanceMetres
        : 0.0;
    final ascent = ascentMetres.isFinite && ascentMetres > 0 ? ascentMetres : 0.0;
    final descent =
        descentMetres.isFinite && descentMetres > 0 ? descentMetres : 0.0;

    final flatSeconds = distance / pace;
    final ascentSeconds = ascent * ascentSecondsPerMetre;
    final descentSeconds = descent * descentSecondsPerMetre;
    final total = flatSeconds + ascentSeconds + descentSeconds;
    return Duration(seconds: total.round());
  }

  /// Construit une estimation complete (waypoint + fin d'etape + confiance) a
  /// partir d'un [EtaInput].
  static EtaEstimate estimate(EtaInput input) {
    final toWaypoint = naismithEta(
      distanceMetres: input.distanceToWaypointM,
      ascentMetres: input.ascentToWaypointM,
      descentMetres: input.descentToWaypointM,
      observedPaceMps: input.observedPaceMps,
    );
    final toEnd = naismithEta(
      distanceMetres: input.distanceToStageEndM,
      ascentMetres: input.ascentToStageEndM,
      descentMetres: input.descentToStageEndM,
      observedPaceMps: input.observedPaceMps,
    );
    // Confiance basse si GPS degrade OU si aucune vitesse observee exploitable
    // (on s'appuie alors sur le profil/pente + cadence, marge plus large).
    final confidence =
        input.gpsDegraded || input.observedPaceMps <= 0
            ? EtaConfidence.low
            : EtaConfidence.high;
    return EtaEstimate(
      toNextWaypoint: toWaypoint,
      toStageEnd: toEnd,
      confidence: confidence,
    );
  }

  /// Flux d'estimations d'ETA, derive du flux d'entrees fourni a la
  /// construction. Chaque [EtaInput] produit un [EtaEstimate].
  Stream<EtaEstimate> estimateStream() {
    final source = _inputStream;
    if (source == null) {
      return const Stream<EtaEstimate>.empty();
    }
    return source.map(estimate);
  }
}
