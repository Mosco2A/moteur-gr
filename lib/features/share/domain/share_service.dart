import '../../../core/error/error_handler.dart';

/// Carte de resultat d'etape PARTAGEABLE in-app (F7D-01, Phase 7).
///
/// Donnees PSEUDONYMES, SANS PII (pas de nom reel, pas d'email, pas de
/// localisation precise du domicile, #85383 minimisation). Pas d'export de
/// trace fine brute (minimisation RGPD A4-2) : seules des STATS agregees.
class StageResultCard {
  const StageResultCard({
    required this.pseudonym,
    required this.stageName,
    required this.distanceKm,
    required this.elevationGainM,
    required this.durationSeconds,
    this.badgeTitle,
  });

  /// Libelle PSEUDONYME de l'auteur (derive d'un UID hache, jamais nom reel).
  final String pseudonym;

  /// Nom de l'etape (libelle public du sentier, pas une donnee perso).
  final String stageName;

  /// Distance parcourue (km), stat agregee.
  final double distanceKm;

  /// Denivele positif (m), stat agregee.
  final int elevationGainM;

  /// Temps de l'etape (secondes), stat agregee.
  final int durationSeconds;

  /// Titre de badge eventuel a mettre en avant (localise), nullable.
  final String? badgeTitle;
}

/// Champs interdits dans une carte de partage (PII — minimisation #85383).
///
/// Garde-fou explicite : la generation refuse toute donnee directement
/// identifiante (nom reel, email, coordonnees precises du domicile).
abstract final class _ForbiddenPii {
  static final RegExp email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+');
}

/// Service de partage in-app d'une carte de resultat d'etape (F7D-01).
///
/// - PSEUDONYME : le partage n'expose JAMAIS de nom reel/email/domicile
///   (#85383, minimisation). Le pseudonyme est derive d'un UID hache.
/// - OPT-IN : prive par defaut. La generation EXIGE un consentement explicite
///   (`optedIn=true`) ; sinon elle renvoie `null` (rien n'est partage). Le
///   reglage de consentement est porte par le design Securite D4 (F7D-02).
/// - MINIMISATION : pas d'export de trace fine brute (A4-2), uniquement des
///   stats agregees.
///
/// ZERO catch silencieux — toute anomalie est loggee via [ErrorHandler].
class ShareService {
  const ShareService();

  /// Derive un libelle PSEUDONYME a partir d'un UID HACHE (8 premiers
  /// caracteres). Jamais de nom reel, jamais "anonyme".
  static String pseudonymFromHash(String uidHash) {
    if (uidHash.isEmpty) return 'rndr-0000';
    final short = uidHash.length >= 8 ? uidHash.substring(0, 8) : uidHash;
    return 'rndr-$short';
  }

  /// Construit une carte de resultat d'etape PARTAGEABLE, ou `null` si
  /// l'utilisateur n'a PAS consenti au partage ([optedIn] faux : prive par
  /// defaut, opt-in F7D-02).
  ///
  /// [authorUidHash] DOIT etre l'UID HACHE (#85383). [stageName] est un libelle
  /// public de sentier. Les stats sont agregees (pas de trace fine, A4-2).
  /// Si un champ PII se glisse dans [stageName] ou [badgeTitle] (email), il est
  /// neutralise (garde-fou minimisation).
  StageResultCard? buildStageCard({
    required bool optedIn,
    required String authorUidHash,
    required String stageName,
    required double distanceKm,
    required int elevationGainM,
    required int durationSeconds,
    String? badgeTitle,
  }) {
    // Prive par defaut : sans opt-in explicite, AUCUN partage genere.
    if (!optedIn) return null;
    try {
      return StageResultCard(
        pseudonym: pseudonymFromHash(authorUidHash),
        stageName: _stripPii(stageName),
        distanceKm: distanceKm,
        elevationGainM: elevationGainM,
        durationSeconds: durationSeconds,
        badgeTitle: badgeTitle == null ? null : _stripPii(badgeTitle),
      );
    } on Exception catch (e, st) {
      ErrorHandler.log(e, stackTrace: st, context: 'ShareService.buildStageCard');
      rethrow;
    }
  }

  /// Neutralise toute PII evidente (email) d'un libelle destine au partage.
  String _stripPii(String input) {
    return input.replaceAll(_ForbiddenPii.email, '').trim();
  }
}
