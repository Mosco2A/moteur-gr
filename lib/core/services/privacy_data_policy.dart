// D4B-01 — Politique transverse de MINIMISATION des donnees (design D4 CORDO
// #86166, CNIL reco mars 2025 A4-2).
//
// PRINCIPE (minimisation, art 5.1.c RGPD) : on ne collecte / ne conserve / ne
// transmet QUE les donnees strictement necessaires a une finalite. En
// particulier, la TRACE GPS FINE (serie complete de points) ne doit JAMAIS
// etre persistee cote serveur lorsque seul le RESULTAT (statistiques d'etape,
// duree d'un segment pour un classement) est utile a la finalite.
//
// REGLE TRANSVERSE (a appliquer par tout service qui ENVOIE des donnees —
// signalement, classement, partage social) :
//
//   "NE PAS persister cote serveur la trace GPS fine complete si seul le
//    resultat est utile. Agreger / tronquer AVANT l'envoi."
//
// Defense en profondeur — cette politique agit a un 2e niveau :
//   1. A LA SOURCE : le throttle GPS adaptatif ([gps_service.dart]) reduit
//      deja la granularite des points COLLECTES selon la vitesse / le
//      contexte = minimisation a la collecte.
//   2. AVANT ENVOI (ici) : [aggregateTrace] transforme une trace locale en
//      un resultat agrege ne contenant AUCUN point fin. C'est ce resultat,
//      et lui seul, qui peut partir vers le serveur.
//
// Ces helpers sont des FONCTIONS PURES (aucune dependance Drift / reseau /
// Riverpod) : deterministes et testables unitairement. Les services D1/D2/D3
// les appellent au moment de preparer un envoi (voir API d'integration en bas
// de fichier).

import 'dart:math' as math;

import '../../features/trek/domain/models/track_point.dart';

/// Resultat AGREGE d'une trace GPS — la SEULE forme transmissible au serveur.
///
/// Contient des statistiques derivees (distance, duree, denivele, nombre de
/// points d'origine) mais AUCUN point GPS fin : ni la serie de coordonnees, ni
/// les horodatages individuels. Impossible d'en reconstituer le trace precis,
/// donc impossible de re-identifier un parcours fin a partir du serveur.
class AggregatedTrace {
  const AggregatedTrace({
    required this.distanceMeters,
    required this.duration,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
    required this.sourcePointCount,
  });

  /// Resultat d'une trace VIDE (aucun point) : tout a zero.
  ///
  /// Evite aux appelants un cas particulier ; une trace vide ne porte aucune
  /// information a minimiser.
  static const AggregatedTrace empty = AggregatedTrace(
    distanceMeters: 0,
    duration: Duration.zero,
    elevationGainMeters: 0,
    elevationLossMeters: 0,
    sourcePointCount: 0,
  );

  /// Distance totale parcourue, en metres (somme des distances inter-points).
  final double distanceMeters;

  /// Duree totale entre le premier et le dernier point horodate.
  ///
  /// [Duration.zero] si moins de deux points portent un horodatage.
  final Duration duration;

  /// Cumul des montees (somme des deltas d'altitude positifs), en metres.
  final double elevationGainMeters;

  /// Cumul des descentes (somme des deltas d'altitude negatifs, en valeur
  /// absolue), en metres.
  final double elevationLossMeters;

  /// Nombre de points de la trace d'origine (information statistique seule —
  /// ne permet PAS de reconstituer les points eux-memes).
  final int sourcePointCount;

  /// Serialise le RESULTAT agrege (ce JSON est sans point fin, donc
  /// transmissible au serveur). Aucune coordonnee, aucun horodatage individuel.
  Map<String, Object> toJson() => <String, Object>{
        'distanceMeters': distanceMeters,
        'durationSeconds': duration.inSeconds,
        'elevationGainMeters': elevationGainMeters,
        'elevationLossMeters': elevationLossMeters,
        'sourcePointCount': sourcePointCount,
      };
}

/// Politique transverse de minimisation (helpers purs, sans etat).
///
/// Point d'entree unique pour transformer une donnee locale riche (trace GPS
/// fine) en une donnee minimisee (resultat agrege) avant tout envoi serveur.
class PrivacyDataPolicy {
  const PrivacyDataPolicy._();

  /// Rayon moyen de la Terre (m), pour la distance haversine.
  static const double _earthRadiusMeters = 6371000;

  /// Agrege une trace GPS fine en un [AggregatedTrace] (RESULTAT seul).
  ///
  /// C'est le coeur de la minimisation : a partir de la serie complete de
  /// [TrackPoint] (collectee localement pour la navigation / le diplome), on
  /// ne derive que les statistiques utiles a une finalite serveur (classement,
  /// bilan d'etape). Le resultat NE CONTIENT AUCUN point fin.
  ///
  /// A appeler par les services AVANT d'envoyer quoi que ce soit au serveur :
  ///   final result = PrivacyDataPolicy.aggregateTrace(localTrace);
  ///   await api.publishSegmentResult(result.toJson()); // pas la trace brute
  ///
  /// Fonction PURE : meme entree -> meme sortie, aucun effet de bord.
  static AggregatedTrace aggregateTrace(List<TrackPoint> trace) {
    // Une trace vide ou a un seul point ne porte ni distance ni duree.
    if (trace.length < 2) {
      return AggregatedTrace(
        distanceMeters: 0,
        duration: Duration.zero,
        elevationGainMeters: 0,
        elevationLossMeters: 0,
        sourcePointCount: trace.length,
      );
    }

    double distance = 0;
    double gain = 0;
    double loss = 0;

    for (var i = 1; i < trace.length; i++) {
      final prev = trace[i - 1];
      final curr = trace[i];
      distance += _haversineMeters(prev, curr);

      final deltaAlt = curr.elevation - prev.elevation;
      if (deltaAlt > 0) {
        gain += deltaAlt;
      } else {
        loss += -deltaAlt;
      }
    }

    return AggregatedTrace(
      distanceMeters: distance,
      duration: _durationOf(trace),
      elevationGainMeters: gain,
      elevationLossMeters: loss,
      sourcePointCount: trace.length,
    );
  }

  /// Duree entre le premier et le dernier point HORODATE de la trace.
  ///
  /// Les horodatages etant optionnels ([TrackPoint.timestamp] nullable), on se
  /// base sur le premier et le dernier point qui en portent un. Renvoie
  /// [Duration.zero] si moins de deux points sont horodates ou si la duree
  /// calculee est negative (horloge incoherente) — on ne propage pas une
  /// valeur aberrante.
  static Duration _durationOf(List<TrackPoint> trace) {
    DateTime? first;
    DateTime? last;
    for (final p in trace) {
      final ts = p.timestamp;
      if (ts == null) continue;
      first ??= ts;
      last = ts;
    }
    if (first == null || last == null) return Duration.zero;
    final d = last.difference(first);
    return d.isNegative ? Duration.zero : d;
  }

  /// Distance haversine entre deux points GPS, en metres (fonction pure).
  static double _haversineMeters(TrackPoint a, TrackPoint b) {
    final lat1 = _toRadians(a.lat);
    final lat2 = _toRadians(b.lat);
    final dLat = _toRadians(b.lat - a.lat);
    final dLng = _toRadians(b.lng - a.lng);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return _earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
