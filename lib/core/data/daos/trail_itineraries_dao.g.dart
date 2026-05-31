// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_itineraries_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailItinerariesDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailItinerariesTable get trailItineraries =>
      attachedDatabase.trailItineraries;
  TrailItinerariesDaoManager get managers => TrailItinerariesDaoManager(this);
}

class TrailItinerariesDaoManager {
  final _$TrailItinerariesDaoMixin _db;
  TrailItinerariesDaoManager(this._db);
  $$TrailItinerariesTableTableManager get trailItineraries =>
      $$TrailItinerariesTableTableManager(
        _db.attachedDatabase,
        _db.trailItineraries,
      );
}
