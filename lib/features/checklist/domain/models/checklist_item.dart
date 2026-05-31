import 'package:freezed_annotation/freezed_annotation.dart';

part 'checklist_item.freezed.dart';
part 'checklist_item.g.dart';

/// Modele immutable representant un item de checklist materiel.
///
/// Combine les donnees du template (nom, categorie) et l'etat
/// utilisateur (coche, note personnelle) pour un sentier donne.
/// Persiste en Drift via ChecklistRepository.
@freezed
abstract class ChecklistItemModel with _$ChecklistItemModel {
  const ChecklistItemModel._();

  const factory ChecklistItemModel({
    /// Cle primaire DB (0 si pas encore insere)
    @Default(0) int id,

    /// Identifiant du template source (ex: 'backpack')
    required String templateId,

    /// Nom de l'item (cle i18n pour resolution via Slang)
    required String name,

    /// Categorie (ex: 'equipment', 'clothing', 'food', 'safety', 'documents', 'hygiene')
    required String category,

    /// Item coche ou non par l'utilisateur
    @Default(false) bool isChecked,

    /// Note personnelle optionnelle de l'utilisateur
    String? customNote,
  }) = _ChecklistItemModel;

  /// Deserialisation depuis JSON
  factory ChecklistItemModel.fromJson(Map<String, dynamic> json) =>
      _$ChecklistItemModelFromJson(json);
}
