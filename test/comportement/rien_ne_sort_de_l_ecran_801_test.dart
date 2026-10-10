/// LA GARDE QUI REFUSE QU UNE COMMANDE DE LA CARTE SORTE DE L ECRAN (801).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE, ET CE QUE LA MESURE A TROUVE
/// ---------------------------------------------------------------------------
///
/// LE SOUPCON : sur les deux captures du 10/10 (798_1 et 798_3a), le disque
/// rouge du SOS paraissait ampute par le bord droit de l ecran. Pour un bouton
/// de SECOURS, c est le pire endroit ou se tromper.
///
/// LA MESURE DIT LE CONTRAIRE, ET ELLE EST NETTE. Sur les deux images, en
/// 1 080 x 2 400, le disque occupe les colonnes 850 a 1 036 : 187 px de large
/// pour 188 px de haut — un cercle COMPLET, pas une tranche — et il laisse 43
/// px entre lui et le bord. A la densite de l appareil (2,625), cela fait un
/// bouton de 72 dp avec 16 dp de marge : exactement ce que le lot 762 a ecrit
/// dans [SosDuCoteDeLaMain.margeLaterale]. Le SOS ETAIT ENTIER. Ce fichier ne
/// repare donc rien sur lui : il VERROUILLE ce qui etait deja juste.
///
/// LE VOISIN ORANGE, LUI, TOUCHAIT BIEN LE DERNIER PIXEL — et ce n est pas un
/// bouton. Sa couleur, relevee au pixel, est `#E65100`, c est-a-dire
/// `CouleursSemantiques.pointPointDeVue`, et non le `#FB8C00` de la demo
/// (`AppTheme.orangeDifficile`). C est un MARQUEUR DE POINT DE VUE de la
/// carte, avec son liseré blanc et son icone d oeil : un objet pose sur une
/// COORDONNEE, que `flutter_map` peint centre sur son point et que le cadre de
/// carte rogne a ses bornes. Un marqueur dont le lieu tombe au bord de la vue
/// est a moitie visible, exactement comme les toponymes « Ciamanna… » et
/// « …apola » qu on lit tronques sur les memes captures. C est de la
/// cartographie, pas un defaut de mise en page.
///
/// D OU LA PORTEE DE CETTE GARDE, ET SA LIMITE ASSUMEE. Elle mesure les
/// COMMANDES — ce que l application pose sur la carte et que le doigt doit
/// pouvoir atteindre : le SOS, la photo, les calques, le zoom, « centrer sur
/// moi », la barre d etape, les bandeaux d alerte. Elle NE mesure PAS le
/// contenu cartographique, qui a le droit d etre coupe par le bord. Confondre
/// les deux aurait donne une garde rouge des la premiere carte affichee — et
/// une garde rouge au premier jour ne garde rien.
///
/// ---------------------------------------------------------------------------
/// POURQUOI MESURER, ET NON ATTENDRE UNE EXCEPTION
/// ---------------------------------------------------------------------------
///
/// Flutter ne crie que sur un debordement de `Flex` (les rayures jaunes). Un
/// enfant pousse hors cadre par un `Positioned`, un `Transform`, une marge
/// oubliee ou une largeur mal calculee ne leve RIEN : il est peint, puis
/// rogne, et tout le monde est content sauf le doigt qui le cherche. La seule
/// facon de le voir est de demander a chaque boite OU ELLE TOMBE. C est la
/// lecon de `aucun_texte_coupe_749_test.dart`, et ce fichier la reprend sur la
/// geometrie plutot que sur le texte.
///
/// LES QUATRE LARGEURS, ET LES DEUX MAINS. 320 dp est le plus petit telephone
/// encore vendu ; 412 le plus large courant. Et le SOS change de cote avec la
/// main dominante depuis le lot 762 : une marge juste a droite et oubliee a
/// gauche ne se verrait que chez les gauchers. Huit configurations, donc.
///
/// LE TEMOIN, SANS QUOI LA GARDE N AFFIRMERAIT RIEN. Le code d aujourd hui est
/// sain — c est ce que la mesure des captures a etabli — et une garde verte
/// sur du code sain ne prouve pas qu elle sait voir. Le dernier test lui
/// soumet donc une mise en page VOLONTAIREMENT fautive, un bouton pousse de
/// 40 px au-dela du bord, et exige qu elle la REFUSE en nommant le coupable.
library;

import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:moteur_gr/features/settings/settings_facade.dart'
    show DominantHand, DominantHandValues, settingsProvider;
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/trek/data/marcheur_simule_providers.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_content.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_overlays.dart';
import 'package:moteur_gr/features/trek/presentation/map/sos_du_cote_de_la_main.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import 'les_chiffres_de_la_demo_762_appuis.dart' show ReglagesFixes;

/// Metres par degre de latitude : la trace suit un meridien.
const double _metresParDegre = 111194.93;

