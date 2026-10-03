// DEUX NOMBRES DE JOURS QUI NE DISAIENT PAS CE QU'ILS COMPTAIENT — tache 580,
// point Y4.
//
// CE QUE CHRIS VOYAIT. Le diplome annoncait « 7 jours de randonnee » et le
// recap « 0 jours ». Sept jours de quoi : de marche, ou du depart a l'arrivee,
// repos compris ? Les deux nombres sortent pourtant du MEME calcul —
// `AdventureStats.durationDays`, qui compte les jours ENTAMES entre le depart
// et l'arrivee de la session, donc le TOTAL, repos compris. Un nombre de jours
// qui ne dit pas ce qu'il compte se lit de travers dans la moitie des cas ;
// c'est le defaut que le LOT R (tache 569) avait corrige sur la faisabilite,
// et ces deux ecrans-la etaient restes dehors.
//
// LA REGLE, ET ELLE EXISTAIT DEJA. L'application dispose d'un vocabulaire
// etabli pour cette distinction, traduit dans les cinq langues : « jours au
// total » (`itinerary.daysTotal`) face a « jours de marche »
// (`itinerary.daysBreakdown`, `summary.durationValue`). Ce fichier ne fabrique
// donc AUCUN vocabulaire neuf : il exige que les deux libelles reprennent
// celui qui existe.
//
// POURQUOI DEUX ETAGES. Le premier verifie la TABLE (les cinq langues disent
// la nature du nombre) ; le second verifie les DEUX ECRANS (ils affichent bien
// ce libelle-la). Sans le second, remplacer la cle par un « $days jours » ecrit
// en dur dans le widget passerait inapercu.
library;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/core/providers/service_providers.dart';
import 'package:moteur_gr/core/services/demo_mode_service.dart';
import 'package:moteur_gr/features/after/presentation/adventure_recap_screen.dart';
import 'package:moteur_gr/features/diploma/presentation/diploma_screen.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/trek/providers/stage_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  group(
    'Y4-a — la table dit, dans les cinq langues, ce que le nombre compte',
    () {
      for (final langue in AppLocale.values) {
        test('${langue.languageCode} : diplome et recap nomment le TOTAL', () {
          final tr = langue.buildSync();
          // La facon dont CETTE langue dit « jours au total », telle que
          // l'itineraire l'ecrit deja. Aucune chaine inventee ici.
          final natureTotal = tr.itinerary.daysTotal.toLowerCase();
          expect(
            natureTotal,
            isNotEmpty,
            reason: 'reference de vocabulaire absente : lecture cassee',
          );

          for (final entree in <String, String>{
            'diploma.recapDuration': tr.diploma.recapDuration,
            'recap.duration': tr.recap.duration,
          }.entries) {
            expect(
              entree.value.toLowerCase().contains(natureTotal),
              isTrue,
              reason:
                  'UN NOMBRE DE JOURS SANS SA NATURE : « ${entree.value} » '
                  '(${entree.key}, ${langue.languageCode}) ne dit pas s il '
                  'compte les jours de marche ou le total. Le chiffre vient de '
                  'AdventureStats.durationDays, qui compte du depart a '
                  'l arrivee : il doit le DIRE, avec le vocabulaire deja '
                  'traduit « ${tr.itinerary.daysTotal} ».',
            );
          }
        });
      }
    },
  );

  // Y4-b — LES DEUX ECRANS AFFICHENT BIEN CE LIBELLE.
  //
  // POURQUOI CE SECOND ETAGE NE PASSE PLUS PAR L'APPLICATION REELLE (tache 601).
  // Il montait le vrai routeur sur une application FRAICHE et lisait les textes
  // rendus. Cela marchait grace a une exemption : le sentier par defaut etait
  // declare « vitrine », ce qui DEVERROUILLAIT le diplome et le recap sans une
  // seule etape marchee — les deux ecrans affichaient donc « 0 jours au total »
  // a l'ouverture de l'application. Cette exemption a disparu : le diplome et le
  // recap sont desormais gates par la MARCHE, pour tout le monde, et une
  // application fraiche montre — correctement — leur etat verrouille.
  //
  // CE QUE L'ETAGE VERIFIE RESTE LE MEME, ET IL LE VERIFIE MIEUX : les deux
  // ecrans, une fois qu'ils ont une aventure a raconter, affichent le libelle
  // TRADUIT et non un « $days jours » ecrit en dur dans le widget. On leur
  // fournit donc ce qu'ils exigent maintenant : une session reellement marchee.
  group('Y4-b — les deux ecrans affichent bien ce libelle', () {
    const trailId = 'test-trail-jours';
    const config = TrailConfig(
      id: trailId,
      name: 'Test Trail',
      displayName: 'Test Trail',
      tagline: 'tagline',
      totalStages: 4,
      totalDistanceKm: 40.0,
      totalElevationGain: 2000,
      region: 'Region',
      country: 'France',
      primaryColorValue: 0xFF2E7D32,
      secondaryColorValue: 0xFF1565C0,
      gpxAssetPath: 'assets/gpx/test.gpx',
      defaultDuration: 4,
      availableDurations: [2, 4, 6],
    );

    late AppDatabase db;

    setUpAll(() async {
      await initializeDateFormatting('fr_FR');
    });

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    StagesCompanion etape(int n) => StagesCompanion(
      trailId: const Value(trailId),
      stageNumber: Value(n),
      name: Value('Etape $n'),
      distanceKm: const Value(10.0),
      elevationGainM: const Value(500),
      elevationLossM: const Value(400),
      description: const Value('desc'),
      startLat: const Value(42.0),
      startLng: const Value(9.0),
      endLat: const Value(42.1),
      endLng: const Value(9.1),
      difficulty: const Value('moderate'),
    );

    /// Pose l'aventure REELLE que les deux ecrans racontent : quatre etapes
    /// marchees, du 15 au 18 juin — donc quatre jours au TOTAL.
    Future<void> poserAventure() async {
      await db.stagesDao.insertAll([etape(1), etape(2), etape(3), etape(4)]);
      await db.trekSessionsDao.upsertSession(
        TrekSession(
          id: 'sess-jours',
          trailId: trailId,
          startedAt: DateTime.utc(2026, 6, 15),
          finishedAt: DateTime.utc(2026, 6, 18),
          status: 'completed',
          completedStages: const ['1', '2', '3', '4'],
          parcoursFullyWalked: true,
        ),
      );
    }

    Future<void> monter(WidgetTester tester, Widget ecran) async {
      LocaleSettings.setLocaleRaw('fr');
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailConfigProvider.overrideWithValue(config),
            currentTrailIdProvider.overrideWith((ref) => trailId),
            demoModeServiceProvider.overrideWithValue(DemoModeService()),
          ],
          child: MaterialApp.router(
            routerConfig: GoRouter(
              initialLocation: '/ecran',
              routes: [
                GoRoute(path: '/ecran', builder: (_, __) => ecran),
                GoRoute(
                  path: '/my-treks',
                  builder: (_, __) => const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(milliseconds: 400));
    }

    /// Tous les libelles REELLEMENT rendus a l'ecran.
    List<String> textesDe(WidgetTester tester) => tester
        .widgetList<Text>(find.byType(Text))
        .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();

    testWidgets('le DIPLOME nomme le total', (tester) async {
      await poserAventure();
      await monter(tester, const DiplomaScreen());

      // Meme lecture que l'etage Y4-a : la NATURE du nombre, insensible a la
      // casse (le libelle d'ecran l'ecrit en minuscules au fil de la phrase).
      final nature = t.itinerary.daysTotal.toLowerCase();
      expect(
        textesDe(tester).any((txt) => txt.toLowerCase().contains(nature)),
        isTrue,
        reason:
            'LE DIPLOME AFFICHE UN NOMBRE DE JOURS SANS DIRE CE QU IL '
            'COMPTE. Le chiffre vient de AdventureStats.durationDays, qui '
            'compte du depart a l arrivee : il doit le DIRE, avec le '
            'vocabulaire deja traduit « ${t.itinerary.daysTotal} ». '
            'Textes lus : ${textesDe(tester).join(' | ')}',
      );
    });

    testWidgets('le RECAP nomme le total', (tester) async {
      await poserAventure();
      await monter(tester, const AdventureRecapScreen());

      final nature = t.itinerary.daysTotal.toLowerCase();
      expect(
        textesDe(tester).any((txt) => txt.toLowerCase().contains(nature)),
        isTrue,
        reason:
            'LE RECAP AFFICHE UN NOMBRE DE JOURS SANS DIRE CE QU IL '
            'COMPTE (meme calcul, meme exigence que le diplome). '
            'Textes lus : ${textesDe(tester).join(' | ')}',
      );
    });
  });
}
