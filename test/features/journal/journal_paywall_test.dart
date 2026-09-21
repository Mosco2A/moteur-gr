import 'dart:async';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Correctif L7-3 — LE JOURNAL EST VRAIMENT VERROUILLE.
///
/// Ce que ces tests protegent n'est pas l'existence d'un bandeau, c'est le
/// fait que le contenu du journal NE S'AFFICHE PAS quand le sentier n'est pas
/// debloque. L'audit initial proposait de recopier la gate de la reference :
/// elle ne bloque rien, elle decore. Et il proposait de s'appuyer sur le
/// drapeau `hasJournal`, qui n'est calcule par personne.
void main() {
  const trailId = 'sentier-bleu';
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());

  Widget ecran({required AsyncValue<bool> acces}) {
    return ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailIdProvider.overrideWithValue(trailId),
        isDemoModeProvider(trailId).overrideWith((ref) async {
          return acces.when(
            data: (v) => v,
            loading: () => Completer<bool>().future,
            error: (e, s) => Future<bool>.error(e),
          );
        }),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/journal',
          routes: [
            GoRoute(
              path: '/journal',
              builder: (_, __) => const JournalScreen(trailId: trailId),
            ),
            GoRoute(
              path: '/my-treks',
              builder: (_, __) => const Scaffold(body: Text('treks')),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('en mode demo : le journal est VERROUILLE, aucune entree, aucun '
      'bouton d ajout', (tester) async {
    await tester.pumpWidget(ecran(acces: const AsyncData(true)));
    await tester.pump();
    await tester.pump();

    expect(find.text(t.journal.lockedTitle), findsOneWidget);
    expect(find.text(t.journal.lockedUnlock), findsOneWidget);
    // On n ecrit pas dans un journal verrouille.
    expect(find.byType(FloatingActionButton), findsNothing);
    // Et on n y lit rien non plus : meme l etat vide du journal ouvert est
    // absent, sinon le verrou laisserait deviner le contenu.
    expect(find.text(t.journal.empty), findsNothing);
  });

  testWidgets('sentier debloque : le journal s ouvre normalement',
      (tester) async {
    await tester.pumpWidget(ecran(acces: const AsyncData(false)));
    await tester.pump();
    await tester.pump();

    expect(find.text(t.journal.lockedTitle), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('FAIL-CLOSED : tant que l acces est indetermine, le contenu ne '
      's affiche pas', (tester) async {
    await tester.pumpWidget(ecran(acces: const AsyncLoading()));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    // Le titre de l ecran reste la : on ne cache pas la navigation.
    expect(find.text(t.journal.title), findsWidgets);
  });

  testWidgets('FAIL-CLOSED : acces en erreur = verrouille, jamais ouvert',
      (tester) async {
    await tester.pumpWidget(
      ecran(acces: AsyncError(Exception('droits illisibles'), StackTrace.empty)),
    );
    await tester.pumpAndSettle();

    expect(find.text(t.journal.lockedTitle), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  // -------------------------------------------------------------------------
  // AUDIT DES SIX DRAPEAUX — demande explicite du correctif L7-3, pour ne pas
  // rejouer le meme audit dans un mois.
  // -------------------------------------------------------------------------
  group('promesses de monetisation : qui est reellement branche', () {
    /// Contenu d un fichier SANS ses commentaires de documentation : un
    /// docstring qui NOMME une API ne la consomme pas. Sans ce filtrage, le
    /// journal se signalerait lui-meme, lui dont le docstring explique
    /// justement pourquoi il ne s appuie PAS sur ces drapeaux.
    String lireCodeSeul(String chemin) => File(chemin)
        .readAsLinesSync()
        .where((l) => !l.trimLeft().startsWith('//'))
        .join(' ');

    List<String> fichiersDeLib() => Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.path)
        .toList();

    test('TrailFeatures et featuresForTrail restent un CUL-DE-SAC : aucun '
        'ecran ne les consulte', () {
      final consommateurs = fichiersDeLib()
          .where((p) => !p.endsWith('monetization_service.dart'))
          .where((p) {
            final c = lireCodeSeul(p);
            return c.contains('featuresForTrail(') ||
                c.contains('getTrialFeatures(') ||
                c.contains('getPremiumFeatures(');
          })
          .toList();

      expect(
        consommateurs,
        isEmpty,
        reason: 'Si ce test tombe, quelqu un vient de brancher la structure '
            'TrailFeatures. Ce n est pas interdit — mais il faut alors '
            'trancher : soit elle devient la source d acces et isDemoModeProvider '
            's aligne dessus, soit elle disparait. Les deux coexistant, on '
            'obtient deux verites d acces qui divergeront.',
      );
    });

    test('la SOURCE UNIQUE d acces reste isDemoModeProvider, et on sait qui '
        'l utilise', () {
      final ecrans = fichiersDeLib()
          .where((p) => p.contains('presentation'))
          .where((p) => lireCodeSeul(p).contains('isDemoModeProvider('))
          .map((p) => p.split(RegExp(r'[\\/]')).last)
          .toList()
        ..sort();

      // Etat constate au correctif L7-3 : l entrainement (verrou ecrit en
      // cycle precedent) et le journal (ce correctif). Les autres promesses du
      // pack — pub en mode gratuit, tracking GPS, quota de suiveurs — n ont
      // AUCUN verrou a ce jour ; le diplome, lui, est garde par un critere de
      // MERITE (finisher) et non par l achat, ce qui est un choix assume.
      expect(
        ecrans,
        containsAll(<String>['journal_screen.dart', 'training_screen.dart']),
      );
    });
  });
}
