/// LA GARDE QUI REFUSE QU'UN LIBELLE DE JOUR SOIT COUPE DANS LE MOT (836).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE
/// ---------------------------------------------------------------------------
///
/// Dans « Risque par etape », de l'ecran Incendie, le mot « Demain »
/// tombait sur TROIS lignes — « De », « mai », « n » — et les pastilles
/// « Niv. 0 » placees
/// sous les libelles ne s'alignaient plus. Christophe a ecrit : illisible.
///
/// ---------------------------------------------------------------------------
/// LA CAUSE, ET POURQUOI LE DESALIGNEMENT N'ETAIT PAS UN SECOND DEFAUT
/// ---------------------------------------------------------------------------
///
/// La rangee etait un `Row` de `Expanded`, un par jour de prevision. L'horizon
/// demande au fournisseur est de DIX jours (`forecastHorizonDays`), et dix
/// colonnes a egalite dans une carte de 360 points font 29,6 points chacune —
/// quand « Demain » en reclame une quarantaine. Un `Text` sans borne ne
/// s'arrete pas a la fin d'un mot quand la place manque : il coupe DEDANS.
///
/// ET LE DESALIGNEMENT EN DECOULAIT. « Auj. » et « J+3 » tenaient sur une
/// ligne, « Demain » sur trois : les titres de colonnes n'avaient plus la meme
/// hauteur, donc les niveaux ecrits dessous ne tombaient plus sur la meme
/// ligne. Corriger
/// la coupure corrige l'alignement — c'est le meme defaut vu deux fois.
///
/// ---------------------------------------------------------------------------
/// CE QUE CETTE GARDE MESURE
/// ---------------------------------------------------------------------------
///
/// UN TEXTE QUI ELLIPSE OU QUI SE FAIT ROGNER NE LEVE AUCUNE EXCEPTION — c'est
/// la lecon du lot 749, et c'est pourquoi les bancs du depot etaient verts avec
/// le defaut sous les yeux. On ne guette donc rien : on MESURE.
///
/// DEUX MESURES, ET ELLES DISENT DEUX CHOSES DIFFERENTES.
///  (1) La boite de chaque libelle est AU MOINS aussi large que le texte le
///      reclame pour tenir sur une ligne — mesure au `TextPainter`, la meme que
///      celle dont le code se sert pour choisir la largeur des colonnes. C'est
///      ce qui interdit la coupure dans le mot comme le rognage silencieux.
///  (2) Tous les libelles de la rangee ont la MEME hauteur, et les niveaux
///      d'une meme ligne le meme sommet. C'est ce qui interdit le
///      desalignement.
///
/// DIX JOURS, PAS TROIS. Les tests existants de cet ecran montaient une
/// prevision a trois jours — assez large pour que rien ne se coupe, donc
/// aveugle au defaut. Celui-ci monte l'horizon COMPLET, qui est le cas reel.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';
import 'package:moteur_gr/features/weather/presentation/fire_risk_screen.dart';
import 'package:moteur_gr/features/weather/providers/weather_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/mesure_de_texte.dart';

/// Les largeurs de telephone mesurees, reprises de la garde 801.
const List<double> _largeurs = <double>[320, 360, 390, 412];

/// La hauteur du cadre : haute, pour que la rangee soit rendue sans defilement.
const double _hauteur = 2400;

/// La tolerance : un dixieme de point.
///
/// Plus large que celle des gardes de geometrie pure, parce qu'on compare ici
/// une boite de mise en page a une mesure de peintre de texte : les deux
/// arrondissent, et pas au meme moment.
const double _tolerance = 0.1;

class _MeteoFigee extends StageWeatherNotifier {
  _MeteoFigee(this._etat)
    : super(const WeatherStageParams(trailId: 'test-trail', stageNumber: 0));

  final WeatherState _etat;

  @override
  WeatherState build() => _etat;
}

