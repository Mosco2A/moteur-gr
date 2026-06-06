/// Interface abstraite du service d'authentification.
///
/// Le moteur supporte 3 modes :
/// 1. Anonyme automatique (défaut, toujours disponible)
/// 2. Google Sign-In silencieux (si disponible)
/// 3. Apple Sign-In (prévu pour iOS, stub)
///
/// PAS de mode email+password (#81461).
abstract class AuthService {
  /// Connexion anonyme automatique
  Future<AuthUser> signInAnonymously();

  /// Connexion Google silencieuse (sans écran de choix de compte)
  Future<AuthUser?> signInWithGoogleSilent();

  /// Connexion Apple Sign-In (iOS uniquement)
  Future<AuthUser?> signInWithApple();

  /// Déconnexion
  Future<void> signOut();

  /// Suppression du compte
  Future<void> deleteAccount();

  /// Met à jour le pseudonyme de l'utilisateur
  Future<void> updateDisplayName(String name);

  /// Met à jour l'index d'avatar local (choix parmi une liste prédéfinie)
  Future<void> updateAvatarIndex(int index);

  /// Utilisateur courant (null si pas connecté)
  AuthUser? get currentUser;

  /// Stream de changement d'état d'authentification
  Stream<AuthUser?> get authStateChanges;
}

/// Représentation de l'utilisateur authentifié.
///
/// ZERO PII par construction (#81775, finitions V8 F7) : le modèle
/// ne porte NI email NI photo — aucune donnée personnelle ne peut
/// transiter, même par accident. Le pseudonyme est libre et l'avatar
/// est un index local (liste prédéfinie).
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.authMethod,
    this.displayName,
    this.avatarIndex = 0,
    this.isAnonymous = true,
  });

  /// Identifiant unique local
  final String uid;

  /// Méthode d'authentification utilisée
  final AuthMethod authMethod;

  /// Nom d'affichage (null si anonyme sans pseudo)
  final String? displayName;

  /// Index de l'avatar local choisi (0-7)
  final int avatarIndex;

  /// Est un utilisateur anonyme
  final bool isAnonymous;
}

/// Methodes d'authentification supportees.
/// Utilise String pour extensibilite (valeurs inconnues gerees par fallback).
typedef AuthMethod = String;

/// Valeurs connues pour AuthMethod avec fallback generique.
abstract class AuthMethodValues {
  static const String anonymous = 'anonymous';
  static const String google = 'google';
  static const String apple = 'apple';
  static const String fallback = anonymous;
  static const List<String> values = [anonymous, google, apple];

  /// Labels d'affichage par methode
  static const Map<String, String> labels = {
    anonymous: 'Anonyme',
    google: 'Google',
    apple: 'Apple',
  };

  /// Label d'affichage avec fallback
  static String labelFor(String method) => labels[method] ?? method;

  static AuthMethod fromString(String value) =>
      values.contains(value) ? value : fallback;
}
