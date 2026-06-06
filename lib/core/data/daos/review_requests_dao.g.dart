// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_requests_dao.dart';

// ignore_for_file: type=lint
mixin _$ReviewRequestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $ReviewRequestsTable get reviewRequests => attachedDatabase.reviewRequests;
  ReviewRequestsDaoManager get managers => ReviewRequestsDaoManager(this);
}

class ReviewRequestsDaoManager {
  final _$ReviewRequestsDaoMixin _db;
  ReviewRequestsDaoManager(this._db);
  $$ReviewRequestsTableTableManager get reviewRequests =>
      $$ReviewRequestsTableTableManager(
        _db.attachedDatabase,
        _db.reviewRequests,
      );
}
