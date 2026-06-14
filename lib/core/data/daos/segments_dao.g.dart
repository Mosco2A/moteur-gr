// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'segments_dao.dart';

// ignore_for_file: type=lint
mixin _$SegmentsDaoMixin on DatabaseAccessor<AppDatabase> {
  $SegmentsTable get segments => attachedDatabase.segments;
  $SegmentEffortLocalTable get segmentEffortLocal =>
      attachedDatabase.segmentEffortLocal;
  SegmentsDaoManager get managers => SegmentsDaoManager(this);
}

class SegmentsDaoManager {
  final _$SegmentsDaoMixin _db;
  SegmentsDaoManager(this._db);
  $$SegmentsTableTableManager get segments =>
      $$SegmentsTableTableManager(_db.attachedDatabase, _db.segments);
  $$SegmentEffortLocalTableTableManager get segmentEffortLocal =>
      $$SegmentEffortLocalTableTableManager(
        _db.attachedDatabase,
        _db.segmentEffortLocal,
      );
}
