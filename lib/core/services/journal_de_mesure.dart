/// LE JOURNAL DE MESURE BATTERIE (lot 671-01) : un fichier texte du dossier
/// documents de l'application, lisible a l'oeil nu, qui ne quitte le
/// telephone que par le bouton Partager de l'ecran de mesure.
///
/// DEUX FORMES DE LIGNE, ET PAS UNE DE PLUS.
/// - La ligne d'EVENEMENT, neuf champs separes par un point-virgule :
///   heure locale ; profil ; evenement ; batterie % ; pas cumules ;
///   position lat,lon ; precision m ; ecart au dernier estime m ;
///   temps du premier point s. Un champ sans objet vaut un tiret.
/// - La ligne de COMPTEURS, toutes les dix minutes, valeurs nommees :
///   heure;profil;compteurs;batterie=NN;acquisitions=NN;pas=NN;distance_m=NN;
///   redemarrages=NN;attente_acquisition_s=NN.N
///
/// DEUX ECRIVAINS, UN FICHIER. L'isolate de fond et celui de l'interface
/// ecrivent dans le meme fichier. MESURE DU 06/10/2026 : l'ajout de `dart:io`
/// n'est PAS atomique entre deux isolates — il ouvre le fichier, se place a la
/// fin, PUIS ecrit (pas d'O_APPEND), et deux ecrivains qui se placent en meme
/// temps a la meme fin s'ecrasent ; le verrou de `RandomAccessFile` est un
/// verrou de processus, aveugle entre deux isolates. Chaque ligne est donc
/// ajoutee d'un seul appel, vidage immediat, SOUS un verrou portable : un
/// fichier voisin cree en exclusif, que le systeme ne laisse creer qu'a un
/// seul a la fois. Le verrou porte la marque de son ecrivain (proprietaire et
/// heure de pose) : seul son proprietaire le leve, et un autre ne le casse
/// que s'il est perime.
///
/// MESURE DU 06/10/2026 SOUS WINDOWS (lot 671-01-FIX) : sur 2000 poses, 293
/// levent `PathAccessException` (errno 5) et non `PathExistsException` —
/// creer en exclusif un fichier EN COURS DE SUPPRESSION y est refuse ainsi.
/// Toute `FileSystemException` a la pose est donc un refus a retenter.
///
/// AUCUNE DEPENDANCE RESEAU NI FIREBASE : ce fichier ne parle qu'au disque.
library;

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:path_provider/path_provider.dart';

import 'gps_cadence.dart';

/// Nom du fichier du journal, dans le dossier documents de l'application.
const String kMeasureJournalFileName = 'journal_de_mesure.txt';

/// Separateur des champs d'une ligne.
const String kMeasureSeparator = ';';

/// Valeur d'un champ sans objet.
const String kMeasureNoValue = '-';

/// Nombre de champs d'une ligne d'evenement.
const int kMeasureEventFieldCount = 9;

/// Mot du champ 3 d'une ligne de compteurs (ce n'est pas un evenement).
const String kMeasureCountersWord = 'compteurs';

/// Periode de la ligne de compteurs.
const Duration kMeasureCountersPeriod = Duration(minutes: 10);

/// Baisse de batterie, en points, qui fait ecrire un palier.
const int kMeasureBatteryStepPoints = 5;

/// Attente du verrou d'ecriture avant de l'examiner, et age au-dela duquel
/// un verrou est perime (son ecrivain a ete tue entre la pose et le retrait).
const Duration kMeasureLockPatience = Duration(seconds: 2);

/// Le vocabulaire FERME des evenements du journal.
enum MeasureEvent {
  /// Debut du suivi.
  demarrage('demarrage'),

  /// Une position recue, ou un tir sans position.
  releve('releve'),

  /// Un point estime le long du trace, retenu (ecrit depuis le lot 671-03).
  estime('estime'),

  /// Fin du suivi.
  arret('arret'),

  /// Changement de profil ou reprise du suivi.
  reprise('reprise'),

  /// Charniere de trace (jamais ecrite a ce lot).
  charniere('charniere'),

  /// Appel de secours (non observable a ce lot, jamais ecrit).
  sos('sos'),

  /// Sortie du trace (non observable a ce lot, jamais ecrite).
  horsTrace('hors-trace'),

  /// L'application revient au premier plan.
  ecranOn('ecran-on'),

  /// L'application quitte le premier plan.
  ecranOff('ecran-off'),

  /// La batterie a perdu [kMeasureBatteryStepPoints] points depuis le
  /// dernier palier.
  palierBatterie('palier-batterie');

  const MeasureEvent(this.word);

  /// Le mot ecrit dans le champ 3.
  final String word;

  /// L'evenement nomme [word] ; tout autre mot est REFUSE.
  static MeasureEvent fromWord(String word) {
    for (final event in values) {
      if (event.word == word) return event;
    }
    throw ArgumentError.value(word, 'word', 'evenement hors du vocabulaire');
  }
}

