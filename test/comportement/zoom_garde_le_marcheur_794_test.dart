/// TACHE 794 — LE ZOOM CHASSAIT LE MARCHEUR HORS DE L'ECRAN.
///
/// CONSEQUENCE DIRECTE DE LA TACHE 790, qui l'avait mesuree et signalee sans
/// la corriger. Le 790 a applique la regle de Christophe, mot pour mot : « Il
/// faut la centrer sur les 50% de l'écran du haut ». Le marcheur recentre
/// tombe donc au QUART de la hauteur depuis le haut, et non au milieu.
/// Consequence arithmetique : le centre de la CAMERA n'est plus le marcheur,
/// il est un quart de hauteur plus bas, derriere le panneau de chiffres, et
/// personne ne le voit.
///
/// Or les boutons + et − appelaient `move(camera.center, zoom ± 1)` : ils
/// tenaient en place ce centre invisible. Chaque appui DOUBLAIT donc l'ecart
/// entre le marcheur et le haut de l'ecran. Sur un cadre de 390 x 844 :
///
///   recentrage      211,0 px du haut   (le quart de 844 : correct)
///   + un cran         0,0 px           (contre le bord)
///   + deux crans   −422,0 px           (dehors)
///   + trois crans −1266,0 px           (tres dehors)
///
/// LA REGLE RETENUE, EN UNE PHRASE. Le zoom s'appuie sur le point de la carte
/// qui occupe le milieu de la moitie haute — le centre de ce que le
/// randonneur voit vraiment — et ce point-la ne bouge plus d'un pixel.
///
/// POURQUOI PAS « LE ZOOM SUIT LE MARCHEUR », qui etait la correction la plus
/// courte. Parce qu'elle est fausse des que le randonneur a fait glisser la
/// carte a la main : le marcheur peut etre hors du cadre, et zoomer autour
/// d'un point qu'on ne voit pas est le meme defaut avec un autre centre.
/// L'ancre est donc un PIXEL et non un objet. Elle garde le marcheur
/// immobile juste apres un recentrage — c'est exactement la que le
/// recentrage l'a pose — et garde le paysage immobile le reste du temps.
/// Les deux cas sont joues ici.
///
/// CE QUE CES GARDES MESURENT, ET POURQUOI ELLES NE SONT PAS CIRCULAIRES.
/// Le correctif LIT son ancre avec `offsetToCrs` et la REPOSE avec le
/// parametre `offset` de `move`. Les gardes, elles, ne relisent ni l'un ni
/// l'autre : elles demandent a la camera ou un lieu CONNU tombe a l'ecran
/// apres le geste (`latLngToScreenOffset`). Trois chemins differents de
/// `flutter_map`, et c'est le troisieme qui a le dernier mot.
///
/// PLUSIEURS CRANS D'AFFILEE, ET C'EST LE POINT. Le defaut s'aggrave a chaque
/// appui : un seul zoom l'aurait montre a 0 px, c'est-a-dire pile au bord,
/// donc discutable. Trois crans le montrent a 1266 px dehors.
///
/// CE QUE CES GARDES NE REFONT PAS. Le lot 772 a corrige la VALEUR que le
/// bouton « centrer sur moi » recoit, le lot 790 son PLACEMENT. Ici il n'est
/// question que de ce que le ZOOM fait de ce placement. Ni l'un ni l'autre
/// n'est defait.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart'
    show trailConfigProvider;
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/services/session_demo.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/map/map_facade.dart'
    show currentPositionProvider;
import 'package:moteur_gr/features/map/providers/current_position_provider.dart'
    show CurrentPosition;
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/centre_de_la_moitie_haute.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_content.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_controller.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Metres par degre de latitude : la trace suit un meridien.
const double _metresParDegre = 111194.93;

/// LA TOLERANCE ANNONCEE : UN PIXEL LOGIQUE, comme au 790. L'ancre fait un
/// aller-retour par la projection a CHAQUE cran — lue en pixels, reportee en
/// coordonnees, reposee en pixels — et trois crans enchainent trois
/// aller-retours. LA MESURE REELLE RESTE EXACTE : 211,0 px attendus, 211,0 px
/// trouves, a tous les crans joues ici.
const double _tolerancePx = 1.0;

/// LE CADRE D'UN VRAI TELEPHONE, et pas la fenetre carree du banc de test :
/// la seule mesure comparable a ce que Christophe a sous les yeux.
const Size _telephone = Size(390, 844);

