/// LE ROBINET UNIQUE GPS de l'isolate d'interface (lot 671-00) : une seule
/// source de positions, diffusee a tous ceux qui ecoutent, au rythme du profil
/// (lot 671-01 : flux continu pour la carte, tir unique pour les profils
/// batterie).
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';
import '../../../core/services/gps_cadence.dart';
import 'gps_cadence_engine.dart';
import 'gps_settings_mapping.dart';

// Le profil vit dans le socle depuis le lot 671-01 (classe pure des cadences),
// la fabrique de flux dans le moteur des cadences ; ils restent lisibles ici
// pour tous ceux qui les prenaient au robinet.
export '../../../core/services/gps_cadence.dart' show PositionProfile;
export 'gps_cadence_engine.dart' show PositionStreamFactory;

/// Possede LA souscription GPS de l'isolate d'interface.
///
/// POURQUOI UN SEUL ROBINET. Avant le lot 671-00, cinq endroits de l'interface
/// ouvraient chacun leur flux (carte, hors-trace, suivi, detection d'etape,
/// arrivees). Le greffon geolocator ne garde pourtant qu'UN flux natif par
/// isolate, regle par le premier qui l'ouvre : les reglages des suivants
/// etaient ignores en silence. Ce controleur rend ce fait explicite et
/// pilotable : une source, un profil, un flux diffuse.
///
/// CYCLE DE VIE. La source est ouverte a la PREMIERE ecoute de [positions] et
/// fermee quand le DERNIER abonne part ; une nouvelle ecoute la rouvre.
///
/// CADENCE (lot 671-01). La source suit le [GpsCadence] du profil : un flux
/// continu pour la carte, un tir unique toutes les 3 ou 15 minutes pour les
/// profils batterie, recepteur relache entre deux tirs. Changer de profil
/// prend effet sans couper les abonnes.
class PositionController {
  /// Sans argument, branche sur Geolocator et n'ecrit le profil nulle part.
  ///
  /// [currentPosition] a la signature de `Geolocator.getCurrentPosition` ;
  /// [writeProfile] ecrit le profil dans le canal lu par l'isolate de fond ;
  /// [readProfile] relit ce canal a la premiere ecoute, pour qu'une interface
  /// relancee reprenne le profil choisi au lieu de l'ecraser par la carte.
  PositionController({
    PositionStreamFactory? positionStream,
    Future<Position> Function({required LocationSettings locationSettings})?
    currentPosition,
    Future<void> Function(PositionProfile profile)? writeProfile,
    Future<PositionProfile> Function()? readProfile,
    TimerScheduler? schedule,
    DateTime Function()? now,
  }) : _currentPosition = currentPosition ?? _geolocatorCurrent,
       _writeProfile = writeProfile,
       _readProfile = readProfile {
    _engine = GpsCadenceEngine(
      openStream: positionStream ?? _geolocatorStream,
      takeShot: (settings) => _currentPosition(locationSettings: settings),
      streamSettings: interfaceStreamSettings,
      onFix: (position, _) {
        _lastFix = position;
        _output?.add(position);
      },
      onStreamError: (Object error, StackTrace stackTrace) {
        ErrorHandler.log(
          error,
          stackTrace: stackTrace,
          context: 'PositionController.positions',
        );
        _output?.addError(error, stackTrace);
      },
      onStreamDone: () {
        _engine.stop();
        final output = _output;
        _output = null;
        unawaited(output?.close());
      },
      schedule: schedule,
      now: now,
    );
  }

  final Future<Position> Function({required LocationSettings locationSettings})
  _currentPosition;
  final Future<void> Function(PositionProfile profile)? _writeProfile;
  final Future<PositionProfile> Function()? _readProfile;
  late final GpsCadenceEngine _engine;

  /// Les profils que ce lot sait servir. Les autres sont refuses par
  /// [setProfile] tant qu'un lot ne leur a pas donne de reglages.
  static const Set<PositionProfile> activeProfiles = {
    PositionProfile.map,
    PositionProfile.batteryFirst,
    PositionProfile.lowBattery,
  };

  /// Les reglages du profil [PositionProfile.map] : ceux de la souscription la
  /// plus utilisee avant le lot 671-00 (carte, hors-trace, suivi) — precision
  /// haute, filtre de 10 m, intervalle par defaut — traduits de
  /// [GpsCadence.map] par la seule fonction de correspondance (lot 671-01).
  static final LocationSettings mapSettings = interfaceStreamSettings(
    GpsCadence.map,
  );

  PositionProfile _profile = PositionProfile.map;
  Position? _lastFix;
  PositionProfile? _publishedProfile;
  bool _restored = false;
  bool _chosen = false;
  StreamController<Position>? _output;