/// La mise en forme des deux formes de ligne.
abstract final class MeasureLine {
  /// Heure locale AAAA-MM-JJTHH:MM:SS.
  static String timestamp(DateTime at) {
    final l = at.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${l.year.toString().padLeft(4, '0')}-${two(l.month)}-'
        '${two(l.day)}T${two(l.hour)}:${two(l.minute)}:${two(l.second)}';
  }

  /// Une ligne d'evenement, neuf champs, un tiret pour chaque champ nul.
  ///
  /// Le champ 8 (ecart au dernier estime) existe toujours. Depuis le lot
  /// 671-03, une ligne `releve` y porte la distance en metres, LE LONG DU
  /// TRACE, entre le dernier point estime et le releve projete ; il vaut un
  /// tiret quand aucun estime ne precede le releve, et sur toute autre ligne.
  static String event({
    required DateTime at,
    required PositionProfile profile,
    required MeasureEvent event,
    int? batteryPercent,
    int? steps,
    double? latitude,
    double? longitude,
    double? accuracyMeters,
    double? driftMeters,
    Duration? timeToFix,
  }) {
    final position = latitude == null || longitude == null
        ? null
        : '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';
    return [
      timestamp(at),
      profile.journalLabel,
      event.word,
      _or(batteryPercent?.toString()),
      _or(steps?.toString()),
      _or(position),
      _or(accuracyMeters?.toStringAsFixed(1)),
      _or(driftMeters?.toStringAsFixed(1)),
      _or(timeToFix == null ? null : seconds(timeToFix)),
    ].join(kMeasureSeparator);
  }

  /// La ligne de compteurs, valeurs nommees dans l'ordre fixe.
  ///
  /// LOT 671-02 : trois valeurs de plus, A LA FIN, l'ordre des precedentes
  /// ne bouge pas. `longueur_de_pas_m` (deux decimales, un tiret tant
  /// qu'aucun intervalle n'a ete accepte), `dispersion_pas_pct` (un tiret
  /// sous deux longueurs acceptees) et `podometre`, l'etat du podometre pour
  /// l'estime (un tiret tant qu'il n'est pas connu).
  static String counters({
    required DateTime at,
    required PositionProfile profile,
    required int? batteryPercent,
    required int acquisitions,
    required int? steps,
    required int? distanceMeters,
    required int restarts,
    required Duration acquisitionWait,
    double? strideMeters,
    double? strideSpreadPercent,
    String? podometer,
  }) => [
    timestamp(at),
    profile.journalLabel,
    kMeasureCountersWord,
    'batterie=${_or(batteryPercent?.toString())}',
    'acquisitions=$acquisitions',
    'pas=${_or(steps?.toString())}',
    'distance_m=${_or(distanceMeters?.toString())}',
    'redemarrages=$restarts',
    'attente_acquisition_s=${seconds(acquisitionWait)}',
    'longueur_de_pas_m=${_or(strideMeters?.toStringAsFixed(2))}',
    'dispersion_pas_pct=${_or(strideSpreadPercent?.round().toString())}',
    'podometre=${_or(podometer)}',
  ].join(kMeasureSeparator);

  /// Des secondes a une decimale.
  static String seconds(Duration d) =>
      (d.inMilliseconds / 1000).toStringAsFixed(1);

  static String _or(String? value) => value ?? kMeasureNoValue;
}

/// Suit les paliers de batterie : un palier tombe a chaque baisse d'au moins
/// [kMeasureBatteryStepPoints] points depuis le dernier palier.
class BatteryStepTracker {
  int? _reference;

  /// Repart de [percent] (demarrage du suivi).
  void reset(int? percent) => _reference = percent;

  /// Vrai si [percent] fait tomber un palier. Une recharge releve la
  /// reference : une baisse se compte depuis le plus haut depuis le palier.
  bool crosses(int? percent) {
    if (percent == null) return false;
    final reference = _reference;
    if (reference == null || percent > reference) {
      _reference = percent;
      return false;
    }
    if (reference - percent < kMeasureBatteryStepPoints) return false;
    _reference = percent;
    return true;
  }
}

/// Ce que l'ecran de mesure montre du journal.
class MeasureJournalSnapshot {
  /// Un releve de l'etat du fichier.
  const MeasureJournalSnapshot({
    required this.path,
    required this.exists,
    required this.lineCount,
    required this.lastLines,
  });

  /// Chemin complet du fichier.
  final String path;

  /// Vrai si le fichier existe deja.
  final bool exists;

  /// Nombre de lignes du fichier.
  final int lineCount;

  /// Les dernieres lignes, telles quelles.
  final List<String> lastLines;
}

/// L'ecrivain du journal, une ligne a la fois.
class MeasureJournal {
  /// [directory] rend le dossier du fichier ; le dossier documents de
  /// l'application en production ([MeasureJournal.documents]).
  MeasureJournal({required Future<Directory> Function() directory})
    : _directory = directory;

  /// Le journal du dossier documents de l'application (path_provider).
  factory MeasureJournal.documents() =>
      MeasureJournal(directory: getApplicationDocumentsDirectory);

  final Future<Directory> Function() _directory;
  Future<void> _queue = Future<void>.value();
  int _failedWrites = 0;

