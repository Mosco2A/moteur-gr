import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/config/trail_config.dart';
import 'package:moteur_gr/core/data/daos/trail_meteo_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/models/stage.dart';
import 'package:moteur_gr/core/network/connectivity_monitor.dart';
import 'package:moteur_gr/features/notifications/providers/download_reminder_provider.dart';
import 'package:moteur_gr/features/planning/providers/planning_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/features/weather/domain/forecast_reach.dart';
import 'package:moteur_gr/features/weather/data/weather_repository.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';
import 'package:moteur_gr/features/weather/presentation/fire_risk_screen.dart';
import 'package:moteur_gr/features/weather/presentation/weather_freshness.dart';
import 'package:moteur_gr/features/weather/presentation/weather_screen.dart';
import 'package:moteur_gr/features/weather/providers/program_weather_provider.dart';
import 'package:moteur_gr/features/weather/providers/weather_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import 'meteo_du_serveur.dart';

/// TACHE 572 — LOT U : REAUDIT DE LA METEO.
///
/// Les trois retours de Chris, en test. CHAQUE test de ce fichier a d'abord ete
/// ROUGE SUR LE COMPORTEMENT : il compile contre le module tel qu'il etait au
/// commit parent (bffc5f1) et echouait sur ce que l'application FAIT.
///
///   [U1] « indiquer le lieu des etapes et la meteo des etapes, pas celle du
///        jour » / « la meteo a l'endroit ou on est cense se trouver le
///        lendemain, puis le surlendemain ». L'ecran meteo affichait la
///        prevision d'UN point, jour d'API par jour d'API, sans jamais nommer le
///        lieu ni dater la journee de programme. -> U1-D, U1-E, U1-F.
///
///   [U2] « la mise a jour des donnees meteo ne produit rien ». CAUSE PROUVEE
///        (U2-A) : l'appel PART, la reponse est ECRITE en cache, le provider EST
///        mis a jour — mais la seule chose a l'ecran qui pourrait le montrer, la
///        ligne « MAJ », etait calculee sur `forecast.days.first.date`, soit le
///        JOUR DU BULLETIN (aujourd'hui a 00:00), et non sur l'instant du
///        releve, que le modele ne portait pas du tout. Le texte etait donc
///        identique au caractere pres avant et apres un rafraichissement
///        REUSSI. Et quand l'appel ECHOUAIT (U2-B), `refresh()` posait un
///        `errorMessage` qu'AUCUN widget du module ne lisait.
///
///   [U3] « indendie MAJ ne produit rien ». Meme cause, plus une propre a
///        l'ecran incendie (U3-C) : `_refreshAll` affichait « Donnees mises a
///        jour » meme quand il avait rafraichi ZERO etape.
///
/// Les deux contraintes du sentier, en test aussi : la portee honnete des
/// previsions (U1-E, PORT-I) et la survie du dernier bulletin hors ligne
/// (OFF-G).
void main() {
  const trailId = 'test-trail';

  setUpAll(() {
    LocaleSettings.setLocaleRaw('fr');
  });

  // ------------------------------------------------------------------ fixtures

  const testConfig = TrailConfig(
    id: trailId,
    name: 'Test',
    displayName: 'Test Trail',
    tagline: 't',
    totalStages: 3,
    totalDistanceKm: 30,
    totalElevationGain: 1000,
    region: 'Test',
    country: 'Test',
    primaryColorValue: 0xFF2E7D32,
    secondaryColorValue: 0xFF1565C0,
    gpxAssetPath: 'assets/test.gpx',
    directions: ['NS', 'SN'],
  );

  StageModel stage(int n, String name, String arrival) => StageModel(
        trailId: trailId,
        stageNumber: n,
        name: name,
        distanceKm: 12,
        elevationGainM: 700,
        elevationLossM: 300,
        startLat: 45.50 + n * 0.05,
        startLng: 2.90 + n * 0.05,
        endLat: 45.55 + n * 0.05,
        endLng: 2.95 + n * 0.05,
        arrivalName: arrival,
      );

  final threeStages = [
    stage(1, 'Depart - Bergerie', 'Bergerie de Colga'),
    stage(2, 'Bergerie - Refuge', 'Refuge de Sega'),
    stage(3, 'Refuge - Village', 'Village de Cozzano'),
  ];

  /// Prevision de [dayCount] jours a partir de [from], neutre (aucune alerte).
  WeatherForecast forecastFrom(DateTime from, int dayCount) => WeatherForecast(
        latitude: 45.55,
        longitude: 2.95,
        days: [
          for (var i = 0; i < dayCount; i++)
            DayForecast(
              date: DateTime(from.year, from.month, from.day)
                  .add(Duration(days: i)),
              temperatureMax: 18 + i.toDouble(),
              temperatureMin: 8 + i.toDouble(),
              precipitationMm: 0,
              windSpeedKmh: 10,
              uvIndex: 4,
              weatherCode: 0,
              precipitationProbabilityMax: 0,
            ),
        ],
      );

  Override weatherOverride(int stageNumber, WeatherState state) =>
      stageWeatherProvider(
        WeatherStageParams(trailId: trailId, stageNumber: stageNumber),
      ).overrideWith(() => _FixedWeatherNotifier(state));

  Widget wrapScreen(Widget screen, List<Override> overrides) {
    return ProviderScope(
      overrides: overrides,
      child: TranslationProvider(
        child: MaterialApp.router(
          routerConfig: GoRouter(
            initialLocation: '/s',
            routes: [
              GoRoute(path: '/s', builder: (_, __) => screen),
              GoRoute(
                path: '/my-treks',
                builder: (_, __) => const Scaffold(body: Text('treks')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester tester, {int frames = 16}) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Tout le texte rendu, concatene : on verifie ce que le randonneur LIT.
  String screenText(WidgetTester tester) => tester
      .widgetList<Text>(find.byType(Text))
      .map((w) => w.data ?? w.textSpan?.toPlainText() ?? '')
      .join(' | ');

  // ==========================================================================
  // U2-A / U3-A — LA CAUSE : LA FRAICHEUR AFFICHEE N'EST PAS L'INSTANT DU RELEVE
  // ==========================================================================

  group('U2/U3 — la ligne MAJ montre l\'instant du releve', () {
    testWidgets(
        'U2-A incendie : la MAJ n\'affiche PAS la date du bulletin',
        (tester) async {
      // Un bulletin dont le premier jour est le 15/07/2026 : c'est la date de la
      // PREVISION, pas celle du releve. Avant la tache 572 l'ecran affichait
      // « MAJ : 15/07/2026 00:00 » — un horodatage qui ne bouge jamais quand on
      // rafraichit, puisqu'il ne decrit pas le rafraichissement.
      final forecast = forecastFrom(DateTime(2026, 7, 15), 3);

      await tester.pumpWidget(wrapScreen(
        const FireRiskScreen(trailId: trailId),
        [
          trailConfigProvider.overrideWithValue(testConfig),
          stagesProvider(trailId)
              .overrideWith((ref) => Future.value(threeStages)),
          for (var n = 1; n <= 3; n++)
            weatherOverride(
                n, WeatherState(forecast: forecast, isLoading: false)),
        ],
      ));
      await settle(tester);

      expect(
        screenText(tester),
        isNot(contains('15/07/2026')),
        reason: 'Le bandeau MAJ affichait la date du BULLETIN au lieu de '
            'l\'instant du releve : un rafraichissement reussi ne changeait '
            'donc rien a l\'ecran — cause exacte de U3.',
      );
    });

    testWidgets('U2-A meteo : la MAJ n\'affiche PAS la date du bulletin',
        (tester) async {
      final forecast = forecastFrom(DateTime(2026, 7, 15), 3);

      await tester.pumpWidget(wrapScreen(
        const WeatherScreen(trailId: trailId, stageNumber: 1),
        [
          trailConfigProvider.overrideWithValue(testConfig),
          stagesProvider(trailId)
              .overrideWith((ref) => Future.value(threeStages)),
          weatherOverride(
              1, WeatherState(forecast: forecast, isLoading: false)),
        ],
      ));
      await settle(tester);

      expect(
        screenText(tester),
        isNot(contains('15 Jul')),
        reason: 'WeatherSourceBanner recevait `today?.date` (le jour du '
            'bulletin) comme horodatage de mise a jour : meme cause que U3.',
      );
    });
  });

  // ==========================================================================
  // U2-B — UN RAFRAICHISSEMENT QUI ECHOUE DOIT SE VOIR
  // ==========================================================================

  group('U2 — l\'echec de mise a jour se voit', () {
    testWidgets('U2-B : l\'errorMessage de l\'etat est affiche au randonneur',
        (tester) async {
      final forecast = forecastFrom(DateTime(2026, 7, 15), 3);

      await tester.pumpWidget(wrapScreen(
        const WeatherScreen(trailId: trailId, stageNumber: 1),
        [
          trailConfigProvider.overrideWithValue(testConfig),
          stagesProvider(trailId)
              .overrideWith((ref) => Future.value(threeStages)),
          weatherOverride(
            1,
            WeatherState(
              forecast: forecast,
              isLoading: false,
              errorMessage: 'boom',
            ),
          ),
        ],
      ));
      await settle(tester);

      expect(
        screenText(tester),
        contains('Mise à jour impossible'),
        reason: 'Avant la tache 572, `WeatherState.errorMessage` etait ecrit '
            'par refresh() et lu par AUCUN widget du module : un bouton qui '
            'echoue etait indistinguable d\'un bouton qui reussit.',
      );
    });
  });

  // ==========================================================================
  // U3-C — LE BOUTON INCENDIE NE DOIT PAS ANNONCER CE QU'IL N'A PAS FAIT
  // ==========================================================================

  group('U3 — le bouton incendie dit la verite sur ce qu\'il a fait', () {
    testWidgets(
        'U3-C : aucune etape resolue -> pas de « Donnees mises a jour »',
        (tester) async {
      // Etapes jamais resolues -> `trailFireRiskProvider.stages` vide ->
      // `_refreshAll` faisait `Future.wait([])` (ZERO appel) puis affichait
      // quand meme le SnackBar de succes.
      final never = Completer<List<StageModel>>();

      await tester.pumpWidget(wrapScreen(
        const FireRiskScreen(trailId: trailId),
        [
          trailConfigProvider.overrideWithValue(testConfig),
          stagesProvider(trailId).overrideWith((ref) => never.future),
        ],
      ));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.refresh).first);
      await settle(tester);

      expect(
        find.text(t.fireRisk.refreshed),
        findsNothing,
        reason: 'Zero etape rafraichie ne peut pas s\'annoncer « Donnees mises '
            'a jour » : c\'est le bouton qui « ne produit rien » tout en '
            'pretendant le contraire.',
      );
      expect(
        find.text(t.fireRisk.refreshNothing),
        findsOneWidget,
        reason: 'Un bouton qui n\'a rien a faire doit le DIRE.',
      );
    });
  });

  // ==========================================================================
  // U1 — LA METEO PAR JOUR DE PROGRAMME, AU LIEU D'ARRIVEE, NOMME ET DATE
  // ==========================================================================

  group('U1 — la meteo suit le programme, pas l\'index de l\'API', () {
    // Depart DEMAIN, bulletin a partir d'AUJOURD'HUI : c'est la situation reelle
    // d'un randonneur qui consulte la veille du depart. Une date figee dans le
    // passe ne testerait rien de la portee (tout serait deja derriere).
    final today = DateTime.now();
    final departure = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));

    List<Override> programOverrides({
      required int durationDays,
      required int forecastDays,
      DateTime? departureDate,
    }) {
      final forecast = forecastFrom(today, forecastDays);
      return [
        trailConfigProvider.overrideWithValue(testConfig),
        stagesProvider(trailId)
            .overrideWith((ref) => Future.value(threeStages)),
        selectedDurationProvider
            .overrideWith(() => _FixedDurationNotifier(durationDays)),
        downloadReminderProvider(trailId).overrideWith(
          () => _FixedDepartureNotifier(
            DepartureReminderState(departureDate: departureDate),
          ),
        ),
        for (var n = 1; n <= 3; n++)
          weatherOverride(
              n, WeatherState(forecast: forecast, isLoading: false)),
      ];
    }

    testWidgets('U1-D : chaque jour de programme est NOMME par son arrivee',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        const WeatherScreen(trailId: trailId, stageNumber: 1),
        programOverrides(
          durationDays: 3,
          forecastDays: 10,
          departureDate: departure,
        ),
      ));
      await settle(tester, frames: 24);

      final text = screenText(tester);
      expect(text, contains(t.weather.program.title),
          reason: 'La section « etape par etape » demandee par Chris.');
      expect(text, contains('Refuge de Sega'),
          reason: 'Un bulletin sans nom de lieu ne sert a rien : le lieu '
              'd\'arrivee du jour 2 doit etre NOMME a l\'ecran.');
      expect(text, contains('Village de Cozzano'),
          reason: 'Idem pour le jour 3 (« puis le surlendemain etc »).');
    });

    testWidgets(
        'U1-E : au-dela de la portee, l\'ecran le DIT (ni vide, ni invente)',
        (tester) async {
      // Programme de 12 jours, prevision de 10 : les jours 11 et 12 sont hors
      // portee. On n'invente pas, on l'ecrit.
      await tester.pumpWidget(wrapScreen(
        const WeatherScreen(trailId: trailId, stageNumber: 1),
        programOverrides(
          durationDays: 12,
          forecastDays: 10,
          departureDate: departure,
        ),
      ));
      await settle(tester, frames: 24);

      expect(
        screenText(tester),
        contains(t.weather.program.beyondHorizon(horizon: 10)),
        reason: 'Jamais de blanc sans explication : la portee reelle du '
            'fournisseur est annoncee.',
      );
    });

    testWidgets(
        'U1-F : sans date de depart, l\'ecran la demande au lieu de supposer',
        (tester) async {
      await tester.pumpWidget(wrapScreen(
        const WeatherScreen(trailId: trailId, stageNumber: 1),
        programOverrides(durationDays: 3, forecastDays: 10),
      ));
      await settle(tester, frames: 24);

      expect(
        screenText(tester),
        contains(t.weather.program.unknownDeparture),
        reason: 'Le trek n\'est pas forcement pour aujourd\'hui (meme regle '
            'que la faisabilite, LOT R) : sans date de depart on ne peut pas '
            'dire quel jour le randonneur sera a quelle etape.',
      );
    });
  });

  // ==========================================================================
  // OFF-G — HORS LIGNE : LE DERNIER BULLETIN CONNU SURVIT
  // ==========================================================================

  group('Hors ligne — le dernier bulletin connu reste lisible, ET DATE', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    WeatherRepository repo({
      ConnectivityStatus reseau = ConnectivityStatusValues.offline,
      Future<bool> Function()? passe,
    }) =>
        WeatherRepository(
          dao: TrailMeteoDao(db),
          demanderUnePasse: passe ?? () async => true,
        );

    test(
        'OFF-G : sans reseau, le DERNIER bulletin connu reste lisible — il n\'y '
        'a plus de duree de vie qui puisse le retirer', () async {
      // L'etat d'un telephone qui a recu la meteo le matin et marche depuis
      // quatre heures sans reseau. La regression que ce test gardait existait
      // parce qu'un `expiresAt` de trois heures filtrait la LECTURE : le TTL
      // gouvernait le DROIT D'AFFICHER au lieu du re-telechargement. La colonne
      // a disparu avec le cache (lot 625) — le bulletin est une donnee de
      // sentier, et une donnee de sentier ne s'auto-efface pas.
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 4)),
      );

      final bulletin =
          await repo().bulletinDeLEtape(trailId: trailId, stageNumber: 1);

      expect(bulletin, isNotNull);
      expect(bulletin!.ageAt()!.inHours, greaterThanOrEqualTo(3));
    });

    test(
        'OFF-G2 : SON AGE EST VISIBLE, et c\'est le point le plus important du '
        'lot 625', () async {
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 9)),
      );

      final bulletin =
          await repo().bulletinDeLEtape(trailId: trailId, stageNumber: 1);
      final fraicheur = weatherFreshness(
        produiteLe: bulletin!.produiteLeLocal,
        t: t,
      );

      expect(fraicheur.level, FreshnessLevel.jourCourantPerime,
          reason: 'Neuf heures depassent la peremption du jour courant (six '
              'heures, #T8) sans atteindre celle des jours suivants.');
      expect(fraicheur.label, contains('9'),
          reason: 'L\'AGE EST DANS LE TEXTE. Un bulletin de neuf heures presente '
              'sans son age est exactement ce que Christophe a nomme dangereux.');
      expect(fraicheur.plusAucunChiffre, isFalse,
          reason: 'A neuf heures la prevision reste une information : grisee et '
              'datee, elle n\'induit pas en erreur (#T10).');
    });

    test(
        'OFF-G3 : PASSE SOIXANTE-DOUZE HEURES, PLUS AUCUN CHIFFRE — la regle '
        'que ce lot existe pour poser', () async {
      // « Une meteo de trois jours presentee comme fraiche a quelqu'un qui
      // decide de passer un col est dangereuse » (Christophe, 28/09). #T8 de la
      // conception 611 : au-dela de 72 h, l'ecran dit qu'il ne sait plus et
      // depuis quand.
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 73)),
      );

      final bulletin =
          await repo().bulletinDeLEtape(trailId: trailId, stageNumber: 1);
      final fraicheur = weatherFreshness(
        produiteLe: bulletin!.produiteLeLocal,
        t: t,
      );

      expect(fraicheur.level, FreshnessLevel.tropVieux);
      expect(fraicheur.plusAucunChiffre, isTrue,
          reason: 'Griser ne suffit plus a cet age : un grise permanent devient '
              'une decoration qu\'on ne lit plus.');
      expect(fraicheur.label, contains('3'),
          reason: 'Et il faut dire DEPUIS QUAND on ne sait plus.');
    });

    test('OFF-G4 : la borne de 72 h est franche, pas approximative', () async {
      WeatherFreshness a(Duration age) => weatherFreshness(
            produiteLe: DateTime.now().subtract(age),
            t: t,
          );

      expect(a(const Duration(hours: 71, minutes: 59)).plusAucunChiffre, isFalse);
      expect(a(const Duration(hours: 72, minutes: 1)).plusAucunChiffre, isTrue);
    });
  });

  // ==========================================================================
  // OFF-H / MAJ — LE BOUTON PRODUIT QUELQUE CHOSE, ET DIT QUOI
  // ==========================================================================

  group('Le bouton de mise a jour produit un effet VISIBLE', () {
    late AppDatabase db;

    setUp(() => db = AppDatabase(NativeDatabase.memory()));
    tearDown(() async => db.close());

    WeatherRepository repo({
      ConnectivityStatus reseau = ConnectivityStatusValues.online,
      Future<bool> Function()? passe,
    }) =>
        WeatherRepository(
          dao: TrailMeteoDao(db),
          demanderUnePasse: passe ?? () async => true,
        );

    test(
        'MAJ-K : un rafraichissement REUSSI change la DATE DE FABRICATION '
        '(c\'est ce qui « ne produisait rien »)', () async {
      final matin = DateTime.now().toUtc().subtract(const Duration(hours: 6));
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: matin,
      );

      final avant =
          await repo().bulletinDeLEtape(trailId: trailId, stageNumber: 1);

      final resultat = await repo(passe: () async {
        // Ce que fait la vraie passe : elle POSE un bulletin plus recent.
        await deposerMeteoEnBase(
          db,
          trailId: trailId,
          stageNumber: 1,
          produiteLe: DateTime.now().toUtc(),
        );
        return true;
      }).demanderLaMiseAJour(trailId: trailId, stageNumber: 1);

      expect(resultat.echoue, isFalse);
      expect(resultat.issue, IssueMiseAJourMeteo.recue);
      expect(
        resultat.bulletin!.produiteLe! > avant!.produiteLe!,
        isTrue,
        reason: 'C\'EST LA PREUVE DU CORRECTIF U2/U3, RENDUE PLUS EXIGEANTE PAR '
            'LE LOT 625 : ce qui avance n\'est plus l\'heure a laquelle le '
            'telephone a appele, c\'est la date a laquelle le MODELE a ete '
            'fabrique. La premiere bougeait a chaque appel, meme quand le '
            'fournisseur renvoyait la meme prevision — un mouvement sans '
            'information.',
      );
    });

    test(
        'OFF-H : un rafraichissement qui echoue est NOMME et ne detruit pas le '
        'dernier bulletin connu', () async {
      final matin = DateTime.now().toUtc().subtract(const Duration(hours: 6));
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: matin,
      );

      final resultat = await repo(
        passe: () async => throw Exception('transport interrompu'),
      ).demanderLaMiseAJour(trailId: trailId, stageNumber: 1);

      expect(resultat.echoue, isTrue,
          reason: 'L\'echec doit etre NOMME pour que l\'ecran puisse le dire.');
      expect(resultat.bulletin, isNotNull,
          reason: 'Un echec de mise a jour ne vide pas l\'ecran : le randonneur '
              'garde le dernier bulletin connu, avec son age.');
      expect(
        resultat.bulletin!.produiteLe!.date.difference(matin).inSeconds.abs(),
        lessThan(2),
        reason: 'Et la date affichee reste celle de la VRAIE fabrication, pas '
            'de maintenant.',
      );
    });

    test(
        'MAJ-L : « rien de plus recent » se distingue d\'un echec, et c\'est le '
        'cas le plus frequent', () async {
      await deposerMeteoEnBase(
        db,
        trailId: trailId,
        stageNumber: 1,
        produiteLe: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
      );

      final resultat = await repo(passe: () async => true)
          .demanderLaMiseAJour(trailId: trailId, stageNumber: 1);

      expect(resultat.issue, IssueMiseAJourMeteo.rienDePlusRecent);
      expect(resultat.echoue, isFalse,
          reason: 'Avec une cadence de quatre heures, la plupart des passes ne '
              'rapportent rien. Les annoncer comme des echecs apprendrait au '
              'randonneur a ignorer le message.');
    });
  });

  // ==========================================================================
  // PORTEE — CE QU'ON DEMANDE VRAIMENT AU FOURNISSEUR
  // ==========================================================================

  group('Portee honnete des previsions', () {
    test('PORT-J : la portee annoncee est celle que le SERVEUR publie', () {
      // Decision de Christophe du 28/09 : « le serveur a une seule version de
      // meteo par etapes et ce a 3 ou 5 jours ». La conception 611 retient 5
      // (#W6) et releve que le depot en DEMANDAIT dix : « C'est le code qui
      // demandait trop, pas Christophe qui demande trop peu. »
      expect(forecastHorizonDays, 5);
      expect(reliableForecastDays, lessThanOrEqualTo(forecastHorizonDays),
          reason: 'NOAA : ~90 % de justesse a 5 jours. Tout ce que le serveur '
              'descend est donc une prevision ; le barreau « tendance » reste en '
              'place et s\'allumera si le serveur publie plus loin.');
    });

    test('PORT-K : chaque rang de jour recoit la portee qui lui revient', () {
      expect(forecastReachFor(daysAhead: 0), ForecastReach.forecast);
      expect(forecastReachFor(daysAhead: forecastHorizonDays - 1),
          ForecastReach.forecast);
      expect(forecastReachFor(daysAhead: forecastHorizonDays),
          ForecastReach.beyondHorizon,
          reason: 'Le serveur ne publie que les jours 0 a portee-1 : le jour '
              'suivant est inconnu, et on le DIT.');

      // LE BARREAU « TENDANCE » N'EST PAS MORT : il s'allume des que le serveur
      // publie au-dela de la fenetre fiable. On le verifie avec une portee recue
      // plus longue, ce qui est exactement le cas que la conception 611 demande
      // de ne pas jeter (#W6).
      expect(
        forecastReachFor(daysAhead: reliableForecastDays, porteeRecue: 10),
        ForecastReach.trend,
      );
    });

    test(
        'PORT-L : un jour DANS la portee mais absent du bulletin n\'est pas '
        'extrapole', () {
      expect(
        reachForProgramDay(daysAhead: 2, hasForecast: false),
        ForecastReach.noData,
        reason: 'Un bulletin en cache peut etre plus vieux que le programme : '
            'on ne comble pas le trou avec une valeur voisine.',
      );
      expect(
        reachForProgramDay(daysAhead: 2, hasForecast: true),
        ForecastReach.forecast,
      );
      // ET LA MOITIE DE LA REGLE QU'IL SERAIT LE PLUS FACILE D'OUBLIER : un
      // bulletin trop vieux ne rend aucun chiffre dans la LISTE DU PROGRAMME non
      // plus. C'est la section qui sert a decider ; l'ecran se taire sans qu'elle
      // se taise ne serait pas se taire.
      expect(
        reachForProgramDay(
          daysAhead: 2,
          hasForecast: true,
          bulletinTropVieux: true,
        ),
        ForecastReach.tropVieux,
      );
    });

    test('PORT-M : la journee est un jour calendaire, pas 24 heures', () {
      // Un depart a 18:00 et une prevision a 00:00 le meme jour valent 0 jour
      // d'ecart : sans ca, la journee du depart serait classee « hier ».
      expect(
        calendarDaysBetween(
          DateTime(2026, 7, 20, 18, 30),
          DateTime(2026, 7, 20),
        ),
        0,
      );
      expect(
        calendarDaysBetween(
          DateTime(2026, 7, 20, 23, 59),
          DateTime(2026, 7, 21, 0, 1),
        ),
        1,
      );
    });

    test(
        'PORT-I : LA PORTEE ANNONCEE DERIVE DE CE QUE LE SERVEUR A ENVOYE, pas '
        'd\'une constante', () async {
      // CE TEST A CHANGE DE NATURE AU LOT 625, ET C'EST LA MESURE DU LOT. Il
      // verifiait l'URL d'un appel — « l'appel demande bien la portee qu'on
      // annonce ». Il n'y a plus d'URL a verifier : l'application ne demande
      // rien. Ce qu'il faut garantir a la place est plus fort : que l'ecran
      // n'annonce pas une portee que la donnee recue ne porte pas.
      final troisJours = WeatherForecast.depuisLePublie(
        jours: joursDepuis(DateTime.now(), nombre: 3),
        latitude: 45.6,
        longitude: 3.0,
        produiteLe: HorodatageServeur.annonceParLeServeur(
          DateTime.now().toUtc().toIso8601String(),
        )!,
      );

      expect(
        reachForProgramDay(
          daysAhead: 4,
          hasForecast: false,
          porteeRecue: troisJours.days.length,
        ),
        ForecastReach.beyondHorizon,
        reason: 'Le serveur n\'a envoye que trois jours : le quatrieme est '
            '« pas encore de prevision », pas « aucune donnee pour ce lieu ». '
            'Une attente ecrite dans le code ne doit jamais contredire la donnee '
            'recue.',
      );
      expect(
        reachForProgramDay(
          daysAhead: 2,
          hasForecast: true,
          porteeRecue: troisJours.days.length,
        ),
        ForecastReach.forecast,
      );
    });
  });

  // ==========================================================================
  // PROGRAMME — LE LIEU ET LA DATE VIENNENT DU PROGRAMME, PAS D'UNE SUPPOSITION
  // ==========================================================================

  group('Programme — dates et lieux (tache 572, U1)', () {
    final today = DateTime.now();
    final departure = DateTime(today.year, today.month, today.day)
        .add(const Duration(days: 1));

    ProviderContainer containerFor({required int durationDays}) {
      final forecast = forecastFrom(today, 10);
      return ProviderContainer(overrides: [
        trailConfigProvider.overrideWithValue(testConfig),
        stagesProvider(trailId)
            .overrideWith((ref) => Future.value(threeStages)),
        selectedDurationProvider
            .overrideWith(() => _FixedDurationNotifier(durationDays)),
        downloadReminderProvider(trailId).overrideWith(
          () => _FixedDepartureNotifier(
            DepartureReminderState(departureDate: departure),
          ),
        ),
        for (var n = 1; n <= 3; n++)
          weatherOverride(
              n, WeatherState(forecast: forecast, isLoading: false)),
      ]);
    }

    test(
        'PROG-N : la DATE de chaque journee vient du programme et de la date de '
        'depart, pas de l\'index du bulletin', () async {
      final container = containerFor(durationDays: 3);
      addTearDown(container.dispose);
      // Laisser les etapes se resoudre.
      await container.read(stagesProvider(trailId).future);

      final state = container.read(programWeatherProvider(trailId));
      expect(state.days.length, greaterThanOrEqualTo(3));
      expect(state.days[0].date.day, departure.day);
      expect(
        calendarDaysBetween(state.days[0].date, state.days[1].date),
        1,
        reason: 'Jour 2 = jour 1 + 1 : « le lendemain, puis le surlendemain ».',
      );
      expect(state.days[0].dayNumber, 1);
    });

    test(
        'PROG-O : le lieu d\'une journee est l\'ARRIVEE de sa DERNIERE etape',
        () async {
      // 3 etapes sur 2 jours : une journee regroupe forcement deux etapes. Elle
      // se termine a l'arrivee de la SECONDE, pas de la premiere.
      final container = containerFor(durationDays: 2);
      addTearDown(container.dispose);
      await container.read(stagesProvider(trailId).future);

      final state = container.read(programWeatherProvider(trailId));
      final places = state.days.map((d) => d.placeName).toList();
      expect(places.last, 'Village de Cozzano',
          reason: 'La derniere journee finit a l\'arrivee de la 3e etape.');
      expect(places.every((p) => p.isNotEmpty), isTrue,
          reason: 'Un bulletin sans nom de lieu ne sert a rien : AUCUNE journee '
              'ne doit rester anonyme.');
    });

    test(
        'PROG-P : sans date de depart, aucune journee n\'est datee et l\'etat le '
        'DECLARE', () async {
      final forecast = forecastFrom(today, 10);
      final container = ProviderContainer(overrides: [
        trailConfigProvider.overrideWithValue(testConfig),
        stagesProvider(trailId)
            .overrideWith((ref) => Future.value(threeStages)),
        selectedDurationProvider.overrideWith(() => _FixedDurationNotifier(3)),
        downloadReminderProvider(trailId).overrideWith(
          () => _FixedDepartureNotifier(const DepartureReminderState()),
        ),
        for (var n = 1; n <= 3; n++)
          weatherOverride(
              n, WeatherState(forecast: forecast, isLoading: false)),
      ]);
      addTearDown(container.dispose);
      await container.read(stagesProvider(trailId).future);

      final state = container.read(programWeatherProvider(trailId));
      expect(state.departureUnknown, isTrue);
      expect(
        state.days.every((d) => d.reach == ForecastReach.unknownDeparture),
        isTrue,
        reason: 'On ne suppose pas que le trek part aujourd\'hui (meme regle '
            'que la faisabilite, LOT R).',
      );
      expect(
        state.days.every((d) => !d.hasValue),
        isTrue,
        reason: 'Et on n\'affiche AUCUN chiffre qu\'on ne sait pas rattacher a '
            'une date.',
      );
    });
  });
}

