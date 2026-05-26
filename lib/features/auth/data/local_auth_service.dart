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
      final methodIndex = prefs.getInt(_keyMethod) ?? 0;

      _currentUser = AuthUser(
        uid: uid,
        authMethod: AuthMethod.values[methodIndex],
        displayName: name,
        isAnonymous: methodIndex == 0,
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
      authMethod: AuthMethod.anonymous,
      isAnonymous: true,
    );

    await prefs.setString(_keyUid, uid);
    await prefs.setInt(_keyMethod, AuthMethod.anonymous.index);

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
      authMethod: AuthMethod.anonymous,
      isAnonymous: true,
    );

    await prefs.remove(_keyName);
    await prefs.setInt(_keyMethod, AuthMethod.anonymous.index);

    _authController.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyMethod);

    _currentUser = null;
    _authController.add(null);

    // Recréer un compte anonyme immédiatement
    await signInAnonymously();
  }

  /// Libère les ressources
  void dispose() {
    _authController.close();
  }
}