/// LES LARGEURS DE TELEPHONE MESUREES.
///
/// 320 est le plus petit encore vendu, 412 le plus large courant. 390 est
/// celui des captures de Christophe une fois ramene en points logiques.
const List<double> kLargeursTelephone = <double>[320, 360, 390, 412];

/// La hauteur du cadre : constante, ce fichier ne mesure que l horizontale.
const double kHauteurTelephone = 844;

/// LA TOLERANCE : un centieme de point logique.
///
/// Elle n absorbe que l arrondi des flottants de la mise en page, jamais un
/// debordement reel — le plus petit defaut visible se compte en points
/// entiers.
const double kToleranceLogique = 0.01;

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

/// Deux etapes : sans elles la carte n a pas de cadrage d etape.
final List<StageModel> _etapes = <StageModel>[
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
final LatLng _ouEstLeMarcheur = LatLng(_trace[30].lat, 3.0);

/// Une minuterie qui ne part jamais : cette garde mesure un PLACEMENT.
class _MinuterieInerte implements Timer {
  @override
  void cancel() {}

  @override
  bool get isActive => false;

  @override
  int get tick => 0;
}

/// Une session FIGEE en marche : le SOS n existe que pendant un trek.
class _SessionFigee extends TrekSessionManagerNotifier {
  _SessionFigee(this._etat);

  final TrackingSessionState _etat;

  @override
  TrackingSessionState build() => _etat;
}

/// Ce qu une boite depasse, et de combien.
typedef Sortie = ({String quoi, double gauche, double droite, double largeur});

/// Dit lesquelles des boites sous [racine] sortent de [0, largeur].
///
/// ELLE MESURE CHAQUE DESCENDANT, pas seulement celui qu on soupconne : le
/// mandat de ce lot est « pas seulement le SOS ». Les boites sans taille (non
/// mises en page, non attachees) sont ignorees : elles n occupent rien, elles
/// ne peuvent rien depasser.
List<Sortie> sortiesDeLEcran(
  WidgetTester tester,
  Finder racine,
  double largeur,
) {
  final out = <Sortie>[];
  final elements = find
      .descendant(of: racine, matching: find.byWidgetPredicate((_) => true))
      .evaluate();
  for (final e in elements) {
    final ro = e.renderObject;
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) continue;
    if (ro.size.isEmpty) continue;
    final Offset coin;
    try {
      coin = ro.localToGlobal(Offset.zero);
    } on Object {
      continue; // pas de transformation vers l ecran : rien a mesurer
    }
    final gauche = coin.dx;
    final droite = coin.dx + ro.size.width;
    if (gauche < -kToleranceLogique || droite > largeur + kToleranceLogique) {
      out.add((
        quoi: e.widget.runtimeType.toString(),
        gauche: gauche,
        droite: droite,
        largeur: largeur,
      ));
    }
  }
  return out;
}

/// Un reproche lisible, pour que le diff dise OU regarder.
String ditLaSortie(Sortie s) =>
    '${s.quoi} : de ${s.gauche.toStringAsFixed(1)} a '
    '${s.droite.toStringAsFixed(1)} sur un ecran de '
    '${s.largeur.toStringAsFixed(0)} points';

