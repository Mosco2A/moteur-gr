/// L'ESTIME LE LONG DU TRACE (lot 671-03) : entre deux releves GPS, le point
/// avance sur le trace connu au rythme des pas comptes, et chaque releve reel
/// le remet a sa vraie place.
///
/// L'ARGUMENT CENTRAL, ET TOUT CE FICHIER EN DECOULE : LA DERIVE NE
/// S'ACCUMULE PAS. Chaque estime repart du DERNIER RELEVE projete, jamais de
/// l'estime precedent : l'erreur a un instant donne est celle du dernier
/// intervalle, pas celle de la journee. A 3 % d'erreur de longueur de pas,
/// trois minutes de marche a 4 km/h valent 200 m d'estime, donc 6 m d'erreur
/// — et non 750 m sur vingt-cinq kilometres.
///
/// AUCUN CAPTEUR DE CAP. Sur un trace connu, la direction est portee par le
/// trace ; seul le SENS reste a trancher, et ce sont les deux derniers releves
/// qui le donnent ([TrackProjector.directionOf]).
///
/// HORS DU TRACE, PAS D'ESTIME. Un releve a plus de
/// [kOffTrackExitThresholdMeters] du trace suspend l'avance jusqu'a un releve
/// revenu sous [kOffTrackReturnThresholdMeters] : hors du sentier, le
/// podometre n'a plus de rail. Les seuils et l'hysteresis sont ceux du
/// detecteur hors-trace de la carte, et de lui seul.
library;

import 'package:geolocator/geolocator.dart';

import '../../../core/geo/geo_utils.dart';
import '../../../core/geo/track_projection.dart';
import '../../../core/services/gps_cadence.dart';
import '../../map/map_facade.dart' show OffTrackDetector;
import 'trace_de_fond.dart';

/// LE PLAFOND DE DISTANCE ESTIMEE : un releve est demande des que l'estime a
/// avance de 500 m depuis le dernier, sans attendre la periode du profil.
///
/// LE RELEVE PART AU PREMIER DES DEUX : la periode du profil
/// ([kBatteryFirstShotPeriod], [kLowBatteryShotPeriod]) ou ce plafond. CE
/// QU'IL FAIT VRAIMENT, ARITHMETIQUE A L'APPUI : a 4 km/h, 3 minutes valent
/// 200 m, donc en profil batterie d'abord la PERIODE gagne presque toujours ;
/// le plafond ne s'y declenche qu'au-dela de 10 km/h (500 m en 3 min), en
/// descente courue. En profil batterie basse, en revanche, 15 minutes valent
/// 1 km a 4 km/h : la le plafond MORD, il ramene l'intervalle a 7 min 30, et
/// c'est la qu'il sert. Une mesure future le corrigera peut-etre : il est
/// nomme pour cela.
const double kEstimateDistanceCeilingMeters = 500.0;

/// L'estime sur UN trace : recalage aux releves, avance aux pas, sens de la
/// marche, suspension hors du trace, retenue des points. Sans horloge, sans
/// capteur, sans preference : tout lui est donne.
class TrackDeadReckoning {
  /// L'estime sur [trace], qui porte aussi le sens de repli.
  TrackDeadReckoning(this.trace)
    : _direction = trace.direction,
      _detector = OffTrackDetector();

  /// Le trace reduit et le sens de la marche connu du trek.
  final BackgroundTrace trace;
  final OffTrackDetector _detector;
  WalkDirection _direction;
  TrackAbscissa? _anchor;
  int? _anchorSteps;
  double? _previousFixM;
  int? _lastIndex;
  TrackAbscissa? _lastEstimate;
  ({double lat, double lng})? _lastKept;

  /// Le sens courant de la marche.
  WalkDirection get direction => _direction;

  /// Le dernier estime calcule depuis le dernier releve, nul s'il n'y en a
  /// pas eu.
  TrackAbscissa? get lastEstimate => _lastEstimate;

  /// Vrai quand le dernier releve a quitte le trace : l'estime est suspendu.
  bool get isOffTrack => _detector.isOffTrack;

  /// La distance avancee par l'estime depuis le dernier releve, le long du
  /// trace ; nulle sans estime.
  double get estimatedSinceFixMeters {
    final anchor = _anchor;
    final estimate = _lastEstimate;
    if (anchor == null || estimate == null) return 0;
    return (estimate.distanceFromStartM - anchor.distanceFromStartM).abs();
  }

  /// RECALE sur un releve reel, pris quand le total consolide valait
  /// [steps], et rend L'ECART AU DERNIER ESTIME : la distance, LE LONG DU
  /// TRACE, entre le dernier point estime et le releve projete. Nul quand
  /// aucun estime ne precede le releve. C'est le champ 8 du journal, et c'est
  /// exactement ce que mesure le banc de derive.
  double? recalibrate({
    required double latitude,
    required double longitude,
    required int? steps,
  }) {
    final projection = TrackProjector.project(
      userLat: latitude,
      userLng: longitude,
      trackPoints: trace.points,
      lastKnownIndex: _lastIndex,
    );
    _lastIndex = projection.trackIndexPosition;
    final fixM = projection.distanceFromStartM;
    final estimate = _lastEstimate;
    final drift = estimate == null
        ? null
        : (estimate.distanceFromStartM - fixM).abs();
    _lastEstimate = null;
    _lastKept = (lat: latitude, lng: longitude);
    _detector.update(projection.distanceToTrackM);
    if (_detector.isOffTrack) {
      _anchor = null;
      _previousFixM = null;
      return drift;
    }
    _direction = TrackProjector.directionOf(
      previousM: _previousFixM,
      latestM: fixM,
      fallback: _direction,
    );
    _previousFixM = fixM;
    _anchor = TrackProjector.locate(
      trackPoints: trace.points,
      distanceFromStartM: fixM,
    );
    _anchorSteps = steps;
    return drift;
  }

