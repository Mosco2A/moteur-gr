import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/hub/presentation/widgets/quick_access_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/texte_ajuste.dart';

/// TACHE 634 — RETOUR 6 DE CHRISTOPHE (DEM-260929-1325).
///
/// Verbatim : « ravitaillement est ecrit sur 2 lignes ».
///
/// CE QUE CES TESTS PROUVENT. Que plus AUCUN libelle de tuile du cockpit n'est
/// coupe en plein mot, dans les CINQ langues et sur les trois largeurs de
/// telephone que le depot teste deja (360 / 390 / 412 px logiques).
///
/// POURQUOI LES TESTS D'AVANT NE VOYAIENT RIEN. Le depot a trois dispositifs
/// anti-debordement (hub_screen_test, persona_l_oeil_573, weather_overflow) et
/// ils etaient tous VERTS avec le defaut. Deux raisons, toutes deux verifiees :
/// un `Text` a deux lignes qui casse un mot ne leve AUCUNE exception Flutter,
/// et ces tests tournent tous en francais. Le present fichier ne cherche donc
/// pas une exception : il MESURE le texte, langue par langue.
void main() {
  // LA VRAIE POLICE EST CHARGEE, SANS QUOI CE FICHIER NE MESURERAIT RIEN.
  //
  // `flutter test` remplace toutes les polices par une police d'essai dont
  // CHAQUE glyphe est un carre d'un cadratin : « i » y est aussi large que
  // « W ». Un test de largeur de texte joue dessus mesure donc une police qui
  // n'existe sur aucun telephone. On charge ici les trois graisses de
  // Montserrat livrees dans le paquet (pubspec.yaml, assets/fonts), pour que
  // les chiffres de ce fichier soient ceux de l'ecran de Christophe.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final chargeur = FontLoader('Montserrat');
    for (final fichier in [
      'assets/fonts/Montserrat-Regular.ttf',
      'assets/fonts/Montserrat-SemiBold.ttf',
      'assets/fonts/Montserrat-Bold.ttf',
    ]) {
      chargeur.addFont(
        File(fichier).readAsBytes().then((o) => ByteData.view(o.buffer)),
      );
    }
    await chargeur.load();
  });

  /// Les trois largeurs de texte reellement disponibles dans une tuile.
  ///
  /// Calcul (hub_section.dart : grille 2 colonnes, crossAxisSpacing 12 ;
  /// hub_screen.dart : ListView padding 16 ; app_card.dart : padding 16) :
  /// (largeurEcran - 32 - 12) / 2 - 32.
  double largeurDeTuile(double largeurEcran) =>
      (largeurEcran - 32 - 12) / 2 - 32;

  const largeursTelephone = [360.0, 390.0, 412.0];

  /// Le theme reel de l'application, celui qui porte Montserrat.
  final themeClair = AppTheme.buildLightTheme(
    primaryColor: const Color(0xFF2E7D32),
    secondaryColor: const Color(0xFF1565C0),
    skin: AppSkin.sentierVivant,
  );

  /// Le style exact du titre d'une tuile : `titleMedium` du theme clair.
  TextStyle styleDuTitre() =>
      themeClair.textTheme.titleMedium ?? const TextStyle(fontSize: 18);

  /// Tous les libelles de tuile du cockpit, dans la langue [langue].
  List<String> libellesDesTuiles(AppLocale langue) {
    final c = langue.buildSync().hub.cards;
    return [
      c.feasibility,
      c.itinerary,
      c.programme,
      c.calendar,
      c.training,
      c.health,
      c.cartes,
      c.nuitees,
      c.transport,
      c.shop,
      c.resume,
      c.checklist,
      c.navigation,
      c.emergency,
      c.signalement,
      c.journal,
      c.adjust,
      c.weather,
      c.fire,
      c.accommodations,
      c.tips,
      c.townGuides,
      c.recap,
      c.importGpx,
      c.diploma,
      c.offline,
      c.group,
    ];
  }

  group('le defaut est bien la avant correction', () {
    test('« Ravitaillement » NE TIENT PAS a 18 px dans une tuile de 360 px', () {
      // La mesure qui explique le retour de Christophe : le mot est plus large
      // que la colonne, donc Flutter le casse — sans rien signaler.
      expect(
        texteTientSansCouperDeMot(
          texte: 'Ravitaillement',
          style: styleDuTitre(),
          largeur: largeurDeTuile(360),
          maxLines: 2,
        ),
        isFalse,
        reason:
            'si ce test devient vrai, le defaut d origine a disparu tout '
            'seul et ce fichier ne prouve plus rien',
      );
    });

    test('un titre de DEUX mots, lui, tenait deja : il se replie', () {
      // « Préparation physique » est plus long en caracteres que
      // « Ravitaillement » et ne posait aucun probleme : c'est la preuve que
      // le defaut tient au MOT INSECABLE, pas a la longueur du libelle.
      expect(
        texteTientSansCouperDeMot(
          texte: 'Préparation physique',
          style: styleDuTitre(),
          largeur: largeurDeTuile(360),
          maxLines: 2,
        ),
        isTrue,
      );
    });
  });

  group('apres correction, aucun libelle de tuile n est coupe', () {
    for (final langue in AppLocale.values) {
      test(
        'en ${langue.languageCode}, les 27 tuiles tiennent aux 3 largeurs',
        () {
          final style = styleDuTitre();
          final coupes = <String>[];

          for (final ecran in largeursTelephone) {
            final largeur = largeurDeTuile(ecran);
            for (final libelle in libellesDesTuiles(langue)) {
              final taille = tailleQuiTient(
                texte: libelle,
                style: style,
                largeur: largeur,
                maxLines: 2,
                tailleMin: 13,
              );
              final tient = texteTientSansCouperDeMot(
                texte: libelle,
                style: style.copyWith(fontSize: taille),
                largeur: largeur,
                maxLines: 2,
              );
              if (!tient) {
                coupes.add(
                  '$libelle (${ecran.toInt()} px, $taille px de police)',
                );
              }
            }
          }

          expect(
            coupes,
            isEmpty,
            reason:
                'libelles encore coupes en ${langue.languageCode} : $coupes',
          );
        },
      );
    }

    test(
      'le seul libelle qui ne tenait PAS meme au plancher a ete remplace',
      () {
        // MESURE. « Zusammenfassung » (15 caracteres insecables) est le seul
        // libelle de tuile des cinq langues qui ne tient pas dans 126 px meme
        // reduit a 13 px, le plancher de lisibilite. Reduire encore aurait rendu
        // la tuile illisible : c'est le cas ou la troisieme piste — un libelle
        // plus court — est la bonne.
        expect(
          texteTientSansCouperDeMot(
            texte: 'Zusammenfassung',
            style: styleDuTitre().copyWith(fontSize: 13),
            largeur: largeurDeTuile(360),
            maxLines: 2,
          ),
          isFalse,
          reason: 'c est la mesure qui a justifie de changer le libelle',
        );

        // ET IL PORTAIT UN SECOND DEFAUT, TROUVE EN CHEMIN : l'allemand donnait
        // le MEME nom a DEUX tuiles differentes — la synthese du plan et le
        // recapitulatif de l'aventure. Leurs sous-titres les distinguaient
        // (« Planubersicht » / « Ihr Abenteuer in Kurze »), pas leurs titres.
        final de = AppLocale.de.buildSync().hub.cards;
        expect(de.resume, isNot(de.recap));
        expect(de.resume, 'Übersicht');
        expect(de.recap, 'Rückblick');
      },
    );

    test('un libelle court garde sa taille d origine — on ne rapetisse pas '
        'toute l interface', () {
      final base = styleDuTitre().fontSize;
      expect(
        tailleQuiTient(
          texte: 'Météo',
          style: styleDuTitre(),
          largeur: largeurDeTuile(360),
          maxLines: 2,
          tailleMin: 13,
        ),
        base,
      );
    });
  });

  group('la tuile rend bien un texte ajuste', () {
    testWidgets('« Ravitaillement » est rendu sur UNE ligne dans la tuile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: themeClair,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: largeurDeTuile(360) + 32, // + le padding de l AppCard
                height: 180,
                child: QuickAccessCard(
                  rubrique: RubriqueStepways.ravitaillement,
                  title: 'Ravitaillement',
                  subtitle: 'Épiceries, pharmacies, gaz',
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final rendu = tester.widget<Text>(
        find.descendant(
          of: find.byType(TexteAjuste),
          matching: find.text('Ravitaillement'),
        ),
      );
      final taille = rendu.style?.fontSize;
      expect(taille, isNotNull);

      // La police a bien ete reduite...
      expect(taille!, lessThan(styleDuTitre().fontSize!));
      // ...juste assez, et pas sous le plancher de lisibilite.
      expect(taille, greaterThanOrEqualTo(13));

      // ...et a cette taille, le mot n'est plus coupe.
      final peintre = TextPainter(
        text: TextSpan(text: 'Ravitaillement', style: rendu.style),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: largeurDeTuile(360));
      expect(peintre.computeLineMetrics().length, 1);
    });
  });
}