  /// Le profil courant.
  PositionProfile get profile => _profile;

  /// Vrai si une souscription au flux de la source est vivante.
  bool get hasLiveSubscription => _engine.hasLiveSubscription;

  /// Les reglages Geolocator d'une position prise pour [profile] : ceux du
  /// flux de la carte, ou ceux d'un tir unique pour les profils batterie.
  static LocationSettings settingsFor(PositionProfile profile) {
    final cadence = GpsCadence.of(profile);
    return cadence.isSingleShot ? singleShotSettings(cadence) : mapSettings;
  }

  /// LE flux de positions de l'interface, diffuse a abonnes multiples.
  ///
  /// Tous les abonnes recoivent chaque position, d'une seule source. Si la
  /// source se termine, les abonnes du moment recoivent la fin et une ecoute
  /// ulterieure repart sur une source neuve.
  Stream<Position> get positions => (_output ??= _newOutput()).stream;

  /// Une position unique, prise avec les reglages du profil courant.
  Future<Position> currentPosition() =>
      _currentPosition(locationSettings: settingsFor(_profile));

  /// LA DERNIERE POSITION RECUE PAR CE ROBINET (lot 671-04), flux ou tir,
  /// nulle avant la premiere. UNE MEMOIRE, PAS UNE ECOUTE : la lire n'ouvre
  /// rien, ne tire rien, et ne garde aucune souscription en vie.
  Position? get lastFix => _lastFix;

  /// UN TIR UNIQUE A LA DEMANDE (lot 671-04, le SOS) : la precision du
  /// profil — haute, c'est la seule du depot ([GpsPrecision.high]) — et
  /// [kSingleShotMaxDelay] au plus, quel que soit le profil (en profil carte
  /// aussi, ou le flux n'a pas de delai). Aucun flux n'est ouvert ; la
  /// position obtenue devient [lastFix].
  Future<Position> singleShot() async {
    final position = await _currentPosition(
      locationSettings: singleShotSettings(GpsCadence.of(_profile)),
    );
    _lastFix = position;
    return position;
  }

  /// Change le profil courant, le publie pour l'isolate de fond, et change la
  /// cadence de la source sans couper ses abonnes.
  ///
  /// Refuse un profil hors de [activeProfiles] : un profil sans reglages
  /// changerait la cadence sans que personne l'ait decide.
  Future<void> setProfile(PositionProfile profile) async {
    if (!activeProfiles.contains(profile)) {
      throw UnsupportedError('Profil GPS non actif a ce lot : ${profile.name}');
    }
    _chosen = true;
    _profile = profile;
    if (_engine.cadence != null) _engine.switchTo(GpsCadence.of(profile));
    await _publishProfile();
  }

  StreamController<Position> _newOutput() =>
      StreamController<Position>.broadcast(onListen: _open, onCancel: _close);

  void _open() {
    _engine.start(GpsCadence.of(_profile));
    unawaited(_restoreThenPublish());
  }

  void _close() => _engine.stop();

  /// A la premiere ecoute, reprend le profil range dans le canal (s'il est
  /// servi et que personne n'en a choisi un entre-temps), sinon publie le
  /// profil courant.
  Future<void> _restoreThenPublish() async {
    final read = _readProfile;
    if (read != null && !_restored) {
      _restored = true;
      try {
        final stored = await read();
        if (!_chosen && activeProfiles.contains(stored)) {
          _profile = stored;
          _publishedProfile = stored;
          if (_engine.cadence != null) _engine.switchTo(GpsCadence.of(stored));
          return;
        }
      } on Object catch (e, st) {
        ErrorHandler.log(
          e,
          stackTrace: st,
          context: 'PositionController.restoreProfile',
        );
      }
    }
    await _publishProfile();
  }

  /// Ecrit le profil courant dans le canal de l'isolate de fond, s'il a
  /// change depuis la derniere ecriture.
  Future<void> _publishProfile() async {
    final write = _writeProfile;
    if (write == null || _publishedProfile == _profile) return;
    final profile = _profile;
    _publishedProfile = profile;
    try {
      await write(profile);
    } on Object catch (e, st) {
      _publishedProfile = null;
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'PositionController.publishProfile',
      );
    }
  }

  static Stream<Position> _geolocatorStream({
    required LocationSettings locationSettings,
  }) => Geolocator.getPositionStream(locationSettings: locationSettings);

  static Future<Position> _geolocatorCurrent({
    required LocationSettings locationSettings,
  }) => Geolocator.getCurrentPosition(
    desiredAccuracy: locationSettings.accuracy,
    timeLimit: locationSettings.timeLimit,
  );
}
