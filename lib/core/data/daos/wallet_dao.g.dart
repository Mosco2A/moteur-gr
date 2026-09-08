// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wallet_dao.dart';

// ignore_for_file: type=lint
mixin _$WalletDaoMixin on DatabaseAccessor<AppDatabase> {
  $WalletBalanceTable get walletBalance => attachedDatabase.walletBalance;
  WalletDaoManager get managers => WalletDaoManager(this);
}

class WalletDaoManager {
  final _$WalletDaoMixin _db;
  WalletDaoManager(this._db);
  $$WalletBalanceTableTableManager get walletBalance =>
      $$WalletBalanceTableTableManager(_db.attachedDatabase, _db.walletBalance);
}
