import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/treks/presentation/widgets/resume_orphan_session_dialog.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// StepWays LOT 2, C4 §3 — dialog de REPRISE de session orpheline.
///
/// Verifie le rendu (titre / message / boutons localises), le retour du bon
/// [ResumeOrphanChoice] selon le bouton, et la NON-dismissibilite a la barriere
/// (au boot, l'utilisateur doit trancher — sinon l'orpheline reviendrait).
void main() {
  /// Monte un bouton qui ouvre le dialog et capture le choix renvoye.
  Widget harness(void Function(ResumeOrphanChoice?) onResult) {
    return TranslationProvider(
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final choice = await showResumeOrphanSessionDialog(context);
                  onResult(choice);
                },
                child: const Text('OPEN'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('affiche titre, message et les deux actions localises',
      (tester) async {
    await tester.pumpWidget(harness((_) {}));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsOneWidget,
    );
    expect(find.text(t.trekState.resumeOrphanDialog.title), findsOneWidget);
    expect(find.text(t.trekState.resumeOrphanDialog.message), findsOneWidget);
    expect(find.text(t.trekState.resumeOrphanDialog.resume), findsOneWidget);
    expect(find.text(t.trekState.resumeOrphanDialog.abandon), findsOneWidget);
  });

  testWidgets('Reprendre renvoie ResumeOrphanChoice.resume', (tester) async {
    ResumeOrphanChoice? result;
    await tester.pumpWidget(harness((c) => result = c));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('resume-orphan-resume')));
    await tester.pumpAndSettle();

    expect(result, ResumeOrphanChoice.resume);
    // Le dialog est referme.
    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsNothing,
    );
  });

  testWidgets('Abandonner renvoie ResumeOrphanChoice.abandon', (tester) async {
    ResumeOrphanChoice? result;
    await tester.pumpWidget(harness((c) => result = c));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('resume-orphan-abandon')));
    await tester.pumpAndSettle();

    expect(result, ResumeOrphanChoice.abandon);
  });

  testWidgets('non dismissible : un tap sur la barriere ne ferme pas',
      (tester) async {
    ResumeOrphanChoice? result;
    var resolved = false;
    await tester.pumpWidget(harness((c) {
      result = c;
      resolved = true;
    }));
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();

    // Tap hors du dialog (coin haut-gauche = barriere).
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    // Toujours affiche, aucun choix renvoye.
    expect(
      find.byKey(const ValueKey('resume-orphan-session-dialog')),
      findsOneWidget,
    );
    expect(resolved, isFalse);
    expect(result, isNull);
  });
}
