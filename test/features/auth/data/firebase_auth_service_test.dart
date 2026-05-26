import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:moteur_gr/features/auth/data/firebase_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';

/// Mock minimal de FirebaseAuth pour les tests unitaires.
///
/// Simule les methodes essentielles sans dependre de Firebase reel.
class MockFirebaseAuth implements fb.FirebaseAuth {
  fb.User? _currentUser;
  final _authController = StreamController<fb.User?>.broadcast();

  @override
  fb.User? get currentUser => _currentUser;

  @override
  Stream<fb.User?> authStateChanges() => _authController.stream;

  @override
  Future<fb.UserCredential> signInAnonymously() async {
    _currentUser = MockFirebaseUser(
      uid: 'anon-test-uid',
      isAnonymous: true,
    );
    _authController.add(_currentUser);
    return MockUserCredential(user: _currentUser!);
  }

  @override
  Future<fb.UserCredential> signInWithCredential(
    fb.AuthCredential credential,
  ) async {
    _currentUser = MockFirebaseUser(
      uid: 'google-test-uid',
      isAnonymous: false,
      displayName: 'Test User',
      email: 'test@example.com',
      providerData: [MockUserInfo(providerId: 'google.com')],
    );
    _authController.add(_currentUser);
    return MockUserCredential(user: _currentUser!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authController.add(null);
  }

  void dispose() => _authController.close();

  // Stubs pour les methodes non utilisees dans les tests
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock minimal de User Firebase
class MockFirebaseUser implements fb.User {
  MockFirebaseUser({
    required this.uid,
    this.isAnonymous = true,
    this.displayName,
    this.email,
    this.photoURL,
    this.providerData = const [],
  });

  @override
  final String uid;

  @override
  final bool isAnonymous;

  @override
  final String? displayName;

  @override
  final String? email;

  @override
  final String? photoURL;

  @override
  final List<fb.UserInfo> providerData;

  bool deleted = false;

  @override
  Future<void> delete() async {
    deleted = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock de UserCredential
class MockUserCredential implements fb.UserCredential {
  MockUserCredential({required this.user});

  @override
  final fb.User user;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock de UserInfo (pour providerData)
class MockUserInfo implements fb.UserInfo {
  MockUserInfo({required this.providerId});

  @override
  final String providerId;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// Mock de GoogleSignIn (retourne toujours null = pas de compte)
class MockGoogleSignIn extends GoogleSignIn {
  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async {
    return null;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

/// Tests du service d'authentification Firebase.
void main() {
  late MockFirebaseAuth mockAuth;
  late MockGoogleSignIn mockGoogle;
  late FirebaseAuthService service;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockGoogle = MockGoogleSignIn();
    service = FirebaseAuthService(
      firebaseAuth: mockAuth,
      googleSignIn: mockGoogle,
    );
  });

  tearDown(() {
    mockAuth.dispose();
  });

  group('FirebaseAuthService', () {
    test('signInAnonymously retourne un AuthUser anonyme', () async {
      final user = await service.signInAnonymously();

      expect(user.uid, 'anon-test-uid');
      expect(user.isAnonymous, true);
      expect(user.authMethod, AuthMethod.anonymous);
    });

    test('currentUser est null initialement', () {
      expect(service.currentUser, isNull);
    });

    test('currentUser est mis a jour apres signInAnonymously', () async {
      await service.signInAnonymously();

      expect(service.currentUser, isNotNull);
      expect(service.currentUser!.uid, 'anon-test-uid');
    });

    test('signInWithGoogleSilent retourne null sans compte Google', () async {
      final user = await service.signInWithGoogleSilent();

      expect(user, isNull);
    });

    test('signInWithApple retourne null (stub)', () async {
      final user = await service.signInWithApple();

      expect(user, isNull);
    });

    test('signOut deconnecte l utilisateur', () async {
      await service.signInAnonymously();
      expect(service.currentUser, isNotNull);

      await service.signOut();
      expect(service.currentUser, isNull);
    });

    test('deleteAccount supprime l utilisateur Firebase', () async {
      await service.signInAnonymously();
      final fbUser = mockAuth.currentUser as MockFirebaseUser;

      await service.deleteAccount();

      expect(fbUser.deleted, true);
    });

    test('authStateChanges emet les changements', () async {
      final states = <AuthUser?>[];
      final sub = service.authStateChanges.listen(states.add);

      await service.signInAnonymously();
      await service.signOut();

      // Laisser le stream propager
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(states.length, greaterThanOrEqualTo(2));
      expect(states.first?.isAnonymous, true);
      expect(states.last, isNull);

      await sub.cancel();
    });

    test('resolveAuthMethod detecte Google depuis providerData', () async {
      // Simuler un sign-in avec credential Google
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: 'fake-access',
        idToken: 'fake-id',
      );
      await mockAuth.signInWithCredential(credential);

      final user = service.currentUser;
      expect(user, isNotNull);
      expect(user!.authMethod, AuthMethod.google);
      expect(user.isAnonymous, false);
    });
  });
}
