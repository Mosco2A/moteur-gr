import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/journal_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';

/// Provider du DAO journal
final journalDaoProvider = Provider<JournalDao>((ref) {
  return JournalDao(ref.watch(databaseProvider));
});

/// État du journal pour un sentier
class JournalState {
  const JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.canAddPhoto = true,
    this.photosToday = 0,
  });

  final List<JournalEntry> entries;
  final bool isLoading;
  final bool canAddPhoto;
  final int photosToday;

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    bool? canAddPhoto,
    int? photosToday,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      canAddPhoto: canAddPhoto ?? this.canAddPhoto,
      photosToday: photosToday ?? this.photosToday,
    );
  }
}

/// Notifier pour gérer le journal de trek
class JournalNotifier extends StateNotifier<JournalState> {
  JournalNotifier(this._dao, this._trailId)
      : super(const JournalState(isLoading: true)) {
    _loadEntries();
  }

  final JournalDao _dao;
  final String _trailId;

  /// Charge les entrées depuis la base
  Future<void> _loadEntries() async {
    final entries = await _dao.getByTrailId(_trailId);
    final photosToday = await _dao.countPhotosToday(_trailId);
    final canAdd = photosToday < JournalDao.maxPhotosPerDay;
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      canAddPhoto: canAdd,
      photosToday: photosToday,
    );
  }

  /// Ajoute une note textuelle au journal
  Future<void> addNote({
    required int stageNumber,
    required String content,
  }) async {
    final now = DateTime.now();
    await _dao.insertEntry(JournalEntriesCompanion(
      trailId: Value(_trailId),
      stageNumber: Value(stageNumber),
      content: Value(content),
      createdAt: Value(now),
    ));
    await _loadEntries();
  }

  /// Ajoute une photo au journal (vérifie la limite quotidienne)
  Future<bool> addPhoto({
    required int stageNumber,
    required String photoPath,
    required int photoSizeBytes,
    String content = '',
  }) async {
    // Vérifier la limite de taille (500 Ko)
    if (photoSizeBytes > JournalDao.maxPhotoSizeBytes) {
      return false;
    }

    // Vérifier la limite quotidienne (3 photos/jour)
    final canAdd = await _dao.canAddPhoto(_trailId);
    if (!canAdd) {
      return false;
    }

    final now = DateTime.now();
    await _dao.insertEntry(JournalEntriesCompanion(
      trailId: Value(_trailId),
      stageNumber: Value(stageNumber),
      content: Value(content),
      photoPath: Value(photoPath),
      photoSizeBytes: Value(photoSizeBytes),
      createdAt: Value(now),
    ));
    await _loadEntries();
    return true;
  }

  /// Met à jour le texte d'une entrée
  Future<void> updateNote(int entryId, String content) async {
    await _dao.updateEntry(
      JournalEntriesCompanion(
        content: Value(content),
        updatedAt: Value(DateTime.now()),
      ),
      entryId,
    );
    await _loadEntries();
  }

  /// Supprime une entrée
  Future<void> deleteEntry(int entryId) async {
    await _dao.deleteEntry(entryId);
    await _loadEntries();
  }

  /// Récupère les entrées d'une étape spécifique
  Future<List<JournalEntry>> getStageEntries(int stageNumber) async {
    return _dao.getByStage(_trailId, stageNumber);
  }
}

/// Provider du journal pour le sentier actif
final journalProvider =
    StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final dao = ref.watch(journalDaoProvider);
  final trailId = ref.watch(trailIdProvider);
  return JournalNotifier(dao, trailId);
});
