import 'package:gpx/gpx.dart';

import '../../../core/geo/geo_utils.dart';
import '../../trek/domain/models/stage.dart';
import '../../trek/domain/models/track_point.dart';

/// Parametres d'import GPX DERIVES du sentier actif (data-driven, zero hardcode).
///
/// PARITE GR20 (Import GPX) — decision Skynet : l'ecran GR20 est generalise et
/// pilote par la CONFIG DU SENTIER, non plus par des constantes GR20 (bornes
/// Corse + refuges GR20 en dur). Cette classe porte tout ce dont le service a
/// besoin pour valider une trace importee et y detecter des etapes, calcule une
/// fois depuis les ETAPES du sentier ([Stage]) :
///  * [bounds] : boite geographique du sentier (min/max lat/lon) + marge, pour
///    juger « hors zone » — DERIVEE des coordonnees depart/arrivee des etapes
///    (le moteur n'a pas de bornes en dur ; si aucune etape n'est chargee,
///    [bounds] est null -> la validation « hors zone » est tolerante).
///  * [referencePoints] : points de reference pour la detection d'etapes et le
///    controle « hors trace » — les coordonnees depart/arrivee des etapes du
///    sentier (memes donnees que Transport/Resume), avec l'etape associee.
///  * [totalStages] : nombre d'etapes du parcours (affichage « X/{total} »).
///  * les tolerances ([outOfTraceToleranceMeters], [stageDetectionRadiusMeters],
///    [boundsMarginDegrees]) sont des parametres nommes a valeurs par defaut
///    raisonnables (surchargables par sentier au besoin).
class TrailImportConfig {
  const TrailImportConfig({
    required this.bounds,
    required this.referencePoints,
    required this.totalStages,
    this.boundsMarginDegrees = 0.15,
    this.outOfTraceToleranceMeters = 5000,
    this.stageDetectionRadiusMeters = 300,
  });

  /// Boite geographique du sentier (avec marge), ou null si indisponible
  /// (aucune etape chargee) — alors la validation « hors zone » est desactivee.
  final GeoBounds? bounds;

  /// Points de reference (coordonnees d'etapes) pour la detection + le hors-trace.
  final List<StageReferencePoint> referencePoints;

  /// Nombre total d'etapes du parcours (pour l'affichage « detectees X/{total} »).
  final int totalStages;

  /// Marge (en degres) ajoutee autour de la boite des etapes pour tolerer les
  /// approches/variantes hors du strict segment depart-arrivee.
  final double boundsMarginDegrees;

  /// Distance (m) au-dela de laquelle un point est juge « eloigne de la trace »
  /// (au plus proche des points de reference). Sert au warning « X% hors trace ».
  final double outOfTraceToleranceMeters;

  /// Rayon (m) autour d'un point de reference d'etape pour considerer l'etape
  /// comme « detectee » sur la trace importee.
  final double stageDetectionRadiusMeters;

  /// Construit la config depuis les etapes du sentier actif.
  ///
  /// [bounds] = boite englobante des coordonnees depart/arrivee des etapes +
  /// [boundsMarginDegrees] de marge (null si aucune etape -> hors-zone tolerant).
  /// [referencePoints] = un point par extremite d'etape (depart ET arrivee).
  /// [totalStages] = nombre d'etapes fourni (parcours) ou, a defaut, le nombre
  /// d'etapes de la liste.
  factory TrailImportConfig.fromStages(
    List<Stage> stages, {
    int? totalStages,
    double boundsMarginDegrees = 0.15,
    double outOfTraceToleranceMeters = 5000,
    double stageDetectionRadiusMeters = 300,
  }) {
    final refs = <StageReferencePoint>[];
    for (final s in stages) {
      refs.add(StageReferencePoint(lat: s.startLat, lon: s.startLng, stage: s));
      refs.add(StageReferencePoint(lat: s.endLat, lon: s.endLng, stage: s));
    }

    GeoBounds? bounds;
    if (refs.isNotEmpty) {
      var minLat = double.infinity;
      var maxLat = -double.infinity;
      var minLon = double.infinity;
      var maxLon = -double.infinity;
      for (final r in refs) {
        if (r.lat < minLat) minLat = r.lat;
        if (r.lat > maxLat) maxLat = r.lat;
        if (r.lon < minLon) minLon = r.lon;
        if (r.lon > maxLon) maxLon = r.lon;
      }
      bounds = GeoBounds(
        minLat: minLat - boundsMarginDegrees,
        maxLat: maxLat + boundsMarginDegrees,
        minLon: minLon - boundsMarginDegrees,
        maxLon: maxLon + boundsMarginDegrees,
      );
    }

    return TrailImportConfig(
      bounds: bounds,
      referencePoints: refs,
      totalStages: totalStages ?? stages.length,
      boundsMarginDegrees: boundsMarginDegrees,
      outOfTraceToleranceMeters: outOfTraceToleranceMeters,
      stageDetectionRadiusMeters: stageDetectionRadiusMeters,
    );
  }
}

