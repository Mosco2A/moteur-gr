/// L'ENREGISTREUR DU JOURNAL DE MESURE (lot 671-01) : branche sur la cadence
/// de l'isolate de fond, il ecrit le demarrage, chaque releve, les reprises,
/// l'arret, les paliers de batterie et, toutes les dix minutes, la ligne de
/// compteurs. Il vit dans l'isolate de fond, celui qui reste eveille ecran
/// eteint ; l'interface n'ecrit que ce qu'elle seule connait (ecran-on,
/// ecran-off, voir [ScreenStateRecorder]).
///
/// CE QU'IL NE FAIT PAS : il ne fait avancer aucun point, ne touche a aucune
/// statistique, et ne recalcule aucune distance. La distance du trek vit dans
/// l'isolate de l'interface (session en memoire) : illisible d'ici sans
/// toucher au trek, elle vaut un tiret.
///
/// DEPUIS LE LOT 671-02, LES PAS SONT CONSOLIDES : un [StepAccumulator]
/// remplace la soustraction naive, le total ne recule plus apres un
/// redemarrage du telephone, il est persiste ([PodometerStore]) pour qu'un
/// trek qui reprend ne reparte pas de zero, et la ligne de compteurs porte la
/// longueur de pas, sa dispersion et l'etat du podometre.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/gps_cadence.dart';
import '../../../core/services/journal_de_mesure.dart';
import '../domain/accumulateur_de_pas.dart';
import 'background_cadence.dart';
import 'gps_cadence_engine.dart';
import 'podometre_preferences.dart';

/// Ecrit le journal de mesure au fil de la cadence de fond.
class MeasureRecorder implements BackgroundCadenceObserver {
  /// [readBattery] rend le pourcentage de batterie (nul si illisible) ;
  /// [stepCounts] ouvre le flux du podometre (pas depuis le demarrage du
  /// telephone) ; [stepsAllowed] dit si l'activite physique est autorisee.
  /// Sans autorisation, le flux n'est pas ouvert et le champ pas vaut un
  /// tiret : ni erreur, ni blocage, ni nouvelle demande. [podometer] persiste
  /// le total de la session [sessionId] et lit la longueur de pas ; sans lui,
  /// rien n'est persiste et la longueur vaut un tiret.
  MeasureRecorder({
    required MeasureJournal journal,
    required Future<int?> Function() readBattery,
    Stream<int> Function()? stepCounts,
    Future<bool> Function()? stepsAllowed,
    PodometerStore? podometer,
    String Function()? sessionId,
    TimerScheduler? schedule,
    DateTime Function()? now,
  }) : _journal = journal,
       _readBattery = readBattery,
       _stepCounts = stepCounts,
       _stepsAllowed = stepsAllowed,
       _podometer = podometer,
       _sessionId = sessionId ?? (() => ''),
       _schedule = schedule ?? Timer.new,
       _now = now ?? DateTime.now;

  final MeasureJournal _journal;
  final Future<int?> Function() _readBattery;
  final Stream<int> Function()? _stepCounts;
  final Future<bool> Function()? _stepsAllowed;
  final PodometerStore? _podometer;
  final String Function() _sessionId;
  final TimerScheduler _schedule;
  final DateTime Function() _now;
  final BatteryStepTracker _battery = BatteryStepTracker();

  PositionProfile _profile = PositionProfile.map;
  StreamSubscription<int>? _stepsSubscription;
  StepAccumulator _steps = StepAccumulator();
  EstimateReadiness? _readiness;
  DateTime? _stepsSavedAt;
  Timer? _countersTimer;

  /// Positions recues depuis le dernier demarrage.
  int acquisitions = 0;

  /// Demarrages du recepteur depuis le dernier demarrage du suivi.
  int restarts = 0;

  /// Somme des temps du premier point depuis le dernier demarrage.
  Duration acquisitionWait = Duration.zero;

  /// Pas comptes depuis le debut de la session, consolides : ils ne reculent
  /// jamais. Nul sans podometre, sans autorisation ou apres une erreur.
  int? get steps => _steps.total;

  /// Ce que le podometre permet a l'estime ; nul tant que rien n'est su.
  EstimateReadiness? get readiness => _readiness;

  @override
  Future<void> started(PositionProfile profile) async {
    _profile = profile;
    acquisitions = 0;
    restarts = 0;
    acquisitionWait = Duration.zero;
    _steps = await _podometer?.restoreSteps(_sessionId()) ?? StepAccumulator();
    _readiness = null;
    _stepsSavedAt = null;
    await _listenSteps();
    final battery = await _readBatterySafely();
    _battery.reset(battery);
    await _event(MeasureEvent.demarrage, battery: battery);
    _armCounters();
  }

  @override
  Future<void> switched(PositionProfile profile) async {
    _profile = profile;
    await _event(MeasureEvent.reprise, battery: await _readBatterySafely());
  }

  @override
  void sourceStarted() => restarts++;

  @override
  Future<void> received(Position? position, Duration? timeToFix) async {
    if (position != null) acquisitions++;
    if (timeToFix != null) acquisitionWait += timeToFix;
    await _saveSteps();
    final battery = await _readBatterySafely();
    await _event(
      MeasureEvent.releve,
      battery: battery,
      position: position,
      timeToFix: timeToFix,
    );
    await _batteryStep(battery);
  }

  @override
  Future<void> stopped() async {
    _countersTimer?.cancel();
    _countersTimer = null;
    await _event(MeasureEvent.arret, battery: await _readBatterySafely());
    await _stepsSubscription?.cancel();
    _stepsSubscription = null;
    await _saveSteps();
  }

