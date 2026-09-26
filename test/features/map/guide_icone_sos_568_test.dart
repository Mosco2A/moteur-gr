import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/map/providers/map_pois_provider.dart';
import 'package:moteur_gr/features/map/widgets/map_guide_sheet.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Q5 (tache 568, LOT Q) — LE GUIDE DE LA CARTE ET SON ICONE SOS.
///
/// LE SOUPCON DE DEPART, tel que le mandat le formulait : « le guide des icones
/// documente une icone SOS qui n'existe sur aucun ecran ».
///
/// CE QUE LA MESURE DIT, ET ELLE CORRIGE LE SOUPCON : l'icone EXISTE. Elle est
/// portee par [SosButton] (`Icons.emergency`), instancie a DEUX endroits —
/// `map_screen.dart` (colonne de gauche de la carte, au-dessus du bouton photo
/// et du selecteur de calques) et `hub_screen.dart` (FAB du cockpit). Ce qui
/// etait FAUX, c'est le texte : la pastille SOS ne se montre QUE pendant une
/// rando active ([SosButton] se masque lui-meme sinon), alors que le guide, lui,
/// s'ouvre a tout moment depuis la carte. Un randonneur qui lisait le guide en
/// preparation cherchait donc un bouton absent.
///
/// LA CORRECTION RETENUE : on ne retire pas l'entree — la fonction existe et
/// c'est la plus importante de la carte. On rend le TEXTE exact, en nommant la
/// condition, exactement comme la ligne « etape en cours » du meme guide nomme
/// deja la sienne (« un tiret signifie que la randonnee n'a pas encore
/// demarre »). Et la tache 568 ajoute par ailleurs la porte d'entree qui
/// manquait vers l'ecran d'urgence (Q4a).
///
/// ECRIT ROUGE : la cle `map.guide.onlyInTrek` n'existait pas, et la ligne SOS
/// du guide ne portait aucune condition.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const trailId = 'mare-a-mare-centre';

  /// Lit un fichier source du paquet (cwd = racine du paquet sous `flutter test`).
  String source(String chemin) => File(chemin).readAsStringSync();

  Widget wrap() => ProviderScope(
        overrides: [
          // Aucun POI : la legende des points disparait, celle des BOUTONS
          // (dont le SOS) reste — c'est elle qu'on examine ici.
          availablePoiTypesProvider(trailId)
              .overrideWith((ref) async => const <String>{}),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => showMapGuideSheet(context, trailId),
                    child: const Text('OUVRIR'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> ouvrirGuide(WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();
    await tester.tap(find.text('OUVRIR'));
    await tester.pumpAndSettle();
  }

  group('Q5 — le guide ne documente plus un bouton introuvable', () {
    testWidgets(
      'la ligne SOS du guide DIT sa condition : visible seulement une fois la '
      'randonnee demarree',
      (tester) async {
        await ouvrirGuide(tester);

        // La ligne existe toujours (la fonction existe : on ne ment pas par
        // omission non plus).
        expect(find.byIcon(Icons.emergency), findsOneWidget);
        expect(find.text(t.a11y.sos), findsOneWidget);

        // Et son explication porte desormais la condition.
        expect(
          find.textContaining(t.map.guide.onlyInTrek),
          findsOneWidget,
          reason: 'la pastille SOS se masque hors rando : le guide doit le dire '
              'au lieu de laisser chercher un bouton absent',
        );
      },
    );

    testWidgets(
      'les boutons TOUJOURS presents de la carte ne portent PAS cette condition '
      '(elle ne devient pas un tic de langage)',
      (tester) async {
        await ouvrirGuide(tester);

        // Calques et photo sont la en preparation comme en rando.
        expect(find.text(t.map.layers), findsOneWidget);
        expect(find.text(t.journal.addPhoto), findsOneWidget);
        // Une seule ligne du guide porte la condition : celle du SOS.
        expect(find.textContaining(t.map.guide.onlyInTrek), findsOneWidget);
      },
    );

    test(
      'l icone documentee n est pas un fantome : elle est bien portee par un '
      'widget de lib/, et ce widget est pose sur la carte',
      () {
        final bouton = source('lib/features/safety/presentation/sos_button.dart');
        expect(
          bouton.contains('Icons.emergency'),
          isTrue,
          reason: 'c est ce widget qui dessine l icone que le guide explique',
        );
        // Et il est REELLEMENT pose sur l ecran depuis lequel le guide s ouvre.
        final carte = source('lib/features/trek/presentation/map/map_screen.dart');
        expect(carte.contains('SosButton()'), isTrue);
        expect(carte.contains('showMapGuideSheet'), isTrue);
      },
    );
  });
}