  /// Le proprietaire des verrous de ce journal : le processus, et un tirage
  /// qui distingue deux journaux du meme processus (deux isolates).
  final String _owner = '$pid-${Random().nextInt(1 << 32)}';

  /// Lignes perdues sur une erreur d'ecriture (dossier en lecture seule,
  /// disque plein). Une erreur n'arrete JAMAIS le suivi : elle est comptee.
  int get failedWrites => _failedWrites;

  /// Se complete quand les ajouts deja demandes sont tous passes.
  Future<void> get idle => _queue;

  /// Le fichier du journal.
  Future<File> file() async =>
      File('${(await _directory()).path}/$kMeasureJournalFileName');

  /// Ajoute [line]. Ne leve jamais.
  ///
  /// Les ajouts d'un meme isolate passent l'un apres l'autre ; ceux de deux
  /// isolates passent par le verrou du fichier.
  Future<void> append(String line) {
    final next = _queue.then((_) => _write(line));
    _queue = next;
    return next;
  }

  Future<void> _write(String line) async {
    try {
      final target = await file();
      final lock = File('${target.path}.verrou');
      final stamp = await _acquire(lock);
      if (stamp == null) {
        _failedWrites++;
        return;
      }
      try {
        // UN SEUL appel d'ajout, vidage immediat : la ligne entiere ou rien.
        target.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
      } finally {
        _release(lock, stamp);
      }
    } on Object {
      _failedWrites++;
    }
  }

  /// Pose le verrou et rend sa marque, `proprietaire;heure de pose en ms`,
  /// ou null si l'on renonce.
  ///
  /// TOUTE `FileSystemException` a la pose est un refus a retenter, pas une
  /// erreur : sous Windows, un verrou en cours de suppression refuse la pose
  /// par `PathAccessException`. Apres [kMeasureLockPatience] d'attente, le
  /// verrou en place est examine une fois et leve s'il est perime ; apres
  /// une seconde patience, on renonce.
  Future<String?> _acquire(File lock) async {
    var examined = false;
    final waited = Stopwatch()..start();
    while (true) {
      final stamp =
          '$_owner$kMeasureSeparator${DateTime.now().millisecondsSinceEpoch}';
      try {
        lock.createSync(exclusive: true);
        _mark(lock, stamp);
        return stamp;
      } on FileSystemException {
        if (waited.elapsed > kMeasureLockPatience) {
          if (examined) return null;
          examined = true;
          _breakIfStale(lock);
          waited.reset();
        }
        await Future<void>.delayed(Duration.zero);
      }
    }
  }

  /// Ecrit [stamp] dans le verrou qu'on vient de creer. S'il ne s'ecrit pas,
  /// le verrou, vide et a nous, est leve et la pose est a retenter.
  void _mark(File lock, String stamp) {
    try {
      lock.writeAsStringSync(stamp, flush: true);
    } on FileSystemException {
      _delete(lock);
      rethrow;
    }
  }

  /// Casse le verrou en place s'il est PERIME : pose depuis plus de
  /// [kMeasureLockPatience] selon sa marque — a defaut de marque (verrou d'un
  /// ancien build, ou ecrivain tue entre la creation et la marque), selon
  /// l'heure du fichier. Il n'est casse que s'il porte encore la marque
  /// jugee perimee ; un verrou vivant est laisse a son proprietaire.
  void _breakIfStale(File lock) {
    try {
      final seen = lock.readAsStringSync();
      final posedAt = int.tryParse(seen.split(kMeasureSeparator).last);
      final posed = posedAt == null
          ? lock.lastModifiedSync()
          : DateTime.fromMillisecondsSinceEpoch(posedAt);
      if (DateTime.now().difference(posed) <= kMeasureLockPatience) return;
      if (lock.readAsStringSync() == seen) _delete(lock);
    } on FileSystemException {
      // Leve entre-temps, ou illisible : rien a casser.
    }
  }

  /// Leve le verrou s'il porte encore [stamp]. Casse comme perime puis repose
  /// par un autre, il appartient a cet autre et n'est pas touche.
  void _release(File lock, String stamp) {
    try {
      if (lock.readAsStringSync() == stamp) _delete(lock);
    } on FileSystemException {
      // Deja leve : rien a faire.
    }
  }

  void _delete(File lock) {
    try {
      lock.deleteSync();
    } on FileSystemException {
      // Deja leve : rien a faire.
    }
  }

  /// L'etat du fichier : existence, nombre de lignes, [last] dernieres.
  Future<MeasureJournalSnapshot> snapshot({int last = 5}) async {
    final target = await file();
    if (!target.existsSync()) {
      return MeasureJournalSnapshot(
        path: target.path,
        exists: false,
        lineCount: 0,
        lastLines: const [],
      );
    }
    final lines = (await target.readAsLines())
        .where((l) => l.isNotEmpty)
        .toList();
    return MeasureJournalSnapshot(
      path: target.path,
      exists: true,
      lineCount: lines.length,
      lastLines: lines.sublist(lines.length > last ? lines.length - last : 0),
    );
  }
}
