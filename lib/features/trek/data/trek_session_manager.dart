import '../../../core/error/error_handler.dart';
import '../domain/models/trek_session.dart';

/// Session orpheline detectee au lancement.
///
/// Contient la session active trouvee en base et son age
/// pour permettre a l'UI de proposer la reprise ou l'abandon.
class PendingSession {
  const PendingSession({
    required this.session,
    required this.age,
  });

  /// La session active trouvee en base.
  final TrekSession session;

  /// Duree depuis le debut de la session.
  final Duration age;

  /// True si la session a plus de 7 jours (candidate au nettoyage).
  bool get isExpired => age.inDays >= 7;
}

/// Callback pour chercher les sessions actives en Drift.
typedef FindActiveSessionsCallback = Future<List<TrekSession>> Function();

/// Callback pour supprimer une session en Drift.
typedef DeleteSessionCallback = Future<void> Function(String sessionId);

/// Callback pour mettre a jour le statut d'une session en Drift.
typedef UpdateSessionStatusCallback = Future<void> Function(
  String sessionId,
  String status,
);

/// Gestionnaire de reprise apres crash pour les sessions de trek.
///
/// Responsabilites :
/// - Detecter les sessions orphelines (status=active) au lancement
/// - Proposer la reprise via [PendingSession]
/// - Nettoyer les sessions abandonnees de plus de 7 jours
/// - ZERO Firebase — tout est local Drift
/// - ZERO catch silencieux — chaque erreur passe par ErrorHandler
class TrekSessionManager {
  TrekSessionManager({
    required FindActiveSessionsCallback onFindActiveSessions,
    required DeleteSessionCallback onDeleteSession,
    required UpdateSessionStatusCallback onUpdateSessionStatus,
    DateTime Function()? clock,
  })  : _onFindActiveSessions = onFindActiveSessions,
        _onDeleteSession = onDeleteSession,
        _onUpdateSessionStatus = onUpdateSessionStatus,
        _clock = clock ?? DateTime.now;

  final FindActiveSessionsCallback _onFindActiveSessions;
  final DeleteSessionCallback _onDeleteSession;
  final UpdateSessionStatusCallback _onUpdateSessionStatus;
  final DateTime Function() _clock;

  /// Cherche une session active en base.
  ///
  /// Retourne un [PendingSession] si une session avec status=active
  /// existe en base (signe d'un crash ou fermeture brutale).
  /// Retourne null si aucune session orpheline.
  Future<PendingSession?> checkPendingSession() async {
    try {
      final activeSessions = await _onFindActiveSessions();

      if (activeSessions.isEmpty) {
        return null;
      }

      // Prendre la plus recente
      final session = activeSessions.reduce(
        (a, b) => a.startedAt.isAfter(b.startedAt) ? a : b,
      );

      final age = _clock().difference(session.startedAt);

      return PendingSession(session: session, age: age);
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'TrekSessionManager.checkPendingSession',
      );
      rethrow;
    }
  }

  /// Supprime les sessions orphelines de plus de 7 jours.
  ///
  /// Une session est consideree orpheline si :
  /// - status == "active"
  /// - startedAt date de plus de 7 jours
  ///
  /// Retourne le nombre de sessions nettoyees.
  Future<int> cleanOrphans() async {
    try {
      final activeSessions = await _onFindActiveSessions();
      final now = _clock();
      final cutoff = now.subtract(const Duration(days: 7));

      var cleaned = 0;
      for (final session in activeSessions) {
        if (session.startedAt.isBefore(cutoff)) {
          await _onUpdateSessionStatus(session.id, 'abandoned');
          await _onDeleteSession(session.id);
          cleaned++;
        }
      }

      return cleaned;
    } on Exception catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'TrekSessionManager.cleanOrphans',
      );
      rethrow;
    }
  }
}
