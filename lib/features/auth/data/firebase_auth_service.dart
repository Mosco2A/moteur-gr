/// Connexion Apple ou Google qui ne rend qu'un identifiant hashe : ni nom, ni
/// adresse, ni photo ne sont conserves ni propages.
library;

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
  }) : _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? GoogleSignIn();

  final fb.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  AuthUser? _currentUser;
  final _authController = StreamController<AuthUser?>.broadcast();

  /// LA TENTATIVE DE CONNEXION EN VOL, ET IL N Y EN A JAMAIS QU UNE (771).
  ///
  /// Nulle quand aucune connexion n est en cours. Tant qu elle ne l est pas,
  /// tout nouvel appel a [garantirUneIdentite] recoit CETTE MEME attente au
  /// lieu d ouvrir la sienne. Remise a nulle des que la tentative s achemine a
  /// son terme — reussie ou non — pour qu un premier lancement en zone
  /// blanche n interdise pas la suivante.
  Future<AuthUser?>? _identiteEnVol;

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

  /// L IDENTIFIANT SOUS LEQUEL LE COMPTE VIT AU SERVEUR (tache 631).
  ///
  /// C EST L IDENTIFIANT D AUTHENTIFICATION BRUT, ET PAS `AuthUser.uid`. La
  /// nuance decide de tout : `AuthUser.uid` est le HASH SHA-256 (voir
  /// [AnonymousIdService]), alors que `firestore.rules` n autorise
  /// `users/{userId}` QUE si `request.auth.uid == userId`. Un document range
  /// sous le hash serait refuse a la lecture comme a l ecriture.
  ///
  /// CE N EST PAS UNE DONNEE PERSONNELLE. Pour un compte ANONYME, cet
  /// identifiant est un numero tire par Firebase : il ne porte ni nom, ni
  /// adresse, ni courriel, ni numero de telephone — c est exactement ce que
  /// Christophe exige du modele (« On ne connait pas leur nom, leur adresse,
  /// leur mail, meme pas leur telephone »). Le hash reste ce qui voyage dans
  /// les donnees METIER ; celui-ci ne sert qu a designer la boite.
  String? get accountId => _firebaseAuth.currentUser?.uid;

  /// GARANTIT QU UNE IDENTITE EXISTE — et rien ne le faisait (tache 631).
  ///
  /// LE DEFAUT MESURE. `authServiceProvider` construisait ce service et
  /// appelait `initialize()`, qui ne fait qu ECOUTER `authStateChanges`.
  /// AUCUN appelant de `signInAnonymously` n existait sur le chemin Firebase —
  /// la recherche dans `lib/` ne le trouvait que sur `LocalAuthService`, qui,
  /// lui, s auto-connecte depuis les finitions V1. Consequence : des que
  /// Firebase devenait disponible, l application n avait PLUS AUCUNE identite,
  /// donc aucun `users/{uid}` a lire, donc aucun droit ne pouvait redescendre —
  /// et personne ne pouvait non plus DESIGNER ce compte pour lui ecrire.
  ///
  /// IDEMPOTENT : si quelqu un est deja connecte, on ne recree rien. Firebase
  /// rend d ailleurs l utilisateur anonyme existant plutot que d en fabriquer un
  /// second, mais on ne s appuie pas dessus — un compte de plus, c est un
  /// compte de trop, et ce serait des droits perdus a chaque lancement.
  ///
  /// UNE SEULE TENTATIVE EN VOL, ET C EST LE CORRECTIF DU 10/10 (tache 771).
  ///
  /// LE DEFAUT MESURE SUR emulator-5560. DEUX comptes anonymes naissaient au
  /// MEME lancement, a 37 millisecondes d ecart (2026-10-10T08:36:59.093Z et
  /// .130Z). Le jeton portait le second, les chemins Firestore visaient le
  /// premier, et `firestore.rules` exigeant `request.auth.uid == userId`, le
  /// serveur refusait TOUT : « Write failed at users/pY0i... :
  /// PERMISSION_DENIED », « [RegistreConsentement] healthData :
  /// permission-denied », « [FicheTechnique] ecriture impossible ». Les regles
  /// etaient justes ; c est l application qui se trompait d identite.
  ///
  /// POURQUOI DEUX, ALORS QUE LE SERVICE EST UNIQUE. Il n y a qu un
  /// `ProviderScope` et donc qu une instance de cette classe — le provider
  /// n etait PAS reconstruit. Mais DEUX appelants la tirent au demarrage, sans
  /// savoir l un de l autre : `auth_provider.dart` en fire-and-forget dans le
  /// `create` du provider, et `monteeEnBaseDemarreeProvider`
  /// (`sync_scheduler.dart`) qui l attend aussitot apres le `ref.read` ayant
  /// JUSTE construit ce service.
  ///
  /// Le corps ci-dessous etait un CONTROLE-PUIS-AGIS que rien ne rendait
  /// atomique : le premier appel partait et se suspendait sur le reseau, le
  /// second lisait `currentUser` encore nul, et ouvrait un SECOND compte.
  ///
  /// CE QUI LE REND IMPOSSIBLE MAINTENANT. La tentative est MEMORISEE avant le
  /// premier `await`, et les appels suivants recoivent cette meme attente.
  /// Cette methode n est volontairement PAS `async` : une `async` rend le
  /// controle a son appelant au premier `await`, et c est precisement dans cet
  /// interstice que le second appel se glissait. Ici, de l entree jusqu a
  /// l affectation de [_identiteEnVol], aucun point de suspension n existe —
  /// donc aucun second appel ne peut passer entre les deux.
  ///
  /// NE LEVE PAS : sans reseau au premier lancement, l identite n existera
  /// qu au suivant, et l application marche entre-temps sur sa base locale.
  Future<AuthUser?> garantirUneIdentite() {
    final deja = _firebaseAuth.currentUser;
    if (deja != null) {
      _currentUser = _toAnonymizedUser(deja);
      return Future<AuthUser?>.value(_currentUser);
    }
    return _identiteEnVol ??= _ouvrirUneIdentite();
  }

  /// LA TENTATIVE ELLE-MEME. Appelee par [garantirUneIdentite] seulement, et
  /// jamais plus d une fois a la fois.
  Future<AuthUser?> _ouvrirUneIdentite() async {
    try {
      return await signInAnonymously();
    } on Object {
      return null;
    } finally {
      // LE DROIT DE REESSAYER. Sans cette remise a nulle, un refus au premier
      // lancement (zone blanche) laisserait l application sans identite pour
      // toujours : chaque appel suivant se verrait rendre l echec memorise.
      _identiteEnVol = null;
    }
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

      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
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

      final userCredential = await _firebaseAuth.signInWithProvider(
        appleProvider,
      );
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
  AuthUser _toAnonymizedUser(fb.User fbUser, {String? method}) {
    final anonymizedUid = AnonymousIdService.hashUserId(fbUser.uid);
    final isAnon = fbUser.isAnonymous;
    final authMethod =
        method ??
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
