import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/recovery_code_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:moteur_gr/features/auth/presentation/profile_screen.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/settings/providers/settings_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TACHE 837 — LOT C, l'ecran « Mon compte » (profil).
///
/// Deux retours de Christophe, mesures A L'ECRAN et non sur l'intention du
/// code :
///
/// (C1) « main dominante inverser les bouton droitier a droite et gaucher a
/// gauche ». CE QUI A ETE MESURE AVANT CORRECTIF : le cote de l'ecran ou
/// atterrissent les commandes etait DEJA bon partout ou il est calcule
/// (`DominantHandValues.isRight` -> droitier a droite) — et sur `main` il
/// n'etait meme calcule NULLE PART (`isRight` : zero appelant dans `lib/`).
/// Ce qui etait reellement inverse, c'est LE CONTROLE LUI-MEME : les segments
/// etaient declares [Droitier, Gaucher], donc le bouton « Droitier » tombait a
/// GAUCHE et « Gaucher » a DROITE. Ces tests mesurent les ABSCISSES des deux
/// boutons apres rendu, et figent le sens dans les deux directions : la carte
/// (ou est le bouton) et le territoire (ce que le reglage vaut).
///
/// (C2) « Dans profil le numeros de recuperation de compte doit aparaitre ».
/// Le code de reconnexion n'existait a l'ecran que derriere Reglages. Ces tests
/// verifient qu'il est dans le profil, LISIBLE (selectionnable), COPIABLE (le
/// presse-papiers recoit exactement le code) et EXPLIQUE.
void main() {
  const code = 'ABCD-EFGH-JKMN-PQRS';
  late AppDatabase db;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  /// Monte le profil en plein ecran, avec un utilisateur sans compte, un code
  /// de reconnexion fige et une base en memoire pour la fiche sante.
  ///
  /// `/profile` est une SOUS-ROUTE de `/my-treks` : en production on y arrive
  /// par un `push`, et l'`AppHeader` interroge `canPop()`.
  Widget wrap(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/my-treks/profile',
      routes: [
        GoRoute(
          path: '/my-treks',
          builder: (_, __) => const Scaffold(body: SizedBox()),
          routes: [
            GoRoute(path: 'profile', builder: (_, __) => const ProfileScreen()),
          ],
        ),
        GoRoute(path: '/health', builder: (_, __) => const Text('HEALTH')),
      ],
    );
    return UncontrolledProviderScope(
      container: container,
      child: TranslationProvider(
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        currentUserProvider.overrideWith(
          (ref) => Stream.value(
            const AuthUser(uid: 'u1', authMethod: AuthMethodValues.anonymous),
          ),
        ),
        recoveryCodeProvider.overrideWith((ref) async => code),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// Rend le profil sur un ecran assez HAUT pour que toute la colonne soit
  /// posee : on mesure des positions reelles, pas des positions de widgets
  /// jamais disposes.
  Future<ProviderContainer> pumpProfil(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = makeContainer();
    await tester.pumpWidget(wrap(container));
    await tester.pumpAndSettle();
    return container;
  }

  group('C1 — la main dominante : le sens, mesure a l ecran', () {
    testWidgets('GAUCHER est a GAUCHE et DROITIER a DROITE (abscisses)', (
      tester,
    ) async {
      await pumpProfil(tester);

      final gaucher = find.text(t.navPilote.dominantHandLeft);
      final droitier = find.text(t.navPilote.dominantHandRight);
      expect(gaucher, findsOneWidget);
      expect(droitier, findsOneWidget);

      // LA MESURE : l'abscisse du centre de chaque bouton, apres rendu.
      final xGaucher = tester.getCenter(gaucher).dx;
      final xDroitier = tester.getCenter(droitier).dx;

      expect(
        xGaucher,
        lessThan(xDroitier),
        reason:
            'Le bouton « Gaucher » doit etre a GAUCHE du bouton « Droitier ». '
            'Mesure : Gaucher x=$xGaucher, Droitier x=$xDroitier. '
            'Avant la tache 837 les segments etaient declares '
            '[Droitier, Gaucher], donc l inverse exact.',
      );
    });

    testWidgets('les deux boutons sont bien de part et d autre du milieu', (
      tester,
    ) async {
      await pumpProfil(tester);

      // Mesure complementaire : ce n'est pas seulement un ordre relatif, les
      // deux moities du controle sont bien occupees chacune de son cote.
      final xGaucher = tester
          .getCenter(find.text(t.navPilote.dominantHandLeft))
          .dx;
      final xDroitier = tester
          .getCenter(find.text(t.navPilote.dominantHandRight))
          .dx;
      final milieu =
          tester.view.physicalSize.width / tester.view.devicePixelRatio / 2;

      expect(
        xGaucher,
        lessThan(milieu),
        reason: 'Gaucher dans la moitie gauche',
      );
      expect(
        xDroitier,
        greaterThan(milieu),
        reason: 'Droitier dans la moitie droite',
      );
    });

    testWidgets('appuyer sur DROITIER enregistre bien « droitier »', (
      tester,
    ) async {
      final container = await pumpProfil(tester);

      // On part de gaucher pour que l'appui soit un vrai changement.
      container
          .read(settingsProvider.notifier)
          .setDominantHand(DominantHandValues.left);
      await tester.pumpAndSettle();
      expect(
        container.read(settingsProvider).dominantHand,
        DominantHandValues.left,
      );

      await tester.tap(find.text(t.navPilote.dominantHandRight));
      await tester.pumpAndSettle();

      // L'ORDRE A CHANGE, PAS LE SENS : le bouton de droite vaut toujours
      // « droitier ». C'est la garde contre une inversion des VALEURS en
      // croyant inverser les POSITIONS.
      expect(
        container.read(settingsProvider).dominantHand,
        DominantHandValues.right,
        reason: 'Le bouton a droite doit valoir droitier, pas gaucher',
      );
    });

    testWidgets('appuyer sur GAUCHER enregistre bien « gaucher »', (
      tester,
    ) async {
      final container = await pumpProfil(tester);
      expect(
        container.read(settingsProvider).dominantHand,
        DominantHandValues.right,
      );

      await tester.tap(find.text(t.navPilote.dominantHandLeft));
      await tester.pumpAndSettle();

      expect(
        container.read(settingsProvider).dominantHand,
        DominantHandValues.left,
        reason: 'Le bouton a gauche doit valoir gaucher, pas droitier',
      );
    });

    test(
      'le SENS DE L EFFET est fige : droitier -> droite, gaucher -> gauche',
      () {
        // Le contrat que TOUT consommateur doit respecter pour lateraliser les
        // commandes. Sur `main` il n'y a encore AUCUN appelant d'`isRight` (le
        // reglage ne deplace donc rien a l'ecran) : ce test fige le sens pour
        // que le jour ou un ecran s'en sert, il ne puisse pas le prendre a
        // l'envers.
        expect(DominantHandValues.isRight(DominantHandValues.right), isTrue);
        expect(DominantHandValues.isRight(DominantHandValues.left), isFalse);
        // Defaut impose (R9) : droitier, et une valeur illisible y retombe.
        expect(DominantHandValues.fallback, DominantHandValues.right);
        expect(DominantHandValues.isRight(DominantHandValues.fallback), isTrue);
        expect(
          DominantHandValues.isRight(DominantHandValues.fromString('?')),
          isTrue,
        );
      },
    );
  });

  group('C2 — le numero de recuperation de compte est dans le profil', () {
    testWidgets('le code s affiche, en entier et selectionnable', (
      tester,
    ) async {
      await pumpProfil(tester);

      // Le titre de section et le libelle du champ.
      expect(find.text(t.recovery.title), findsOneWidget);
      expect(find.text(t.recovery.codeLabel), findsOneWidget);

      // Le code LUI-MEME, a l'identique (19 caracteres, groupes de 4).
      final champ = find.byKey(const ValueKey('profile-recovery-code'));
      expect(champ, findsOneWidget);
      expect(tester.widget<SelectableText>(champ).data, code);

      // LISIBLE : selectionnable (on peut le prendre a la main) et en
      // monospace (un O et un 0 ne se confondent pas a la recopie).
      final style = tester.widget<SelectableText>(champ).style;
      expect(style?.fontFamily, 'monospace');
    });

    testWidgets('une phrase explique a quoi il sert', (tester) async {
      await pumpProfil(tester);
      // L'explication est celle de l'ecran dedie, deja traduite en 5 langues :
      // elle dit que le code ouvre le coffre SUR UN AUTRE TELEPHONE.
      expect(find.text(t.recovery.intro), findsOneWidget);
    });

    testWidgets('si le keystore ne repond JAMAIS, le profil se stabilise quand '
        'meme (zero spinner infini)', (tester) async {
      // REGRESSION (tache 837) : la 1re version de ce bloc posait un
      // `CircularProgressIndicator` dans l'etat `loading`. Le code vient du
      // keystore de l'OS, qui peut ne jamais repondre — et c'est le cas sous
      // test, sans implementation de plateforme. L'ecran tournait alors pour
      // toujours : `pumpAndSettle` expirait, et sur un telephone l'utilisateur
      // aurait vu un profil qui ne se pose jamais. C'est precisement ce que
      // l'audit #327 interdit sur cet ecran (« aucun spinner infini »).
      tester.view.physicalSize = const Size(390, 3000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          currentUserProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(uid: 'u1', authMethod: AuthMethodValues.anonymous),
            ),
          ),
          // Un futur qui ne se resout JAMAIS.
          recoveryCodeProvider.overrideWith(
            (ref) => Completer<String>().future,
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(wrap(container));
      // C'EST LA L'ASSERTION : si un spinner tournait, cet appel expirerait.
      await tester.pumpAndSettle();

      // Le bloc reste annonce et explique, simplement sans code encore.
      expect(find.text(t.recovery.title), findsOneWidget);
      expect(find.text(t.recovery.intro), findsOneWidget);
      expect(find.byKey(const ValueKey('profile-recovery-code')), findsNothing);
      // Et le reste du profil est bien la : un code en attente ne doit rien
      // bloquer d'autre.
      expect(find.text(t.navPilote.dominantHandRight), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'le bouton copier met exactement le code dans le presse-papiers',
      (tester) async {
        final copies = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async {
            if (call.method == 'Clipboard.setData') {
              copies.add((call.arguments as Map)['text'] as String);
            }
            return null;
          },
        );
        addTearDown(() {
          tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
            SystemChannels.platform,
            null,
          );
        });

        await pumpProfil(tester);

        await tester.tap(find.byKey(const ValueKey('profile-recovery-copy')));
        await tester.pumpAndSettle();

        // COPIABLE : le presse-papiers a recu le code, et rien d'autre.
        expect(copies, [code]);
        // Et l'utilisateur en a la confirmation a l'ecran.
        expect(find.text(t.recovery.copied), findsOneWidget);
      },
    );
  });
}
