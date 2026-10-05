// LES DOUBLONS LEGITIMES SONT DECLARES, ET LE CONTROLE RESTE DUR — tache 685.
//
// CE QUE CE FICHIER TIENT (memoire #101219, kaizen #101252). Le controle de fin
// de run refusait S1, S3, S4 et S8 des DEUX cotes de la QA du 645-05c pour des
// captures legitimement identiques : les ticks GPS d'une carte immobile, le
// cockpit hors-ligne, le catalogue de la demo, le cockpit avant/apres un
// dialogue annule. Artemis avait raison de ne pas elargir le fichier a la
// main (« on ne negocie pas avec un rouge pour le faire taire ») : il fallait
// d'abord savoir POURQUOI chaque paire etait identique.
//
// DEUX CHOSES SONT VERIFIEES ICI, ET LA SECONDE EST LA PLUS IMPORTANTE.
//   1. LE FICHIER DE TOLERANCES DIT LA VERITE : chaque declaration porte une
//      raison, les familles sont COMPLETES (sinon le verdict change d'un run a
//      l'autre au gre de l'horloge de la barre d'etat), et les groupes refuses
//      volontairement le restent.
//   2. LE CONTROLE N'EST PAS AFFAIBLI : on le LANCE sur un jeu fabrique et on
//      exige qu'il rougisse sur un doublon non declare, qu'il accepte une
//      famille declaree, et qu'il REFUSE une tolerance sans raison.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le fichier de tolerances, lu une fois.
const String _cheminTolerances =
    'integration_test/campagne_v2/captures_doublons_tolerees.txt';

final String _tolerances = File(_cheminTolerances).readAsStringSync();

/// Une declaration du fichier : sa forme, ses noms, sa raison.
class _Declaration {
  _Declaration(this.ligne, this.famille, this.noms, this.raison);

  final int ligne;
  final bool famille;
  final List<String> noms;
  final String raison;
}

/// Les declarations du fichier, commentaires exclus.
List<_Declaration> get _declarations {
  final out = <_Declaration>[];
  final lignes = _tolerances.split('\n');
  for (var i = 0; i < lignes.length; i++) {
    final morceaux = lignes[i].split('#');
    final corps = morceaux.first.trim();
    if (corps.isEmpty) continue;
    final famille = corps.startsWith('groupe:');
    final noms = (famille ? corps.substring('groupe:'.length) : corps)
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final raison = morceaux.length > 1
        ? morceaux.sublist(1).join('#').trim()
        : '';
    out.add(_Declaration(i + 1, famille, noms, raison));
  }
  return out;
}

/// La famille declaree qui contient [nom], ou null.
_Declaration? _familleDe(String nom) {
  for (final d in _declarations) {
    if (d.famille && d.noms.contains(nom)) return d;
  }
  return null;
}

/// Lance le controle sur un jeu fabrique. Rend le code de sortie et la sortie.
///
/// LE CONTROLE NE DECODE AUCUNE IMAGE : il compare des empreintes d'octets et
/// verifie que le fichier n'est pas vide. Un jeu fabrique de trois « PNG » de
/// quelques octets suffit donc a eprouver sa regle de doublon, sans emulateur
/// et sans la moindre capture reelle.
({int code, String sortie})? _lancerLeControle(String? tolerances) {
  final python = _python();
  if (python == null) return null;
  final bac = Directory.systemTemp.createTempSync('tolerances_685_');
  try {
    final captures = Directory('${bac.path}/captures')..createSync();
    File('${captures.path}/A.png').writeAsBytesSync([1, 2, 3]);
    File('${captures.path}/B.png').writeAsBytesSync([1, 2, 3]); // = A
    File('${captures.path}/C.png').writeAsBytesSync([9, 9, 9]); // != A
    final log = File('${bac.path}/run.log')
      ..writeAsStringSync('PERSONA_SHOT|A\nPERSONA_SHOT|B\nPERSONA_SHOT|C\n');
    final args = <String>[
      'tool/persona_shot_check.py',
      '--log',
      log.path,
      '--captures',
      captures.path,
    ];
    if (tolerances != null) {
      final f = File('${bac.path}/tol.txt')..writeAsStringSync(tolerances);
      args.addAll(['--tolerances', f.path]);
    }
    final r = Process.runSync(python, args);
    return (code: r.exitCode, sortie: '${r.stdout}${r.stderr}');
  } finally {
    bac.deleteSync(recursive: true);
  }
}

