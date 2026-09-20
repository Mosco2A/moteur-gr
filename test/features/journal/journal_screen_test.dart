import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/daos/journal_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/journal/data/journal_repository.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/features/journal/providers/journal_providers.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Test E3.1c : ecran journal s affiche avec donnees mock.
void main() {
  testWidgets('JournalScreen affiche le titre et l etat vide', (tester) async {
    final db = AppDatabase(NativeDatabase.memory());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailIdProvider.overrideWithValue('sentier-bleu'),
        ],
        // AppHeader (Ph5/L6a) utilise GoRouter -> on heberge l'ecran dans un
        // GoRouter minimal (+ /my-treks pour l'accueil contextuel).
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/journal',
            routes: [
              GoRoute(
                path: '/journal',
                builder: (_, __) => const JournalScreen(trailId: 'sentier-bleu'),
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );

    // Attendre le chargement initial (CircularProgressIndicator)
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Attendre que le chargement se termine
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // Verifier que l ecran s affiche (Scaffold present)
    expect(find.byType(Scaffold), findsOneWidget);

    // Verifier le FAB d ajout
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Verifier l etat vide (icone livre)
    expect(find.byIcon(Icons.book_outlined), findsOneWidget);

    await db.close();
  });

  // -------------------------------------------------------------------------
  // R10 (retour Chris, LOT L10) — LE SELECTEUR D'ETAPE SUIT LE SENTIER
  //
  // Le menu deroulant « Etape » de la boite d'ajout de note etait rempli par un
  // `List.generate(16, ...)` : 16 est le compte du GR20. Sur un sentier
  // StepWays a 7 etapes, l'utilisateur pouvait rattacher une note aux etapes 8
  // a 16, qui n'existent pas — le moteur cessait d'etre generique.
  // -------------------------------------------------------------------------
  group('R10 — nombre d\'etapes du selecteur (sentier a 7 etapes)', () {
    const trailId = 'sentier-bleu';

    StageModel stage(int n) => StageModel(
          id: n,
          trailId: trailId,
          stageNumber: n,
          name: 'Etape $n',
          distanceKm: 10,
          elevationGainM: 500,
          elevationLossM: 400,
          startLat: 42.0,
          startLng: 9.0,
          endLat: 42.1,
          endLng: 9.1,
        );

    /// 7 etapes = le compte reel du Mare a Mare Centre (et non 16).
    final sevenStages = List.generate(7, (i) => stage(i + 1));

    test('journalStageCountProvider suit le nombre REEL d\'etapes', () async {
      final container = ProviderContainer(overrides: [
        stagesProvider(trailId).overrideWith((ref) async => sevenStages),
      ]);
      addTearDown(container.dispose);

      await container.read(stagesProvider(trailId).future);

      expect(container.read(journalStageCountProvider(trailId)), 7,
          reason: 'Ni 16 (GR20), ni le total declare : le compte reel');
    });

    test('repli sur TrailConfig.totalStages quand aucune etape n\'est chargee',
        () async {
      final container = ProviderContainer(overrides: [
        stagesProvider(trailId).overrideWith((ref) async => <StageModel>[]),
      ]);
      addTearDown(container.dispose);

      await container.read(stagesProvider(trailId).future);

      // Repli sur le sentier declare par defaut (jamais 16, jamais 0).
      final declared =
          container.read(trailConfigProvider.select((c) => c.totalStages));
      expect(container.read(journalStageCountProvider(trailId)), declared);
      expect(container.read(journalStageCountProvider(trailId)),
          greaterThanOrEqualTo(1),
          reason: 'Un menu deroulant vide leverait une assertion Flutter');
    });

    testWidgets('le menu deroulant propose 7 etapes, et JAMAIS une 8e',
        (tester) async {
      LocaleSettings.setLocaleRaw('fr');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailIdProvider.overrideWithValue(trailId),
            stagesProvider(trailId).overrideWith((ref) async => sevenStages),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/journal',
                routes: [
                  GoRoute(
                    path: '/journal',
                    builder: (_, __) => const JournalScreen(trailId: trailId),
                  ),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Ouvrir la boite « Nouvelle note » puis derouler le selecteur d'etape.
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();

      final stageLabel = t.journal.stage;
      // Les 7 etapes du sentier sont proposees...
      expect(find.text('$stageLabel 1'), findsWidgets);
      expect(find.text('$stageLabel 7'), findsWidgets);
      // ... et AUCUNE etape fantome au-dela (le `16` en dur est parti).
      expect(find.text('$stageLabel 8'), findsNothing);
      expect(find.text('$stageLabel 16'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // QA Skynet (LOT L10) — RENDU D'UNE ENTREE AVEC PHOTO DANS LA LISTE
  //
  // Le rendu initial empilait la photo AVANT le texte, sur 200 px de haut :
  // l'image mangeait la carte, se coupait brutalement en bas et rejetait la
  // note tout en bas, collee au bord. PARITE GR20 (`trek_journal_screen.dart`)
  // : le TEXTE vient d'abord, la miniature FERME la carte, sur 120 px cadres
  // par un SizedBox.
  // -------------------------------------------------------------------------
  group('QA L10 — rendu d\'une entree de journal avec photo', () {
    const trailId = 'sentier-bleu';
    const longNote =
        'Montee raide des le depart puis bascule sur le versant nord, '
        'brouillard jusqu au col et eclaircie magnifique a l arrivee.';

    /// Hauteur de la miniature (parite GR20) — doit rester bornee.
    const photoHeight = 120.0;

    Finder photoFrame() => find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == photoHeight,
        );

    Future<void> pumpJournal(WidgetTester tester, AppDatabase db) async {
      LocaleSettings.setLocaleRaw('fr');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailIdProvider.overrideWithValue(trailId),
            stagesProvider(trailId).overrideWith((ref) async => <StageModel>[]),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/journal',
                routes: [
                  GoRoute(
                    path: '/journal',
                    builder: (_, __) => const JournalScreen(trailId: trailId),
                  ),
                  GoRoute(
                      path: '/my-treks', builder: (_, __) => const SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }

    testWidgets('le TEXTE est AU-DESSUS de la photo, dans un cadre borne',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await JournalRepository(JournalDao(db)).addPhotoNote(
        trailId: trailId,
        stageNumber: 2,
        text: longNote,
        photoPath: '/inexistant/photo.jpg',
        photoSizeBytes: 4096,
      );

      await pumpJournal(tester, db);

      // La note est lisible...
      expect(find.text(longNote), findsOneWidget);
      // ... et la photo vit dans un cadre de hauteur BORNEE (jamais 200, et
      // jamais la hauteur intrinseque de l'image).
      expect(photoFrame(), findsOneWidget);
      expect(tester.getSize(photoFrame()).height, photoHeight);

      // L'ORDRE est le point du retour Skynet : le texte AVANT la photo.
      expect(
        tester.getTopLeft(find.text(longNote)).dy,
        lessThan(tester.getTopLeft(photoFrame()).dy),
        reason: 'La note doit se lire au-dessus de la miniature, pas sous elle',
      );
    });

    testWidgets('une entree SANS photo garde son rendu (aucun cadre image)',
        (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await JournalRepository(JournalDao(db)).addNote(
        trailId: trailId,
        stageNumber: 1,
        text: 'Note simple sans photo',
      );

      await pumpJournal(tester, db);

      expect(find.text('Note simple sans photo'), findsOneWidget);
      // Non-regression : aucun cadre photo ne s'invite sur une note texte.
      expect(photoFrame(), findsNothing);
    });
  });
}
