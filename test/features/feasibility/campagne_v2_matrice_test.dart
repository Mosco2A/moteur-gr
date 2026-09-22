// PREPARATION DE LA CAMPAGNE PERSONAS V2 — tache 541.
//
// CE QUE CE TEST PROUVE, ET POURQUOI IL EXISTE.
// La campagne v2 doit rendre « la LISTE des bascules de verdict une par une »
// (#10-f de `data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md`). Une
// bascule est un COUPLE : le verdict d'AVANT et le verdict d'APRES. Ni l'un ni
// l'autre ne peut etre une valeur recopiee a la main dans un tableau — sinon
// toute la campagne repose sur des chiffres que personne n'a verifies.
//
// Ce test confronte donc les DEUX colonnes de la matrice des 96 combinaisons
// (`integration_test/campagne_v2/matrice_96.json`) au moteur REEL :
//   * colonne AVANT  -> `FeasibilityScale.v1` (bareme historique 100 m, plafonds
//     21/29/39/45), conserve dans le moteur exactement pour cet usage ;
//   * colonne APRES  -> `FeasibilityScale.v2` (unite d'energie 42 m, plafonds
//     re-derives), avec plancher demontre, altitude et chaleur de chaque
//     personnage.
// Si un seul chiffre de l'une des deux colonnes ment, ce test est ROUGE et la
// campagne ne part pas.
//
// Il verifie en outre les proprietes MATHEMATIQUES du score de circuit sur les
// memes 96 cellules — ce sont elles qui ont mis au jour les deux trous remontes
// dans `integration_test/campagne_v2/CAMPAGNE_V2.md` : C2 ne peut JAMAIS mordre,
// et C3 ne depend PAS du randonneur.
//
// AUCUN CODE APPLICATIF N'EST TOUCHE : ce fichier est un test, il lit.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/feasibility/domain/feasibility_formula.dart';

/// Tolerance de comparaison des reels (la matrice est arrondie a 1e-4).
const double kEps = 5e-4;

HikerLevel _levelFromName(String name) => switch (name) {
      'beginner' => HikerLevel.beginner,
      'intermediate' => HikerLevel.intermediate,
      'confirmed' => HikerLevel.confirmed,
      'expert' => HikerLevel.expert,
      _ => throw ArgumentError('niveau inconnu: $name'),
    };

String _verdictName(FeasibilityVerdict v) => switch (v) {
      FeasibilityVerdict.green => 'green',
      FeasibilityVerdict.orange => 'orange',
      FeasibilityVerdict.red => 'red',
    };

String _constraintName(CircuitConstraint c) => switch (c) {
      CircuitConstraint.worstStage => 'C1',
      CircuitConstraint.averageLoad => 'C2',
      CircuitConstraint.rest => 'C3',
      CircuitConstraint.habitGap => 'C4',
    };

List<StageEffort> _stagesOf(Map<String, dynamic> jeu) {
  final rows = (jeu['stages'] as List).cast<Map<String, dynamic>>();
  return [
    for (var i = 0; i < rows.length; i++)
      StageEffort(
        index: i,
        name: 'E${rows[i]['n']}',
        distanceKm: (rows[i]['distanceKm'] as num).toDouble(),
        elevationGainM: (rows[i]['elevationGainM'] as num).toInt(),
      ),
  ];
}

