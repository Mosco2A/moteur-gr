// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_meta_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailMetaDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailMetaTable get trailMeta => attachedDatabase.trailMeta;
  TrailMetaDaoManager get managers => TrailMetaDaoManager(this);
}

class TrailMetaDaoManager {
  final _$TrailMetaDaoMixin _db;
  TrailMetaDaoManager(this._db);
  $$TrailMetaTableTableManager get trailMeta =>
      $$TrailMetaTableTableManager(_db.attachedDatabase, _db.trailMeta);
}
