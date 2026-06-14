// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'waypoints_dao.dart';

// ignore_for_file: type=lint
mixin _$WaypointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $WaypointTable get waypoint => attachedDatabase.waypoint;
  $WaypointCommentTable get waypointComment => attachedDatabase.waypointComment;
  WaypointsDaoManager get managers => WaypointsDaoManager(this);
}

class WaypointsDaoManager {
  final _$WaypointsDaoMixin _db;
  WaypointsDaoManager(this._db);
  $$WaypointTableTableManager get waypoint =>
      $$WaypointTableTableManager(_db.attachedDatabase, _db.waypoint);
  $$WaypointCommentTableTableManager get waypointComment =>
      $$WaypointCommentTableTableManager(
        _db.attachedDatabase,
        _db.waypointComment,
      );
}