/// LA REPONSE OPEN-METEO ET LA PANNE RESEAU SIMULEE ONT DISPARU D'ICI (lot 625).
///
/// Elles servaient a eprouver un appel sortant que l'application ne fait plus. Leur
/// absence est la mesure la plus simple du lot : il n'existe plus, dans ce fichier,
/// de forme de reponse de fournisseur a imiter.

/// Notifier meteo de test : etat fixe, aucune DB ni reseau.
class _FixedWeatherNotifier extends StageWeatherNotifier {
  _FixedWeatherNotifier(this._fixed)
      : super(const WeatherStageParams(trailId: 'test-trail', stageNumber: 0));

  final WeatherState _fixed;

  @override
  WeatherState build() => _fixed;
}

/// Notifier de date de depart de test : etat fixe, aucune SharedPreferences.
class _FixedDepartureNotifier extends DownloadReminderNotifier {
  _FixedDepartureNotifier(this._fixed) : super('test-trail');

  final DepartureReminderState _fixed;

  @override
  DepartureReminderState build() => _fixed;
}

/// Notifier de duree de test : duree figee (aucune persistance).
class _FixedDurationNotifier extends SelectedDurationNotifier {
  _FixedDurationNotifier(this._fixed);

  final int _fixed;

  @override
  int build() => _fixed;
}
