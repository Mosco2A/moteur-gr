import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/error/error_handler.dart';

/// Seuil de batterie basse (20 %) — palier commun au pilotage batterie
/// (battery_aware_location_controller) et a la capture de fond. Conserve tel
/// quel : au-dessous, on plafonne la precision GPS (economie).
const int kLowBatteryThreshold = 20;

/// Canal de notification Android du foreground service de capture.
///
/// Suffixe `_v2` (retour terrain) : Android FIGE l'importance d'un canal a
/// sa creation. Si un ancien canal existait en importance LOW, y remonter
/// l'importance serait ignore par l'OS. Un nouvel id cree un canal neuf en
/// importance DEFAULT -> la notification de suivi redevient visible (heads-up)
/// sans reinstaller l'app. Generique (aucun sentier particulier).
const String kForegroundChannelId = 'moteur_gr_gps_foreground_v2';

/// Nom lisible du canal foreground (visible dans les reglages Android).
const String kForegroundChannelName = 'Suivi GPS';

/// Id fixe de la notification persistante du foreground service.
const int kForegroundNotificationId = 9001;

/// Cles SharedPreferences du HANDSHAKE FIABLE UI -> isolate de fond.
///
/// Pourquoi ce handshake (retour terrain, bug « trace qui tire tout
/// droit ») : l'isolate de fond ne peut PAS dependre d'un message IPC envoye
/// juste apres `startService()` — au cold start ce message est perdu ~100 % du
/// temps (le pipe natif et le broadcast stream de l'isolate ne sont pas encore
/// prets). L'UI ecrit donc la config ICI (store natif persistant, lisible depuis
/// n'importe quel isolate) AVANT `startService()` ; l'isolate la relit a son
/// demarrage (`prefs.reload()`) et s'abonne au GPS immediatement.
const String kPrefsBgSessionId = 'bg_gps_session_id';
const String kPrefsBgTrailId = 'bg_gps_trail_id';
const String kPrefsBgStageInfo = 'bg_gps_stage_info';
const String kPrefsBgDistanceFilter = 'bg_gps_distance_filter';

/// Cle du TAMPON de points captes par l'isolate de fond, en attente de drain.
///
/// Substitut GENERIQUE d'un stockage de fond dedie : ici le socle
/// persiste via Drift, mais la base Drift n'est pas partageable entre isolates
/// (ouverte en memoire cote UI). L'isolate de fond serialise donc ses points
/// dans SharedPreferences (isolate-safe, aucune contention de verrou SQLite) ;
/// l'isolate UI les DRAINE vers la table de trace (sessionTrackPoints) au retour
/// au premier plan. Meme architecture « stockage de fond dedie + drain » que le
/// l'implementation de reference, sans dependance a un store tiers.
const String kPrefsBgPointsBuffer = 'bg_gps_points_buffer';

/// Seuil de distance (metres) au-dela duquel un nouveau point est RETENU.
///
/// ~12 m : un poil au-dessus du distanceFilter courant (10 m) pour absorber la
/// derive GPS a l'arret sans hacher la trace en marche. En-dessous, le point est
/// du sur-place et jete. Valeur GENERIQUE (aucun sentier).
const double kBgMinKeepDistanceMeters = 12.0;

/// Delai (defaut) sans point retenu au-dela duquel la sonde de vie force un
/// point « keep-alive ». Distingue « en pause » (isolate vivant, 1 pt / 5 min)
/// de « appli morte » (plus aucun point) sans encrasser la trace.
const Duration kBgKeepAliveThreshold = Duration(minutes: 5);

/// Periode de la sonde de vie (watchdog) dans l'isolate de fond.
const Duration kBgWatchdogPeriod = Duration(seconds: 20);

/// Periode du heartbeat (compteur autoritaire pousse vers l'UI).
const Duration kBgHeartbeatPeriod = Duration(seconds: 30);

/// Log VISIBLE au `adb logcat` (prefixe `BGGPS`), meme en release.
///
/// Retour terrain : `developer.log` n'apparait PAS en release au logcat (seul
/// `print`/`debugPrint` remonte sous le tag `flutter`). On loggue donc via
/// `debugPrint` pour un filtrage terrain direct : `adb logcat | grep BGGPS`.
void _logBg(String message) {
  debugPrint('BGGPS ${DateTime.now().toIso8601String()} $message');
}

