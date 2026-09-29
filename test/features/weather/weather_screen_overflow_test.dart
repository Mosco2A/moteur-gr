import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/daos/stages_dao.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/features/weather/presentation/weather_screen.dart';
import 'package:moteur_gr/features/weather/widgets/today_stage_weather_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import 'meteo_du_serveur.dart';

/// Tests LOT-B de l'écran météo E31 : rendu + NON-RÉGRESSION overflow mobile.
///
/// Retour d'expérience du Lot A (#95062) : un layout qui ne déborde pas à
/// 1200 px peut déborder à 360/390/412 px. Ce fichier rend l'écran COMPLET à
/// chaque largeur mobile et échoue si le moindre RenderFlex signale un overflow.
///
/// HORS LIGNE AVEC UN BULLETIN DEPOSE PAR LE SERVEUR (lot 625) : l'écran affiche
/// toute l'UX (carte du jour, J+1/J+2, « toutes les étapes », bandeau source + âge)
/// SANS le moindre appel réseau — le bulletin est en base, notre serveur l'y a mis.
///
/// CE QUE CE FICHIER TESTAIT AVANT, ET QUI A ÉTÉ SUPPRIMÉ : « l'écran bascule sur le
/// seed de démonstration ». Sur un sentier RÉEL, fabriquer une prévision fictive et
/// la badger discrètement « démonstration » est le « défaut vert » que la conception
/// 611 nomme un mensonge confortable (#I21). Le cas sans bulletin a désormais son
/// propre test, plus bas, et il vérifie qu'on n'affiche AUCUN chiffre.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    // 3 étapes fictives pour test-trail (coords Auvergne inventées).
    await StagesDao(db).insertAll([
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(1),
        name: Value('Départ - Refuge haut'),
        distanceKm: Value(12.0),
        elevationGainM: Value(900),
        elevationLossM: Value(200),
        startLat: Value(45.51),
        startLng: Value(2.96),
        endLat: Value(45.55),
        endLng: Value(2.99),
      ),
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(2),
        name: Value('Refuge haut - Col des cratères oubliés du massif'),
        distanceKm: Value(15.0),
        elevationGainM: Value(1100),
        elevationLossM: Value(400),
        startLat: Value(45.55),
        startLng: Value(2.99),
        endLat: Value(45.60),
        endLng: Value(3.05),
      ),
      const StagesCompanion(
        trailId: Value('test-trail'),
        stageNumber: Value(3),
        name: Value('Col - Arrivée'),
        distanceKm: Value(10.0),
        elevationGainM: Value(300),
        elevationLossM: Value(1200),
        startLat: Value(45.60),
        startLng: Value(3.05),
        endLat: Value(45.58),
        endLng: Value(3.10),
      ),
    ]);
  });

  tearDown(() async {
    await db.close();
  });

  /// Depose le bulletin du serveur pour l'etape affichee.
  Future<void> deposerLeBulletin({Duration age = const Duration(hours: 1)}) =>
      deposerMeteoEnBase(
        db,
        trailId: 'test-trail',
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(age),
        latitude: 45.58,
        longitude: 3.10,
      );

  Widget wrap() {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        databaseProvider.overrideWithValue(db),
        // HORS LIGNE : c'est l'etat du randonneur sur le sentier, et il ne change
        // RIEN a la lecture — le bulletin vient de la base, pas du reseau.
        connectivityProvider.overrideWith(
          (ref) => Stream.value(ConnectivityStatusValues.offline),
        ),
      ],
      // AppHeader (Ph5/L6c) utilise GoRouter -> GoRouter minimal (+ /my-treks).
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/weather',
            routes: [
              GoRoute(
                path: '/weather',
                builder: (_, __) => const WeatherScreen(
                  trailId: 'test-trail',
                  stageNumber: 1,
                  region: 'Auvergne',
                ),
              ),
              GoRoute(path: '/my-treks', builder: (_, __) => const SizedBox()),
            ],
          ),
        ),
      ),
    );
  }

  group('WeatherScreen — rendu', () {
    testWidgets('affiche la carte du jour et le titre', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await deposerLeBulletin();
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.weather.title), findsWidgets);
      // Carte « aujourd'hui » présente (seed démo).
      expect(find.byType(TodayStageWeatherCard), findsOneWidget);
      expect(find.text(t.weather.today), findsOneWidget);
      // Vue « toutes les étapes » présente.
      expect(find.text(t.weather.allStages), findsOneWidget);
    });

    testWidgets('cloisonnement : aucun libellé GR20 / Fra li Monti',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await deposerLeBulletin();
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.textContaining('GR20'), findsNothing);
      expect(find.textContaining('Fra li Monti'), findsNothing);
    });
  });

  // --- Non-régression overflow largeurs mobiles (retour Lot A #95062) ---
  group('non-regression overflow largeurs mobiles', () {
    const mobileWidths = <double>[360, 390, 412];

    Future<List<String>> overflowsAt(
      WidgetTester tester,
      double width,
    ) async {
      final captured = <String>[];
      final previous = FlutterError.onError;
      FlutterError.onError = (details) {
        final message = details.exceptionAsString();
        if (message.contains('overflowed')) {
          captured.add(message.split('\n').first);
        } else {
          (previous ?? FlutterError.presentError)(details);
        }
      };

      tester.view.physicalSize = Size(width, 3200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      try {
        await deposerLeBulletin();
        await tester.pumpWidget(wrap());
        await tester.pumpAndSettle();
      } finally {
        FlutterError.onError = previous;
      }

      for (var guard = 0; guard < captured.length + 8; guard++) {
        final pending = tester.takeException();
        if (pending == null) break;
        if (!pending.toString().contains('overflowed')) {
          throw pending;
        }
      }
      return captured;
    }

    for (final width in mobileWidths) {
      testWidgets('aucun overflow a ${width.toInt()} px', (tester) async {
        final overflows = await overflowsAt(tester, width);
        expect(
          overflows,
          isEmpty,
          reason:
              'WeatherScreen deborde a ${width.toInt()} px : $overflows',
        );
      });
    }
  });

  // =========================================================================
  // LES DEUX ECRANS SANS CHIFFRES — CE QUE LE LOT 625 EXISTE POUR RENDRE PROPRE
  // =========================================================================

  group('WeatherScreen — quand il n y a pas de chiffre a montrer', () {
    testWidgets(
        'JAMAIS EU DE RESEAU DEPUIS L INSTALLATION : l ecran EXPLIQUE, il n est '
        'ni vide ni invente', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Aucun bulletin en base, hors ligne : le randonneur vient d installer
      // l application et n a jamais eu de reseau.
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.text(t.weather.neverReceived.title), findsOneWidget);
      expect(find.text(t.weather.neverReceived.body), findsOneWidget,
          reason: 'Il faut lui dire CE QUI VA SE PASSER : la meteo est fabriquee '
              'par notre serveur et arrivera avec les donnees du sentier.');

      // ET SURTOUT : AUCUN CHIFFRE INVENTE. Avant ce lot, l ecran fabriquait une
      // prevision fictive (12 a 25 °C, codes WMO cycliques) badgee « donnees de
      // demonstration », sur un sentier REEL. Sept cartes credibles contre un
      // badge discret.
      expect(find.byType(TodayStageWeatherCard), findsNothing);
      expect(find.text(t.weather.source.demo), findsNothing);
    });

    testWidgets(
        'et « Actualiser » y PRODUIT QUELQUE CHOSE : la reponse RESTE a l ecran',
        (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final avant = _textes(tester);
      await tester.tap(find.byIcon(Icons.refresh));
      // PAS DE `pumpAndSettle` ICI : s il restait la moindre roue a l ecran, elle
      // tournerait sans fin et le test expirerait au lieu d echouer. On pompe un
      // nombre BORNE d images — ce qui verifie du meme coup que l ecran ne part
      // pas dans une animation perpetuelle.
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final apres = _textes(tester);

      expect(apres, isNot(avant),
          reason: 'GARDE ANTI-GESTE-MORT (tache 573) : sur l ecran ou il n y a '
              'rien d autre a lire, un bouton dont la seule trace est un bandeau '
              'fugace est indistinguable d un bouton mort.');
      expect(apres, contains(t.weather.neverReceived.title),
          reason: 'L explication ne DISPARAIT pas pendant la verification : la '
              'remplacer par une roue ferait perdre au randonneur le seul texte '
              'utile de l ecran au moment ou il agit.');
    });

    testWidgets(
        'BULLETIN DE PLUS DE TROIS JOURS : plus aucun chiffre, et l ecran dit '
        'depuis quand', (tester) async {
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // « Une meteo de trois jours presentee comme fraiche a quelqu un qui decide
      // de passer un col est dangereuse » (Christophe, 28/09). C est le point le
      // plus important de ce lot.
      await deposerLeBulletin(age: const Duration(hours: 80));
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(TodayStageWeatherCard), findsNothing,
          reason: 'Passe 72 h, on ne grise plus : on RETIRE les chiffres.');
      expect(find.text(t.weather.expiredNotice.title), findsOneWidget);

      // L AGE RESTE VISIBLE : dire qu on ne sait plus sans dire depuis quand ne
      // renseigne personne.
      final textes = tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data ?? '')
          .join(' | ');
      expect(textes, contains('3'),
          reason: 'l age du dernier bulletin connu doit etre lisible');
    });
  });
}

/// Tout le texte rendu, concatene : on verifie ce que le randonneur LIT.
String _textes(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
    .join(' | ');
