/// LES TROIS CADENCES GPS DU BUILD DE MESURE (lot 671-01) : une seule
/// definition, en Dart pur, lue par l'isolate d'interface ET l'isolate de fond.
///
/// POURQUOI EN DART PUR, ET POURQUOI DANS LE SOCLE. Ce fichier n'importe ni
/// Flutter ni aucun greffon : il ne nomme donc pas `LocationAccuracy`, qui
/// vient du greffon geolocator. Il porte SON PROPRE type de precision
/// ([GpsPrecision]), et UNE SEULE fonction de `lib/features/trek/data/`
/// (`gps_settings_mapping.dart`) le traduit en reglages du greffon. Il vit dans
/// le socle parce que le journal de mesure (`journal_de_mesure.dart`, socle
/// lui aussi) ecrit le nom du profil, et que le socle ne lit aucune feature.
library;

/// Profil de captation GPS.
///
/// Vocabulaire de la conception « batterie d'abord » (lot 671) :
/// - [map] : profil « carte », flux continu, celui d'avant le lot ;
/// - [batteryFirst] : profil « batterie d'abord », un tir toutes les 3 min ;
/// - [stationary] : profil « arret », nomme, sans cadence a ce lot ;
/// - [lowBattery] : profil « batterie basse », un tir toutes les 15 min.
///
/// Le nom Dart ([Enum.name]) est la valeur ecrite dans le canal partage avec
/// l'isolate de fond ; [journalLabel] est le mot ecrit dans le journal.
enum PositionProfile {
  /// « carte ».
  map('carte'),

  /// « batterie d'abord ».
  batteryFirst('batterieDabord'),

  /// « arret ».
  stationary('arret'),

  /// « batterie basse ».
  lowBattery('batterieBasse');

  const PositionProfile(this.journalLabel);

  /// Le mot du profil dans le champ 2 d'une ligne du journal de mesure.
  final String journalLabel;

  /// Le profil range sous [value] ; absent ou inconnu = [map].
  ///
  /// C'est la lecture TOLERANTE du canal partage avec l'isolate de fond : une
  /// valeur ecrite par une version future ou abimee ne doit jamais couper la
  /// captation, elle retombe sur le profil d'avant le lot.
  static PositionProfile fromStored(String? value) {
    for (final profile in values) {
      if (profile.name == value) return profile;
    }
    return map;
  }
}

/// Comment le recepteur est sollicite.
enum GpsCaptureMode {
  /// Un flux continu : le recepteur reste ouvert et pousse ses positions.
  stream,

  /// Un tir unique a la fois : le recepteur est ouvert pour UN point, puis
  /// relache jusqu'au tir suivant. Aucune souscription ne vit entre deux tirs.
  singleShot,
}

/// La precision demandee au recepteur, dans le vocabulaire de l'application.
///
/// UNE SEULE VALEUR, ET C'EST LA MESURE : les trois profils demandent tous la
/// precision haute. Ce qui change entre eux est le RYTHME, pas la finesse.
enum GpsPrecision {
  /// Precision haute.
  high,
}

/// Filtre de distance du profil carte dans l'isolate d'interface : celui du
/// robinet unique du lot 671-00, inchange. L'isolate de fond garde le sien
/// (`kBgMinKeepDistanceMeters`, 12 m), recu par la poignee de main.
const int kMapDistanceFilterMeters = 10;

/// Delai maximum d'un tir unique : au-dela, le tir est journalise sans
/// position, et rien n'est retente avant le tir suivant.
const Duration kSingleShotMaxDelay = Duration(seconds: 15);

/// Periode des tirs du profil « batterie d'abord » (decision du 06/10/2026 :
/// le GPS recale toutes les 3 minutes).
const Duration kBatteryFirstShotPeriod = Duration(minutes: 3);

/// Periode des tirs du profil « batterie basse ».
const Duration kLowBatteryShotPeriod = Duration(minutes: 15);

/// Marge ajoutee au silence normal d'un profil de tir avant que la sonde de
/// vie ne s'en inquiete : le systeme peut retarder un minuteur.
const Duration kSingleShotSilenceMargin = Duration(seconds: 30);

/// Periode de la sonde de vie de l'isolate de fond en flux continu.
const Duration kStreamWatchdogPeriod = Duration(seconds: 20);

/// Periode du battement (compteur pousse vers l'interface) en flux continu.
const Duration kStreamHeartbeatPeriod = Duration(seconds: 30);

/// Ce qu'un profil demande au recepteur : mode, precision, filtre, rythme.
class GpsCadence {
  const GpsCadence._({
    required this.mode,
    required this.precision,
    this.distanceFilterMeters,
    this.period,
    this.maxDelay,
  });

  /// Profil carte : flux continu, precision haute, filtre de 10 m.
  static const GpsCadence map = GpsCadence._(
    mode: GpsCaptureMode.stream,
    precision: GpsPrecision.high,
    distanceFilterMeters: kMapDistanceFilterMeters,
  );

  /// Profil batterie d'abord : un tir toutes les 3 min, 15 s au plus.
  static const GpsCadence batteryFirst = GpsCadence._(
    mode: GpsCaptureMode.singleShot,
    precision: GpsPrecision.high,
    period: kBatteryFirstShotPeriod,
    maxDelay: kSingleShotMaxDelay,
  );

  /// Profil batterie basse : un tir toutes les 15 min, 15 s au plus.
  static const GpsCadence lowBattery = GpsCadence._(
    mode: GpsCaptureMode.singleShot,
    precision: GpsPrecision.high,
    period: kLowBatteryShotPeriod,
    maxDelay: kSingleShotMaxDelay,
  );

  /// Flux continu ou tir unique.
  final GpsCaptureMode mode;

  /// La precision demandee.
  final GpsPrecision precision;

  /// Filtre de distance du flux, en metres ; nul en tir unique.
  final int? distanceFilterMeters;

  /// Ecart entre deux tirs ; nul en flux continu.
  final Duration? period;

  /// Attente maximale d'un tir ; nulle en flux continu.
  final Duration? maxDelay;

  /// La cadence de [profile]. Le profil « arret », sans cadence a ce lot,
  /// garde celle de la carte : un profil sans reglages ne coupe jamais le GPS.
  static GpsCadence of(PositionProfile profile) => switch (profile) {
    PositionProfile.map || PositionProfile.stationary => map,
    PositionProfile.batteryFirst => batteryFirst,
    PositionProfile.lowBattery => lowBattery,
  };

  /// Vrai pour un profil de tir unique.
  bool get isSingleShot => mode == GpsCaptureMode.singleShot;

  /// Le silence NORMAL entre deux points d'un profil de tir : periode, plus
  /// delai maximum, plus [kSingleShotSilenceMargin]. Nul en flux continu, ou
  /// le silence n'a pas de duree attendue.
  Duration? get normalSilence =>
      isSingleShot ? period! + maxDelay! + kSingleShotSilenceMargin : null;

  /// Periode de la sonde de vie : 20 s en flux, le silence normal en tir.
  Duration get watchdogPeriod => normalSilence ?? kStreamWatchdogPeriod;

  /// Periode du battement : 30 s en flux, le silence normal en tir.
  Duration get heartbeatPeriod => normalSilence ?? kStreamHeartbeatPeriod;
}
