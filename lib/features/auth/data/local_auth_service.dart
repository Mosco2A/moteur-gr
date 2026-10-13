/// Le repli OFFICIEL quand Firebase manque : identite tenue dans les prefs,
/// sans backend — ce service ne peut produire aucune donnee nominative.
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../domain/auth_service.dart';
import '../domain/diffusion_identite.dart';

/// Implémentation locale du service d'authentification.
///
/// FALLBACK OFFICIEL du moteur quand Firebase est indisponible
/// (authServiceProvider) — cohérent avec l'offline-first.
/// Stocke uid/pseudo/avatar dans SharedPreferences, zéro backend,
/// zéro PII (finitions V8 F7) : aucune donnée email/photo ne peut
/// être produite par ce service.
class LocalAuthService implements AuthService {
  LocalAuthService();

  static const String _keyUid = 'auth_uid';
  static const String _keyName = 'auth_display_name';
  static const String _keyMethod = 'auth_method';
  static const String _keyAvatarIndex = 'auth_avatar_index';

  /// L IDENTITE ET SA DIFFUSION, COMME SUR LE CHEMIN FIREBASE (tache 781).
  ///
  /// Le repli local souffrait EXACTEMENT du meme defaut que le chemin
  /// Firebase : son flux de diffusion ne rejouait rien a un abonne tardif, et
  /// il n emet qu une fois (`initialize()` au demarrage). Les deux
  /// implementations partagent donc la meme diffusion, pour qu aucune ne puisse
  /// redevenir l exception — voir [DiffusionIdentite], qui porte aussi le
  /// garde-fou « emettre dans le vide » de la tache 561 autrefois tenu ici par
  /// un `_emit` prive.
  final _identite = DiffusionIdentite<AuthUser>();

  @override
  AuthUser? get currentUser => _identite.valeur;

  @override
  Stream<AuthUser?> get authStateChanges => _identite.flux;

  /// Initialise depuis les préférences sauvegardées.
  ///
  /// Appelee en fire-and-forget par `authServiceProvider` : elle doit donc
  /// tolerer un dispose survenu pendant son attente, sans rien emettre.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (_identite.estFerme) return;
    final uid = prefs.getString(_keyUid);

    if (uid != null) {
      final name = prefs.getString(_keyName);
      final methodStr =
          prefs.getString(_keyMethod) ?? AuthMethodValues.anonymous;
      final avatarIdx = prefs.getInt(_keyAvatarIndex) ?? 0;

      _identite.publier(
        AuthUser(
          uid: uid,
          authMethod: AuthMethodValues.fromString(methodStr),
          displayName: name,
          avatarIndex: avatarIdx,
          isAnonymous: methodStr == AuthMethodValues.anonymous,
        ),
      );
    } else {
      // Auto-connexion anonyme au premier lancement
      await signInAnonymously();
    }
  }

  @override
  Future<AuthUser> signInAnonymously() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString(_keyUid) ?? const Uuid().v4();

    final utilisateur = AuthUser(
      uid: uid,
      authMethod: AuthMethodValues.anonymous,
      isAnonymous: true,
    );

    await prefs.setString(_keyUid, uid);
    await prefs.setString(_keyMethod, AuthMethodValues.anonymous);

    _identite.publier(utilisateur);
    return utilisateur;
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

    await prefs.remove(_keyName);
    await prefs.setString(_keyMethod, AuthMethodValues.anonymous);
    await prefs.remove(_keyAvatarIndex);

    _identite.publier(
      AuthUser(
        uid: uid,
        authMethod: AuthMethodValues.anonymous,
        isAnonymous: true,
      ),
    );
  }

  @override
  Future<void> deleteAccount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUid);
    await prefs.remove(_keyName);
    await prefs.remove(_keyMethod);
    await prefs.remove(_keyAvatarIndex);

    _identite.publier(null);

    // Recréer un compte anonyme immédiatement
    await signInAnonymously();
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final actuel = _identite.valeur;
    if (actuel == null) return;

    final prefs = await SharedPreferences.getInstance();
    final trimmed = name.trim();

    if (trimmed.isEmpty) {
      await prefs.remove(_keyName);
    } else {
      await prefs.setString(_keyName, trimmed);
    }

    _identite.publier(
      AuthUser(
        uid: actuel.uid,
        authMethod: actuel.authMethod,
        displayName: trimmed.isEmpty ? null : trimmed,
        avatarIndex: actuel.avatarIndex,
        isAnonymous: actuel.isAnonymous,
      ),
    );
  }

  @override
  Future<void> updateAvatarIndex(int index) async {
    final actuel = _identite.valeur;
    if (actuel == null) return;

    final prefs = await SharedPreferences.getInstance();
    final clampedIndex = index.clamp(0, 7);

    await prefs.setInt(_keyAvatarIndex, clampedIndex);

    _identite.publier(
      AuthUser(
        uid: actuel.uid,
        authMethod: actuel.authMethod,
        displayName: actuel.displayName,
        avatarIndex: clampedIndex,
        isAnonymous: actuel.isAnonymous,
      ),
    );
  }

  /// Libère les ressources
  void dispose() {
    _identite.fermer();
  }
}
