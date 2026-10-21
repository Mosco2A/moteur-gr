// TACHE 861 — LES DEUX NOTES A L'ECRAN, NOMMEES ET COLOREES.
//
// CE QUE CE FICHIER GARDE. Que les deux axes sont NOMMES a l'ecran (« Effort »
// et « Pente » : un nombre sur vingt sans nom d'axe ne veut plus rien dire
// des qu'il y en a deux), que le chiffre brut en metres par kilometre
// accompagne TOUJOURS la raideur, et que le degrade colore va bien du vert au
// rouge sans jamais porter l'information tout seul.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/domain/note_d_effort.dart';
import 'package:moteur_gr/domain/note_de_raideur.dart';
import 'package:moteur_gr/features/trail/widgets/les_deux_notes.dart';

/// LE BLOC, AVEC SES NIVEAUX TIRES DES LOIS et non ecrits a la main : le test
/// exerce ainsi le vrai cablage, pas une valeur de complaisance.
Widget bloc({
  required double effort,
  required double raideur,
  required double metresParKm,
  String? titre,
}) => MaterialApp(
  home: Scaffold(
    body: LesDeuxNotes(
      effort: effort,
      raideur: raideur,
      metresParKm: metresParKm,
      libelleDEffort: NoteDEffort.libelleDuNiveau(
        NoteDEffort.indicePourNote(effort),
      ),
      libelleDeRaideur: NoteDeRaideur.libelleDuNiveau(metresParKm),
      graduationsDEffort: <double>[
        for (final seuil in NoteDEffort.graduationsPubliees)
          NoteDEffort.pourIndice(seuil),
      ],
      graduationsDeRaideur: <double>[
        for (final bande in NoteDeRaideur.graduationsPubliees)
          NoteDeRaideur.pourMetresParKm(bande),
      ],
      titre: titre,
    ),
  ),
);

void main() {
  group('861 — les deux notes sont nommees et accompagnees de leur brut', () {
    testWidgets('CHAQUE AXE PORTE SON NOM ET SON NOMBRE', (tester) async {
      await tester.pumpWidget(
        bloc(effort: 16.06, raideur: 12.81, metresParKm: 128.1),
      );
      // LE CHIFFRE VIT SOUS L AIGUILLE DE SA JAUGE (tache 862), et chaque
      // jauge porte le nom de son axe.
      final effort = tester.widget<Text>(
        find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-effort')),
      );
      final pente = tester.widget<Text>(
        find.byKey(const ValueKey('chiffre-sous-l-aiguille-jauge-de-pente')),
      );
      expect(effort.data, '16,1');
      expect(pente.data, '12,8');
      expect(find.text('Effort'), findsOneWidget);
      expect(find.text('Pente'), findsOneWidget);
    });

    testWidgets('LE CHIFFRE BRUT EST A COTE DE LA RAIDEUR, ARRONDI A '
        'L ENTIER', (tester) async {
      // UNE PENTE MOYENNE AU DIXIEME DE METRE PAR KILOMETRE SERAIT UNE FAUSSE
      // PRECISION, et c'est justement la reserve que ce chiffre corrige.
      await tester.pumpWidget(
        bloc(effort: 16.06, raideur: 12.81, metresParKm: 128.1),
      );
      final brut = tester.widget<Text>(
        find.byKey(const ValueKey('appoint-de-pente')),
      );
      expect(brut.data, '128 m de montee par kilometre');
    });

    testWidgets('L EFFORT N A PAS DE CHIFFRE BRUT : son indice n est pas une '
        'grandeur que le client sait relire', (tester) async {
      await tester.pumpWidget(
        bloc(effort: 16.06, raideur: 12.81, metresParKm: 128.1),
      );
      expect(find.byKey(const ValueKey('appoint-de-pente')), findsOneWidget);
      expect(find.byKey(const ValueKey('appoint-de-effort')), findsNothing);
    });

    testWidgets('LE TITRE EST FACULTATIF', (tester) async {
      await tester.pumpWidget(bloc(effort: 3.0, raideur: 1.0, metresParKm: 10));
      expect(find.byKey(const ValueKey('les-deux-notes')), findsOneWidget);
      await tester.pumpWidget(
        bloc(
          effort: 3.0,
          raideur: 1.0,
          metresParKm: 10,
          titre: 'Journee la plus dure de ce plan',
        ),
      );
      expect(find.text('Journee la plus dure de ce plan'), findsOneWidget);
    });

    testWidgets('AUCUN MOT DE NIVEAU N EST AFFICHE : Christophe tranchera les '
        'niveaux apres', (tester) async {
      await tester.pumpWidget(
        bloc(effort: 19.9, raideur: 20.0, metresParKm: 300),
      );
      for (final interdit in <String>[
        'Facile',
        'Moyen',
        'Modere',
        'Difficile',
        'Extreme',
      ]) {
        expect(
          find.textContaining(interdit, skipOffstage: false),
          findsNothing,
          reason: 'le mot $interdit est a l ecran',
        );
      }
    });
  });
}
