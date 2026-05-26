import 'package:freezed_annotation/freezed_annotation.dart';

part 'delta_update.freezed.dart';
part 'delta_update.g.dart';

/// Modele de mise a jour delta pour un sentier.
///
/// Represente un delta entre deux versions de donnees sentier.
/// Seules les tables modifiees sont listees dans changedTables,
/// permettant une MAJ partielle sans re-telecharger l integralite.
@freezed
class DeltaUpdate with _ {
  const factory DeltaUpdate({
    /// Identifiant du sentier concerne
    required String trailId,

    /// Version locale actuelle (point de depart du delta)
    required int fromVersion,

    /// Version cible apres application du delta
    required int toVersion,

    /// Liste des tables modifiees entre les deux versions
    required List<String> changedTables,

    /// Taille du delta en octets (pour affichage/estimation)
    required int downloadSize,
  }) = _DeltaUpdate;

  /// Deserialisation depuis JSON
  factory DeltaUpdate.fromJson(Map<String, dynamic> json) =>
      _(json);
}
