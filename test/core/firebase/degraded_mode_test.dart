import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/firebase/cloud_unavailable_notice.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/group/presentation/group_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Tests du mode degrade sans Firebase (P1-4 audit #327).
///
/// Le chemin isAvailable=false doit afficher un ETAT EXPLICITE :
/// - GroupScreen : notice mode local a la place du formulaire
///   creer/rejoindre (qui ne pourrait qu echouer) ;
/// - ProfileScreen : plus de spinner infini quand l utilisateur est
///   null, et notice cloud a la place de la tuile Google ;
/// - cles Slang t.cloud.* presentes dans les 5 langues.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    LocaleSettings.setLocaleRaw('fr');
  });

  Widget wrap(
    Widget child, {
    required bool firebaseAvailable,
    List<Override> extra = const [],
  }) {
    return ProviderScope(
      overrides: [
        firebaseServiceProvider.overrideWithValue(
          FirebaseService.testOnly(isAvailable: firebaseAvailable),
        ),
        ...extra,
      ],
      child: TranslationProvider(
        child: MaterialApp(home: child),
      ),
    );
  }

  group('P1-4 — etats explicites sans Firebase', () {
    test('cles Slang cloud.* presentes dans les 5 langues', () {
      for (final locale in ['fr', 'en', 'de', 'es', 'it']) {
        LocaleSettings.setLocaleRaw(locale);
        expect(t.cloud.localModeTitle, isNotEmpty,
            reason: 'localModeTitle manquant pour $locale');
        expect(t.cloud.localModeBody, isNotEmpty,
            reason: 'localModeBody manquant pour $locale');
        expect(t.cloud.statusSection, isNotEmpty,
            reason: 'statusSection manquant pour $locale');
        expect(t.cloud.statusActive, isNotEmpty,
            reason: 'statusActive manquant pour $locale');
        expect(t.cloud.statusActiveDesc, isNotEmpty,
            reason: 'statusActiveDesc manquant pour $locale');
        expect(t.cloud.statusLocal, isNotEmpty,
            reason: 'statusLocal manquant pour $locale');
        expect(t.cloud.statusLocalDesc, isNotEmpty,
            reason: 'statusLocalDesc manquant pour $locale');
      }
      LocaleSettings.setLocaleRaw('fr');
    });

    testWidgets('GroupScreen sans Firebase : notice explicite, pas de formulaire',
        (tester) async {
      await tester.pumpWidget(wrap(
        const GroupScreen(trailId: 'sentier-bleu'),
        firebaseAvailable: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CloudUnavailableNotice), findsOneWidget);
      expect(find.text(t.cloud.localModeTitle), findsOneWidget);
      // Le formulaire creer/rejoindre ne doit PAS etre propose.
      expect(find.text('Creer un groupe'), findsNothing);
      expect(find.text('Rejoindre'), findsNothing);
      // Aucun spinner.
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('GroupScreen avec Firebase : formulaire normal conserve',
        (tester) async {
      await tester.pumpWidget(wrap(
        const GroupScreen(trailId: 'sentier-bleu'),
        firebaseAvailable: true,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CloudUnavailableNotice), findsNothing);
      expect(find.text('Creer un groupe'), findsOneWidget);
    });

    testWidgets(
        'ProfileScreen utilisateur null : message explicite, pas de spinner infini',
        (tester) async {
      await tester.pumpWidget(wrap(
        const ProfileScreen(),
        firebaseAvailable: false,
        extra: [
          currentUserProvider.overrideWith(
            (ref) => Stream<AuthUser?>.value(null),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text(t.auth.errorLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
        'ProfileScreen anonyme sans Firebase : notice cloud, pas de tuile Google',
        (tester) async {
      const user = AuthUser(
        uid: 'local-0001',
        authMethod: AuthMethodValues.anonymous,
      );
      await tester.pumpWidget(wrap(
        const ProfileScreen(),
        firebaseAvailable: false,
        extra: [
          currentUserProvider.overrideWith(
            (ref) => Stream<AuthUser?>.value(user),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CloudUnavailableNotice), findsOneWidget);
      expect(find.text(t.auth.signInGoogle), findsNothing);
    });

    testWidgets(
        'ProfileScreen anonyme avec Firebase : tuile Google conservee',
        (tester) async {
      const user = AuthUser(
        uid: 'cloud-0001',
        authMethod: AuthMethodValues.anonymous,
      );
      await tester.pumpWidget(wrap(
        const ProfileScreen(),
        firebaseAvailable: true,
        extra: [
          currentUserProvider.overrideWith(
            (ref) => Stream<AuthUser?>.value(user),
          ),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CloudUnavailableNotice), findsNothing);
      expect(find.text(t.auth.signInGoogle), findsOneWidget);
    });
  });
}
