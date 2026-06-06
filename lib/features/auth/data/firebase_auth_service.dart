import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_service.dart';
import 'anonymous_id_service.dart';

/// Service d'authentification Firebase avec anonymisation (E4.15).
///
/// Chaque connexion Apple/Google retourne un userId anonymise
/// via SHA-256 (voir [AnonymousIdService]). Aucune donnee
/// personnelle (nom, email, photo) n'est stockee ni propagee.
///
/// Profil local = pseudonyme choisi + avatar uniquement.
/// RGPD simplifie (#81775) : zero PII, hash irreversible,
/// pas de compte applicatif — l identite reste chez Apple/Google.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    fb.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthUser? _currentUser;
  final _authController = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  /// Initialise l'ecoute des changements d'etat Firebase.
  void initialize() {
    _firebaseAuth.authStateChanges().listen((fb.User? fbUser) {
      if (fbUser == null) {
        _currentUser = null;
        _authController.add(null);
      } else {
        _currentUser = _toAnonymizedUser(fbUser);
        _authController.add(_currentUser);
      }
    });
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final credential = await _firebaseAuth.signInAnonymously();
    final user = _toAnonymizedUser(credential.user!);
    _currentUser = user;
    _authController.add(user);
    return user;
  }

  @override
  Future<AuthUser?> signInWithGoogleSilent() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) return null;

      // Anonymisation : on ne garde PAS nom/email/photo
      final user = _toAnonymizedUser(
        userCredential.user!,
        method: AuthMethodValues.google,
      );
      _currentUser = user;
      _authController.add(user);
      return user;
    } on Exception {
      return null;
    }
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    try {
      final appleProvider = fb.AppleAuthProvider();
      // Aucun scope email/name demande : on n en a pas besoin,
      // l identifiant anonymise suffit (RGPD #81775 — minimisation).

      final userCredential =
          await _firebaseAuth.signInWithProvider(appleProvider);
      if (userCredential.user == null) return null;

      // Anonymisation : on ne garde PAS nom/email/photo
      final user = _toAnonymizedUser(
        userCredential.user!,
        method: AuthMethodValues.apple,
      );
      _currentUser = user;
      _authController.add(user);
      return user;
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _firebaseAuth.signOut();
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> deleteAccount() async {
    final fbUser = _firebaseAuth.currentUser;
    if (fbUser != null) {
      await fbUser.delete();
    }
    await _googleSignIn.signOut();
    _currentUser = null;
    _authController.add(null);
  }

  @override
  Future<void> updateDisplayName(String name) async {
    if (_currentUser == null) return;

    final trimmed = name.trim();
    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      authMethod: _currentUser!.authMethod,
      displayName: trimmed.isEmpty ? null : trimmed,
      avatarIndex: _currentUser!.avatarIndex,
      isAnonymous: _currentUser!.isAnonymous,
      // Jamais email/photoUrl — zero PII
    );
    _authController.add(_currentUser);
  }

  @override
  Future<void> updateAvatarIndex(int index) async {
    if (_currentUser == null) return;

    final clampedIndex = index.clamp(0, 7);
    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      authMethod: _currentUser!.authMethod,
      displayName: _currentUser!.displayName,
      avatarIndex: clampedIndex,
      isAnonymous: _currentUser!.isAnonymous,
      // Jamais email/photoUrl — zero PII
    );
    _authController.add(_currentUser);
  }

  /// Convertit un utilisateur Firebase en AuthUser anonymise.
  ///
  /// Le UID est hache via SHA-256. Nom, email, photo sont
  /// deliberement ignores — zero PII stocke (#81775).
  AuthUser _toAnonymizedUser(
    fb.User fbUser, {
    String? method,
  }) {
    final anonymizedUid = AnonymousIdService.hashUserId(fbUser.uid);
    final isAnon = fbUser.isAnonymous;
    final authMethod = method ??
        (isAnon ? AuthMethodValues.anonymous : AuthMethodValues.google);

    return AuthUser(
      uid: anonymizedUid,
      authMethod: authMethod,
      isAnonymous: isAnon,
      // displayName: null — choisi localement par l'utilisateur
      // email: null — JAMAIS stocke (RGPD)
      // photoUrl: null — JAMAIS stocke (RGPD)
    );
  }

  /// Libere les ressources.
  void dispose() {
    _authController.close();
  }
}