/// OU LE CENTRE VISIBLE TOMBE SUR CE CADRE-LA : le quart de 844.
const double _ouLeCentreVisibleTombe = 844.0 * fractionDuCentreHaut;

/// LES CRANS JOUES A LA SUITE. Trois en zoom avant, puis deux en arriere : le
/// defaut s'aggravant a chaque appui, c'est la SUITE qui le montre.
const List<double> _cransEnAvant = [1, 2, 3];

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

/// Deux etapes : sans elles la carte n'a pas de cadrage d'etape.
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

/// Le marcheur est pose A MI-TRACE, loin des bords.
final LatLng _ouEstLeMarcheur = LatLng(_trace[30].lat, 3.0);

/// UNE MINUTERIE INERTE, comme au 790 : ces gardes mesurent un PLACEMENT, pas
/// ce que la marche simulee produit. Elles n'ont aucun battement a attendre.
class _MinuterieInerte implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

/// Une session FIGEE : ces gardes mesurent la carte, pas la machine de
/// session.
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

  // =========================================================================
  // 1. L'ARITHMETIQUE DU DEFAUT ET CELLE DU REMEDE, SANS AUCUN WIDGET
  //
  // Une camera posee a la main, la projection de `flutter_map`, et les deux
  // formules mises cote a cote. C'est ici que les PIXELS AVANT et APRES
  // s'ecrivent noir sur blanc, a chaque cran.
  // =========================================================================
  group('794 — ce que chaque cran de zoom fait du marcheur', () {
    /// Une camera de telephone, centree comme le 790 la laisse : le marcheur
    /// au quart du haut, donc le CENTRE un quart de hauteur plus bas.
    MapCamera cameraApresRecentrage() {
      final nue = MapCamera(
        crs: const Epsg3857(),
        center: _ouEstLeMarcheur,
        zoom: 13,
        rotation: 0,
        nonRotatedSize: _telephone,
      );
      // Ce que `move(marcheur, 13, offset: decalage)` produit comme centre,
      // par la formule meme de `moveRaw` : centre = unproject(project(cible)
      // − decalage).
      final vise = nue.projectAtZoom(_ouEstLeMarcheur, 13);
      return nue.withPosition(
        center: nue.unprojectAtZoom(
          vise - decalageVersLeCentreHaut(_telephone),
          13,
        ),
      );
    }

    /// Ce que fait une camera apres un `move(cible, zoom, offset: decalage)`.
    MapCamera apresUnMove(
      MapCamera camera,
      LatLng cible,
      double zoom, {
      Offset decalage = Offset.zero,
    }) {
      final vise = camera.projectAtZoom(cible, zoom);
      return camera.withPosition(
        center: camera.unprojectAtZoom(vise - decalage, zoom),
        zoom: zoom,
      );
    }

    test('le point de depart est bien celui du 790 : 211,0 px du haut', () {
      final camera = cameraApresRecentrage();
      expect(
        camera.latLngToScreenOffset(_ouEstLeMarcheur).dy,
        closeTo(_ouLeCentreVisibleTombe, _tolerancePx),
        reason:
            'sans ce point de depart les mesures qui suivent ne veulent '
            'rien dire',
      );
      // ET LE CENTRE DE CAMERA N'EST PLUS LE MARCHEUR : c'est toute la cause
      // de ce lot.
      expect(
        camera.latLngToScreenOffset(camera.center).dy,
        closeTo(_telephone.height / 2, _tolerancePx),
        reason:
            'le centre de camera est au MILIEU du cadre, un quart plus '
            'bas que le marcheur — sous le panneau de chiffres',
      );
    });

    test('LE DEFAUT : autour du centre de camera, le marcheur sort', () {
      // LA FORMULE D'AVANT, mot pour mot : `move(camera.center, zoom + n)`,
      // sans decalage. Ce test n'est pas la pour defendre ce code — il est
      // parti — mais pour FIXER les pixels du defaut, qui sont la seule
      // facon de dire que le remede change quelque chose.
      final depart = cameraApresRecentrage();
      final mesures = <double>[];
      var camera = depart;
      for (final _ in _cransEnAvant) {
        camera = apresUnMove(camera, camera.center, camera.zoom + 1);
        mesures.add(camera.latLngToScreenOffset(_ouEstLeMarcheur).dy);
      }

      // LES TROIS NOMBRES DU RAPPORT DU 790, RETROUVES : 0, puis −422, puis
      // −1266. A chaque cran l'ecart au haut de l'ecran double.
      expect(mesures[0], closeTo(0.0, _tolerancePx));
      expect(mesures[1], closeTo(-422.0, _tolerancePx));
      expect(mesures[2], closeTo(-1266.0, _tolerancePx));

      // DES LE DEUXIEME CRAN LE MARCHEUR EST DEHORS, et au premier il est
      // pile sur le bord : c'est pour cela qu'un seul cran ne suffisait pas
      // a montrer le defaut.
      expect(mesures[1], lessThan(0));
      expect(mesures[2], lessThan(mesures[1]));
    });

    test('LE REMEDE : autour du centre visible, rien ne bouge', () {
      var camera = cameraApresRecentrage();
      for (final cran in _cransEnAvant) {
        final ancre = ancreDuCentreVisible(camera);
        expect(ancre, isNotNull, reason: 'cadre de telephone : mesurable');
        camera = apresUnMove(
          camera,
          ancre!,
          camera.zoom + 1,
          decalage: decalageVersLeCentreHaut(camera.nonRotatedSize),
        );
        final ou = camera.latLngToScreenOffset(_ouEstLeMarcheur).dy;
        expect(
          ou,
          closeTo(_ouLeCentreVisibleTombe, _tolerancePx),
          reason:
              'apres $cran cran(s) de zoom avant, le marcheur doit etre '
              'reste a ${_ouLeCentreVisibleTombe.toStringAsFixed(1)} px du '
              'haut ; mesure ${ou.toStringAsFixed(1)} px',
        );
      }
      // ET ON REVIENT : deux crans en arriere ne le bougent pas davantage.
      for (var cran = 1; cran <= 2; cran++) {
        final ancre = ancreDuCentreVisible(camera)!;
        camera = apresUnMove(
          camera,
          ancre,
          camera.zoom - 1,
          decalage: decalageVersLeCentreHaut(camera.nonRotatedSize),
        );
        expect(
          camera.latLngToScreenOffset(_ouEstLeMarcheur).dy,
          closeTo(_ouLeCentreVisibleTombe, _tolerancePx),
          reason: 'apres $cran cran(s) de zoom ARRIERE le marcheur a bouge',
        );
      }
    });

    test('LE CAS GENERAL : meme sans marcheur a l ecran, le paysage tient', () {
      // LE RANDONNEUR A FAIT GLISSER LA CARTE : la camera regarde 30 km au
      // nord, le marcheur est loin hors du cadre. La regle ne lui demande
      // rien, et doit donc valoir quand meme.
      final ailleurs = MapCamera(
        crs: const Epsg3857(),
        center: LatLng(_ouEstLeMarcheur.latitude + 0.3, 3.0),
        zoom: 13,
        rotation: 0,
        nonRotatedSize: _telephone,
      );
      expect(
        ailleurs.latLngToScreenOffset(_ouEstLeMarcheur).dy,
        greaterThan(_telephone.height),
        reason: 'ce cas-ci ne vaut que si le marcheur est bien DEHORS',
      );

      // LE LIEU QU'ON REGARDE, releve une fois pour toutes avant de zoomer.
      final regarde = ancreDuCentreVisible(ailleurs)!;
      var camera = ailleurs;
      for (final cran in _cransEnAvant) {
        final ancre = ancreDuCentreVisible(camera)!;
        final vise = camera.projectAtZoom(ancre, camera.zoom + 1);
        camera = camera.withPosition(
          center: camera.unprojectAtZoom(
            vise - decalageVersLeCentreHaut(camera.nonRotatedSize),
            camera.zoom + 1,
          ),
          zoom: camera.zoom + 1,
        );
        final ou = camera.latLngToScreenOffset(regarde).dy;
        expect(
          ou,
          closeTo(_ouLeCentreVisibleTombe, _tolerancePx),
          reason:
              'apres $cran cran(s), le lieu regarde doit etre reste a '
              '${_ouLeCentreVisibleTombe.toStringAsFixed(1)} px du haut ; '
              'mesure ${ou.toStringAsFixed(1)} px',
        );
      }
    });

    test('une camera pas encore mise en page n a pas d ancre', () {
      // Avant sa premiere mise en page, la camera porte une taille infinie
      // negative : il n'y a aucun pixel a interroger. `null`, et l'appelant
      // retombe sur l'ancien geste — imparfait, jamais a l'infini.
      final avantMiseEnPage = MapCamera(
        crs: const Epsg3857(),
        center: _ouEstLeMarcheur,
        zoom: 13,
        rotation: 0,
        nonRotatedSize: MapCamera.kImpossibleSize,
      );
      expect(ancreDuCentreVisible(avantMiseEnPage), isNull);
      expect(cadreMesurable(MapCamera.kImpossibleSize), isFalse);
      expect(cadreMesurable(Size.zero), isFalse);
      expect(cadreMesurable(const Size(390, -10)), isFalse);
      expect(cadreMesurable(_telephone), isTrue);
    });
  });

  // =========================================================================
  // 2. LE GESTE, JOUE SUR LA VRAIE CARTE
  //
  // Les vrais boutons, le vrai ecran, les vraies surcouches. C'est cette
  // garde-ci qui rougit sur le code d'avant.
  // =========================================================================
  group('794 — les boutons + et − sur la carte montee', () {
    /// Monte la carte sur un telephone, dans la configuration la plus chargee
    /// (demo, marche simulee), et rend le conteneur.
    Future<ProviderContainer> monteLaCarte(WidgetTester tester) async {
      tester.view.physicalSize = _telephone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          trailConfigProvider.overrideWithValue(testTrailConfig),
          gpxTrackProvider(
            testTrailConfig.id,
          ).overrideWith((ref) async => _trace),
          stagesProvider(
            testTrailConfig.id,
          ).overrideWith((ref) async => _etapes),
          enDemoProvider.overrideWithValue(true),
          currentPositionProvider.overrideWithValue(
            AsyncData(
              CurrentPosition(
                latitude: _ouEstLeMarcheur.latitude,
                longitude: _ouEstLeMarcheur.longitude,
                altitude: 1000,
              ),
            ),
          ),
          trekSessionManagerProvider.overrideWith(
            () => _SessionFigee(
              TrackingSessionState(
                status: TrackingSessionStatus.recording,
                session: TrekSession(
                  id: 'sim-794',
                  trailId: testTrailConfig.id,
                  startedAt: _depart,
                  status: 'active',
                ),
              ),
            ),
          ),
          marcheurSimuleProvider.overrideWithValue(
            MarcheurSimule(
              minuterie: (periode, action) => _MinuterieInerte(),
              maintenant: () => _depart,
              surveillerLeCycleDeVie: false,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

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
      return container;
    }

    testWidgets(
      'TROIS crans de zoom avant d affilee ne deplacent pas le marcheur',
      (tester) async {
        final container = await monteLaCarte(tester);
        final controleur = container.read(mapControllerProvider);

        // ON PART DU RECENTRAGE, parce que c'est la sequence de Christophe :
        // il appuie sur « centrer sur moi », puis il zoome.
        await tester.tap(find.byTooltip(t.a11y.centerOnMe));
        await tester.pump();

        final hauteur = controleur.camera.nonRotatedSize.height;
        expect(
          hauteur,
          _telephone.height,
          reason: 'le cadre de carte doit remplir le telephone declare',
        );
        final attendu = hauteur * fractionDuCentreHaut;
        // LE ZOOM D'OUVERTURE EST RELEVE, PAS SUPPOSE. Il vient du cadrage
        // d'etape (`cadrageDOuverture`) et vaut 15,75 sur cette trace de
        // 3 km : un nombre en dur ici aurait rougi au premier reglage du
        // cadrage, pour une raison qui n'a rien a voir avec le zoom.
        final zoomDOuverture = controleur.camera.zoom;

        expect(
          controleur.camera.latLngToScreenOffset(_ouEstLeMarcheur).dy,
          closeTo(attendu, _tolerancePx),
          reason:
              'le 790 doit etre en place avant que le 794 mesure quoi que '
              'ce soit',
        );

        // LES TROIS APPUIS, MESURES UN PAR UN. C'est la boucle qui compte :
        // sur le code d'avant, le premier appui donnait 0,0 px — pile sur le
        // bord, donc discutable — et le deuxieme −422,0 px, dehors.
        for (final cran in _cransEnAvant) {
          await tester.tap(find.byTooltip(t.a11y.zoomIn));
          await tester.pump();

          final ou = controleur.camera
              .latLngToScreenOffset(_ouEstLeMarcheur)
              .dy;
          expect(
            ou,
            closeTo(attendu, _tolerancePx),
            reason:
                'LE DEFAUT DE CHRISTOPHE : apres ${cran.toInt()} appui(s) sur '
                '+, le marcheur doit etre reste a '
                '${attendu.toStringAsFixed(1)} px du haut. Mesure : '
                '${ou.toStringAsFixed(1)} px sur un cadre de '
                '${hauteur.toStringAsFixed(1)} px. Le code d avant donnait '
                '0,0 px au premier cran, −422,0 px au deuxieme et −1266,0 px '
                'au troisieme — hors ecran.',
          );
          // ET IL EST BIEN A L'ECRAN, ce qui est la formulation la plus
          // directe du retour : le zoom ne doit pas chasser le marcheur.
          expect(
            ou,
            greaterThan(0),
            reason:
                'le marcheur est sorti par le HAUT apres '
                '${cran.toInt()} cran(s) : ${ou.toStringAsFixed(1)} px',
          );
          expect(
            ou,
            lessThan(hauteur / 2),
            reason:
                'le marcheur doit rester dans la MOITIE HAUTE, celle que '
                'le panneau de chiffres ne recouvre pas',
          );
        }

        // LE ZOOM A VRAIMENT EU LIEU : sans cette ligne, un bouton inerte
        // passerait la garde avec les honneurs.
        expect(
          controleur.camera.zoom,
          closeTo(zoomDOuverture + _cransEnAvant.length, 0.001),
          reason:
              'trois appuis sur + doivent avoir monte le zoom de trois '
              'crans exactement depuis le cadrage d etape '
              '(${zoomDOuverture.toStringAsFixed(2)})',
        );
      },
    );

    testWidgets('et DEUX crans de zoom arriere ne le deplacent pas davantage', (
      tester,
    ) async {
      final container = await monteLaCarte(tester);
      final controleur = container.read(mapControllerProvider);

      await tester.tap(find.byTooltip(t.a11y.centerOnMe));
      await tester.pump();

      final hauteur = controleur.camera.nonRotatedSize.height;
      final attendu = hauteur * fractionDuCentreHaut;
      final zoomAvant = controleur.camera.zoom;

      for (var cran = 1; cran <= 2; cran++) {
        await tester.tap(find.byTooltip(t.a11y.zoomOut));
        await tester.pump();

        final ou = controleur.camera.latLngToScreenOffset(_ouEstLeMarcheur).dy;
        expect(
          ou,
          closeTo(attendu, _tolerancePx),
          reason:
              'apres $cran appui(s) sur −, le marcheur doit etre reste '
              'a ${attendu.toStringAsFixed(1)} px du haut ; mesure '
              '${ou.toStringAsFixed(1)} px',
        );
        expect(ou, greaterThan(0), reason: 'sorti par le haut');
        expect(
          ou,
          lessThan(hauteur / 2),
          reason: 'le marcheur doit rester dans la MOITIE HAUTE',
        );
      }

      expect(
        controleur.camera.zoom,
        closeTo(zoomAvant - 2, 0.001),
        reason:
            'deux appuis sur − doivent avoir baisse le zoom de deux '
            'crans',
      );
    });

    testWidgets(
      'LE CAS GENERAL joue a la main : la carte glissee, puis zoomee',
      (tester) async {
        final container = await monteLaCarte(tester);
        final controleur = container.read(mapControllerProvider);

        // LE RANDONNEUR FAIT GLISSER LA CARTE du doigt, loin du marcheur.
        // C'est le geste, pas un appel de controleur : on veut que
        // `flutter_map` ait vraiment deplace sa camera.
        final avant = controleur.camera.center;
        await tester.drag(find.byType(FlutterMap), const Offset(0, -500));
        await tester.pumpAndSettle();
        expect(
          controleur.camera.center.latitude,
          isNot(closeTo(avant.latitude, 1e-9)),
          reason:
              'le glissement doit avoir deplace la camera, sinon ce cas '
              'ne joue rien',
        );

        final hauteur = controleur.camera.nonRotatedSize.height;
        final attendu = hauteur * fractionDuCentreHaut;

        // LE LIEU QU'ON REGARDE MAINTENANT, releve avant de zoomer. Ce n'est
        // plus le marcheur, et c'est tout l'objet de ce cas : la regle ne
        // demande jamais ou se trouve le marcheur.
        final regarde = ancreDuCentreVisible(controleur.camera);
        expect(regarde, isNotNull);

        for (final cran in _cransEnAvant) {
          await tester.tap(find.byTooltip(t.a11y.zoomIn));
          await tester.pump();

          final ou = controleur.camera.latLngToScreenOffset(regarde!).dy;
          expect(
            ou,
            closeTo(attendu, _tolerancePx),
            reason:
                'apres ${cran.toInt()} cran(s), le lieu que le randonneur '
                'regardait doit etre reste a '
                '${attendu.toStringAsFixed(1)} px du haut ; mesure '
                '${ou.toStringAsFixed(1)} px. Zoomer autour d un point '
                'invisible serait le meme defaut avec un autre centre.',
          );
        }
      },
    );
  });
}
