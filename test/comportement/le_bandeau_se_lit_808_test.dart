// LES GARDES DE LA TACHE 808, CHANTIERS « L INVERSION » ET « LA LISIBILITE »
// (items 2 et 5 de Christophe, testes le 10/10 EN MODE DEMO).
//
// ITEM 2, verbatim : « dans navigation total et restant devraient etre
// inverse . Passer total avec le titre ca bouge pas et mettre ce qui bouge
// dans ke tableau en dessous (pour sentier et etape) ».
//
// ITEM 5, verbatim : « tu reverifiera les font, on est en mode navigation
// tout doit etre bien lisible ».
//
// CE QUE LE RELEVE A TROUVE, ET QUI CONTREDIT A MOITIE LE SOUPCON. Les huit
// textes du bandeau ont ete mesures sur la capture de Christophe
// (802_etape_accentuee.png, 1080x2400, rapport de pixels 2,75, soit 393
// points de large) ET sur les jetons du theme. Sept passaient deja le seuil
// AA de 4,5 — y compris les libelles gris accuses, a 7,69:1. UN SEUL
// echouait : la puce « Hors trace », 3,08:1, c est-a-dire l avertissement le
// plus important de l ecran.
//
// LE VRAI DEFAUT ETAIT LA HIERARCHIE, PAS LE CONTRASTE : le titre d etape,
// la ligne qui dit OU L ON EST, etait le plus petit texte lisible du bandeau
// (14 points) sous des libelles secondaires a 16. Ces gardes tiennent les
// deux bouts — le releve chiffre, et l ordre des tailles.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/a11y/wcag_contrast.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/map/widgets/chiffres_de_la_barre.dart';
import 'package:moteur_gr/features/map/widgets/entete_de_la_barre.dart';
import 'package:moteur_gr/features/map/widgets/stage_progress_bar.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

