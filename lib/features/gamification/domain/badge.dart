import 'package:freezed_annotation/freezed_annotation.dart';

part 'badge.freezed.dart';
part 'badge.g.dart';

/// Paliers de badge (F7C-01). String extensible volontairement evitee ici :
/// le tier structure les regles d'obtention (debutant vs expert).
abstract final class BadgeTier {
  static const String debutant = 'debutant';
  static const String expert = 'expert';
  static const List<String> values = [debutant, expert];
}

/// Codes de badges du catalogue (F7C-01). Servent de cle de regle ET de cle
/// i18n (titre/description resolus via Slang t.gamification.badge.<code>).
abstract final class BadgeCode {
  // Debutant
  static const String firstStage = 'first_stage'; // 1re etape terminee
  static const String firstTrek = 'first_trek'; // 1er trek complet
  static const String firstSegment = 'first_segment'; // 1er segment complete
  // Expert
  static const String elevation5000 = 'elevation_5000'; // 5000 m D+ cumule
  static const String tenStages = 'ten_stages'; // 10 etapes terminees
  static const String challenger = 'challenger'; // 1er defi reussi

  static const List<String> values = [
    firstStage,
    firstTrek,
    firstSegment,
    elevation5000,
    tenStages,
    challenger,
  ];
}

/// Modele immutable d'un badge (F7C-01, Phase 7 gamification).
///
/// [titre] et [description] sont des libelles LOCALISES (resolus via Slang a la
/// construction du catalogue, 5 langues) — aucun texte en dur cote moteur.
/// [obtainedAt] est non nul si le badge a ete obtenu (sinon verrouille).
@freezed
abstract class Badge with _$Badge {
  const Badge._();

  const factory Badge({
    /// Identifiant unique du badge (== code par defaut).
    required String id,

    /// Code de regle/i18n du badge (BadgeCode).
    required String code,

    /// Titre localise (Slang).
    required String titre,

    /// Description localisee (Slang).
    required String description,

    /// Palier ('debutant' / 'expert', BadgeTier).
    required String tier,

    /// Reference d'icone (asset/glyph) du badge.
    required String iconRef,

    /// Date d'obtention (null = badge verrouille, pas encore obtenu).
    DateTime? obtainedAt,
  }) = _Badge;

  /// Vrai si le badge est obtenu.
  bool get isObtained => obtainedAt != null;

  factory Badge.fromJson(Map<String, dynamic> json) => _$BadgeFromJson(json);
}
