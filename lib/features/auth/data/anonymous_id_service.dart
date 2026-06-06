import 'dart:convert';

import 'package:crypto/crypto.dart';

/// Service d'anonymisation des identifiants utilisateur (E4.15).
///
/// Transforme un UID Firebase en identifiant anonyme irreversible
/// via SHA-256. Aucune donnee personnelle n'est conservee.
/// Conforme RGPD (#81775) : hash irreversible, zero PII stocke.
///
/// Le sel est FIXE dans le moteur : le hash doit etre deterministe
/// entre deux appareils pour que la restauration (E4.16) retrouve
/// les donnees du meme compte Apple/Google.
class AnonymousIdService {
  /// Sel interne pour eviter les rainbow tables.
  /// Concatene au UID avant hachage.
  static const String _salt = 'moteur-gr-2026';

  /// Transforme un UID Firebase en identifiant anonyme SHA-256.
  ///
  /// Deterministe : meme input = meme output.
  /// Irreversible : impossible de retrouver l'UID original.
  ///
  /// Retourne un hash hexadecimal de 64 caracteres.
  static String hashUserId(String firebaseUid) {
    final bytes = utf8.encode('$_salt:$firebaseUid');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
