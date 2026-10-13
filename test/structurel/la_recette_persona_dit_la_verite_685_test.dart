// LA FICHE DE LA RECETTE PERSONA DIT LA VERITE — tache 685.
//
// POURQUOI CETTE GARDE. La recette de lancement (section 12 de
// `integration_test/campagne_v2/CAMPAGNE_V2.md`) est le seul endroit ou un
// operateur — ou un agent — va lire ce qu'il faut faire avant de lancer un
// persona. Les quatre runs perdus les 04 et 05/10 l'ont ete parce que deux
// causes etaient connues de qui les avait mesurees et de personne d'autre : le
// delai fixe de l'accueil et la charge de l'appareil. Une parade qui n'est pas
// dans la fiche est une parade oubliee au prochain run.
//
// CE QU'ELLE EXIGE : que la fiche NOMME les deux causes mesurees, qu'elle porte
// les chiffres qui les prouvent, qu'elle nomme l'image d'emulateur fautive et
// celle qui est recommandee, et que les parametres qu'elle promet existent
// VRAIMENT dans le pilote. Le precedent est
// `codemagic_entete_ne_mente_pas_619_test.dart` et
// `la_doc_ne_mente_pas_645_test.dart` : une doc que rien ne verifie devient
// fausse, et elle devient fausse en silence.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La fiche de la campagne, lue une fois.
final String _fiche = File(
  'integration_test/campagne_v2/CAMPAGNE_V2.md',
).readAsStringSync();

/// Le pilote de runs, lu une fois.
final String _pilote = File('tool/run_persona.ps1').readAsStringSync();

