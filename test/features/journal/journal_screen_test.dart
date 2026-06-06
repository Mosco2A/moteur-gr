import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        child: const MaterialApp(
          home: JournalScreen(trailId: 'sentier-bleu'),
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
