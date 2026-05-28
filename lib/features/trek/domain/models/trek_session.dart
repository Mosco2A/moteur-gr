import 'package:freezed_annotation/freezed_annotation.dart';

part 'trek_session.freezed.dart';
part 'trek_session.g.dart';

/// Session de trek enregistree.
///
/// Le statut est un String libre (jamais enum) pour extensibilite (#81752).
/// Valeurs courantes : active, paused, completed, abandoned.
@freezed
class TrekSession with _$TrekSession {
  const TrekSession._();

  const factory TrekSession({
    /// Identifiant unique (UUID)
    required String id,

    /// Identifiant du sentier
    required String trailId,

    /// Date/heure de debut
    required DateTime startedAt,

    /// Date/heure de fin (null si en cours)
    DateTime? finishedAt,

    /// Statut — String libre, pas enum (#81752)
    /// Valeurs courantes : active, paused, completed, abandoned
    @Default('active') String status,
  }) = _TrekSession;

  /// La session est-elle terminee ?
  bool get isFinished => finishedAt != null;

  /// Duree ecoulee (ou depuis startedAt si en cours)
  Duration get elapsed =>
      (finishedAt ?? DateTime.now()).difference(startedAt);

  /// Deserialisation depuis JSON
  factory TrekSession.fromJson(Map<String, dynamic> json) =>
      _$TrekSessionFromJson(json);
}