/// Faut-il RETENIR (persister) ce point ?
///
/// On ne retient un point que si sa distance au DERNIER POINT RETENU atteint
/// [threshold] — ou si c'est le tout premier (aucun retenu). Filtre la derive
/// GPS a l'arret (Firestore/stockage/batterie gonfles, trace encrassee).
/// Fonction PURE (Haversine en Dart pur) -> couverte par test unitaire.
bool bgShouldKeepPosition({
  required double? lastKeptLat,
  required double? lastKeptLon,
  required double newLat,
  required double newLon,
  double threshold = kBgMinKeepDistanceMeters,
}) {
  if (lastKeptLat == null || lastKeptLon == null) return true;
  final meters =
      Geolocator.distanceBetween(lastKeptLat, lastKeptLon, newLat, newLon);
  return meters >= threshold;
}

/// La sonde de vie doit-elle forcer un point « keep-alive » ?
///
/// True si AUCUN point n'a ete retenu depuis au moins [threshold] (defaut
/// 5 min), ou si aucun ne l'a encore ete. Sous le filtre de distance, ne rien
/// capter a l'arret est NORMAL : on ne force donc une capture que de loin en
/// loin pour prouver que l'isolate vit. Fonction PURE -> testable.
bool bgIsKeepAliveDue(
  DateTime? lastKeptAt,
  DateTime now, {
  Duration threshold = kBgKeepAliveThreshold,
}) =>
    lastKeptAt == null || now.difference(lastKeptAt) >= threshold;

/// Faut-il (re)s'abonner au flux GPS ?
///
/// On NE se re-abonne PAS si on est deja abonne (garde anti-churn : annuler /
/// re-creer le stream peut tuer la capture en silence — hypothese H-DOUBLE-FGS
/// du diagnostic terrain). Extrait en fonction PURE pour test unitaire.
bool bgShouldSubscribe({required bool hasSubscription}) => !hasSubscription;

/// Libelle (content) de la notification persistante, refletant l'etat de la
/// capture de fond : `N pts · dernier HH:MM:SS`, ou `N pts · en attente` tant
/// qu'aucun fix n'est arrive. Rend le compteur LISIBLE ecran verrouille (la
/// preuve terrain que la capture vit). Fonction PURE -> testable.
String bgNotificationContent(int positionsReceived, DateTime? lastFixAt) {
  final pts = '$positionsReceived pts';
  if (lastFixAt == null) return '$pts · en attente';
  final h = lastFixAt.hour.toString().padLeft(2, '0');
  final m = lastFixAt.minute.toString().padLeft(2, '0');
  final s = lastFixAt.second.toString().padLeft(2, '0');
  return '$pts · dernier $h:$m:$s';
}

/// Encode un point de fond en Map JSON-serialisable pour le tampon de drain.
Map<String, dynamic> bgEncodePoint({
  required String id,
  required String sessionId,
  required String trailId,
  required double latitude,
  required double longitude,
  required double altitude,
  required double accuracy,
  required double speed,
  required DateTime timestamp,
}) =>
    <String, dynamic>{
      'id': id,
      'sessionId': sessionId,
      'trailId': trailId,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'accuracy': accuracy,
      'speed': speed,
      'timestamp': timestamp.toIso8601String(),
    };

/// Etat de demarrage du foreground service, tel que verifie par
/// l'auto-diagnostic (~4 s apres start). Rend VISIBLE un echec silencieux : le
/// plugin AVALE l'erreur native (SecurityException / ForegroundServiceStart
/// NotAllowed sur Android 14+), donc cote Dart aucun throw ne remonte.
enum GpsServiceStartStatus {
  /// Aucun demarrage en cours (repos / arrete).
  idle,

  /// start() appele, verification de l'etat reel du service en cours (~4 s).
  verifying,

  /// Le service tourne REELLEMENT (isRunning natif = true).
  running,

  /// Le service N'A PAS demarre : l'OS a refuse / tue le foreground service.
  /// L'UI doit afficher un message visible et persistant.
  failedToStart,
}

