// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_ads_dao.dart';

// ignore_for_file: type=lint
mixin _$NoAdsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NoAdsStateTable get noAdsState => attachedDatabase.noAdsState;
  NoAdsDaoManager get managers => NoAdsDaoManager(this);
}

class NoAdsDaoManager {
  final _$NoAdsDaoMixin _db;
  NoAdsDaoManager(this._db);
  $$NoAdsStateTableTableManager get noAdsState =>
      $$NoAdsStateTableTableManager(_db.attachedDatabase, _db.noAdsState);
}
