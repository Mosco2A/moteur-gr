import 'dart:async';

import 'package:drift/native.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/daos/progress_dao.dart';
import 'package:moteur_gr/core/data/daos/sync_queue_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/models/sync_config.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/services/cloud_sync_service.dart';
import 'package:moteur_gr/core/services/sync_scheduler.dart';
import 'package:moteur_gr/features/auth/data/anonymous_id_service.dart';
import 'package:moteur_gr/features/auth/data/firebase_auth_service.dart';

/// UNE SEULE IDENTITE PAR LANCEMENT (tache 771).
///
/// LE DEFAUT MESURE, LE 10/10 SUR emulator-5560. Firebase s initialise, la
/// connexion anonyme reussit — et DEUX comptes anonymes naissent a 37
/// MILLISECONDES D ECART au meme lancement (2026-10-10T08:36:59.093Z et
/// .130Z). Le jeton d authentification porte alors un identifiant, les chemins
/// Firestore en visent un AUTRE. `firestore.rules` exigeant
/// `request.auth.uid == userId`, le serveur refuse — mot pour mot dans le
/// journal de l appareil : « Write failed at users/pY0i... :
/// PERMISSION_DENIED », « [RegistreConsentement] healthData :
/// permission-denied », « [FicheTechnique] ecriture impossible :
/// permission-denied ». Les regles sont JUSTES ; c est l application qui se
/// trompe d identite.
///
/// LA CAUSE, ET CE N EST PAS UN PROVIDER RECONSTRUIT. Il n y a qu un seul
/// `ProviderScope` (`main.dart`), donc UNE SEULE instance de
/// [FirebaseAuthService]. Mais DEUX appelants tirent `garantirUneIdentite()`
/// sur elle au demarrage, sans savoir l un de l autre :
///
///   1. `auth_provider.dart` — `unawaited(service.garantirUneIdentite())` dans
///      le `create` du provider, en fire-and-forget ;
///   2. `sync_scheduler.dart` — `await auth.garantirUneIdentite()` dans
///      `monteeEnBaseDemarreeProvider`, declenche par le `ref.read` qui vient
///      JUSTE de construire ce service.
///
/// Et `garantirUneIdentite()` lisait `currentUser`, le trouvait nul, puis
/// appelait `signInAnonymously()` : un controle-puis-agis que rien ne rendait
/// atomique. Le premier appel part et se suspend sur le reseau ; le second lit
/// `currentUser` AVANT que le premier ait pose quoi que ce soit, le trouve nul
/// a son tour, et ouvre un SECOND compte.
///
/// CE QUE CES GARDES TIENNENT :
///   - deux appels concurrents ne produisent QU UNE connexion ;
///   - l identifiant qui construit les chemins est celui DU JETON, jamais une
///     copie prise ailleurs — y compris quand la copie est fausse.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('une seule identite par lancement (tache 771)', () {
    test('deux appels concurrents ne produisent QU UNE connexion', () async {
      final auth = _AuthFaux();
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();
      addTearDown(() => _refermer(service, auth));

      // L ORDRE EXACT DU DEMARRAGE MESURE : le provider tire en
      // fire-and-forget, la montee en base attend — a 0 ms d ecart, et sans
      // qu aucun des deux sache que l autre existe.
      final premier = service.garantirUneIdentite();
      final second = service.garantirUneIdentite();
      final deux = await Future.wait([premier, second]);

      expect(
        auth.connexions,
        1,
        reason:
            'deux appels concurrents ont ouvert ${auth.connexions} '
            'compte(s) : une seule tentative doit etre en vol, les suivantes '
            'attendent son resultat au lieu d en lancer une autre',
      );
      expect(
        deux[0]!.uid,
        deux[1]!.uid,
        reason: 'les deux appelants doivent voir LA MEME identite',
      );
    });

    test('l identite rendue est celle du jeton, pas d un appel', () async {
      final auth = _AuthFaux();
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();
      addTearDown(() => _refermer(service, auth));

      final deux = await Future.wait([
        service.garantirUneIdentite(),
        service.garantirUneIdentite(),
      ]);

      // LE JETON EST LA SEULE AUTORITE. `accountId` lit l utilisateur courant
      // du SDK — exactement la source dont Firestore tire son jeton. Ce que
      // les appelants ont recu doit en DERIVER, sinon les donnees metier d un
      // compte partent sous le nom d un autre.
      final jeton = service.accountId;
      expect(jeton, isNotNull);
      for (final identite in deux) {
        expect(
          identite!.uid,
          AnonymousIdService.hashUserId(jeton!),
          reason:
              'l identite rendue (${identite.uid}) ne derive pas du jeton '
              '($jeton) : un appelant ecrirait sous un compte que le serveur '
              'n a pas authentifie',
        );
      }
    });

    test('un compte deja ouvert n en fait ouvrir aucun autre', () async {
      final auth = _AuthFaux()..poserUnCompteDejaOuvert('compte-du-matin');
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();
      addTearDown(() => _refermer(service, auth));

      await Future.wait([
        service.garantirUneIdentite(),
        service.garantirUneIdentite(),
      ]);

      expect(
        auth.connexions,
        0,
        reason: 'un compte de plus, c est un compte de trop (tache 631)',
      );
      expect(service.accountId, 'compte-du-matin');
    });

    test('une connexion refusee laisse une seconde tentative', () async {
      final auth = _AuthFaux()..refuserLaProchaine = true;
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();
      addTearDown(() => _refermer(service, auth));

      // Premiere vague : le reseau refuse. Elle ne doit pas lever, et elle ne
      // doit pas CONDAMNER l identite — sinon un premier lancement en zone
      // blanche laisserait le telephone sans compte pour toujours.
      final refusees = await Future.wait([
        service.garantirUneIdentite(),
        service.garantirUneIdentite(),
      ]);
      expect(refusees, everyElement(isNull));
      expect(auth.connexions, 1, reason: 'une seule tentative en vol');

      // Seconde vague, reseau revenu : elle aboutit.
      final obtenue = await service.garantirUneIdentite();
      expect(obtenue, isNotNull);
      expect(auth.connexions, 2);
    });
  });

  group('les chemins portent l identifiant du jeton (tache 771)', () {
    late AppDatabase db;
    late _ReseauFaux reseau;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      reseau = _ReseauFaux();
    });
    tearDown(() async {
      reseau.fermer();
      await db.close();
    });

    SyncScheduler fabriquer(
      _MonteeFausse nuage,
      Future<String?> Function() jeton,
    ) {
      return SyncScheduler(
        cloudSyncService: nuage,
        connectivityMonitor: reseau,
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        progressDao: ProgressDao(db),
        identiteDuJeton: jeton,
        observerLeCycleDeVie: false,
      );
    }

    test('armee sur un identifiant perime, elle ecrit sous le jeton', () async {
      final nuage = _MonteeFausse(SyncQueueDao(db));
      final montee = fabriquer(nuage, () async => 'compte-du-jeton');
      addTearDown(montee.stop);

      // ARMEE SUR UNE COPIE PERIMEE. C est la situation exacte du 10/10 : la
      // valeur retenue au moment de l armement n est plus celle que le serveur
      // authentifie quand l ecriture part.
      await montee.start(userId: 'compte-perime');
      await _laisserRetomber(montee);
      nuage.identifiantsVus.clear();
      await montee.monterMaintenant('garde 771');

      expect(
        nuage.identifiantsVus,
        isNotEmpty,
        reason: 'la passe n a rien tente : la garde ne prouverait rien',
      );
      expect(
        nuage.identifiantsVus,
        everyElement('compte-du-jeton'),
        reason:
            'les chemins ont porte ${nuage.identifiantsVus.toSet()} alors '
            'que le jeton dit compte-du-jeton : firestore.rules refuserait '
            'tout, exactement comme le 10/10',
      );
    });

    test('sans jeton, rien ne part sous l ancienne copie', () async {
      final nuage = _MonteeFausse(SyncQueueDao(db));
      final montee = fabriquer(nuage, () async => null);
      addTearDown(montee.stop);

      await montee.start(userId: 'compte-perime');
      await _laisserRetomber(montee);
      expect(await montee.monterMaintenant('garde 771'), 0);
      expect(
        nuage.identifiantsVus,
        isEmpty,
        reason:
            'plus de jeton veut dire plus d autorisation : ecrire sous la '
            'derniere copie connue serait se faire refuser, ou pire, ecrire '
            'chez quelqu un d autre',
      );
    });
  });
}

