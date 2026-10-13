/// TACHE 790 — « ON A TOUJOURS CE POINT QUI N EST PAS CENTRE QUAND ON
/// CENTRE LA CARTE ».
///
/// Retour de Christophe du 10/10 16:17, mot pour mot. C'est la TROISIEME fois
/// qu'il revient sur le placement des choses sur cette carte : le SOS qui
/// masquait le trace, le SOS qui recouvrait un bouton, et maintenant le
/// marcheur qui se cache. La recette 778 l'avait releve dans les memes
/// termes : le bouton recentre bien, mais « il atterrit en bas de la zone
/// visible, a demi cache par le panneau d'info ».
///
/// LA REGLE, DE LA MAIN DE CHRISTOPHE, 10/10 16:18 : « Il est centré sur la
/// carte mais comme est cachée par le panneau de stat on croit qu'elle est en
/// bas. Il faut la centrer sur les 50% de l'écran du haut ». Le marcheur doit
/// donc tomber au milieu de la MOITIE HAUTE, c'est-a-dire au QUART de la
/// hauteur depuis le haut.
///
/// CE QUE CES GARDES MESURENT, ET POURQUOI ELLES NE SONT PAS CIRCULAIRES. Le
/// correctif passe un decalage en pixels a `MapController.move`, qui le
/// reporte dans la projection au zoom courant. Ces gardes, elles, ne
/// relisent pas ce decalage : elles demandent a la camera OU LE MARCHEUR
/// TOMBE A L'ECRAN apres le geste (`latLngToScreenOffset`). Deux chemins
/// differents de `flutter_map` — l'un pose, l'autre mesure — et c'est le
/// second qui a le dernier mot.
///
/// POURQUOI DEUX CONFIGURATIONS DE SURCOUCHES. La premiere piste etait de
/// mesurer la hauteur reellement occupee par les bandeaux, qui sont
/// CONDITIONNELS. Christophe a tranche plus court : une fraction fixe. La
/// consequence se mesure, et c'est l'objet des gardes jumelles — en demo le
/// haut de la carte occupe 80 px et le panneau du bas commence a 533 px ;
/// hors demo, 8 px et 593 px. Deux configurations franchement differentes,
/// et le marcheur tombe pourtant au MEME pixel. Si quelqu'un reintroduit un
/// jour une mesure des bandeaux, ces gardes divergeront et le diront.
///
/// CE QUE CES GARDES NE REFONT PAS. Le lot 772 a corrige la VALEUR que ce
/// bouton recoit — le robinet de position qui l'effacait pendant un
/// rechargement. Ici il n'est question que du PLACEMENT. Les gardes du 772
/// restent ; celle qui lisait le centre de la camera a ete reecrite en
/// position d'ecran, parce que le centre de la camera N'EST PLUS le marcheur
/// — c'est tout l'objet de ce lot — mais l'intention, elle, est intacte.
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
    show StageProgressBar, currentPositionProvider;
import 'package:moteur_gr/features/map/providers/current_position_provider.dart'
    show CurrentPosition;
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/barre_d_etape.dart';
import 'package:moteur_gr/features/trek/presentation/map/centre_de_la_moitie_haute.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_content.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_controller.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_overlays.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Metres par degre de latitude : la trace suit un meridien.
const double _metresParDegre = 111194.93;

/// LA TOLERANCE ANNONCEE : UN PIXEL LOGIQUE. Le decalage fait un
/// aller-retour par la projection — pose en pixels par `move`, reporte en
/// coordonnees, puis relu en pixels par `latLngToScreenOffset` — et peut en
/// revenir avec l'erreur d'arrondi des flottants. Un pixel est deja sous le
/// grain de l'oeil. LA MESURE REELLE, ELLE, EST EXACTE : 211,0 px attendus,
/// 211,0 px trouves, sur les quatre configurations jouees ici.
const double _tolerancePx = 1.0;

