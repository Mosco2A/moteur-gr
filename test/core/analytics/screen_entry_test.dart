// T1 — L'OBSERVABILITE EN ECHEC NE COUTE JAMAIS UN ECRAN (lot 645-09).
//
// CE QUE CE FICHIER PROUVE, ET POURQUOI C'EST LA GARDE LA PLUS IMPORTANTE DU
// LOT. L'instrumentation posee par 645-09 tourne sur un telephone ou Firebase
// est indisponible 100 pct du temps : `analytics_service.dart` rend
// `AnalyticsService.disabled()`. Une miette qui couterait un ecran serait donc
// un defaut PERMANENT, pas un cas limite. Et le precedent existe : au volet 2
// de la tache 637, le service qui sert a savoir que l'application casse etait
// lui-meme capable de la casser, parce que son provider levait a la lecture.
//
// LES QUATRE PANNES COUVERTES ICI sont celles qui peuvent arriver sur un
// vrai appareil :
//
//   1. le puits natif LEVE (Firebase absent, Google Play trop vieux) ;
//   2. le puits natif rend une FUTURE REJETEE (panne asynchrone) ;
//   3. la METHODE D'ENTREE du service leve, synchronement ;
//   4. LA LECTURE DU PROVIDER leve (conteneur detruit, surcharge en test).
//
// Le balayage des 63 ecrans du catalogue est en bas de fichier : aucune des
// 63 miettes de l'application ne peut lever, et c'est verifie une par une.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';
import 'package:moteur_gr/core/analytics/screen_entry.dart';

/// Un puits crash qui NOTE ce qu'on lui pose, pour lire la convention.
class _PuitsNoteur implements CrashSink {
  final cles = <String, String>{};
  final miettes = <String>[];

  @override
  Future<void> log(String message) async => miettes.add(message);
  @override
  Future<void> setCustomKey(String key, String value) async =>
      cles[key] = value;
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Un puits crash EN PANNE : il leve a chaque geste (panne 1).
class _PuitsQuiLeve implements CrashSink {
  @override
  Future<void> log(String message) async => throw StateError('journal mort');
  @override
  Future<void> setCustomKey(String key, String value) async =>
      throw StateError('cle morte');
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async => throw StateError('rapport mort');
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Un puits crash qui rend des futures REJETEES (panne 2).
class _PuitsQuiRejette implements CrashSink {
  @override
  Future<void> log(String message) => Future.error(StateError('rejet'));
  @override
  Future<void> setCustomKey(String key, String value) =>
      Future.error(StateError('rejet'));
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) => Future.error(StateError('rejet'));
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Un service dont la METHODE D'ENTREE leve, synchronement (panne 3).
class _ServiceQuiLeve extends AnalyticsService {
  _ServiceQuiLeve()
    : super(analytics: const NoOpAnalyticsSink(), crash: const NoOpCrashSink());

