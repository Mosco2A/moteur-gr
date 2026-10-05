import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/temperature_unit.dart';

/// P2 (#101255 point 2, defaut #101197 point 2) — LE FORMAT DE TEMPERATURE,
/// UNIQUE ET DANS LE DOMAINE.
///
/// CE QUI MANQUAIT. Le reglage Celsius / Fahrenheit s'affichait, se persistait
/// (lot 645-F1) et ne changeait RIEN : les endroits qui montrent une
/// temperature ecrivaient « 18° », un degre sans unite, toujours en Celsius.
/// Le randonneur qui choisissait Fahrenheit voyait un bouton bouger, pas une
/// temperature.
///
/// CE QUE CE FICHIER PROUVE. La seule fonction qui ecrit une temperature rend
/// « 18 °C » ou « 64 °F », convertit juste, arrondit, et retombe sur Celsius
/// devant une unite inconnue au lieu d'inventer. Les six endroits qui
/// l'appellent sont verifies a l'ecran par
/// `test/features/weather/temperature_dans_l_unite_choisie_test.dart`.
///
/// 18 °C valent 64,4 °F (arrondi 64) et 9 °C valent 48,2 °F (arrondi 48) : des
/// valeurs choisies pour qu'un arrondi ne puisse pas coincider par hasard avec
/// la valeur Celsius, ce qui rendrait le test aveugle a une conversion oubliee.
void main() {
  group('temperatureInUnit', () {
    test('Celsius est l unite du modele : rien ne bouge', () {
      expect(temperatureInUnit(18, TemperatureUnitValues.celsius), 18);
    });

    test('Fahrenheit convertit, et les deux reperes connus le prouvent', () {
      expect(temperatureInUnit(0, TemperatureUnitValues.fahrenheit), 32);
      expect(temperatureInUnit(100, TemperatureUnitValues.fahrenheit), 212);
      expect(temperatureInUnit(-40, TemperatureUnitValues.fahrenheit), -40);
    });

    test('une unite inconnue ne convertit pas', () {
      expect(temperatureInUnit(18, 'kelvin'), 18);
    });
  });

  group('formatTemperature', () {
    test('rend « 18 °C » en Celsius', () {
      expect(formatTemperature(18, TemperatureUnitValues.celsius), '18 °C');
    });

    test('rend « 64 °F » en Fahrenheit', () {
      expect(formatTemperature(18, TemperatureUnitValues.fahrenheit), '64 °F');
    });

    test('arrondit, negatifs compris', () {
      expect(formatTemperature(-5.4, TemperatureUnitValues.celsius), '-5 °C');
      expect(formatTemperature(17.6, TemperatureUnitValues.celsius), '18 °C');
      expect(formatTemperature(-5, TemperatureUnitValues.fahrenheit), '23 °F');
    });

    test('une unite inconnue retombe sur Celsius, symbole compris', () {
      expect(formatTemperature(18, 'kelvin'), '18 °C');
    });
  });

  group('formatTemperatureRange', () {
    test('ne porte l unite qu une fois (regle du SI)', () {
      expect(
        formatTemperatureRange(18, 9, TemperatureUnitValues.celsius),
        '18 / 9 °C',
      );
      expect(
        formatTemperatureRange(18, 9, TemperatureUnitValues.fahrenheit),
        '64 / 48 °F',
      );
    });

    test(
      'respecte l ordre de l appelant (le cockpit met le minimum d abord)',
      () {
        expect(
          formatTemperatureRange(9, 18, TemperatureUnitValues.celsius),
          '9 / 18 °C',
        );
      },
    );
  });

  group('TemperatureUnitValues', () {
    test('deux unites, Celsius par defaut', () {
      expect(TemperatureUnitValues.values, ['celsius', 'fahrenheit']);
      expect(TemperatureUnitValues.fallback, TemperatureUnitValues.celsius);
    });

    test('symboles et libelles', () {
      expect(TemperatureUnitValues.symbolFor('celsius'), '°C');
      expect(TemperatureUnitValues.symbolFor('fahrenheit'), '°F');
      expect(TemperatureUnitValues.labelFor('celsius'), 'Celsius');
      expect(TemperatureUnitValues.labelFor('fahrenheit'), 'Fahrenheit');
    });

    test('fromString normalise ce qu elle ne connait pas', () {
      expect(TemperatureUnitValues.fromString('kelvin'), 'celsius');
      expect(TemperatureUnitValues.fromString(''), 'celsius');
      expect(TemperatureUnitValues.fromString('fahrenheit'), 'fahrenheit');
    });
  });
}
