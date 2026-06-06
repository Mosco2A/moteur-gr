// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_track_points_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionTrackPointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SessionTrackPointsTable get sessionTrackPoints =>
      attachedDatabase.sessionTrackPoints;
  SessionTrackPointsDaoManager get managers =>
      SessionTrackPointsDaoManager(this);
}

class SessionTrackPointsDaoManager {
  final _$SessionTrackPointsDaoMixin _db;
  SessionTrackPointsDaoManager(this._db);
  $$SessionTrackPointsTableTableManager get sessionTrackPoints =>
      $$SessionTrackPointsTableTableManager(
        _db.attachedDatabase,
        _db.sessionTrackPoints,
      );
}
