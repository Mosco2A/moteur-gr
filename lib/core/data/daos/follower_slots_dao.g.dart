// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower_slots_dao.dart';

// ignore_for_file: type=lint
mixin _$FollowerSlotsDaoMixin on DatabaseAccessor<AppDatabase> {
  $FollowerSlotsTable get followerSlots => attachedDatabase.followerSlots;
  FollowerSlotsDaoManager get managers => FollowerSlotsDaoManager(this);
}

class FollowerSlotsDaoManager {
  final _$FollowerSlotsDaoMixin _db;
  FollowerSlotsDaoManager(this._db);
  $$FollowerSlotsTableTableManager get followerSlots =>
      $$FollowerSlotsTableTableManager(_db.attachedDatabase, _db.followerSlots);
}
