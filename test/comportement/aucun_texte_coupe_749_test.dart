import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/branding/stepways_icons.dart';
import 'package:moteur_gr/core/theme/app_skin.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/contextual_action_bar.dart';
import 'package:moteur_gr/shared/widgets/hub_section.dart';
import 'package:moteur_gr/shared/widgets/mesure_de_texte.dart';
import 'package:moteur_gr/shared/widgets/quick_access_card.dart';
import 'package:moteur_gr/shared/widgets/step_status_icon.dart';
import 'package:moteur_gr/shared/widgets/texte_ajuste.dart';

/// TACHE 749 — AUCUN TEXTE N'EST COUPE.
///
/// LE DEFAUT. Christophe l'a remonte le 07/10 puis redit le 09/10, et il l'a
/// releve mot pour mot a l'ecran : « Évaluez votre niv… », « Le déroulé de
/// vo… », « Répartissez vos … », « Télécharger les c… », « Réserver vos
/// nui… », « Préparez votre s… », « Découvrir de… ». Sept captures, deux
/// causes, et aucune des deux n'est de la redaction — il l'a cadre lui-meme le
/// 09/10 09:56 : « Aucun rapport entre les tronqué et les trop bavard ».
///
/// LA REGLE QUE CE FICHIER GARDE. Un texte passe a la ligne, et son conteneur
/// grandit ; a defaut il rapetisse pour tenir ENTIER ; a defaut son conteneur
/// defile, et le defilement se voit. `TextOverflow.ellipsis` n'est plus un
/// moyen de mise en page : c'est un filet mort, sous l'une de ces trois
/// garanties.
///
/// POURQUOI CE FICHIER MESURE AU LIEU D'ATTENDRE UNE EXCEPTION. Le depot
/// portait DEJA plusieurs bancs anti-debordement, et ils etaient tous verts
/// avec le defaut sous les yeux : un `Text` qui s'arrete sur des points de
/// suspension est un `Text` parfaitement heureux, il ne leve rien. La seule
/// facon de voir une troncature est de mesurer le texte et de demander s'il
/// tenait. C'est la lecon de la tache 634, et ce fichier la reprend.
void main() {
  // LA VRAIE POLICE EST CHARGEE, SANS QUOI CE FICHIER NE MESURERAIT RIEN.
  //
  // `flutter test` remplace toutes les polices par une police d'essai dont
  // chaque glyphe est un carre d'un cadratin : « i » y est aussi large que
  // « W ». On charge Montserrat, la police reelle du paquet, pour que les
  // chiffres de ce fichier soient ceux de l'ecran de Christophe.
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

  /// Le theme reel de l'application, celui qui porte Montserrat.
  final themeClair = AppTheme.buildLightTheme(
    primaryColor: const Color(0xFF2E7D32),
    secondaryColor: const Color(0xFF1565C0),
    skin: AppSkin.sentierVivant,
  );

  TextStyle styleDuTitre() =>
      themeClair.textTheme.titleMedium ?? const TextStyle(fontSize: 18);
  TextStyle styleDuSousTitre() =>
      themeClair.textTheme.bodySmall ?? const TextStyle(fontSize: 12);

  /// Les largeurs de telephone que le depot teste deja, plus une etroite.
  ///
  /// 320 px est le plus petit telephone encore vendu ; c'est la largeur ou une
  /// tuile qui passe a deux lignes risque de deborder EN HAUTEUR, et c'est donc
  /// celle qui compte le plus pour ce lot.
  const largeursTelephone = [320.0, 360.0, 390.0, 412.0];

  /// La largeur d'une CELLULE de la grille du cockpit.
  ///
  /// `hub_screen` pose un `ListView` a padding 16, la grille a deux colonnes
  /// separees de 12 : (largeurEcran - 32 - 12) / 2.
  double largeurDeCellule(double largeurEcran) => (largeurEcran - 32 - 12) / 2;

  /// La largeur offerte au TEXTE dans la cellule : la carte porte 16 de padding
  /// de chaque cote.
  double largeurDeTexte(double largeurEcran) =>
      largeurDeCellule(largeurEcran) - 32;

  /// Les 27 sous-titres de tuile du cockpit, dans la langue [langue].
  ///
  /// Ce sont eux que Christophe a vus coupes : les six premiers de cette liste
  /// sont, mot pour mot, six de ses sept captures.
  List<String> sousTitresDesTuiles(AppLocale langue) {
    final c = langue.buildSync().hub.cards;
    return [
      c.feasibilitySub,
      c.itinerarySub,
      c.programmeSub,
      c.cartesSub,
      c.nuiteesSub,
      c.checklistSub,
      c.calendarSub,
      c.trainingSub,
      c.healthSub,
      c.transportSub,
      c.shopSub,
      c.resumeSub,
      c.navigationSub,
      c.emergencySub,
      c.signalementSub,
      c.journalSub,
      c.adjustSub,
      c.weatherSub,
      c.fireSub,
      c.accommodationsSub,
      c.tipsSub,
      c.townGuidesSub,
      c.recapSub,
      c.importGpxSub,
      c.diplomaSub,
      c.offlineSub,
      c.groupSub,
    ];
  }

  List<String> titresDesTuiles(AppLocale langue) {
    final c = langue.buildSync().hub.cards;
    return [
      c.feasibility,
      c.itinerary,
      c.programme,
      c.cartes,
      c.nuitees,
      c.checklist,
      c.calendar,
      c.training,
      c.health,
      c.transport,
      c.shop,
      c.resume,
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

  /// La hauteur mesuree d'une tuile, pour les textes de [langue].
  double hauteurMesuree(AppLocale langue, double largeurEcran) {
    final titres = titresDesTuiles(langue);
    final sousTitres = sousTitresDesTuiles(langue);
    return hauteurDeTuileRequise(
      tuiles: [
        for (var i = 0; i < titres.length; i++)
          (titre: titres[i], sousTitre: sousTitres[i], avecCoche: true),
      ],
      largeurCellule: largeurDeCellule(largeurEcran),
      styleTitre: styleDuTitre(),
      styleSousTitre: styleDuSousTitre(),
    );
  }

  // ===========================================================================
  group('le defaut etait bien la, et il etait mesurable', () {
    // ---------------------------------------------------------------------
    test('le budget fixe de 180 px NE SUFFISAIT PAS aux sous-titres que '
        'Christophe a vus coupes', () {
      // Reconstitution de l'ancienne tuile : padding 32 + pastille 36 +
      // espace 8 + titre 2 lignes + espace 4 + coche 4+18. Ce qui restait au
      // sous-titre dans 180 px, et ce qu'il lui aurait fallu.
      final largeur = largeurDeTexte(360);
      final hauteurDeLigneDuTitre = hauteurDesTextes(
        blocs: [(texte: 'M', style: styleDuTitre(), maxLignes: 1)],
        largeurTexte: largeur,
      );
      final placeRestante =
          180 - (32 + 36 + 8 + hauteurDeLigneDuTitre * 2 + 4 + 4 + 18);

      final sousTitresCoupes = <String>[];
      for (final sousTitre in sousTitresDesTuiles(AppLocale.fr)) {
        final hauteurVoulue = hauteurDesTextes(
          blocs: [
            (texte: sousTitre, style: styleDuSousTitre(), maxLignes: null),
          ],
          largeurTexte: largeur,
        );
        if (hauteurVoulue > placeRestante) sousTitresCoupes.add(sousTitre);
      }

      // Si cette liste etait vide, le defaut n'aurait jamais existe — et ce
      // fichier ne garderait rien.
      expect(
        sousTitresCoupes,
        isNotEmpty,
        reason:
            'le budget de 180 px laissait ${placeRestante.toStringAsFixed(1)} '
            'px au sous-titre : des sous-titres DEVAIENT etre coupes',
      );
    });

    // ---------------------------------------------------------------------
    test('la hauteur mesuree est bien PLUS GRANDE que l ancien budget', () {
      // C'est le coeur du correctif : on ne coupe plus parce qu'on reserve ce
      // qu'il faut. A 320 px — le pire cas — la tuile doit depasser 180.
      expect(
        hauteurMesuree(AppLocale.fr, 320),
        greaterThan(hauteurMinimaleDeTuile),
        reason:
            'a 320 px les sous-titres reclament plus que les 180 px '
            'd avant, sinon rien n a change',
      );
    });

    // ---------------------------------------------------------------------
    test('la hauteur ne descend JAMAIS sous l ancienne', () {
      // Le plancher protege l'allure du cockpit : la ou le texte tenait deja,
      // Christophe doit retrouver exactement ce qu'il connait.
      for (final largeur in largeursTelephone) {
        for (final langue in AppLocale.values) {
          expect(
            hauteurMesuree(langue, largeur),
            greaterThanOrEqualTo(hauteurMinimaleDeTuile),
            reason: 'en ${langue.languageCode} a $largeur px',
          );
        }
      }
    });
  });

  // ===========================================================================
  group('apres correction, aucun texte de tuile n est coupe', () {
    // CE QUE CES CAS PROUVENT, ET POURQUOI ILS MONTENT LE VRAI WIDGET. Mesurer
    // la fonction de hauteur ne prouverait rien d interessant : elle rend le
    // maximum de ce que les tuiles reclament, donc elle est d accord avec
    // elle-meme par construction. Ces cas montent donc une section de cockpit
    // COMPLETE — les 27 tuiles, avec leur coche — puis ils interrogent CHAQUE
    // paragraphe de l arbre rendu : `didExceedMaxLines` dit si Flutter a du
    // couper. C est la question exacte que Christophe pose en regardant son
    // ecran, posee au moteur de rendu.
    for (final langue in AppLocale.values) {
      for (final largeurEcran in largeursTelephone) {
        testWidgets(
          'en ${langue.languageCode} a ${largeurEcran.toInt()} px, les 27 '
          'tuiles s ecrivent en entier',
          (tester) async {
            tester.view.physicalSize = Size(largeurEcran, 2400);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            final titres = titresDesTuiles(langue);
            final sousTitres = sousTitresDesTuiles(langue);

            await tester.pumpWidget(
              MaterialApp(
                theme: themeClair,
                home: Scaffold(
                  body: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      HubSection(
                        title: langue.buildSync().hub.sections.prepare,
                        rubrique: RubriqueStepways.faisabilite,
                        cards: [
                          for (var i = 0; i < titres.length; i++)
                            QuickAccessCard(
                              rubrique: RubriqueStepways.faisabilite,
                              title: titres[i],
                              subtitle: sousTitres[i],
                              stepStatus: PlanningStepStatus.inProgress,
                              onTap: () {},
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);

            final coupes = tester.allRenderObjects
                .whereType<RenderParagraph>()
                .where((p) => p.didExceedMaxLines)
                .map((p) => p.text.toPlainText())
                .toList();
            expect(
              coupes,
              isEmpty,
              reason:
                  'textes coupes en ${langue.languageCode} a '
                  '${largeurEcran.toInt()} px : $coupes',
            );
          },
        );
      }
    }
  });

  // ===========================================================================
  group('les libelles de la barre du bas tiennent ENTIERS', () {
    // « Découvrir de… » etait le premier onglet de la barre du bas. Un onglet
    // n'a pas la place de deux lignes de paragraphe : la barre a ete rehaussee
    // pour en accorder deux, et [TexteAjuste] rapetisse la police si deux
    // lignes ne suffisent pas. Ce qu'on garde ici, c'est qu'au bout du compte
    // le libelle s'ecrit en entier.
    for (final langue in AppLocale.values) {
      test(
        'en ${langue.languageCode}, les trois onglets s ecrivent en entier',
        () {
          final t = langue.buildSync();
          final libelles = [
            t.myTreks.discoverTitle,
            t.myTreks.accountTitle,
            t.nav.settings,
          ];
          // Trois onglets se partagent la largeur du plus petit telephone,
          // moins le padding de la barre (8 de chaque cote) et celui du
          // bouton (4).
          const largeurDUnOnglet = (320 - 16) / 3 - 8;
          final style =
              themeClair.textTheme.labelLarge ?? const TextStyle(fontSize: 14);

          for (final libelle in libelles) {
            final taille = tailleQuiTient(
              texte: libelle,
              style: style,
              largeur: largeurDUnOnglet,
              maxLines: 2,
              tailleMin: 11,
            );
            expect(
              texteTientSansCouperDeMot(
                texte: libelle,
                style: style.copyWith(fontSize: taille),
                largeur: largeurDUnOnglet,
                maxLines: 2,
              ),
              isTrue,
              reason:
                  '« $libelle » ne tient pas entier sur deux lignes dans '
                  '${largeurDUnOnglet.toStringAsFixed(1)} px, meme rapetisse',
            );
          }
        },
      );
    }

    // ---------------------------------------------------------------------
    testWidgets('la barre reserve la hauteur de deux lignes de libelle', (
      tester,
    ) async {
      late double hauteur;
      await tester.pumpWidget(
        MaterialApp(
          theme: themeClair,
          home: Builder(
            builder: (context) {
              hauteur = ContextualActionBar.hauteurPour(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // Icone 22 + espace 4 + deux lignes de labelLarge + marges 16.
      final style =
          themeClair.textTheme.labelLarge ?? const TextStyle(fontSize: 14);
      final deuxLignes = (style.fontSize ?? 14) * (style.height ?? 1.43) * 2;
      expect(hauteur, greaterThanOrEqualTo(22 + 4 + deuxLignes + 16));
    });

    // ---------------------------------------------------------------------
    for (final largeur in [320.0, 360.0]) {
      for (final avecSos in [false, true]) {
        testWidgets('la vraie barre a ${largeur.toInt()} px'
            '${avecSos ? ' avec le SOS' : ''} n ecrete aucun libelle', (
          tester,
        ) async {
          tester.view.physicalSize = Size(largeur, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.reset);

          final t = AppLocale.fr.buildSync();
          await tester.pumpWidget(
            MaterialApp(
              theme: themeClair,
              home: Scaffold(
                bottomNavigationBar: ContextualActionBar(
                  actions: [
                    ContextualAction(
                      icon: StepwaysIcons.sommet,
                      label: t.myTreks.discoverTitle,
                      onPressed: () {},
                    ),
                    ContextualAction(
                      icon: StepwaysIcons.sommet,
                      label: t.myTreks.accountTitle,
                      onPressed: () {},
                    ),
                    if (avecSos)
                      // Le SOS est rendu en pastille pleine : un `Padding` de
                      // plus, donc le plus haut des enfants de la barre.
                      ContextualAction(
                        icon: StepwaysIcons.danger,
                        label: t.navPilote.sos,
                        onPressed: () {},
                        salient: true,
                      )
                    else
                      ContextualAction(
                        icon: StepwaysIcons.sommet,
                        label: t.nav.settings,
                        onPressed: () {},
                      ),
                  ],
                ),
                body: const SizedBox.shrink(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final coupes = tester.allRenderObjects
              .whereType<RenderParagraph>()
              .where((p) => p.didExceedMaxLines)
              .map((p) => p.text.toPlainText())
              .toList();
          expect(
            coupes,
            isEmpty,
            reason:
                'libelles d onglet coupes a ${largeur.toInt()} px : $coupes',
          );
        });
      }
    }
  });

  // ===========================================================================
  group('aux largeurs etroites, rien ne deborde en hauteur', () {
    // C'est le risque propre a ce lot : une tuile qui passe a deux ou trois
    // lignes peut deborder EN HAUTEUR si la cellule ne suit pas. Ces cas
    // montent une vraie section de cockpit et echouent sur la moindre
    // exception de mise en page.
    for (final largeur in largeursTelephone) {
      for (final echelle in [1.0, 1.3]) {
        testWidgets(
          'section de cockpit a ${largeur.toInt()} px, textes x$echelle',
          (tester) async {
            tester.view.physicalSize = Size(largeur, 900);
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            final t = AppLocale.fr.buildSync();
            await tester.pumpWidget(
              MaterialApp(
                theme: themeClair,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: Size(largeur, 900),
                    textScaler: TextScaler.linear(echelle),
                  ),
                  child: Scaffold(
                    body: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        HubSection(
                          title: t.hub.sections.prepare,
                          rubrique: RubriqueStepways.faisabilite,
                          cards: [
                            for (var i = 0; i < 6; i++)
                              QuickAccessCard(
                                rubrique: RubriqueStepways.faisabilite,
                                title: titresDesTuiles(AppLocale.fr)[i],
                                subtitle: sousTitresDesTuiles(AppLocale.fr)[i],
                                stepStatus: PlanningStepStatus.inProgress,
                                onTap: () {},
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });

  // ===========================================================================
  group('la garde structurelle : la troncature ne revient pas', () {
    // CE QUE CETTE GARDE FAIT, ET POURQUOI ELLE LIT LE CODE SOURCE. Les cas
    // ci-dessus mesurent les textes d'AUJOURD'HUI. Ils ne diront rien d'un
    // `maxLines: 1` repose demain sur une tuile, par reflexe, pour « faire
    // propre ». Cette garde-la lit les fichiers que le lot 749 a traites et
    // refuse qu'un plafond de lignes ou des points de suspension y
    // reapparaissent.
    //
    // CE N'EST PAS UNE INTERDICTION GENERALE de `TextOverflow.ellipsis` : le
    // depot en garde a bon droit (une valeur numerique a chasse fixe, le filet
    // mort de [TexteAjuste]...). La garde ne porte que sur les endroits
    // TRAITES, ou la coupure etait le defaut.
    const fichiersTraites = [
      'lib/shared/widgets/quick_access_card.dart',
      'lib/shared/widgets/hub_section.dart',
      'lib/features/map/widgets/poi_popup.dart',
      'lib/features/hub/presentation/widgets/hub_trek_card.dart',
      'lib/features/hub/presentation/widgets/hub_weather_card.dart',
      'lib/features/hub/presentation/widgets/collapsible_prepare_section.dart',
      'lib/features/hub/presentation/widgets/localized_conditions_banner.dart',
      'lib/features/trail/widgets/stage_list_tile.dart',
      'lib/features/trail/widgets/poi_tile.dart',
      'lib/features/trail/presentation/trail_catalog_screen.dart',
      'lib/features/treks/presentation/widgets/trek_summary_card.dart',
      'lib/features/weather/widgets/all_stages_weather_list.dart',
      'lib/features/weather/widgets/program_weather_list.dart',
      'lib/features/weather/widgets/today_stage_weather_card.dart',
      'lib/features/weather/presentation/fire_risk_screen.dart',
      'lib/features/map/widgets/stage_poi_checklist.dart',
      'lib/features/checklist/widgets/checklist_item_widget.dart',
      'lib/features/checklist/widgets/checklist_preparation_section.dart',
      'lib/features/checklist/widgets/checklist_weight_banner.dart',
      'lib/features/booking/presentation/nuitees_screen.dart',
      'lib/features/booking/presentation/widgets/nuitee_card_parts.dart',
      'lib/features/trek/presentation/planning/itinerary_screen.dart',
      'lib/features/after/presentation/gpx_import_screen.dart',
      'lib/features/leaderboard/presentation/leaderboard_screen.dart',
      'lib/features/gamification/presentation/defi_screen.dart',
    ];

    // ---------------------------------------------------------------------
    test('aucun fichier traite ne reintroduit de points de suspension', () {
      final fautifs = <String>[];
      for (final chemin in fichiersTraites) {
        final fichier = File(chemin);
        expect(
          fichier.existsSync(),
          isTrue,
          reason: '$chemin a disparu : la garde ne garde plus rien',
        );
        final lignes = fichier.readAsLinesSync();
        for (var i = 0; i < lignes.length; i++) {
          final ligne = lignes[i];
          if (ligne.trimLeft().startsWith('//')) continue;
          if (ligne.contains('TextOverflow.ellipsis') ||
              ligne.contains('TextOverflow.clip') ||
              ligne.contains('TextOverflow.fade')) {
            fautifs.add('$chemin:${i + 1}');
          }
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'la regle du lot 749 est qu un texte passe a la ligne, rapetisse '
            'ou defile — jamais qu il se coupe. Points de suspension revenus '
            'ici : $fautifs',
      );
    });

    // ---------------------------------------------------------------------
    test('aucun fichier traite ne reintroduit de plafond de lignes', () {
      final fautifs = <String>[];
      // Le plafond LEGITIME : celui que [TexteAjuste] recoit en parametre,
      // parce qu'il garantit par ailleurs que le texte tient entier dedans.
      final plafond = RegExp(r'maxLines:\s*[0-9]');
      for (final chemin in fichiersTraites) {
        final lignes = File(chemin).readAsLinesSync();
        for (var i = 0; i < lignes.length; i++) {
          final ligne = lignes[i];
          if (ligne.trimLeft().startsWith('//')) continue;
          if (!plafond.hasMatch(ligne)) continue;
          // `TexteAjuste` et les champs de saisie ont le droit d'en porter un.
          final contexte = lignes
              .sublist((i - 6).clamp(0, i), (i + 3).clamp(0, lignes.length))
              .join('\n');
          if (contexte.contains('TexteAjuste(') ||
              contexte.contains('TextField(') ||
              contexte.contains('TextFormField(')) {
            continue;
          }
          fautifs.add('$chemin:${i + 1} -> ${ligne.trim()}');
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'un plafond de lignes est revenu la ou le lot 749 l avait retire : '
            '$fautifs',
      );
    });

    // ---------------------------------------------------------------------
    test('la grille du cockpit ne revient pas a une hauteur ecrite en dur', () {
      // Le defaut d'origine n'etait pas une ligne de texte : c'etait un
      // NOMBRE, `mainAxisExtent: 180`, pose a la main dans la grille. Si
      // quelqu'un le repose, tous les cas ci-dessus continueront de passer —
      // ils mesurent la fonction, pas la grille. Cette garde lit donc la
      // grille elle-meme.
      final source = File('lib/shared/widgets/hub_section.dart');
      expect(
        source.readAsStringSync(),
        contains('hauteurDeTuilePour('),
        reason: 'la grille du cockpit doit MESURER sa hauteur de tuile',
      );
      expect(
        codeSansCommentaires(
          source,
        ).contains(RegExp(r'mainAxisExtent:\s*[0-9]')),
        isFalse,
        reason:
            'une hauteur de tuile ecrite en dur est exactement ce qui coupait '
            'les sous-titres du cockpit',
      );
    });

    // ---------------------------------------------------------------------
    test('la galerie de badges ne revient pas a un rapport de forme fige', () {
      final source = File(
        'lib/features/gamification/presentation/badge_gallery_screen.dart',
      );
      expect(
        codeSansCommentaires(
          source,
        ).contains(RegExp(r'childAspectRatio:\s*[0-9]')),
        isFalse,
        reason:
            'un rapport de forme fige rend la hauteur de tuile independante du '
            'texte : c est le defaut du lot 749',
      );
    });

    // ---------------------------------------------------------------------
    test('le texte qui defile le MONTRE', () {
      // La regle accepte qu'un conteneur defile au lieu de grandir, a une
      // condition : que ca se voie. Un texte qui s'arrete au pli sans aucun
      // signe de defilement se lit comme un texte coupe — c'est le retour de
      // Christophe sur la page des sauvegardes Google.
      for (final chemin in [
        'lib/features/map/widgets/poi_popup.dart',
        'lib/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart',
      ]) {
        final source = File(chemin).readAsStringSync();
        expect(
          source,
          contains('thumbVisibility: true'),
          reason: '$chemin defile : la barre de defilement doit etre visible',
        );
      }
    });
  });
}

/// Le code d'un fichier, ses lignes de commentaire retirees.
///
/// Les gardes de ce fichier cherchent des valeurs ecrites en dur dans du CODE.
/// Or les correctifs du lot 749 CITENT ces valeurs dans leurs commentaires,
/// pour expliquer le defaut qu'elles ont cause (« elle disait
/// `mainAxisExtent: 180` »). Une garde qui lirait les commentaires
/// s'etranglerait sur l'explication du defaut au lieu de surveiller son
/// retour.
String codeSansCommentaires(File fichier) => fichier
    .readAsLinesSync()
    .where((l) => !l.trimLeft().startsWith('//'))
    .join('\n');
