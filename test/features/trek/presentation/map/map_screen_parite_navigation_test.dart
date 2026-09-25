import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/track_point.dart';
import 'package:moteur_gr/core/models/poi.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/features/safety/presentation/sos_button.dart';
import 'package:moteur_gr/features/trail/providers/pois_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/domain/models/trek_session.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// PARITE GR20 (#99460) — l'onglet Carte StepWays clone l'ecran Navigation GR20.
///
/// Verifie la presence des elements ajoutes (au niveau GR20, hors peau) :
///   * bouton SOS (visible pendant un trek, masque hors trek) ;
///   * bouton Calques (toggle des couches) ;
///   * couche POI ;
///   * barre d'etape active pendant un trek ;
/// et le fix de navigation : le retour depuis la carte ne plante pas.
void main() {
  final mockTrackPoints = [
    const TrackPoint(lat: 45.77, lng: 2.96, altitude: 1465, distanceFromStart: 0),
    const TrackPoint(
        lat: 45.78, lng: 2.97, altitude: 1500, distanceFromStart: 1200),
    const TrackPoint(
        lat: 45.79, lng: 2.98, altitude: 1600, distanceFromStart: 2400),
  ];

  final mockStages = [
    const StageModel(
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Puy de Dome',
      distanceKm: 12.0,
      elevationGainM: 450,
      elevationLossM: 200,
      startLat: 45.77,
      startLng: 2.96,
      endLat: 45.79,
      endLng: 2.98,
    ),
  ];

  final mockPois = [
    const PoiModel(
      id: 1,
      trailId: 'test-trail',
      stageNumber: 1,
      name: 'Source du col',
      type: 'water',
      lat: 45.775,
      lng: 2.965,
    ),
  ];

  Position fakePosition() => Position(
        latitude: 45.775,
        longitude: 2.965,
        timestamp: DateTime.utc(2026, 6, 15, 9),
        accuracy: 5,
        altitude: 1480,
        altitudeAccuracy: 5,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.2,
        speedAccuracy: 0.5,
      );

  TrekSession recordingSession() => TrekSession(
        id: 'sess-parite-1',
        trailId: 'test-trail',
        startedAt: DateTime.utc(2026, 6, 15, 8),
        status: 'active',
      );

  /// Harnais MapScreen avec surcharge du statut de session.
  Widget harness({
    required TrackingSessionStatus status,
    bool withGps = false,
  }) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        // Trace du sentier courant ET trace 'default' (lu par la projection).
        gpxTrackProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        gpxTrackProvider('default')
            .overrideWith((ref) => Future.value(mockTrackPoints)),
        stagesProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockStages)),
        stagesProvider('default')
            .overrideWith((ref) => Future.value(mockStages)),
        poisProvider(testTrailConfig.id)
            .overrideWith((ref) => Future.value(mockPois)),
        // GPS : soit refuse (pas de position), soit une position fixe.
        if (withGps)
          locationProvider.overrideWith((ref) => Stream.value(fakePosition()))
        else
          gpsPermissionProvider.overrideWith(
              (ref) => Future.value(GpsPermissionStateValues.denied)),
        // Session de tracking figee au statut demande.
        trekSessionManagerProvider.overrideWith(
          () => _FixedStatusNotifier(
            TrackingSessionState(
              status: status,
              session: status == TrackingSessionStatus.recording ||
                      status == TrackingSessionStatus.paused
                  ? recordingSession()
                  : null,
            ),
          ),
        ),
        // Neutralise le flux d'etape (evite le vrai GPS via le mount).
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
      ],
      child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
    );
  }

  group('MapScreen parite GR20 — elements presents', () {
    testWidgets('bouton Calques present (toggle des couches)', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // FAB des calques (heroTag mapLayers -> icone layers).
      expect(find.byIcon(Icons.layers), findsOneWidget);
    });

    testWidgets('SOS overlay masque hors trek (acces unique, aucun SOS de barre)',
        (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // OVERLAY SOS ([SosButton], colonne bas-gauche) : se rend en
      // SizedBox.shrink hors trek -> son sous-arbre ne porte AUCUNE icone SOS.
      expect(find.byType(SosButton), findsOneWidget); // widget monte
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.byIcon(Icons.emergency),
        ),
        findsNothing,
        reason: 'overlay SOS invisible hors trek (parite SosButton)',
      );

      // SOS UNIQUE aligne GR20 (cycle 3) : le doublon SOS de la barre §4 a ete
      // RETIRE. Hors trek, l'overlay est masque ET la barre ne porte plus de SOS
      // -> AUCUNE icone SOS a l'ecran (exactement comme GR20, sans barre SOS).
      expect(
        find.byIcon(Icons.emergency),
        findsNothing,
        reason: 'plus de SOS en barre (retire cycle 3) + overlay masque hors trek',
      );
    });

    testWidgets('SOS overlay = SEUL acces pendant un trek (parite GR20)',
        (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      // OVERLAY SOS ([SosButton]) : visible en trek (icone + texte « SOS »).
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.byIcon(Icons.emergency),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SosButton),
          matching: find.text('SOS'),
        ),
        findsOneWidget,
      );

      // SOS UNIQUE aligne GR20 (cycle 3) : plus de doublon en barre. En trek,
      // il n'y a donc qu'UNE SEULE icone SOS et un seul texte « SOS » a l'ecran,
      // ceux de l'overlay — a l'identique de GR20 (SosFloatingButton unique).
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
    });

    testWidgets('barre d etape active affichee pendant un trek avec fix GPS',
        (tester) async {
      await tester.pumpWidget(
        harness(status: TrackingSessionStatus.recording, withGps: true),
      );
      // Laisse le stream GPS + la projection se resoudre.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StageProgressBar), findsOneWidget);
    });

    // -----------------------------------------------------------------------
    // LOT D (tache 554) — CONTRAT RETOURNE, ET C'EST VOULU.
    //
    // Ce test exigeait AUPARAVANT que la barre d'etape soit ABSENTE hors trek.
    // Chris a tranche l'inverse, mot pour mot : « 14 navigation ne ressemble en
    // rien a GR20 !!!!! ». La cause etait precisement cette absence : sans
    // randonnee demarree, l'ecran n'avait plus qu'une carte et des boutons,
    // alors que la navigation de reference affiche sa barre de chiffres EN
    // PERMANENCE. La barre est donc desormais TOUJOURS presente ; hors trek elle
    // porte les chiffres du PROGRAMME et un tiret sur ce qui exige le GPS.
    // -----------------------------------------------------------------------
    testWidgets('barre d etape TOUJOURS presente, meme hors trek (LOT D)',
        (tester) async {
      await tester.pumpWidget(
        harness(status: TrackingSessionStatus.idle, withGps: true),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(StageProgressBar), findsOneWidget);

      // Les chiffres montres sont ceux du PROGRAMME de l'etape (mockStages) :
      // 12 km, D+ 450 m, D- 200 m. Aucun GPS n'est necessaire pour les
      // connaitre.
      expect(find.text('Puy de Dome'), findsOneWidget);
      expect(find.text('450 m'), findsOneWidget);
      expect(find.text('200 m'), findsOneWidget);

      // Et les chiffres qui exigent la marche portent un tiret — jamais un
      // zero, qui se lirait comme une mesure.
      expect(
        find.text(StageProgressBar.pendingValueLabel),
        findsWidgets,
        reason: 'parcouru et vitesse moyenne ne sont pas encore mesurables',
      );
    });

    testWidgets('bouton photo vers le journal present sur la carte (LOT D)',
        (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // Manque reel n°1 : la carte de reference porte ce bouton, StepWays
      // n'en avait aucune occurrence.
      expect(find.byIcon(Icons.photo_camera), findsOneWidget);
    });

    testWidgets('guide des icones accessible depuis l en-tete (LOT D)',
        (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      // Manque reel n°2 : action (i) de l'en-tete -> guide de la carte.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      await tester.tap(find.byIcon(Icons.info_outline));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // La legende nomme les types de points REELLEMENT presents sur le
      // sentier charge (ici un point d'eau), avec le libelle traduit.
      expect(find.text(t.poi.water), findsWidgets);
      expect(find.text(t.map.layers), findsWidgets);
    });

    testWidgets('le panneau Calques porte la LISTE DES POINTS DE L ETAPE '
        '(LOT D)', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.layers));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Les calques (fonction d'origine) sont toujours la...
      expect(find.text(t.map.layersTitle), findsOneWidget);
      // ... et la liste des points de l'etape en cours s'y ajoute : titres des
      // deux familles, et le point d'eau de l'etape 1 du sentier de test.
      expect(find.text(t.stage.waterSources.title), findsOneWidget);
      expect(find.text(t.stage.accommodation.title), findsOneWidget);
      expect(find.text('Source du col'), findsOneWidget);
      expect(find.byType(Checkbox), findsOneWidget);
    });
  });

  group('MapScreen parite GR20 — navigation retour', () {
    testWidgets('retour depuis la carte (racine de branche) ne plante pas',
        (tester) async {
      // Router minimal : /home + /map (comme l'onglet Carte du shell). On entre
      // par /map (racine de branche, pile vide) : le bouton retour ne doit PAS
      // tenter de depiler une pile vide (crash) mais revenir a /home.
      final router = GoRouter(
        initialLocation: '/map',
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) =>
                const Scaffold(body: Text('HOME-SCREEN')),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(trailId: 'test-trail'),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trailConfigProvider.overrideWithValue(testTrailConfig),
            gpxTrackProvider(testTrailConfig.id)
                .overrideWith((ref) => Future.value(mockTrackPoints)),
            gpsPermissionProvider.overrideWith(
                (ref) => Future.value(GpsPermissionStateValues.denied)),
            trekSessionManagerProvider.overrideWith(
              () => _FixedStatusNotifier(
                const TrackingSessionState(status: TrackingSessionStatus.idle),
              ),
            ),
            currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Le bouton retour est present.
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);

      // Tap retour : aucune exception, on arrive sur /home.
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('HOME-SCREEN'), findsOneWidget);
    });
  });
}

/// Notifier de test : fige un [TrackingSessionState] donne (statut de session).
class _FixedStatusNotifier extends TrekSessionManagerNotifier {
  _FixedStatusNotifier(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
