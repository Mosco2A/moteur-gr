// D4C-03 — Tests widget du formulaire « Signaler » (DSA art 16, design #86166).
//
// Couvre :
//   - les 5 motifs (art 16) sont affiches et selectionnables ;
//   - les champs detail / contact / bonne foi sont presents ;
//   - envoi VALIDE : le ModerationService recoit une notification art 16
//     complete (motif compose, contact, bonne foi) et la sheet se ferme ;
//   - envoi INVALIDE (bonne foi non cochee) : aucune notification creee,
//     message d'erreur affiche (l'erreur n'est pas masquee).
//
// Le ModerationService reel est branche ; seul le store est un faux en memoire
// (override de moderationStoreProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/moderation_service.dart';
import 'package:moteur_gr/features/moderation/presentation/report_content_sheet.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Faux store en memoire : capture les notifications creees.
class _FakeStore implements ModerationStore {
  final List<ModerationReport> saved = <ModerationReport>[];

  @override
  Future<void> saveReport(ModerationReport report) async => saved.add(report);

  @override
  Future<void> updateReport(ModerationReport report) async {}

  @override
  Future<void> applyContentState(
    ModeratedContentType contentType,
    String contentRef,
    ContentModerationState state,
  ) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Translations tr = AppLocale.fr.buildSync();
  late _FakeStore store;

  setUp(() => store = _FakeStore());

  Widget host() => ProviderScope(
        overrides: [moderationStoreProvider.overrideWithValue(store)],
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => Center(
                  child: ElevatedButton(
                    onPressed: () => showReportSheet(
                      context,
                      contentType: ModeratedContentType.waypoint,
                      contentRef: 'wp-42',
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  group('ReportContentSheet — DSA art 16', () {
    testWidgets('affiche les 5 motifs et les champs art 16', (tester) async {
      await openSheet(tester);

      expect(find.text(tr.moderation.reportTitle), findsOneWidget);
      for (final reason in ['illegal', 'harassment', 'spam', 'dangerous', 'other']) {
        expect(
          find.byKey(ValueKey('report-reason-$reason')),
          findsOneWidget,
          reason: 'motif $reason manquant',
        );
      }
      expect(find.byKey(const ValueKey('report-contact')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-good-faith')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-submit')), findsOneWidget);
    });

    testWidgets('envoi VALIDE cree une notification art 16 complete',
        (tester) async {
      await openSheet(tester);

      // Choisit un motif different du defaut (sheet defilante : on remonte
      // chaque cible dans le viewport avant de la toucher).
      final reason = find.byKey(const ValueKey('report-reason-harassment'));
      await tester.ensureVisible(reason);
      await tester.tap(reason);
      await tester.pump();
      // Detail libre + contact + bonne foi.
      await tester.enterText(
          find.byKey(const ValueKey('report-details')), 'propos haineux');
      await tester.enterText(
          find.byKey(const ValueKey('report-contact')), 'temoin@example.com');
      final goodFaith = find.byKey(const ValueKey('report-good-faith'));
      await tester.ensureVisible(goodFaith);
      await tester.tap(goodFaith);
      await tester.pump();

      final submit = find.byKey(const ValueKey('report-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // Une notification valide a ete creee, mentions art 16 presentes.
      expect(store.saved, hasLength(1));
      final report = store.saved.single;
      expect(report.contentType, ModeratedContentType.waypoint);
      expect(report.contentRef, 'wp-42');
      expect(report.bonneFoi, isTrue);
      expect(report.notifierContact, 'temoin@example.com');
      expect(report.motif, contains(tr.moderation.reasons.harassment));
      expect(report.motif, contains('propos haineux'));
      // La sheet s'est fermee (retour a l'ecran d'origine).
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('envoi INVALIDE (bonne foi non cochee) : refuse + erreur',
        (tester) async {
      await openSheet(tester);

      await tester.enterText(
          find.byKey(const ValueKey('report-contact')), 'temoin@example.com');
      // On NE coche PAS la bonne foi.
      final submit = find.byKey(const ValueKey('report-submit'));
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();

      // Aucune notification creee, message d'erreur affiche (pas masque).
      expect(store.saved, isEmpty);
      expect(find.text(tr.moderation.errorRequired), findsOneWidget);
      // La sheet reste ouverte.
      expect(find.text(tr.moderation.reportTitle), findsOneWidget);
    });
  });
}
