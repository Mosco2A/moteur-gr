import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/geo/track_point.dart';
import '../../../core/geo/track_projection.dart';
import '../../notifications/providers/notification_provider.dart';
import '../domain/off_track_detector.dart';
import 'gpx_track_provider.dart';

/// Etat expose a l'UI pour l'alerte hors-trace.
class OffTrackState {
  const OffTrackState({
    this.isOffTrack = false,
    this.distanceMeters = 0.0,
    this.hasFix = false,
  });

  /// True si le randonneur est actuellement considere hors du trace.
  final bool isOffTrack;

  /// Distance perpendiculaire de la derniere position au trace (metres).
  final double distanceMeters;

  /// True des qu'au moins un point GPS a ete traite (evite d'afficher 0 m
  /// tant qu'aucune position n'est connue).
  final bool hasFix;

  OffTrackState copyWith({
    bool? isOffTrack,
    double? distanceMeters,
    bool? hasFix,
  }) {
    return OffTrackState(
      isOffTrack: isOffTrack ?? this.isOffTrack,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      hasFix: hasFix ?? this.hasFix,
    );
  }
}

/// Textes de l'alerte hors-trace (notification), injectes depuis l'i18n.
///
/// Le provider est du code metier (pur Riverpod) : il ne connait pas Slang.
/// L'UI (carte) fournit les libelles traduits via [offTrackMessagesProvider]
/// pour que la notification parte dans la langue de l'utilisateur.
class OffTrackMessages {
  const OffTrackMessages({
    required this.notifTitle,
    required this.notifBody,
  });

  /// Titre de la notification a la sortie du trace.
  final String notifTitle;

  /// Corps de la notification, fonction de la distance (metres) au trace.
  final String Function(int meters) notifBody;
}

/// Detient les libelles de la notification hors-trace, alimentes par l'UI.
///
/// Le provider off-track est du code metier (il ne connait pas Slang) et tourne
/// meme ecran verrouille. L'ecran carte pousse les libelles traduits (Slang,
/// navAlert.offTrackNotif*) via [setMessages] a son montage / changement de
/// langue, pour que la notification parte dans la langue de l'utilisateur. Sans
/// injection, un fallback generique (langue de base) s'applique.
class OffTrackMessagesNotifier extends Notifier<OffTrackMessages> {
  @override
  OffTrackMessages build() {
    return OffTrackMessages(
      notifTitle: 'Vous quittez le sentier',
      notifBody: (m) => 'Vous vous eloignez du sentier ($m m). '
          'Verifiez votre position.',
    );
  }

  /// Injecte les libelles traduits (appele depuis l'UI carte).
  ///
  /// Idempotent sur le titre (stable par langue) : l'ecran carte appelle cette
  /// methode via `addPostFrameCallback` a CHAQUE frame ; sans garde, chaque
  /// frame reaffectait `state` (nouvel objet a chaque build) et notifiait les
  /// listeners inutilement. On ne pousse donc un nouvel etat que si le titre a
  /// reellement change (bascule de langue), pas a chaque frame.
  void setMessages(OffTrackMessages messages) {
    if (messages.notifTitle == state.notifTitle) return;
    state = messages;
  }
}

/// Messages de la notification hors-trace (fallback langue de base par defaut).
final offTrackMessagesProvider =
    NotifierProvider<OffTrackMessagesNotifier, OffTrackMessages>(
        OffTrackMessagesNotifier.new);

/// Notifier de l'alerte hors-trace.
///
/// A chaque nouvelle position GPS, PROJETTE la position sur le trace PLEINE
/// RESOLUTION (reutilise [TrackProjector.project] -> `distanceToTrackM`, la
/// distance perpendiculaire au sentier — aucune geometrie recodee) et applique
/// un [OffTrackDetector] (hysteresis). A la SORTIE : une seule alerte
/// (notification locale + vibration courte). Au RETOUR : la notification se leve.
class OffTrackNotifier extends StateNotifier<OffTrackState> {
  OffTrackNotifier({
    required this.ref,
    OffTrackDetector? detector,
  })  : _detector = detector ?? OffTrackDetector(),
        super(const OffTrackState());

  final Ref ref;
  final OffTrackDetector _detector;

  /// Trace de reference (pleine resolution) sur lequel on projette la position.
  List<TrackPoint> _track = const <TrackPoint>[];

  /// Dernier index de projection connu (optimisation fenetree du projecteur).
  int? _lastIndex;

  StreamSubscription<Position>? _sub;

  /// Demarre la surveillance sur [gpsStream] en projetant sur [track].
  void startListening({
    required Stream<Position> gpsStream,
    required List<TrackPoint> track,
  }) {
    _sub?.cancel();
    _track = track;
    _lastIndex = null;
    _detector.reset();
    state = const OffTrackState();
    // Sans trace exploitable, on ne peut pas mesurer l'ecart : on ne surveille pas.
    if (track.length < 2) return;
    _sub = gpsStream.listen(_onPosition, onError: (_) {});
  }

