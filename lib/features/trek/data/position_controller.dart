/// LE ROBINET UNIQUE GPS de l'isolate d'interface (lot 671-00) : une seule
/// souscription a la source de positions, diffusee a tous ceux qui ecoutent.
library;

import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../../core/error/error_handler.dart';

/// Profil de captation GPS porte par le [PositionController].
///
/// Vocabulaire de la conception « batterie d'abord » (lot 671) :
/// - [map] : profil « carte », suivi fin, celui d'aujourd'hui ;
/// - [batteryFirst] : profil « batterie d'abord » ;
/// - [stationary] : profil « arret » ;
/// - [lowBattery] : profil « batterie basse ».
///
/// AU LOT 671-00 SEUL [map] EST ACTIF ([PositionController.activeProfiles]) :
/// les trois autres sont nommes pour poser le canal, ils ne captent rien.
enum PositionProfile {
  /// « carte ».
  map,

  /// « batterie d'abord ».
  batteryFirst,

  /// « arret ».
  stationary,

  /// « batterie basse ».
  lowBattery;

  /// Le profil range sous [value] ; absent ou inconnu = [map].
  ///
  /// C'est la lecture TOLERANTE du canal partage avec l'isolate de fond : une
  /// valeur ecrite par une version future ou abimee ne doit jamais couper la
  /// captation, elle retombe sur le profil d'aujourd'hui.
  static PositionProfile fromStored(String? value) {
    for (final profile in values) {
      if (profile.name == value) return profile;
    }
    return map;
  }
}

/// Fabrique du flux de positions : la signature de
/// `Geolocator.getPositionStream`, injectable pour les tests.
typedef PositionStreamFactory =
    Stream<Position> Function({required LocationSettings locationSettings});

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
class PositionController {
  /// Sans argument, branche sur Geolocator et n'ecrit le profil nulle part.
  ///
  /// [currentPosition] a la signature de `Geolocator.getCurrentPosition` ;
  /// [writeProfile] ecrit le profil dans le canal lu par l'isolate de fond.
  PositionController({
    PositionStreamFactory? positionStream,
    Future<Position> Function({required LocationSettings locationSettings})?
    currentPosition,
    Future<void> Function(PositionProfile profile)? writeProfile,
  }) : _positionStream = positionStream ?? _geolocatorStream,
       _currentPosition = currentPosition ?? _geolocatorCurrent,
       _writeProfile = writeProfile;

  final PositionStreamFactory _positionStream;
  final Future<Position> Function({required LocationSettings locationSettings})
  _currentPosition;
  final Future<void> Function(PositionProfile profile)? _writeProfile;

  /// Les profils que ce lot sait servir. Les autres sont refuses par
  /// [setProfile] tant qu'un lot ne leur a pas donne de reglages.
  static const Set<PositionProfile> activeProfiles = {PositionProfile.map};

  /// Les reglages du profil [PositionProfile.map] : ceux de la souscription la
  /// plus utilisee avant le lot 671-00 (carte, hors-trace, suivi), RECOPIES
  /// tels quels — precision haute, filtre de 10 m, intervalle par defaut.
  static const LocationSettings mapSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  PositionProfile _profile = PositionProfile.map;
  PositionProfile? _publishedProfile;
  StreamSubscription<Position>? _source;
  StreamController<Position>? _output;

  /// Le profil courant.
  PositionProfile get profile => _profile;

  /// Les reglages Geolocator de [profile].
  ///
  /// Au lot 671-00, seul [PositionProfile.map] a des reglages propres ; les
  /// profils nommes mais pas encore regles retombent sur ceux de la carte.
  static LocationSettings settingsFor(PositionProfile profile) =>
      switch (profile) {
        PositionProfile.map => mapSettings,
        PositionProfile.batteryFirst ||
        PositionProfile.stationary ||
        PositionProfile.lowBattery => mapSettings,
      };

  /// LE flux de positions de l'interface, diffuse a abonnes multiples.
  ///
  /// Tous les abonnes recoivent chaque position, d'une seule souscription a
  /// la source. Si la source se termine, les abonnes du moment recoivent la
  /// fin et une ecoute ulterieure repart sur une source neuve.
  Stream<Position> get positions => (_output ??= _newOutput()).stream;

  /// Une position unique, prise avec les reglages du profil courant.
  Future<Position> currentPosition() =>
      _currentPosition(locationSettings: settingsFor(_profile));

  /// Change le profil courant et le publie pour l'isolate de fond.
  ///
  /// Refuse un profil hors de [activeProfiles] : au lot 671-00, un profil sans
  /// reglages changerait la cadence sans que personne l'ait decide.
  Future<void> setProfile(PositionProfile profile) async {
    if (!activeProfiles.contains(profile)) {
      throw UnsupportedError('Profil GPS non actif a ce lot : ${profile.name}');
    }
    _profile = profile;
    await _publishProfile();
  }

  StreamController<Position> _newOutput() =>
      StreamController<Position>.broadcast(onListen: _open, onCancel: _close);

  void _open() {
    unawaited(_publishProfile());
    _source = _positionStream(locationSettings: settingsFor(_profile)).listen(
      (position) => _output?.add(position),
      onError: (Object error, StackTrace stackTrace) {
        ErrorHandler.log(
          error,
          stackTrace: stackTrace,
          context: 'PositionController.positions',
        );
        _output?.addError(error, stackTrace);
      },
      onDone: () {
        _source = null;
        final output = _output;
        _output = null;
        unawaited(output?.close());
      },
      cancelOnError: false,
    );
  }

  Future<void> _close() async {
    final source = _source;
    _source = null;
    await source?.cancel();
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
