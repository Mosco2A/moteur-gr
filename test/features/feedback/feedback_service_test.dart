import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/feedback_queue_dao.dart';
import 'package:moteur_gr/features/feedback/data/feedback_service.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Mock ConnectivityMonitor qui retourne un statut configurable.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  FakeConnectivityMonitor({this.fakeStatus = ConnectivityStatusValues.online})
    : super(connectivity: Connectivity());

  String fakeStatus;

  @override
  Future<ConnectivityStatus> checkStatus() async => fakeStatus;
}

/// Destinataire de test : note ce qui lui est reellement remis (tache 596).
class _PuitsDeTest implements FeedbackSink {
  final List<FeedbackQueueData> recus = <FeedbackQueueData>[];

  @override
  Future<void> envoyer(FeedbackQueueData feedback) async => recus.add(feedback);
}

/// Tests du service feedback offline-first.
void main() {
  late AppDatabase db;
  late FeedbackQueueDao dao;
  late FakeConnectivityMonitor monitor;
  late FeedbackService service;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dao = FeedbackQueueDao(db);
    monitor = FakeConnectivityMonitor();
    service = FeedbackService(dao: dao, connectivityMonitor: monitor);
  });

  tearDown(() async {
    await db.close();
  });

  group('FeedbackService', () {
    // TACHE 596 (C1) — CES TROIS TESTS CONSACRAIENT LE FAUX SUCCES.
    //
    // Ils verifiaient qu'un retour etait « marque envoye apres flush online »
    // alors que `_sendToBackend` attendait 10 ms et rendait `true` sans qu'un
    // octet ne quitte le telephone. Le test passait au vert sur une simulation
    // — c'est exactement comme ca qu'un mensonge tient vingt fois de suite.
    // Ils disent desormais ce qui se passe VRAIMENT, avec et sans destinataire.

    test(
      'EN LIGNE MAIS SANS DESTINATAIRE : le retour est GARDE, pas envoye',
      () async {
        monitor.fakeStatus = ConnectivityStatusValues.online;

        final issue = await service.submit(
          trailId: 'sentier-bleu',
          category: FeedbackCategory.bug,
          content: 'Crash au demarrage de la carte',
          rating: 2,
        );

        expect(issue, FeedbackIssue.gardeLocalement);
        final pending = await dao.getPending();
        expect(
          pending,
          hasLength(1),
          reason: 'sans destinataire, le retour DOIT rester sur le telephone',
        );
      },
    );

    test(
      'EN LIGNE AVEC DESTINATAIRE : le retour part et quitte la file',
      () async {
        monitor.fakeStatus = ConnectivityStatusValues.online;
        final puits = _PuitsDeTest();
        final avecPuits = FeedbackService(
          dao: dao,
          connectivityMonitor: monitor,
          sink: puits,
        );

        final issue = await avecPuits.submit(
          trailId: 'sentier-bleu',
          category: FeedbackCategory.bug,
          content: 'Crash au demarrage de la carte',
          rating: 2,
        );

        expect(issue, FeedbackIssue.envoye);
        expect(puits.recus, hasLength(1));
        expect(await dao.getPending(), isEmpty);
      },
    );

    test('submit stocke en Drift et reste pending quand hors ligne', () async {
      // Arrange — offline
      monitor.fakeStatus = ConnectivityStatusValues.offline;

      // Act
      final issue = await service.submit(
        trailId: 'sentier-bleu',
        category: FeedbackCategory.suggestion,
        content: 'Ajouter un mode sombre',
      );

      // Assert — feedback reste en attente
      expect(issue, FeedbackIssue.gardeLocalement);
      final pending = await dao.getPending();
      expect(pending.length, 1);
      expect(pending.first.feedbackType, FeedbackCategory.suggestion);
      expect(pending.first.content, 'Ajouter un mode sombre');
    });

    test(
      'flush envoie les feedbacks pending quand en ligne ET adresses',
      () async {
        // Arrange — stocker offline
        monitor.fakeStatus = ConnectivityStatusValues.offline;
        final puits = _PuitsDeTest();
        final avecPuits = FeedbackService(
          dao: dao,
          connectivityMonitor: monitor,
          sink: puits,
        );
        await avecPuits.submit(
          trailId: 'sentier-bleu',
          category: FeedbackCategory.compliment,
          content: 'Super app !',
          rating: 5,
        );
        await avecPuits.submit(
          trailId: 'sentier-bleu',
          category: FeedbackCategory.bug,
          content: 'GPS instable en foret',
        );
        expect(await avecPuits.pendingCount(), 2);

        // Act — passer en ligne et flush
        monitor.fakeStatus = ConnectivityStatusValues.online;
        final sent = await avecPuits.flush();

        // Assert
        expect(sent, 2);
        expect(puits.recus, hasLength(2));
        expect(await avecPuits.pendingCount(), 0);
      },
    );

    test('flush retourne 0 quand hors ligne', () async {
      monitor.fakeStatus = ConnectivityStatusValues.offline;
      await service.submit(
        trailId: 'sentier-bleu',
        category: FeedbackCategory.bug,
        content: 'Test offline',
      );

      final sent = await service.flush();
      expect(sent, 0);
      expect(await service.pendingCount(), 1);
    });

    test('FeedbackCategory.fromString valide les categories', () {
      expect(FeedbackCategory.fromString('bug'), FeedbackCategory.bug);
      expect(
        FeedbackCategory.fromString('suggestion'),
        FeedbackCategory.suggestion,
      );
      expect(
        FeedbackCategory.fromString('compliment'),
        FeedbackCategory.compliment,
      );
      // Categorie inconnue → fallback
      expect(FeedbackCategory.fromString('troll'), FeedbackCategory.fallback);
      expect(FeedbackCategory.fromString(''), FeedbackCategory.fallback);
    });
  });
}