/// L'interpreteur Python de la machine, ou null s'il n'y en a pas.
String? _python() {
  for (final nom in const ['python', 'python3', 'py']) {
    try {
      final r = Process.runSync(nom, const ['--version']);
      if (r.exitCode == 0) return nom;
    } on ProcessException {
      continue;
    }
  }
  return null;
}

void main() {
  group('LE FICHIER DE TOLERANCES DIT POURQUOI', () {
    test('chaque declaration porte une raison ecrite', () {
      final muettes = _declarations
          .where((d) => d.raison.isEmpty)
          .map((d) => 'ligne ${d.ligne} : ${d.noms.join(" ")}')
          .toList();
      expect(
        muettes,
        isEmpty,
        reason:
            'TOLERANCE MUETTE : une paire declaree sans raison ne se relit '
            'pas, donc ne se leve jamais. ${muettes.join(" | ")}',
      );
    });

    test('une famille s ecrit « groupe: », une paire a deux noms', () {
      final malFormees = _declarations
          .where((d) => !d.famille && d.noms.length != 2)
          .map((d) => 'ligne ${d.ligne} : ${d.noms.length} noms')
          .toList();
      expect(
        malFormees,
        isEmpty,
        reason:
            'une ligne de paire qui porte trois noms en tolere deux et oublie '
            'la troisieme sans le dire : ${malFormees.join(" | ")}',
      );
    });
  });

  group('LES QUATRE FAMILLES MESUREES SONT COMPLETES', () {
    test('S1 : la carte immobile sous les ticks GPS, du demarrage au SOS', () {
      final attendus = <String>[
        'S1_Lea_20_demarrage',
        'S1_Lea_21_carte',
        for (var i = 0; i < 8; i++)
          'S1_Lea_22_gps_tick_${i.toString().padLeft(2, "0")}',
        'S1_Lea_23_apres_gps',
        'S1_Lea_25_apres_sos',
      ];
      final famille = _familleDe(attendus.first);
      expect(famille, isNotNull, reason: 'la famille de S1 a disparu');
      expect(
        famille!.noms,
        containsAll(attendus),
        reason:
            'FAMILLE INCOMPLETE : la regle de doublon compare l image '
            'ENTIERE, donc le groupement change d un run a l autre au gre de '
            'l horloge. Une famille partielle laisse le run rouge un jour sur '
            'deux (mesure du 05/10, memoire #101219).',
      );
    });

    test(
      'S3 : la meme carte immobile, douze ticks et l overlay non arrete',
      () {
        final attendus = <String>[
          'S3_Steve_04_apres_demarrage',
          'S3_Steve_05_carte',
          for (var i = 0; i < 12; i++)
            'S3_Steve_06_gps_tick_${i.toString().padLeft(2, "0")}',
          'S3_Steve_07_apres_gps',
          'S3_Steve_07b_overlay_arrete',
        ];
        final famille = _familleDe(attendus.first);
        expect(famille, isNotNull, reason: 'la famille de S3 a disparu');
        expect(famille!.noms, containsAll(attendus));
      },
    );

    test('S3 : le cockpit avant / apres un dialogue SOS annule', () {
      final famille = _familleDe('S3_Steve_09_apres_sos');
      expect(famille, isNotNull);
      expect(
        famille!.noms,
        containsAll(<String>[
          'S3_Steve_09_apres_sos',
          'S3_Steve_10_cockpit_fin',
          'S3_Steve_S3E_zz_retour_cockpit',
        ]),
      );
    });

    test('S4 : le cockpit hors-ligne, aux trois passages', () {
      final famille = _familleDe('S4_Ines_07_bascule_offline');
      expect(famille, isNotNull);
      expect(
        famille!.noms,
        containsAll(<String>[
          'S4_Ines_07_bascule_offline',
          'S4_Ines_10_cockpit_offline',
          'S4_Ines_S4E_zz_retour_cockpit',
        ]),
      );
    });

    test('S8 : le catalogue ou l onboarding rend la main', () {
      final paire = _declarations.firstWhere(
        (d) => d.noms.contains('S8_Demo_02_apres_onboarding'),
        orElse: () => _Declaration(-1, false, const [], ''),
      );
      expect(paire.ligne, greaterThan(0), reason: 'la paire de S8 a disparu');
      expect(paire.noms, contains('S8_Demo_03_catalogue'));
    });
  });

  group('CE QUI RESTE ROUGE DOIT RESTER ROUGE', () {
    test('le faux « consentement atteint » de S2 n est pas tolere', () {
      final nommees = _declarations.expand((d) => d.noms).toSet();
      expect(
        nommees,
        isNot(contains('S2_Marc_S2E_38b_consent_bascule')),
        reason:
            'ce doublon est le SEUL endroit ou se voit que le scenario tape '
            'l en-tete de section au lieu de la tuile : le tolerer rendrait '
            'le mensonge invisible',
      );
    });

    test('les deux groupes fabriques par la charge ne sont pas toleres', () {
      final nommees = _declarations.expand((d) => d.noms).toSet();
      for (final nom in const [
        'S1_Lea_10b_test_6min_demarre',
        'S1_Lea_12c_faisabilite_verdict_reel',
        'S1_Lea_13_retour_cockpit',
        'S1_Lea_14_entrainement',
      ]) {
        expect(
          nommees,
          isNot(contains(nom)),
          reason:
              'MESURE : sur une machine saine ces ecrans different de 408 869 '
              'a 1 986 942 pixels, EN PLEIN CONTENU. Leur identite n est pas '
              'une action sans effet, c est une image perimee servie sous la '
              'charge. La parade est la gate de charge du pilote, pas une '
              'tolerance ($nom).',
        );
      }
    });
  });

  group('TACHE 695 — « DECLAREE MAIS INUTILE » NE SUFFIT PAS A RETIRER', () {
    /// Les cinq declarations que le controle avait nommees « inutiles ».
    ///
    /// CE QUI S'EST PASSE, ET C'EST MESURE. Depuis la tache 685, le controle
    /// nomme les tolerances DECLAREES MAIS INUTILES sur un run : toutes leurs
    /// captures sont presentes et aucune paire interne n'est identique. Les runs
    /// du 05/10 (memoire #101275) en ont designe CINQ. La tache 695 les a
    /// retirees toutes les cinq, puis a rejoue un run S1 complet sur machine
    /// CALME (loadavg 1 min = 2.03, retard marqueur->screencap = 0 ms, 65
    /// captures pour 65 marqueurs, 61 exigences tenues / 2 echouees). LE RUN A
    /// DIT NON, DEUX FOIS SUR DEUX :
    ///   * 19b_cta_demarrer / 19b2_apres_achat : ZERO pixel de difference sur
    ///     1080x2400, images identiques AU BIT. Le run est ROUGE sans la
    ///     declaration.
    ///   * 27_apres_terminer / 33_recap_apres_trek : 603 pixels, TOUS dans la
    ///     boite (123,47)-(967,80) — la BARRE D'ETAT. Le contenu applicatif est
    ///     identique au pixel : ces deux images ne sont « differentes » que
    ///     parce que la minute a tourne.
    ///
    /// LA LECON, ET C'EST ELLE QUE CETTE GARDE TIENT : le controle compare
    /// l'image ENTIERE, barre d'etat comprise (kaizen d'Artemis, memoire
    /// #101298). « Inutile sur ce run » ne prouve donc RIEN — la meme paire, sur
    /// le meme produit, est declaree utile ou inutile selon l'horloge. Les cinq
    /// declarations sont remises, et on ne les retire pas tant que le controle
    /// n'exclut pas la barre d'etat.
    const designees = <String>[
      'S1_Lea_19b_cta_demarrer',
      'S1_Lea_19b2_apres_achat',
      'S1_Lea_27_apres_terminer',
      'S1_Lea_33_recap_apres_trek',
      'S3_Steve_S3E_31_signalement',
      'S3_Steve_S3E_31b_signalement_eau',
      'S4_Ines_09_carte_offline',
      'S4_Ines_S4E_36_trace_offline',
      'S4_Ines_S4E_45_trail_selection',
      'S4_Ines_S4E_45b_pyrenees_actif',
    ];

    test('les cinq designees sont TOUJOURS declarees, et avec leur raison', () {
      final nommees = {
        for (final d in _declarations)
          for (final n in d.noms) n: d,
      };
      for (final nom in designees) {
        final d = nommees[nom];
        expect(
          d,
          isNotNull,
          reason:
              'TOLERANCE RETIREE SUR UN SIGNAL FAUX : $nom a ete designe '
              '« inutile » par un run, et la tache 695 a MESURE que ce signal '
              'ne vaut rien (0 pixel de difference sur une paire, 603 pixels '
              'tous dans la barre d etat sur l autre). Ne la retirez pas sans '
              'une mesure pixel HORS barre d etat sur un run de son scenario.',
        );
        expect(
          d!.raison,
          isNotEmpty,
          reason: '$nom est declare ligne ${d.ligne} SANS RAISON',
        );
      }
    });

    test('LA MESURE QUI LE PROUVE EST ECRITE DANS LE FICHIER', () {
      // Sans ces chiffres, le prochain lot refait le tour entier — ou retire de
      // nouveau les cinq sur le meme rapport.
      for (final preuve in const [
        'ZERO pixel de difference', // 19b / 19b2, identiques au bit
        '(123,47)-(967,80)', // 27 / 33, la boite de la barre d etat
        'BARRE D\'ETAT', // la cause nommee
      ]) {
        expect(
          _tolerances,
          contains(preuve),
          reason:
              'MESURE PERDUE : le fichier doit garder « $preuve », qui est la '
              'preuve que « declaree mais inutile » ne suffit pas a retirer '
              'une tolerance (tache 695).',
        );
      }
    });
  });

  group('LE CONTROLE REFUSE TOUJOURS CE QU IL DOIT REFUSER', () {
    test('un doublon NON declare fait rougir le run', () {
      final r = _lancerLeControle(null);
      if (r == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      expect(r.code, 1, reason: 'un doublon non declare doit rougir');
      expect(r.sortie, contains('IDENTIQUES non tolerees'));
    });

    test('une PAIRE declaree avec sa raison passe', () {
      final r = _lancerLeControle(
        'A B  # meme ecran, aucun geste entre les deux\n',
      );
      if (r == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
    });

    test('une FAMILLE declaree avec sa raison passe', () {
      final r = _lancerLeControle(
        'groupe: A B C  # la meme carte immobile aux trois captures\n',
      );
      if (r == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
      expect(r.sortie, contains('1 famille(s)'));
    });

    test('une tolerance SANS RAISON fait rougir le run', () {
      final r = _lancerLeControle('A B\n');
      if (r == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      expect(
        r.code,
        1,
        reason:
            'le fichier exige une raison depuis la tache 665 ; rien ne le '
            'verifiait. Sortie :\n${r.sortie}',
      );
      expect(r.sortie, contains('SANS RAISON ECRITE'));
    });

    test('trois noms sur une ligne de PAIRE sont refuses', () {
      final r = _lancerLeControle('A B C  # trois noms sans groupe:\n');
      if (r == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      expect(r.code, 1, reason: 'sortie :\n${r.sortie}');
      expect(r.sortie, contains('ligne de PAIRE'));
    });
  });
}
