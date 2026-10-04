import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/geo/trace_point.dart';
import 'package:moteur_gr/core/models/stage_row.dart';
import 'package:moteur_gr/features/map/domain/stage_focus.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';

/// TACHE 558 — LA CARTE : OU ELLE S'OUVRE, ET A QUOI ELLE RESSEMBLE.
///
/// DEUX RETOURS DE CHRIS, mot pour mot :
///  * « Je veux etre a la premiere etape et voir le sentier !!! » — la carte
///    s'ouvrait cadree sur le sentier ENTIER (125 km de diagonale mesures a
///    l'ouverture par la campagne personas) : le trace y tient dans un fil de
///    quelques pixels et on n'est nulle part en particulier ;
///  * « enleve dans randonnee le laius sur les tiret . Et respecte la FORME GR20
///    pour cet ecran! » — les six chiffres etaient poses a plat dans un `Wrap`,
///    sous une phrase qui expliquait les tirets.
void main() {
  StageModel stage(
    int num,
    double lat0,
    double lng0,
    double lat1,
    double lng1,
  ) => StageModel(
    trailId: 'test-trail',
    stageNumber: num,
    name: 'Etape $num',
    distanceKm: 10,
    elevationGainM: 400,
    elevationLossM: 300,
    startLat: lat0,
    startLng: lng0,
    endLat: lat1,
    endLng: lng1,
  );

  // Trois etapes qui se suivent le long d'un meridien : de quoi distinguer sans
  // ambiguite le troncon d'une etape du sentier entier.
  final stages = [
    stage(1, 42.00, 9.00, 42.10, 9.00),
    stage(2, 42.10, 9.00, 42.20, 9.00),
    stage(3, 42.20, 9.00, 42.30, 9.00),
  ];

  List<TrackPoint> trace() => [
    for (var i = 0; i <= 30; i++)
      TrackPoint(
        lat: 42.00 + i * 0.01,
        lng: 9.00,
        altitude: 500,
        distanceFromStart: i * 1000,
      ),
  ];

  // ---------------------------------------------------------------------------
  group('mapFocusStage — l etape sur laquelle la carte s ouvre', () {
    test('sans progression connue : la PREMIERE etape', () {
      expect(mapFocusStage(stages, null)!.stageNumber, 1);
    });

    test('avec une etape courante en base : CELLE-LA', () {
      // C'etait le point ouvert signale par le lot 554 : la colonne
      // `currentStage` etait ECRITE par le suivi de trek et lue par personne.
      expect(mapFocusStage(stages, 3)!.stageNumber, 3);
    });

    test(
      'un numero hors du sentier ne fait rien inventer : premiere etape',
      () {
        expect(mapFocusStage(stages, 99)!.stageNumber, 1);
        expect(mapFocusStage(stages, 0)!.stageNumber, 1);
      },
    );

    test('« premiere » = plus petit NUMERO, pas premiere de la liste', () {
      // La base peut rendre les lignes dans n importe quel ordre.
      final desordre = [stages[2], stages[0], stages[1]];
      expect(mapFocusStage(desordre, null)!.stageNumber, 1);
    });

    test(
      'aucune etape chargee : on ne cadre sur rien plutot que sur un devine',
      () {
        expect(mapFocusStage(const [], 1), isNull);
        expect(mapFocusStage(null, 1), isNull);
      },
    );
  });

  // ---------------------------------------------------------------------------
  group('stageTrackSegment — le troncon de trace d une etape', () {
    test('le troncon est BEAUCOUP plus petit que le sentier entier', () {
      final points = trace();
      final segment = stageTrackSegment(points, stages[0]);

      expect(segment, isNotEmpty);
      expect(
        segment.length,
        lessThan(points.length),
        reason: 'sinon on cadre encore sur tout le sentier',
      );
      // Etape 1 = du point 0 au point 10 sur 30 : environ un tiers du trace.
      expect(segment.first.lat, closeTo(42.00, 1e-6));
      expect(segment.last.lat, closeTo(42.10, 1e-6));
    });

    test('chaque etape retrouve SON troncon, dans l ordre', () {
      final points = trace();
      final s1 = stageTrackSegment(points, stages[0]);
      final s3 = stageTrackSegment(points, stages[2]);
      expect(s1.last.lat, lessThan(s3.first.lat));
      expect(s3.last.lat, closeTo(42.30, 1e-6));
    });

    test(
      'trace absent ou etape hors trace : liste VIDE, et l appelant se rabat',
      () {
        expect(stageTrackSegment(const [], stages[0]), isEmpty);
        expect(stageTrackSegment([trace().first], stages[0]), isEmpty);
        // Depart et arrivee qui tombent sur le meme point de trace : rien
        // d'exploitable, on ne fabrique pas un cadrage sur une donnee manquante.
        final degenere = stage(9, 42.00, 9.00, 42.001, 9.00);
        expect(
          stageTrackSegment([trace().first, trace()[1]], degenere),
          isEmpty,
        );
      },
    );

    test('nearestTrackPointIndex trouve bien le point le plus proche', () {
      final points = trace();
      expect(nearestTrackPointIndex(points, 42.00, 9.00), 0);
      expect(nearestTrackPointIndex(points, 42.30, 9.00), 30);
      expect(nearestTrackPointIndex(points, 42.152, 9.00), 15);
    });
  });

  // ---------------------------------------------------------------------------
  // GARDE-FOU DE NON-RETOUR sur le cadrage, lu sur la source : c'est
  // `initialCameraFit` qui prenait les bornes du trace COMPLET, et c'est la
  // seule ligne ou le defaut peut revenir.
  group('la carte ne s ouvre plus sur le sentier entier', () {
    test('le cadrage d ouverture passe par le troncon de l etape', () {
      final source = _sourceAvecSesVoisines(
        'lib/features/trek/presentation/map/map_screen.dart',
      );
      expect(
        source.contains('stageTrackSegment'),
        isTrue,
        reason: 'le cadrage doit porter sur le troncon de l etape',
      );
      expect(
        source.contains('currentStageNumberProvider'),
        isTrue,
        reason: 'et suivre l etape courante quand la base en connait une',
      );
      expect(
        source.contains('focusBounds ?? bounds'),
        isTrue,
        reason: 'avec un repli EXPLICITE sur le sentier entier',
      );
    });

    test('le laius sur les tirets a quitte l ecran', () {
      // LOT 645-06, VAGUE 2 : cette garde est NEGATIVE — elle affirme une
      // ABSENCE. Elle lisait la racine `map_screen.dart` en direct, ce qui
      // suffisait quand la racine portait les 1236 lignes de l'ecran. Depuis la
      // scission en `part`, la racine ne porte plus que ses imports et ses six
      // directives : la garde ne lisait plus que 62 lignes, et le voisinage
      // qu'elle surveille a demenage dans `map_screen_barres.dart`. Elle ne
      // pouvait donc PLUS JAMAIS rougir — verte en silence, le pire etat d'une
      // garde. On lit desormais la bibliotheque ENTIERE, racine et morceaux.
      // LOT 645-06b : plus de `part` (regle 12) ; l'ecran et ses bibliotheques
      // voisines du meme dossier sont lus ensemble, le voisinage surveille vit
      // dans `map_content.dart`.
      // L'attente ne bouge pas d'un caractere : ce laius n'est nulle part.
      final source = _sourceAvecSesVoisines(
        'lib/features/trek/presentation/map/map_screen.dart',
      );
      expect(source.contains('t.map.statsPendingNote'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  group('StageProgressBar — FORME GR20 : six cases, deux lignes, centrees', () {
    Widget bar({bool pending = true}) => MaterialApp(
      home: Scaffold(
        body: StageProgressBar(
          stageName: 'Etape 1',
          distanceRemainingKm: 12,
          progressRatio: 0,
          isOffTrack: false,
          totalDistanceKm: 120.5,
          distanceCoveredKm: 4.2,
          elevationGainM: 800,
          elevationLossM: 600,
          avgSpeedKmh: 3.4,
          altitudeM: 1465,
          showPendingValues: pending,
        ),
      ),
    );

    testWidgets('les six chiffres tiennent sur DEUX lignes de trois', (
      tester,
    ) async {
      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      // Les six libelles sont la...
      for (final label in [
        t.tracking.total,
        t.tracking.covered,
        t.tracking.avgSpeed,
        t.tracking.dPlus,
        t.tracking.dMinus,
        t.tracking.altitude,
      ]) {
        expect(find.text(label), findsOneWidget);
      }

      // ... sur DEUX hauteurs distinctes, trois par hauteur.
      final hauteurs = <double, int>{};
      for (final label in [
        t.tracking.total,
        t.tracking.covered,
        t.tracking.avgSpeed,
        t.tracking.dPlus,
        t.tracking.dMinus,
        t.tracking.altitude,
      ]) {
        final y = tester.getTopLeft(find.text(label)).dy;
        hauteurs[y] = (hauteurs[y] ?? 0) + 1;
      }
      expect(hauteurs.length, 2, reason: 'deux lignes, pas un Wrap a plat');
      expect(
        hauteurs.values.every((n) => n == 3),
        isTrue,
        reason: 'trois cases par ligne, comme la navigation de reference',
      );
    });

    testWidgets('l icone est GROSSE (28 px, parite GR20) et non plus 14', (
      tester,
    ) async {
      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      for (final icone in [
        StepwaysIcons.distance,
        StepwaysIcons.pas,
        StepwaysIcons.vitesse,
        StepwaysIcons.denivelePlus,
        StepwaysIcons.deniveleMoins,
        StepwaysIcons.sommet,
      ]) {
        final widget = tester.widget<StepIcon>(
          find.byWidgetPredicate((w) => w is StepIcon && w.asset == icone),
        );
        expect(widget.size, 28.0, reason: 'grosse icone, lisible en marchant');
      }
    });

    testWidgets('chaque case est CENTREE et occupe le tiers de la largeur', (
      tester,
    ) async {
      await tester.pumpWidget(bar());
      await tester.pumpAndSettle();

      // Les trois cases d'une ligne se partagent la largeur a egalite : leurs
      // centres sont equidistants. C'est ce qui donne la disposition centree de
      // la reference, et ce qu'un Wrap « spaceBetween » ne garantissait pas.
      final centres = [
        tester.getCenter(find.text(t.tracking.total)).dx,
        tester.getCenter(find.text(t.tracking.covered)).dx,
        tester.getCenter(find.text(t.tracking.avgSpeed)).dx,
      ];
      final ecart1 = centres[1] - centres[0];
      final ecart2 = centres[2] - centres[1];
      expect(ecart1, greaterThan(0));
      expect(ecart2, closeTo(ecart1, 1.0));
    });

    testWidgets('AUCUNE phrase d explication des tirets sous les chiffres', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StageProgressBar(
              stageName: 'Etape 1',
              distanceRemainingKm: 12,
              progressRatio: 0,
              isOffTrack: false,
              totalDistanceKm: 120.5,
              elevationGainM: 800,
              elevationLossM: 600,
              showPendingValues: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // L acquis du lot 554 tient : les cases absentes portent un TIRET, jamais
      // un zero. Mais plus personne n explique le tiret : il se comprend seul.
      expect(find.text(StageProgressBar.pendingValueLabel), findsNWidgets(3));
      expect(find.text('0.0 km'), findsNothing);
      expect(find.text('0.0 km/h'), findsNothing);
      expect(find.textContaining('tiret'), findsNothing);
    });
  });
}

/// Lit un fichier de `lib/` ET les bibliotheques du MEME dossier qu'il importe
/// ou re-exporte, de proche en proche, dans l ordre des directives.
///
/// LOT 645-06b : les plus gros fichiers de `lib/` ne sont plus des `part`
/// (regle 12) mais de vraies bibliotheques voisines, chacune avec ses imports.
/// Le code mesure ici est le meme, au caractere pres — il vit juste dans
/// plusieurs fichiers du meme dossier. On les recolle donc, l ecran d abord,
/// ce qui preserve l ordre des lignes a l interieur de chaque fichier, dont
/// dependent les mesures de position. Seule la LECTURE change ; aucune attente
/// de ces tests n a ete touchee.
String _sourceAvecSesVoisines(String chemin) {
  final dossier = chemin.substring(0, chemin.lastIndexOf('/'));
  final lus = <String>[];
  void lire(String fichier) {
    if (lus.contains(fichier)) return;
    lus.add(fichier);
    final source = File(fichier).readAsStringSync();
    final voisines =
        RegExp(r"^(?:import|export) '([a-z0-9_]+\.dart)'", multiLine: true)
            .allMatches(source)
            .map((m) => '$dossier/${m.group(1)}')
            .where(
              (n) => !n.endsWith('.g.dart') && !n.endsWith('.freezed.dart'),
            );
    for (final n in voisines) {
      lire(n);
    }
  }

  lire(chemin);
  return [for (final f in lus) File(f).readAsStringSync()].join('\n');
}
