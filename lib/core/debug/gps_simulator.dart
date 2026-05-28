import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gpx/gpx.dart';

import '../geo/track_point.dart';

/// Vitesses de lecture du simulateur GPS.
enum SimulationSpeed {
  x1(1),
  x10(10),
  x50(50),
  x100(100);

  const SimulationSpeed(this.factor);
  final int factor;
  int get intervalMs => (1000 / factor).round();
}

/// Simulateur GPS qui lit un fichier GPX et emet des positions via Stream.
///
/// Permet de tester le tracking sans GPS reel, notamment sur emulateur.
/// Garde par [kDebugMode] -- en release, n'emet rien.
class GpsSimulator {
  GpsSimulator._({required List<TrackPoint> points}) : _points = points;

  /// Parse un fichier GPX depuis une chaine XML.
  factory GpsSimulator.fromGpxString(String gpxContent) {
    final gpx = GpxReader().fromString(gpxContent);
    final points = <TrackPoint>[];
    var cumulativeDistance = 0.0;
    if (gpx.trks.isNotEmpty) {
      for (final segment in gpx.trks.first.trksegs) {
        for (final wpt in segment.trkpts) {
          final lat = wpt.lat;
          final lng = wpt.lon;
          final alt = wpt.ele;
          if (lat == null || lng == null) continue;
          points.add(TrackPoint(
            lat: lat.toDouble(),
            lng: lng.toDouble(),
            altitude: alt?.toDouble() ?? 0.0,
            distanceFromStart: cumulativeDistance,
          ));
          cumulativeDistance += 100;
        }
      }
    }
    return GpsSimulator._(points: points);
  }

  /// Cree un simulateur directement depuis une liste de points.
  factory GpsSimulator.fromPoints(List<TrackPoint> points) {
    return GpsSimulator._(points: List.unmodifiable(points));
  }

  final List<TrackPoint> _points;
  StreamController<TrackPoint>? _controller;
  Timer? _timer;
  int _currentIndex = 0;
  bool _isRunning = false;

  int get pointCount => _points.length;
  int get currentIndex => _currentIndex;
  bool get isRunning => _isRunning;

  Stream<TrackPoint> get positionStream {
    _controller ??= StreamController<TrackPoint>.broadcast();
    return _controller!.stream;
  }

  void start({SimulationSpeed speed = SimulationSpeed.x10}) {
    if (!kDebugMode) return;
    if (_points.isEmpty) return;
    stop();
    _controller ??= StreamController<TrackPoint>.broadcast();
    _isRunning = true;
    _currentIndex = 0;
    _timer = Timer.periodic(
      Duration(milliseconds: speed.intervalMs),
      (_) => _emitNext(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  void dispose() {
    stop();
    _controller?.close();
    _controller = null;
  }

  void _emitNext() {
    if (_currentIndex >= _points.length) {
      stop();
      return;
    }
    final point = _points[_currentIndex];
    _controller?.add(point);
    _currentIndex++;
  }
}
