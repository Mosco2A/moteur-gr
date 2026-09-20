import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/safety/presentation/sos_button.dart';
import 'package:moteur_gr/features/trek/providers/tracking_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// NON-REGRESSION — LOT FIX-2, finding M1.
///
/// LE FINDING TEL QUE RAPPORTE : « DEUX acces SOS simultanes pendant le trek, le
/// FAB overlay ET une action SOS en barre contextuelle ; le doublon avait deja
/// ete retire en cycle 3, il est revenu. »
///
/// CE QUE LA VERIFICATION A MONTRE : le doublon n'est PAS revenu. La barre
/// contextuelle de la carte ne porte QUE « Etape en cours » et « Journal »
/// (code + capture `S3_Steve_07_apres_gps` du round 1), et le cockpit n'a
/// aucune barre du bas. Ce que le harnais observait, c'est son propre finder :
/// `find.byIcon(Icons.emergency)` attendu FAUX alors que la pastille SOS
/// legitime — l'unique acces — contient justement cette icone. Le test ne
/// pouvait donc JAMAIS etre satisfait, meme sans aucun doublon.
///
/// CE QUE CES TESTS VERROUILLENT (l'invariant lui-meme, pas son symptome) :
///  - un SEUL point d'entree SOS, le bouton flottant [SosButton], masque hors
///    trek ;
///  - AUCUNE action SOS en barre contextuelle nulle part dans l'app ;
///  - l'ecran de demonstration dormant qui porte la SECONDE pastille SOS
///    (`nav_pilote_screen.dart`, conserve pour ses decisions de design) reste
///    injoignable : aucune route ne le reference. S'il etait rebranche, le
///    doublon reviendrait pour de bon — le garde le signalerait.
void main() {
  /// Lit un fichier source du paquet (cwd = racine du paquet sous `flutter test`).
  String source(String chemin) => File(chemin).readAsStringSync();

  group('M1 — un seul acces SOS, jamais en barre contextuelle', () {
    test('AUCUNE action de barre contextuelle ne declare un SOS', () {
      final fautifs = <String>[];

      for (final fichier in Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))) {
        final contenu = fichier.readAsStringSync();
        // On isole chaque declaration `ContextualAction( ... )` et on refuse
        // qu'elle porte l'icone d'urgence ou un libelle SOS.
        for (final bloc in _declarations(contenu, 'ContextualAction(')) {
          final minuscule = bloc.toLowerCase();
          if (minuscule.contains('emergency') || minuscule.contains('sos')) {
            fautifs.add(fichier.path);
          }
        }
      }

      expect(
        fautifs,
        isEmpty,
        reason: 'le SOS a ete retire des barres contextuelles en cycle 3 '
            '(parite GR20 : le SOS vit dans le Stack, jamais dans la barre). '
            'Le remettre recree le double acces du finding M1.',
      );
    });

    test('la barre contextuelle de la carte = Etape en cours + Journal, '
        'rien d autre', () {
      final carte =
          source('lib/features/trek/presentation/map/map_screen.dart');
      final debut = carte.indexOf('buildContextualActions');
      expect(debut, greaterThan(-1));
      // Corps de la methode jusqu'au `@override` suivant.
      final fin = carte.indexOf('@override', debut);
      final corps = carte.substring(debut, fin > debut ? fin : carte.length);

      expect(
        'ContextualAction('.allMatches(corps).length,
        2,
        reason: 'exactement deux actions de navigation contextuelle',
      );
      expect(corps.toLowerCase(), isNot(contains('emergency')));
    });

    test('l ecran de demo dormant (2e pastille SOS) n est cable sur AUCUNE '
        'route', () {
      final routeur = source('lib/core/routing/app_router.dart');
      // Ni import REEL du fichier (le routeur en garde une trace en
      // commentaire, qui documente pourquoi l'ecran est dormant), ni
      // instanciation de l'ecran.
      expect(
        RegExp(r"^\s*import\s+.*nav_pilote_screen\.dart", multiLine: true)
            .hasMatch(routeur),
        isFalse,
        reason: 'le routeur ne doit pas importer l ecran de demo dormant',
      );
      expect(routeur.contains('NavPiloteScreen('), isFalse);

      // Et personne d'autre ne l'instancie dans l'app.
      final instanciations = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('nav_pilote_screen.dart'))
          .where((f) => f.readAsStringSync().contains('NavPiloteScreen'))
          .map((f) => f.path)
          .toList();

      expect(
        instanciations,
        isEmpty,
        reason: 'cet ecran porte une SECONDE pastille SOS ; le rebrancher '
            'recreerait le double acces (finding M1)',
      );
    });

    test('le cockpit place le SOS du MEME cote que la carte (parite GR20) '
        'et ne le pose pas sur le bouton « Terminer le trek »', () {
      final cockpit = source('lib/features/hub/presentation/hub_screen.dart');
      expect(
        cockpit.contains(
          'floatingActionButtonLocation: FloatingActionButtonLocation'
          '.startFloat',
        ),
        isTrue,
        reason: 'au coin bas-droit par defaut, la pastille SOS recouvrait la '
            'fin du bouton pleine largeur « Terminer le trek » ; GR20 place ce '
            'meme FAB en startFloat sur son accueil',
      );
    });
  });

  group('M1 — le bouton SOS lui-meme : present en trek, absent sinon', () {
    Widget wrap(TrackingSessionStatus status) => ProviderScope(
          overrides: [
            trekSessionManagerProvider
                .overrideWith(() => _FakeTrek(TrackingSessionState(
                      status: status,
                    ))),
          ],
          child: TranslationProvider(
            child: const MaterialApp(
              home: Scaffold(
                floatingActionButton: SosButton(),
                body: SizedBox.shrink(),
              ),
            ),
          ),
        );

    testWidgets('trek en cours -> EXACTEMENT un acces SOS', (tester) async {
      await tester.pumpWidget(wrap(TrackingSessionStatus.recording));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is FloatingActionButton && w.heroTag == 'sos_e515',
        ),
        findsOneWidget,
      );
    });

    testWidgets('trek en pause -> l acces SOS reste disponible',
        (tester) async {
      await tester.pumpWidget(wrap(TrackingSessionStatus.paused));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.emergency), findsOneWidget);
    });

    testWidgets('hors trek -> AUCUN acces SOS', (tester) async {
      await tester.pumpWidget(wrap(TrackingSessionStatus.idle));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byIcon(Icons.emergency), findsNothing);
    });
  });
}

/// Extrait le texte de chaque declaration commencant par [ouverture], parentheses
/// equilibrees (suffisant pour inspecter le contenu d'un constructeur).
List<String> _declarations(String source, String ouverture) {
  final blocs = <String>[];
  var index = source.indexOf(ouverture);
  while (index != -1) {
    var profondeur = 0;
    var curseur = index + ouverture.length - 1; // sur la parenthese ouvrante
    for (; curseur < source.length; curseur++) {
      final c = source[curseur];
      if (c == '(') profondeur++;
      if (c == ')') {
        profondeur--;
        if (profondeur == 0) break;
      }
    }
    blocs.add(source.substring(index, curseur.clamp(index, source.length)));
    index = source.indexOf(ouverture, index + ouverture.length);
  }
  return blocs;
}

class _FakeTrek extends TrekSessionManagerNotifier {
  _FakeTrek(this._initial);
  final TrackingSessionState _initial;

  @override
  TrackingSessionState build() => _initial;
}
