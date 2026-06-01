import 'package:drift/drift.dart';
import 'package:logger/logger.dart';

import '../../../core/data/daos/feedback_queue_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/network/connectivity_monitor.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Categories de feedback disponibles.
///
/// bug, suggestion, compliment — extensible via String.
abstract class FeedbackCategory {
  static const String bug = 'bug';
  static const String suggestion = 'suggestion';
  static const String compliment = 'compliment';
  static const String fallback = suggestion;
  static const List<String> values = [bug, suggestion, compliment];

  /// Valide une categorie ; retourne fallback si inconnue.
  static String fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Statuts possibles d'un feedback dans la file Drift.
abstract class FeedbackStatus {
  static const String pending = 'pending';
  static const String sent = 'sent';
  static const String failed = 'failed';
}

/// Service offline-first de feedback.
///
/// Stocke les feedbacks dans la file Drift (FeedbackQueueDao)
/// et tente l'envoi quand la connexion est disponible.
/// Aucun feedback n'est perdu : tout passe par la queue locale.
class FeedbackService {
  FeedbackService({
    required FeedbackQueueDao dao,
    required ConnectivityMonitor connectivityMonitor,
  })  : _dao = dao,
        _connectivityMonitor = connectivityMonitor;

  final FeedbackQueueDao _dao;
  final ConnectivityMonitor _connectivityMonitor;

  /// Soumet un feedback — stocke localement, puis tente l'envoi si en ligne.
  ///
  /// Retourne l'id du feedback insere en base.
  Future<int> submit({
    required String trailId,
    required String category,
    required String content,
    int? rating,
  }) async {
    // Validation categorie
    final validCategory = FeedbackCategory.fromString(category);

    final id = await _dao.addFeedback(FeedbackQueueCompanion(
      trailId: Value(trailId),
      feedbackType: Value(validCategory),
      content: Value(content),
      rating: Value(rating),
      createdAt: Value(DateTime.now()),
    ));

    _log.d('[FeedbackService] Feedback #$id stocke (categorie=$validCategory)');

    // Tentative d'envoi immediat si connecte
    await _flushIfOnline();

    return id;
  }

  /// Nombre de feedbacks en attente d'envoi.
  Future<int> pendingCount() => _dao.countPending();

  /// Recupere les feedbacks en attente.
  Future<List<FeedbackQueueData>> pendingFeedbacks() => _dao.getPending();

  /// Force le flush de la file d'attente (appel manuel ou reconnexion).
  Future<int> flush() async {
    final status = await _connectivityMonitor.checkStatus();
    if (status != ConnectivityStatusValues.online) {
      _log.d('[FeedbackService] Flush annule — hors ligne');
      return 0;
    }
    return _sendPending();
  }

  /// Tente l'envoi si la connexion est en ligne.
  Future<void> _flushIfOnline() async {
    try {
      final status = await _connectivityMonitor.checkStatus();
      if (status == ConnectivityStatusValues.online) {
        await _sendPending();
      }
    } catch (e) {
      // Pas de propagation — le feedback est deja en base
      _log.d('[FeedbackService] Erreur flush auto: $e');
    }
  }

  /// Envoie les feedbacks pending un par un. Marque sent ou failed.
  ///
  /// En production, remplacer _sendToBackend par un vrai appel API.
  Future<int> _sendPending() async {
    final pending = await _dao.getPending();
    var sentCount = 0;

    for (final feedback in pending) {
      try {
        final success = await _sendToBackend(feedback);
        if (success) {
          await _dao.markSent(feedback.id);
          sentCount++;
          _log.d('[FeedbackService] Feedback #${feedback.id} envoye');
        } else {
          await _dao.markFailed(feedback.id);
          _log.d('[FeedbackService] Feedback #${feedback.id} echoue');
        }
      } catch (e) {
        await _dao.markFailed(feedback.id);
        _log.d('[FeedbackService] Erreur envoi #${feedback.id}: $e');
      }
    }

    // Nettoyage des feedbacks envoyes
    if (sentCount > 0) {
      await _dao.clearSent();
      _log.d('[FeedbackService] $sentCount feedback(s) envoye(s) et nettoye(s)');
    }

    return sentCount;
  }

  /// Simulation d'envoi backend.
  ///
  /// A remplacer par un vrai appel HTTP/Firebase en production.
  Future<bool> _sendToBackend(FeedbackQueueData feedback) async {
    // Simule un delai reseau minimal
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return true;
  }
}