void main() {
  group('LA FICHE NOMME LES DEUX CAUSES MESUREES', () {
    test('cause 1 : le delai fixe de l accueil, avec sa chronologie', () {
      expect(
        _fiche,
        contains('Onboarding absent (deja complete)'),
        reason:
            'la fiche doit citer la phrase exacte que le harnais ecrivait : '
            'c est elle qu on retrouve dans les vieux journaux de run',
      );
      for (final chiffre in const ['07:56:59.158', '07:57:12.972', '13,8 s']) {
        expect(
          _fiche,
          contains(chiffre),
          reason:
              'CHIFFRE PERDU ($chiffre) : sans la chronologie, la cause 1 '
              'redevient une opinion',
        );
      }
      expect(
        _fiche,
        contains('screen:onboarding'),
        reason:
            'la miette d observabilite est ce qui a CONTREDIT le harnais : '
            'elle doit etre nommee',
      );
    });

    test('cause 2 : la charge de l appareil, avec son seuil et son budget', () {
      expect(
        _fiche,
        contains('/proc/loadavg'),
        reason: 'la fiche doit dire OU se lit la charge',
      );
      for (final chiffre in const [
        '1 918 053',
        '1 986 942',
        '-ChargeTimeoutS 600',
      ]) {
        expect(
          _fiche,
          contains(chiffre),
          reason: 'CHIFFRE PERDU ($chiffre) : la cause 2 doit rester mesuree',
        );
      }
    });

    test('la parade PRC-003 et son ORDRE sont ecrits', () {
      expect(_fiche, contains('PRC-003'));
      expect(
        _fiche,
        contains('0 capture pour 52 marqueurs'),
        reason: 'le cout de l incident doit rester lisible',
      );
      expect(
        _fiche,
        contains('`pre-build` -> `gate de charge` -> `demons`'),
        reason:
            'L ORDRE EST LA PARADE : il doit etre ecrit tel quel, pas '
            'devine',
      );
    });
  });

  group('LA FICHE NOMME L IMAGE D EMULATEUR', () {
    test('l image fautive est nommee par son empreinte de build', () {
      expect(
        _fiche,
        contains('UE1A.230829.050'),
        reason:
            'sans l empreinte, personne ne saura si le defaut est encore la '
            'apres une mise a jour du SDK',
      );
      expect(_fiche, contains('bt_stack_manage'));
      expect(
        _fiche,
        contains('ANR in com.google.android.bluetooth'),
        reason: 'la signature a chercher dans le logcat doit etre ecrite',
      );
    });

    test('l image recommandee et le reglage sont dits', () {
      expect(
        _fiche,
        contains('hw.bluetooth=no'),
        reason:
            'la vraie correction est dans l image : le reglage doit etre '
            'nomme, pas seulement la parade',
      );
      expect(
        _fiche,
        contains('IMAGE RECOMMANDEE'),
        reason: 'la fiche doit dire sur quoi rejouer la recette',
      );
    });
  });

  group('CE QUE LA FICHE PROMET EXISTE DANS LE PILOTE', () {
    test('les parametres cites sont de vrais parametres', () {
      for (final param in const [
        'ChargeMax',
        'ChargeTimeoutS',
        'SansCoupureBluetooth',
      ]) {
        expect(_fiche, contains(param), reason: 'la fiche doit citer $param');
        expect(
          _pilote,
          contains('\$$param'),
          reason:
              'LA FICHE PROMET UN PARAMETRE QUI N EXISTE PAS ($param) : '
              'l operateur lancera une commande refusee',
        );
      }
    });

    test('la ligne FIN promise porte bien la charge mesuree', () {
      expect(_fiche, contains('charge_1min='));
      expect(
        _pilote,
        contains('charge_1min='),
        reason:
            'la fiche annonce la charge dans la ligne FIN : le pilote doit '
            'vraiment l y ecrire',
      );
    });

    test('les familles de tolerances annoncees sont dans le fichier', () {
      expect(_fiche, contains('groupe: a b c'));
      final tol = File(
        'integration_test/campagne_v2/captures_doublons_tolerees.txt',
      ).readAsStringSync();
      expect(
        tol,
        contains('groupe:'),
        reason:
            'la fiche annonce des familles : le fichier de tolerances doit '
            'en declarer',
      );
    });
  });

  group('L ETAT DE REFERENCE DU 05/10 EST GRAVE, CHIFFRES COMPRIS', () {
    test('les quatre temps d apparition de l accueil sont ecrits', () {
      // CE QUE CETTE GARDE TIENT. Les quatre runs joues avec le nouveau pilote
      // ont mesure le temps mis par l'accueil a se montrer. TROIS DEPASSENT
      // l'ancien delai fixe de 10 000 ms : c'est la preuve, faite sur la
      // machine, que la cause 1 n'etait pas une opinion. Si ces chiffres
      // disparaissent de la fiche, la demonstration disparait avec eux.
      for (final chiffre in const [
        '9 843 ms',
        '10 543 ms',
        '13 100 ms',
        '13 438 ms',
      ]) {
        expect(
          _fiche,
          contains(chiffre),
          reason:
              'TEMPS D APPARITION PERDU ($chiffre) : sans ces quatre mesures, '
              'personne ne pourra verifier que le delai fixe de 10 s etait '
              'trop court sur cette machine',
        );
      }
    });

    test('les quatre verdicts et le zero run perdu sont dits', () {
      expect(
        _fiche,
        contains('61 / 2'),
        reason: 'l etat de reference de S1 doit rester lisible',
      );
      expect(
        _fiche,
        contains('Zero run perdu'),
        reason:
            'c est la promesse du lot : si elle n est plus ecrite, plus rien '
            'ne dit ce qu on attend d une campagne',
      );
    });

    test('le travail de la gate de charge est chiffre', () {
      expect(
        _fiche,
        contains('229 s'),
        reason:
            'la gate a retenu S3 229 s : un seuil dont on ne mesure jamais '
            'l effet redevient decoratif',
      );
      expect(
        _fiche,
        contains('57/1 au lieu de'),
        reason:
            'le run lance trop tot a rendu 57/1 : c est la contre-preuve, et '
            'elle vaut autant que la preuve',
      );
    });
  });
}