void main() {
  late AppDatabase db;
  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() async => db.close());
  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  /// Monte la carte en DEMO, trek en cours, a [largeur] et pour [main].
  ///
  /// LA DEMO EST LA CONFIGURATION LA PLUS CHARGEE : marche simulee en cours,
  /// donc barre d etape pleine en bas et SOS deploye en haut. C est celle des
  /// captures de Christophe.
  Future<void> monteLaCarte(
    WidgetTester tester, {
    required double largeur,
    required DominantHand main,
  }) async {
    tester.view.physicalSize = Size(largeur, kHauteurTelephone);
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
        stagesProvider(testTrailConfig.id).overrideWith((ref) async => _etapes),
        enDemoProvider.overrideWithValue(true),
        settingsProvider.overrideWith(() => ReglagesFixes(main)),
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
                id: 'sim-801',
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
              body: MapContent(trailId: testTrailConfig.id, rawPoints: _trace),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('RIEN NE SORT DE L ECRAN (801)', () {
    for (final largeur in kLargeursTelephone) {
      for (final main in <DominantHand>[
        DominantHandValues.right,
        DominantHandValues.left,
      ]) {
        testWidgets(
          'les commandes de la carte tiennent dans ${largeur.toInt()} points '
          '(main $main)',
          (tester) async {
            await monteLaCarte(tester, largeur: largeur, main: main);

            // Les deux surcouches de commandes. Le contenu cartographique est
            // hors portee, et l en-tete dit pourquoi.
            final racines = <String, Finder>{
              'MapTopBanners': find.byType(MapTopBanners),
              'MapBottomBar': find.byType(MapBottomBar),
            };

            final sorties = <String>[];
            var mesures = 0;
            racines.forEach((nom, racine) {
              expect(
                racine,
                findsOneWidget,
                reason:
                    '$nom absent : la garde serait verte faute de mesurer '
                    'quoi que ce soit.',
              );
              final trouvees = sortiesDeLEcran(tester, racine, largeur);
              mesures += find
                  .descendant(
                    of: racine,
                    matching: find.byWidgetPredicate((_) => true),
                  )
                  .evaluate()
                  .length;
              sorties.addAll(trouvees.map((s) => '$nom > ${ditLaSortie(s)}'));
            });

            expect(
              mesures,
              greaterThan(10),
              reason:
                  'Moins de dix boites mesurees : les surcouches ne se sont '
                  'pas rendues, la garde ne prouve rien.',
            );
            expect(
              sorties,
              isEmpty,
              reason:
                  'Des commandes de la carte sortent de l ecran '
                  '(${sorties.length}) :\n   ${sorties.join('\n   ')}',
            );
          },
        );
      }
    }

    // LE CAS NOMME DE LA CAPTURE. La mesure precedente dit seulement « rien
    // ne sort » ; celle-ci dit « le SOS garde EXACTEMENT la marge que le lot
    // 762 a ecrite », des deux cotes et a toute largeur. C est le chiffre
    // qu on peut comparer aux 43 px releves sur l ecran de Christophe.
    for (final largeur in kLargeursTelephone) {
      for (final main in <DominantHand>[
        DominantHandValues.right,
        DominantHandValues.left,
      ]) {
        testWidgets(
          'le SOS garde sa marge sur ${largeur.toInt()} points (main $main)',
          (tester) async {
            await monteLaCarte(tester, largeur: largeur, main: main);
            final boite = tester.getRect(find.byType(SosDuCoteDeLaMain));
            final bouton = tester.getRect(
              find.descendant(
                of: find.byType(SosDuCoteDeLaMain),
                matching: find.byType(FloatingActionButton),
              ),
            );
            expect(
              boite.left,
              greaterThanOrEqualTo(-kToleranceLogique),
              reason: 'le SOS deborde a gauche sur $largeur points',
            );
            expect(
              boite.right,
              lessThanOrEqualTo(largeur + kToleranceLogique),
              reason: 'le SOS deborde a droite sur $largeur points',
            );

            final marge = DominantHandValues.isRight(main)
                ? largeur - bouton.right
                : bouton.left;
            expect(
              marge,
              closeTo(SosDuCoteDeLaMain.margeLaterale, kToleranceLogique),
              reason:
                  'LE BOUTON DE SECOURS DOIT RESTER DECOLLE DU BORD : marge '
                  'mesuree ${marge.toStringAsFixed(2)} points sur un ecran de '
                  '${largeur.toInt()}, main $main, alors que le lot 762 '
                  'annonce ${SosDuCoteDeLaMain.margeLaterale}.',
            );
          },
        );
      }
    }

    // ----------------------------------------------------------------------
    // LE TEMOIN : la mesure REFUSE une mise en page fautive.
    // ----------------------------------------------------------------------
    testWidgets('une commande poussee hors cadre est REFUSEE, et nommee', (
      tester,
    ) async {
      const largeur = 390.0;
      tester.view.physicalSize = const Size(largeur, kHauteurTelephone);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Le defaut qu on craignait sur le SOS, fabrique expres : un bouton de
      // 72 points pousse de 40 au-dela du bord droit. Aucune exception n est
      // levee par Flutter — c est tout le probleme — et pourtant 40 points du
      // bouton de secours sont hors de portee du doigt.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(40, 0),
                        child: const SizedBox(
                          key: ValueKey('sos-fautif'),
                          width: 72,
                          height: 72,
                          child: ColoredBox(color: Color(0xFFD32F2F)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason:
            'Flutter ne leve RIEN sur ce debordement : c est pourquoi il faut '
            'le mesurer.',
      );

      final sorties = sortiesDeLEcran(
        tester,
        find.byType(Stack).first,
        largeur,
      );
      expect(
        sorties,
        isNotEmpty,
        reason:
            'La mesure a laisse passer un bouton pousse de 40 points hors du '
            'bord : elle ne garde rien.',
      );
      expect(
        sorties.any((s) => s.droite > largeur + 1),
        isTrue,
        reason: 'Le depassement doit etre nomme avec son chiffre.',
      );
      // Et elle se tait sur la meme mise en page remise dans le cadre.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: 16),
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: ColoredBox(color: Color(0xFFD32F2F)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        sortiesDeLEcran(tester, find.byType(Stack).first, largeur),
        isEmpty,
        reason:
            'La mesure doit se taire quand la commande est dans le cadre, '
            'sinon elle crierait sur tout.',
      );
    });
  });
}
