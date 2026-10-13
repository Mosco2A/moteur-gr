/// LA GARDE QUI REFUSE QU'UN BLOC SOIT ROGNE PAR SON CADRE (836).
///
/// ---------------------------------------------------------------------------
/// CE QUI A ETE SIGNALE
/// ---------------------------------------------------------------------------
///
/// Deux blocs coupes, sur deux ecrans differents :
///  * l'histogramme de difficulte du PROGRAMME etait coupe en bas, et on ne
///    lisait plus les etiquettes des jours ;
///  * la legende de couleurs du CALENDRIER se perdait au bord du bouton
///    « VALIDER LES DATES ».
///
/// ---------------------------------------------------------------------------
/// LA CAUSE DU PREMIER, ET POURQUOI AUCUNE HAUTEUR DE BARRE NE LA CORRIGEAIT
/// ---------------------------------------------------------------------------
///
/// Le « R » des jours de repos etait ecrit DANS sa barre. Or la barre d'un jour
/// de repos ne fait qu'une fraction de la hauteur du cadre (0,18) : dans un
/// cadre de 60 points dont 16 de marges, cela faisait HUIT points de haut pour
/// un texte de DOUZE. Monter la fraction aurait menti sur le graphe — une barre
/// dit un denivele, et un jour de repos n'en a pas. L'etiquette n'avait rien a
/// faire dans une boite dont la hauteur represente une donnee : elle est
/// desormais SOUS les barres, dans une bande qui a sa propre hauteur, mesuree.
///
/// ---------------------------------------------------------------------------
/// CE QUE CETTE GARDE MESURE
/// ---------------------------------------------------------------------------
///
/// UN TEXTE ROGNE PAR SON PARENT NE LEVE AUCUNE EXCEPTION quand le parent n'est
/// pas un `Flex` : il est peint, puis coupe, et personne ne crie. On compare
/// donc des RECTANGLES — celui du texte et celui du bloc qui le contient — et
/// on refuse qu'un texte depasse de son bloc.
///
/// LE TEMOIN : le dernier test de chaque groupe soumet a la mesure une mise en
/// page volontairement fautive et exige qu'elle la REFUSE.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/domain/planned_day.dart';
import 'package:moteur_gr/features/planning/presentation/calendar_screen.dart';
import 'package:moteur_gr/features/planning/presentation/trail_planning_screen.dart';
import 'package:moteur_gr/features/planning/providers/planned_days_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/mesure_de_texte.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Les largeurs de telephone mesurees, reprises de la garde 801.
const List<double> _largeurs = <double>[320, 360, 390, 412];

/// La hauteur d'un telephone courant.
const double _hauteur = 844;

/// La tolerance : un dixieme de point, pour l'arrondi de la mise en page.
const double _tolerance = 0.1;

/// Trouve un widget par le NOM de sa classe, meme privee.
///
/// Les deux blocs mesures ici sont des widgets prives de leur ecran — c'est
/// normal, ils n'ont aucune raison d'etre publics — et une garde ne doit pas
/// forcer a elargir une interface pour pouvoir mesurer.
Finder parNomDeClasse(String nom) =>
    find.byWidgetPredicate((w) => w.runtimeType.toString() == nom);

/// Les rectangles qui depassent de [cadre], parmi ceux de [boites].
List<String> depassements(
  Map<String, Rect> boites,
  Rect cadre, {
  double tolerance = _tolerance,
}) {
  final sorties = <String>[];
  boites.forEach((nom, boite) {
    final deborde =
        boite.top < cadre.top - tolerance ||
        boite.bottom > cadre.bottom + tolerance ||
        boite.left < cadre.left - tolerance ||
        boite.right > cadre.right + tolerance;
    if (deborde) {
      sorties.add(
        '$nom : ${boite.top.toStringAsFixed(1)}..'
        '${boite.bottom.toStringAsFixed(1)} en vertical, cadre '
        '${cadre.top.toStringAsFixed(1)}..'
        '${cadre.bottom.toStringAsFixed(1)}',
      );
    }
  });
  return sorties;
}

class _ProgrammeFige extends PlannedDaysNotifier {
  _ProgrammeFige(Ref ref, List<PlannedDay> jours) : super(const [], 1, ref) {
    state = jours;
  }
}

