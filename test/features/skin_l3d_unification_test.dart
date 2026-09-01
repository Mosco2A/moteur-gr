// SW-SKIN-L3d — Tests de l'unification des composants (Card -> AppCard,
// *Button -> AppButton) sur les domaines journal + guides + diploma.
//
// Objectif : prouver que les ecrans/widgets de ces trois domaines utilisent
// desormais la grammaire unifiee (AppCard / AppButton) et PLUS aucune Card
// Material brute, tout en gardant les taps fonctionnels (iso-fonction).
// L'iso-rendu visuel (padding, contenu, semantique) est preserve par
// construction dans les ecrans ; ces tests verrouillent la substitution
// structurelle et le comportement (tap, ouverture de lien, cible tactile).

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/daos/review_requests_dao.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/after/data/in_app_review_service.dart';
import 'package:moteur_gr/features/after/providers/in_app_review_provider.dart';
import 'package:moteur_gr/features/diploma/presentation/diploma_screen.dart';
import 'package:moteur_gr/features/guides/domain/town_guide.dart';
import 'package:moteur_gr/features/guides/domain/town_guide_catalog.dart';
import 'package:moteur_gr/features/guides/presentation/town_guide_detail_screen.dart';
import 'package:moteur_gr/features/guides/presentation/town_guides_screen.dart';
import 'package:moteur_gr/features/guides/providers/guide_providers.dart';
import 'package:moteur_gr/features/journal/widgets/add_note_dialog.dart';
import 'package:moteur_gr/features/journal/widgets/journal_entry_card.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

/// Lanceur de deeplink factice (guides) : enregistre les URL ouvertes sans
/// toucher au plugin natif url_launcher. Permet de tester le bouton
/// FACILITATEUR converti en AppButton (#84100) en mode pur widget.
class _FakeLauncher implements GuideDeeplinkLauncher {
  _FakeLauncher({this.result = true});
  bool result;
  final List<String> opened = [];

  @override
  Future<bool> open(String url) async {
    opened.add(url);
    return result;
  }
}

/// Service d'avis store no-op : evite l'appel plugin natif (isAvailable) que
/// DiplomaScreen declenche en post-frame. On garde le DAO reel (base memoire)
/// pour satisfaire le constructeur, mais on court-circuite la demande.
class _NoReviewService extends InAppReviewService {
  _NoReviewService(ReviewRequestsDao dao)
      : super(reviewRequestsDao: dao);

  @override
  Future<bool> requestReviewIfEligible(String trailId) async => false;
}

const _guidesTrailId = 'mare_a_mare_centre';

GuideSectionLabels _stubLabels(String categorie) =>
    GuideSectionLabels(titre: 'titre-$categorie', contenu: 'intro-$categorie');

