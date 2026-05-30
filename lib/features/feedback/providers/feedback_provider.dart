import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/feedback_queue_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';

/// Provider du DAO feedback
final feedbackQueueDaoProvider = Provider<FeedbackQueueDao>((ref) {
  return FeedbackQueueDao(ref.watch(databaseProvider));
});

/// Types de feedback disponibles.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef FeedbackType = String;

/// Valeurs connues pour FeedbackType avec fallback generique.
abstract class FeedbackTypeValues {
  static const String bug = 'bug';
  static const String suggestion = 'suggestion';
  static const String question = 'question';
  static const String other = 'other';
  static const String fallback = other;
  static const List<String> values = [bug, suggestion, question, other];

  static const Map<String, String> labels = {
    bug: 'Bug / Probleme',
    suggestion: 'Suggestion',
    question: 'Question',
    other: 'Autre',
  };

  static String labelFor(String type) => labels[type] ?? type;
  static FeedbackType fromString(String value) =>
      values.contains(value) ? value : fallback;
}

/// Etat du formulaire de feedback
class FeedbackState {
  const FeedbackState({
    this.pendingCount = 0,
    this.isSubmitting = false,
    this.lastSubmitSuccess,
  });

  final int pendingCount;
  final bool isSubmitting;
  final bool? lastSubmitSuccess;

  FeedbackState copyWith({
    int? pendingCount,
    bool? isSubmitting,
    bool? lastSubmitSuccess,
  }) {
    return FeedbackState(
      pendingCount: pendingCount ?? this.pendingCount,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      lastSubmitSuccess: lastSubmitSuccess,
    );
  }
}

/// Notifier pour gerer les feedbacks avec file d'attente offline
class FeedbackNotifier extends Notifier<FeedbackState> {
  late FeedbackQueueDao _dao;
  late String _trailId;
  late ConnectivityStatus _connectivity;

  @override
  FeedbackState build() {
    _dao = ref.watch(feedbackQueueDaoProvider);
    _trailId = ref.watch(trailIdProvider);
    _connectivity =
        ref.watch(connectivityProvider).valueOrNull ?? ConnectivityStatusValues.offline;
    _loadPendingCount();
    return const FeedbackState();
  }

  Future<void> _loadPendingCount() async {
    final count = await _dao.countPending();
    state = state.copyWith(pendingCount: count);
  }

  /// Soumet un feedback (stocke localement, envoye quand en ligne)
  Future<bool> submitFeedback({
    required FeedbackType type,
    required String content,
    int? rating,
  }) async {
    state = state.copyWith(isSubmitting: true);

    try {
      await _dao.addFeedback(FeedbackQueueCompanion(
        trailId: Value(_trailId),
        feedbackType: Value(type),
        content: Value(content),
        rating: Value(rating),
        createdAt: Value(DateTime.now()),
      ));

      // Tenter l'envoi immediat si en ligne
      if (_connectivity == ConnectivityStatusValues.online) {
        await _trySendPending();
      }

      await _loadPendingCount();
      state = state.copyWith(isSubmitting: false, lastSubmitSuccess: true);
      return true;
    } catch (_) {
      state = state.copyWith(isSubmitting: false, lastSubmitSuccess: false);
      return false;
    }
  }

  /// Tente d'envoyer les feedbacks en attente
  Future<void> _trySendPending() async {
    final pending = await _dao.getPending();
    for (final feedback in pending) {
      // Simulation d'envoi (pas de backend Firebase)
      // En production, appeler l'API ici
      await _dao.markSent(feedback.id);
    }
  }

  /// Force le renvoi des feedbacks en attente
  Future<void> retrySendPending() async {
    if (_connectivity == ConnectivityStatusValues.online) {
      await _trySendPending();
      await _loadPendingCount();
    }
  }
}

/// Provider du feedback pour le sentier actif
final feedbackProvider =
    NotifierProvider<FeedbackNotifier, FeedbackState>(FeedbackNotifier.new);
