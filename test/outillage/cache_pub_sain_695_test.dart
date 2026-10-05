// LE CACHE PUB PARTAGE EST ASSAINI, ET LA PURGE N'EFFACE QUE DES PAQUETS
// INCOMPLETS — tache 695.
//
// CE QUE CE FICHIER EMPECHE DE REVENIR (kaizen #101276, mesure #101275).
// Le 05/10 a 13:24:55, deux `flutter pub get` ont tourne EN PARALLELE dans deux
// arbres de travail differents. Le cache pub est PARTAGE par toute la machine :
// 29 dossiers de paquets sont restes VIDES — cloud_firestore, share_plus,
// firebase_core, connectivity_plus, battery_plus, device_info_plus,
// package_info_plus, printing, sqlite3_flutter_libs et vingt autres, tous
// horodates a la meme seconde. Or `pub get` conclut qu'un paquet est installe EN
// VOYANT SON DOSSIER : un dossier vide ne se retelecharge JAMAIS. Facture
// mesuree : 219 fausses erreurs de `flutter analyze` (« Target of URI doesn't
// exist: package:cloud_firestore/cloud_firestore.dart ») sur un depot
// parfaitement sain, et deux agents partis chercher une regression qui
// n'existait pas.
//
// POURQUOI UNE GARDE, ET SUR QUOI ELLE PORTE. La purge touche a des dossiers du
// disque de la machine : c'est exactement le genre d'outil qu'il faut eprouver
// AVANT de le croire. On fabrique donc un FAUX CACHE dans un dossier temporaire
// et on LANCE le vrai outil dessus. Deux proprietes comptent, et la seconde plus
// que la premiere :
//   1. il efface bien les dossiers de paquets incomplets ;
//   2. IL N'EFFACE RIEN D'AUTRE — ni un paquet complet, ni un fichier, ni le
//      cache `git/`, ni quoi que ce soit hors de `hosted/<hote>/`.
// Et le verrou est eprouve lui aussi : tenu par un processus VIVANT, il fait
// ATTENDRE puis renoncer proprement, sans jamais lancer la commande protegee.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Le chemin de l'outil, relatif a la racine du depot.
const String _outil = 'tool/pub_cache_sain.py';

/// L'interpreteur Python de la machine, ou null s'il n'y en a pas.
///
/// Meme resolveur que `tolerances_de_captures_685_test.dart` : sous Windows
/// l'executable s'appelle `python` ou `py`, sous Linux et macOS `python3`.
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

