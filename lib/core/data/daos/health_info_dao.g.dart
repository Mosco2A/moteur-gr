// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_info_dao.dart';

// ignore_for_file: type=lint
mixin _$HealthInfoDaoMixin on DatabaseAccessor<AppDatabase> {
  $HealthInfoEntriesTable get healthInfoEntries =>
      attachedDatabase.healthInfoEntries;
  HealthInfoDaoManager get managers => HealthInfoDaoManager(this);
}

class HealthInfoDaoManager {
  final _$HealthInfoDaoMixin _db;
  HealthInfoDaoManager(this._db);
  $$HealthInfoEntriesTableTableManager get healthInfoEntries =>
      $$HealthInfoEntriesTableTableManager(
        _db.attachedDatabase,
        _db.healthInfoEntries,
      );
}
