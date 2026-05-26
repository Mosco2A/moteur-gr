import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/feedback_queue_dao.dart';

/// Tests du DAO feedback queue.
void main() {
  late AppDatabase db;
  late FeedbackQueueDao dao;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = FeedbackQueueDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  FeedbackQueueCompanion makeFeedback({
    String trailId = 'gr20',
    String type = 'suggestion',
    String content = 'Super app !',
    int? rating,
    String status = 'pending',
  }) {
    return FeedbackQueueCompanion(
      trailId: Value(trailId),
      feedbackType: Value(type),
      content: Value(content),
      rating: Value(rating),
      status: Value(status),
      createdAt: Value(DateTime.now()),
    );
  }

  group('FeedbackQueueDao', () {
    test('addFeedback insère un feedback', () async {
      final id = await dao.addFeedback(makeFeedback());
      expect(id, greaterThan(0));
    });

    test('getPending retourne les feedbacks en attente', () async {
      await dao.addFeedback(makeFeedback());
      await dao.addFeedback(makeFeedback(content: 'Deuxième'));

      final pending = await dao.getPending();
      expect(pending.length, 2);
    });

    test('markSent marque un feedback comme envoyé', () async {
      final id = await dao.addFeedback(makeFeedback());
      await dao.markSent(id);

      final pending = await dao.getPending();
      expect(pending, isEmpty);
    });

    test('markFailed marque un feedback comme échoué', () async {
      final id = await dao.addFeedback(makeFeedback());
      await dao.markFailed(id);

      final pending = await dao.getPending();
      expect(pending, isEmpty);
    });

    test('getByTrailId filtre par sentier', () async {
      await dao.addFeedback(makeFeedback(trailId: 'gr20'));
      await dao.addFeedback(makeFeedback(trailId: 'tmb'));
      await dao.addFeedback(makeFeedback(trailId: 'gr20'));

      final gr20 = await dao.getByTrailId('gr20');
      expect(gr20.length, 2);

      final tmb = await dao.getByTrailId('tmb');
      expect(tmb.length, 1);
    });

    test('countPending retourne le bon nombre', () async {
      await dao.addFeedback(makeFeedback());
      await dao.addFeedback(makeFeedback());
      final id = await dao.addFeedback(makeFeedback());
      await dao.markSent(id);

      final count = await dao.countPending();
      expect(count, 2);
    });

    test('clearSent supprime les feedbacks envoyés', () async {
      final id1 = await dao.addFeedback(makeFeedback());
      await dao.addFeedback(makeFeedback());
      await dao.markSent(id1);

      final cleared = await dao.clearSent();
      expect(cleared, 1);

      final pending = await dao.getPending();
      expect(pending.length, 1);
    });
  });
}
