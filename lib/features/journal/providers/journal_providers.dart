import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/journal_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/engine/trail_engine.dart';
import '../data/journal_repository.dart';
import '../data/photo_service.dart';
import '../domain/models/journal_entry.dart';

// ---------------------------------------------------------------------------
// Providers Riverpod 3 pour le journal de trek (E3.1c)
//
// Convention : select() partout, zero ref.watch brut dans build.
// Tout texte UI passe par Slang (t.journal.*).
// ---------------------------------------------------------------------------

/// Provider du DAO journal — couche basse Drift.
final journalDaoProvider = Provider<JournalDao>((ref) {
  return JournalDao(ref.watch(databaseProvider));
});

/// Provider du repository journal — couche domaine.
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final dao = ref.watch(journalDaoProvider);
  return JournalRepository(dao);
});

/// Provider du PhotoService — gestion photos offline.
final photoServiceProvider = Provider<PhotoService>((ref) {
  final dao = ref.watch(journalDaoProvider);
  return PhotoService(journalDao: dao);
});

/// Etat du journal pour un sentier donne.
///
/// Contient les entrees groupees par jour, l'indicateur de chargement,
/// et les compteurs photo (limite quotidienne 3/jour).
class JournalScreenState {
  const JournalScreenState({
    this.entries = const [],
    this.isLoading = false,
    this.canAddPhoto = true,
    this.photosToday = 0,
  });

  /// Toutes les entrees du journal, triees par date descendante.
  final List<JournalEntryModel> entries;

  /// Vrai pendant le chargement initial depuis la base.
  final bool isLoading;

  /// Vrai si on peut encore ajouter une photo aujourd'hui (max 3).
  final bool canAddPhoto;

  /// Nombre de photos ajoutees aujourd'hui.
  final int photosToday;

  JournalScreenState copyWith({
    List<JournalEntryModel>? entries,
    bool? isLoading,
    bool? canAddPhoto,
    int? photosToday,
  }) {
    return JournalScreenState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      canAddPhoto: canAddPhoto ?? this.canAddPhoto,
      photosToday: photosToday ?? this.photosToday,
    );
  }

  /// Entrees regroupees par cle de date (format ISO yyyy-MM-dd).
  ///
  /// Utilise pour l'affichage par jour dans journal_screen.
  Map<String, List<JournalEntryModel>> get entriesByDay {
    final grouped = <String, List<JournalEntryModel>>{};
    for (final entry in entries) {
      final key = _dayKey(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  /// Cle de regroupement : yyyy-MM-dd.
  static String _dayKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// Notifier Riverpod 3 pour le journal de trek.
///
/// Charge les entrees depuis le repository, gere les CRUD notes/photos,
/// et maintient le compteur de quota photos quotidien.
class JournalScreenNotifier extends Notifier<JournalScreenState> {
  late JournalRepository _repo;
  late PhotoService _photoService;
  late String _trailId;

  @override
  JournalScreenState build() {
    _repo = ref.read(journalRepositoryProvider);
    _photoService = ref.read(photoServiceProvider);
    _trailId = ref.read(trailIdProvider);
    _loadEntries();
    return const JournalScreenState(isLoading: true);
  }

  /// Charge les entrees du sentier actif depuis la base.
  Future<void> _loadEntries() async {
    final entries = await _repo.getByTrailId(_trailId);
    final photosToday = await _photoService.photosToday(_trailId);
    final canAdd = photosToday < PhotoService.maxPhotosPerDay;
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      canAddPhoto: canAdd,
      photosToday: photosToday,
    );
  }

  /// Ajoute une note textuelle au journal.
  Future<void> addNote({
    required int stageNumber,
    required String content,
  }) async {
    await _repo.addNote(
      trailId: _trailId,
      stageNumber: stageNumber,
      text: content,
    );
    await _loadEntries();
  }

  /// Met a jour le texte d'une entree existante.
  Future<void> updateNote(int entryId, String content) async {
    await _repo.updateNote(entryId, content);
    await _loadEntries();
  }

  /// Supprime une entree par son identifiant.
  Future<void> deleteEntry(int entryId) async {
    await _repo.deleteEntry(entryId);
    await _loadEntries();
  }

  /// Verifie si on peut encore ajouter une photo aujourd'hui.
  Future<bool> canAddPhotoToday() async {
    return _photoService.canAddPhoto(_trailId);
  }

  /// Force le rechargement complet des entrees.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadEntries();
  }
}

/// Provider principal du journal ecran — pilote JournalScreen.
///
/// Usage dans le build du widget :
/// ```dart
/// final isLoading = ref.watch(
///   journalScreenProvider.select((s) => s.isLoading),
/// );
/// ```
final journalScreenProvider =
    NotifierProvider<JournalScreenNotifier, JournalScreenState>(
  JournalScreenNotifier.new,
);