void main() {
  setUpAll(() async {
    LocaleSettings.setLocaleRaw('fr');
    await initializeDateFormatting('fr');
  });

  /// La date de depart est SEMEE dans les preferences, la ou le vrai notifier
  /// va la lire. On evite ainsi un faux notifier — le calendrier est donc
  /// mesure avec le code de production — et l'import de 91 caracteres que
  /// `dart format` ne sait pas couper.
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'departure_date_test-trail': '2030-06-10T00:00:00.000',
    });
  });

  StageModel etape(int n) => StageModel(
    trailId: 'test-trail',
    stageNumber: n,
    name: 'Etape $n',
    distanceKm: 12,
    elevationGainM: 600,
    elevationLossM: 500,
    startLat: 0,
    startLng: 0,
    endLat: 0,
    endLng: 0,
  );

  PlannedDay jourDeMarche(int n, int numeroEtape) =>
      PlannedDay(dayNumber: n, stages: [etape(numeroEtape)]);
  PlannedDay jourDeRepos(int n) =>
      PlannedDay(dayNumber: n, stages: const [], isRestDay: true);

  /// UN PROGRAMME AVEC DES JOURS DE REPOS, parce que c'est le « R » qui etait
  /// rogne : sans jour de repos, l'histogramme n'a aucune etiquette et la garde
  /// ne mesurerait rien.
  final programme = <PlannedDay>[
    jourDeMarche(1, 1),
    jourDeMarche(2, 2),
    jourDeRepos(3),
    jourDeMarche(4, 3),
    jourDeMarche(5, 4),
    jourDeRepos(6),
    jourDeMarche(7, 5),
  ];

  PlanningStats statsDe(List<PlannedDay> jours) {
    final marche = jours.where((d) => !d.isRestDay).length;
    return PlanningStats(
      totalDistance: 0,
      totalElevationGain: 0,
      totalElevationLoss: 0,
      totalHours: 0,
      trekDays: marche,
      restDays: jours.length - marche,
      stageCount: marche,
    );
  }

  // =========================================================================
  // (1) L'HISTOGRAMME DU PROGRAMME
  // =========================================================================
  group('L HISTOGRAMME DU PROGRAMME NE ROGNE PLUS SES ETIQUETTES (836)', () {
    Future<void> monteLeProgramme(
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
            trailConfigProvider.overrideWithValue(testTrailConfig),
            stagesProvider('test-trail').overrideWith(
              (ref) => Future.value([for (var i = 1; i <= 5; i++) etape(i)]),
            ),
            plannedDaysProvider(
              'test-trail',
            ).overrideWith((ref) => _ProgrammeFige(ref, programme)),
            planningStatsProvider(
              'test-trail',
            ).overrideWithValue(statsDe(programme)),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/planning',
              routes: [
                GoRoute(
                  path: '/planning',
                  builder: (_, __) =>
                      const TrailPlanningScreen(trailId: 'test-trail'),
                ),
                GoRoute(
                  path: '/my-treks',
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    for (final largeur in _largeurs) {
      testWidgets(
        'sur ${largeur.toInt()} points, aucune etiquette ne depasse de '
        'l histogramme',
        (tester) async {
          await monteLeProgramme(tester, largeur: largeur);

          final histogramme = parNomDeClasse('_ElevationProfile');
          expect(
            histogramme,
            findsOneWidget,
            reason: 'l histogramme n est pas rendu : la garde ne prouve rien.',
          );
          final cadre = tester.getRect(histogramme);

          final etiquettes = find.descendant(
            of: histogramme,
            matching: find.text(t.programme.restDayLabel),
          );
          expect(
            etiquettes,
            findsWidgets,
            reason:
                'aucune etiquette « ${t.programme.restDayLabel} » dans '
                'l histogramme, alors que le programme porte deux jours de '
                'repos : la garde ne mesurerait rien.',
          );

          // ON COMPARE A LA HAUTEUR INTRINSEQUE, PAS AU CADRE PARENT — et
          // c'est la lecon de ce banc. Une boite de texte contrainte par son
          // parent rend la taille CONTRAINTE : un « R » de douze points
          // enferme dans une barre de huit mesure huit, pas douze. Comparer
          // deux rectangles ne voit donc RIEN de ce rognage-la. La seule mesure
          // qui tranche est celle du peintre : la place qu'il faut au texte,
          // face a la place qu'on lui donne.
          final manquent = <String>[];
          final dehors = <String>[];
          var i = 0;
          for (final element in etiquettes.evaluate()) {
            final cible = find.byElementPredicate((e) => e == element);
            final boite = tester.getRect(cible);
            final paragraphe = tester.renderObject(cible) as RenderParagraph;
            final requise = hauteurDesTextes(
              blocs: [
                (
                  texte: t.programme.restDayLabel,
                  style: paragraphe.text.style ?? const TextStyle(),
                  maxLignes: 1,
                ),
              ],
              largeurTexte: double.maxFinite,
            );
            final nom = 'etiquette ${++i}';
            if (boite.height + _tolerance < requise - margeDArrondiDuPeintre) {
              manquent.add(
                '$nom : ${boite.height.toStringAsFixed(1)} points de haut '
                'pour ${requise.toStringAsFixed(1)} reclames',
              );
            }
            dehors.addAll(depassements({nom: boite}, cadre));
          }

          expect(
            manquent,
            isEmpty,
            reason:
                'DES ETIQUETTES DE JOUR N ONT PAS LA HAUTEUR DE S ECRIRE sur '
                'un ecran de ${largeur.toInt()} points : elles seront rognees, '
                'comme le « R » enferme dans une barre de huit '
                'points.\n   ${manquent.join('\n   ')}',
          );
          expect(
            dehors,
            isEmpty,
            reason:
                'DES ETIQUETTES SORTENT DU CADRE DE L HISTOGRAMME sur un ecran '
                'de ${largeur.toInt()} points.\n   ${dehors.join('\n   ')}',
          );
        },
      );
    }

    testWidgets('TEMOIN — un texte enferme dans une barre trop basse est '
        'bien vu comme depassant', (tester) async {
      // LA MISE EN PAGE FAUTIVE : le texte de 12 points au centre d une barre
      // de 8, c est-a-dire l histogramme d avant ce lot.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                key: const ValueKey('cadre'),
                height: 8,
                width: 40,
                child: Center(
                  child: Text(
                    t.programme.restDayLabel,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cible = find.text(t.programme.restDayLabel);
      final boite = tester.getRect(cible);
      final paragraphe = tester.renderObject(cible) as RenderParagraph;
      final requise = hauteurDesTextes(
        blocs: [
          (
            texte: t.programme.restDayLabel,
            style: paragraphe.text.style ?? const TextStyle(),
            maxLignes: 1,
          ),
        ],
        largeurTexte: double.maxFinite,
      );

      // ET LA PREUVE QUE LA COMPARAISON DE RECTANGLES NE SUFFISAIT PAS : la
      // boite du texte est ici AUSSI GRANDE que son cadre, parce que le parent
      // l'a contrainte. Un banc qui se contenterait de comparer les deux
      // rectangles serait VERT devant ce rognage.
      final cadre = tester.getRect(find.byKey(const ValueKey('cadre')));
      expect(
        depassements({'le R enferme': boite}, cadre),
        isEmpty,
        reason:
            'si la boite du texte depassait vraiment de son cadre, la lecon de '
            'ce temoin — « comparer les rectangles ne suffit pas » — serait '
            'fausse et ce banc devrait etre reecrit.',
      );

      expect(
        boite.height + _tolerance < requise - margeDArrondiDuPeintre,
        isTrue,
        reason:
            'LA MESURE NE VOIT PLUS RIEN : soumise au texte de 12 points '
            'enferme dans une barre de 8, elle devrait constater qu il manque '
            'de la hauteur (boite ${boite.height.toStringAsFixed(1)}, '
            'reclame ${requise.toStringAsFixed(1)}). Sinon les tests verts '
            'ci-dessus ne prouvent rien.',
      );
    });
  });

  // =========================================================================
  // (2) LA LEGENDE DU CALENDRIER
  // =========================================================================
  group('LA LEGENDE DU CALENDRIER RESTE LISIBLE (836)', () {
    Future<void> monteLeCalendrier(
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
            plannedDaysProvider(
              'test-trail',
            ).overrideWith((ref) => _ProgrammeFige(ref, programme)),
            planningStatsProvider(
              'test-trail',
            ).overrideWithValue(statsDe(programme)),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/c',
                routes: [
                  GoRoute(
                    path: '/c',
                    builder: (_, __) =>
                        const CalendarScreen(trailId: 'test-trail'),
                  ),
                  GoRoute(path: '/home', builder: (_, __) => const SizedBox()),
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

    for (final largeur in _largeurs) {
      testWidgets(
        'sur ${largeur.toInt()} points, la legende est ENTIEREMENT lisible a '
        'l ouverture',
        (tester) async {
          await monteLeCalendrier(tester, largeur: largeur);

          final defilement = find.byType(SingleChildScrollView);
          expect(
            defilement,
            findsOneWidget,
            reason: 'la zone de defilement du calendrier est introuvable.',
          );
          final fenetre = tester.getRect(defilement);

          final boites = <String, Rect>{};
          final cibles = <String, String>{
            'Depart': t.calendar.legend.start,
            'Marche': t.calendar.legend.walk,
            'Repos': t.calendar.legend.rest,
            'Arrivee': t.calendar.legend.arrival,
          };
          cibles.forEach((nom, texte) {
            final trouve = find.text(texte);
            if (trouve.evaluate().length == 1) {
              boites[nom] = tester.getRect(trouve);
            }
          });

          expect(
            boites.length,
            cibles.length,
            reason:
                'LA LEGENDE N EST PAS ENTIEREMENT MONTEE : '
                '${boites.length} items sur ${cibles.length} trouves a '
                '${largeur.toInt()} points. Les manquants sont hors de l arbre '
                'rendu, donc invisibles.',
          );

          final sorties = depassements(boites, fenetre);
          expect(
            sorties,
            isEmpty,
            reason:
                'LA LEGENDE DU CALENDRIER EST ROGNEE PAR LE BORD DE SA ZONE '
                'DE DEFILEMENT sur un ecran de ${largeur.toInt()} points — '
                'c est ce qui la faisait passer pour « cachee derriere le '
                'bouton VALIDER LES DATES », qui est colle a ce '
                'bord.\n   ${sorties.join('\n   ')}',
          );
        },
      );
    }
  });
}
