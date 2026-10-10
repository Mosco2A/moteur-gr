/// TACHE 772 — LES TROIS DEFAUTS QUE CHRISTOPHE A VUS, ET REVUS.
///
/// Trois retours de Christophe, pas trois trouvailles d'audit. Le premier est
/// du 10/10 11:08, les deux autres trainaient depuis la veille :
///
///   1. « en demo le centrage du point d'avancement ne centre rien » ;
///   2. « L'icone source est toujours un nuage avec de la pluie ???? » ;
///   3. Programme et Resume portent, dans le cockpit, LE MEME DESSIN.
///
/// ---------------------------------------------------------------------------
/// 1. LA POSITION CONNUE NE DOIT PAS S'EFFACER PARCE QUE LE ROBINET SE RECHARGE
/// ---------------------------------------------------------------------------
///
/// CE QUI A ETE MESURE AVANT D'ECRIRE UNE LIGNE DE CORRECTIF, et qui contredit
/// l'hypothese de depart. En demo, hors rechargement, `currentPositionProvider`
/// rend bien une `AsyncData` portant la position du marcheur simule, et le
/// bouton « centrer sur moi » amene la camera EXACTEMENT dessus. Le defaut
/// n'est donc pas que la demo n'a pas de position : c'est qu'elle la PERD.
///
/// LA VRAIE CAUSE. `currentPositionProvider` composait son resultat avec
/// `AsyncValue.whenData`, qui ne transforme que la branche `data` : sur la
/// branche `loading` il rend une `AsyncLoading` NUE et jette donc la valeur que
/// Riverpod retient pendant un rechargement. Or le robinet de position se
/// reconstruit pour des raisons parfaitement ordinaires — un changement de
/// profil GPS decide par le recalage, l'entree ou la sortie de demo. A chaque
/// reconstruction, l'application cessait de savoir ou se trouve le randonneur
/// ALORS QU'ELLE LE SAVAIT ENCORE : mesure faite, `locationProvider` rendait
/// `hasValue: true` et la bonne latitude au moment precis ou
/// `currentPositionProvider` rendait `null`.
///
/// POURQUOI LA DEMO EN SOUFFRE PLUS QUE LA VRAIE RANDONNEE. Les positions
/// simulees passent par un flux DIFFUSE : un nouvel abonne ne recoit rien tant
/// que le battement suivant n'est pas tombe — et plus rien du tout quand le
/// marcheur est ARRIVE. En randonnee reelle le recepteur reemet tout seul et la
/// trouee se referme ; en demo elle pouvait ne jamais se refermer.
///
/// CE QUE LE RANDONNEUR VOYAIT : son marqueur disparaissait de la carte, le
/// cadrage retombait sur la premiere etape, et « centrer sur moi » se rabattait
/// sur le trace en annoncant « Position introuvable » — alors que la position
/// etait connue.
///
/// ---------------------------------------------------------------------------
/// 2. ET 3. DEUX IDEES NE PARTAGENT PAS UN DESSIN
/// ---------------------------------------------------------------------------
///
/// Les deux defauts d'icone sont le MEME defaut : deux idees differentes
/// montrees par le meme trace. Une garde sur un nom de fichier n'aurait rien
/// vu — les noms etaient justes, c'est l'association qui ne l'etait pas. Ces
/// gardes mesurent donc le DESSIN REELLEMENT CHARGE, et refusent qu'il serve
/// deux fois pour deux sens differents.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/hub_prepare_section.dart';
import 'package:moteur_gr/features/map/map_facade.dart'
    show currentPositionProvider;
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_content.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_controller.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/poi/poi_type_config.dart';
import 'package:moteur_gr/shared/widgets/quick_access_card.dart';

/// Metres par degre de latitude : la trace du test suit un meridien, donc
/// l'abscisse sur la trace y est exacte au metre pres.
const double _metresParDegre = 111194.93;

/// 3 km plein nord, un point tous les 50 m.
final List<TrackPoint> _trace = <TrackPoint>[
  for (var i = 0; i <= 60; i++)
    TrackPoint(
      lat: 45.0 + (i * 50.0) / _metresParDegre,
      lng: 3.0,
      altitude: 1000.0,
      distanceFromStart: i * 50.0,
    ),
];

/// Deux etapes : sans elles la carte n'a pas de cadrage d'etape a defaire.
final List<StageModel> _etapes = [
  StageModel(
    trailId: testTrailConfig.id,
    stageNumber: 1,
    name: 'E1',
    distanceKm: 1.5,
    elevationGainM: 0,
    elevationLossM: 0,
    startLat: _trace.first.lat,
    startLng: 3.0,
    endLat: _trace[30].lat,
    endLng: 3.0,
  ),
  StageModel(
    trailId: testTrailConfig.id,
    stageNumber: 2,
    name: 'E2',
    distanceKm: 1.5,
    elevationGainM: 0,
    elevationLossM: 0,
    startLat: _trace[30].lat,
    startLng: 3.0,
    endLat: _trace.last.lat,
    endLng: 3.0,
  ),
];

