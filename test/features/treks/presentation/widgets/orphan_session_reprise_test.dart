import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/trek/data/trek_session_manager.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/session_recovery_provider.dart';
import 'package:moteur_gr/features/treks/presentation/widgets/orphan_session_reprise.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// StepWays LOT 2, C4 §3 — DECLENCHEMENT de la reprise orpheline au boot.
///
/// Verifie que [OrphanSessionReprise], insere sous l'arbre route, presente le
/// dialog quand une session orpheline est detectee ([pendingSessionProvider]),
/// et applique le bon effet :
///   * Reprendre  -> ecrit selectedTrailIdProvider = trailId + navigue /home ;
///   * Abandonner -> solde la session en base (status=abandoned) ;
///   * aucune orpheline -> pas de dialog (transparent).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  const trailId = 'mare-a-mare-centre';

  TrekSession orphan({String id = 'orphan-1', String status = 'active'}) =>
      TrekSession(
        id: id,
        trailId: trailId,
        startedAt: DateTime.now().subtract(const Duration(hours: 2)),
        status: status,
      );

  /// Container cable sur la DB in-memory + une session orpheline eventuelle.
  /// [pending] null => aucune orpheline detectee.
  ProviderContainer makeContainer(PendingSession? pending) {
    final container = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      pendingSessionProvider.overrideWith((ref) async => pending),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  /// Enveloppe [OrphanSessionReprise] sous un router minimal ; /home rend un
  /// marqueur pour observer la navigation « Reprendre ».
  Widget wrap(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/boot',
      routes: [
        GoRoute(
          path: '/boot',
          builder: (_, __) => const OrphanSessionReprise(
            child: Scaffold(body: Text('BOOT_CHILD')),
          ),
        ),
        GoRoute(path: '/home', builder: (_, __) => const Text('HOME_STUB')),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('aucune session orpheline -> pas de dialog', (tester) async {
    await tester.pumpWidget(wrap(makeContainer(null)));
    await tester.pumpAndSettle();

    expect(find.text('BOOT_CHILD'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsNothing,
    );
  });

  testWidgets('session orpheline detectee -> dialog affiche', (tester) async {
    await tester.pumpWidget(wrap(makeContainer(
      PendingSession(session: orphan(), age: const Duration(hours: 2)),
    )));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsOneWidget,
    );
  });

  testWidgets('Reprendre -> ecrit selectedTrailId + navigue /home',
      (tester) async {
    final container = makeContainer(
      PendingSession(session: orphan(), age: const Duration(hours: 2)),
    );
    // Etat initial different pour prouver l'ecriture.
    container.read(selectedTrailIdProvider.notifier).state = 'autre';

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('resume-orphan-resume')));
    await tester.pumpAndSettle();

    expect(container.read(selectedTrailIdProvider), trailId);
    expect(find.text('HOME_STUB'), findsOneWidget);
  });

  testWidgets('Abandonner -> session soldee en base (status=abandoned)',
      (tester) async {
    // La session orpheline existe en base (comme apres un crash) : on doit
    // pouvoir la relire soldee apres l'abandon.
    final session = orphan();
    await db.trekSessionsDao.upsertSession(session);

    final container = makeContainer(
      PendingSession(session: session, age: const Duration(hours: 2)),
    );

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('resume-orphan-abandon')));
    await tester.pumpAndSettle();

    // Dialog referme + session soldee `abandoned` (jamais fully walked).
    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsNothing,
    );
    final restored = await db.trekSessionsDao.getById(session.id);
    expect(restored, isNotNull);
    expect(restored!.status, 'abandoned');
    expect(restored.parcoursFullyWalked, isFalse);
    expect(restored.finishedAt, isNotNull);
    // Plus aucune session « en cours » (invariant C4 restaure).
    final ongoing = await db.trekSessionsDao.findActiveSessions();
    expect(ongoing, isEmpty);
  });

  testWidgets('le dialog ne se represente pas apres traitement',
      (tester) async {
    final session = orphan();
    await db.trekSessionsDao.upsertSession(session);
    final container = makeContainer(
      PendingSession(session: session, age: const Duration(hours: 2)),
    );

    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('resume-orphan-abandon')));
    await tester.pumpAndSettle();

    // Une reconstruction ne doit pas rouvrir un dialog pour la meme session.
    await tester.pump();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsNothing,
    );
  });
}
