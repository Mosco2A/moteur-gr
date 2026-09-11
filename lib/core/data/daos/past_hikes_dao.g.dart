// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'past_hikes_dao.dart';

// ignore_for_file: type=lint
mixin _$PastHikesDaoMixin on DatabaseAccessor<AppDatabase> {
  $PastHikeEntriesTable get pastHikeEntries => attachedDatabase.pastHikeEntries;
  $HikerExperienceNoteTable get hikerExperienceNote =>
      attachedDatabase.hikerExperienceNote;
  PastHikesDaoManager get managers => PastHikesDaoManager(this);
}

class PastHikesDaoManager {
  final _$PastHikesDaoMixin _db;
  PastHikesDaoManager(this._db);
  $$PastHikeEntriesTableTableManager get pastHikeEntries =>
      $$PastHikeEntriesTableTableManager(
        _db.attachedDatabase,
        _db.pastHikeEntries,
      );
  $$HikerExperienceNoteTableTableManager get hikerExperienceNote =>
      $$HikerExperienceNoteTableTableManager(
        _db.attachedDatabase,
        _db.hikerExperienceNote,
      );
}