/// Boite geographique (min/max lat/lon), en degres decimaux.
class GeoBounds {
  const GeoBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  /// Le point ([lat],[lon]) est-il dans la boite ?
  bool contains(double lat, double lon) =>
      lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
}

/// Point de reference d'une etape (depart OU arrivee) pour la detection.
class StageReferencePoint {
  const StageReferencePoint({
    required this.lat,
    required this.lon,
    required this.stage,
  });

  final double lat;
  final double lon;
  final Stage stage;
}

/// Type de message d'avertissement produit par l'import (i18n cote UI).
///
/// Le service ne fabrique AUCUNE chaine visible : il retourne des codes typés
/// + des compteurs ; l'ecran traduit via Slang (5 langues). Parite avec les
/// warnings GR20, mais sans texte en dur dans le moteur.
enum ImportWarningType {
  /// N points hors de la zone geographique du sentier, ignores.
  outOfBounds,

  /// X % des points sont eloignes de la trace du sentier.
  offTrail,
}

/// Un avertissement d'import : un [type] + une [value] (compteur ou pourcentage).
class ImportWarning {
  const ImportWarning(this.type, this.value);

  final ImportWarningType type;

  /// Valeur associee : nombre de points (outOfBounds) ou pourcentage (offTrail).
  final int value;
}

/// Motif d'invalidite d'une trace importee (i18n cote UI).
enum ImportInvalidReason {
  /// Moins de [ImportedTrekData.minPoints] points GPS.
  tooFewPoints,

  /// Plus de 50 % des points hors de la zone geographique du sentier.
  outOfBounds,
}

/// Donnees d'un trek importe depuis un fichier GPX (parite modele GR20).
///
/// Generique : `stagesDetected` porte des [Stage] du domaine (etapes du sentier
/// actif), et les messages sont des CODES ([warnings]/[invalidReason]) traduits
/// par l'UI — aucun libelle en dur dans le moteur.
class ImportedTrekData {
  const ImportedTrekData({
    required this.trackPoints,
    required this.stagesDetected,
    required this.totalStages,
    required this.totalDistanceKm,
    required this.totalElevationGain,
    required this.totalElevationLoss,
    required this.totalDuration,
    required this.startDate,
    required this.endDate,
    required this.direction,
    required this.warnings,
    required this.isValid,
    this.invalidReason,
    this.invalidValue,
  });

  /// Nombre minimal de points GPS pour qu'une trace soit exploitable.
  static const int minPoints = 10;

  final List<TrackPoint> trackPoints;
  final List<Stage> stagesDetected;

  /// Nombre total d'etapes du parcours (pour l'affichage « X/{total} »).
  final int totalStages;
  final double totalDistanceKm;
  final int totalElevationGain;
  final int totalElevationLoss;
  final Duration totalDuration;
  final DateTime startDate;
  final DateTime endDate;

  /// Sens de la trace : 'NS' (nord->sud) ou 'SN' (sud->nord).
  final String direction;

  /// Avertissements non bloquants (codes typés + valeurs).
  final List<ImportWarning> warnings;

  /// La trace est-elle exploitable ?
  final bool isValid;

  /// Motif d'invalidite (si `!isValid`).
  final ImportInvalidReason? invalidReason;

  /// Valeur associee au motif d'invalidite (ex. nombre de points).
  final int? invalidValue;

  /// Fabrique une trace invalide portant un [reason] typé (i18n cote UI).
  factory ImportedTrekData.invalid(
    ImportInvalidReason reason, {
    int? value,
  }) {
    final now = DateTime.now();
    return ImportedTrekData(
      trackPoints: const [],
      stagesDetected: const [],
      totalStages: 0,
      totalDistanceKm: 0,
      totalElevationGain: 0,
      totalElevationLoss: 0,
      totalDuration: Duration.zero,
      startDate: now,
      endDate: now,
      direction: 'NS',
      warnings: const [],
      isValid: false,
      invalidReason: reason,
      invalidValue: value,
    );
  }
}

/// Service d'import GPX — GENERIQUE, data-driven par sentier.
///
/// Parite GR20 (`features/after/data/gpx_import_service.dart`) : meme flux
/// (parsing gpx -> validations -> calculs -> detection d'etapes), mais SANS
/// aucune constante GR20 (Corse / refuges 16 en dur). Les bornes geographiques,
/// les points de reference et le nombre d'etapes proviennent de la config du
/// sentier ([TrailImportConfig], derivee des etapes), et les tolerances sont des
/// parametres. Aucune chaine visible n'est produite ici (codes traduits par l'UI).
class GpxImportService {
  const GpxImportService();