  /// Ecrit la ligne de compteurs (et un palier de batterie s'il tombe).
  Future<void> writeCounters() async {
    final battery = await _readBatterySafely();
    await _saveSteps();
    final stride = await _podometer?.readStride();
    await _journal.append(
      MeasureLine.counters(
        at: _now(),
        profile: _profile,
        batteryPercent: battery,
        acquisitions: acquisitions,
        steps: steps,
        distanceMeters: null,
        restarts: restarts,
        acquisitionWait: acquisitionWait,
        strideMeters: stride != null && stride.isCalibrated
            ? stride.meters
            : null,
        strideSpreadPercent: stride?.spreadPercent,
        podometer: _readiness?.word,
      ),
    );
    await _batteryStep(battery);
  }

  void _armCounters() {
    _countersTimer?.cancel();
    _countersTimer = _schedule(kMeasureCountersPeriod, () async {
      await writeCounters();
      if (_countersTimer != null) _armCounters();
    });
  }

  /// LES PAS, ouverts a un seul endroit, l'isolate de fond. Ils sont ecrits
  /// au journal et persistes ; ils ne font avancer aucun point.
  Future<void> _listenSteps() async {
    unawaited(_stepsSubscription?.cancel());
    _stepsSubscription = null;
    final open = _stepCounts;
    if (open == null) return;
    if (!await _isAllowed()) {
      _steps.fail();
      await _setReadiness(EstimateReadiness.permissionRefused);
      return;
    }
    await _setReadiness(EstimateReadiness.possible);
    _stepsSubscription = open().listen(
      _onRawSteps,
      // Le service du podometre a deja journalise l'erreur (ErrorHandler) :
      // ici, le total devient nul, l'etat est retenu, et le suivi continue.
      onError: (Object error) {
        _steps.fail();
        unawaited(_setReadiness(EstimateReadiness.forError(error)));
      },
      cancelOnError: true,
    );
  }

  void _onRawSteps(int raw) {
    _steps.add(raw);
    final saved = _stepsSavedAt;
    if (saved == null || _now().difference(saved) >= kStepsSavePeriod) {
      unawaited(_saveSteps());
    }
  }

  Future<void> _saveSteps() async {
    final store = _podometer;
    if (store == null || _steps.lastRaw == null) return;
    _stepsSavedAt = _now();
    await store.saveSteps(_sessionId(), _steps);
  }

  Future<void> _setReadiness(EstimateReadiness readiness) async {
    _readiness = readiness;
    await _podometer?.saveReadiness(readiness);
  }

  Future<bool> _isAllowed() async {
    final allowed = _stepsAllowed;
    if (allowed == null) return true;
    try {
      return await allowed();
    } on Object {
      return false;
    }
  }

  Future<void> _batteryStep(int? battery) async {
    if (!_battery.crosses(battery)) return;
    await _event(MeasureEvent.palierBatterie, battery: battery);
  }

  Future<void> _event(
    MeasureEvent event, {
    required int? battery,
    Position? position,
    Duration? timeToFix,
  }) => _journal.append(
    MeasureLine.event(
      at: _now(),
      profile: _profile,
      event: event,
      batteryPercent: battery,
      steps: steps,
      latitude: position?.latitude,
      longitude: position?.longitude,
      accuracyMeters: position?.accuracy,
      timeToFix: timeToFix,
    ),
  );

  Future<int?> _readBatterySafely() async {
    try {
      return await _readBattery();
    } on Object {
      return null;
    }
  }
}

/// Ecrit ecran-on et ecran-off, depuis l'isolate de l'interface.
///
/// LE CYCLE DE VIE NE DISTINGUE PAS L'ECRAN ETEINT DE L'APPLICATION MASQUEE :
/// `paused` arrive dans les deux cas. ecran-off veut donc dire « l'application
/// a quitte le premier plan », et ecran-on « elle y est revenue ». Aucun code
/// natif n'est ajoute pour faire mieux.
class ScreenStateRecorder {
  /// [readProfile] rend le profil en vigueur (le canal partage).
  ScreenStateRecorder({
    required MeasureJournal journal,
    required Future<PositionProfile> Function() readProfile,
    required Future<int?> Function() readBattery,
    DateTime Function()? now,
  }) : _journal = journal,
       _readProfile = readProfile,
       _readBattery = readBattery,
       _now = now ?? DateTime.now;

  final MeasureJournal _journal;
  final Future<PositionProfile> Function() _readProfile;
  final Future<int?> Function() _readBattery;
  final DateTime Function() _now;
  AppLifecycleListener? _listener;

  /// L'evenement du journal pour [state] ; nul pour les etats de passage.
  static MeasureEvent? eventFor(AppLifecycleState state) => switch (state) {
    AppLifecycleState.resumed => MeasureEvent.ecranOn,
    AppLifecycleState.paused => MeasureEvent.ecranOff,
    _ => null,
  };

  /// Commence a ecouter le cycle de vie.
  void start() {
    _listener ??= AppLifecycleListener(
      onStateChange: (state) => unawaited(record(state)),
    );
  }

  /// Cesse d'ecouter.
  void stop() {
    _listener?.dispose();
    _listener = null;
  }

  /// Ecrit la ligne de [state], s'il en a une. Ne leve jamais.
  Future<void> record(AppLifecycleState state) async {
    final event = eventFor(state);
    if (event == null) return;
    PositionProfile profile;
    int? battery;
    try {
      profile = await _readProfile();
    } on Object {
      profile = PositionProfile.map;
    }
    try {
      battery = await _readBattery();
    } on Object {
      battery = null;
    }
    await _journal.append(
      MeasureLine.event(
        at: _now(),
        profile: profile,
        event: event,
        batteryPercent: battery,
      ),
    );
  }
}
