// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_stages_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailStagesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailStagesTable get trailStages => attachedDatabase.trailStages;
  TrailStagesDaoManager get managers => TrailStagesDaoManager(this);
}

class TrailStagesDaoManager {
  final _$TrailStagesDaoMixin _db;
  TrailStagesDaoManager(this._db);
  $$TrailStagesTableTableManager get trailStages =>
      $$TrailStagesTableTableManager(_db.attachedDatabase, _db.trailStages);
}
