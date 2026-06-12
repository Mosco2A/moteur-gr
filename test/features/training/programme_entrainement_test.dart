import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/training/domain/programme_generator.dart';
import 'package:moteur_gr/features/training/models/programme_entrainement.dart';

void main() {
  group('ProgrammeGenerator.generer — plan J-42 (6 semaines)', () {
    test('genere 3 seances par semaine (18 pour 6 semaines)', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 6,
        niveau: NiveauEntrainement.intermediaire,
      );
      expect(prog.dureeSemaines, 6);
      expect(prog.nbSeances, 18);
    });

    test('chaque semaine contient marche + cardio + renforcement', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 6,
        niveau: NiveauEntrainement.intermediaire,
      );
      // Semaine 1 = jours 0,2,4.
      final s1 = prog.seances.where((s) => s.jourOffset < 7).toList();
      final types = s1.map((s) => s.type).toSet();
      expect(types, containsAll(<TypeSeance>{
        TypeSeance.renforcement,
        TypeSeance.cardio,
        TypeSeance.marche,
      }));
    });

    test('progressivite : la sortie marche s allonge semaine apres semaine', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 6,
        niveau: NiveauEntrainement.debutant,
      );
      final marches = prog.seances
          .where((s) => s.type == TypeSeance.marche)
          .toList()
        ..sort((a, b) => a.jourOffset.compareTo(b.jourOffset));
      for (var i = 1; i < marches.length; i++) {
        expect(marches[i].dureeMin, greaterThan(marches[i - 1].dureeMin));
      }
    });

    test('intensite cardio monte vers la fin du plan', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 6,
        niveau: NiveauEntrainement.avance,
      );
      final cardios = prog.seances
          .where((s) => s.type == TypeSeance.cardio)
          .toList()
        ..sort((a, b) => a.jourOffset.compareTo(b.jourOffset));
      expect(cardios.first.intensite, IntensiteSeance.faible);
      expect(cardios.last.intensite, IntensiteSeance.elevee);
    });

    test('niveau avance demarre avec un volume marche superieur au debutant',
        () {
      final debutant = ProgrammeGenerator.generer(
        dureeSemaines: 4,
        niveau: NiveauEntrainement.debutant,
      );
      final avance = ProgrammeGenerator.generer(
        dureeSemaines: 4,
        niveau: NiveauEntrainement.avance,
      );
      final m1Debutant = debutant.seances
          .firstWhere((s) => s.type == TypeSeance.marche)
          .dureeMin;
      final m1Avance = avance.seances
          .firstWhere((s) => s.type == TypeSeance.marche)
          .dureeMin;
      expect(m1Avance, greaterThan(m1Debutant));
    });

    test('duree invalide (0) ramenee a 1 semaine minimum', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 0,
        niveau: NiveauEntrainement.debutant,
      );
      expect(prog.dureeSemaines, 1);
      expect(prog.nbSeances, 3);
    });
  });

  group('ProgrammeEntrainement — serialisation Freezed', () {
    test('round-trip JSON conserve le plan', () {
      final prog = ProgrammeGenerator.generer(
        dureeSemaines: 2,
        niveau: NiveauEntrainement.intermediaire,
      );
      // Round-trip via une chaine JSON reelle (comme cache/Firestore) :
      // jsonEncode serialise recursivement les seances imbriquees.
      final encoded = jsonEncode(prog.toJson());
      final back = ProgrammeEntrainement.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(back, prog);
      expect(back.seances.first.type, prog.seances.first.type);
    });

    test('SeanceEntrainement serialise type et intensite en JsonValue', () {
      const seance = SeanceEntrainement(
        jourOffset: 0,
        type: TypeSeance.renforcement,
        dureeMin: 30,
        intensite: IntensiteSeance.moderee,
        description: 'x',
      );
      final json = seance.toJson();
      expect(json['type'], 'renforcement');
      expect(json['intensite'], 'moderee');
    });
  });
}
