import 'package:freezed_annotation/freezed_annotation.dart';

part 'trek_session.freezed.dart';
part 'trek_session.g.dart';

/// Session de randonnee d'un utilisateur sur un sentier.
///
/// Represente une tentative de parcours avec horodatage
/// debut/fin et statut extensible (String).
@freezed
abstract class TrekSession with _$TrekSession {
  const TrekSession._();

  const factory TrekSession({
    /// Identifiant unique (UUID)
    required String id,

    /// Identifiant du sentier parcouru
    required String trailId,

    /// Date/heure de debut
    required DateTime startedAt,

    /// Date/heure de fin (null si en cours)
    DateTime? finishedAt,

    /// Statut — String extensible (active, paused, completed, abandoned, ...)
    @Default("active") String status,
  }) = _TrekSession;

  /// Deserialisation depuis JSON
  factory TrekSession.fromJson(Map<String, dynamic> json) =>
      _$TrekSessionFromJson(json);
}
