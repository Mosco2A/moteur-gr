// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nuitee_selections_dao.dart';

// ignore_for_file: type=lint
mixin _$NuiteeSelectionsDaoMixin on DatabaseAccessor<AppDatabase> {
  $NuiteeSelectionsTable get nuiteeSelections =>
      attachedDatabase.nuiteeSelections;
  NuiteeSelectionsDaoManager get managers => NuiteeSelectionsDaoManager(this);
}

class NuiteeSelectionsDaoManager {
  final _$NuiteeSelectionsDaoMixin _db;
  NuiteeSelectionsDaoManager(this._db);
  $$NuiteeSelectionsTableTableManager get nuiteeSelections =>
      $$NuiteeSelectionsTableTableManager(
        _db.attachedDatabase,
        _db.nuiteeSelections,
      );
}
