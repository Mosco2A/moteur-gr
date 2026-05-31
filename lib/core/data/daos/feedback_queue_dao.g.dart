// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'feedback_queue_dao.dart';

// ignore_for_file: type=lint
mixin _$FeedbackQueueDaoMixin on DatabaseAccessor<AppDatabase> {
  $FeedbackQueueTable get feedbackQueue => attachedDatabase.feedbackQueue;
  FeedbackQueueDaoManager get managers => FeedbackQueueDaoManager(this);
}

class FeedbackQueueDaoManager {
  final _$FeedbackQueueDaoMixin _db;
  FeedbackQueueDaoManager(this._db);
  $$FeedbackQueueTableTableManager get feedbackQueue =>
      $$FeedbackQueueTableTableManager(_db.attachedDatabase, _db.feedbackQueue);
}
