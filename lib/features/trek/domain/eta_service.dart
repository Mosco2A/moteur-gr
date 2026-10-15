/// L'heure d'arrivee estimee, rendue AVEC son niveau de confiance : une
/// estimation sans confiance se lit comme une promesse.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/models/stage_duration.dart';

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
/// et profil GPX a venir (denivele restant).
///
/// IL N'Y A PLUS DE MODELE DE TEMPS DE MARCHE ICI (tache 839). Ce fichier en
/// portait un SECOND, mesure par la tache 838 : 1,1 m/s a plat, 600 m/h de
/// montee, descente a 1,67 s/m. Il annoncait l'heure d'arrivee pendant que
/// `stage_duration.dart` decoupait les jours avec d'AUTRES coefficients — 29 %
/// d'ecart sur une montee de 200 m en 1 km, entre le programme qu'on prepare et
/// l'heure qu'on annonce. Le modele unique et prudent vit desormais dans
/// [walkingSeconds] ; ce service ne fait plus que ce qui lui appartient : y
/// INJECTER la vitesse a plat REELLEMENT observee du randonneur a la place de
/// la vitesse de reference (audit A6-6). Les deux penalites de relief, elles,
/// ne se negocient plus ici.
///
/// La fonction [naismithEta] est PURE et statique -> directement testable.
class EtaService {
  EtaService({Stream<EtaInput>? inputStream}) : _inputStream = inputStream;

  final Stream<EtaInput>? _inputStream;

  /// Vitesse de marche a plat par defaut (m/s) si aucune observation fiable.
  ///
  /// DERIVEE du modele unique ([kWalkingFlatPaceMps], soit 4 km/h). Elle valait
  /// 1,1 m/s ecrit en dur, c'est-a-dire 3,96 km/h : deux chiffres pour une seule
  /// vitesse, donc une divergence qui ne pouvait que grandir.
  static const double defaultFlatPaceMps = kWalkingFlatPaceMps;

  /// Vitesse plancher (m/s) : evite des ETA infinies si la vitesse observee
  /// tombe a 0 (on suppose une marche lente residuelle).
  static const double floorPaceMps = kWalkingFloorPaceMps;

  /// Secondes par metre de MONTEE — celles du modele unique (400 m/h, 9 s/m).
  static const double ascentSecondsPerMetre = kWalkingAscentSecondsPerMetre;

  /// Secondes par metre de DESCENTE — celles du modele unique (1,67 s/m).
  static const double descentSecondsPerMetre = kWalkingDescentSecondsPerMetre;

  /// Calcule l'ETA du modele unique, RAFFINEE par la vitesse observee.
  ///
  /// [distanceMetres] : distance a plat du segment.
  /// [ascentMetres]   : denivele positif du segment.
  /// [descentMetres]  : denivele negatif (valeur positive) du segment.
  /// [observedPaceMps]: vitesse a plat observee (m/s). Si <= 0, on utilise
  ///                    [defaultFlatPaceMps] ; bornee a [floorPaceMps].
  ///
  /// Le calcul est delegue a [walkingSeconds] : aucune arithmetique de temps de
  /// marche ne survit dans ce fichier. Fonction PURE (sans effet de bord).
  static Duration naismithEta({
    required double distanceMetres,
    required double ascentMetres,
    required double descentMetres,
    required double observedPaceMps,
  }) {
    final seconds = walkingSeconds(
      distanceMetres: distanceMetres,
      ascentMetres: ascentMetres,
      descentMetres: descentMetres,
      flatPaceMps: observedPaceMps,
    );
    return Duration(seconds: seconds.round());
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
    final confidence = input.gpsDegraded || input.observedPaceMps <= 0
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
