// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trek_entitlements_dao.dart';

// ignore_for_file: type=lint
mixin _$TrekEntitlementsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrekEntitlementsTable get trekEntitlements =>
      attachedDatabase.trekEntitlements;
  TrekEntitlementsDaoManager get managers => TrekEntitlementsDaoManager(this);
}

class TrekEntitlementsDaoManager {
  final _$TrekEntitlementsDaoMixin _db;
  TrekEntitlementsDaoManager(this._db);
  $$TrekEntitlementsTableTableManager get trekEntitlements =>
      $$TrekEntitlementsTableTableManager(
        _db.attachedDatabase,
        _db.trekEntitlements,
      );
}