  /// Parse [gpxContent] et valide/analyse la trace au regard de [config].
  ImportedTrekData importGpxFile(String gpxContent, TrailImportConfig config) {
    final warnings = <ImportWarning>[];
    final Gpx gpx;
    try {
      gpx = GpxReader().fromString(gpxContent);
    } catch (_) {
      // Parsing impossible -> trace trop pauvre (l'UI affiche le motif).
      return ImportedTrekData.invalid(
        ImportInvalidReason.tooFewPoints,
        value: 0,
      );
    }

    // Aplati tous les trks -> trksegs -> trkpts (parite GR20).
    final wpts = <Wpt>[];
    for (final trk in gpx.trks) {
      for (final seg in trk.trksegs) {
        wpts.addAll(seg.trkpts);
      }
    }

    if (wpts.length < ImportedTrekData.minPoints) {
      return ImportedTrekData.invalid(
        ImportInvalidReason.tooFewPoints,
        value: wpts.length,
      );
    }

    // Validation « hors zone » — seulement si le sentier fournit une boite
    // (derivee des etapes). Sans boite, on n'ecarte rien (tolerant, data-driven).
    if (config.bounds != null) {
      final bounds = config.bounds!;
      var outOfBoundsCount = 0;
      for (final wpt in wpts) {
        final lat = wpt.lat ?? 0;
        final lon = wpt.lon ?? 0;
        if (!bounds.contains(lat, lon)) outOfBoundsCount++;
      }
      if (outOfBoundsCount > wpts.length * 0.5) {
        return ImportedTrekData.invalid(
          ImportInvalidReason.outOfBounds,
          value: outOfBoundsCount,
        );
      }
      if (outOfBoundsCount > 0) {
        warnings.add(
          ImportWarning(ImportWarningType.outOfBounds, outOfBoundsCount),
        );
      }
    }

    // Conversion en TrackPoint du domaine (lat/lng/elevation/timestamp).
    final trackPoints = <TrackPoint>[];
    for (final wpt in wpts) {
      trackPoints.add(TrackPoint(
        lat: wpt.lat ?? 0,
        lng: wpt.lon ?? 0,
        elevation: wpt.ele ?? 0,
        timestamp: wpt.time,
      ));
    }

    // Controle « hors trace » (non bloquant) : proportion de points eloignes du
    // plus proche point de reference du sentier. Ignore si aucun point de ref.
    if (config.referencePoints.isNotEmpty) {
      var outOfToleranceCount = 0;
      for (final tp in trackPoints) {
        var minDist = double.infinity;
        for (final ref in config.referencePoints) {
          final dist =
              GeoUtils.haversineDistance(tp.lat, tp.lng, ref.lat, ref.lon);
          if (dist < minDist) minDist = dist;
        }
        if (minDist > config.outOfTraceToleranceMeters) outOfToleranceCount++;
      }
      final percent =
          (outOfToleranceCount / trackPoints.length * 100).round();
      if (percent > 30) {
        warnings.add(ImportWarning(ImportWarningType.offTrail, percent));
      }
    }

    // Detection d'etapes : une etape est detectee si un point de la trace passe
    // dans le rayon d'un de ses points de reference (depart ou arrivee).
    final stagesDetected = <Stage>[];
    final detectedIds = <String>{};
    for (final tp in trackPoints) {
      for (final ref in config.referencePoints) {
        if (detectedIds.contains(ref.stage.id)) continue;
        final dist =
            GeoUtils.haversineDistance(tp.lat, tp.lng, ref.lat, ref.lon);
        if (dist < config.stageDetectionRadiusMeters) {
          detectedIds.add(ref.stage.id);
          stagesDetected.add(ref.stage);
        }
      }
    }
    stagesDetected.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

    // Distance totale (Haversine cumule).
    var totalDistanceM = 0.0;
    for (var i = 1; i < trackPoints.length; i++) {
      totalDistanceM += GeoUtils.haversineDistance(
        trackPoints[i - 1].lat,
        trackPoints[i - 1].lng,
        trackPoints[i].lat,
        trackPoints[i].lng,
      );
    }

    // D+ / D- (delta d'altitude).
    var totalElevationGain = 0;
    var totalElevationLoss = 0;
    for (var i = 1; i < trackPoints.length; i++) {
      final diff = trackPoints[i].elevation - trackPoints[i - 1].elevation;
      if (diff > 0) {
        totalElevationGain += diff.round();
      } else {
        totalElevationLoss += diff.abs().round();
      }
    }

    // Duree = fin - debut (timestamps GPS si presents, sinon zero).
    final startDate = trackPoints.first.timestamp;
    final endDate = trackPoints.last.timestamp;
    final totalDuration = (startDate != null && endDate != null)
        ? endDate.difference(startDate)
        : Duration.zero;

    // Direction : comparaison de latitude premier vs dernier point.
    final firstLat = trackPoints.first.lat;
    final lastLat = trackPoints.last.lat;
    final direction = firstLat > lastLat ? 'NS' : 'SN';

    return ImportedTrekData(
      trackPoints: trackPoints,
      stagesDetected: stagesDetected,
      totalStages: config.totalStages,
      totalDistanceKm: totalDistanceM / 1000,
      totalElevationGain: totalElevationGain,
      totalElevationLoss: totalElevationLoss,
      totalDuration: totalDuration,
      startDate: startDate ?? DateTime.now(),
      endDate: endDate ?? DateTime.now(),
      direction: direction,
      warnings: warnings,
      isValid: true,
    );
  }
}
