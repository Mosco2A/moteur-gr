import 'dart:math';

/// Fonctions utilitaires de calcul geographique.
///
/// Toutes les distances sont en metres, les angles en degres.
class GeoUtils {
  GeoUtils._();

  static const double _earthRadiusMeters = 6371000.0;

  /// Convertit des degres en radians.
  static double _toRadians(double degrees) => degrees * pi / 180.0;

  /// Convertit des radians en degres.
  static double _toDegrees(double radians) => radians * 180.0 / pi;

  /// Calcule la distance en metres entre deux points GPS
  /// via la formule de Haversine.
  ///
  /// Precision suffisante pour des distances < 1000 km.
  static double haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusMeters * c;
  }

  /// Calcule le cap (bearing) en degres depuis le point 1 vers le point 2.
  ///
  /// Retourne une valeur entre 0 et 360 degres (0 = nord, 90 = est).
  static double bearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final lat1Rad = _toRadians(lat1);
    final lat2Rad = _toRadians(lat2);

    final y = sin(dLng) * cos(lat2Rad);
    final x =
        cos(lat1Rad) * sin(lat2Rad) - sin(lat1Rad) * cos(lat2Rad) * cos(dLng);

    final theta = atan2(y, x);

    // Normaliser entre 0 et 360
    return (_toDegrees(theta) + 360) % 360;
  }

  /// Projette un point sur un segment [segA, segB].
  ///
  /// Retourne un record (projectedLat, projectedLng, distanceToSegment)
  /// ou distanceToSegment est la distance perpendiculaire en metres
  /// entre le point et sa projection sur le segment.
  ///
  /// Si la projection tombe en dehors du segment,
  /// le point le plus proche (segA ou segB) est utilise.
  static ({
    double projectedLat,
    double projectedLng,
    double distanceToSegment,
  }) projectPointOnSegment(
    double pointLat,
    double pointLng,
    double segALat,
    double segALng,
    double segBLat,
    double segBLng,
  ) {
    // Vecteurs en coordonnees cartesiennes locales (approximation plate)
    final cosLat = cos(_toRadians((segALat + segBLat) / 2));

    const ax = 0.0;
    const ay = 0.0;
    final bx = (segBLng - segALng) * cosLat;
    final by = segBLat - segALat;
    final px = (pointLng - segALng) * cosLat;
    final py = pointLat - segALat;

    // Vecteur AB
    final abx = bx - ax;
    final aby = by - ay;

    // Parametre t de la projection sur la droite AB
    final abLenSq = abx * abx + aby * aby;

    double t;
    if (abLenSq < 1e-15) {
      // Segment degenere (A == B)
      t = 0.0;
    } else {
      t = ((px - ax) * abx + (py - ay) * aby) / abLenSq;
      // Clamper sur [0, 1] pour rester sur le segment
      t = t.clamp(0.0, 1.0);
    }

    // Point projete en coordonnees locales
    final projX = ax + t * abx;
    final projY = ay + t * aby;

    // Reconvertir en lat/lng
    final projectedLat = segALat + projY;
    final projectedLng = segALng + projX / cosLat;

    // Distance entre le point original et sa projection
    final distanceToSegment = haversineDistance(
      pointLat,
      pointLng,
      projectedLat,
      projectedLng,
    );

    return (
      projectedLat: projectedLat,
      projectedLng: projectedLng,
      distanceToSegment: distanceToSegment,
    );
  }
}
