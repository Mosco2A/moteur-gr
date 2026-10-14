import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/core/utils/nombre_en_clair.dart';
import 'package:moteur_gr/features/map/providers/gpx_track_provider.dart';
import 'package:moteur_gr/features/map/providers/location_provider.dart';
import 'package:moteur_gr/features/map/providers/supply_alert_provider.dart';
import 'package:moteur_gr/features/trail/providers/stages_provider.dart';
import 'package:moteur_gr/domain/trek_session.dart';
import 'package:moteur_gr/features/trek/presentation/map/map_screen.dart';
import 'package:moteur_gr/features/trek/providers/gps_providers.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// Correctif L6-1 — LE MONTAGE de l'alerte ravitaillement sur la carte.
///
/// La REGLE de declenchement est testee a part (supply_alert_provider_test).
/// Ici on ne verifie que ce que ce correctif a reellement ajoute : la
/// minuterie, la fermeture a la main, et le rearmement au changement d'etape.
void main() {
  final mockTrackPoints = [
    const TrackPoint(
      lat: 45.77,
      lng: 2.96,
      altitude: 1465,
      distanceFromStart: 0,
    ),
    const TrackPoint(
      lat: 45.78,
      lng: 2.97,
      altitude: 1500,
      distanceFromStart: 1200,
    ),
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

  TrekSession recordingSession() => TrekSession(
    id: 'sess-supply-1',
    trailId: 'test-trail',
    startedAt: DateTime.utc(2026, 6, 15, 8),
    status: 'active',
  );

  /// Alerte pilotee par le test (permet de changer d etape en cours de route).
  final alerteProvider = StateProvider<SupplyGapAlert?>(
    (ref) => const SupplyGapAlert(stageNumber: 3, gap: 6),
  );

  Widget harness({required TrackingSessionStatus status}) {
    return ProviderScope(
      overrides: [
        trailConfigProvider.overrideWithValue(testTrailConfig),
        gpxTrackProvider(
          testTrailConfig.id,
        ).overrideWith((ref) => Future.value(mockTrackPoints)),
        gpxTrackProvider(
          'default',
        ).overrideWith((ref) => Future.value(mockTrackPoints)),
        stagesProvider(
          testTrailConfig.id,
        ).overrideWith((ref) => Future.value(mockStages)),
        stagesProvider(
          'default',
        ).overrideWith((ref) => Future.value(mockStages)),
        gpsPermissionProvider.overrideWith(
          (ref) => Future.value(GpsPermissionStateValues.denied),
        ),
        trekSessionManagerProvider.overrideWith(
          () => _FixedStatusNotifier(
            TrackingSessionState(
              status: status,
              session:
                  status == TrackingSessionStatus.recording ||
                      status == TrackingSessionStatus.paused
                  ? recordingSession()
                  : null,
            ),
          ),
        ),
        currentStageIdProvider.overrideWith((ref) => const Stream.empty()),
        // L alerte elle-meme est pilotee par le test.
        supplyGapAlertProvider.overrideWith((ref) => ref.watch(alerteProvider)),
      ],
      child: const MaterialApp(home: MapScreen(trailId: 'test-trail')),
    );
  }

  /// Conteneur Riverpod de l ecran monte (pour piloter l alerte en cours de
  /// test, comme le ferait un changement d etape reel).
  ProviderContainer conteneur(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(MapScreen)));

  String texteAlerte(int gap) => t.shop.gapLong(n: gap);

  /// LES LARGEURS DE TELEPHONE MESUREES, reprises des gardes 801 et 836 :
  /// 320 est le plus petit encore vendu, 412 le plus large courant.
  const largeurs = <double>[320, 360, 390, 412];

  /// Hauteur d'un telephone courant.
  const hauteur = 844.0;

  /// Mesure la hauteur du bandeau portant [texte], a [largeur] de large.
  Future<double> hauteurDuBandeau(
    WidgetTester tester, {
    required SupplyGapAlert alerte,
    required String texte,
    required double largeur,
  }) async {
    tester.view.physicalSize = Size(largeur, hauteur);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
    conteneur(tester).read(alerteProvider.notifier).state = alerte;
    await tester.pump(const Duration(milliseconds: 100));
    final cible = find.text(texte);
    expect(cible, findsOneWidget, reason: 'libelle introuvable : $texte');
    // Le Material du bandeau est le premier ancetre de ce genre.
    final bandeau = find
        .ancestor(of: cible, matching: find.byType(Material))
        .first;
    final taille = tester.getSize(bandeau);
    // AUCUN DEBORDEMENT : Flutter ne crie pas toujours, mais quand il crie il
    // faut l'entendre.
    expect(tester.takeException(), isNull);
    return taille.height;
  }

  group('Alerte ravitaillement sur la carte (L6-1)', () {
    testWidgets('visible pendant un trek, libelle TRADUIT et nombre injecte', (
      tester,
    ) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is StepIcon && w.asset == StepwaysIcons.danger,
        ),
        findsOneWidget,
      );
    });

    testWidgets('AUCUNE alerte hors trek', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.idle));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('s efface SEULE au bout d une minute', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      // Toujours la a 59 s : la minuterie ne coupe pas la lecture trop tot.
      await tester.pump(const Duration(seconds: 59));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('se ferme a la demande et RESTE fermee', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip(t.map.supplyDismiss));
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);

      // Le temps passe : rien ne la fait revenir sur la meme etape.
      await tester.pump(const Duration(seconds: 120));
      expect(find.text(texteAlerte(6)), findsNothing);
    });

    testWidgets('se REARME au changement d etape, meme apres fermeture', (
      tester,
    ) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byTooltip(t.map.supplyDismiss));
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);

      // Nouvelle etape = nouvelle decision de ravitaillement.
      conteneur(tester).read(alerteProvider.notifier).state =
          const SupplyGapAlert(stageNumber: 4, gap: 5);
      await tester.pump();
      expect(find.text(texteAlerte(5)), findsOneWidget);
    });

    testWidgets('DIT LA TAILLE DU TROU : les etapes ET les kilometres', (
      tester,
    ) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      conteneur(tester).read(alerteProvider.notifier).state =
          const SupplyGapAlert(stageNumber: 2, gap: 5, km: 52.5);
      await tester.pump(const Duration(milliseconds: 100));

      // Le trou reel du Mare a Mare Centre, mot pour mot.
      expect(
        find.text(
          'Dernier ravitaillement avant 5 étapes et 52,5 km. '
          'Prévois tes réserves !',
        ),
        findsOneWidget,
      );
      expect(find.text(t.shop.limitedTitle), findsOneWidget);
    });

    testWidgets('L EAU A SON PROPRE TITRE ET SON PROPRE TEXTE', (tester) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      conteneur(
        tester,
      ).read(alerteProvider.notifier).state = const SupplyGapAlert(
        stageNumber: 1,
        gap: 2,
        kind: SupplyGapKind.water,
        km: 28.6,
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Points d\'eau limités'), findsOneWidget);
      expect(
        find.text(
          'Dernier point d\'eau avant 2 étapes et 28,6 km. '
          'Fais le plein !',
        ),
        findsOneWidget,
      );
      // Et surtout : le libelle de l'eau ne parle JAMAIS de commerce.
      expect(find.text(texteAlerte(2)), findsNothing);
    });

    testWidgets('sans distances connues, elle parle encore — en etapes', (
      tester,
    ) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      conteneur(
        tester,
      ).read(alerteProvider.notifier).state = const SupplyGapAlert(
        stageNumber: 1,
        gap: 2,
        kind: SupplyGapKind.water,
      );
      await tester.pump(const Duration(milliseconds: 100));
      // Pas de « 0 km » invente : le libelle sans portee, et celui de l'eau.
      expect(
        find.text('Dernier point d\'eau avant 2 étapes. Fais le plein !'),
        findsOneWidget,
      );
    });

    testWidgets('disparait des que l ecart n est plus alarmant', (
      tester,
    ) async {
      await tester.pumpWidget(harness(status: TrackingSessionStatus.recording));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text(texteAlerte(6)), findsOneWidget);

      conteneur(tester).read(alerteProvider.notifier).state = null;
      await tester.pump();
      expect(find.text(texteAlerte(6)), findsNothing);
    });
  });

  /// LA MESURE DE LA PLACE, AVANT DE POSER LE TEXTE (tache 834).
  ///
  /// Le bandeau s'affiche pendant la marche, dans la MEME [Column] que la
  /// pastille SOS et au-dessus d'elle : un bandeau plus haut repousse le SOS
  /// vers le bas. On ne mesure donc pas « est-ce que ca deborde », on mesure
  /// « est-ce que ca prend PLUS DE PLACE QU'AVANT ».
  ///
  /// LE TEMOIN EST L'ANCIEN LIBELLE, celui qui ne parle qu'en etapes. Si le
  /// libelle neuf — qui ajoute la portee en kilometres — ne depasse pas sa
  /// hauteur, alors la tache 834 n'a rien coute a l'ecran. Et ce n'est pas un
  /// hasard : « et 52,5 km » (dix caracteres) remplace « sans commerce »
  /// (treize), le texte neuf est plus COURT que l'ancien.
  ///
  /// La lecon vient de la tache 844, ou une note de donnee rallongee a fait
  /// deborder un bandeau de 124 pixels sur un telephone courant.
  group('La place prise par le bandeau (834)', () {
    for (final largeur in largeurs) {
      testWidgets('a $largeur de large, le texte neuf ne grandit pas', (
        tester,
      ) async {
        final temoin = await hauteurDuBandeau(
          tester,
          alerte: const SupplyGapAlert(stageNumber: 2, gap: 5),
          texte: texteAlerte(5),
          largeur: largeur,
        );
        final avecPortee = await hauteurDuBandeau(
          tester,
          alerte: const SupplyGapAlert(stageNumber: 2, gap: 5, km: 52.5),
          texte:
              'Dernier ravitaillement avant 5 étapes et 52,5 km. '
              'Prévois tes réserves !',
          largeur: largeur,
        );
        expect(
          avecPortee,
          lessThanOrEqualTo(temoin),
          reason:
              'le libelle avec la portee prend ${avecPortee - temoin} points '
              'de plus que l ancien a $largeur de large',
        );
      });
    }

    testWidgets('le libelle de l EAU tient dans la meme place', (tester) async {
      final temoin = await hauteurDuBandeau(
        tester,
        alerte: const SupplyGapAlert(stageNumber: 1, gap: 2),
        texte: texteAlerte(2),
        largeur: 320,
      );
      final eau = await hauteurDuBandeau(
        tester,
        alerte: const SupplyGapAlert(
          stageNumber: 1,
          gap: 2,
          kind: SupplyGapKind.water,
          km: 28.6,
        ),
        texte:
            'Dernier point d\'eau avant 2 étapes et 28,6 km. Fais le plein !',
        largeur: 320,
      );
      expect(eau, lessThanOrEqualTo(temoin));
    });

    testWidgets('AUCUN DEBORDEMENT DANS LES CINQ LANGUES', (tester) async {
      // Les cinq langues n'ont pas la meme longueur : l'allemand et l'espagnol
      // sont les plus bavards. On passe sur le plus petit telephone vendu.
      addTearDown(() => LocaleSettings.setLocaleRaw('fr'));
      for (final langue in <String>['fr', 'en', 'de', 'it', 'es']) {
        LocaleSettings.setLocaleRaw(langue);
        tester.view.physicalSize = const Size(320, hauteur);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        // ON REPART D'UN ARBRE VIDE, ET C'EST INDISPENSABLE : [SupplyGapAlert]
        // a une egalite de VALEUR, donc reposer la meme alerte ne notifie
        // personne et le bandeau garderait le texte de la langue precedente.
        // Sans cette ligne, ce test passe au vert en ne mesurant que le
        // francais, cinq fois.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          harness(status: TrackingSessionStatus.recording),
        );
        conteneur(
          tester,
        ).read(alerteProvider.notifier).state = const SupplyGapAlert(
          stageNumber: 1,
          gap: 2,
          kind: SupplyGapKind.water,
          km: 28.6,
        );
        await tester.pump(const Duration(milliseconds: 100));
        // La portee se met en forme dans la langue : « 28,6 » en francais,
        // « 28.6 » en anglais.
        final portee = nombreEnClair(28.6, langue);
        expect(
          find.text(t.map.waterGapRange(n: 2, km: portee)),
          findsOneWidget,
          reason: 'libelle d eau absent en $langue',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'debordement en $langue',
        );
      }
    });
  });
}

/// Notifier de session fige sur un statut (meme harnais que les autres tests
/// de la carte).
class _FixedStatusNotifier extends TrekSessionManagerNotifier {
  _FixedStatusNotifier(this._initial);

  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
