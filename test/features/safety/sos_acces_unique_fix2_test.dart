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
///  - l'ecran de demonstration qui portait la SECONDE pastille SOS
///    (`nav_pilote_screen.dart`) n'est plus dormant : il a ete SUPPRIME le
///    20/09/2026 par le correctif L0-1 (cycle4), avec sa suite de 28 tests et la
///    banniere publicitaire devenue orpheline. C'est d'ailleurs lui qui avait
///    produit le faux positif M1 ci-dessus. Le garde ci-dessous devient donc
///    PLUS STRICT : le filtre qui epargnait son propre fichier du balayage est
///    tombe avec lui, et plus AUCUN fichier de `lib/` ne doit porter son nom de
///    classe. S'il revenait, le doublon SOS reviendrait avec — le garde rougit.
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

    test('la carte n a plus AUCUNE barre du bas — donc plus aucun endroit ou '
        'un second SOS pourrait reapparaitre (L6-3)', () {
      final carte =
          source('lib/features/trek/presentation/map/map_screen.dart');

      // Le correctif L6-3 a retire la barre contextuelle de la carte : la
      // navigation de reference n en a aucune sur son ecran terrain. Ce test
      // ne verifie donc plus le CONTENU de la barre (il n y en a plus), il
      // verifie son ABSENCE — garantie plus forte pour le finding M1.
      expect(
        carte.contains('bottomNavigationBar:'),
        isFalse,
        reason: 'la carte terrain n a pas de barre du bas (L6-3)',
      );
      expect(
        carte.contains('buildContextualActions'),
        isFalse,
        reason: 'plus d actions contextuelles declarees par la carte (L6-3)',
      );
      expect(carte.contains('ContextualAction('), isFalse);
    });

    test('l accueil maison GARDE sa barre : ce n est PAS le meme cas que la '
        'carte (nuance du correctif L6-3)', () {
      // Ecran multi-sentiers, sans equivalent dans la reference : la
      // comparaison qui a fait retirer la barre de la carte ne tient pas pour
      // lui. Ce test existe pour qu un futur passage ne retire pas cette
      // barre-la « par coherence ».
      final maison =
          source('lib/features/treks/presentation/my_treks_screen.dart');
      expect(maison.contains('bottomNavigationBar:'), isTrue);
    });

    test('l ecran de demo supprime (2e pastille SOS) n est cable sur AUCUNE '
        'route et ne revient nulle part dans lib/', () {
      final routeur = source('lib/core/routing/app_router.dart');
      // Ni import REEL du fichier (le routeur en garde une trace en
      // commentaire, qui documente quand et pourquoi l'ecran a ete supprime),
      // ni instanciation de l'ecran.
      expect(
        RegExp(r"^\s*import\s+.*nav_pilote_screen\.dart", multiLine: true)
            .hasMatch(routeur),
        isFalse,
        reason: 'le routeur ne doit pas importer l ecran de demo supprime',
      );
      expect(routeur.contains('NavPiloteScreen('), isFalse);

      // Et personne ne le reintroduit dans l'app. Le filtre qui excluait
      // `nav_pilote_screen.dart` du balayage est RETIRE (L0-1, 20/09/2026) :
      // le fichier n'existe plus, donc plus AUCUN fichier de lib/ n'a le droit
      // de porter ce nom de classe. Le garde est volontairement absolu.
      final instanciations = Directory('lib')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => f.readAsStringSync().contains('NavPiloteScreen'))
          .map((f) => f.path)
          .toList();

      expect(
        instanciations,
        isEmpty,
        reason: 'cet ecran portait une SECONDE pastille SOS a l origine du faux '
            'positif M1 ; le reintroduire recreerait le double acces',
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
