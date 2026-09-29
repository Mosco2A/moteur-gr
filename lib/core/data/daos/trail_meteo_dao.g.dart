// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_meteo_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailMeteoDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailMeteoTable get trailMeteo => attachedDatabase.trailMeteo;
  TrailMeteoDaoManager get managers => TrailMeteoDaoManager(this);
}

class TrailMeteoDaoManager {
  final _$TrailMeteoDaoMixin _db;
  TrailMeteoDaoManager(this._db);
  $$TrailMeteoTableTableManager get trailMeteo =>
      $$TrailMeteoTableTableManager(_db.attachedDatabase, _db.trailMeteo);
}
