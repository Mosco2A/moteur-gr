// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hiker_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$HikerProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $HikerProfileTable get hikerProfile => attachedDatabase.hikerProfile;
  HikerProfileDaoManager get managers => HikerProfileDaoManager(this);
}

class HikerProfileDaoManager {
  final _$HikerProfileDaoMixin _db;
  HikerProfileDaoManager(this._db);
  $$HikerProfileTableTableManager get hikerProfile =>
      $$HikerProfileTableTableManager(_db.attachedDatabase, _db.hikerProfile);
}
