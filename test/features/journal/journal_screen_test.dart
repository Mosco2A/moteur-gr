import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';

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
}
