import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';

/// Provider singleton pour la base de donnees Drift.
///
/// Cree une seule instance d'AppDatabase pour toute l'app.
/// En mode test, overrider ce provider avec une DB in-memory.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(NativeDatabase.memory());
  ref.onDispose(() => db.close());
  return db;
});
