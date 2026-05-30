import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';
import 'gps_service.dart';

/// Intervalle GPS normal (15 secondes).
const int kNormalIntervalMs = 15000;

/// Intervalle GPS batterie basse (30 secondes).
const int kLowBatteryIntervalMs = 30000;

/// Seuil batterie basse (20%).
const int kLowBatteryThreshold = 20;

/// Duree max en background sans trek actif avant pause (30 min).
const int kBackgroundPauseMinutes = 30;

/// ID notification foreground Android.
const int kForegroundNotificationId = 9001;

/// Channel ID pour la notification foreground Android.
const String kForegroundChannelId = 'moteur_gr_gps_foreground';

/// Channel name pour la notification foreground Android.
const String kForegroundChannelName = 'GPS Tracking';

/// Service GPS en arriere-plan avec notification foreground Android.
///
/// Etend GpsService avec :
/// - Notification foreground Android pour keep-alive
/// - Intervalle adaptatif : 15s normal, 30s si batterie < 20%
/// - Lifecycle aware : pause quand app en background > 30 min sans trek actif
/// - ZERO catch silencieux -- toute erreur via ErrorHandler
class BackgroundGpsService extends GpsService with WidgetsBindingObserver {
  BackgroundGpsService({
    Battery? battery,
    FlutterLocalNotificationsPlugin? notificationsPlugin,
    super.isLocationServiceEnabled,
    super.checkPermission,
    super.requestPermission,
    super.getPositionStream,
  })  : _battery = battery ?? Battery(),
        _notificationsPlugin =
            notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  final Battery _battery;
  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  bool _isTrekActive = false;
  DateTime? _backgroundSince;
  bool _isPaused = false;
  StreamController<Position>? _adaptiveController;
  StreamSubscription<Position>? _sourceSubscription;
  Timer? _throttleTimer;
  Position? _lastPosition;
  int _currentIntervalMs = kNormalIntervalMs;

  Future<void> start() async {
    try {
      await _showForegroundNotification();
      WidgetsBinding.instance.addObserver(this);
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'BackgroundGpsService.start');
      rethrow;
    }
  }

  Future<void> stop() async {
    try {
      _throttleTimer?.cancel();
      _throttleTimer = null;
      await _sourceSubscription?.cancel();
      _sourceSubscription = null;
      await _adaptiveController?.close();
      _adaptiveController = null;
      await _cancelForegroundNotification();
      WidgetsBinding.instance.removeObserver(this);
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'BackgroundGpsService.stop');
      rethrow;
    }
  }

  void setTrekActive(bool active) {
    _isTrekActive = active;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _backgroundSince = DateTime.now();
      case AppLifecycleState.resumed:
        _backgroundSince = null;
        if (_isPaused) {
          _isPaused = false;
          _resumeStream();
        }
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
        break;
    }
  }

  @override
  Stream<Position> getPositionStream() {
    _adaptiveController = StreamController<Position>.broadcast(
      onCancel: () {
        _throttleTimer?.cancel();
        _sourceSubscription?.cancel();
      },
    );
    _startAdaptiveStream();
    return _adaptiveController!.stream;
  }

  void _startAdaptiveStream() {
    final sourceStream = super.getPositionStream();
    _sourceSubscription = sourceStream.listen(
      (position) {
        _lastPosition = position;
        _emitIfReady();
      },
      onError: (Object error, StackTrace stackTrace) {
        ErrorHandler.log(
          error,
          stackTrace: stackTrace,
          context: 'BackgroundGpsService.getPositionStream',
        );
        _adaptiveController?.addError(error, stackTrace);
      },
      onDone: () {
        _adaptiveController?.close();
      },
    );
    _scheduleThrottle();
  }

  void _scheduleThrottle() {
    _throttleTimer?.cancel();
    _throttleTimer = Timer.periodic(
      Duration(milliseconds: _currentIntervalMs),
      (_) => _emitIfReady(),
    );
  }

  void _emitIfReady() {
    if (_shouldPause()) {
      if (!_isPaused) {
        _isPaused = true;
        _pauseStream();
      }
      return;
    }
    _updateIntervalFromBattery();
    final position = _lastPosition;
    if (position != null &&
        _adaptiveController != null &&
        !_adaptiveController!.isClosed) {
      _adaptiveController!.add(position);
      _lastPosition = null;
    }
  }

  bool _shouldPause() {
    if (_isTrekActive) return false;
    if (_backgroundSince == null) return false;
    final elapsed = DateTime.now().difference(_backgroundSince!);
    return elapsed.inMinutes >= kBackgroundPauseMinutes;
  }

  void _pauseStream() {
    _throttleTimer?.cancel();
    _sourceSubscription?.pause();
  }

  void _resumeStream() {
    _sourceSubscription?.resume();
    _scheduleThrottle();
  }

  Future<void> _updateIntervalFromBattery() async {
    try {
      final batteryLevel = await _battery.batteryLevel;
      final newInterval = batteryLevel < kLowBatteryThreshold
          ? kLowBatteryIntervalMs
          : kNormalIntervalMs;
      if (newInterval != _currentIntervalMs) {
        _currentIntervalMs = newInterval;
        _scheduleThrottle();
      }
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'BackgroundGpsService._updateIntervalFromBattery',
      );
    }
  }

  Future<void> _showForegroundNotification() async {
    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _notificationsPlugin.initialize(initSettings);

      const androidDetails = AndroidNotificationDetails(
        kForegroundChannelId,
        kForegroundChannelName,
        channelDescription: 'GPS tracking en cours',
        importance: Importance.low,
        priority: Priority.low,
        ongoing: true,
        autoCancel: false,
      );
      const details = NotificationDetails(android: androidDetails);

      await _notificationsPlugin.show(
        kForegroundNotificationId,
        'Moteur GR',
        'GPS actif',
        details,
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'BackgroundGpsService._showForegroundNotification',
      );
      rethrow;
    }
  }

  Future<void> _cancelForegroundNotification() async {
    try {
      await _notificationsPlugin.cancel(kForegroundNotificationId);
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'BackgroundGpsService._cancelForegroundNotification',
      );
      rethrow;
    }
  }

  int get currentIntervalMs => _currentIntervalMs;

  Future<void> updateInterval() => _updateIntervalFromBattery();
}

final backgroundGpsServiceProvider = Provider<BackgroundGpsService>((ref) {
  return BackgroundGpsService();
});
