// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_gpx_points_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailGpxPointsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailGpxPointsTable get trailGpxPoints => attachedDatabase.trailGpxPoints;
  TrailGpxPointsDaoManager get managers => TrailGpxPointsDaoManager(this);
}

class TrailGpxPointsDaoManager {
  final _$TrailGpxPointsDaoMixin _db;
  TrailGpxPointsDaoManager(this._db);
  $$TrailGpxPointsTableTableManager get trailGpxPoints =>
      $$TrailGpxPointsTableTableManager(
          _db.attachedDatabase, _db.trailGpxPoints);
}
