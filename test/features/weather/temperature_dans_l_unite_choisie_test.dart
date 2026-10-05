import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/temperature_unit.dart';
import 'package:moteur_gr/features/weather/models/weather_alert.dart';
import 'package:moteur_gr/features/weather/models/weather_forecast.dart';
import 'package:moteur_gr/features/weather/presentation/weather_alert_l10n.dart';
import 'package:moteur_gr/features/weather/widgets/compact_forecast_row.dart';
import 'package:moteur_gr/features/weather/widgets/day_forecast_card.dart';
import 'package:moteur_gr/features/weather/widgets/today_stage_weather_card.dart';
import 'package:moteur_gr/features/weather/widgets/weather_alert_banner.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// P2 (#101255 point 2, defaut #101197 point 2) — LA TEMPERATURE S'AFFICHE DANS
/// L'UNITE CHOISIE.
///
/// CE QUI MANQUAIT, MESURE PAR ARTEMIS LE 04/10. Le reglage Celsius /
/// Fahrenheit s'affichait, se persistait (lot 645-F1) et ne changeait RIEN :
/// les six endroits qui montrent une temperature ecrivaient « 18° », un degre
/// sans unite, toujours en Celsius. Le randonneur qui choisissait Fahrenheit
/// voyait un bouton bouger, pas une temperature.
///
/// CE QUE CE FICHIER PROUVE : LES WIDGETS, rendus pour de vrai, montrent le
/// symbole de l'unite choisie ET la valeur convertie — jamais l'autre symbole
/// en meme temps, ce qui est la seule facon de voir une conversion oubliee
/// quelque part. LE FORMAT lui-meme (conversion, arrondi, repli sur une unite
/// inconnue) est prouve par son test miroir,
/// `test/domain/temperature_unit_test.dart`.
///
/// 18 °C vaut 64,4 °F (arrondi 64) et 9 °C vaut 48,2 °F (arrondi 48) : les deux
/// valeurs du jour de reference ci-dessous sont choisies pour que l'arrondi ne
/// puisse pas coincider par hasard avec la valeur Celsius.
void main() {
  // Jour de reference : 18 °C / 9 °C, ciel clair, rien qui declenche d'alerte.
  final jour = DayForecast(
    date: DateTime(2026, 7, 14),
    temperatureMax: 18,
    temperatureMin: 9,
    precipitationMm: 0,
    windSpeedKmh: 10,
    uvIndex: 4,
    weatherCode: 0,
  );

  group('les widgets rendus, dans les deux unites', () {
    // Monte un widget avec le reglage d'unite DEJA persiste : le notifier le
    // relit dans son `_load`, exactement comme au lancement de l'application.
    Future<void> rendre(
      WidgetTester tester,
      Widget enfant, {
      required String unite,
    }) async {
      // `resetStatic` AVANT d'ecrire : sans lui, `getInstance` rend la poignee
      // deja memorisee par le rendu precedent et le second reglage n'est jamais
      // relu — le test passerait en montrant deux fois la MEME unite.
      SharedPreferences.resetStatic();
      SharedPreferences.setMockInitialValues({
        'settings_temperature_unit': unite,
      });
      await tester.pumpWidget(
        ProviderScope(
          child: TranslationProvider(
            child: MaterialApp(
              home: Scaffold(body: SingleChildScrollView(child: enfant)),
            ),
          ),
        ),
      );
      // Laisse le `_load` asynchrone des reglages ecrire l'etat, puis rebatir.
      await tester.pump();
      await tester.pumpAndSettle();
    }

    /// Vrai si un `Text` de l'arbre contient [extrait].
    bool texteContenant(String extrait) => find
        .byWidgetPredicate((w) => w is Text && (w.data ?? '').contains(extrait))
        .evaluate()
        .isNotEmpty;

    for (final (nom, construire) in <(String, Widget Function())>[
      ('DayForecastCard', () => DayForecastCard(day: jour)),
      ('TodayStageWeatherCard', () => TodayStageWeatherCard(day: jour)),
      ('CompactForecastRow', () => CompactForecastRow(days: [jour])),
    ]) {
      testWidgets('$nom en Fahrenheit : « °F » et la valeur convertie', (
        tester,
      ) async {
        await rendre(
          tester,
          construire(),
          unite: TemperatureUnitValues.fahrenheit,
        );

        expect(texteContenant('°F'), isTrue, reason: '$nom doit montrer °F');
        expect(
          texteContenant('°C'),
          isFalse,
          reason: '$nom ne doit plus montrer °C quand Fahrenheit est choisi',
        );
        expect(texteContenant('64'), isTrue, reason: '18 °C valent 64 °F');
        expect(texteContenant('48'), isTrue, reason: '9 °C valent 48 °F');
      });

      testWidgets('$nom en Celsius : « °C » et la valeur non convertie', (
        tester,
      ) async {
        await rendre(
          tester,
          construire(),
          unite: TemperatureUnitValues.celsius,
        );

        expect(texteContenant('°C'), isTrue, reason: '$nom doit montrer °C');
        expect(texteContenant('°F'), isFalse);
        expect(texteContenant('18'), isTrue);
        expect(texteContenant('9'), isTrue);
      });
    }

    // L'ALERTE INCENDIE PORTAIT « °C » EN DUR DANS LES CINQ TRADUCTIONS.
    // C'est le seul endroit ou le symbole etait dans un texte traduit et non
    // dans du code : il suit maintenant le reglage comme les autres.
    // DEUX TESTS ET PAS UN SEUL, ET LA RAISON COMPTE : un second `pumpWidget`
    // avec la MEME racine `ProviderScope` met l'arbre a jour au lieu de le
    // reconstruire — le conteneur Riverpod survit, le notifier des reglages
    // n'est pas rebati, et le second reglage n'arriverait jamais. Un seul test
    // qui bascule d'une unite a l'autre mesurerait donc le harnais.
    final alerteIncendie = WeatherAlert(
      severity: 'danger',
      kind: WeatherAlertKind.fire,
      date: DateTime(2026, 7, 14),
      amount: 35,
      type: AlertType.fire,
    );

    testWidgets('le bandeau d alerte incendie en Fahrenheit', (tester) async {
      await rendre(
        tester,
        WeatherAlertBanner(alerts: [alerteIncendie]),
        unite: TemperatureUnitValues.fahrenheit,
      );
      expect(texteContenant('95 °F'), isTrue, reason: '35 °C valent 95 °F');
      expect(texteContenant('°C'), isFalse);
    });

    testWidgets('le bandeau d alerte incendie en Celsius', (tester) async {
      await rendre(
        tester,
        WeatherAlertBanner(alerts: [alerteIncendie]),
        unite: TemperatureUnitValues.celsius,
      );
      expect(texteContenant('35 °C'), isTrue);
      expect(texteContenant('°F'), isFalse);
    });
  });

  group('la traduction de l alerte ne porte plus l unite', () {
    test(
      'les cinq langues passent par le format, pas par un « °C » en dur',
      () {
        final alerte = WeatherAlert(
          severity: 'danger',
          kind: WeatherAlertKind.fire,
          date: DateTime(2026, 7, 14),
          amount: 35,
          type: AlertType.fire,
        );
        for (final locale in AppLocale.values) {
          final t = locale.buildSync();
          expect(
            alerte.localizedDescription(
              t,
              unit: TemperatureUnitValues.fahrenheit,
            ),
            contains('95 °F'),
            reason:
                'langue ${locale.languageTag} : l alerte incendie doit '
                'ecrire la temperature dans l unite demandee',
          );
          expect(
            alerte.localizedDescription(t, unit: TemperatureUnitValues.celsius),
            contains('35 °C'),
            reason: 'langue ${locale.languageTag} : en Celsius, 35 °C',
          );
        }
      },
    );
  });
}
