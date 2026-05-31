// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pois_dao.dart';

// ignore_for_file: type=lint
mixin _$PoisDaoMixin on DatabaseAccessor<AppDatabase> {
  $PoisTable get pois => attachedDatabase.pois;
  PoisDaoManager get managers => PoisDaoManager(this);
}

class PoisDaoManager {
  final _$PoisDaoMixin _db;
  PoisDaoManager(this._db);
  $$PoisTableTableManager get pois =>
      $$PoisTableTableManager(_db.attachedDatabase, _db.pois);
}
