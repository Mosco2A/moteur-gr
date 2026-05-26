import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_service.dart';

/// Implementation Firebase du service d'authentification.
///
/// Delegue a FirebaseAuth pour toutes les operations.
/// Convertit les objets Firebase (User) en AuthUser du domaine.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  @override
  AuthUser? get currentUser {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser == null) return null;
    return _toAuthUser(fbUser);
  }

  @override
  Stream<AuthUser?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((fbUser) {
      if (fbUser == null) return null;
      return _toAuthUser(fbUser);
    });
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    return _toAuthUser(credential.user!);
  }

  @override
  Future<AuthUser?> signInWithGoogleSilent() async {
    try {
      final googleUser = await _googleSignIn.signInSilently();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      return _toAuthUser(userCredential.user!);
    } catch (e) {
      // Silencieux = pas d'interruption en cas d'echec
      return null;
    }
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    // Stub -- Apple Sign-In sera implemente avec sign_in_with_apple
    // quand le provisioning iOS sera configure
    return null;
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.delete();
    }
  }

  /// Convertit un User Firebase en AuthUser du domaine
  AuthUser _toAuthUser(fb.User fbUser) {
    return AuthUser(
      uid: fbUser.uid,
      authMethod: _resolveAuthMethod(fbUser),
      displayName: fbUser.displayName,
      email: fbUser.email,
      photoUrl: fbUser.photoURL,
      isAnonymous: fbUser.isAnonymous,
    );
  }

  /// Determine la methode d'authentification depuis les providers Firebase
  AuthMethod _resolveAuthMethod(fb.User fbUser) {
    if (fbUser.isAnonymous) return AuthMethod.anonymous;

    for (final provider in fbUser.providerData) {
      if (provider.providerId == 'google.com') return AuthMethod.google;
      if (provider.providerId == 'apple.com') return AuthMethod.apple;
    }

    return AuthMethod.anonymous;
  }
}