/// Statistiques de capture de fond, poussees depuis l'isolate vers l'UI
/// (evenements `trackPoint` + `heartbeat`). Alimente une ligne de diagnostic :
/// le compteur grimpe EN DIRECT, sans `adb`.
@immutable
class BgCaptureStats {
  const BgCaptureStats({
    required this.positionsReceived,
    required this.lastFixAt,
    required this.lastEventAt,
  });

  const BgCaptureStats.initial()
      : positionsReceived = 0,
        lastFixAt = null,
        lastEventAt = null;

  /// Nombre de positions RETENUES par l'isolate depuis le demarrage.
  final int positionsReceived;

  /// Horodatage du dernier fix GPS retenu (cote isolate).
  final DateTime? lastFixAt;

  /// Horodatage de la derniere mise a jour recue par l'UI (fix ou heartbeat).
  final DateTime? lastEventAt;

  BgCaptureStats copyWith({
    int? positionsReceived,
    DateTime? lastFixAt,
    DateTime? lastEventAt,
  }) =>
      BgCaptureStats(
        positionsReceived: positionsReceived ?? this.positionsReceived,
        lastFixAt: lastFixAt ?? this.lastFixAt,
        lastEventAt: lastEventAt ?? this.lastEventAt,
      );
}

/// Service GPS de fond FIABILISE (re-portage socle, generalise).
///
/// Heberge (via flutter_background_service) un isolate dedie
/// `@pragma('vm:entry-point')` qui capture la position ECRAN ETEINT, meme quand
/// l'isolate UI est gele par l'OS. Points cles (retours terrain,
/// generalisees — zero sentier particulier) :
/// - handshake config via SharedPreferences (UI -> isolate) AVANT startService ;
/// - stockage de fond DEDIE (tampon SharedPreferences) draine par l'UI ;
/// - filtre de distance ([kBgMinKeepDistanceMeters]) + keep-alive
///   ([kBgKeepAliveThreshold]) ;
/// - notification foreground importance DEFAULT (visible ecran verrouille) ;
/// - permission POST_NOTIFICATIONS demandee au runtime ;
/// - auto-diagnostic ([verifyServiceStarted]) qui rend visible un echec
///   silencieux du foreground service.
///
/// Il n'y a PLUS de logique de « pause apres 30 min en fond » : la capture
/// continue est justement le besoin.
///
/// ZERO catch silencieux cote UI : toute erreur passe par [ErrorHandler].
class BackgroundGpsService {
  BackgroundGpsService({FlutterBackgroundService? service})
      : _service = service ?? FlutterBackgroundService();

  final FlutterBackgroundService _service;

  /// Controller broadcast diffusant les points captes de fond vers l'app.
  final _trackPointController = StreamController<BgTrackPoint>.broadcast();

  /// Stream public des points captes par l'isolate de fond.
  Stream<BgTrackPoint> get trackPointStream => _trackPointController.stream;

  String? _sessionId;
  String? get sessionId => _sessionId;

  String? _trailId;
  String? get trailId => _trailId;

  bool _running = false;
  bool get isRunning => _running;

  /// Le service a-t-il ete configure (entrypoint enregistre) ? Idempotent.
  bool _initialized = false;
  bool get isInitialized => _initialized;

  /// Etat de demarrage publie par l'auto-diagnostic (source de verite : l'etat
  /// REEL du service natif, pas le flag optimiste [_running]). L'UI l'ecoute
  /// pour afficher une banniere en cas de [GpsServiceStartStatus.failedToStart].
  final ValueNotifier<GpsServiceStartStatus> startStatus =
      ValueNotifier<GpsServiceStartStatus>(GpsServiceStartStatus.idle);

  /// Statistiques de capture (compteur + dernier fix), poussees par l'isolate.
  final ValueNotifier<BgCaptureStats> captureStats =
      ValueNotifier<BgCaptureStats>(const BgCaptureStats.initial());

  StreamSubscription<Map<String, dynamic>?>? _eventSubscription;
  StreamSubscription<Map<String, dynamic>?>? _heartbeatSubscription;

