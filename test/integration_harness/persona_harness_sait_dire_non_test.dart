// LE HARNAIS SAIT-IL DIRE NON ? — tache 543.
//
// LA REGLE QUI FONDE CE FICHIER, posee le 22/09 :
// AVANT DE FAIRE CONFIANCE A UN HARNAIS, ON PROUVE QU'IL SAIT DIRE NON.
// On lui fait passer un cas VOLONTAIREMENT FAUX et on verifie qu'il ROUGIT.
//
// POURQUOI ELLE EXISTE. Les suites S1 a S5 de la campagne N1 contenaient ZERO
// `expect()`. Elles loguaient « COINCE » et concluaient « All tests passed ».
// Elles ne pouvaient PAS echouer, et nous avons cru a une campagne verte qui ne
// testait rien (#100283, mission 1). Un harnais qui ne peut pas echouer est
// pire qu'un harnais absent : il produit de la fausse confiance.
//
// CE FICHIER EST LE CONTRE-POISON. Il n'ouvre aucun ecran et ne demande aucun
// emulateur : il attaque directement la COUCHE D'EXIGENCES du harnais
// (`exige`, `verdictPersona`, `reinitialiserExigences`) et verifie qu'elle
// echoue quand elle doit echouer. Il tourne en `flutter test`, donc il tourne
// a chaque fois, et pas seulement les jours de campagne.
//
// IL EST VERT QUAND LE HARNAIS SAIT ROUGIR : chaque cas attend une
// `TestFailure` et la capture. Un de ces tests qui devient rouge signifie que
// le harnais a PERDU sa capacite a echouer — c'est-a-dire le retour exact du
// defaut d'origine.
library;

import 'package:flutter_test/flutter_test.dart';

import '../../integration_test/persona_harness.dart';

/// Joue [action] et rend la `TestFailure` levee, ou `null` si rien n'a echoue.
TestFailure? echecLeve(void Function() action) {
  try {
    action();
    return null;
  } on TestFailure catch (e) {
    return e;
  }
}

