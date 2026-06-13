import 'package:freezed_annotation/freezed_annotation.dart';

part 'programme_entrainement.freezed.dart';
part 'programme_entrainement.g.dart';

/// Type de seance d'entrainement pre-trek (F6E-01).
enum TypeSeance {
  @JsonValue('marche')
  marche,
  @JsonValue('cardio')
  cardio,
  @JsonValue('renforcement')
  renforcement,
}

/// Intensite d'une seance (F6E-01).
enum IntensiteSeance {
  @JsonValue('faible')
  faible,
  @JsonValue('moderee')
  moderee,
  @JsonValue('elevee')
  elevee,
}

/// Une seance d'entrainement planifiee (F6E-01).
@freezed
abstract class SeanceEntrainement with _$SeanceEntrainement {
  const SeanceEntrainement._();

  const factory SeanceEntrainement({
    /// Decalage en jours depuis le debut du programme (0 = jour 1).
    required int jourOffset,

    /// Type de seance (marche, cardio, renforcement).
    required TypeSeance type,

    /// Duree de la seance en minutes.
    required int dureeMin,

    /// Intensite de la seance.
    required IntensiteSeance intensite,

    /// Description / consigne de la seance.
    required String description,
  }) = _SeanceEntrainement;

  factory SeanceEntrainement.fromJson(Map<String, dynamic> json) =>
      _$SeanceEntrainementFromJson(json);
}

/// Programme d'entrainement pre-trek (F6.5, Phase 6).
///
/// Plan J-N (semaines avant le depart) compose de seances rando / cardio /
/// renforcement, base sur des bonnes pratiques d'entrainement trek
/// (progressivite, sorties longues croissantes, renforcement jambes/gainage,
/// cadrage #85929 BP PureGym). GENERIQUE : parametre par la date de depart et
/// le niveau declare. AUCUNE donnee de sante personnelle stockee cote serveur
/// (minimisation RGPD : le plan est calcule/affiche LOCALEMENT).
@freezed
abstract class ProgrammeEntrainement with _$ProgrammeEntrainement {
  const ProgrammeEntrainement._();

  const factory ProgrammeEntrainement({
    /// Identifiant du programme.
    required String id,

    /// Duree totale du programme en semaines.
    required int dureeSemaines,

    /// Seances planifiees, ordonnees par jourOffset croissant.
    required List<SeanceEntrainement> seances,
  }) = _ProgrammeEntrainement;

  /// Nombre total de seances.
  int get nbSeances => seances.length;

  factory ProgrammeEntrainement.fromJson(Map<String, dynamic> json) =>
      _$ProgrammeEntrainementFromJson(json);
}
