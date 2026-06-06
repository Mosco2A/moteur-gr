// E5.19b -- Tests widgets natifs Home Screen (R1.10).
//
// Le rendu natif (Kotlin/SwiftUI) ne s'execute pas dans flutter test.
// Ces tests verifient ce qui est verifiable cote repo et cote Dart :
// 1. Widget Android REELLEMENT declare : receiver dans le manifest,
//    layout RemoteViews et metadonnees presents, RemoteViews cable.
// 2. Widget iOS REELLEMENT integre : target TrekWidgetExtension dans
//    le pbxproj, TrekWidget.swift compile dans la target, appex embarque.
// 3. Contrat de cles SharedPreferences Dart <-> natif : les cles
//    ecrites par WidgetDataService (service instancie, prefs mockees)
//    sont exactement celles lues par TrekWidget.kt / TrekWidget.swift.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/features/trek/data/widget_data_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Widget Android -- R1.10', () {
    test('declare au AndroidManifest avec layout et metadonnees', () {
      final manifest =
          File('android/app/src/main/AndroidManifest.xml')
              .readAsStringSync();

      // Receiver AppWidgetProvider declare et exporte
      expect(manifest, contains('android:name=".TrekWidget"'));
      expect(manifest,
          contains('android.appwidget.action.APPWIDGET_UPDATE'));
      expect(manifest, contains('android.appwidget.provider'));
      expect(manifest, contains('@xml/widget_trek_info'));

      // Ressources widget presentes
      expect(
        File('android/app/src/main/res/layout/widget_trek_progress.xml')
            .existsSync(),
        isTrue,
        reason: 'layout RemoteViews requis',
      );
      expect(
        File('android/app/src/main/res/xml/widget_trek_info.xml')
            .existsSync(),
        isTrue,
        reason: 'metadonnees appwidget-provider requises',
      );

      // Le layout contient les vues remplies par TrekWidget.kt
      final layout =
          File('android/app/src/main/res/layout/widget_trek_progress.xml')
              .readAsStringSync();
      for (final id in [
        'trail_name',
        'stage_name',
        'progress_bar',
        'distance_remaining',
        'eta',
        'altitude',
      ]) {
        expect(layout, contains('@+id/$id'),
            reason: 'vue $id requise par RemoteViews');
      }

      // TrekWidget.kt cable les RemoteViews (plus de TODO)
      final kotlin = File(
        'android/app/src/main/kotlin/com/only1cent/moteur_gr/TrekWidget.kt',
      ).readAsStringSync();
      expect(kotlin,
          contains('RemoteViews(context.packageName, R.layout.widget_trek_progress)'));
      expect(kotlin, contains('appWidgetManager.updateAppWidget(appWidgetId, views)'));
      expect(kotlin, isNot(contains('TODO: Creer res/layout')));
    });

    test('widget iOS dans une target Xcode (pbxproj)', () {
      final pbxproj =
          File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();

      // Target extension WidgetKit presente
      expect(pbxproj, contains('TrekWidgetExtension'));
      expect(pbxproj,
          contains('productType = "com.apple.product-type.app-extension"'));

      // TrekWidget.swift compile dans la target
      expect(pbxproj, contains('TrekWidget.swift in Sources'));

      // Extension embarquee dans Runner
      expect(pbxproj,
          contains('TrekWidgetExtension.appex in Embed Foundation Extensions'));

      // Point d'entree WidgetKit + App Group dans le Swift
      final swift =
          File('ios/TrekWidget/TrekWidget.swift').readAsStringSync();
      expect(swift, contains('@main'));
      expect(swift, contains('WidgetBundle'));
      expect(swift, contains('group.com.only1cent.moteurGr'));

      // Plus de couleur sentier hardcodee : fond pilote par le theme
      expect(swift, isNot(contains('#2D5016')));
      expect(swift, contains('widget_trek_theme_color'));
    });
  });

  group('Contrat de cles Dart <-> widgets natifs -- R1.10', () {
    test('les cles ecrites par le service sont celles lues par le natif',
        () async {
      // Service reellement instancie avec prefs mockees
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = WidgetDataService(prefs: prefs);

      await service.updateWidgetData(
        trailName: 'Sentier des Volcans',
        stageName: 'Etape 1 - Puy de la Vache',
        stageProgress: 0.3,
        distanceRemaining: 8000.0,
        etaMinutes: 95,
        altitude: 1150.0,
        stageIndex: 1,
        totalStages: 5,
      );

      // Suffixes lus par TrekWidget.kt (prefixe flutter.widget_trek_)
      // et TrekWidget.swift (prefixe flutter.widget_trek_ via App Group)
      const nativeSuffixes = [
        'trail_name',
        'stage_name',
        'stage_progress',
        'distance_remaining',
        'eta_minutes',
        'altitude',
        'stage_index',
        'total_stages',
      ];
      for (final suffix in nativeSuffixes) {
        final key = 'widget_trek_$suffix';
        expect(prefs.getKeys(), contains(key),
            reason: 'le natif lit flutter.$key');
      }

      // Coherence croisee avec les sources natives
      final kotlin = File(
        'android/app/src/main/kotlin/com/only1cent/moteur_gr/TrekWidget.kt',
      ).readAsStringSync();
      final swift =
          File('ios/TrekWidget/TrekWidget.swift').readAsStringSync();
      expect(kotlin, contains('flutter.widget_trek_'));
      expect(swift, contains('flutter.widget_trek_'));
      for (final suffix in nativeSuffixes) {
        expect(kotlin, contains(suffix),
            reason: 'TrekWidget.kt doit lire $suffix');
        expect(swift, contains(suffix),
            reason: 'TrekWidget.swift doit lire $suffix');
      }
    });
  });
}
