// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_manifests_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailManifestsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailManifestsTable get trailManifests => attachedDatabase.trailManifests;
  TrailManifestsDaoManager get managers => TrailManifestsDaoManager(this);
}

class TrailManifestsDaoManager {
  final _$TrailManifestsDaoMixin _db;
  TrailManifestsDaoManager(this._db);
  $$TrailManifestsTableTableManager get trailManifests =>
      $$TrailManifestsTableTableManager(
        _db.attachedDatabase,
        _db.trailManifests,
      );
}