final DateTime _depart = DateTime.utc(2026, 10, 10, 8);

/// UNE MINUTERIE QUE LE TEST FAIT AVANCER LUI-MEME : un test qui dort est un
/// test qui devient intermittent.
class _MinuterieFausse implements Timer {
  _MinuterieFausse(this._action);

  final void Function(Timer) _action;
  bool _active = true;
  int _tick = 0;

  void avancer(int pas) {
    for (var i = 0; i < pas && _active; i++) {
      _tick++;
      _action(this);
    }
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => _tick;
}

class _Horloge {
  _MinuterieFausse? derniere;

  FabriqueDeMinuterie get fabrique =>
      (Duration periode, void Function(Timer) action) {
        final minuterie = _MinuterieFausse(action);
        derniere = minuterie;
        return minuterie;
      };
}

/// Une session FIGEE : ces gardes mesurent la carte, pas la machine de session.
class _SessionFigee extends TrekSessionManagerNotifier {
  _SessionFigee(this._etat);

  final TrackingSessionState _etat;

  @override
  TrackingSessionState build() => _etat;
}

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  ProviderContainer conteneurDeDemo(MarcheurSimule marcheur) {
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(
          testTrailConfig.id,
        ).overrideWith((ref) async => _trace),
        stagesProvider(testTrailConfig.id).overrideWith((ref) async => _etapes),
        enDemoProvider.overrideWithValue(true),
        marcheurSimuleProvider.overrideWithValue(marcheur),
        trekSessionManagerProvider.overrideWith(
          () => _SessionFigee(
            TrackingSessionState(
              status: TrackingSessionStatus.recording,
              session: TrekSession(
                id: 'sim-772',
                trailId: testTrailConfig.id,
                startedAt: _depart,
                status: 'active',
              ),
            ),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  ({MarcheurSimule marcheur, _Horloge horloge}) marcheurEnMarche() {
    final horloge = _Horloge();
    final marcheur = MarcheurSimule(
      minuterie: horloge.fabrique,
      maintenant: () => _depart,
      surveillerLeCycleDeVie: false,
    );
    addTearDown(marcheur.fermer);
    expect(
      marcheur.demarrer(
        trace: _trace,
        trailId: testTrailConfig.id,
        sessionId: 'sim-772',
      ),
      isTrue,
    );
    return (marcheur: marcheur, horloge: horloge);
  }

  // =========================================================================
  // 1. « EN DEMO LE CENTRAGE DU POINT D'AVANCEMENT NE CENTRE RIEN »
  // =========================================================================
  group('772 — la position connue survit au rechargement du robinet', () {
    test(
      'le robinet garde la position, donc la position courante la garde aussi',
      () async {
        final m = marcheurEnMarche();
        final container = conteneurDeDemo(m.marcheur);
        // Quelqu'un ECOUTE, comme la carte : sans ecoute il ne vit pas.
        container.listen(currentPositionProvider, (_, _) {});

        m.horloge.derniere!.avancer(10);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);
        final avant = container.read(currentPositionProvider).value;
        expect(
          avant,
          isNotNull,
          reason: 'la demo doit d abord AVOIR une position a perdre',
        );

        // CE QUE FAIT UN CHANGEMENT DE PROFIL GPS, ou une entree/sortie de
        // demo : le robinet est reconstruit sous les pieds de ses lecteurs.
        container.invalidate(positionControllerProvider);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        // LE ROBINET, LUI, N'A RIEN OUBLIE. C'est la mesure qui designe le
        // coupable : si lui sait encore, celui qui ne sait plus a tort.
        final robinet = container.read(locationProvider);
        expect(
          robinet.value,
          isNotNull,
          reason:
              'le robinet retient la derniere position pendant un '
              'rechargement — si ce n est plus vrai, cette garde ne mesure '
              'plus rien',
        );

        expect(
          container.read(currentPositionProvider).value,
          isNotNull,
          reason:
              'la position courante s est effacee alors que le robinet la '
              'retenait encore : le marqueur disparait et « centrer sur moi » '
              'se rabat sur le trace',
        );
        expect(
          container.read(currentPositionProvider).value!.latitude,
          closeTo(robinet.value!.latitude, 1e-9),
          reason:
              'la position gardee doit etre CELLE du robinet, pas une autre',
        );
      },
    );

    testWidgets(
      'apres un rechargement, « centrer sur moi » amene la camera sur le '
      'marcheur simule',
      (tester) async {
        final m = marcheurEnMarche();
        final container = conteneurDeDemo(m.marcheur);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: TranslationProvider(
              child: MaterialApp(
                home: Scaffold(
                  body: MapContent(
                    trailId: testTrailConfig.id,
                    rawPoints: _trace,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        for (var i = 0; i < 20; i++) {
          m.horloge.derniere?.avancer(1);
          await tester.pump(const Duration(milliseconds: 10));
        }

        container.invalidate(positionControllerProvider);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 10));

        final marcheurOu = container.read(currentPositionProvider).value;
        expect(
          marcheurOu,
          isNotNull,
          reason: 'sans position connue le bouton n a rien a viser',
        );

        await tester.tap(find.byTooltip(t.a11y.centerOnMe));
        await tester.pump();

        final camera = container.read(mapControllerProvider).camera.center;
        expect(
          camera.latitude,
          closeTo(marcheurOu!.latitude, 1e-6),
          reason:
              'le bouton doit recentrer sur le MARCHEUR SIMULE, comme il '
              'recentre sur le randonneur en vrai',
        );
        expect(camera.longitude, closeTo(marcheurOu.longitude, 1e-6));
      },
    );

    testWidgets('sans aucune position, le bouton ne reste pas muet', (
      tester,
    ) async {
      // LA SIMULATION N'EST PAS LANCEE : il n'y a alors vraiment aucune
      // position, et c'est le seul cas ou le repli est legitime. Il doit le
      // DIRE — un bouton de carte qui ne repond rien est un bouton mort.
      final horloge = _Horloge();
      final marcheur = MarcheurSimule(
        minuterie: horloge.fabrique,
        maintenant: () => _depart,
        surveillerLeCycleDeVie: false,
      );
      addTearDown(marcheur.fermer);
      final container = conteneurDeDemo(marcheur);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(
                body: MapContent(
                  trailId: testTrailConfig.id,
                  rawPoints: _trace,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(container.read(currentPositionProvider).value, isNull);

      await tester.tap(find.byTooltip(t.a11y.centerOnMe));
      await tester.pump();

      expect(
        find.text(t.gps.centeredOnTrack),
        findsOneWidget,
        reason:
            'le bouton doit dire pourquoi il n a pas centre sur le '
            'randonneur',
      );
    });
  });

  // =========================================================================
  // 2. ET 3. UN DESSIN, UNE IDEE
  // =========================================================================

  /// Le dessin que ce chemin d'icone designe REELLEMENT, trace bicolore
  /// compris : `assets/icons/programme.svg` et
  /// `assets/icons/rubriques-duo/programme.svg` sont le MEME dessin, et c'est
  /// precisement ce que la garde doit voir.
  String dessinDe(String asset) => iconeBicolorePour(asset)?.duo ?? asset;

  group('772 — un point d eau n est pas de la pluie', () {
    test('le dessin du point d eau n est pas celui de la pluie', () {
      final eau = PoiTypeConfig.getStyle('water').icon;
      expect(
        dessinDe(eau),
        isNot(dessinDe(StepwaysIcons.pluie)),
        reason:
            'une source et une averse sont deux choses differentes : '
            'verbatim de Christophe, « L icone source est toujours un nuage '
            'avec de la pluie ???? »',
      );
      expect(
        dessinDe(eau),
        isNot(dessinDe(StepwaysIcons.nuageux)),
        reason: 'un point d eau n est pas un nuage',
      );
    });

    test('aucun type de point d interet ne porte un dessin de meteo', () {
      // La meteo a ses propres dessins ; aucun d'eux ne designe un lieu du
      // terrain. Si l'un reapparait dans le registre des points d'interet,
      // c'est qu'une clef a de nouveau glisse.
      final meteo = {
        for (final m in [
          StepwaysIcons.pluie,
          StepwaysIcons.nuageux,
          StepwaysIcons.orage,
          StepwaysIcons.neige,
          StepwaysIcons.brouillard,
          StepwaysIcons.soleil,
        ])
          dessinDe(m),
      };
      for (final type in PoiTypeConfig.knownTypes) {
        expect(
          meteo,
          isNot(contains(dessinDe(PoiTypeConfig.getStyle(type).icon))),
          reason:
              'le point d interet « $type » est dessine avec une icone de '
              'meteo',
        );
      }
    });
  });

  group('772 — deux cartes du cockpit ne partagent jamais un dessin', () {
    testWidgets('chaque carte de « Preparer » porte SON dessin', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 6000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(
                body: SingleChildScrollView(
                  child: HubPrepareSection(
                    trailId: testTrailConfig.id,
                    initiallyExpanded: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final cartes = tester
          .widgetList<QuickAccessCard>(
            find.byType(QuickAccessCard, skipOffstage: false),
          )
          .toList();
      expect(
        cartes.length,
        greaterThan(8),
        reason:
            'la section « Preparer » n a pas ete construite en entier : '
            'cette garde ne mesurerait alors presque rien',
      );

      final parDessin = <String, List<String>>{};
      for (final carte in cartes) {
        final cle = carte.rubrique != null
            ? carte.rubrique!.duo
            : dessinDe(carte.icon!);
        parDessin.putIfAbsent(cle, () => []).add(carte.title);
      }

      final partages = parDessin.entries
          .where((e) => e.value.length > 1)
          .map((e) => '${e.value.join(" + ")} -> ${e.key}')
          .toList();

      expect(
        partages,
        isEmpty,
        reason:
            'deux cartes du cockpit montrent le meme dessin : le '
            'randonneur ne peut plus les distinguer d un coup d oeil. '
            'Partages mesures : ${partages.join(" | ")}',
      );
    });
  });
}
