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

  /// Utilisateur courant (null si pas connecté)
  AuthUser? get currentUser;

  /// Stream de changement d'état d'authentification
  Stream<AuthUser?> get authStateChanges;
}

/// Représentation de l'utilisateur authentifié
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.authMethod,
    this.displayName,
    this.email,
    this.photoUrl,
    this.isAnonymous = true,
  });

  /// Identifiant unique local
  final String uid;

  /// Méthode d'authentification utilisée
  final AuthMethod authMethod;

  /// Nom d'affichage (null si anonyme)
  final String? displayName;

  /// Email (null si anonyme)
  final String? email;

  /// URL de la photo de profil
  final String? photoUrl;

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