/// LE CADRE D'UN VRAI TELEPHONE, et pas la fenetre carree du banc de test.
/// La regle est une fraction : elle vaut a toute taille. Mais une mesure sur
/// 390 x 844 est une mesure qu'on peut comparer a ce que Christophe a sous
/// les yeux, et c'est la seule qui vaut comme preuve.
const Size _telephone = Size(390, 844);

/// OU LE MARCHEUR DOIT TOMBER SUR CE CADRE-LA, EN PIXELS, une fois pour
/// toutes : le quart de 844. Les deux gardes jumelles visent ce MEME nombre,
/// et c'est ainsi qu'elles se comparent l'une a l'autre sans se parler — un
/// decalage calcule sur la hauteur des bandeaux en donnerait deux.
const double _ouLeMarcheurDoitTomber = 844.0 * fractionDuCentreHaut;

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

/// Le marcheur est pose A MI-TRACE, donc loin des bords : un point deja
/// contre le haut du cadre tomberait au quart sans rien prouver.
final LatLng _ouEstLeMarcheur = LatLng(_trace[30].lat, 3.0);

/// UNE MINUTERIE INERTE, ET C'EST VOULU. La garde 772 fait avancer la
/// sienne, parce qu'elle mesure ce que la marche simulee PRODUIT. Celle-ci
/// mesure un PLACEMENT : elle pose la position elle-meme, au millionieme de
/// degre, et n'a donc aucun battement a attendre. Une minuterie qui ne part
/// jamais vaut mieux qu'un test qui dort.
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

