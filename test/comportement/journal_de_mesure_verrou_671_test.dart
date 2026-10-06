// LOT 671-01-FIX — LE VERROU D'ECRITURE DU JOURNAL DE MESURE.
//
// LE DEFAUT, MESURE SUR LA MACHINE WINDOWS DE CHRISTOPHE LE 06/10/2026 : sur
// 2000 poses du verrou, 1062 reussies, 645 PathExistsException et 293
// PathAccessException (errno 5). Sous Windows, creer en exclusif un fichier EN
// COURS DE SUPPRESSION leve PathAccessException, pas PathExistsException ; la
// pose ne rattrapait que la seconde, la premiere s'echappait et la ligne etait
// jetee (de 5 a 14 pour cent du journal, comptes, aucun ecrase).
//
// CE QUE CE FICHIER PROUVE :
//  1. LE BANC WINDOWS. Deux isolates, deux cents lignes chacun, une pose sur
//     quatre tombe sur un verrou en cours de suppression : quatre cents
//     lignes entieres, aucune perdue.
//  2. LA LIGNE EST ECRITE quand la pose leve une FileSystemException autre
//     que PathExistsException, et le compteur d'ecritures ratees reste a zero.
//  3. LA REPRISE SURE. Un verrou perime (ecrivain tue) est repris, et le
//     verrou pose porte son proprietaire et son heure de pose ; un verrou
//     VIVANT n'est jamais casse, la ligne est comptee perdue plutot que
//     d'ecrire sous le verrou d'un autre.
//
// LE DISQUE DE WINDOWS EST SIMULE par `IOOverrides` : le verrou que le journal
// manipule est enveloppe, et sa pose exclusive leve, a la demande, l'exception
// mesuree chez Christophe. Tout le reste passe au vrai disque, dans un dossier
// temporaire.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/journal_de_mesure.dart';

/// Suffixe du fichier de verrou, voisin du journal.
const String _suffixeVerrou = '.verrou';

/// L'exception mesuree chez Christophe sur une pose exclusive qui tombe sur
/// un verrou en cours de suppression.
PathAccessException _enCoursDeSuppression(String chemin) => PathAccessException(
  chemin,
  const OSError('Access is denied.', 5),
  'Cannot create file',
);

/// Le disque de Windows : la pose exclusive du verrou numero `n` (des 1)
/// leve [_enCoursDeSuppression] quand [panne] le dit. Il note les marques
/// ecrites dans le verrou et ses suppressions.
final class _DisqueWindows extends IOOverrides {
  _DisqueWindows({bool Function(int n)? panne}) : panne = panne ?? _jamais;

  final bool Function(int n) panne;
  int poses = 0;
  int suppressions = 0;
  final marques = <String>[];

  static bool _jamais(int n) => false;

  @override
  File createFile(String path) {
    final reel = super.createFile(path);
    return path.endsWith(_suffixeVerrou) ? _Verrou(reel, this) : reel;
  }
}

/// Le fichier de verrou vu au travers de [_DisqueWindows].
class _Verrou implements File {
  _Verrou(this._reel, this._disque);

  final File _reel;
  final _DisqueWindows _disque;

  @override
  String get path => _reel.path;

  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    if (exclusive && _disque.panne(++_disque.poses)) {
      throw _enCoursDeSuppression(path);
    }
    _reel.createSync(recursive: recursive, exclusive: exclusive);
  }

  @override
  void writeAsStringSync(
    String contents, {
    FileMode mode = FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) {
    _disque.marques.add(contents);
    _reel.writeAsStringSync(
      contents,
      mode: mode,
      encoding: encoding,
      flush: flush,
    );
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) =>
      _reel.readAsStringSync(encoding: encoding);

  @override
  DateTime lastModifiedSync() => _reel.lastModifiedSync();

  @override
  bool existsSync() => _reel.existsSync();

  @override
  void deleteSync({bool recursive = false}) {
    _disque.suppressions++;
    _reel.deleteSync(recursive: recursive);
  }

  @override
  Never noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'le faux verrou ne simule pas ${invocation.memberName}',
  );
}

/// Les lignes du journal de [dossier], aucune s'il n'existe pas.
List<String> _lignes(String dossier) {
  final f = File('$dossier/$kMeasureJournalFileName');
  return f.existsSync() ? f.readAsLinesSync() : const <String>[];
}

/// Un ecrivain du banc Windows : deux cents lignes, une pose de verrou sur
/// quatre tombe sur un verrou en cours de suppression.
Future<void> _ecrireDeuxCentsSousWindows(String dossier, String ecrivain) {
  final disque = _DisqueWindows(panne: (n) => n % 4 == 0);
  return IOOverrides.runWithIOOverrides(() async {
    final journal = MeasureJournal(directory: () async => Directory(dossier));
    for (var i = 0; i < 200; i++) {
      await journal.append(
        '$ecrivain;${i.toString().padLeft(3, '0')};${'x' * 60}',
      );
    }
    if (journal.failedWrites > 0) {
      throw StateError('$ecrivain : ${journal.failedWrites} lignes perdues');
    }
    if (disque.poses < 250) {
      throw StateError(
        '$ecrivain : ${disque.poses} poses, la panne n a pas '
        'ete exercee',
      );
    }
  }, disque);
}

/// Le banc Windows : deux isolates ecrivent en meme temps. Les isolates sont
/// lances d'ici, ou rien d'intransmissible n'est capture.
Future<void> _deuxEcrivainsSousWindows(String dossier) => Future.wait([
  Isolate.run(() => _ecrireDeuxCentsSousWindows(dossier, 'A')),
  Isolate.run(() => _ecrireDeuxCentsSousWindows(dossier, 'B')),
]);

