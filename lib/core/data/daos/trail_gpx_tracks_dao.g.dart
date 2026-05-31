// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_gpx_tracks_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailGpxTracksDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailGpxTracksTable get trailGpxTracks => attachedDatabase.trailGpxTracks;
  TrailGpxTracksDaoManager get managers => TrailGpxTracksDaoManager(this);
}

class TrailGpxTracksDaoManager {
  final _$TrailGpxTracksDaoMixin _db;
  TrailGpxTracksDaoManager(this._db);
  $$TrailGpxTracksTableTableManager get trailGpxTracks =>
      $$TrailGpxTracksTableTableManager(
          _db.attachedDatabase, _db.trailGpxTracks);
}
