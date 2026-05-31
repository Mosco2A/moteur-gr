import 'package:drift/drift.dart' show Value;
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/data/database.dart';

part 'journal_entry.freezed.dart';
part 'journal_entry.g.dart';

/// Modele immutable representant une entree du journal de trek.
///
/// Mappe les champs de la table JournalEntries (Drift).
/// Utilise Freezed v3 pour l'immutabilite et la serialisation JSON.
@freezed
abstract class JournalEntryModel with _$JournalEntryModel {
  const JournalEntryModel._();

  const factory JournalEntryModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du sentier parent (ex: 'gr20')
    required String trailId,

    /// Numero de l'etape associee (1-indexed)
    required int stageNumber,

    /// Contenu textuel de la note
    @Default('') String text,

    /// Chemin local de la photo (null si note sans photo)
    String? photoPath,

    /// Taille de la photo en octets (null si pas de photo)
    int? photoSizeBytes,

    /// Date de creation de l'entree
    required DateTime createdAt,

    /// Date de derniere modification (null si jamais modifiee)
    DateTime? updatedAt,
  }) = _JournalEntryModel;

  /// Construit depuis une ligne Drift (table JournalEntries)
  factory JournalEntryModel.fromDb(JournalEntry row) {
    return JournalEntryModel(
      id: row.id,
      trailId: row.trailId,
      stageNumber: row.stageNumber,
      text: row.content,
      photoPath: row.photoPath,
      photoSizeBytes: row.photoSizeBytes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Convertit vers un companion Drift pour insertion/mise a jour
  JournalEntriesCompanion toCompanion() {
    return JournalEntriesCompanion(
      trailId: Value(trailId),
      stageNumber: Value(stageNumber),
      content: Value(text),
      photoPath: Value(photoPath),
      photoSizeBytes: Value(photoSizeBytes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  /// Deserialisation depuis JSON
  factory JournalEntryModel.fromJson(Map<String, dynamic> json) =>
      _$JournalEntryModelFromJson(json);
}
