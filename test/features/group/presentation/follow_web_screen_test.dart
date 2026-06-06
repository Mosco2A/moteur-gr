import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:moteur_gr/features/group/presentation/follow_web_screen.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests de la page de suivi web (E4.12a).
///
/// Test 1: la page charge avec le header et le statut.
/// Test 2: sans session valide (Firebase indisponible), l ecran
/// d erreur lien invalide s affiche. Textes via cles Slang.
void main() {
  group('FollowWebScreen', () {
    /// Helper: cree un ProviderScope avec Firebase indisponible.
    Widget buildTestWidget(String shareCode) {
      return ProviderScope(
        overrides: [
          firebaseServiceProvider.overrideWithValue(
            FirebaseService.testOnly(isAvailable: false),
          ),
        ],
        child: MaterialApp(
          home: FollowWebScreen(shareCode: shareCode),
        ),
      );
    }

    testWidgets('affiche le header de suivi en direct', (tester) async {
      await tester.pumpWidget(buildTestWidget('XK9P2L'));
      await tester.pumpAndSettle();

      // Header present avec le titre i18n
      expect(find.text(t.follow.title), findsOneWidget);

      // Firebase indisponible => ecran erreur affiche
      expect(find.text(t.follow.invalidLink), findsOneWidget);
      expect(find.byIcon(Icons.link_off), findsOneWidget);
    });

    testWidgets('sans shareCode affiche ecran erreur', (tester) async {
      await tester.pumpWidget(buildTestWidget(''));
      await tester.pumpAndSettle();

      // Meme sans shareCode, le widget se construit
      expect(find.text(t.follow.title), findsOneWidget);
      // Firebase indisponible => erreur
      expect(find.text(t.follow.invalidLink), findsOneWidget);
      expect(find.text(t.follow.invalidLinkHint), findsOneWidget);
    });
  });
}
