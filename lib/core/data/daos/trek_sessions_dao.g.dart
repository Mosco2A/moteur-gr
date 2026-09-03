// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trek_sessions_dao.dart';

// ignore_for_file: type=lint
mixin _$TrekSessionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrekSessionsTable get trekSessions => attachedDatabase.trekSessions;
  TrekSessionsDaoManager get managers => TrekSessionsDaoManager(this);
}

class TrekSessionsDaoManager {
  final _$TrekSessionsDaoMixin _db;
  TrekSessionsDaoManager(this._db);
  $$TrekSessionsTableTableManager get trekSessions =>
      $$TrekSessionsTableTableManager(_db.attachedDatabase, _db.trekSessions);
}
