// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trail_accommodations_dao.dart';

// ignore_for_file: type=lint
mixin _$TrailAccommodationsDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrailAccommodationsTable get trailAccommodations =>
      attachedDatabase.trailAccommodations;
  TrailAccommodationsDaoManager get managers =>
      TrailAccommodationsDaoManager(this);
}

class TrailAccommodationsDaoManager {
  final _$TrailAccommodationsDaoMixin _db;
  TrailAccommodationsDaoManager(this._db);
  $$TrailAccommodationsTableTableManager get trailAccommodations =>
      $$TrailAccommodationsTableTableManager(
          _db.attachedDatabase, _db.trailAccommodations);
}
