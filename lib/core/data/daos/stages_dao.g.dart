// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stages_dao.dart';

// ignore_for_file: type=lint
mixin _$StagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $StagesTable get stages => attachedDatabase.stages;
  StagesDaoManager get managers => StagesDaoManager(this);
}

class StagesDaoManager {
  final _$StagesDaoMixin _db;
  StagesDaoManager(this._db);
  $$StagesTableTableManager get stages =>
      $$StagesTableTableManager(_db.attachedDatabase, _db.stages);
}