void main() {
  /// La surface du bandeau, mesuree au pixel sur la capture de Christophe :
  /// RGB(30,30,30), soit exactement `colorScheme.surface` du theme sombre.
  const fondDuBandeau = Color(0xFF1E1E1E);

  /// Le vert du sentier tel qu il sort du theme sur la capture (#77CD7B).
  const vertDuSentier = Color(0xFF77CD7B);

  /// Compose [teinte] a 30/255 sur [fond] — la recette des pastilles.
  Color surLaPastille(Color teinte, Color fond) =>
      Color.alphaBlend(teinte.withAlpha(30), fond);

  Widget barre({
    required bool vueSentier,
    String nom = 'Quasquara - Santa-Maria-Siche',
    bool isOffTrack = false,
    Size taille = const Size(393, 844),
  }) => MaterialApp(
    theme: AppTheme.buildDarkTheme(
      primaryColor: const Color(0xFF2E7D32),
      secondaryColor: const Color(0xFF8D6E63),
      skin: AppSkin.sentierVivant,
    ),
    home: MediaQuery(
      data: MediaQueryData(size: taille),
      child: Scaffold(
        body: Align(
          alignment: Alignment.bottomCenter,
          child: StageProgressBar(
            stageName: nom,
            distanceRemainingKm: 7.7,
            progressRatio: 0.05,
            isOffTrack: isOffTrack,
            totalDistanceKm: 8.1,
            distanceCoveredKm: 0.4,
            elevationGainM: 17,
            elevationLossM: 6,
            avgSpeedKmh: 4,
            altitudeM: vueSentier ? null : 782,
            etapesFaites: vueSentier ? 3 : null,
            etapesTotal: vueSentier ? 7 : null,
            vueSentier: vueSentier,
            perimetreLabel: vueSentier
                ? t.map.perimetreSentier
                : t.map.perimetreEtape,
          ),
        ),
      ),
    ),
  );

  group('CE QUI NE BOUGE PAS MONTE AU TITRE (item 2)', () {
    testWidgets('LE TOTAL EST DANS LA PASTILLE DU TITRE, en vue etape comme '
        'en vue sentier', (tester) async {
      for (final vueSentier in [false, true]) {
        await tester.pumpWidget(barre(vueSentier: vueSentier));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(PastilleDuPerimetre),
            matching: find.text('8,1 km'),
          ),
          findsOneWidget,
          reason: 'vueSentier=$vueSentier : « Passer total avec le titre »',
        );
        // Et il n est plus nulle part ailleurs : pas deux totaux a l ecran.
        expect(find.text('8,1 km'), findsOneWidget);
        expect(find.text(t.tracking.total), findsNothing);
      }
    });

    testWidgets('LE RESTANT EST UNE CASE DU TABLEAU, en vue etape comme en '
        'vue sentier', (tester) async {
      for (final vueSentier in [false, true]) {
        await tester.pumpWidget(barre(vueSentier: vueSentier));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byType(ChiffresDeLaBarre),
            matching: find.text(t.tracking.remaining),
          ),
          findsOneWidget,
          reason: 'vueSentier=$vueSentier : « ce qui bouge dans le tableau »',
        );
        expect(find.text('7,7 km'), findsOneWidget);
        // La ligne grise qu il occupait n existe plus du tout.
        expect(find.text(t.map.stageRemaining(km: '7.7')), findsNothing);
      }
    });
  });

  group('LE RELEVE DE CONTRASTE DU BANDEAU (item 5)', () {
    test('les huit textes du bandeau passent le seuil AA, puce hors-trace '
        'comprise', () {
      // AVANT / APRES, chiffre. Les valeurs « avant » sont celles mesurees sur
      // la capture du 10/10 ; elles sont rappelees pour que la garde dise
      // d ou l on vient, pas seulement ou l on est.
      final releve = <String, (Color, Color, double)>{
        // texte                      couleur            fond            seuil
        'titre d etape': (AppTheme.grisClair, fondDuBandeau, 4.5),
        'pastille du perimetre': (
          vertDuSentier,
          surLaPastille(vertDuSentier, fondDuBandeau),
          4.5,
        ),
        // AVANT : emergencyRed sur emergencyRed a 30/255 => 3,08:1, ECHEC.
        // APRES : blanc sur rouge plein.
        'puce hors trace': (Colors.white, AppTheme.emergencyRed, 4.5),
        'pourcentage': (vertDuSentier, fondDuBandeau, 4.5),
        // Les valeurs sont du grand texte (20 pt gras) : seuil 3,0.
        'valeurs du tableau': (const Color(0xFFF5F5F5), fondDuBandeau, 3.0),
        // AVANT : grisTexteSecondaire => 7,69:1. APRES : grisClair.
        'libelles du tableau': (AppTheme.grisClair, fondDuBandeau, 4.5),
        'bouton de bascule': (vertDuSentier, fondDuBandeau, 4.5),
      };

      final echecs = <String>[];
      releve.forEach((nom, trio) {
        final (devant, derriere, seuil) = trio;
        final ratio = WcagContrast.ratio(devant, derriere);
        if (ratio < seuil) {
          echecs.add('$nom : ${ratio.toStringAsFixed(2)}:1 < $seuil');
        }
      });

      expect(
        echecs,
        isEmpty,
        reason:
            'le bandeau se lit dehors, bras tendu, en plein soleil : aucun '
            'de ses textes ne descend sous son seuil',
      );
    });

    test(
      'la puce hors-trace a bien ete REPAREE : l ancienne recette echouait',
      () {
        // La garde qui dit pourquoi on a touche a cette puce. Si quelqu un
        // revenait au rouge teinte, il retomberait sous le seuil.
        final ancien = WcagContrast.ratio(
          AppTheme.emergencyRed,
          surLaPastille(AppTheme.emergencyRed, fondDuBandeau),
        );
        final nouveau = WcagContrast.ratio(Colors.white, AppTheme.emergencyRed);
        expect(ancien, lessThan(4.5), reason: 'mesure du defaut : 3,08:1');
        expect(nouveau, greaterThanOrEqualTo(4.5));
        expect(nouveau, greaterThan(ancien));
      },
    );

    testWidgets('LE TITRE N EST PLUS LE PLUS PETIT TEXTE DU BANDEAU', (
      tester,
    ) async {
      await tester.pumpWidget(barre(vueSentier: false));
      await tester.pumpAndSettle();

      double taille(Finder f) => tester.widget<Text>(f).style!.fontSize!;

      final titre = taille(find.text('Quasquara - Santa-Maria-Siche'));
      final libelle = taille(find.text(t.tracking.remaining));
      final pastille = taille(
        find.descendant(
          of: find.byType(PastilleDuPerimetre),
          matching: find.text(t.map.perimetreEtape),
        ),
      );

      // AVANT la tache 808 : titre 14, libelle 16, pastille 11 — la ligne la
      // plus importante etait plus petite que les libelles.
      expect(
        titre,
        greaterThanOrEqualTo(libelle),
        reason: 'le nom de l etape ne se lit plus moins bien que « Restant »',
      );
      expect(titre, greaterThanOrEqualTo(14.0), reason: 'plancher de recul');
      expect(pastille, greaterThanOrEqualTo(14.0), reason: 'etait a 11');
    });
  });

  group('LE BANDEAU TIENT SOUS 390 POINTS (item 5, contrainte de la demo)', () {
    testWidgets('rien ne deborde, meme avec la puce hors-trace en plus', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        barre(
          vueSentier: false,
          isOffTrack: true,
          taille: const Size(390, 844),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.takeException(),
        isNull,
        reason: 'aucun debordement de rangee a 390 points de large',
      );
      // HORS TRACE, LE TOTAL CEDE LA PLACE — arbitrage assume : sur 360
      // points, le nom du lieu et l avertissement priment sur une longueur
      // d etape qui ne bouge pas.
      expect(
        find.text('8,1 km'),
        findsNothing,
        reason: 'le total s efface tant que le marcheur est hors trace',
      );
      expect(find.text(t.map.offTrackChip), findsOneWidget);
      // Le nom tient encore, et les six libelles sont tous la.
      expect(find.text('Quasquara - Santa-Maria-Siche'), findsOneWidget);
      for (final libelle in [
        t.tracking.remaining,
        t.tracking.covered,
        t.tracking.avgSpeed,
        t.tracking.dPlus,
        t.tracking.dMinus,
        t.tracking.altitude,
      ]) {
        expect(find.text(libelle), findsOneWidget);
      }
    });

    // UNE LIGNE DE TEXTE EN MOINS, ET C EST CE QUI REND LA PLACE A LA CARTE.
    //
    // POURQUOI CETTE GARDE NE MESURE PAS UNE HAUTEUR EN POINTS. Au banc,
    // Flutter remplace la police du projet par une police d essai dont CHAQUE
    // glyphe occupe un cadratin : « 7.7 km » y fait 120 points de large la ou
    // Montserrat en demande 62, les valeurs se replient sur deux lignes et le
    // bandeau mesure 340 points au lieu des 305 mesures au pixel sur la
    // capture de Christophe (1080x2400, rapport 2,75). Un seuil en points
    // mesurerait donc le banc, pas l application — et il mentirait dans les
    // deux sens.
    //
    // CE QUI SE MESURE SANS POLICE, EN REVANCHE, C EST LA STRUCTURE : le
    // pourcentage partage desormais sa ligne avec la barre qu il legende, au
    // lieu d occuper une ligne a lui avec le restant. C est exactement
    // l interligne rendu a la carte, et aucune police ne peut le simuler.
    testWidgets('le pourcentage partage la ligne de la barre : une ligne de '
        'texte rendue a la carte', (tester) async {
      await tester.pumpWidget(barre(vueSentier: false));
      await tester.pumpAndSettle();

      final barreDeProgression = tester.getRect(
        find.byType(LinearProgressIndicator),
      );
      final pourcentage = tester.getRect(find.text('5%'));

      expect(
        pourcentage.center.dy,
        greaterThanOrEqualTo(barreDeProgression.top - 24),
        reason: 'le pourcentage n est plus sur une ligne a lui en dessous',
      );
      expect(
        pourcentage.center.dy,
        lessThanOrEqualTo(barreDeProgression.bottom + 24),
      );
      expect(
        pourcentage.left,
        greaterThan(barreDeProgression.right - 1),
        reason: 'il est A DROITE de la barre, sur la meme ligne',
      );
    });
  });
}
