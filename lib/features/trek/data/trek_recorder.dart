import 'package:uuid/uuid.dart';

import '../../../core/error/error_handler.dart';
import '../domain/models/track_point.dart';
import '../domain/models/trek_session.dart';

/// Callback pour persister un batch de TrackPoints en Drift.
typedef FlushCallback = Future<void> Function(
  String sessionId,
  List<TrackPoint> points,
);

/// Callback pour persister une TrekSession en Drift.
typedef SessionPersistCallback = Future<void> Function(TrekSession session);

/// Enregistreur de traces GPS pour une session de trek.
///
/// Responsabilites :
/// - Buffer de [bufferSize] TrackPoints en memoire
/// - Flush automatique vers Drift quand le buffer est plein
/// - Gestion du cycle de vie : start / stop / pause / resume
/// - ZERO Firebase — tout est local Drift
/// - ZERO catch silencieux — chaque erreur passe par ErrorHandler
class TrekRecorder {
  TrekRecorder({
    required FlushCallback onFlush,
    required SessionPersistCallback onSessionPersist,
    int bufferSize = defaultBufferSize,
    Uuid? uuid,
  })  : _onFlush = onFlush,
        _onSessionPersist = onSessionPersist,
        _bufferSize = bufferSize,
        _uuid = uuid ?? const Uuid();

  /// Taille du buffer par defaut avant flush.
  static const int defaultBufferSize = 10;

  final FlushCallback _onFlush;
  final SessionPersistCallback _onSessionPersist;
  final int _bufferSize;
  final Uuid _uuid;

  /// Buffer de points en attente de flush.
  final List<TrackPoint> _buffer = [];

  /// Session active (null si arretee).
  TrekSession? _currentSession;

  /// Etat interne : recording, paused, stopped.
  _RecorderState _state = _RecorderState.stopped;

  // --- Getters publics pour les tests ---

  /// Nombre de points dans le buffer.
  int get bufferCount => _buffer.length;

  /// Session en cours (null si inactive).
  TrekSession? get currentSession => _currentSession;

  /// True si l'enregistrement est actif (pas en pause, pas arrete).
  bool get isRecording => _state == _RecorderState.recording;

  /// True si l'enregistrement est en pause.
  bool get isPaused => _state == _RecorderState.paused;

  /// True si l'enregistrement est arrete.
  bool get isStopped => _state == _RecorderState.stopped;

  /// Demarre une nouvelle session de trek.
  ///
  /// Cree un UUID, persiste la session avec statut "active",
  /// et passe en mode enregistrement.
  /// Leve [StateError] si une session est deja active.
  Future<TrekSession> start(String trailId) async {
    if (_state != _RecorderState.stopped) {
      final error = StateError(
        'TrekRecorder.start: session deja active (${_currentSession?.id})',
      );
      ErrorHandler.log(error, context: 'TrekRecorder.start');
      throw error;
    }

    try {
      final session = TrekSession(
        id: _uuid.v4(),
        trailId: trailId,
        startedAt: DateTime.now(),
        status: 'active',
      );

      await _onSessionPersist(session);
      _currentSession = session;
      _state = _RecorderState.recording;
      return session;
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'TrekRecorder.start');
      rethrow;
    }
  }

  /// Arrete la session en cours.
  ///
  /// Flush le buffer restant, finalise la session avec statut "completed"
  /// et horodatage de fin, puis persiste.
  /// Leve [StateError] si aucune session n'est active.
  Future<TrekSession> stop() async {
    if (_state == _RecorderState.stopped || _currentSession == null) {
      final error = StateError('TrekRecorder.stop: aucune session active');
      ErrorHandler.log(error, context: 'TrekRecorder.stop');
      throw error;
    }

    try {
      // Flush les points restants dans le buffer
      if (_buffer.isNotEmpty) {
        await _flush();
      }

      final finalized = _currentSession!.copyWith(
        status: 'completed',
        finishedAt: DateTime.now(),
      );

      await _onSessionPersist(finalized);
      _currentSession = null;
      _state = _RecorderState.stopped;
      return finalized;
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'TrekRecorder.stop');
      rethrow;
    }
  }

  /// Met en pause l'enregistrement.
  ///
  /// Les points GPS recus pendant la pause sont ignores.
  /// Leve [StateError] si pas en enregistrement.
  void pause() {
    if (_state != _RecorderState.recording) {
      final error = StateError(
        'TrekRecorder.pause: pas en enregistrement (etat: $_state)',
      );
      ErrorHandler.log(error, context: 'TrekRecorder.pause');
      throw error;
    }
    _state = _RecorderState.paused;
  }

  /// Reprend l'enregistrement apres une pause.
  ///
  /// Leve [StateError] si pas en pause.
  void resume() {
    if (_state != _RecorderState.paused) {
      final error = StateError(
        'TrekRecorder.resume: pas en pause (etat: $_state)',
      );
      ErrorHandler.log(error, context: 'TrekRecorder.resume');
      throw error;
    }
    _state = _RecorderState.recording;
  }

  /// Ajoute un point GPS au buffer.
  ///
  /// Si le buffer atteint [_bufferSize], flush automatiquement vers Drift.
  /// Les points sont ignores si l'enregistrement est en pause ou arrete.
  Future<void> addPoint(TrackPoint point) async {
    if (_state != _RecorderState.recording) {
      return;
    }

    try {
      _buffer.add(point);

      if (_buffer.length >= _bufferSize) {
        await _flush();
      }
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'TrekRecorder.addPoint');
      rethrow;
    }
  }

  /// Flush le buffer vers Drift via le callback.
  Future<void> _flush() async {
    if (_buffer.isEmpty || _currentSession == null) {
      return;
    }

    final batch = List<TrackPoint>.from(_buffer);
    _buffer.clear();

    try {
      await _onFlush(_currentSession!.id, batch);
    } on Exception catch (e, st) {
      // Remettre les points dans le buffer en cas d'echec
      _buffer.insertAll(0, batch);
      ErrorHandler.log(e, stackTrace: st, context: 'TrekRecorder._flush');
      rethrow;
    }
  }
}

/// Etats internes du recorder.
enum _RecorderState {
  stopped,
  recording,
  paused,
}