/// Ce qu'une configuration donne a mesurer, tout en pixels logiques et tout
/// dans le repere du CADRE DE CARTE.
typedef Mesure = ({
  /// La hauteur du cadre de carte.
  double hauteurDuCadre,

  /// Ou le marcheur tombe, compte depuis le haut du cadre.
  double ouTombeLeMarcheur,

  /// Ou commence le panneau de chiffres du bas — la zone que l'oeil de
  /// Christophe ne voit pas.
  double hautDuPanneau,

  /// Ce que les surcouches du haut occupent.
  double hauteurDesBandeaux,
});

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  // =========================================================================
  // 1. LA REGLE ELLE-MEME : UN QUART DE HAUTEUR VERS LE HAUT
  // =========================================================================
  group('790 — la regle du centre visible', () {
    test('le point vise remonte d un QUART de la hauteur', () {
      // La regle de Christophe : le milieu de la moitie haute. `move` pose
      // le point a `hauteur / 2 + dy` du haut ; pour le mettre a
      // `hauteur / 4`, il faut donc exactement moins un quart de hauteur.
      expect(fractionDuCentreHaut, 0.25);
      expect(decalageVersLeCentreHaut(const Size(400, 800)).dy, -200.0);
      expect(
        decalageVersLeCentreHaut(const Size(400, 800)).dx,
        0.0,
        reason: 'la regle ne touche QUE la verticale',
      );
      expect(decalageVersLeCentreHaut(_telephone).dy, -844.0 / 4);
    });

    test('une taille pas encore mesuree ne decale RIEN', () {
      // Avant sa premiere mise en page, la camera porte une taille infinie
      // negative. Un quart d'infini enverrait la carte a l'infini : le
      // repli rend le centre geometrique, imparfait mais juste.
      expect(
        decalageVersLeCentreHaut(MapCamera.kImpossibleSize),
        Offset.zero,
        reason: 'un quart d infini n est pas un decalage',
      );
      expect(decalageVersLeCentreHaut(Size.zero), Offset.zero);
      expect(decalageVersLeCentreHaut(const Size(400, -10)), Offset.zero);
    });
  });

  // =========================================================================
  // 2. LE GESTE, JOUE ET MESURE
  // =========================================================================

  /// Monte la carte dans la configuration demandee, appuie sur « centrer sur
  /// moi », et rend les quatre mesures.
  ///
  /// LA POSITION EST POSEE, PAS SIMULEE AU BATTEMENT. Cette garde mesure un
  /// PLACEMENT : elle doit viser un point connu exactement, sinon la mesure
  /// ne veut rien dire. Le lot 772, lui, garde la mesure de la VALEUR.
  Future<Mesure> joueLeGeste(
    WidgetTester tester, {
    required bool enDemo,
  }) async {
    tester.view.physicalSize = _telephone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final overrides = [
      databaseProvider.overrideWithValue(db),
      trailConfigProvider.overrideWithValue(testTrailConfig),
      gpxTrackProvider(testTrailConfig.id).overrideWith((ref) async => _trace),
      stagesProvider(testTrailConfig.id).overrideWith((ref) async => _etapes),
      enDemoProvider.overrideWithValue(enDemo),
      currentPositionProvider.overrideWithValue(
        AsyncData(
          CurrentPosition(
            latitude: _ouEstLeMarcheur.latitude,
            longitude: _ouEstLeMarcheur.longitude,
            altitude: 1000,
          ),
        ),
      ),
      // EN DEMO, LA CONFIGURATION LA PLUS CHARGEE : marche simulee en cours,
      // donc barre d'etape pleine en bas et SOS deploye en haut. C'est celle
      // ou Christophe a vu le defaut.
      if (enDemo)
        trekSessionManagerProvider.overrideWith(
          () => _SessionFigee(
            TrackingSessionState(
              status: TrackingSessionStatus.recording,
              session: TrekSession(
                id: 'sim-790',
                trailId: testTrailConfig.id,
                startedAt: _depart,
                status: 'active',
              ),
            ),
          ),
        ),
      if (enDemo)
        marcheurSimuleProvider.overrideWithValue(
          MarcheurSimule(
            minuterie: (periode, action) => _MinuterieInerte(),
            maintenant: () => _depart,
            surveillerLeCycleDeVie: false,
          ),
        ),
    ];
    final container = ProviderContainer(overrides: overrides);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: TranslationProvider(
          child: MaterialApp(
            home: Scaffold(
              body: MapContent(trailId: testTrailConfig.id, rawPoints: _trace),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byTooltip(t.a11y.centerOnMe));
    await tester.pump();

    final camera = container.read(mapControllerProvider).camera;
    final hauteur = camera.nonRotatedSize.height;
    expect(
      hauteur.isFinite && hauteur > 0,
      isTrue,
      reason:
          'sans cadre mesure cette garde ne mesure rien — la carte n a pas '
          'ete mise en page',
    );

    // TOUT EST RAMENE AU REPERE DU CADRE DE CARTE. `latLngToScreenOffset`
    // compte depuis le coin de la carte ; `getTopLeft` compte depuis le coin
    // de la fenetre. Dans l'application il y a une barre de titre au-dessus
    // de la carte, donc les deux reperes ne coincident pas : on retranche
    // l'origine de la carte plutot que de supposer qu'elle est a zero.
    final origine = tester.getTopLeft(find.byType(FlutterMap)).dy;

    return (
      hauteurDuCadre: hauteur,
      ouTombeLeMarcheur: camera.latLngToScreenOffset(_ouEstLeMarcheur).dy,
      hautDuPanneau:
          tester.getTopLeft(find.byType(ActiveStageBar)).dy - origine,
      hauteurDesBandeaux: tester.getSize(find.byType(MapTopBanners)).height,
    );
  }

  /// La verification commune aux deux configurations.
  void leMarcheurEstAuQuartDuHaut(Mesure m, String configuration) {
    final attendu = m.hauteurDuCadre * fractionDuCentreHaut;
    final ou = m.ouTombeLeMarcheur;

    expect(
      ou,
      closeTo(attendu, _tolerancePx),
      reason:
          'LE DEFAUT DE CHRISTOPHE ($configuration) : le marcheur doit '
          'tomber au quart de la hauteur depuis le haut — au milieu de la '
          'moitie haute — et non au centre geometrique, ou le panneau de '
          'chiffres le recouvre. Mesure : ${ou.toStringAsFixed(1)} px sur '
          '${m.hauteurDuCadre.toStringAsFixed(1)} px de cadre, attendu '
          '${attendu.toStringAsFixed(1)} px.',
    );

    // ET IL N'EST PLUS AU MILIEU. C'est la formulation directe du defaut vu
    // trois fois : cette ligne-ci est celle qui rougit sur le code d'avant,
    // ou le marcheur tombait pile au centre du cadre.
    expect(
      (ou - m.hauteurDuCadre / 2).abs(),
      greaterThan(m.hauteurDuCadre * 0.2),
      reason:
          'le marcheur est reste au CENTRE GEOMETRIQUE ($configuration) : '
          'c est exactement le defaut — il atterrit derriere le panneau de '
          'chiffres, et l oeil le croit « en bas »',
    );

    // IL TOMBE DANS LA ZONE DEGAGEE, ET C'EST LA PREUVE QUI COMPTE : au-
    // dessus du panneau de chiffres, et dans le cadre.
    expect(
      ou,
      lessThan(m.hautDuPanneau),
      reason:
          'le marcheur tombe DERRIERE le panneau de chiffres '
          '($configuration) : panneau a ${m.hautDuPanneau.toStringAsFixed(1)}'
          ' px, marcheur a ${ou.toStringAsFixed(1)} px',
    );
    expect(ou, greaterThan(0), reason: 'hors cadre par le haut');
    expect(
      ou,
      lessThan(m.hauteurDuCadre / 2),
      reason: 'le marcheur doit rester dans la MOITIE HAUTE',
    );

    // LE MEME PIXEL DANS LES DEUX CONFIGURATIONS, et c'est la que les deux
    // gardes jumelles se rejoignent : meme cadre declare, meme nombre
    // attendu. Si l'une d'elles derive un jour et l'autre pas, c'est que le
    // calcul s'est remis a ecouter les bandeaux.
    expect(
      m.hauteurDuCadre,
      _telephone.height,
      reason: 'le cadre de carte doit remplir le telephone declare',
    );
    expect(
      ou,
      closeTo(_ouLeMarcheurDoitTomber, _tolerancePx),
      reason:
          'sur un cadre de ${_telephone.height.toStringAsFixed(0)} px, le '
          'marcheur tombe a ${_ouLeMarcheurDoitTomber.toStringAsFixed(1)} px '
          'du haut, dans TOUTES les configurations ($configuration en donne '
          '${ou.toStringAsFixed(1)})',
    );
  }

  testWidgets(
    '790 — EN DEMO, surcouches en place, le marcheur tombe au quart du haut',
    (tester) async {
      final m = await joueLeGeste(tester, enDemo: true);

      // LA CONFIGURATION EST BIEN LA PLUS CHARGEE, sinon les deux gardes
      // jumelles compareraient deux fois la meme chose.
      expect(
        m.hauteurDesBandeaux,
        greaterThan(50),
        reason:
            'en demo le haut de la carte doit porter ses surcouches (SOS '
            'deploye) — mesure a 80 px le 10/10',
      );
      expect(
        find.byType(StageProgressBar),
        findsOneWidget,
        reason: 'et le bas son panneau de chiffres',
      );

      leMarcheurEstAuQuartDuHaut(m, 'en demo, surcouches en place');
    },
  );

  testWidgets(
    '790 — HORS DEMO, surcouches reduites, le marcheur tombe au MEME quart',
    (tester) async {
      final m = await joueLeGeste(tester, enDemo: false);

      // LA CONFIGURATION EST FRANCHEMENT PLUS NUE : 8 px de surcouche en
      // haut au lieu de 80, et le panneau du bas commence 60 px plus bas.
      expect(
        m.hauteurDesBandeaux,
        lessThan(50),
        reason:
            'hors demo le haut de la carte doit etre degage — mesure a 8 px '
            'le 10/10 ; si cette configuration se charge, la garde jumelle '
            'ne prouve plus l independance aux bandeaux',
      );

      leMarcheurEstAuQuartDuHaut(m, 'hors demo, surcouches reduites');
    },
  );
}
