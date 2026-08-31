// SW-SKIN-L3b — Tests de l'unification des composants (Card -> AppCard,
// OutlinedButton -> AppButton) sur le domaine weather (meteo).
//
// Objectif : prouver que les widgets meteo utilisent desormais la grammaire
// unifiee (AppCard / AppButton) et PLUS aucune Card Material brute, tout en
// gardant le rendu (padding, liseré d'alerte semantique) et les taps
// fonctionnels (iso-fonction). L'iso-rendu visuel est preserve par
// construction dans les widgets ; ces tests verrouillent la substitution
// structurelle et le comportement (dont le CTA incendie en rouge semantique).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/theme/app_theme.dart';
import 'package:moteur_gr/features/tips/domain/models/tip_card.dart';
import 'package:moteur_gr/features/tips/presentation/tip_detail_sheet.dart';
import 'package:moteur_gr/features/weather/models/weather_alert.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';
import 'package:moteur_gr/features/weather/providers/current_stage_provider.dart';
import 'package:moteur_gr/features/weather/widgets/all_stages_weather_list.dart';
import 'package:moteur_gr/features/weather/widgets/day_forecast_card.dart';
import 'package:moteur_gr/features/weather/widgets/today_stage_weather_card.dart';
import 'package:moteur_gr/features/weather/widgets/weather_alert_banner.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/shared/widgets/app_button.dart';
import 'package:moteur_gr/shared/widgets/app_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final Translations tr = AppLocale.fr.buildSync();

  // Journee calme (aucune condition d'alerte) : liseré neutre.
  DayForecast calmDay() => DayForecast(
        date: DateTime(2026, 7, 15),
        temperatureMax: 24,
        temperatureMin: 14,
        precipitationMm: 1,
        windSpeedKmh: 10,
        uvIndex: 4,
        weatherCode: 1,
      );

  // Journee d'orage (isAlertCondition == true) : liseré rouge 1.5px attendu.
  DayForecast stormDay() => DayForecast(
        date: DateTime(2026, 7, 16),
        temperatureMax: 28,
        temperatureMin: 18,
        precipitationMm: 25,
        windSpeedKmh: 45,
        uvIndex: 6,
        weatherCode: 95,
      );

  Widget wrap(Widget child) {
    return ProviderScope(
      child: TranslationProvider(
        child: MaterialApp(
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  group('SW-SKIN-L3b — TodayStageWeatherCard', () {
    testWidgets('utilise AppCard (plus de Card brute)', (tester) async {
      await tester.pumpWidget(wrap(TodayStageWeatherCard(day: calmDay())));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('SW-SKIN-L3b — AllStagesWeatherList', () {
    testWidgets('utilise AppCard (plus de Card brute)', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          // Liste d'etapes vide (branche « aucune prevision ») : la coque
          // AppCard + ExpansionTile se construit sans base de donnees.
          overrides: [
            trailStagesProvider('test-trail').overrideWith((ref) async => const []),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: Scaffold(
                body: AllStagesWeatherList(trailId: 'test-trail'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);
    });
  });

  group('SW-SKIN-L3b — DayForecastCard', () {
    testWidgets('utilise AppCard sans liseré en conditions calmes',
        (tester) async {
      await tester.pumpWidget(wrap(DayForecastCard(day: calmDay())));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      // Etat calme : aucun liseré semantique (borderColor null).
      final card = tester.widget<AppCard>(find.byType(AppCard));
      expect(card.borderColor, isNull);
    });

    testWidgets('conserve le liseré rouge 1.5px en condition d\'alerte',
        (tester) async {
      await tester.pumpWidget(wrap(DayForecastCard(day: stormDay())));
      await tester.pumpAndSettle();

      expect(find.byType(AppCard), findsOneWidget);
      expect(find.byType(Card), findsNothing);

      // Liseré semantique conserve a l'identique (rouge urgence, 1.5px).
      final card = tester.widget<AppCard>(find.byType(AppCard));
      expect(card.borderColor, AppTheme.rougeUrgence);
      expect(card.borderWidth, 1.5);
    });
  });

  group('SW-SKIN-L3b — WeatherAlertBanner (CTA incendie)', () {
    // Fiche conseil incendie -> declenche l'affichage du CTA.
    const fireTip = TipCard(
      id: 'incendie-periode-risque',
      titleFr: 'Risque incendie',
      contentFr: 'Consignes de securite en periode de risque.',
      category: 'safety',
    );

    // Alerte de type fire (severite danger) attendue par le bandeau.
    final fireAlert = WeatherAlert(
      severity: 'danger',
      kind: WeatherAlertKind.fire,
      date: DateTime(2026, 7, 15),
      type: AlertType.fire,
      fireTipId: 'incendie-periode-risque',
    );

    testWidgets('le CTA est un AppButton outline en rouge semantique',
        (tester) async {
      await tester.pumpWidget(wrap(
        WeatherAlertBanner(alerts: [fireAlert], fireTipCard: fireTip),
      ));
      await tester.pumpAndSettle();

      // Grammaire unifiee : aucune Card brute, un AppButton pour le CTA.
      expect(find.byType(Card), findsNothing);
      expect(find.byType(AppButton), findsOneWidget);

      // La couleur SEMANTIQUE rouge du CTA securite est preservee (tone) sur la
      // variante outline (pas la couleur primary du theme).
      final button = tester.widget<AppButton>(find.byType(AppButton));
      expect(button.variant, AppButtonVariant.outline);
      expect(button.tone, AppTheme.rougeUrgence);
      expect(button.label, tr.weather.fireSafetyTips);
    });

    testWidgets('tap du CTA ouvre la fiche conseil (iso-fonction)',
        (tester) async {
      await tester.pumpWidget(wrap(
        WeatherAlertBanner(alerts: [fireAlert], fireTipCard: fireTip),
      ));
      await tester.pumpAndSettle();

      // Tap sur le libelle du CTA : onPressed inchange -> ouvre la fiche.
      await tester.tap(find.text(tr.weather.fireSafetyTips));
      await tester.pumpAndSettle();

      expect(find.byType(TipDetailSheet), findsOneWidget);
    });

    testWidgets('sans fiche conseil, pas de CTA (comportement inchange)',
        (tester) async {
      await tester.pumpWidget(wrap(
        WeatherAlertBanner(alerts: [fireAlert]),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(AppButton), findsNothing);
      expect(find.byType(Card), findsNothing);
    });
  });
}
