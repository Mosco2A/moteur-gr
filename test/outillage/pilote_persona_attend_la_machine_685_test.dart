// LE PILOTE DE RUNS PERSONA ATTEND LA MACHINE — tache 685.
//
// CE QUE CE FICHIER EMPECHE DE REVENIR (kaizen #101252, memoire #101219).
//
// 1. LA RECETTE ATTENDAIT LE DISQUE DE L'HOTE, PAS LA CHARGE DE L'APPAREIL.
//    Le 05/10, sur un emulateur encore occupe, un run S1 a rendu TROIS captures
//    d'ecrans DIFFERENTS au contenu IDENTIQUE (12c_faisabilite_verdict_reel =
//    13_retour_cockpit = 14_entrainement, dix secondes et un appui entre les
//    deux) : l'appareil servait une image perimee. Lu sans cette cause, le jeu
//    de captures accusait le produit.
//
// 2. LA PARADE PRC-003 VIVAIT DANS UN PILOTE JETABLE. Le watchdog de la machine
//    abat un `python|node` quand le volume grossit de plus de 5 Go/h, et le
//    premier build Gradle d'un arbre neuf en fait 17 : il a tue le demon de
//    captures le 04/10 a 20:18:55, 0 capture pour 52 marqueurs. Artemis avait
//    pare a la main (pre-construire l'APK avant d'allumer les demons) dans un
//    script jetable — c'est-a-dire oublie au run suivant.
//
// POURQUOI UNE GARDE SUR LA SOURCE DU .ps1. Ce pilote ne tourne QUE devant un
// emulateur : aucun test ne peut l'executer ici. Mais ce qui a casse est
// LISIBLE DANS LE TEXTE — un seuil, un budget, et surtout un ORDRE (le
// pre-build avant le premier demon). C'est exactement ce que cette garde lit.
// Meme procede que `codemagic_entete_ne_mente_pas_619_test.dart`.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La recette de lancement, lue une fois.
final String _pilote = File('tool/run_persona.ps1').readAsStringSync();

/// Position de la premiere occurrence de [quoi], ou -1.
int _ou(String quoi) => _pilote.indexOf(quoi);

void main() {
  group('LE RUN ATTEND QUE L EMULATEUR SOIT CALME', () {
    test('la charge de l appareil est LUE, et au bon endroit', () {
      expect(
        _pilote,
        contains('/proc/loadavg'),
        reason:
            'LA GATE DE CHARGE A DISPARU : sans lecture de /proc/loadavg, le '
            'run repart sur un emulateur occupe et ses captures ne prouvent '
            'plus rien (kaizen #101252).',
      );
      expect(
        _pilote,
        contains('function Wait-ChargeCalme'),
        reason: 'la fonction d attente de la charge a disparu',
      );
    });

    test('le seuil est 3 et le budget 10 minutes', () {
      expect(
        _pilote,
        contains(r'[double]$ChargeMax = 3.0'),
        reason:
            'SEUIL DEPLACE : 3 est le chiffre mesure (4 coeurs vus par le '
            'noyau de l emulateur ; au-dela, un screencap part en retard).',
      );
      expect(
        _pilote,
        contains(r'[int]$ChargeTimeoutS = 600'),
        reason:
            'BUDGET DEPLACE : 10 minutes est la borne demandee. Un budget '
            'illimite fait attendre la campagne sans fin ; un budget trop '
            'court rend la gate decorative.',
      );
    });

    test('l abandon est DIT, explicitement, et pas avale', () {
      expect(
        _pilote,
        contains('CHARGE : ABANDON DE L ATTENTE'),
        reason:
            'A L ABANDON, LA LIGNE DOIT ETRE EXPLICITE : un run joue sur une '
            'machine chargee doit se lire avec ce chiffre, pas se faire '
            'passer pour un run ordinaire.',
      );
      expect(
        _pilote,
        contains('charge_1min='),
        reason:
            'la charge mesuree doit partir dans la ligne FIN du run : c est '
            'la seule facon de relire un verdict de captures en contexte',
      );
    });

    test('la gate ne se desarme que sur demande EXPLICITE', () {
      expect(
        _pilote,
        contains(r'[switch]$SansGateDeCharge'),
        reason: 'la desactivation doit etre un geste nomme, jamais le defaut',
      );
      final i = _ou(r'if ($SansGateDeCharge) {');
      expect(i, greaterThan(0));
      expect(
        _pilote.substring(i, i + 400),
        contains('ne prouveront rien'),
        reason:
            'une gate desarmee doit le dire a l ecran, sinon le run passe '
            'pour mesure',
      );
    });
  });

  group('LA PARADE PRC-003 EST DANS LA RECETTE, PAS DANS UN JETABLE', () {
    test('l APK est pre-construit par le pilote', () {
      expect(
        _pilote,
        contains('function Invoke-PreBuild'),
        reason:
            'PARADE PERDUE : sans pre-build, la rafale d E/S du premier '
            'build Gradle tombe pendant que les demons tournent, et le '
            'watchdog abat le demon de captures (memoire #101219).',
      );
      expect(
        _pilote,
        contains('flutter build apk --debug'),
        reason: 'le pre-build doit vraiment construire quelque chose',
      );
    });

    test('LE PRE-BUILD PASSE AVANT LE PREMIER DEMON — c est tout l objet', () {
      final preBuild = _ou(r'Invoke-PreBuild $repo $Tag');
      final premierDemon = _ou("Start-Demon 'shot'");
      expect(
        preBuild,
        greaterThan(0),
        reason: 'appel du pre-build introuvable',
      );
      expect(premierDemon, greaterThan(0), reason: 'demon de captures absent');
      expect(
        preBuild,
        lessThan(premierDemon),
        reason:
            'ORDRE INVERSE = PARADE ANNULEE. Le watchdog abat un python au '
            'hasard pendant la rafale d E/S : si un demon existe deja, c est '
            'lui qui tombe, et le run est perdu (04/10, 0 capture pour 52 '
            'marqueurs).',
      );
    });

    test('LA GATE DE CHARGE AUSSI PASSE AVANT LE PREMIER DEMON', () {
      final gate = _ou(r'Wait-ChargeCalme $Serial $ChargeMax');
      final premierDemon = _ou("Start-Demon 'shot'");
      expect(gate, greaterThan(0), reason: 'appel de la gate introuvable');
      expect(
        gate,
        lessThan(premierDemon),
        reason:
            'attendre la machine APRES avoir allume les demons les fait '
            'vivre pour rien pendant dix minutes',
      );
    });

    test('le pre-build ne se paie qu une fois par arbre', () {
      final i = _ou('function Invoke-PreBuild');
      expect(i, greaterThan(0));
      final corps = _pilote.substring(i, i + 1200);
      expect(
        corps,
        contains('app-debug.apk'),
        reason:
            'sans test de presence de l APK, chaque run paierait un build '
            'complet : la recette deviendrait trop chere pour etre suivie',
      );
      expect(corps, contains('pre-build saute'));
    });
  });
}