/// Un faux cache pub, avec un exemplaire de chaque cas qui compte.
///
/// LES TROIS DOSSIERS DE PAQUETS SONT LES TROIS ETATS REELS :
///   * `complet-1.0.0`  : un paquet normal, avec son `pubspec.yaml` ;
///   * `vide-2.0.0`     : le cas du 05/10, dossier cree et jamais rempli ;
///   * `amorce-3.0.0`   : commence a se remplir puis abandonne — il a des
///                        fichiers mais PAS de `pubspec.yaml`, donc `pub get`
///                        le croit installe tout autant.
/// Et trois temoins qui ne doivent PAS bouger : un fichier a cote des paquets,
/// le cache `git/` (dont les dossiers n'ont pas la forme `paquet-version`) et
/// `bin/`.
Directory _fauxCache() {
  final bac = Directory.systemTemp.createTempSync('cache_pub_695_');
  final hote = Directory('${bac.path}/hosted/pub.dev')
    ..createSync(recursive: true);
  Directory('${hote.path}/complet-1.0.0').createSync();
  File(
    '${hote.path}/complet-1.0.0/pubspec.yaml',
  ).writeAsStringSync('name: complet\n');
  File('${hote.path}/complet-1.0.0/lib/complet.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('// vrai contenu\n');
  Directory('${hote.path}/vide-2.0.0').createSync();
  File('${hote.path}/amorce-3.0.0/lib/amorce.dart')
    ..createSync(recursive: true)
    ..writeAsStringSync('// moitie descendu\n');
  File('${hote.path}/.un_fichier_a_cote').writeAsStringSync('temoin\n');
  // LE TEMOIN QUI MANQUAIT, ET QUI A COUTE 697 FICHIERS (tache 695).
  // `hosted/pub.dev/.cache` est le cache de metadonnees de PUB lui-meme : il n a
  // pas de `pubspec.yaml` et n est pas un paquet a moitie descendu. La premiere
  // version de l outil l a efface pour de bon le 05/10 a 19:48 (697 fichiers,
  // 22 315 916 octets) parce que ce faux cache ne portait que des FICHIERS
  // temoins, jamais un DOSSIER qui ne soit pas un paquet. Il en porte un
  // maintenant.
  File('${hote.path}/.cache/moteur_gr-versions.json')
    ..createSync(recursive: true)
    ..writeAsStringSync('{"versions":[]}\n');
  // Et un dossier au nom SANS version : lui non plus n est pas un paquet.
  Directory('${hote.path}/un_dossier_a_pub').createSync();
  Directory('${bac.path}/git/moteur-gr-abc123').createSync(recursive: true);
  Directory('${bac.path}/bin').createSync(recursive: true);
  return bac;
}

/// Lance l'outil sur [cache] avec [args]. Rend le code et la sortie.
({int code, String sortie}) _lancer(
  String python,
  String cache,
  List<String> args,
) {
  final r = Process.runSync(python, <String>[
    _outil,
    '--cache',
    cache,
    ...args,
  ]);
  return (code: r.exitCode, sortie: '${r.stdout}${r.stderr}');
}

/// Les chemins encore presents dans [bac], relatifs a sa racine.
Set<String> _restants(Directory bac) => bac
    .listSync(recursive: true)
    .map((e) => e.path.substring(bac.path.length).replaceAll(r'\', '/'))
    .toSet();

void main() {
  final python = _python();

  group('LA PURGE DU CACHE PUB EFFACE LES PAQUETS INCOMPLETS', () {
    test('les deux dossiers sans pubspec.yaml sont effaces, le paquet complet '
        'reste', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final r = _lancer(python, bac.path, const ['--purger']);
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');

        final restants = _restants(bac);
        expect(
          restants,
          isNot(contains('/hosted/pub.dev/vide-2.0.0')),
          reason:
              'LE CAS DU 05/10 : un dossier de paquet VIDE passe pour '
              'installe et ne se retelecharge jamais. Il doit partir.',
        );
        expect(
          restants,
          isNot(contains('/hosted/pub.dev/amorce-3.0.0')),
          reason:
              'un paquet a moitie descendu est tout aussi menteur qu un '
              'dossier vide : flutter ne regarde que le dossier',
        );
        expect(
          restants,
          contains('/hosted/pub.dev/complet-1.0.0/pubspec.yaml'),
          reason:
              'UN PAQUET COMPLET EFFACE, C EST 732 PAQUETS A RETELECHARGER '
              'pour rien : le critere est le pubspec.yaml, rien d autre',
        );
        expect(
          restants,
          contains('/hosted/pub.dev/complet-1.0.0/lib/complet.dart'),
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test(
      'RIEN D AUTRE N EST TOUCHE : ni un fichier, ni le cache git, ni bin',
      () {
        if (python == null) {
          markTestSkipped('aucun interpreteur Python sur cette machine');
          return;
        }
        final bac = _fauxCache();
        try {
          _lancer(python, bac.path, const ['--purger']);
          final restants = _restants(bac);
          for (final temoin in const [
            '/hosted/pub.dev/.un_fichier_a_cote',
            // LE CACHE DE METADONNEES DE PUB : efface pour de bon le 05/10 par
            // la premiere version de l outil. Il n a pas de pubspec.yaml et ce
            // n est PAS un paquet incomplet — c est a pub, pas a nous.
            '/hosted/pub.dev/.cache',
            '/hosted/pub.dev/.cache/moteur_gr-versions.json',
            // Un dossier dont le nom ne porte pas de version n est pas un
            // paquet : il appartient a pub.
            '/hosted/pub.dev/un_dossier_a_pub',
            '/git/moteur-gr-abc123',
            '/bin',
          ]) {
            expect(
              restants,
              contains(temoin),
              reason:
                  'LA PURGE EFFACE DES DOSSIERS SUR LE DISQUE DE LA MACHINE : '
                  'son perimetre est <cache>/hosted/<hote>/<paquet>/ et il ne '
                  'doit JAMAIS s elargir. Temoin perdu : $temoin',
            );
          }
        } finally {
          bac.deleteSync(recursive: true);
        }
      },
    );

    test(
      'LE JOURNAL DIT CE QU IL EFFACE, avec ce que le dossier contenait',
      () {
        if (python == null) {
          markTestSkipped('aucun interpreteur Python sur cette machine');
          return;
        }
        final bac = _fauxCache();
        try {
          final r = _lancer(python, bac.path, const ['--purger']);
          expect(
            r.sortie,
            contains('2 INCOMPLET(S)'),
            reason: 'la mesure d avant doit etre dite : sortie :\n${r.sortie}',
          );
          expect(r.sortie, contains('PURGE : pub.dev/vide-2.0.0'));
          expect(r.sortie, contains('PURGE : pub.dev/amorce-3.0.0'));
          expect(
            r.sortie,
            contains('(0 fichier(s), 0 octet(s))'),
            reason:
                'UNE PURGE MUETTE EST UNE PURGE QU ON NE PEUT PAS CONTREDIRE : '
                'le journal doit dire ce que le dossier contenait, pour qu une '
                'suppression de trop se voie. Sortie :\n${r.sortie}',
          );
          expect(r.sortie, isNot(contains('complet-1.0.0')));
        } finally {
          bac.deleteSync(recursive: true);
        }
      },
    );

    test('--simuler n efface RIEN, et le dit', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final avant = _restants(bac);
        final r = _lancer(python, bac.path, const ['--purger', '--simuler']);
        expect(r.code, 0);
        expect(r.sortie, contains('SIMULATION'));
        expect(r.sortie, contains('A PURGER : pub.dev/vide-2.0.0'));
        expect(
          _restants(bac),
          avant,
          reason: 'une simulation qui efface n est pas une simulation',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test('APPELE SANS ACTION, l outil MESURE et n efface rien', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final avant = _restants(bac);
        final r = _lancer(python, bac.path, const <String>[]);
        expect(r.code, 0);
        expect(r.sortie, contains('2 INCOMPLET(S)'));
        expect(
          _restants(bac),
          avant,
          reason:
              'un outil qui efface quand on l appelle sans argument est un '
              'outil qu on finit par lancer par erreur',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test('sur un cache SAIN la purge ne fait rien et le dit', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        _lancer(python, bac.path, const ['--purger']);
        final apres = _restants(bac);
        final r = _lancer(python, bac.path, const ['--purger']);
        expect(r.code, 0);
        expect(r.sortie, contains('rien a purger'));
        expect(_restants(bac), apres, reason: 'la purge doit etre idempotente');
      } finally {
        bac.deleteSync(recursive: true);
      }
    });
  });

  group('UN SEUL pub get A LA FOIS PAR MACHINE', () {
    test('LE VERROU TENU PAR UN PROCESSUS VIVANT FAIT ATTENDRE, puis renoncer '
        'SANS lancer la commande protegee', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      final temoin = File('${bac.path}/la_commande_a_tourne');
      try {
        // Le verrou est tenu par CE processus de test, qui est bien vivant :
        // l outil ne doit donc pas le reprendre pour un verrou abandonne.
        File('${bac.path}/.stepways_pub_get.lock').writeAsStringSync(
          jsonEncode({'pid': pid, 'depuis': 'maintenant', 'cwd': 'le test'}),
        );
        final r = _lancer(python, bac.path, <String>[
          '--attente-max-s',
          '1',
          '--sous-verrou',
          python,
          '-c',
          "open(r'${temoin.path}','w').write('tourne')",
        ]);
        expect(
          r.code,
          75,
          reason:
              'le verrou non obtenu a son propre code de sortie, lisible par '
              'une gate. Sortie :\n${r.sortie}',
        );
        expect(r.sortie, contains('UN AUTRE pub get TOURNE SUR CETTE MACHINE'));
        expect(r.sortie, contains('VERROU NON OBTENU'));
        expect(
          temoin.existsSync(),
          isFalse,
          reason:
              'VERROU DECORATIF : la commande protegee a tourne alors que le '
              'verrou etait tenu. C est exactement le defaut du 05/10 — deux '
              'pub get en parallele sur un cache partage.',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test('UN VERROU ABANDONNE PAR UN PROCESSUS MORT EST REPRIS, sinon un agent '
        'tue bloquerait la machine', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      final temoin = File('${bac.path}/la_commande_a_tourne');
      try {
        // Un PID qui n existe pas : le verrou d un processus abattu (c est
        // arrive le 04/10, le watchdog PRC-003 abat un python au hasard).
        File('${bac.path}/.stepways_pub_get.lock').writeAsStringSync(
          jsonEncode({'pid': 999999999, 'depuis': 'hier', 'cwd': 'un mort'}),
        );
        final r = _lancer(python, bac.path, <String>[
          '--attente-max-s',
          '5',
          '--sous-verrou',
          python,
          '-c',
          "open(r'${temoin.path}','w').write('tourne')",
        ]);
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
        expect(r.sortie, contains('VERROU ABANDONNE'));
        expect(
          temoin.existsSync(),
          isTrue,
          reason: 'la commande protegee doit avoir tourne',
        );
        expect(
          File('${bac.path}/.stepways_pub_get.lock').existsSync(),
          isFalse,
          reason:
              'LE VERROU DOIT ETRE RENDU : un verrou laisse derriere soi fait '
              'attendre quinze minutes le prochain appelant',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test('LA PURGE SE FAIT SOUS LE VERROU, jamais a cote', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final r = _lancer(python, bac.path, <String>[
          '--sous-verrou',
          python,
          '-c',
          'pass',
        ]);
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
        final iPurge = r.sortie.indexOf('PURGE : pub.dev/');
        final iCommande = r.sortie.indexOf('(sous verrou)');
        expect(iPurge, greaterThan(0), reason: 'sortie :\n${r.sortie}');
        expect(iCommande, greaterThan(0), reason: 'sortie :\n${r.sortie}');
        expect(
          iPurge,
          lessThan(iCommande),
          reason:
              'PURGER HORS DU VERROU, C EST EFFACER SOUS LES PIEDS D UN AUTRE '
              'pub get le paquet qu il est en train de remplir : la purge doit '
              'passer AVANT la commande, et les deux sous le meme verrou.',
        );
        expect(_restants(bac), isNot(contains('/hosted/pub.dev/vide-2.0.0')));
      } finally {
        bac.deleteSync(recursive: true);
      }
    });

    test('SANS COMMANDE, --sous-verrou assainit sous le verrou et ne lance '
        'rien - c est la forme que le pilote appelle', () {
      if (python == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final r = _lancer(python, bac.path, const ['--sous-verrou']);
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
        expect(
          r.sortie,
          contains('assaini SOUS VERROU'),
          reason:
              'une liste de commande VIDE est FAUSSE en booleen : testee ainsi, '
              'l appel retomberait sur --purger, donc sur la purge HORS verrou '
              '- le defaut qu on vient de fermer (QA #101314)',
        );
        expect(
          _restants(bac),
          isNot(contains('/hosted/pub.dev/vide-2.0.0')),
          reason: 'la purge doit bien avoir eu lieu',
        );
        expect(
          _restants(bac),
          contains('/hosted/pub.dev/complet-1.0.0/pubspec.yaml'),
        );
        expect(
          File('${bac.path}/.stepways_pub_get.lock').existsSync(),
          isFalse,
          reason: 'le verrou doit etre RENDU',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });
  });

  group('LE PILOTE DE LA RECETTE CONTROLE LE CACHE A SON REVEIL', () {
    final pilote = File('tool/run_persona.ps1').readAsStringSync();

    test('il assainit le cache, et AVANT le pre-build qui appelle Gradle', () {
      expect(
        pilote,
        contains('pub_cache_sain.py --sous-verrou'),
        reason:
            'CONTROLE PERDU : sans assainissement au reveil, un cache abime '
            'par un pub get concurrent fait echouer le build du run - ou '
            'pire, le laisse passer avec des paquets manquants (kaizen '
            '#101276).',
      );
      final purge = pilote.indexOf('pub_cache_sain.py --sous-verrou');
      final preBuild = pilote.indexOf(r'Invoke-PreBuild $repo $Tag');
      expect(
        preBuild,
        greaterThan(0),
        reason: 'appel du pre-build introuvable',
      );
      expect(
        purge,
        lessThan(preBuild),
        reason:
            'ORDRE INVERSE = CONTROLE INUTILE. Le pre-build lance Gradle, donc '
            'pub get : assainir le cache APRES, c est assainir apres l echec.',
      );
    });

    test('ET IL NE PURGE JAMAIS NU, c est-a-dire hors verrou', () {
      // CE QUE CETTE GARDE EMPECHE DE REVENIR (QA #101314, AFFAIBLI 1). Le
      // pilote appelait « --purger » NU. Or ce chemin NE PREND PAS le verrou,
      // et l outil documente lui-meme la purge hors verrou comme dangereuse :
      // effacer pendant qu un pub get concurrent telecharge, c est retirer sous
      // ses pieds le paquet qu il est en train de remplir — le defaut du 05/10,
      // refait a l envers. Le banc gravait donc un appel nu dans le pilote
      // pendant que la garde juste au-dessus en faisait un principe.
      final nus = RegExp(
        r'pub_cache_sain\.py\s+--purger',
      ).allMatches(pilote).length;
      expect(
        nus,
        0,
        reason:
            'PURGE NUE DANS LE PILOTE : $nus appel(s) a « --purger », qui ne '
            'prend pas le verrou. Utilisez « --sous-verrou » SANS commande : '
            'il assainit sous le verrou et ne lance rien de plus.',
      );
    });

    test('le controle ne se desarme que sur demande EXPLICITE, et le dit', () {
      expect(pilote, contains(r'[switch]$SansControleCachePub'));
      final i = pilote.indexOf(r'if ($SansControleCachePub) {');
      expect(i, greaterThan(0));
      expect(
        pilote.substring(i, i + 400),
        contains('paquets manquants'),
        reason:
            'un controle desarme doit dire ce qu il laisse passer, sinon le '
            'run passe pour mesure',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // FLUTTER EST RESOLU EN CHEMIN, JAMAIS LANCE PAR SON NOM NU — tache 699.
  //
  // CE QUE CES CAS EMPECHENT DE REVENIR, ET C'EST MESURE (#101332). La premiere
  // version de cet outil lancait `['flutter', 'pub', 'get']` — un NOM NU — en
  // `subprocess.run(shell=False)`. Sous Windows, `C:\flutter\bin` ne contient
  // que `flutter` (script sh) et `flutter.bat`, AUCUN `.exe`, et
  // `CreateProcess` ne resout NI `.bat` NI `.cmd` : `--pub-get` levait
  // `FileNotFoundError [WinError 2]` avec une trace nue, donc l'outil ecrit
  // pour serialiser les `pub get` ne pouvait PAS faire de `pub get`. La QA
  // #101314 ne l'avait pas vu : elle avait mesure `--mesurer`, `--simuler` et
  // `--purger`, jamais le bout de la chaine.
  //
  // COMMENT ON LE MESURE SANS LE VRAI SDK. On fabrique un FAUX dossier bin qui
  // porte l'etat exact du vrai sous Windows — un `.bat`, pas de `.exe`, pas de
  // fichier sans suffixe — et on REDUIT LE PATH a ce seul dossier : le vrai
  // flutter n'y est pas. Le faux trace ses appels. Et le TEMOIN DU DEFAUT vient
  // d'abord : dans ce meme PATH, un nom nu leve bien WinError 2 alors que le
  // chemin complet tourne. Sans lui, ces cas pourraient passer au vert sur un
  // PATH complaisant.
  group('FLUTTER EST RESOLU EN CHEMIN, JAMAIS LANCE PAR SON NOM NU', () {
    final pythonExe = python == null ? null : _pythonComplet(python);

    test('LE TEMOIN DU DEFAUT : dans ce PATH, le nom nu ne se lance PAS, le '
        'chemin complet SI', () {
      if (pythonExe == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      if (!Platform.isWindows) {
        markTestSkipped(
          'le defaut est propre a CreateProcess : hors Windows, le lanceur du '
          'SDK est un script SANS suffixe que le nom nu trouve',
        );
        return;
      }
      final sdk = _fauxSdk();
      try {
        final nu = Process.runSync(
          pythonExe,
          <String>[
            '-c',
            'import subprocess\n'
                'try:\n'
                '    subprocess.run(["flutter", "--version"], '
                'capture_output=True)\n'
                '    print("LANCE")\n'
                'except FileNotFoundError as err:\n'
                '    print("REFUSE", err.errno)\n',
          ],
          environment: _env(sdk.dossier.path),
          includeParentEnvironment: false,
        );
        expect(
          '${nu.stdout}',
          contains('REFUSE 2'),
          reason:
              'le nom nu se lance dans ce PATH : le faux SDK ou le PATH reduit '
              'ne tiennent pas, et les cas suivants ne mesureraient rien. '
              'Sortie : ${nu.stdout}${nu.stderr}',
        );

        final complet = Process.runSync(
          pythonExe,
          <String>[
            '-c',
            'import subprocess, sys\n'
                'fini = subprocess.run([sys.argv[1], "--version"])\n'
                'print(fini.returncode)\n',
            '${sdk.dossier.path}\\flutter.bat',
          ],
          environment: _env(sdk.dossier.path),
          includeParentEnvironment: false,
        );
        expect(
          complet.exitCode,
          0,
          reason:
              'le MEME appel par le chemin complet doit tourner, sinon ce '
              'n est pas la resolution qui est en cause : '
              '${complet.stdout}${complet.stderr}',
        );
      } finally {
        sdk.dossier.deleteSync(recursive: true);
      }
    });

    test('--pub-get LANCE LE FLUTTER DU PATH alors qu il n y a qu un .bat', () {
      if (pythonExe == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final sdk = _fauxSdk();
      final bac = _fauxCache();
      try {
        final r = _lancerAvec(pythonExe, bac.path, const [
          '--pub-get',
        ], _env(sdk.dossier.path));
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
        expect(
          sdk.trace.existsSync(),
          isTrue,
          reason:
              'le faux flutter n a pas ete appele : la resolution n a pas eu '
              'lieu.\n${r.sortie}',
        );
        expect(
          sdk.trace.readAsStringSync(),
          contains('pub get'),
          reason: 'flutter a ete lance, mais pas avec « pub get »',
        );
        expect(
          r.sortie.toLowerCase(),
          contains('(sous verrou)'),
          reason: 'la commande doit etre lancee SOUS LE VERROU',
        );
        expect(
          r.sortie,
          isNot(contains('Traceback')),
          reason: 'aucune trace d exception ne doit remonter a l appelant',
        );
        expect(
          _restants(bac),
          isNot(contains('/hosted/pub.dev/vide-2.0.0')),
          reason: 'la purge sous verrou doit avoir eu lieu avant le pub get',
        );
        expect(
          File('${bac.path}/.stepways_pub_get.lock').existsSync(),
          isFalse,
          reason: 'le verrou doit etre RENDU',
        );
      } finally {
        sdk.dossier.deleteSync(recursive: true);
        bac.deleteSync(recursive: true);
      }
    });

    test('PATHEXT DETOURNE : which ne trouve rien, et c est LE REPLI qui '
        'trouve', () {
      if (pythonExe == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      if (!Platform.isWindows) {
        markTestSkipped('PATHEXT n existe que sous Windows');
        return;
      }
      final sdk = _fauxSdk();
      final bac = _fauxCache();
      try {
        // `shutil.which` honore PATHEXT : prive de `.BAT`, il rend None. Le
        // repli explicite de resolution_executable.py essaie `.bat` DOSSIER PAR
        // DOSSIER du PATH, et c est tout l interet de ne pas s en remettre a
        // `which` seul.
        final env = _env(sdk.dossier.path)..['PATHEXT'] = '.BANC699';
        final r = _lancerAvec(pythonExe, bac.path, const ['--pub-get'], env);
        expect(r.code, 0, reason: 'sortie :\n${r.sortie}');
        expect(
          sdk.trace.existsSync() &&
              sdk.trace.readAsStringSync().contains('pub get'),
          isTrue,
          reason:
              'PATHEXT detourne, le repli doit prendre le relais.\n${r.sortie}',
        );
      } finally {
        sdk.dossier.deleteSync(recursive: true);
        bac.deleteSync(recursive: true);
      }
    });

    test('PATH VIDE : l outil REFUSE proprement, sans prendre le verrou et '
        'sans trace d exception', () {
      if (pythonExe == null) {
        markTestSkipped('aucun interpreteur Python sur cette machine');
        return;
      }
      final bac = _fauxCache();
      try {
        final r = _lancerAvec(pythonExe, bac.path, const [
          '--pub-get',
        ], _env(''));
        expect(
          r.code,
          76,
          reason:
              '76 = executable introuvable, distinct de 75 (verrou non obtenu) '
              'et du code de la commande.\n${r.sortie}',
        );
        expect(r.sortie, contains('FLUTTER INTROUVABLE'));
        expect(
          r.sortie,
          contains('PATHEXT'),
          reason:
              'le message doit dire CE QUI A ETE TENTE : sans PATHEXT ni la '
              'liste des candidats, le lecteur ne sait pas si le defaut est '
              'dans sa machine ou dans le code',
        );
        expect(r.sortie, contains('flutter.bat'));
        expect(
          r.sortie,
          isNot(contains('Traceback')),
          reason:
              'l appelant est un script de recette : il merite une ligne '
              'lisible, pas une trace d exception',
        );
        expect(
          File('${bac.path}/.stepways_pub_get.lock').existsSync(),
          isFalse,
          reason: 'aucun verrou ne doit rester',
        );
        expect(
          _restants(bac),
          contains('/hosted/pub.dev/vide-2.0.0'),
          reason:
              'LA RESOLUTION PASSE AVANT LE VERROU ET LA PURGE : un outil '
              'introuvable ne doit faire attendre personne, et ne doit RIEN '
              'avoir efface',
        );
      } finally {
        bac.deleteSync(recursive: true);
      }
    });
  });
}

/// Le chemin COMPLET de l'interpreteur Python.
///
/// Indispensable pour le lancer avec un PATH reduit : avec le nom nu, c'est lui
/// qu'on ne trouverait plus, et le cas mesurerait l'inverse de ce qu'il croit.
String? _pythonComplet(String python) {
  try {
    final r = Process.runSync(python, const [
      '-c',
      'import sys; print(sys.executable)',
    ]);
    final chemin = '${r.stdout}'.trim();
    if (r.exitCode != 0 || chemin.isEmpty) return null;
    return chemin;
  } on ProcessException {
    return null;
  }
}

/// Un environnement MINIMAL dont le PATH est exactement [dossierSdk].
///
/// `includeParentEnvironment: false` est volontaire : herite du PATH de la
/// machine, le vrai flutter serait trouve et le cas ne prouverait rien.
/// `SystemRoot` et `COMSPEC` restent : le premier parce que Python en a besoin
/// pour demarrer sous Windows, le second parce que `CreateProcess` passe par
/// `cmd.exe` pour executer un `.bat`.
Map<String, String> _env(String dossierSdk) {
  final env = <String, String>{
    'PATH': dossierSdk,
    'PATHEXT': '.COM;.EXE;.BAT;.CMD',
    'PYTHONIOENCODING': 'utf-8',
  };
  for (final nom in const ['SystemRoot', 'windir', 'COMSPEC', 'TEMP', 'TMP']) {
    final v = Platform.environment[nom];
    if (v != null) env[nom] = v;
  }
  return env;
}

/// « Tous les arguments » en shell POSIX, hors de l'interpolation Dart.
const _tousLesArgumentsSh = r'$@';

/// Un faux dossier `bin` de SDK, dans l'etat EXACT du vrai.
///
/// Sous Windows : `flutter.bat` et RIEN D'AUTRE — ni `.exe`, ni fichier sans
/// suffixe. Ailleurs : le script `flutter` sans suffixe, comme le vrai SDK. Le
/// faux flutter TRACE ses arguments, donc on sait ce qu'il a recu.
({Directory dossier, File trace}) _fauxSdk() {
  final dossier = Directory.systemTemp.createTempSync('faux_sdk_699_');
  final trace = File('${dossier.path}/appels.txt');
  if (Platform.isWindows) {
    File('${dossier.path}/flutter.bat').writeAsStringSync(
      '@echo off\r\n'
      'echo APPEL: %* >> "${trace.path}"\r\n'
      'echo Got dependencies!\r\n'
      'exit /b 0\r\n',
    );
  } else {
    final lanceur = File('${dossier.path}/flutter')
      ..writeAsStringSync(
        <String>[
          '#!/bin/sh',
          'echo "APPEL: $_tousLesArgumentsSh" >> "${trace.path}"',
          'echo "Got dependencies!"',
          '',
        ].join('\n'),
      );
    Process.runSync('chmod', <String>['+x', lanceur.path]);
  }
  return (dossier: dossier, trace: trace);
}

/// Lance l'outil sur [cache] avec [args] DANS [environnement].
({int code, String sortie}) _lancerAvec(
  String pythonExe,
  String cache,
  List<String> args,
  Map<String, String> environnement,
) {
  final r = Process.runSync(
    pythonExe,
    <String>[_outil, '--cache', cache, ...args],
    environment: environnement,
    includeParentEnvironment: false,
  );
  return (code: r.exitCode, sortie: '${r.stdout}${r.stderr}');
}
