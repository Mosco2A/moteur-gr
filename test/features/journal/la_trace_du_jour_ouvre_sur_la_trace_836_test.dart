/// LA GARDE QUI EXIGE QUE LA VIGNETTE DU CARNET OUVRE SUR SA TRACE (836).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE
/// ---------------------------------------------------------------------------
///
/// Dans le carnet, « Tracé du jour » dessinait la trace verte sur un fond GRIS
/// et vide, sans fond de carte.
///
/// ---------------------------------------------------------------------------
/// LA CAUSE : UN ORDRE, PAS UNE COUCHE MANQUANTE
/// ---------------------------------------------------------------------------
///
/// LE FOND ETAIT POURTANT BIEN LA. [FondDeCarte] etait monte dans cette
/// vignette depuis le debut, et la garde `fond_de_carte_decide_test.dart` le
/// verifiait meme. Le defaut etait ailleurs : les `MapOptions` n'avaient NI
/// `initialCenter` NI `initialZoom`, seulement un `initialCameraFit`.
///
/// OR `flutter_map` N'APPLIQUE `initialCameraFit` QU'EN POST-FRAME. D'ici la,
/// la couche de tuiles a deja demande une pleine fournee au zoom par DEFAUT,
/// centree sur le point par defaut du paquet — une vue que personne ne verra.
/// Et comme son flux d'evenements est un `broadcast` SANS REJEU, aucune seconde
/// fournee n'est demandee pour la vue reelle. Tout cela est deja ecrit, mot
/// pour mot, dans `cadrage_d_ouverture.dart` et `fond_de_carte.dart` : la
/// tache 758
/// avait corrige exactement ce defaut sur l'ecran de NAVIGATION.
///
/// ET ICI C'ETAIT DEFINITIF. Sur la carte de navigation, le moindre geste
/// rattrapait le coup — « il faut sortir puis revenir pour qu'elle s'affiche ».
/// Cette vignette est en `InteractiveFlag.none` : aucun geste n'est possible,
/// donc plus rien ne pouvait declencher le chargement.
///
/// ---------------------------------------------------------------------------
/// POURQUOI CETTE GARDE MESURE LA CAMERA, ET NON LES TUILES
/// ---------------------------------------------------------------------------
///
/// AUCUN TEST WIDGET NE PEUT PROUVER QU'UN FOND EST PEINT : sous binding de
/// test, le fournisseur de tuiles du depot rend des PNG 1x1 TRANSPARENTS
/// (`test_inert_tile_provider.dart`). C'est precisement pour cela que le test
/// existant de cette vignette — `journal_day_trace_test.dart`, qui verifie
/// `find.byType(FlutterMap)` — etait VERT avec le defaut sous les yeux : il
/// prouvait que la carte EXISTE, jamais qu'elle regarde au bon endroit.
///
/// ON MESURE DONC LA SEULE CHOSE QUI DECIDE DU CHARGEMENT : la camera
/// d'ouverture. Si son centre tombe dans les bornes de la trace, les tuiles
/// demandees a la premiere image sont les bonnes.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/map/fond_de_carte.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/monetization_service.dart';
import 'package:moteur_gr/features/journal/presentation/journal_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  const trailId = 'sentier-bleu';

  /// La trace du jour : trois points en Corse, assez ecartes pour que les
  /// bornes soient franches.
  const latitudes = <double>[42.10, 42.14, 42.18];
  const longitude = 9.0;

  Future<void> noteLe(AppDatabase db, DateTime quand, String texte) {
    return db.journalDao.insertEntry(
      JournalEntriesCompanion.insert(
        trailId: trailId,
        stageNumber: 1,
        content: Value(texte),
        createdAt: quand,
      ),
    );
  }

  Future<void> pointLe(AppDatabase db, DateTime quand, double lat) {
    return db.sessionTrackPointsDao.insertPoint(
      trailId: trailId,
      sessionId: 'session-836',
      dayIndex: 1,
      lat: lat,
      lng: longitude,
      altitude: 900,
      recordedAt: quand,
      source: TrackPointSource.gps,
    );
  }

  Future<void> monteLeCarnet(WidgetTester tester, AppDatabase db) async {
    LocaleSettings.setLocaleRaw('fr');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          // L7-3 : le carnet est verrouille en demonstration ; cette garde
          // regarde le carnet OUVERT.
          isDemoModeProvider(trailId).overrideWith((ref) async => false),
          trailIdProvider.overrideWithValue(trailId),
        ],
        child: TranslationProvider(
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
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
  }

  group('LA TRACE DU JOUR OUVRE SUR LA TRACE (836)', () {
    testWidgets('la camera d ouverture de la vignette tombe DANS les bornes '
        'de la trace du jour', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await noteLe(db, DateTime(2026, 6, 10, 9), 'Jour un');
      for (var i = 0; i < latitudes.length; i++) {
        await pointLe(db, DateTime(2026, 6, 10, 10 + i), latitudes[i]);
      }

      await monteLeCarnet(tester, db);

      final carte = find.byType(FlutterMap);
      expect(
        carte,
        findsOneWidget,
        reason: 'la vignette du carnet n est pas rendue : rien a mesurer.',
      );
      // Le fond passe bien par le decideur (fichier telecharge ou reseau).
      expect(
        find.descendant(of: carte, matching: find.byType(FondDeCarte)),
        findsOneWidget,
      );

      final options = tester.widget<FlutterMap>(carte).options;
      final centre = options.initialCenter;
      final latMin = latitudes.reduce((a, b) => a < b ? a : b);
      final latMax = latitudes.reduce((a, b) => a > b ? a : b);

      expect(
        centre.latitude >= latMin && centre.latitude <= latMax,
        isTrue,
        reason:
            'LA VIGNETTE N OUVRE PAS SUR SA TRACE : centre en '
            '${centre.latitude}, alors que la trace du jour va de $latMin a '
            '$latMax. Les tuiles de la premiere image seront demandees '
            'ailleurs, et le flux d evenements de flutter_map etant SANS '
            'REJEU, aucune autre fournee ne sera demandee. Comme la vignette '
            'refuse tout geste (InteractiveFlag.none), le fond restera gris '
            'DEFINITIVEMENT.',
      );
      expect(
        centre.longitude,
        closeTo(longitude, 0.001),
        reason:
            'LA VIGNETTE N OUVRE PAS SUR SA TRACE : centre en '
            '${centre.longitude} alors que la trace est sur le meridien '
            '$longitude.',
      );
      expect(
        options.initialZoom,
        greaterThan(0),
        reason:
            'SANS ZOOM D OUVERTURE, flutter_map retombe sur son zoom par '
            'defaut et demande une fournee de tuiles pour une vue que '
            'personne ne verra.',
      );
    });

    // ------------------------------------------------------------------------
    // LE TEMOIN : la mesure refuse une carte laissee au cadrage differe.
    // ------------------------------------------------------------------------
    testWidgets('TEMOIN — une carte sans initialCenter est bien vue comme '
        'ouvrant ailleurs', (tester) async {
      // LA MISE EN PAGE FAUTIVE : `initialCameraFit` SEUL, c'est-a-dire la
      // vignette d'avant ce lot. On ne monte aucune tuile — c'est la CAMERA
      // qu'on mesure, et elle se lit sans peindre.
      final cible = LatLngBounds.fromPoints([
        for (final lat in latitudes) LatLng(lat, longitude),
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: cible,
                    padding: const EdgeInsets.all(24),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: const [],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final options = tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .options;
      final centre = options.initialCenter;
      final latMin = latitudes.reduce((a, b) => a < b ? a : b);
      final latMax = latitudes.reduce((a, b) => a > b ? a : b);

      expect(
        centre.latitude >= latMin && centre.latitude <= latMax,
        isFalse,
        reason:
            'LA MESURE NE VOIT PLUS RIEN. Soumise a une carte laissee au seul '
            '`initialCameraFit`, elle devrait constater que la camera '
            'd ouverture est AILLEURS que sur la trace (centre releve : '
            '$centre). Si elle ne le voit pas, le test vert ci-dessus ne '
            'prouve rien.',
      );
    });
  });
}
