import 'package:freezed_annotation/freezed_annotation.dart';

part 'defi_saisonnier.freezed.dart';
part 'defi_saisonnier.g.dart';

/// Types d'objectif d'un defi saisonnier (F7C-02). String extensible evitee :
/// l'objectif structure le calcul de progression.
abstract final class DefiObjectif {
  static const String distance = 'distance'; // metres cumules
  static const String denivele = 'denivele'; // metres D+ cumules
  static const String segments = 'segments'; // nombre de segments completes
  static const List<String> values = [distance, denivele, segments];
}

/// Modele immutable d'un defi saisonnier (F7C-02, Phase 7 gamification).
///
/// Periode bornee [debut]..[fin], objectif [typeObjectif] a atteindre ([cible]).
/// La PROGRESSION est calculee LOCALEMENT (offline-first, R2) ; le CLASSEMENT
/// du defi est calcule COTE SERVEUR (Cloud Function classementDefi, meme
/// pattern k-anonymat que F7A-03). [titre]/[description] localises (Slang).
@freezed
abstract class DefiSaisonnier with _$DefiSaisonnier {
  const DefiSaisonnier._();

  const factory DefiSaisonnier({
    /// Identifiant unique du defi.
    required String id,

    /// Titre localise (Slang).
    required String titre,

    /// Description localisee (Slang).
    required String description,

    /// Debut de la periode (UTC).
    required DateTime debut,

    /// Fin de la periode (UTC, incluse).
    required DateTime fin,

    /// Type d'objectif ('distance' / 'denivele' / 'segments', DefiObjectif).
    required String typeObjectif,

    /// Valeur cible a atteindre (unite selon typeObjectif).
    required double cible,
  }) = _DefiSaisonnier;

  /// Le defi est-il actif a la date [now] (dans la periode) ?
  bool isActiveAt(DateTime now) {
    final t = now.toUtc();
    return !t.isBefore(debut) && !t.isAfter(fin);
  }

  factory DefiSaisonnier.fromJson(Map<String, dynamic> json) =>
      _$DefiSaisonnierFromJson(json);
}

/// Progression LOCALE de l'utilisateur sur un defi (F7C-02).
class DefiProgress {
  const DefiProgress({
    required this.defiId,
    required this.current,
    required this.target,
  });

  final String defiId;

  /// Valeur courante atteinte (unite selon le type d'objectif).
  final double current;

  /// Cible du defi.
  final double target;

  /// Ratio [0..1] (borne) de progression.
  double get ratio {
    if (target <= 0) return 0;
    final r = current / target;
    return r.clamp(0.0, 1.0);
  }

  /// Objectif atteint ?
  bool get isComplete => current >= target;
}