/// Lance [_tenirVivant] dans un autre isolate.
Future<void> _tenirVivantAilleurs(String chemin, Duration duree) =>
    Isolate.run(() => _tenirVivant(chemin, duree));

/// Un ecrivain VIVANT d'un autre isolate : il tient le verrou [chemin]
/// pendant [duree] et renouvelle sa marque toutes les cent millisecondes,
/// puis le leve.
void _tenirVivant(String chemin, Duration duree) {
  final verrou = File(chemin);
  final fin = DateTime.now().add(duree);
  while (DateTime.now().isBefore(fin)) {
    verrou.writeAsStringSync(
      'vivant-7;${DateTime.now().millisecondsSinceEpoch}',
      flush: true,
    );
    sleep(const Duration(milliseconds: 100));
  }
  try {
    verrou.deleteSync();
  } on FileSystemException {
    // Casse par l'ecrivain teste : le test le dira.
  }
}

void main() {
  late Directory bac;
  late String verrou;
  late MeasureJournal journal;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('journal_verrou_671_');
    verrou = '${bac.path}/$kMeasureJournalFileName$_suffixeVerrou';
    journal = MeasureJournal(directory: () async => Directory(bac.path));
  });

  tearDown(() {
    if (bac.existsSync()) bac.deleteSync(recursive: true);
  });

  group('671-01-FIX (1) — le banc Windows', () {
    test('deux isolates, deux cents lignes chacun, une pose sur quatre tombe '
        'sur un verrou en cours de suppression : quatre cents lignes '
        'entieres, aucune perdue', () async {
      final dossier = bac.path;
      await _deuxEcrivainsSousWindows(dossier);
      final lignes = _lignes(dossier);
      final entieres = RegExp(r'^[AB];\d{3};x{60}$');
      expect(lignes, hasLength(400), reason: 'lignes perdues ou en trop');
      expect(lignes.where(entieres.hasMatch), hasLength(400));
      expect(File(verrou).existsSync(), isFalse, reason: 'verrou oublie');
    });
  });

  group('671-01-FIX (2) — une pose refusee autrement que par PathExists', () {
    test('trois poses levent PathAccessException (errno 5) : la pose est '
        'retentee et la ligne est ECRITE', () async {
      final disque = _DisqueWindows(panne: (n) => n <= 3);
      await IOOverrides.runWithIOOverrides(
        () => journal.append('ligne;windows'),
        disque,
      );
      expect(_lignes(bac.path), [
        'ligne;windows',
      ], reason: 'la ligne a ete jetee');
      expect(disque.poses, 4, reason: 'trois refus puis une pose');
    });

    test('dans ce cas le compteur d ecritures ratees reste a zero, et le '
        'verrou est leve', () async {
      final disque = _DisqueWindows(panne: (n) => n <= 3);
      await IOOverrides.runWithIOOverrides(
        () => journal.append('ligne;windows'),
        disque,
      );
      expect(journal.failedWrites, 0, reason: 'une ligne comptee perdue');
      expect(File(verrou).existsSync(), isFalse, reason: 'verrou oublie');
    });
  });

  group('671-01-FIX (3) — la reprise du verrou', () {
    test('un verrou perime est repris, marque ou non (ancien build), et le '
        'verrou pose porte son proprietaire et son heure de pose', () async {
      final ilYaUneMinute = DateTime.now().subtract(const Duration(minutes: 1));
      final orphelins = {
        'marque': 'mort-1;${ilYaUneMinute.millisecondsSinceEpoch}',
        'sans marque': '',
      };
      for (final MapEntry(key: cas, value: contenu) in orphelins.entries) {
        File(verrou)
          ..writeAsStringSync(contenu)
          ..setLastModifiedSync(ilYaUneMinute);
        final disque = _DisqueWindows();
        final avant = DateTime.now().millisecondsSinceEpoch;
        await IOOverrides.runWithIOOverrides(
          () => journal.append('ligne;$cas'),
          disque,
        );
        final apres = DateTime.now().millisecondsSinceEpoch;

        expect(_lignes(bac.path).last, 'ligne;$cas', reason: cas);
        expect(journal.failedWrites, 0, reason: cas);
        expect(File(verrou).existsSync(), isFalse, reason: cas);
        expect(
          disque.marques,
          hasLength(1),
          reason: '$cas : le verrou pose ne porte ni proprietaire ni heure',
        );
        final marque = RegExp(
          r'^([^;]+);(\d+)$',
        ).firstMatch(disque.marques.single);
        expect(marque, isNotNull, reason: '$cas : ${disque.marques.single}');
        expect(marque!.group(1), isNot('mort-1'));
        expect(
          int.parse(marque.group(2)!),
          inInclusiveRange(avant, apres),
          reason: '$cas : heure de pose',
        );
      }
    });

    test('un verrou VIVANT n est pas casse : la ligne est comptee perdue '
        'plutot que d etre ecrite sous le verrou d un autre', () async {
      final tenue = _tenirVivantAilleurs(verrou, const Duration(seconds: 6));
      while (!File(verrou).existsSync()) {
        await Future<void>.delayed(const Duration(milliseconds: 5));
      }
      final disque = _DisqueWindows();
      await IOOverrides.runWithIOOverrides(
        () => journal.append('ligne;intruse'),
        disque,
      );
      final suppressions = disque.suppressions;
      await tenue;

      expect(suppressions, 0, reason: 'le verrou vivant a ete casse');
      expect(_lignes(bac.path), isEmpty, reason: 'ecrite sous un autre');
      expect(journal.failedWrites, 1);
    });
  });
}
