// D4C-03 — Tests widget de l'ecran PLAINTES (DSA art 20, design #86166).
//
// Couvre :
//   - depot d'une plainte valide : le ComplaintService recoit l'expose et la
//     reference du contenu, l'ecran se ferme ;
//   - expose vide : aucune plainte deposee, message d'erreur affiche.
//
// Le ComplaintService reel est branche ; seul le sink est un faux en memoire
// (override de complaintSinkProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/complaint_service.dart';
import 'package:moteur_gr/core/services/moderation_service.dart';
import 'package:moteur_gr/features/moderation/presentation/complaint_screen.dart';
import 'package:moteur_gr/features/moderation/providers/moderation_ui_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Faux sink en memoire : capture les plaintes deposees.
class _FakeSink implements ComplaintSink {
  final List<ModerationComplaint> saved = <ModerationComplaint>[];

  @override
  Future<void> saveComplaint(ModerationComplaint complaint) async =>
      saved.add(complaint);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Translations tr = AppLocale.fr.buildSync();
  late _FakeSink sink;

  setUp(() => sink = _FakeSink());

  Widget host() => ProviderScope(
        overrides: [complaintSinkProvider.overrideWithValue(sink)],
        child: TranslationProvider(
          child: const MaterialApp(
            home: ComplaintScreen(
              contentType: ModeratedContentType.waypoint,
              contentRef: 'wp-7',
            ),
          ),
        ),
      );

  group('ComplaintScreen — DSA art 20', () {
    testWidgets('depot valide : la plainte est transmise au service',
        (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('complaint-expose')),
        'Mon contenu est licite, je conteste le retrait.',
      );
      await tester.tap(find.byKey(const ValueKey('complaint-submit')));
      await tester.pumpAndSettle();

      expect(sink.saved, hasLength(1));
      final complaint = sink.saved.single;
      expect(complaint.contentType, ModeratedContentType.waypoint);
      expect(complaint.contentRef, 'wp-7');
      expect(complaint.expose,
          'Mon contenu est licite, je conteste le retrait.');
      expect(complaint.status, 'ouverte');
    });

    testWidgets('expose vide : refuse + message d erreur', (tester) async {
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('complaint-submit')));
      await tester.pumpAndSettle();

      expect(sink.saved, isEmpty);
      expect(find.text(tr.moderation.complaintEmpty), findsOneWidget);
    });
  });
}
