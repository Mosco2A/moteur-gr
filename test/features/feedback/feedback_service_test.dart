import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
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
    test('submit stocke en Drift puis marque envoye quand en ligne', () async {
      // Arrange — online
      monitor.fakeStatus = ConnectivityStatusValues.online;

      // Act — soumettre un feedback
      final id = await service.submit(
        trailId: 'gr20',
        category: FeedbackCategory.bug,
        content: 'Crash au demarrage de la carte',
        rating: 2,
      );

      // Assert — feedback insere
      expect(id, greaterThan(0));

      // Le flush auto (en ligne) a du marquer le feedback comme envoye
      final pending = await dao.getPending();
      expect(pending, isEmpty,
          reason: 'Le feedback doit etre marque envoye apres flush online');
    });

    test('submit stocke en Drift et reste pending quand hors ligne', () async {
      // Arrange — offline
      monitor.fakeStatus = ConnectivityStatusValues.offline;

      // Act
      final id = await service.submit(
        trailId: 'gr20',
        category: FeedbackCategory.suggestion,
        content: 'Ajouter un mode sombre',
      );

      // Assert — feedback reste en attente
      expect(id, greaterThan(0));
      final pending = await dao.getPending();
      expect(pending.length, 1);
      expect(pending.first.feedbackType, FeedbackCategory.suggestion);
      expect(pending.first.content, 'Ajouter un mode sombre');
    });

    test('flush envoie les feedbacks pending quand en ligne', () async {
      // Arrange — stocker offline
      monitor.fakeStatus = ConnectivityStatusValues.offline;
      await service.submit(
        trailId: 'gr20',
        category: FeedbackCategory.compliment,
        content: 'Super app !',
        rating: 5,
      );
      await service.submit(
        trailId: 'gr20',
        category: FeedbackCategory.bug,
        content: 'GPS instable en foret',
      );
      expect(await service.pendingCount(), 2);

      // Act — passer en ligne et flush
      monitor.fakeStatus = ConnectivityStatusValues.online;
      final sent = await service.flush();

      // Assert
      expect(sent, 2);
      expect(await service.pendingCount(), 0);
    });

    test('flush retourne 0 quand hors ligne', () async {
      monitor.fakeStatus = ConnectivityStatusValues.offline;
      await service.submit(
        trailId: 'gr20',
        category: FeedbackCategory.bug,
        content: 'Test offline',
      );

      final sent = await service.flush();
      expect(sent, 0);
      expect(await service.pendingCount(), 1);
    });

    test('FeedbackCategory.fromString valide les categories', () {
      expect(FeedbackCategory.fromString('bug'), FeedbackCategory.bug);
      expect(FeedbackCategory.fromString('suggestion'), FeedbackCategory.suggestion);
      expect(FeedbackCategory.fromString('compliment'), FeedbackCategory.compliment);
      // Categorie inconnue → fallback
      expect(FeedbackCategory.fromString('troll'), FeedbackCategory.fallback);
      expect(FeedbackCategory.fromString(''), FeedbackCategory.fallback);
    });
  });
}
