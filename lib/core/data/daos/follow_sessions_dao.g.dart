// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$FollowSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FollowSessionsTable get followSessions => attachedDatabase.followSessions;
  FollowSessionsDaoManager get managers => FollowSessionsDaoManager(this);
}

class FollowSessionsDaoManager {
  final _$FollowSessionsDaoMixin _db;
  FollowSessionsDaoManager(this._db);
  $$FollowSessionsTableTableManager get followSessions =>
      $$FollowSessionsTableTableManager(
        _db.attachedDatabase,
        _db.followSessions,
      );
}
