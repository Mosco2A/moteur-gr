import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/auth_service.dart';

/// Implémentation locale du service d'authentification.
///
/// Stocke l'utilisateur dans SharedPreferences.
/// Pas de backend Firebase, tout est local.
class LocalAuthService implements AuthService {
  LocalAuthService();

  static const String _keyUid = 'auth_uid';
  static const String _keyName = 'auth_display_name';
  static const String _keyMethod = 'auth_method';
  static const String _keyAvatarIndex = 'auth_avatar_index';

  AuthUser? _currentUser;
  final _authController = StreamController<AuthUser?>.broadcast();

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _authController.stream;

  /// Initialise depuis les préférences sauvegardées
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid);

    if (uid != null) {
      final name = prefs.getString(_keyName);
      final methodStr = prefs.getString(_keyMethod) ?? AuthMethodValues.anonymous;
      final avatarIdx = prefs.getInt(_keyAvatarIndex) ?? 0;

      _currentUser = AuthUser(
        uid: uid,
        authMethod: AuthMethodValues.fromString(methodStr),
        displayName: name,
        avatarIndex: avatarIdx,
        isAnonymous: methodStr == AuthMethodValues.anonymous,
      );
      _authController.add(_currentUser);
    } else {
      // Auto-connexion anonyme au premier lancement
      await signInAnonymously();
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid) ?? const Uuid().v4();

    _currentUser = AuthUser(
      uid: uid,
      authMethod: AuthMethodValues.anonymous,
      isAnonymous: true,
    );

    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyMethod, AuthMethodValues.anonymous);

    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<AuthUser?> signInWithGoogleSilent() async {
    // Stub — l'intégration Google Sign-In sera ajoutée ultérieurement
    // Retourne null (silencieux = pas d'interruption)
    return null;
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    // Stub — Apple Sign-In iOS uniquement, sera ajouté ultérieurement
    return null;
  }

  @override
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    // Garder l'UID pour les données locales mais revenir en anonyme
    final uid = prefs.getString(_keyUid) ?? const Uuid().v4();

    _currentUser = AuthUser(
      uid: uid,
      authMethod: AuthMethodValues.anonymous,
      isAnonymous: true,
    );

    await prefs.remove(_keyName);
    await prefs.setString(_keyMethod, AuthMethodValues.anonymous);
    await prefs.remove(_keyAvatarIndex);

    _authController.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyMethod);
    await prefs.remove(_keyAvatarIndex);

    _currentUser = null;
    _authController.add(null);

    // Recréer un compte anonyme immédiatement
    await signInAnonymously();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim();

    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      authMethod: _currentUser!.authMethod,
      displayName: trimmed.isEmpty ? null : trimmed,
      email: _currentUser!.email,
      photoUrl: _currentUser!.photoUrl,
      avatarIndex: _currentUser!.avatarIndex,
      isAnonymous: _currentUser!.isAnonymous,
    );

    if (trimmed.isEmpty) {
      await prefs.remove(_keyName);
    } else {
      await prefs.setString(_keyName, trimmed);
    }

    _authController.add(_currentUser);
  }

  @override
  Future<void> updateAvatarIndex(int index) async {
    if (_currentUser == null) return;

    final prefs = await SharedPreferences.getInstance();
    final clampedIndex = index.clamp(0, 7);

    _currentUser = AuthUser(
      uid: _currentUser!.uid,
      authMethod: _currentUser!.authMethod,
      displayName: _currentUser!.displayName,
      email: _currentUser!.email,
      photoUrl: _currentUser!.photoUrl,
      avatarIndex: clampedIndex,
      isAnonymous: _currentUser!.isAnonymous,
    );

    await prefs.setInt(_keyAvatarIndex, clampedIndex);
    _authController.add(_currentUser);
  }

  /// Libère les ressources
  void dispose() {
    _authController.close();
  }
}
