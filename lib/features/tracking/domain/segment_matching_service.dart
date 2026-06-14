import 'package:drift/drift.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/data/daos/segments_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/geo/geo_utils.dart';

/// Un point GPS horodate de la trace utilisateur (entree du matching).
class TimedPoint {
  const TimedPoint({required this.position, required this.time});

  final LatLng position;
  final DateTime time;
}

/// Resultat de la detection d'un passage sur un segment (cote CLIENT).
///
/// Donne l'index d'entree/sortie dans la trace utilisateur et la duree
/// LOCALE de l'effort. ATTENTION (R2) : cette duree sert l'AFFICHAGE
/// immediat uniquement ; le classement OFFICIEL/comparatif est recalcule
/// COTE SERVEUR apres synchronisation (Cloud Function F7A-03).
class SegmentDetection {
  const SegmentDetection({
    required this.entryIndex,
    required this.exitIndex,
    required this.startedAt,
    required this.durationSeconds,
  });

  final int entryIndex;
  final int exitIndex;
  final DateTime startedAt;
  final int durationSeconds;
}

/// Service de detection de passage sur un segment, cote CLIENT (F7A-02).
///
/// A partir de la trace GPS de l'utilisateur et de la polyline d'un segment
/// (F7A-01), detecte l'ENTREE et la SORTIE du segment (proximite geometrique
/// avec tolerance, ordre des points) et calcule la duree de l'effort
/// LOCALEMENT pour un retour immediat a l'ecran.
///
/// REGLE R2 (offline-first / calcul serveur) : ce calcul client est un
/// APERCU pour l'affichage. Le classement OFFICIEL "Roi de l etape" est
/// recalcule COTE SERVEUR apres remontee des efforts (F7A-03), jamais en
/// live sur le terrain (zones blanches). L'effort detecte est stocke en
/// local (segmentEffortLocal `pending`, F7A-01) puis synchronise en differe.
///
/// ZERO catch silencieux — toute erreur de persistance est loggee + relancee.
class SegmentMatchingService {
  SegmentMatchingService({required AppDatabase database})
      : _dao = SegmentsDao(database);

  final SegmentsDao _dao;

  /// Tolerance geometrique par defaut (metres) pour considerer un point
  /// "sur" la polyline du segment.
  static const double defaultToleranceM = 25.0;

  /// Indique si [point] est sur la [polyline] du segment a [toleranceM] pres.
  ///
  /// Fonction PURE et testable : projette le point sur chaque sous-segment
  /// de la polyline et renvoie vrai si la distance perpendiculaire minimale
  /// est <= [toleranceM]. Une polyline vide -> faux ; un point unique ->
  /// distance directe a ce point.
  static bool isOnSegment(
    LatLng point,
    List<LatLng> polyline,
    double toleranceM,
  ) {
    if (polyline.isEmpty) return false;
    if (polyline.length == 1) {
      final d = GeoUtils.haversineDistance(
        point.latitude,
        point.longitude,
        polyline.first.latitude,
        polyline.first.longitude,
      );
      return d <= toleranceM;
    }
    for (var i = 0; i < polyline.length - 1; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];
      final proj = GeoUtils.projectPointOnSegment(
        point.latitude,
        point.longitude,
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (proj.distanceToSegment <= toleranceM) return true;
    }
    return false;
  }

  /// Detecte un passage sur le segment defini par [segmentPolyline] dans la
  /// [userTrack] de l'utilisateur, avec [toleranceM] (defaut
  /// [defaultToleranceM]).
  ///
  /// Heuristique : l'ENTREE est le premier point de la trace proche du DEBUT
  /// de la polyline (premier point de [segmentPolyline]) ; la SORTIE est le
  /// dernier point proche de la FIN de la polyline et survenant APRES
  /// l'entree (ordre temporel respecte). Retourne `null` si le passage n'est
  /// pas detecte (pas d'entree, ou pas de sortie posterieure).
  ///
  /// La duree est calculee LOCALEMENT (affichage, R2).
  static SegmentDetection? detectPassage({
    required List<TimedPoint> userTrack,
    required List<LatLng> segmentPolyline,
    double toleranceM = defaultToleranceM,
  }) {
    if (userTrack.length < 2 || segmentPolyline.length < 2) return null;
    final segStart = segmentPolyline.first;
    final segEnd = segmentPolyline.last;

    int? entryIndex;
    for (var i = 0; i < userTrack.length; i++) {
      if (isOnSegment(userTrack[i].position, [segStart], toleranceM)) {
        entryIndex = i;
        break;
      }
    }
    if (entryIndex == null) return null;

    int? exitIndex;
    for (var i = userTrack.length - 1; i > entryIndex; i--) {
      if (isOnSegment(userTrack[i].position, [segEnd], toleranceM)) {
        exitIndex = i;
        break;
      }
    }
    if (exitIndex == null) return null;

    final startedAt = userTrack[entryIndex].time;
    final endedAt = userTrack[exitIndex].time;
    final duration = endedAt.difference(startedAt).inSeconds;
    if (duration <= 0) return null;

    return SegmentDetection(
      entryIndex: entryIndex,
      exitIndex: exitIndex,
      startedAt: startedAt,
      durationSeconds: duration,
    );
  }

  /// Detecte un passage puis PERSISTE l'effort detecte en local
  /// (segmentEffortLocal `pending`, F7A-01) pour un affichage immediat et une
  /// synchronisation differee (F7A-03). Retourne l'id local de l'effort, ou
  /// `null` si aucun passage n'est detecte.
  ///
  /// [userUidHash] DOIT etre l'UID HACHE (AnonymousIdService) : jamais de PII
  /// (#85383). Le classement officiel reste calcule cote serveur (R2).
  Future<int?> detectAndStore({
    required String segmentId,
    required String userUidHash,
    required List<TimedPoint> userTrack,
    required List<LatLng> segmentPolyline,
    double toleranceM = defaultToleranceM,
  }) async {
    final detection = detectPassage(
      userTrack: userTrack,
      segmentPolyline: segmentPolyline,
      toleranceM: toleranceM,
    );
    if (detection == null) return null;
    try {
      return await _dao.insertEffort(
        SegmentEffortLocalCompanion(
          segmentId: Value(segmentId),
          userUidHash: Value(userUidHash),
          durationSeconds: Value(detection.durationSeconds),
          startedAt: Value(detection.startedAt.toUtc()),
        ),
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'SegmentMatchingService.detectAndStore');
      rethrow;
    }
  }
}