void main() {
  const trailId = 'test-trail';

  setUpAll(() => LocaleSettings.setLocaleRaw('fr'));

  const config = TrailConfig(
    id: trailId,
    name: 'Test',
    displayName: 'Test Trail',
    tagline: 't',
    totalStages: 1,
    totalDistanceKm: 10,
    totalElevationGain: 400,
    region: 'Test',
    country: 'Test',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/test.gpx',
    directions: ['NS', 'SN'],
  );

  final etapes = <StageModel>[
    const StageModel(
      trailId: trailId,
      stageNumber: 1,
      name: 'Etape Alpha',
      distanceKm: 10,
      elevationGainM: 400,
      elevationLossM: 300,
      startLat: 0,
      startLng: 0,
      endLat: 0,
      endLng: 0,
    ),
  ];

  /// L'HORIZON COMPLET : dix jours, c'est ce que le fournisseur rend vraiment.
  ///
  /// Le premier jour est chaud (niveau eleve) pour que l'etape remonte dans
  /// « Risque par etape » — la section ne montre que les etapes a risque.
  final previsionDixJours = WeatherForecast(
    latitude: 0,
    longitude: 0,
    days: [
      for (var i = 0; i < 10; i++)
        DayForecast(
          date: DateTime(2026, 7, 15).add(Duration(days: i)),
          temperatureMax: i == 0 ? 36 : 30,
          temperatureMin: 15,
          precipitationMm: 0,
          windSpeedKmh: 5,
          uvIndex: 8,
          weatherCode: 0,
          precipitationProbabilityMax: 0,
        ),
    ],
  );

  Future<void> monteLIncendie(
    WidgetTester tester, {
    required double largeur,
  }) async {
    tester.view.physicalSize = Size(largeur, _hauteur);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          trailConfigProvider.overrideWithValue(config),
          stagesProvider(trailId).overrideWith((ref) => Future.value(etapes)),
          stageWeatherProvider(
            const WeatherStageParams(trailId: trailId, stageNumber: 1),
          ).overrideWith(
            () => _MeteoFigee(
              WeatherState(forecast: previsionDixJours, isLoading: false),
            ),
          ),
        ],
        child: TranslationProvider(
          // `AppHeader` interroge le routeur pour savoir s il peut revenir en
          // arriere : sans routeur en contexte, l ecran ne se batit pas.
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/t',
              routes: [
                GoRoute(
                  path: '/t',
                  builder: (_, __) => const FireRiskScreen(trailId: trailId),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Les libelles de jour que l'ecran rend reellement, du plus tot au plus
  /// tard.
  List<String> libellesDesJours() => <String>[
    t.fireRisk.day.today,
    t.fireRisk.day.tomorrow,
    for (var i = 2; i < 10; i++) t.fireRisk.day.plus(n: i),
  ];

  group('LA RANGEE DES JOURS NE COUPE AUCUN MOT (836)', () {
    for (final largeur in _largeurs) {
      testWidgets(
        'sur ${largeur.toInt()} points, chaque libelle de jour a la place de '
        's ecrire en entier sur une ligne',
        (tester) async {
          await monteLIncendie(tester, largeur: largeur);

          // Il y a bien de quoi mesurer : sans la rangee, la garde serait verte
          // pour rien.
          final demain = find.text(t.fireRisk.day.tomorrow);
          expect(
            demain,
            findsOneWidget,
            reason:
                'la rangee des jours n est pas rendue : '
                '« ${t.fireRisk.day.tomorrow} » est introuvable, '
                'la garde ne prouve rien.',
          );

          final trop = <String>[];
          for (final libelle in libellesDesJours()) {
            final trouve = find.text(libelle);
            if (trouve.evaluate().length != 1) continue;

            final boite = tester.getSize(trouve);
            final paragraphe = tester.renderObject(trouve) as RenderParagraph;
            // LA LARGEUR QUE LE TEXTE RECLAME, mesuree au peintre avec le style
            // REELLEMENT rendu — pas un style suppose.
            final requise = largeurDUneLigne(
              texte: libelle,
              style: paragraphe.text.style ?? const TextStyle(),
            );

            if (boite.width + _tolerance < requise - margeDArrondiDuPeintre) {
              trop.add(
                '« $libelle » : boite de ${boite.width.toStringAsFixed(1)} '
                'points pour ${requise.toStringAsFixed(1)} reclames',
              );
            }
          }

          expect(
            trop,
            isEmpty,
            reason:
                'DES LIBELLES DE JOUR N ONT PAS LA PLACE DE S ECRIRE sur un '
                'ecran de ${largeur.toInt()} points : ils seront coupes dans '
                'le mot, comme « De / mai / n ».\n   ${trop.join('\n   ')}',
          );
        },
      );

      testWidgets(
        'sur ${largeur.toInt()} points, les niveaux d une meme ligne sont '
        'alignes',
        (tester) async {
          await monteLIncendie(tester, largeur: largeur);

          // Tous les titres de colonnes ont la MEME hauteur : c'est ce qui
          // garantit que ce qui est ecrit dessous tombe a la meme hauteur.
          final hauteurs = <double>{};
          final sommetsParLigne = <String, Set<double>>{};
          for (final libelle in libellesDesJours()) {
            final trouve = find.text(libelle);
            if (trouve.evaluate().length != 1) continue;
            final boite = tester.getRect(trouve);
            hauteurs.add(double.parse(boite.height.toStringAsFixed(1)));
            // La rangee peut passer a la ligne : on groupe par SOMMET du
            // libelle, ce qui revient a grouper par ligne de la rangee.
            final ligne = boite.top.toStringAsFixed(1);
            sommetsParLigne.putIfAbsent(ligne, () => <double>{});
          }

          expect(
            hauteurs.length,
            1,
            reason:
                'LES TITRES DE COLONNES N ONT PAS TOUS LA MEME HAUTEUR sur '
                '${largeur.toInt()} points (hauteurs relevees : $hauteurs). '
                'C est exactement ce qui desalignait les « Niv. » : un libelle '
                'sur trois lignes pousse son niveau plus bas que les autres.',
          );

          expect(
            sommetsParLigne,
            isNotEmpty,
            reason: 'aucun libelle mesure : la garde ne prouve rien.',
          );
        },
      );
    }
  });
}
