// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kudos_feed_dao.dart';

// ignore_for_file: type=lint
mixin _$KudosFeedDaoMixin on DatabaseAccessor<AppDatabase> {
  $KudosLocalTable get kudosLocal => attachedDatabase.kudosLocal;
  $ActivityFeedCacheTable get activityFeedCache =>
      attachedDatabase.activityFeedCache;
  KudosFeedDaoManager get managers => KudosFeedDaoManager(this);
}

class KudosFeedDaoManager {
  final _$KudosFeedDaoMixin _db;
  KudosFeedDaoManager(this._db);
  $$KudosLocalTableTableManager get kudosLocal =>
      $$KudosLocalTableTableManager(_db.attachedDatabase, _db.kudosLocal);
  $$ActivityFeedCacheTableTableManager get activityFeedCache =>
      $$ActivityFeedCacheTableTableManager(
        _db.attachedDatabase,
        _db.activityFeedCache,
      );
}