  /// Arrete la surveillance (fin de trek, alerte desactivee, trace indispo).
  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  /// Callback a chaque nouvelle position GPS.
  void _onPosition(Position position) {
    if (!mounted || _track.length < 2) return;

    // Reutilisation de la projection geometrique existante : distanceToTrackM
    // est la distance perpendiculaire (cross-track) de la position au trace.
    final projection = TrackProjector.project(
      userLat: position.latitude,
      userLng: position.longitude,
      trackPoints: _track,
      lastKnownIndex: _lastIndex,
    );
    _lastIndex = projection.trackIndexPosition;

    final distance = projection.distanceToTrackM;
    final transition = _detector.update(distance);

    state = state.copyWith(
      isOffTrack: _detector.isOffTrack,
      distanceMeters: distance,
      hasFix: true,
    );

    switch (transition) {
      case OffTrackTransition.enteredOffTrack:
        _vibrate();
        // Fire-and-forget : la methode gere son propre try-catch.
        unawaited(_sendNotification(distance));
        break;
      case OffTrackTransition.returnedOnTrack:
        unawaited(_clearNotification());
        break;
      case OffTrackTransition.none:
        break;
    }
  }

  /// Vibration COURTE, uniquement a la sortie (pas de spam). Guard total : aucun
  /// effet si la plateforme ne supporte pas le retour haptique (ou sous test).
  void _vibrate() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {
      // Retour haptique indisponible — sans importance pour l'alerte.
    }
  }

  /// Notification locale a la sortie du trace. Try-catch : ne jamais propager
  /// (la banniere in-screen reste le fallback UX).
  Future<void> _sendNotification(double distance) async {
    try {
      final messages = ref.read(offTrackMessagesProvider);
      await ref.read(notificationServiceProvider).showOffTrackAlert(
            title: messages.notifTitle,
            body: messages.notifBody(distance.round()),
          );
    } catch (_) {
      // Fallback = banniere carte ; on n'interrompt jamais le suivi GPS.
    }
  }

  /// Leve la notification hors-trace au retour sur le sentier.
  Future<void> _clearNotification() async {
    try {
      await ref.read(notificationServiceProvider).cancelOffTrackAlert();
    } catch (_) {
      // Sans importance : l'etat (banniere) est deja repasse "sur le trace".
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Flux de positions GPS brut (geolocator), expose comme [Stream].
///
/// Isole ici (Provider et non StreamProvider) pour passer le Stream tel quel au
/// notifier hors-trace, independamment de l'ecran carte (le detecteur doit
/// tourner telephone en poche). Surchargeable dans les tests.
final offTrackGpsStreamProvider = Provider<Stream<Position>>((ref) {
  const settings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );
  return Geolocator.getPositionStream(locationSettings: settings);
});

/// Alerte de securite "hors-trace" : surveille l'ecart de la position reelle au
/// trace du sentier ACTIF et alerte (banniere + notification + vibration) quand
/// le randonneur quitte le sentier.
///
/// Choix du trace : [gpxTrackProvider] du sentier actif (PLEINE RESOLUTION). Le
/// trace simplifie d'affichage couperait les lacets et donnerait de faux
/// positifs (RM-5).
///
/// N'est PAS conditionne a l'ecran carte (contrairement aux POI) : c'est une
/// alerte de securite qui doit fonctionner meme telephone en poche — la
/// notification locale part hors ecran, la banniere n'est qu'un bonus in-screen.
/// Desactivable via les reglages ([NotificationSettings.offTrackAlerts], ON par
/// defaut). `keepAlive` pour ne pas suspendre la surveillance quand aucun widget
/// n'ecoute (ecran verrouille).
final offTrackProvider =
    StateNotifierProvider<OffTrackNotifier, OffTrackState>((ref) {
  ref.keepAlive();
  final notifier = OffTrackNotifier(ref: ref);

  final enabled = ref.watch(
    notificationSettingsProvider.select((s) => s.offTrackAlerts),
  );
  final trailId = ref.watch(trailIdProvider);
  final track = ref.watch(gpxTrackProvider(trailId)).value;

  if (enabled && track != null && track.length >= 2) {
    notifier.startListening(
      gpsStream: ref.watch(offTrackGpsStreamProvider),
      track: track,
    );
  } else {
    // Alerte desactivee / trace indispo : couper proprement la surveillance
    // (pas d'abonnement GPS residuel).
    notifier.stopListening();
  }

  // NB : pas de ref.onDispose(notifier.dispose) — StateNotifierProvider dispose
  // deja le notifier automatiquement (un double dispose leverait une erreur).
  return notifier;
});
