import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:moteur_gr/core/data/daos/session_track_points_dao.dart';
import 'package:moteur_gr/core/services/gps_cadence.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';
import 'package:moteur_gr/domain/age_de_position.dart';
import 'package:moteur_gr/features/safety/presentation/sos_button.dart';
import 'package:moteur_gr/features/safety/presentation/sos_confirmation_dialog.dart';
import 'package:moteur_gr/features/trek/data/background_gps_service.dart';
import 'package:moteur_gr/features/trek/data/gps_service.dart';
import 'package:moteur_gr/features/trek/data/position_connue.dart';
import 'package:moteur_gr/features/trek/data/position_controller.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';

/// LOT 671-04 — LE SOS EN TIR UNIQUE, ET UNE POSITION TOUJOURS AFFICHEE AVEC
/// SON AGE. PROUVE SANS TELEPHONE : LE BALAYAGE DES GESTES NE TOUCHE PAS AU
/// SOS (il evite « sos », « 112 » et l'icone d'urgence, parce qu'il appelait
/// vraiment le numero d'urgence) — tout est donc ici, nommement.
///
/// LES FAUX : un faux fournisseur de position passe par la fabrique du
/// robinet ([PositionController], `currentPosition` et `positionStream`), qui
/// rend, tarde ou refuse a la demande et compte ce qu'on lui demande ; une
/// fausse horloge pour l'age ; un journal dans un dossier temporaire ; un
/// faux trek en cours. Aucun capteur, aucun temps reel.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final t0 = DateTime(2026, 10, 7, 14);

  Position position(double lat, double lng, DateTime at) => Position(
    latitude: lat,
    longitude: lng,
    timestamp: at,
    accuracy: 5,
    altitude: 1200,
    altitudeAccuracy: 3,
    heading: 0,
    headingAccuracy: 0,
    speed: 1,
    speedAccuracy: 0,
  );

  group('(4) L AGE, AUX BORNES, SUR UNE HORLOGE INJECTEE — une fonction pure, '
      'appelee sans monter de widget', () {
    AgeEnClair? age(int secondes) => ageEnClair(
      mesureeA: t0,
      maintenant: t0.add(Duration(seconds: secondes)),
    );

    test('0 s et 59 s : a l instant', () {
      expect(age(0), isNull);
      expect(age(59), isNull);
    });

    test('60 s, 61 s et 119 s : une minute', () {
      for (final s in [60, 61, 119]) {
        expect(age(s), (heures: 0, minutes: 1), reason: '$s s');
      }
    });

    test('179 s : DEUX minutes, JAMAIS trois — l arrondi est vers le bas', () {
      expect(age(179), (heures: 0, minutes: 2));
    });

    test('3 600 s : une heure ; 3 725 s : une heure et deux minutes', () {
      expect(age(3600), (heures: 1, minutes: 0));
      expect(age(3725), (heures: 1, minutes: 2));
    });

    test('une heure de mesure dans le futur (horloge d un autre appareil) : '
        'a l instant, jamais un age negatif', () {
      expect(age(-30), isNull);
    });
  });

  /// Le banc du bouton : un trek en cours, un robinet sur un faux
  /// fournisseur, une fausse horloge, un journal temporaire.
  late Directory dossier;
  late MeasureJournal journal;
  late DateTime maintenant;
  late int fluxOuverts;
  late List<Completer<Position>> tirs;
  late PositionController robinet;
  BgTrackPoint? pointDeFond;

  setUp(() async {
    dossier = await Directory.systemTemp.createTemp('sos_671_');
    journal = MeasureJournal(directory: () async => dossier);
    maintenant = t0;
    fluxOuverts = 0;
    tirs = [];
    pointDeFond = null;
    robinet = PositionController(
      positionStream: ({required locationSettings}) {
        fluxOuverts++;
        return const Stream.empty();
      },
      currentPosition: ({required locationSettings}) {
        final c = Completer<Position>();
        tirs.add(c);
        return c.future;
      },
      readProfile: () async => PositionProfile.batteryFirst,
    );
    await robinet.setProfile(PositionProfile.batteryFirst);
  });

  // Le journal ecrit sur le vrai disque, que le temps simule des tests de
  // widgets n'attend pas : on n'attend donc rien ici, on efface.
  tearDown(() {
    if (dossier.existsSync()) dossier.deleteSync(recursive: true);
  });

  /// Le robinet a recu un releve a [at] : la derniere position connue.
  Future<void> releveA(DateTime at, {double lat = 42.1, double lng = 9.1}) {
    final shot = robinet.singleShot();
    tirs.removeLast().complete(position(lat, lng, at));
    return shot;
  }

  Widget bouton() => ProviderScope(
    overrides: [
      trekSessionManagerProvider.overrideWith(
        () => _TrekEnCours(
          const TrackingSessionState(status: TrackingSessionStatus.recording),
        ),
      ),
      positionControllerProvider.overrideWithValue(robinet),
      positionsConnuesProvider.overrideWithValue(
        PositionsConnues(
          robinet: robinet,
          pointDeFond: () => pointDeFond,
          journal: journal,
          maintenant: () => maintenant,
        ),
      ),
    ],
    child: TranslationProvider(
      child: const MaterialApp(
        home: Scaffold(
          floatingActionButton: SosButton(),
          body: SizedBox.shrink(),
        ),
      ),
    ),
  );

  Future<void> appuyer(WidgetTester tester) async {
    await tester.pumpWidget(bouton());
    await tester.pump();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
  }

  /// DANS LES TROIS CAS : l'appel du 112 et la fiche medicale sont la, et
  /// actifs. Un dialogue de secours sans appel serait pire que le defaut
  /// d'origine.
  void lesSecoursSontLa() {
    final appel = tester112();
    expect(appel.onPressed, isNotNull, reason: 'le bouton 112 est inactif');
    final fiche = find.byKey(const ValueKey('sos-medical-id'));
    expect(fiche, findsOneWidget);
    expect(
      (fiche.evaluate().single.widget as InkWell).onTap,
      isNotNull,
      reason: 'la fiche medicale est inactive',
    );
  }

  group('(3) LES TROIS CAS DU SOS — aucun n affiche « position indisponible » '
      'tout seul', () {
    testWidgets('POSITION FRAICHE OBTENUE : la connue s affiche TOUT DE SUITE '
        'avec son age, puis la fraiche la remplace et l age repasse a '
        'l instant', (tester) async {
      await releveA(t0, lat: 42.10000, lng: 9.10000);
      maintenant = t0.add(const Duration(seconds: 179));
      await appuyer(tester);

      expect(find.text('Lat: 42.10000'), findsOneWidget);
      expect(find.text('Position il y a 2 min'), findsOneWidget);
      expect(find.text(t.sos.gpsAcquiring), findsOneWidget);
      expect(find.text(t.sos.positionUnavailable), findsNothing);
      lesSecoursSontLa();

      tirs.single.complete(position(42.20000, 9.20000, maintenant));
      await tester.pump();
      expect(find.text('Lat: 42.20000'), findsOneWidget);
      expect(find.text('Lat: 42.10000'), findsNothing);
      expect(find.text(t.sos.ageNow), findsOneWidget);
      expect(find.text(t.sos.gpsAcquiring), findsNothing);
      lesSecoursSontLa();
      await _fermer(tester);
    });

    testWidgets('LE TIR TARDE AU-DELA DE 15 s : le dialogue le DIT et GARDE '
        'l ancienne position avec son age — les coordonnees sont TOUJOURS '
        'a l ecran apres l echec', (tester) async {
      await releveA(t0, lat: 42.10000, lng: 9.10000);
      maintenant = t0.add(const Duration(minutes: 3));
      await appuyer(tester);
      expect(find.text(t.sos.gpsAcquiring), findsOneWidget);

      await tester.pump(kSingleShotMaxDelay + const Duration(seconds: 1));
      expect(
        find.text(t.sos.freshFailed(seconds: kSingleShotMaxDelay.inSeconds)),
        findsOneWidget,
      );
      expect(find.text('Lat: 42.10000'), findsOneWidget);
      expect(find.text('Lng: 9.10000'), findsOneWidget);
      expect(find.text('Position il y a 3 min'), findsOneWidget);
      expect(find.text(t.sos.gpsAcquiring), findsNothing);
      expect(find.text(t.sos.positionUnavailable), findsNothing);
      lesSecoursSontLa();
      // Une reponse tardive apres l'echec remplace quand meme ? Non : le tir
      // est clos, l'affichage ne saute plus sous les yeux.
      tirs.single.complete(position(42.3, 9.3, maintenant));
      await tester.pump();
      expect(find.text('Lat: 42.10000'), findsOneWidget);
      await _fermer(tester);
    });

    testWidgets('LE RECEPTEUR REFUSE (erreur du tir) : meme reponse que le '
        'retard, l ancienne position reste', (tester) async {
      await releveA(t0);
      maintenant = t0.add(const Duration(minutes: 1));
      await appuyer(tester);
      tirs.single.completeError(TimeoutException('pas de ciel'));
      await tester.pump();
      expect(
        find.text(t.sos.freshFailed(seconds: kSingleShotMaxDelay.inSeconds)),
        findsOneWidget,
      );
      expect(find.text('Position il y a 1 min'), findsOneWidget);
      lesSecoursSontLa();
      await _fermer(tester);
    });

    testWidgets('AUCUNE POSITION CONNUE : l indisponibilite s affiche AVEC '
        'ce que le randonneur peut faire, et les secours restent', (
      tester,
    ) async {
      await appuyer(tester);
      expect(find.text(t.sos.positionUnavailable), findsOneWidget);
      expect(find.text(t.sos.unavailableHelp), findsOneWidget);
      expect(find.text(t.sos.gpsAcquiring), findsOneWidget);
      lesSecoursSontLa();
      await tester.pump(kSingleShotMaxDelay + const Duration(seconds: 1));
      expect(find.text(t.sos.positionUnavailable), findsOneWidget);
      expect(find.text(t.sos.unavailableHelp), findsOneWidget);
      lesSecoursSontLa();
      await _fermer(tester);
    });

    testWidgets('UN POINT ESTIME LE LONG DU TRACE (isolate de fond) est '
        'montre comme tel, avec son age', (tester) async {
      await releveA(t0, lat: 42.10000);
      pointDeFond = BgTrackPoint(
        id: 'e',
        sessionId: 's',
        trailId: 'banc',
        latitude: 42.15000,
        longitude: 9.15000,
        altitude: 1300,
        accuracy: 0,
        speed: 0,
        timestamp: t0.add(const Duration(minutes: 2)),
        source: TrackPointSource.estimated,
        trackDistanceM: 1500,
      );
      maintenant = t0.add(const Duration(minutes: 2, seconds: 30));
      await appuyer(tester);
      expect(find.text('Lat: 42.15000'), findsOneWidget);
      expect(find.text(t.sos.ageNow), findsOneWidget);
      expect(find.text(t.sos.estimated), findsOneWidget);
      expect(find.text('Alt: 1300 m'), findsOneWidget);
      await _fermer(tester);
    });
  });

  testWidgets('(4) LE DIALOGUE MONTRE L AGE DE LA POSITION — une position '
      'sans son age est un mensonge dans une situation d urgence', (
    tester,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: SosConfirmationDialog(
              connue: PositionConnue(
                latitude: 42.1,
                longitude: 9.1,
                mesureeA: t0,
              ),
              maintenant: () => t0.add(const Duration(seconds: 179)),
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('sos-age')),
      findsOneWidget,
      reason: 'aucun age sous la position montree aux secours',
    );
    expect(find.text('Position il y a 2 min'), findsOneWidget);
  });

  testWidgets('(5) AUCUNE SOUSCRIPTION PERMANENTE POUR LE SOS : en profil '
      'batterie d abord, afficher le bouton n ouvre AUCUN flux et ne tire '
      'rien ; l appui tire UNE fois, et plus rien ensuite', (tester) async {
    await tester.pumpWidget(bouton());
    await tester.pump(const Duration(minutes: 10));
    expect(robinet.profile, PositionProfile.batteryFirst);
    expect(
      (fluxOuverts: fluxOuverts, tirs: tirs.length),
      (fluxOuverts: 0, tirs: 0),
      reason:
          'une souscription continue existe en profil batterie d abord : le '
          'bouton SOS tient le robinet ouvert ($fluxOuverts flux, '
          '${tirs.length} tirs en 10 min sans que personne ait appuye)',
    );
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(tirs, hasLength(1));
    expect(robinet.hasLiveSubscription, isFalse);
    tirs.single.complete(position(42.2, 9.2, maintenant));
    await tester.pump(const Duration(minutes: 10));
    expect(tirs, hasLength(1));
    expect(fluxOuverts, 0);
    await _fermer(tester);
  });

  testWidgets('(6) LE JOURNAL : l appui ecrit UNE ligne sos, neuf champs, la '
      'position affichee et son age en secondes', (tester) async {
    // Un journal ne dans le temps simule du test : sa file s'y vide.
    journal = MeasureJournal(directory: () async => dossier);
    await releveA(t0, lat: 42.1, lng: 9.1);
    maintenant = t0.add(const Duration(seconds: 179));
    await appuyer(tester);
    // L'ecriture du journal est synchrone sous son verrou : quelques images
    // suffisent a vider sa file.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    final lignes = File(
      '${dossier.path}/$kMeasureJournalFileName',
    ).readAsLinesSync();
    final sos = lignes.where((l) => l.split(';')[2] == 'sos').toList();
    expect(sos, hasLength(1));
    final champs = sos.single.split(';');
    expect(champs, hasLength(kMeasureEventFieldCount));
    expect(MeasureEvent.fromWord(champs[2]), MeasureEvent.sos);
    expect(champs[1], PositionProfile.batteryFirst.journalLabel);
    expect(champs[5], '42.100000,9.100000');
    expect(champs[8], '179.0');
    expect(() => MeasureEvent.fromWord('appel'), throwsArgumentError);
    await _fermer(tester);
  });
}

/// Le bouton d'appel du 112 du dialogue.
AppButton tester112() =>
    find
            .byWidgetPredicate((w) => w is AppButton && w.label == t.sos.call)
            .evaluate()
            .single
            .widget
        as AppButton;

/// Ferme le dialogue et laisse partir ses minuteurs.
Future<void> _fermer(WidgetTester tester) async {
  await tester.tap(find.text(t.sos.cancel));
  await tester.pump(kSingleShotMaxDelay + const Duration(seconds: 1));
}

class _TrekEnCours extends TrekSessionManagerNotifier {
  _TrekEnCours(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
