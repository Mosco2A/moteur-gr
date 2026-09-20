import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/journal_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/engine/trail_engine.dart';
import '../../trail/providers/stages_provider.dart';
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

  /// Ajoute une entree de journal AVEC une photo (R10, LOT L10).
  ///
  /// [sourcePath] est le fichier choisi par l'utilisateur (appareil photo ou
  /// galerie). Il est compresse et recopie dans le stockage local du journal par
  /// [PhotoService] (<= 500 Ko, 3 photos/jour), PUIS seulement l'entree est
  /// inseree : jamais de ligne en base pointant vers un fichier absent.
  /// [content] peut etre vide (photo seule).
  ///
  /// Retourne `null` en cas de succes, sinon le [PhotoError] a presenter a
  /// l'utilisateur (quota du jour atteint, photo trop lourde, fichier
  /// introuvable, erreur disque).
  Future<PhotoError?> addPhotoNote({
    required int stageNumber,
    required String content,
    required String sourcePath,
  }) async {
    final saved = await _photoService.savePhotoFromFile(
      trailId: _trailId,
      sourcePath: sourcePath,
    );
    if (!saved.isSuccess) return saved.error ?? PhotoError.ioError;

    await _repo.addPhotoNote(
      trailId: _trailId,
      stageNumber: stageNumber,
      text: content,
      photoPath: saved.path!,
      photoSizeBytes: saved.sizeBytes ?? 0,
    );
    await _loadEntries();
    return null;
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

/// Nombre d'etapes REELLES du sentier, pour le selecteur d'etape du journal
/// (R10, LOT L10).
///
/// Remplace le `16` EN DUR du menu deroulant « Etape » : 16 est le compte du
/// GR20, alors que les sentiers StepWays en ont 7, 12 ou 5. Sur un sentier a
/// 7 etapes, l'utilisateur pouvait rattacher une note aux etapes 8 a 16, qui
/// n'existent pas — le moteur cessait d'etre generique.
///
/// Source de verite : les etapes reellement chargees du sentier
/// ([stagesProvider]). Repli sur `TrailConfig.totalStages` tant que la base n'a
/// pas repondu (ou si aucune etape n'est seedee), et PLANCHER A 1 pour ne
/// jamais rendre un menu deroulant vide (un `DropdownButtonFormField` sans item
/// mais avec une valeur initiale leve une assertion Flutter).
final journalStageCountProvider = Provider.family<int, String>((ref, trailId) {
  final loaded = ref.watch(stagesProvider(trailId)).maybeWhen(
        data: (stages) => stages.length,
        orElse: () => 0,
      );
  if (loaded > 0) return loaded;
  final declared = ref.watch(trailConfigProvider.select((c) => c.totalStages));
  return declared > 0 ? declared : 1;
});