/// REFERME LE SERVICE SANS LAISSER D ERREUR DERRIERE SOI.
///
/// On laisse ARRIVER ce qui est en vol AVANT de fermer : une emission du faux
/// SDK qui atterrit sur un controller deja ferme leve APRES la fin du test, et
/// l erreur est imputee au suivant — la lecon exacte de la tache 561 (J3).
Future<void> _refermer(FirebaseAuthService service, _AuthFaux auth) async {
  await pumpEventQueue();
  await auth.fermer();
  service.dispose();
}

/// LAISSE RETOMBER LA PASSE DE DEMARRAGE. `start` la lance sans l attendre (le
/// premier ecran ne doit pas attendre le reseau) : sans ce temps mort, la passe
/// que la garde declenche ensuite serait DIFFEREE, et la garde mesurerait
/// l autre.
Future<void> _laisserRetomber(SyncScheduler montee) async {
  for (var i = 0; i < 200 && montee.enCours; i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  await pumpEventQueue();
}

// ===========================================================================
// LES DOUBLES. Il n y a ni `mockito` ni `firebase_auth_mocks` dans la pile, et
// on n en ajoute pas pour trois methodes : meme choix qu a la tache 635 pour
// la fausse Firestore, et meme forme (`implements` + `noSuchMethod`).
// ===========================================================================

class _UtilisateurFaux implements fb.User {
  _UtilisateurFaux(this.uid);

  @override
  final String uid;

  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdentificationFausse implements fb.UserCredential {
  _IdentificationFausse(this.user);

  @override
  final fb.User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// UN FAUX SDK D AUTHENTIFICATION QUI PREND DU TEMPS, et c est l essentiel : le
/// defaut du 10/10 ne vit QUE dans la fenetre d attente du reseau. Une
/// connexion instantanee ne reproduirait rien.
class _AuthFaux implements fb.FirebaseAuth {
  /// LE TEMPS DU RESEAU. C est pendant cette attente que le second appelant
  /// lisait `currentUser` a null et ouvrait un deuxieme compte.
  final Duration delai = const Duration(milliseconds: 20);

  /// Nombre de connexions REELLEMENT ouvertes. La mesure de la garde.
  int connexions = 0;

  /// Vrai pour que la prochaine connexion echoue, comme un premier lancement
  /// sans reseau.
  bool refuserLaProchaine = false;

  fb.User? _courant;
  final _flux = StreamController<fb.User?>.broadcast();

  void poserUnCompteDejaOuvert(String uid) => _courant = _UtilisateurFaux(uid);

  Future<void> fermer() => _flux.close();

  @override
  fb.User? get currentUser => _courant;

  @override
  Stream<fb.User?> authStateChanges() => _flux.stream;

  @override
  Future<fb.UserCredential> signInAnonymously() async {
    connexions++;
    final numero = connexions;
    if (refuserLaProchaine) {
      refuserLaProchaine = false;
      await Future<void>.delayed(delai);
      throw fb.FirebaseAuthException(code: 'network-request-failed');
    }
    await Future<void>.delayed(delai);
    final utilisateur = _UtilisateurFaux('compte-$numero');
    _courant = utilisateur;
    if (!_flux.isClosed) _flux.add(utilisateur);
    return _IdentificationFausse(utilisateur);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ReseauFaux implements ConnectivityMonitor {
  final _flux = StreamController<ConnectivityStatus>.broadcast();

  void fermer() => _flux.close();

  @override
  Future<ConnectivityStatus> checkStatus() async =>
      ConnectivityStatusValues.online;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _flux.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// UNE MONTEE QUI N ECRIT RIEN ET RETIENT SOUS QUEL NOM ON LUI A DEMANDE
/// D ECRIRE. C est la seule chose que ces deux gardes observent.
class _MonteeFausse implements CloudSyncService {
  _MonteeFausse(this.syncQueueDao);

  @override
  final SyncQueueDao syncQueueDao;

  /// Tous les identifiants de compte recus, dans l ordre.
  final List<String> identifiantsVus = [];

  CloudSyncResult _rien() => CloudSyncResult(
    status: CloudSyncStatusValues.success,
    syncedAt: DateTime.utc(2026, 10, 10),
  );

  @override
  Future<CloudSyncResult> catchUpOnReconnect(
    String userId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    identifiantsVus.add(userId);
    return _rien();
  }

  @override
  Future<CloudSyncResult> syncUserData(
    String userId,
    String trailId, {
    SyncConfig config = const SyncConfig(),
  }) async {
    identifiantsVus.add(userId);
    return _rien();
  }

  @override
  Future<CloudSyncResult> syncPastHikes(
    String userId, {
    String identifiantLocal = 'local',
  }) async {
    identifiantsVus.add(userId);
    return _rien();
  }

  @override
  Future<void> pushBatchHourly(String userId, String trailId) async {
    identifiantsVus.add(userId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
