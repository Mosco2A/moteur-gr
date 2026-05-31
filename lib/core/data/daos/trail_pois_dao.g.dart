// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_pois_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailPoisDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailPoisTable get trailPois => attachedDatabase.trailPois;
  TrailPoisDaoManager get managers => TrailPoisDaoManager(this);
}

class TrailPoisDaoManager {
  final _$TrailPoisDaoMixin _db;
  TrailPoisDaoManager(this._db);
  $$TrailPoisTableTableManager get trailPois =>
      $$TrailPoisTableTableManager(_db.attachedDatabase, _db.trailPois);
}