  /// FAIT AVANCER le point : depuis le DERNIER RELEVE, de (pas depuis ce
  /// releve) x [strideMeters], dans le sens courant. Nul sans rail : aucun
  /// releve sur le trace, pas inconnus, ou hors du trace.
  TrackAbscissa? advance({required int? steps, required double strideMeters}) {
    final anchor = _anchor;
    final fromSteps = _anchorSteps;
    if (anchor == null || fromSteps == null || steps == null) return null;
    final walked = steps - fromSteps;
    // Le total consolide ne recule jamais (lot 671-02) ; s'il le faisait, on
    // repartirait de lui plutot que de faire reculer le point.
    if (walked < 0) {
      _anchorSteps = steps;
      return null;
    }
    return _lastEstimate = TrackProjector.advance(
      trackPoints: trace.points,
      from: anchor,
      meters: walked * strideMeters,
      direction: _direction,
    );
  }

  /// LA REGLE DE RETENUE DE L'ISOLATE DE FOND, la meme pour les deux
  /// origines : un estime n'est retenu que s'il est a [minDistanceMeters] du
  /// dernier point retenu, releve ou estime. Une trace estimee tous les 12 m
  /// est dense, lisible, et coherente avec ce que la table contient deja.
  bool keep(TrackAbscissa estimate, double minDistanceMeters) {
    final last = _lastKept;
    if (last != null &&
        GeoUtils.haversineDistance(
              last.lat,
              last.lng,
              estimate.lat,
              estimate.lng,
            ) <
            minDistanceMeters) {
      return false;
    }
    _lastKept = (lat: estimate.lat, lng: estimate.lng);
    return true;
  }
}

/// L'estime tel que l'isolate de fond le mene : le trace relu au canal, le
/// profil qui l'autorise, le plafond de distance qui demande un releve.
///
/// L'AVANCE EST RECALCULEE A CHAQUE PAQUET DE PAS RECU, ET A RIEN D'AUTRE :
/// le podometre livre ses pas par paquets, une avance de plus entre deux
/// paquets ne bougerait pas le point, et un minuteur de plus serait une
/// depense pour rien.
class BackgroundEstimate {
  /// [readTrace] relit le canal [kPrefsBgTrace] ; [trailId] est le sentier
  /// suivi ; [keepDistanceMeters] la regle de retenue de l'isolate ;
  /// [requestFix] demande un releve immediat (plafond de distance).
  BackgroundEstimate({
    required Future<String?> Function() readTrace,
    required String Function() trailId,
    required double Function() keepDistanceMeters,
    void Function()? requestFix,
  }) : _readTrace = readTrace,
       _trailId = trailId,
       _keepDistanceMeters = keepDistanceMeters,
       _requestFix = requestFix;

  final Future<String?> Function() _readTrace;
  final String Function() _trailId;
  final double Function() _keepDistanceMeters;
  final void Function()? _requestFix;
  TrackDeadReckoning? _reckoning;
  String? _raw;
  bool _fixRequested = false;

  /// L'estime en cours, nul sans trace utilisable ou hors profil batterie.
  TrackDeadReckoning? get reckoning => _reckoning;

  /// Un releve (ou un tir sans position) sous [profile] : rend l'ecart au
  /// dernier estime, en metres le long du trace, nul sans estime. Hors des
  /// profils de tir (carte), l'estime est sans objet : il est oublie.
  Future<double?> onFix(
    Position? position,
    int? steps,
    PositionProfile profile,
  ) async {
    if (position == null) return null;
    if (!GpsCadence.of(profile).isSingleShot) {
      _reckoning = null;
      _raw = null;
      return null;
    }
    await _reload();
    _fixRequested = false;
    return _reckoning?.recalibrate(
      latitude: position.latitude,
      longitude: position.longitude,
      steps: steps,
    );
  }

  /// Un paquet de pas : rend l'estime s'il est RETENU, nul sinon.
  TrackAbscissa? onSteps(int? steps, double strideMeters, PositionProfile p) {
    final reckoning = _reckoning;
    if (reckoning == null || !GpsCadence.of(p).isSingleShot) return null;
    final estimate = reckoning.advance(
      steps: steps,
      strideMeters: strideMeters,
    );
    if (estimate == null) return null;
    final ceiling =
        reckoning.estimatedSinceFixMeters >= kEstimateDistanceCeilingMeters;
    if (ceiling && !_fixRequested) {
      _fixRequested = true;
      _requestFix?.call();
    }
    return reckoning.keep(estimate, _keepDistanceMeters()) ? estimate : null;
  }

  /// Relit le trace s'il a change ; un trace d'un autre sentier est ignore.
  Future<void> _reload() async {
    String? raw;
    try {
      raw = await _readTrace();
    } on Object {
      raw = null;
    }
    if (raw == _raw && _reckoning != null) return;
    _raw = raw;
    final trace = decodeBackgroundTrace(raw);
    final trailId = _trailId();
    final usable =
        trace != null && (trailId.isEmpty || trace.trailId == trailId);
    _reckoning = usable ? TrackDeadReckoning(trace) : null;
  }
}