void main() {
  setUp(reinitialiserExigences);
  tearDown(reinitialiserExigences);

  group('LE HARNAIS SAIT DIRE NON', () {
    test('une exigence FAUSSE fait echouer la cloture, et elle est nommee', () {
      // LE CAS VOLONTAIREMENT FAUX.
      exige('AutoTest', 'cas-faux', false,
          'un libelle qui n existe nulle part dans l application');

      final echec = echecLeve(() => verdictPersona('AutoTest'));

      expect(echec, isNotNull,
          reason: 'LE HARNAIS NE SAIT PLUS DIRE NON : une exigence non tenue '
              'n a pas fait echouer la cloture. La campagne ne doit pas partir.');
      expect(echec!.message, contains('un libelle qui n existe nulle part'),
          reason: 'l exigence fautive doit etre NOMMEE dans l echec, sinon '
              'personne ne saura quoi corriger');
      expect(echec.message, contains('AutoTest'),
          reason: 'le personnage concerne doit etre nomme');
    });

    test('une exigence TENUE ne fait echouer personne', () {
      // Contre-preuve : le harnais ne rougit pas a tort. Sans elle, un harnais
      // qui echouerait TOUJOURS passerait le test precedent.
      exige('AutoTest', 'cas-vrai', true, 'une verification qui tient');
      expect(echecLeve(() => verdictPersona('AutoTest')), isNull,
          reason: 'le harnais rougit alors que tout est tenu');
    });

    test('UN SCENARIO QUI NE VERIFIE RIEN EST ROUGE, pas vert', () {
      // C'est le defaut d'origine, teste frontalement : aucune exigence
      // evaluee doit donner un ECHEC, jamais un vert.
      final echec = echecLeve(() => verdictPersona('AutoTest'));
      expect(echec, isNotNull,
          reason: 'HARNAIS AVEUGLE ACCEPTE : un scenario sans aucune exigence '
              'est passe vert. C est exactement le defaut de la campagne N1.');
      expect(echec!.message, contains('HARNAIS AVEUGLE'));
    });

    test('le minimum d exigences est respecte, pas seulement le zero', () {
      // Une suite peut etre aveugle SANS etre vide : trois exigences la ou le
      // scenario en promet quarante, c est un harnais qui a decroche en route.
      for (var i = 0; i < 3; i++) {
        exige('AutoTest', 'pas-$i', true, 'verification $i');
      }
      expect(echecLeve(() => verdictPersona('AutoTest', minimumExigences: 40)),
          isNotNull,
          reason: 'le plancher d exigences ne protege plus');
      expect(echecLeve(() => verdictPersona('AutoTest', minimumExigences: 3)),
          isNull,
          reason: 'le plancher rejette un compte pourtant atteint');
    });

    test('UNE exigence fausse noyee dans vingt vraies fait quand meme rougir',
        () {
      // Le cas realiste : ce n est pas le scenario entier qui casse, c est un
      // point sur vingt. Il doit suffire.
      for (var i = 0; i < 20; i++) {
        exige('AutoTest', 'pas-$i', true, 'verification $i');
      }
      exige('AutoTest', 'pas-13bis', false, 'LA SEULE QUI CASSE');

      final echec = echecLeve(() => verdictPersona('AutoTest'));
      expect(echec, isNotNull,
          reason: 'une exigence fausse sur vingt-et-une est passee inapercue');
      expect(echec!.message, contains('LA SEULE QUI CASSE'));
    });
  });

  group('LA REMISE A ZERO ENTRE SCENARIOS', () {
    test('sans remise a zero, le scenario suivant heriterait de l echec', () {
      // Demonstration du defaut que `reinitialiserExigences` corrige : les
      // compteurs sont GLOBAUX. On le montre explicitement plutot que de le
      // supposer.
      exige('ScenarioA', 'pas', false, 'echec du scenario A');
      expect(kExigencesEchouees, hasLength(1));

      // Sans remise a zero, ScenarioB porterait l echec de ScenarioA.
      final heritage = echecLeve(() => verdictPersona('ScenarioB'));
      expect(heritage, isNotNull);
      expect(heritage!.message, contains('echec du scenario A'),
          reason: 'la fuite entre scenarios doit etre visible ici, sinon ce '
              'test ne demontre rien');

      // Avec remise a zero, ScenarioB repart propre — et redevient aveugle,
      // donc rouge pour SA propre raison, pas pour celle de ScenarioA.
      reinitialiserExigences();
      expect(kExigencesEchouees, isEmpty);
      expect(kExigencesTenues, 0);
      final propre = echecLeve(() => verdictPersona('ScenarioB'));
      expect(propre, isNotNull);
      expect(propre!.message, contains('HARNAIS AVEUGLE'));
      expect(propre.message, isNot(contains('echec du scenario A')));
    });

    test('la remise a zero re-arme le garde anti-harnais-aveugle', () {
      // LE POINT LE PLUS IMPORTANT DE CE GROUPE. Sans remise a zero, le
      // compteur du scenario precedent suffit a franchir le minimum : le garde
      // cense empecher le retour du defaut d origine SE DESARME TOUT SEUL.
      for (var i = 0; i < 40; i++) {
        exige('ScenarioA', 'pas-$i', true, 'verification $i');
      }
      // ScenarioB n evalue RIEN, mais herite des 40 de ScenarioA : il passe.
      expect(echecLeve(() => verdictPersona('ScenarioB', minimumExigences: 40)),
          isNull,
          reason: 'la fuite doit etre visible ici, sinon ce test ne demontre '
              'rien');

      // Avec la remise a zero, ScenarioB est correctement declare aveugle.
      reinitialiserExigences();
      final echec =
          echecLeve(() => verdictPersona('ScenarioB', minimumExigences: 40));
      expect(echec, isNotNull,
          reason: 'le garde anti-harnais-aveugle reste desarme');
      expect(echec!.message, contains('HARNAIS AVEUGLE'));
    });
  });
}
