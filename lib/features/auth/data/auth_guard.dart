import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../domain/auth_service.dart';

/// Guard GoRouter pour l'authentification.
///
/// Comportement :
/// - Si l'utilisateur n'est pas connecté (null), force une connexion
///   anonyme automatique via le callback [onAutoSignIn].
/// - Les routes publiques (login, onboarding) ne sont pas protégées.
/// - L'anonyme EST considéré comme authentifié (design #82877).
class AuthGuard {
  const AuthGuard({
    required this.getCurrentUser,
    required this.onAutoSignIn,
  });

  /// Getter de l'utilisateur courant (depuis le provider)
  final AuthUser? Function() getCurrentUser;

  /// Callback pour déclencher une connexion anonyme automatique
  final Future<void> Function() onAutoSignIn;

  /// Routes exclues du guard (toujours accessibles)
  static const _publicPaths = <String>['/no-data', '/catalog'];

  /// Redirect function pour GoRouter.
  ///
  /// Retourne null si la navigation est autorisée,
  /// ou un chemin de redirection si l'utilisateur doit être redirigé.
  Future<String?> redirect(BuildContext context, GoRouterState state) async {
    final path = state.uri.path;

    // Routes publiques : pas de guard
    if (_publicPaths.contains(path)) return null;

    final user = getCurrentUser();

    if (user != null) {
      // Utilisateur connecté (anonyme ou identifié) : accès autorisé
      return null;
    }

    // Pas d'utilisateur : déclencher connexion anonyme automatique
    await onAutoSignIn();

    // Après auto sign-in, vérifier à nouveau
    final userAfter = getCurrentUser();
    if (userAfter != null) {
      // Connexion anonyme réussie, laisser passer
      return null;
    }

    // Échec de la connexion anonyme (ne devrait pas arriver) :
    // rediriger vers /no-data en dernier recours
    return '/no-data';
  }
}