List<TownGuide> _catalogGuides() => TownGuideCatalog.guidesFor(
      _guidesTrailId,
      sectionLabelResolver: _stubLabels,
    ).where((g) => g.hasContent).toList();

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();

  setUpAll(() async {
    await initializeDateFormatting('fr_FR');
  });

  // -------------------------------------------------------------------------
  // JOURNAL
  // -------------------------------------------------------------------------
  group('SW-SKIN-L3d — journal', () {
    testWidgets('JournalEntryCard rend un AppCard (plus de Card brute) '
        'et conserve son contenu', (tester) async {
      final entry = JournalEntry(
        id: 1,
        trailId: 'sentier-bleu',
        stageNumber: 4,
        content: 'Belle etape sous le soleil.',
        createdAt: DateTime(2026, 6, 1, 9, 30),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JournalEntryCard(
              entry: entry,
              onDelete: () {},
              onEdit: (_) {},
            ),
          ),
        ),
      );

      // Grammaire unifiee : AppCard, aucune Card Material brute.
      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      // Iso-rendu du contenu (etape + texte toujours la).
      expect(find.text('Étape 4'), findsOneWidget);
      expect(find.text('Belle etape sous le soleil.'), findsOneWidget);
    });

    testWidgets('AddNoteDialog : validation = AppButton + tap fonctionnel',
        (tester) async {
      int? savedStage;
      String? savedContent;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AddNoteDialog(
              onSave: (stage, content) {
                savedStage = stage;
                savedContent = content;
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // La validation est desormais un AppButton (plus d'ElevatedButton brut) ;
      // le bouton "Annuler" reste un TextButton plat (hors scope L3d).
      expect(find.byType(AppButton), findsOneWidget);

      // Saisie puis tap sur "Enregistrer" -> onSave recoit les valeurs.
      await tester.enterText(find.byType(TextField), 'Ma note du jour');
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();

      expect(savedStage, 1);
      expect(savedContent, 'Ma note du jour');
    });
  });

  // -------------------------------------------------------------------------
  // GUIDES
  // -------------------------------------------------------------------------
  group('SW-SKIN-L3d — guides', () {
    Widget wrapGuides(Widget child, {required GuideDeeplinkLauncher launcher}) {
      return ProviderScope(
        overrides: [
          guideDeeplinkLauncherProvider.overrideWithValue(launcher),
        ],
        child: TranslationProvider(child: MaterialApp(home: child)),
      );
    }

    testWidgets('TownGuidesScreen : les localites sont des AppCard '
        '(plus de Card brute)', (tester) async {
      await tester.pumpWidget(
        wrapGuides(const TownGuidesScreen(trailId: _guidesTrailId),
            launcher: _FakeLauncher()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(Card), findsNothing);

      // Les cles de carte (clic -> detail) sont preservees sur l'AppCard.
      final guides = _catalogGuides();
      expect(guides, isNotEmpty);
      expect(find.byKey(ValueKey('town-guide-card-${guides.first.id}')),
          findsOneWidget);
    });

    testWidgets('TownGuideDetailScreen : sections en AppCard, bouton lien = '
        'AppButton + ouverture facilitateur', (tester) async {
      final launcher = _FakeLauncher(result: true);
      const guide = TownGuide(
        id: 'g-test',
        trailId: _guidesTrailId,
        nomLieu: 'Lieu test',
        latitude: 0,
        longitude: 0,
        sections: [
          GuideSection(
            categorie: GuideCategory.hebergement,
            titre: 'Hebergement',
            items: [
              GuideItem(
                nom: 'Gite test',
                description: 'desc',
                deeplinkUrl: 'https://example.org/gite',
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(wrapGuides(
        const TownGuideDetailScreen(
          trailId: _guidesTrailId,
          guideId: 'g-test',
          guide: guide,
        ),
        launcher: launcher,
      ));
      await tester.pumpAndSettle();

      // Section thematique = AppCard, aucune Card brute.
      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(Card), findsNothing);

      // Le bouton facilitateur est un AppButton (variante outline) et garde sa
      // cle ; le tap OUVRE le lien SORTANT via le launcher (aucune resa in-app).
      final btn = find.byKey(const ValueKey('guide-deeplink-Gite test'));
      expect(btn, findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);

      await tester.tap(btn);
      await tester.pumpAndSettle();
      expect(launcher.opened, ['https://example.org/gite']);
    });
  });

  // -------------------------------------------------------------------------
  // DIPLOMA
  // -------------------------------------------------------------------------
  group('SW-SKIN-L3d — diploma', () {
    testWidgets('DiplomaScreen : sections en AppCard (plus de Card brute) '
        'et bouton PDF = AppButton', (tester) async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      LocaleSettings.setLocaleRaw('fr');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            trailConfigProvider.overrideWithValue(testTrailConfig),
            // No-op review : evite l'appel plugin natif en post-frame.
            inAppReviewServiceProvider.overrideWithValue(
              _NoReviewService(db.reviewRequestsDao),
            ),
          ],
          child: TranslationProvider(
            child: const MaterialApp(home: DiplomaScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Photos (vide), stats, carte trace, compteur = AppCard ; aucune Card
      // Material brute residuelle dans l'ecran.
      expect(find.byType(AppCard), findsWidgets);
      expect(find.byType(Card), findsNothing);

      // Le bouton de telechargement PDF est desormais un AppButton.
      expect(find.byType(AppButton), findsOneWidget);
      expect(find.text(tr.diploma.downloadPdf), findsOneWidget);
    });
  });
}
