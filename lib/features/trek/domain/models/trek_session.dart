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

    /// GO-85 inc2 (persistance ALPHA, port GR20 #97501 chantier B) —
    /// Identifiants des etapes REELLEMENT completees (arrivee detectee a leur
    /// fin). Sert de critere BLOQUANT du finisher : un simple demi-tour ou une
    /// arrivee opportuniste a la derniere etape (sans avoir marche les etapes
    /// intermediaires) ne suffit PAS a terminer le parcours. Porte directement
    /// sur la session (pas de nouvelle table). Retro-compat : une session sans
    /// ce champ (sessions anterieures, JSON legacy) = liste vide -> jamais de
    /// faux finisher.
    @Default(<String>[]) List<String> completedStages,

    /// GO-85 inc2 (persistance ALPHA) — Le parcours choisi a-t-il ete
    /// REELLEMENT parcouru en entier (toutes ses etapes dans [completedStages]) ?
    ///
    /// Fige au moment ou la porte du finisher s'ouvre (completion validee via
    /// [TrekPlan.isFullyWalked]). Persiste sur la session pour tracer qu'un
    /// finisher legitime a bien eu lieu (vs un arret manuel prematuré).
    /// Defaut false : une session non terminee (ou legacy) n'est pas « fully
    /// walked » tant que la gate n'a pas ete franchie.
    @Default(false) bool parcoursFullyWalked,
  }) = _TrekSession;

  /// Deserialisation depuis JSON
  factory TrekSession.fromJson(Map<String, dynamic> json) =>
      _$TrekSessionFromJson(json);
}
