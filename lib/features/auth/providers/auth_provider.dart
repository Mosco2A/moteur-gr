import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/firebase/firebase_service.dart';
import '../data/firebase_auth_service.dart';
import '../data/local_auth_service.dart';
import '../domain/auth_service.dart';

/// Provider du service d'authentification.
///
/// Si Firebase est disponible, utilise FirebaseAuthService.
/// Sinon, fallback sur LocalAuthService (mode offline/local).
final authServiceProvider = Provider<AuthService>((ref) {
  final isFirebaseAvailable = ref.watch(isFirebaseAvailableProvider);

  if (isFirebaseAvailable) {
    return FirebaseAuthService();
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
