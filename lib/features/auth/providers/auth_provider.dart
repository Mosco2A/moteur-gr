import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_service.dart';
import '../data/firebase_auth_service.dart';
import '../data/local_auth_service.dart';
import '../domain/auth_service.dart';

/// Provider du service d'authentification.
///
/// Si Firebase est disponible : FirebaseAuthService (E4.15,
/// identifiants anonymises SHA-256, zero PII #81775).
/// Sinon : LocalAuthService (mode local, zero Firebase).
/// L'interface AuthService permet de brancher d'autres implémentations
/// plus tard sans toucher aux consumers.
final authServiceProvider = Provider<AuthService>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);

  if (firebase.isAvailable) {
    final service = FirebaseAuthService()..initialize();
    ref.onDispose(service.dispose);
    return service;
  }

  final service = LocalAuthService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider de l'utilisateur courant
final currentUserProvider = StreamProvider<AuthUser?>((ref) {
  final service = ref.watch(authServiceProvider);
  return service.authStateChanges;
});

/// Provider synchrone de l'utilisateur (pour les guards GoRouter)
final authStateProvider = Provider<AuthUser?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull;
});

/// Est connecte (meme anonyme = connecte)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authStateProvider) != null;
});

/// Est un utilisateur identifie (pas anonyme)
final isIdentifiedProvider = Provider<bool>((ref) {
  final user = ref.watch(authStateProvider);
  return user != null && !user.isAnonymous;
});
