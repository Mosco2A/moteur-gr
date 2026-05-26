import 'package:drift/drift.dart';

import '../database.dart';
import '../tables/feedback_queue_table.dart';

part 'feedback_queue_dao.g.dart';

/// DAO pour la file d'attente de feedback offline.
///
/// Gère le stockage local des feedbacks utilisateur
/// et leur envoi différé quand la connexion est rétablie.
@DriftAccessor(tables: [FeedbackQueue])
class FeedbackQueueDao extends DatabaseAccessor<AppDatabase>
    with _$FeedbackQueueDaoMixin {
  FeedbackQueueDao(super.db);

  /// Insère un nouveau feedback dans la file d'attente
  Future<int> addFeedback(FeedbackQueueCompanion entry) {
    return into(feedbackQueue).insert(entry);
  }

  /// Récupère tous les feedbacks en attente d'envoi
  Future<List<FeedbackQueueData>> getPending() {
    return (select(feedbackQueue)
          ..where((t) => t.status.equals('pending'))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  /// Marque un feedback comme envoyé
  Future<int> markSent(int feedbackId) {
    return (update(feedbackQueue)
          ..where((t) => t.id.equals(feedbackId)))
        .write(FeedbackQueueCompanion(
      status: const Value('sent'),
      sentAt: Value(DateTime.now()),
    ));
  }

  /// Marque un feedback comme échoué
  Future<int> markFailed(int feedbackId) {
    return (update(feedbackQueue)
          ..where((t) => t.id.equals(feedbackId)))
        .write(const FeedbackQueueCompanion(
      status: Value('failed'),
    ));
  }

  /// Récupère tous les feedbacks d'un sentier
  Future<List<FeedbackQueueData>> getByTrailId(String trailId) {
    return (select(feedbackQueue)
          ..where((t) => t.trailId.equals(trailId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Compte les feedbacks en attente
  Future<int> countPending() async {
    final pending = await getPending();
    return pending.length;
  }

  /// Supprime les feedbacks envoyés (nettoyage)
  Future<int> clearSent() {
    return (delete(feedbackQueue)
          ..where((t) => t.status.equals('sent')))
        .go();
  }
}