  /// Initialise le service (idempotent) : cree le canal + enregistre
  /// l'entrypoint. A appeler tot (boot) ; defensivement rappele par [start].
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await createNotificationChannel();
      await configureService();
      _initialized = true;
    } on Exception catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st, context: 'BackgroundGpsService.initialize');
      rethrow;
    }
  }

  /// Cree le canal Android en importance DEFAULT (notif visible, heads-up).
  /// Overridable pour neutraliser le platform channel dans les tests.
  @protected
  @visibleForTesting
  Future<void> createNotificationChannel() async {
    if (!Platform.isAndroid) return;
    const channel = AndroidNotificationChannel(
      kForegroundChannelId,
      kForegroundChannelName,
      description: 'Suivi GPS de la randonnee en arriere-plan',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
    );
    final plugin = FlutterLocalNotificationsPlugin();
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(channel);
  }

  /// Demande POST_NOTIFICATIONS au RUNTIME (Android 13+). Sans elle, la notif
  /// persistante ne s'affiche pas et l'OS tue le service ecran eteint.
  /// Best-effort : ne jette jamais, no-op hors Android.
  @protected
  @visibleForTesting
  Future<void> ensureNotificationPermission() async {
    if (!Platform.isAndroid) return;
    try {
      if (await Permission.notification.isGranted) return;
      await Permission.notification.request();
    } catch (_) {
      // Best-effort : une demande ratee ne doit jamais bloquer le suivi GPS.
    }
  }

  /// Enregistre l'entrypoint [_onServiceStart] du foreground service.
  /// Overridable pour neutraliser le platform channel dans les tests.
  @protected
  @visibleForTesting
  Future<void> configureService() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onServiceStart,
        autoStart: false,
        isForegroundMode: true,
        foregroundServiceNotificationId: kForegroundNotificationId,
        notificationChannelId: kForegroundChannelId,
        initialNotificationTitle: 'Suivi GPS',
        initialNotificationContent: 'Enregistrement de la randonnee',
        foregroundServiceTypes: [AndroidForegroundType.location],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onServiceStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Demarre la capture GPS de fond pour la session [sessionId] du sentier
  /// [trailId].
  ///
  /// [distanceFilter] : seuil de retention (defaut [kBgMinKeepDistanceMeters]).
  /// [stageInfo] : texte de la notification (etape courante), generique.
  Future<void> start({
    required String sessionId,
    required String trailId,
    double distanceFilter = kBgMinKeepDistanceMeters,
    String stageInfo = '',
  }) async {
    if (_running) return;

    // Filet : garantir que configure() a tourne AVANT startService (idempotent).
    await initialize();

    // PRIORITE : POST_NOTIFICATIONS avant de demarrer le foreground service.
    await ensureNotificationPermission();

    _sessionId = sessionId;
    _trailId = trailId;
    _running = true;
    captureStats.value = const BgCaptureStats.initial();
    startStatus.value = GpsServiceStartStatus.verifying;

    // ROLLBACK D'ETAT sur echec : sans quoi le guard `if (_running) return` en
    // tete transformerait toute relance en no-op muet (bug terrain « oblige de
    // relancer l'appli »). On restaure un etat propre et on repropage.
    try {
      await startForegroundService(
        sessionId: sessionId,
        trailId: trailId,
        distanceFilter: distanceFilter,
        stageInfo: stageInfo,
      );
    } on Exception catch (e, st) {
      _running = false;
      startStatus.value = GpsServiceStartStatus.failedToStart;
      ErrorHandler.log(e, stackTrace: st, context: 'BackgroundGpsService.start');
      rethrow;
    }

    // AUTO-DIAGNOSTIC (fire-and-forget, ne bloque pas l'UI ~4 s).
    unawaited(verifyServiceStarted());
  }

  /// Persiste la config (handshake), demarre le service natif et branche les
  /// evenements (points + heartbeat). Overridable pour test sans backend natif.
  @protected
  @visibleForTesting
  Future<void> startForegroundService({
    required String sessionId,
    required String trailId,
    required double distanceFilter,
    required String stageInfo,
  }) async {
    // HANDSHAKE : persister la config AVANT startService (l'IPC configure court
    // une course perdue d'avance au cold start). Best-effort a l'ecriture.
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrefsBgSessionId, sessionId);
      await prefs.setString(kPrefsBgTrailId, trailId);
      await prefs.setString(kPrefsBgStageInfo, stageInfo);
      await prefs.setDouble(kPrefsBgDistanceFilter, distanceFilter);
    } catch (_) {
      // Ignore : le service tente quand meme de demarrer (IPC = 2e chemin).
    }

    await _service.startService();
    _logBg('[ui] startService() appele session=$sessionId trail=$trailId');

    // 2e chemin (best-effort) : IPC configure, s'il passe.
    _service.invoke('configure', {
      'sessionId': sessionId,
      'trailId': trailId,
      'stageInfo': stageInfo,
      'distanceFilter': distanceFilter,
    });

    _eventSubscription = _service.on('trackPoint').listen((event) {
      if (event == null) return;
      final point = BgTrackPoint(
        id: event['id'] as String? ?? '',
        sessionId: event['sessionId'] as String? ?? '',
        trailId: event['trailId'] as String? ?? '',
        latitude: (event['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (event['longitude'] as num?)?.toDouble() ?? 0,
        altitude: (event['altitude'] as num?)?.toDouble() ?? 0,
        accuracy: (event['accuracy'] as num?)?.toDouble() ?? 0,
        speed: (event['speed'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(event['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
      if (!_trackPointController.isClosed) _trackPointController.add(point);

      final authoritative = event['positionsReceived'];
      final current = captureStats.value;
      captureStats.value = current.copyWith(
        positionsReceived: authoritative is int
            ? authoritative
            : current.positionsReceived + 1,
        lastFixAt: point.timestamp,
        lastEventAt: DateTime.now(),
      );
    });

    _heartbeatSubscription = _service.on('heartbeat').listen((event) {
      if (event == null) return;
      final n = event['positionsReceived'];
      final lastFixTs = event['lastFixTs'];
      final current = captureStats.value;
      captureStats.value = current.copyWith(
        positionsReceived: n is int ? n : current.positionsReceived,
        lastFixAt: lastFixTs is String
            ? (DateTime.tryParse(lastFixTs) ?? current.lastFixAt)
            : current.lastFixAt,
        lastEventAt: DateTime.now(),
      );
    });
  }

  /// Delai avant l'auto-diagnostic (laisse a l'OS le temps de lancer/refuser le
  /// foreground service). Overridable (Duration.zero) pour tests deterministes.
  @protected
  @visibleForTesting
  Duration get startVerificationDelay => const Duration(seconds: 4);

  /// Interroge l'etat REEL du service natif. Overridable pour test.
  @protected
  @visibleForTesting
  Future<bool> queryServiceRunning() => _service.isRunning();

  /// AUTO-DIAGNOSTIC : compare l'etat REEL du service (isRunning natif) a
  /// l'intention ([_running]). Si le service n'a pas demarre, l'OS a refuse/tue
  /// le foreground service en avalant l'erreur native -> on repasse [_running] a
  /// false (une relance redevient possible) et on publie [failedToStart].
  /// Best-effort : ne jette jamais ; en cas d'indisponibilite, n'alarme pas.
  @protected
  @visibleForTesting
  Future<void> verifyServiceStarted() async {
    await Future<void>.delayed(startVerificationDelay);
    if (!_running) return; // stop() appele entre-temps.

    bool running;
    try {
      running = await queryServiceRunning();
    } catch (e) {
      _logBg('[ui] auto-diagnostic: isRunning() indisponible ($e) — no alarm');
      startStatus.value = GpsServiceStartStatus.running;
      return;
    }

    if (running) {
      startStatus.value = GpsServiceStartStatus.running;
      _logBg('[ui] auto-diagnostic OK: service running');
    } else {
      _running = false;
      startStatus.value = GpsServiceStartStatus.failedToStart;
      _logBg('[ui] auto-diagnostic KO: service NON running — OS a refuse');
    }
  }

  /// Arrete la capture de fond.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    startStatus.value = GpsServiceStartStatus.idle;
    _service.invoke('stop');
    await _eventSubscription?.cancel();
    _eventSubscription = null;
    await _heartbeatSubscription?.cancel();
    _heartbeatSubscription = null;
  }

  /// Met a jour le texte de la notification (etape courante), generique.
  void updateNotification({required String stageInfo}) {
    if (!_running) return;
    _service.invoke('updateNotification', {'stageInfo': stageInfo});
  }

  /// DRAINE le tampon de points captes par l'isolate de fond et le VIDE.
  ///
  /// Appele par l'UI au retour au premier plan : lit le tampon SharedPreferences
  /// (rempli par l'isolate ecran eteint), le vide atomiquement, et renvoie les
  /// points pour insertion en base (sessionTrackPoints). Best-effort : en cas
  /// d'erreur de lecture, renvoie une liste vide sans jamais jeter.
  Future<List<BgTrackPoint>> drainBackgroundPoints() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getStringList(kPrefsBgPointsBuffer);
      if (raw == null || raw.isEmpty) return const [];
      // Vider AVANT de parser : un point mal forme ne doit pas rester coince.
      await prefs.setStringList(kPrefsBgPointsBuffer, const []);
      final points = <BgTrackPoint>[];
      for (final line in raw) {
        try {
          points.add(BgTrackPoint.fromJson(
              jsonDecode(line) as Map<String, dynamic>));
        } catch (_) {
          // Point corrompu ignore (best-effort).
        }
      }
      return points;
    } catch (e, st) {
      ErrorHandler.log(e,
          stackTrace: st,
          context: 'BackgroundGpsService.drainBackgroundPoints');
      return const [];
    }
  }

  /// Libere les ressources.
  void dispose() {
    unawaited(stop());
    _trackPointController.close();
    startStatus.dispose();
    captureStats.dispose();
  }
}

/// Point GPS capte par l'isolate de fond, transmis a l'UI et/ou persiste dans
/// le tampon de drain. Modele plat (JSON-serialisable) independant de Drift.
@immutable
class BgTrackPoint {
  const BgTrackPoint({
    required this.id,
    required this.sessionId,
    required this.trailId,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.accuracy,
    required this.speed,
    required this.timestamp,
  });

  factory BgTrackPoint.fromJson(Map<String, dynamic> json) => BgTrackPoint(
        id: json['id'] as String? ?? '',
        sessionId: json['sessionId'] as String? ?? '',
        trailId: json['trailId'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
        longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
        altitude: (json['altitude'] as num?)?.toDouble() ?? 0,
        accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0,
        speed: (json['speed'] as num?)?.toDouble() ?? 0,
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  final String id;
  final String sessionId;
  final String trailId;
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => bgEncodePoint(
        id: id,
        sessionId: sessionId,
        trailId: trailId,
        latitude: latitude,
        longitude: longitude,
        altitude: altitude,
        accuracy: accuracy,
        speed: speed,
        timestamp: timestamp,
      );
}

/// Provider du service GPS de fond.
final backgroundGpsServiceProvider = Provider<BackgroundGpsService>((ref) {
  final service = BackgroundGpsService();
  ref.onDispose(service.dispose);
  return service;
});

// =========================================================
// CODE EXECUTE DANS L'ISOLATE DU SERVICE DE FOND
// =========================================================

/// Point d'entree du foreground service (Android) / handler (iOS).
///
/// Cet isolate est SEPARE de l'UI (aucune memoire partagee). Il relit la config
/// persistee par l'UI (handshake) et lance sa capture GPS IMMEDIATEMENT, sans
/// dependre de l'IPC. Les points retenus sont pousses vers l'UI (IPC) ET
/// serialises dans le tampon SharedPreferences (drain au retour au premier
/// plan) — c'est la SEULE ecriture qui survit ecran eteint.
@pragma('vm:entry-point')
Future<void> _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  _logBg('[bg] onStart ATTEINT (isolate de fond demarre)');

  const uuid = Uuid();
  String sessionId = '';
  String trailId = '';
  double distanceFilter = kBgMinKeepDistanceMeters;

  StreamSubscription<Position>? positionSub;
  int positionsReceived = 0;
  DateTime? lastFixAt;
  double? lastKeptLat;
  double? lastKeptLon;
  DateTime? lastNotifUpdateAt;
  Timer? heartbeatTimer;
  Timer? watchdogTimer;
  Timer? resubscribeTimer;

  SharedPreferences? prefs;
  try {
    prefs = await SharedPreferences.getInstance();
  } catch (_) {
    prefs = null;
  }

  LocationSettings buildSettings() {
    // PAS de foregroundNotificationConfig ici : flutter_background_service est
    // DEJA l'hote du foreground service `location`. En ajouter un via geolocator
    // demarrerait un SECOND FGS dans le meme process (double FGS fragile,
    // startForeground interdit depuis un contexte background sur Android 12+ ->
    // SecurityException avalee = capture morte). Geolocator se contente ici
    // d'ECOUTER ; l'hote maintient le process vivant.
    if (Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.round(),
        forceLocationManager: false,
      );
    }
    if (Platform.isIOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter.round(),
        activityType: ActivityType.fitness,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: distanceFilter.round(),
    );
  }

  void refreshCaptureNotification() {
    final s = service;
    if (s is! AndroidServiceInstance) return;
    final now = DateTime.now();
    if (lastNotifUpdateAt != null &&
        now.difference(lastNotifUpdateAt!) < const Duration(seconds: 5)) {
      return;
    }
    lastNotifUpdateAt = now;
    s.setForegroundNotificationInfo(
      title: 'Suivi GPS',
      content: bgNotificationContent(positionsReceived, lastFixAt),
    );
  }

  /// Ajoute le point au TAMPON de drain (SharedPreferences), isolate-safe.
  Future<void> bufferPoint(Map<String, dynamic> pointMap) async {
    final p = prefs;
    if (p == null) return;
    try {
      await p.reload();
      final buffer = p.getStringList(kPrefsBgPointsBuffer) ?? <String>[];
      buffer.add(jsonEncode(pointMap));
      await p.setStringList(kPrefsBgPointsBuffer, buffer);
    } catch (e) {
      _logBg('[bg] ECHEC ecriture tampon de fond: $e');
    }
  }

  /// Traite UNE position (flux ou filet) : filtre de distance, compteur,
  /// persistance tampon, IPC vers l'UI, notification. [force] bypasse le filtre
  /// (point keep-alive). Retourne true si le point a ete RETENU.
  Future<bool> handlePosition(Position position,
      {required String via, bool force = false}) async {
    if (!force &&
        !bgShouldKeepPosition(
          lastKeptLat: lastKeptLat,
          lastKeptLon: lastKeptLon,
          newLat: position.latitude,
          newLon: position.longitude,
          threshold: distanceFilter,
        )) {
      return false;
    }

    positionsReceived++;
    final now = DateTime.now();
    lastFixAt = now;
    lastKeptLat = position.latitude;
    lastKeptLon = position.longitude;
    final pointId = uuid.v4();

    _logBg('[bg] point #$positionsReceived via=$via'
        '${force ? ' keep-alive' : ''} '
        'lat=${position.latitude.toStringAsFixed(5)} '
        'lon=${position.longitude.toStringAsFixed(5)}');

    final pointMap = bgEncodePoint(
      id: pointId,
      sessionId: sessionId,
      trailId: trailId,
      latitude: position.latitude,
      longitude: position.longitude,
      altitude: position.altitude,
      accuracy: position.accuracy,
      speed: position.speed,
      timestamp: now,
    );

    // 1) Persister dans le tampon (SEULE ecriture qui survit ecran eteint).
    await bufferPoint(pointMap);

    // 2) Notifier l'UI (mise a jour live) — sans effet si l'UI est gelee.
    service.invoke('trackPoint', {
      ...pointMap,
      'positionsReceived': positionsReceived,
      'via': via,
    });

    refreshCaptureNotification();
    return true;
  }

  void startGpsListening() {
    if (!bgShouldSubscribe(hasSubscription: positionSub != null)) {
      _logBg('[bg] deja abonne -> pas de re-abonnement');
      return;
    }
    positionSub?.cancel();
    resubscribeTimer?.cancel();
    _logBg('[bg] abonnement Geolocator distanceFilter=${distanceFilter.round()}m '
        'session=$sessionId');
    positionSub = Geolocator.getPositionStream(
      locationSettings: buildSettings(),
    ).listen(
      (position) => handlePosition(position, via: 'stream'),
      onError: (Object error, StackTrace _) {
        // NE PAS avaler : un onError vide tue la capture en silence. On logue
        // et on re-tente (le stream errore est mort, il faut le recreer).
        _logBg('[bg] ERREUR stream Geolocator: $error -> re-abo dans 5s');
        positionSub?.cancel();
        positionSub = null;
        resubscribeTimer?.cancel();
        resubscribeTimer = Timer(const Duration(seconds: 5), startGpsListening);
      },
      cancelOnError: true,
    );
  }

  void sendHeartbeat() {
    final now = DateTime.now();
    final ageSec =
        lastFixAt == null ? null : now.difference(lastFixAt!).inSeconds;
    _logBg('[bg] HEARTBEAT positionsReceived=$positionsReceived '
        'dernierFix=${ageSec == null ? "aucun" : "${ageSec}s"} '
        'abonne=${positionSub != null}');
    service.invoke('heartbeat', {
      'positionsReceived': positionsReceived,
      'lastFixTs': lastFixAt?.toIso8601String(),
      'subscribed': positionSub != null,
    });
    refreshCaptureNotification();
  }

  void applyConfig(Map<String, dynamic>? event) {
    if (event == null) return;
    sessionId = event['sessionId'] as String? ?? sessionId;
    trailId = event['trailId'] as String? ?? trailId;
    final df = event['distanceFilter'];
    if (df is num) distanceFilter = df.toDouble();
    final stageInfo = event['stageInfo'] as String? ?? '';
    final s = service;
    if (s is AndroidServiceInstance && stageInfo.isNotEmpty) {
      s.setForegroundNotificationInfo(title: 'Suivi GPS', content: stageInfo);
    }
    startGpsListening();
  }

  service.on('configure').listen(applyConfig);

  service.on('updateNotification').listen((event) {
    if (event == null) return;
    final stageInfo = event['stageInfo'] as String? ?? '';
    final s = service;
    if (s is AndroidServiceInstance && stageInfo.isNotEmpty) {
      s.setForegroundNotificationInfo(title: 'Suivi GPS', content: stageInfo);
    }
  });

  service.on('stop').listen((_) {
    _logBg('[bg] stop recu -> arret capture + timers');
    positionSub?.cancel();
    resubscribeTimer?.cancel();
    watchdogTimer?.cancel();
    heartbeatTimer?.cancel();
    service.stopSelf();
  });

  // DEMARRAGE AUTONOME (coeur du fix) : relire la config persistee par l'UI
  // AVANT startService et s'abonner IMMEDIATEMENT, sans dependre de l'IPC.
  try {
    final p = prefs;
    if (p != null) {
      await p.reload();
      sessionId = p.getString(kPrefsBgSessionId) ?? sessionId;
      trailId = p.getString(kPrefsBgTrailId) ?? trailId;
      distanceFilter =
          p.getDouble(kPrefsBgDistanceFilter) ?? distanceFilter;
      final storedStageInfo = p.getString(kPrefsBgStageInfo) ?? '';
      final s = service;
      if (s is AndroidServiceInstance && storedStageInfo.isNotEmpty) {
        s.setForegroundNotificationInfo(
            title: 'Suivi GPS', content: storedStageInfo);
      }
    }
  } catch (_) {
    // Best-effort : meme sans config relue, on capture (mieux que muet).
  }

  startGpsListening();

  // SONDE DE VIE : ne force un getCurrentPosition « keep-alive » que si aucun
  // point n'a ete retenu depuis >= kBgKeepAliveThreshold (persiste de force).
  watchdogTimer = Timer.periodic(kBgWatchdogPeriod, (_) async {
    final now = DateTime.now();
    if (!bgIsKeepAliveDue(lastFixAt, now)) return;
    _logBg('[bg] SONDE DE VIE -> getCurrentPosition keep-alive');
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      await handlePosition(pos, via: 'filet', force: true);
    } catch (e) {
      _logBg('[bg] SONDE DE VIE getCurrentPosition ECHEC: $e');
    }
  });

  heartbeatTimer = Timer.periodic(kBgHeartbeatPeriod, (_) => sendHeartbeat());
  sendHeartbeat();
}

/// Handler iOS background (maintien du service en arriere-plan).
@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}