  @override
  Future<void> enterScreen(
    ScreenBreadcrumb screen, {
    String? trail,
    String? stage,
  }) => throw StateError('entree morte');
}

AnalyticsService _serviceAvec(CrashSink puits) =>
    AnalyticsService(analytics: const NoOpAnalyticsSink(), crash: puits);

void main() {
  group('645-09 — la convention des trois cles et de la miette', () {
    test(
      'une entree d ecran pose les trois cles et UNE miette courte',
      () async {
        final puits = _PuitsNoteur();
        await _serviceAvec(
          puits,
        ).enterScreen(ScreenBreadcrumb.map, trail: 'gr20', stage: '7');

        expect(puits.cles.keys, containsAll(AnalyticsKeys.all));
        expect(puits.cles[AnalyticsKeys.screen], 'map');
        expect(puits.cles[AnalyticsKeys.stage], '7');
        expect(puits.miettes, ['screen:map']);
      },
    );

    test('le sentier part ANONYMISE, jamais en clair', () async {
      final puits = _PuitsNoteur();
      await _serviceAvec(
        puits,
      ).enterScreen(ScreenBreadcrumb.map, trail: 'gr20');

      expect(puits.cles[AnalyticsKeys.trail], isNot(contains('gr20')));
      expect(
        puits.cles[AnalyticsKeys.trail],
        AnalyticsService.anonymize('gr20'),
      );
    });

    test('reposer le MEME contexte ne coute pas un appel de plus', () async {
      final puits = _PuitsNoteur();
      final service = _serviceAvec(puits);
      for (var i = 0; i < 20; i++) {
        await service.enterScreen(ScreenBreadcrumb.hub);
      }

      // C'est la garde de budget : un `build()` qui repasse 20 fois par la ne
      // pose qu'UNE miette.
      expect(puits.miettes, ['screen:hub']);
    });

    test('changer d ecran pose une miette de plus', () async {
      final puits = _PuitsNoteur();
      final service = _serviceAvec(puits);
      await service.enterScreen(ScreenBreadcrumb.hub);
      await service.enterScreen(ScreenBreadcrumb.map);
      await service.enterScreen(ScreenBreadcrumb.hub);

      expect(puits.miettes, ['screen:hub', 'screen:map', 'screen:hub']);
    });

    test(
      'une etape qui change rafraichit la cle SANS nouvelle miette',
      () async {
        final puits = _PuitsNoteur();
        final service = _serviceAvec(puits);
        await service.enterScreen(ScreenBreadcrumb.map, stage: '7');
        await service.enterScreen(ScreenBreadcrumb.map, stage: '8');

        expect(puits.cles[AnalyticsKeys.stage], '8');
        expect(puits.miettes, ['screen:map']);
      },
    );

    test('le service INERTE ne pose rien et ne leve pas', () async {
      // C'est l'etat de l'application 100 pct du temps aujourd'hui.
      await expectLater(
        AnalyticsService.disabled().enterScreen(ScreenBreadcrumb.hub),
        completes,
      );
    });
  });

  group('645-09 / T1 — un puits en panne ne remonte jamais', () {
    test('un puits qui LEVE est avale par le service', () async {
      await expectLater(
        _serviceAvec(_PuitsQuiLeve()).enterScreen(ScreenBreadcrumb.hub),
        completes,
      );
    });

    test('un puits qui REJETTE est avale par le service', () async {
      await expectLater(
        _serviceAvec(_PuitsQuiRejette()).enterScreen(ScreenBreadcrumb.hub),
        completes,
      );
    });
  });

  group('645-09 / T1 — le raccord d ecran ne casse pas l ecran', () {
    /// Monte un ecran MINIMAL qui pose sa miette comme le font les 63 vrais :
    /// ce qui est mesure ici, c'est le raccord, pas le decor.
    // `Override` n'est pas exporte par l'API publique de Riverpod 3.3.2 :
    // `List<Object>` + `.cast()` le retrouve par inference, comme le socle
    // `parcours_reel.dart` le fait deja.
    Future<void> monter(WidgetTester tester, List<Object> surcharges) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: surcharges.cast(),
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, _) {
                observeScreenEntry(ref, ScreenBreadcrumb.hub);
                return const Text('ecran affiche');
              },
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('le puits natif leve : l ecran s affiche quand meme', (
      tester,
    ) async {
      await monter(tester, [
        analyticsServiceProvider.overrideWithValue(
          _serviceAvec(_PuitsQuiLeve()),
        ),
      ]);
      expect(find.text('ecran affiche'), findsOneWidget);
    });

    testWidgets('la methode d entree leve : l ecran s affiche quand meme', (
      tester,
    ) async {
      await monter(tester, [
        analyticsServiceProvider.overrideWithValue(_ServiceQuiLeve()),
      ]);
      expect(find.text('ecran affiche'), findsOneWidget);
    });

    testWidgets('la LECTURE du provider leve : l ecran s affiche quand meme', (
      tester,
    ) async {
      // La panne du volet 2 de la tache 637, a l'identique.
      await monter(tester, [
        analyticsServiceProvider.overrideWith(
          (ref) => throw StateError('provider mort'),
        ),
      ]);
      expect(find.text('ecran affiche'), findsOneWidget);
    });
  });

  group('645-09 / T1 — balayage des 63 miettes du catalogue', () {
    testWidgets('aucune des miettes de l application ne peut lever', (
      tester,
    ) async {
      for (final miette in ScreenBreadcrumb.all) {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              analyticsServiceProvider.overrideWithValue(
                _serviceAvec(_PuitsQuiLeve()),
              ),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  observeScreenEntry(ref, miette, trail: 'gr20', stage: '3');
                  return Text(miette.name);
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          find.text(miette.name),
          findsOneWidget,
          reason: 'la miette ${miette.name} a empeche son ecran de s afficher',
        );
      }
    });
  });
}