void main() {
  late Map<String, dynamic> matrice;
  late Map<String, dynamic> jeux;
  late Map<String, dynamic> personas;
  late List<Map<String, dynamic>> cellules;

  setUpAll(() {
    // Le test tourne depuis la racine du paquet (convention `flutter test`).
    final f = File('integration_test/campagne_v2/matrice_96.json');
    expect(
      f.existsSync(),
      isTrue,
      reason: 'La matrice de campagne est introuvable : ${f.absolute.path}. '
          'Sans elle la campagne v2 n a ni colonne AVANT ni colonne APRES.',
    );
    matrice = jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;
    jeux = matrice['jeuxEtapes'] as Map<String, dynamic>;
    personas = matrice['personas'] as Map<String, dynamic>;
    cellules = (matrice['cellules'] as List).cast<Map<String, dynamic>>();
  });

  group('Matrice 96 — la forme du plan de campagne', () {
    test('96 cellules, ni une de plus ni une de moins', () {
      expect(cellules.length, 96);
    });

    test('6 personas x 4 jeux d etapes x 4 rangs de forme, sans doublon', () {
      expect(personas.keys.length, 6);
      expect(jeux.keys.length, 4);
      final ids = cellules.map((c) => c['id'] as String).toSet();
      expect(ids.length, 96, reason: 'deux cellules portent le meme identifiant');
      for (final p in personas.keys) {
        for (final j in jeux.keys) {
          for (var r = 0; r < 4; r++) {
            expect(ids.contains('$p-$j-R$r'), isTrue,
                reason: 'cellule $p-$j-R$r absente');
          }
        }
      }
    });

    test('les cas limites #10-e sont dans la matrice : 1 etape et 30 etapes', () {
      expect((jeux['J3']!['stages'] as List).length, 1);
      expect((jeux['J4']!['stages'] as List).length, 30);
    });

    test('la colonne AVANT couvre 1032 ratios d etape', () {
      final total = cellules.fold<int>(
          0, (s, c) => s + (c['v1']['ratios'] as List).length);
      expect(total, 1032, reason: '24 x (7 + 5 + 1 + 30)');
    });
  });

  group('Colonne AVANT — verrouillee sur le moteur reel, bareme v1', () {
    test('le niveau derive de chaque cellule est celui que rend deriveLevel', () {
      final ecarts = <String>[];
      for (final c in cellules) {
        final p = personas[c['profil']] as Map<String, dynamic>;
        final attendu = c['v1']['niveau'] as String;
        final obtenu = FeasibilityFormula.deriveLevel(
          maxElevationGainPerDayDone: (p['maxGainPerDayM'] as num).toDouble(),
          maxDistancePerDayDone: (p['maxDistPerDayKm'] as num).toDouble(),
          age: (p['age'] as num).toInt(),
          fitnessRank: (c['rangForme'] as num).toInt(),
        );
        if (obtenu.name != attendu) {
          ecarts.add('${c['id']} : attendu $attendu, moteur ${obtenu.name}');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.join('\n'));
    });

    test('plafond, scores d etape, verdicts d etape et pire etape', () {
      final ecarts = <String>[];
      for (final c in cellules) {
        final jeu = jeux[c['jeu']] as Map<String, dynamic>;
        final v1 = c['v1'] as Map<String, dynamic>;
        // Bareme v1 : ni plancher demontre, ni altitude, ni chaleur — la V1
        // ne connaissait rien de tout cela.
        final a = FeasibilityFormula.evaluate(
          stages: _stagesOf(jeu),
          level: _levelFromName(v1['niveau'] as String),
          scale: FeasibilityScale.v1,
        );

        final plafondAttendu = (v1['plafond'] as num).toDouble();
        if ((a.dailyCapacityEnergyKm - plafondAttendu).abs() > kEps) {
          ecarts.add('${c['id']} plafond : attendu $plafondAttendu, '
              'moteur ${a.dailyCapacityEnergyKm}');
        }

        final ratios = (v1['ratios'] as List).cast<num>();
        final verdicts = (v1['verdictsEtape'] as List).cast<String>();
        if (a.stageVerdicts.length != ratios.length) {
          ecarts.add('${c['id']} : ${a.stageVerdicts.length} etapes evaluees '
              'contre ${ratios.length} attendues');
          continue;
        }
        for (var i = 0; i < ratios.length; i++) {
          if ((a.stageVerdicts[i].score - ratios[i].toDouble()).abs() > kEps) {
            ecarts.add('${c['id']} etape ${i + 1} score : attendu ${ratios[i]}, '
                'moteur ${a.stageVerdicts[i].score}');
          }
          if (_verdictName(a.stageVerdicts[i].verdict) != verdicts[i]) {
            ecarts.add('${c['id']} etape ${i + 1} verdict : attendu '
                '${verdicts[i]}, moteur ${_verdictName(a.stageVerdicts[i].verdict)}');
          }
        }
        if (a.hardestStageIndex + 1 != (v1['pireEtape'] as num).toInt()) {
          ecarts.add('${c['id']} pire etape : attendu ${v1['pireEtape']}, '
              'moteur ${a.hardestStageIndex + 1}');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(30).join('\n'));
    });

    test('le verdict de circuit AVANT est bien celui de la pire etape', () {
      // La V1 n'avait pas de score de circuit : son verdict global ETAIT la
      // couleur de la pire etape. Sur le moteur d'aujourd'hui, cette grandeur
      // survit sous le nom C1 (`circuit.worstStage`).
      final ecarts = <String>[];
      for (final c in cellules) {
        final jeu = jeux[c['jeu']] as Map<String, dynamic>;
        final v1 = c['v1'] as Map<String, dynamic>;
        final a = FeasibilityFormula.evaluate(
          stages: _stagesOf(jeu),
          level: _levelFromName(v1['niveau'] as String),
          scale: FeasibilityScale.v1,
        );
        final c1 = a.circuit!.worstStage;
        if ((c1 - (v1['C1'] as num).toDouble()).abs() > kEps) {
          ecarts.add('${c['id']} C1 : attendu ${v1['C1']}, moteur $c1');
        }
        final couleur =
            _verdictName(FeasibilityThresholds.median.verdictFor(c1));
        if (couleur != v1['verdictCircuit']) {
          ecarts.add('${c['id']} circuit : attendu ${v1['verdictCircuit']}, '
              'moteur $couleur');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(30).join('\n'));
    });
  });

  group('Colonne APRES — confrontee au moteur v2 reel', () {
    /// Evalue une cellule avec TOUS les termes v2 : plancher demontre (#2-g),
    /// altitude du jeu (#2-h), saison du depart du personnage (#2-i).
    FeasibilityAssessment evaluerV2(Map<String, dynamic> c) {
      final jeu = jeux[c['jeu']] as Map<String, dynamic>;
      final p = personas[c['profil']] as Map<String, dynamic>;
      return FeasibilityFormula.evaluate(
        stages: _stagesOf(jeu),
        level: _levelFromName(c['v2']['niveau'] as String),
        demonstratedFloorEnergyKm: (p['eMaxRealise'] as num).toDouble(),
        conditions: TrekConditions(
          maxAltitudeM: (jeu['aMaxM'] as num).toDouble(),
          season: p['saison'] as String,
        ),
      );
    }

    test('capacite du jour : plafond, plancher demontre, altitude et chaleur',
        () {
      final ecarts = <String>[];
      for (final c in cellules) {
        final a = evaluerV2(c);
        final v2 = c['v2'] as Map<String, dynamic>;
        if ((a.levelCeilingEnergyKm - (v2['cNiveau'] as num)).abs() > kEps) {
          ecarts.add('${c['id']} C_niveau : attendu ${v2['cNiveau']}, '
              'moteur ${a.levelCeilingEnergyKm}');
        }
        if ((a.dailyCapacityEnergyKm - (v2['cJour'] as num)).abs() > kEps) {
          ecarts.add('${c['id']} C_jour : attendu ${v2['cJour']}, '
              'moteur ${a.dailyCapacityEnergyKm}');
        }
        if ((a.conditions.altitudeFactor - (v2['kAltitude'] as num)).abs() >
            kEps) {
          ecarts.add('${c['id']} k_altitude : attendu ${v2['kAltitude']}, '
              'moteur ${a.conditions.altitudeFactor}');
        }
        if ((a.conditions.heatFactor - (v2['kChaleur'] as num)).abs() > kEps) {
          ecarts.add('${c['id']} k_chaleur : attendu ${v2['kChaleur']}, '
              'moteur ${a.conditions.heatFactor}');
        }
        final plancherActif =
            a.dailyCapacityEnergyKm > a.levelCeilingEnergyKm *
                a.conditions.altitudeFactor * a.conditions.heatFactor + kEps;
        if (plancherActif != (v2['plancherActif'] as bool)) {
          ecarts.add('${c['id']} plancher demontre : attendu '
              '${v2['plancherActif']}, moteur $plancherActif');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(30).join('\n'));
    });

    test('scores et verdicts d etape', () {
      final ecarts = <String>[];
      for (final c in cellules) {
        final a = evaluerV2(c);
        final ratios = (c['v2']['ratios'] as List).cast<num>();
        final verdicts = (c['v2']['verdictsEtape'] as List).cast<String>();
        for (var i = 0; i < ratios.length; i++) {
          if ((a.stageVerdicts[i].score - ratios[i].toDouble()).abs() > kEps) {
            ecarts.add('${c['id']} etape ${i + 1} : attendu ${ratios[i]}, '
                'moteur ${a.stageVerdicts[i].score}');
          }
          if (_verdictName(a.stageVerdicts[i].verdict) != verdicts[i]) {
            ecarts.add('${c['id']} etape ${i + 1} verdict : attendu '
                '${verdicts[i]}, moteur ${_verdictName(a.stageVerdicts[i].verdict)}');
          }
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(30).join('\n'));
    });

    test('C1, C2, C3, contrainte dominante et verdict de circuit', () {
      final ecarts = <String>[];
      for (final c in cellules) {
        final a = evaluerV2(c);
        final v2 = c['v2'] as Map<String, dynamic>;
        final circuit = a.circuit!;
        if ((circuit.worstStage - (v2['C1'] as num)).abs() > kEps) {
          ecarts.add('${c['id']} C1 : attendu ${v2['C1']}, '
              'moteur ${circuit.worstStage}');
        }
        if ((circuit.averageLoad - (v2['C2'] as num)).abs() > kEps) {
          ecarts.add('${c['id']} C2 : attendu ${v2['C2']}, '
              'moteur ${circuit.averageLoad}');
        }
        final c3Attendu = v2['C3'] as num?;
        if (c3Attendu == null) {
          if (circuit.rest != null) {
            ecarts.add('${c['id']} C3 : attendu NON APPLICABLE, '
                'moteur ${circuit.rest}');
          }
        } else if (circuit.rest == null ||
            (circuit.rest! - c3Attendu).abs() > kEps) {
          ecarts.add('${c['id']} C3 : attendu $c3Attendu, '
              'moteur ${circuit.rest}');
        }
        if (_constraintName(circuit.dominant) != v2['contrainteDominante']) {
          ecarts.add('${c['id']} dominante : attendu '
              '${v2['contrainteDominante']}, moteur ${_constraintName(circuit.dominant)}');
        }
        if (_verdictName(circuit.verdict) != v2['verdictCircuit']) {
          ecarts.add('${c['id']} circuit : attendu ${v2['verdictCircuit']}, '
              'moteur ${_verdictName(circuit.verdict)}');
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(30).join('\n'));
    });
  });

  group('Proprietes du score de circuit — mesurees, pas supposees', () {
    test('INVARIANT DE STRUCTURE : C2 <= C1 sur toutes les combinaisons', () {
      // CE N EST PAS UN ECHANTILLON, C EST UNE DEMONSTRATION. C2 est la MOYENNE
      // des energies, C1 leur MAXIMUM, normalises par le MEME plafond : une
      // moyenne n est jamais superieure a un maximum, donc C2 <= C1 par
      // construction, avec egalite seulement si toutes les etapes sont egales.
      // C2 est donc REDONDANTE dans un maximum.
      //
      // CORRECTION ACTEE LE 22/09 : S_circuit = max(C1 ; C3). C2 sort du
      // maximum et passe en AFFICHAGE, meme statut que C4 ; l exigence #10-b
      // porte desormais sur DEUX contraintes dominantes, pas trois.
      //
      // POURQUOI UN INVARIANT ET NON UN CONSTAT DE DOMINANCE : un constat dit
      // « C2 n a pas mordu sur mes 96 cellules », ce qui ne vaut que pour cet
      // echantillon. L invariant dit « C2 NE PEUT PAS mordre », et il rougira
      // le jour ou quelqu un changera le normalisateur de C2 sans revoir la
      // redondance. C est la protection, pas la mesure, qui a de la valeur.
      final fautifs = <String>[];
      for (final c in cellules) {
        final v2 = c['v2'] as Map<String, dynamic>;
        if ((v2['C2'] as num) > (v2['C1'] as num) + kEps) {
          fautifs.add('${c['id']} C2=${v2['C2']} > C1=${v2['C1']}');
        }
      }
      expect(fautifs, isEmpty, reason: fautifs.join('\n'));
      expect(matrice['constats']['invariantC2infOuEgalC1'], isTrue);

      // Meme invariant sur le MOTEUR, tous jeux x tous niveaux, avec et sans
      // jours de repos — c est la ou un normalisateur change se verrait.
      for (final jeu in jeux.values.cast<Map<String, dynamic>>()) {
        for (final level in HikerLevel.values) {
          for (final repos in <Set<int>>[const {}, const {1}, const {0, 2}]) {
            final a = FeasibilityFormula.evaluate(
              stages: _stagesOf(jeu),
              level: level,
              restAfterStageIndex: repos,
            );
            expect(a.circuit!.averageLoad,
                lessThanOrEqualTo(a.circuit!.worstStage + kEps),
                reason: 'moteur : C2 > C1 sur ${jeu['nom']} / ${level.name}');
            expect(a.circuit!.dominant, isNot(CircuitConstraint.averageLoad),
                reason: 'C2 ne doit jamais etre la contrainte retenue');
          }
        }
      }
    });

    test('GO-61 : la contrainte dominante ne peut plus etre que C1', () {
      // S_circuit = C1. C2 etait deja sortie du maximum (une moyenne ne depasse
      // pas le maximum de sa serie) ; C3 en est sortie a son tour, parce qu elle
      // etait la seule grandeur EXTRAPOLEE du modele (#M08) a garder le droit de
      // mettre au rouge. Il ne reste donc qu une contrainte decisive.
      expect(
          (matrice['constats']['contraintesDominantesPossibles'] as List)
              .cast<String>()
              .toSet(),
          {'C1'});
      for (final c in cellules) {
        expect(c['v2']['contrainteDominante'], 'C1', reason: c['id'] as String);
      }
      // Et sur le MOTEUR, tous jeux x tous niveaux x plusieurs programmes de
      // repos : aucune autre contrainte ne peut prendre la main.
      for (final jeu in jeux.values.cast<Map<String, dynamic>>()) {
        for (final level in HikerLevel.values) {
          for (final repos in <Set<int>>[const {}, const {1}, const {0, 2}]) {
            final a = FeasibilityFormula.evaluate(
              stages: _stagesOf(jeu),
              level: level,
              restAfterStageIndex: repos,
            );
            expect(a.circuit!.dominant, CircuitConstraint.worstStage,
                reason: 'moteur : ${jeu['nom']} / ${level.name} / $repos');
            expect(a.circuit!.score, closeTo(a.circuit!.worstStage, 1e-12));
            expect(a.isCircuitHarsherThanStages, isFalse,
                reason: 'plus aucun mecanisme ne durcit un circuit');
          }
        }
      }
    });

    test('TROU 2 : C3 ne depend pas du randonneur — une valeur par jeu d etapes',
        () {
      // monotonie = moyenne / ecart-type des MEMES charges : la capacite du jour
      // est un facteur commun au numerateur et au denominateur, elle se
      // simplifie exactement. C3 ne contient donc aucune trace du randonneur.
      for (final j in jeux.keys) {
        final valeurs =
            cellules.where((c) => c['jeu'] == j).map((c) => c['v2']['C3']).toSet();
        expect(valeurs.length, 1,
            reason: 'jeu $j : C3 devrait etre constante, vu $valeurs');
      }
    });

    test('ARTEFACT C3 LEVE : la colonne decrit l ETAT PAR DEFAUT du produit',
        () {
      // Le cablage des jours de repos est livre (commit 5154813) : le provider
      // traduit le vrai programme en index d etapes. La colonne C3 n est donc
      // plus un artefact — elle decrit l etat PAR DEFAUT, celui ou aucun jour
      // de repos n est pose dans le programme, qui est exactement ce que le
      // produit rend a l ouverture.
      expect(matrice['meta']['C3_PROVISOIRE'], isFalse);
      expect(matrice['meta']['C3_statut'], contains('ARTEFACT LEVE'));
      for (final c in cellules) {
        expect(c['v2']['joursDeRepos'], 0,
            reason: '${c['id']} : la colonne de base est l etat sans repos');
        expect(c['v2']['avecDeuxRepos'], isNotNull,
            reason: '${c['id']} : le contrefactuel a deux repos doit exister');
      }
    });

    test('LE COUPLE DE CHIFFRES DU REPOS PAR DEFAUT, verifie sur le moteur',
        () {
      // LA QUESTION POSEE : combien de cellules sont ROUGES par le SEUL fait
      // qu aucun jour de repos n est pose, et combien le restent avec deux ?
      // C est ce couple qui permet d arbitrer s il faut proposer les repos par
      // defaut. On ne le lit pas dans la matrice : on le RECALCULE sur le
      // moteur, cellule par cellule.
      var rougesSansRepos = 0;
      var rougesAvecDeuxRepos = 0;
      final ecarts = <String>[];
      for (final c in cellules) {
        final jeu = jeux[c['jeu']] as Map<String, dynamic>;
        final p = personas[c['profil']] as Map<String, dynamic>;
        final stages = _stagesOf(jeu);
        final level = _levelFromName(c['v2']['niveau'] as String);
        final conditions = TrekConditions(
          maxAltitudeM: (jeu['aMaxM'] as num).toDouble(),
          season: p['saison'] as String,
        );
        final floor = (p['eMaxRealise'] as num).toDouble();

        final sansRepos = FeasibilityFormula.evaluate(
          stages: stages,
          level: level,
          demonstratedFloorEnergyKm: floor,
          conditions: conditions,
        );
        // Deux repos, repartis comme la matrice les pose (semantique moteur :
        // APRES une etape, jamais apres la derniere).
        final apres = ((c['v2']['avecDeuxRepos'] as Map)['reposPosesApres']
                as List)
            .cast<num>()
            .map((n) => n.toInt() - 1)
            .toSet();
        final avecRepos = FeasibilityFormula.evaluate(
          stages: stages,
          level: level,
          demonstratedFloorEnergyKm: floor,
          conditions: conditions,
          restAfterStageIndex: apres,
        );

        if (_verdictName(sansRepos.circuit!.verdict) != c['v2']['verdictCircuit']) {
          ecarts.add('${c['id']} sans repos : matrice '
              '${c['v2']['verdictCircuit']}, moteur '
              '${_verdictName(sansRepos.circuit!.verdict)}');
        }
        final attenduR2 = (c['v2']['avecDeuxRepos'] as Map)['verdictCircuit'];
        if (_verdictName(avecRepos.circuit!.verdict) != attenduR2) {
          ecarts.add('${c['id']} avec 2 repos : matrice $attenduR2, moteur '
              '${_verdictName(avecRepos.circuit!.verdict)}');
        }
        if (sansRepos.circuit!.verdict == FeasibilityVerdict.red) {
          rougesSansRepos++;
        }
        if (avecRepos.circuit!.verdict == FeasibilityVerdict.red) {
          rougesAvecDeuxRepos++;
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(20).join(' | '));

      // CE QUE LE COUPLE DE CHIFFRES EST DEVENU (GO-61). Il avait une fonction
      // precise : montrer combien de cellules etaient rouges par le SEUL manque
      // de repos. Il l a remplie — 36 sur 96, dont un profil confirme a 0,68 de
      // pire etape — et c est cette mesure qui a fait sortir C3 du verdict.
      // Desormais le nombre de repos poses ne change AUCUN verdict : les deux
      // comptes sont donc EGAUX, et cette egalite est la propriete a verrouiller.
      expect(rougesSansRepos, rougesAvecDeuxRepos,
          reason: 'le repos ne doit plus faire basculer une seule couleur');
      expect(rougesSansRepos, 25,
          reason: 'rouges par la pire etape, repos ou pas');

      final constat = matrice['constats']['REPOS_PAR_DEFAUT'] as Map;
      expect(constat['rougesSousLaRegleEnVigueur'], rougesSansRepos);
      expect(constat['rougesUNIQUEMENT_faute_de_repos_ancienneRegle'], 36,
          reason: 'la mesure historique est conservee, elle a fonde GO-61');
    });

    test('LE REPOS NE DECIDE PLUS, ET LE VERDICT DISCRIMINE (GO-61)', () {
      // LE CAS QUI A TOUT DECLENCHE. Sur Mare a Mare Centre, 7 etapes sans
      // repos : monotonie 4,04, C3 = 2,02. L expert, dont la pire etape est a
      // 0,54 — VERT FRANC — recevait un circuit ROUGE. Il recoit desormais le
      // verdict de ses etapes, et le chiffre du repos reste affiche, au-dessus
      // de son seuil, en CONSEIL.
      final sansRepos = FeasibilityFormula.evaluate(
        stages: _stagesOf(jeux['J1'] as Map<String, dynamic>),
        level: HikerLevel.expert,
      );
      expect(
          _verdictName(FeasibilityThresholds.median
              .verdictFor(sansRepos.circuit!.worstStage)),
          'green',
          reason: 'la pire etape de l expert est verte franche');
      expect(sansRepos.circuit!.monotony, closeTo(4.04, 0.01));
      expect(sansRepos.circuit!.rest, closeTo(2.0197, kEps));
      expect(sansRepos.circuit!.dominant, CircuitConstraint.worstStage);
      expect(_verdictName(sansRepos.circuit!.verdict), 'green');
      // ET IL CONSEILLE : deux jours de repos, apres les etapes 2 et 5.
      expect(sansRepos.isRestAdvised, isTrue);
      expect(sansRepos.recommendedRestAfterStageIndex, {1, 4});

      final avecRepos = FeasibilityFormula.evaluate(
        stages: _stagesOf(jeux['J1'] as Map<String, dynamic>),
        level: HikerLevel.expert,
        restAfterStageIndex: const {1, 4},
      );
      expect(_verdictName(avecRepos.circuit!.verdict), 'green');
      expect(avecRepos.restDaysPlanned, 2);
      // La monotonie tombe de 4,04 a 1,53, donc C3 de 2,02 a 0,77 : sous son
      // seuil. Le VERDICT, lui, n a pas bouge d un chiffre — c est exactement
      // ce que GO-61 demande.
      expect(avecRepos.circuit!.monotony, closeTo(1.535, 0.01));
      expect(avecRepos.circuit!.rest, closeTo(0.7675, kEps));
      expect(avecRepos.circuit!.score, closeTo(sansRepos.circuit!.score, 1e-12));
      expect(avecRepos.isRestAdvised, isFalse);

      // ET LA DISCRIMINATION REVIENT, c est le point. Meme sentier, meme
      // programme : le debutant est ROUGE par sa pire etape (C1 = 1,40) la ou
      // l expert est VERT. La contrainte qui decide redevient dependante du
      // randonneur, ce que C3 seule ne pouvait pas faire.
      final debutant = FeasibilityFormula.evaluate(
        stages: _stagesOf(jeux['J1'] as Map<String, dynamic>),
        level: HikerLevel.beginner,
        restAfterStageIndex: const {1, 4},
      );
      expect(_verdictName(debutant.circuit!.verdict), 'red');
      expect(debutant.circuit!.dominant, CircuitConstraint.worstStage);
      expect(debutant.circuit!.worstStage, closeTo(1.4015, kEps));
    });

    test('TABLE DE RE-MESURE : C3 par nombre de jours de repos, verifiee sur le '
        'moteur', () {
      // C est cette table que la campagne lira apres le cablage, au lieu de
      // recalculer. Elle doit donc etre exacte au chiffre pres, sur le moteur.
      final ecarts = <String>[];
      for (final entree in jeux.entries) {
        final jeu = entree.value as Map<String, dynamic>;
        final table = jeu['c3ParNombreDeRepos'] as Map<String, dynamic>;
        final placements = jeu['reposPosesApresLesEtapes'] as Map<String, dynamic>;
        for (final r in table.keys) {
          final apres = (placements[r] as List)
              .cast<num>()
              .map((n) => n.toInt() - 1)
              .toSet();
          final a = FeasibilityFormula.evaluate(
            stages: _stagesOf(jeu),
            level: HikerLevel.intermediate,
            restAfterStageIndex: apres,
          );
          final attendu = table[r] as num?;
          final obtenu = a.circuit!.rest;
          if (attendu == null) {
            if (obtenu != null) {
              ecarts.add('${entree.key} $r repos : attendu NON APPLICABLE, '
                  'moteur $obtenu');
            }
          } else if (obtenu == null || (obtenu - attendu).abs() > kEps) {
            ecarts.add('${entree.key} $r repos : attendu $attendu, '
                'moteur $obtenu');
          }
        }
      }
      expect(ecarts, isEmpty, reason: ecarts.take(20).join('\n'));
    });

    test('ECART PLANIFICATEUR / MOTEUR : le repos se pose AVANT chez l un, '
        'APRES chez l autre', () {
      // PlanningCalculator._computeRestPositions pose un repos AVANT une etape ;
      // FeasibilityFormula.dailyLoads le pose APRES, et IGNORE un repos demande
      // apres la derniere etape. Les deux ne produisent donc pas la meme serie.
      // Sur un sentier d UNE etape elles divergent meme totalement : cote
      // planning la serie devient [0, E] et la monotonie vaut 1 ; cote moteur
      // elle reste [E] et la monotonie est NON APPLICABLE.
      // C est la semantique du MOTEUR qui fait foi, puisque c est elle qui rend
      // le verdict — mais le cablage doit traduire, pas recopier.
      final uneEtape = _stagesOf(jeux['J3'] as Map<String, dynamic>);
      for (final repos in <Set<int>>[const {}, const {0}, const {0, 1}]) {
        final a = FeasibilityFormula.evaluate(
          stages: uneEtape,
          level: HikerLevel.intermediate,
          restAfterStageIndex: repos,
        );
        expect(a.circuit!.rest, isNull,
            reason: 'un sentier d une etape ne peut pas recevoir de jour de '
                'repos cote moteur, quoi qu on lui demande');
      }
      // Et la preuve que le moteur ignore bien le repos apres la DERNIERE etape.
      final j1 = _stagesOf(jeux['J1'] as Map<String, dynamic>);
      final apresDerniere = FeasibilityFormula.evaluate(
        stages: j1,
        level: HikerLevel.intermediate,
        restAfterStageIndex: {j1.length - 1},
      );
      final sansRien = FeasibilityFormula.evaluate(
        stages: j1,
        level: HikerLevel.intermediate,
      );
      expect(apresDerniere.circuit!.rest, sansRien.circuit!.rest);
    });

    test('CONSTAT DE DUREE : enonce factuel, JAMAIS un verdict', () {
      // Le moteur affiche « ce trek dure N jours de marche, ta plus longue
      // sortie enchainee est de M jours ». C est un CONSTAT, parce qu aucun
      // seuil publie ne permet de scorer la duree cumulee (#M06).
      // CE QUI EST VERIFIE ICI : faire varier M de 0 a 40 ne doit changer AUCUNE
      // sortie decisionnelle. Si un jour la duree se met a peser, ce test rougit.
      final stages = _stagesOf(jeux['J1'] as Map<String, dynamic>);
      FeasibilityAssessment evaluerAvec(int jours) =>
          FeasibilityFormula.evaluate(
            stages: stages,
            level: HikerLevel.intermediate,
            longestConsecutiveDaysDone: jours,
            restAfterStageIndex: const {1, 4},
          );

      final reference = evaluerAvec(0);
      for (final m in <int>[1, 2, 3, 7, 12, 17, 40]) {
        final a = evaluerAvec(m);
        expect(_verdictName(a.globalVerdict), _verdictName(reference.globalVerdict),
            reason: 'le verdict global bouge avec la duree deja realisee ($m)');
        expect(a.circuit!.score, closeTo(reference.circuit!.score, 1e-12),
            reason: 'le score de circuit bouge avec la duree ($m)');
        expect(a.circuit!.dominant, reference.circuit!.dominant);
        expect(a.limitingFactor, reference.limitingFactor);
        expect(a.recommendedTrainingWeeks, reference.recommendedTrainingWeeks);
        expect(a.dailyCapacityEnergyKm,
            closeTo(reference.dailyCapacityEnergyKm, 1e-12));
        expect(a.suggestedDays, reference.suggestedDays);
        expect(a.stageVerdicts.map((v) => _verdictName(v.verdict)).toList(),
            reference.stageVerdicts.map((v) => _verdictName(v.verdict)).toList());
        // Et le constat lui-meme reste disponible et honnete.
        expect(a.longestConsecutiveDaysDone, m);
        expect(a.walkingDays, stages.length);
        expect(a.hasDurationStatement, isTrue);
      }
      // Duree inconnue : on ne l enonce pas, on n invente pas un zero parlant.
      expect(reference.hasDurationStatement, isFalse,
          reason: 'sans donnee, le constat ne doit pas etre enonce');
    });

    test('CAS LIMITE #10-e : sur un sentier d UNE etape, C3 est NON APPLICABLE',
        () {
      for (final c in cellules.where((c) => c['jeu'] == 'J3')) {
        expect(c['v2']['C3applicable'], isFalse, reason: c['id'] as String);
        expect(c['v2']['C3'], isNull, reason: c['id'] as String);
        expect(c['v2']['contrainteDominante'], isNot('C3'),
            reason: '${c['id']} : une contrainte non calculable ne peut decider');
      }
      expect(jeux['J3']!['reposMinimumPourVert'], 'sans-objet');
      // Et sur le moteur reel : pas de NaN, pas d Infinity, pas de zero affiche.
      final a = FeasibilityFormula.evaluate(
        stages: _stagesOf(jeux['J3'] as Map<String, dynamic>),
        level: HikerLevel.intermediate,
      );
      expect(a.circuit!.rest, isNull);
      expect(a.circuit!.monotony, isNull);
      expect(a.circuit!.dominant, isNot(CircuitConstraint.rest));
      expect(a.circuit!.score.isFinite, isTrue);
    });

    test('CAS LIMITE #10-e : sur 30 etapes, la PIRE fenetre de 7 jours est '
        'retenue et nommee', () {
      for (final c in cellules.where((c) => c['jeu'] == 'J4')) {
        expect(c['v2']['fenetreMonotonie'], startsWith('jours '),
            reason: '${c['id']} : la fenetre retenue doit etre nommee');
      }
      final a = FeasibilityFormula.evaluate(
        stages: _stagesOf(jeux['J4'] as Map<String, dynamic>),
        level: HikerLevel.confirmed,
      );
      expect(a.circuit!.monotonyWindowStartDay, isNotNull);
      expect(a.circuit!.monotonyWindowEndDay, isNotNull);
      expect(
          a.circuit!.monotonyWindowEndDay! -
              a.circuit!.monotonyWindowStartDay! +
              1,
          7);
    });

    test('CONSEQUENCE CHIFFREE DE GO-61 : de 78 cellules rouges a 25', () {
      // TROIS CHIFFRES A NE PAS CONFONDRE. 42 rouges en v1 ; 78 sous la regle
      // max(C1 ; C3), dont 24 sur 24 sur le sentier de PRODUCTION, expert
      // compris — c est ce qui a fait dire a Chris « le Mare a Mare est rouge
      // pour tout le monde » ; 25 sous la regle en vigueur, ou seul C1 decide.
      expect(matrice['constats']['cellulesCircuitRougeV1'], 42);
      expect(matrice['constats']['cellulesCircuitRouge'], 25);
      expect(
          (matrice['constats']['REPOS_PAR_DEFAUT']
              as Map)['rougesSansAucunRepos_ancienneRegle'],
          78);
      // Et sur le sentier de production, le verdict DISCRIMINE de nouveau : ni
      // tout rouge, ni tout vert.
      final j1 = cellules.where((c) => c['jeu'] == 'J1').toList();
      expect(j1.length, 24);
      final rougesJ1 =
          j1.where((c) => c['v2']['verdictCircuit'] == 'red').length;
      expect(rougesJ1, greaterThan(0));
      expect(rougesJ1, lessThan(24));
    });

    test('TOUT allegement vient du plancher demontre, aucun d ailleurs', () {
      // 214 allegements sur 452 bascules (389 d etape et 63 de circuit, ces
      // dernieres recalculees apres GO-61 : le verdict du circuit est celui de
      // sa pire etape). Pas un seul allegement ne survient dans une cellule ou
      // le plancher #2-g est inactif : sur ces quatre jeux d etapes, l unite
      // d energie et les plafonds re-derives ne font que DURCIR.
      final cellulesParId = {for (final c in cellules) c['id'] as String: c};
      final bascules = (matrice['bascules'] as List).cast<Map<String, dynamic>>();
      final orphelins = bascules
          .where((f) => f['sens'] == 'ALLEGE')
          .where((f) => cellulesParId[f['cellule']]!['v2']['plancherActif'] != true)
          .map((f) => f['cellule'] as String)
          .toList();
      expect(orphelins, isEmpty,
          reason: 'allegement sans plancher actif : ${orphelins.take(10)}');
      expect(bascules.where((f) => f['sens'] == 'ALLEGE').length, 214);
      expect(bascules.length, 452);
      expect(bascules.where((f) => f['portee'] == 'circuit').length, 63);
    });

    test('COUVERTURE : les 96 n atteignent jamais le niveau EXPERT', () {
      // Constat, pas defaut du produit : aucun des six personnages de Christophe
      // ne derive en expert, quel que soit son rang de forme. C est pour cela
      // que le banc des 4 niveaux existe en annexe, HORS des 96.
      final niveaux = (matrice['constats']['niveauxAtteintsParLes96'] as List)
          .cast<String>()
          .toSet();
      expect(niveaux.contains('expert'), isFalse);
      final annexe =
          (matrice['annexeNiveaux'] as List).cast<Map<String, dynamic>>();
      expect(annexe.map((n) => n['niveau']).toSet(),
          {'beginner', 'intermediate', 'confirmed', 'expert'});
    });

    test('le banc des 4 niveaux est verrouille sur le moteur reel', () {
      final annexe =
          (matrice['annexeNiveaux'] as List).cast<Map<String, dynamic>>();
      expect(annexe.length, 4, reason: '#10-b exige les QUATRE niveaux');
      for (final n in annexe) {
        final jeu = jeux[n['jeu']] as Map<String, dynamic>;
        final level = _levelFromName(n['niveau'] as String);
        final av = FeasibilityFormula.evaluate(
          stages: _stagesOf(jeu),
          level: level,
          scale: FeasibilityScale.v1,
        );
        expect(
            _verdictName(
                FeasibilityThresholds.median.verdictFor(av.circuit!.worstStage)),
            n['v1']['verdictCircuit'],
            reason: 'banc ${n['niveau']} AVANT');
        expect(av.dailyCapacityEnergyKm,
            closeTo((n['v1']['plafond'] as num).toDouble(), kEps));

        final ap = FeasibilityFormula.evaluate(
          stages: _stagesOf(jeu),
          level: level,
          conditions: TrekConditions(
            maxAltitudeM: (jeu['aMaxM'] as num).toDouble(),
            season: FeasibilitySeason.autumn,
          ),
        );
        expect(_verdictName(ap.circuit!.verdict), n['v2']['verdictCircuit'],
            reason: 'banc ${n['niveau']} APRES');
      }
    });
  });

  group('Couverture exigee par #10-b', () {
    test('le plancher demontre est actif ET inactif dans la matrice', () {
      final actifs = cellules.where((c) => c['v2']['plancherActif'] == true).length;
      expect(actifs, greaterThan(0));
      expect(actifs, lessThan(96));
    });

    test('k_altitude est actif ET neutre dans la matrice', () {
      final ks = cellules.map((c) => c['v2']['kAltitude'] as num).toSet();
      expect(ks.any((k) => k == 1.0), isTrue, reason: 'aucun jeu a altitude neutre');
      expect(ks.any((k) => k < 1.0), isTrue, reason: 'aucun jeu a altitude active');
    });

    test('k_chaleur est actif ET neutre dans la matrice', () {
      final ks = cellules.map((c) => c['v2']['kChaleur'] as num).toSet();
      expect(ks, containsAll(<num>[1.0, 0.93]));
    });

    test('AUCUN persona ne part en hiver : le cas #1-e sort de la matrice', () {
      // Les six dates de depart de Christophe tombent au printemps, en ete ou en
      // automne. Le « verdict declare non valide » ne peut donc PAS etre couvert
      // par les 96 : il lui faut un scenario dedie en famille 3 (F3-2).
      final saisons = cellules.map((c) => c['saison'] as String).toSet();
      expect(saisons.contains('winter'), isFalse);
      expect(saisons, containsAll(<String>['spring', 'summer', 'autumn']));
    });
  });
}
