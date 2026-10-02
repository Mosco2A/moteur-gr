/// Choisit le service d'identite selon la disponibilite de Firebase, et rend
/// dans les deux cas un identifiant hashe.
library;

import 'dart:async';

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
    // UNE IDENTITE EST GARANTIE, ET RIEN NE LA GARANTISSAIT (tache 631).
    // `initialize()` ne fait qu ECOUTER : sans la ligne ci-dessous, personne
    // n appelait jamais `signInAnonymously` sur le chemin Firebase (mesure dans
    // `lib/` : les seuls appelants etaient ceux de `LocalAuthService`). Le
    // telephone n avait donc AUCUN identifiant cote serveur, donc aucun
    // `users/{uid}` a lire : la descente des droits n aurait jamais rien trouve,
    // et personne n aurait pu designer ce compte pour lui ecrire.
    // Fire-and-forget, comme le chemin local juste en dessous : le premier ecran
    // n attend pas le reseau.
    unawaited(service.garantirUneIdentite());
    ref.onDispose(service.dispose);
    return service;
  }

  // OFFLINE-FIRST (finitions V1, point 2) : sans cet `initialize()`, le
  // LocalAuthService ne poussait JAMAIS d'utilisateur dans `authStateChanges`
  // (il ne s'auto-connectait qu'appele explicitement). Resultat : hors reseau /
  // sans Firebase, `currentUserProvider` restait bloque en `loading` -> spinner
  // infini sur /profile. On amorce donc l'etat local (auto-connexion anonyme au
  // 1er lancement, ou restauration des prefs) en fire-and-forget : le stream
  // emet aussitot, jamais bloque par le reseau (parite du chemin Firebase, qui
  // appelle deja `initialize()` ci-dessus). Best-effort, non bloquant.
  final service = LocalAuthService();
  unawaited(service.initialize());
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
  return ref.watch(currentUserProvider).value;
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

/// L IDENTIFIANT DU COMPTE AU SERVEUR — celui sous lequel ses droits vivent.
///
/// A QUOI IL SERT, ET POURQUOI IL EST AFFICHE. StepWays n a AUCUN compte
/// nominatif : pas de nom, pas d adresse, pas de courriel, pas de numero. Pour
/// poser des droits sur un compte precis — un achat a rattraper, une
/// restauration, un depannage — il faut bien pouvoir le DESIGNER. Cet
/// identifiant est la seule facon de le faire, et il est montre dans les
/// reglages, sous « Abonnement & achats », pour que le randonneur puisse le
/// donner quand il demande de l aide.
///
/// CE N EST PAS `AuthUser.uid`. Celui-la est le hash SHA-256 qui voyage dans les
/// donnees metier ; celui-ci est l identifiant d authentification, le seul que
/// `firestore.rules` accepte comme nom de document (`request.auth.uid ==
/// userId`). Pour un compte anonyme, il ne designe personne.
///
/// `null` quand Firebase n est pas configure dans ce paquet, ou tant que la
/// premiere connexion anonyme n a pas abouti (premier lancement hors ligne).
final identifiantDeCompteProvider = Provider<String?>((ref) {
  final firebase = ref.watch(firebaseServiceProvider);
  if (!firebase.isAvailable) return null;
  // Se recalcule des que l identite arrive.
  ref.watch(currentUserProvider);
  final service = ref.watch(authServiceProvider);
  if (service is! FirebaseAuthService) return null;
  return service.identifiantDeCompte;
});
