import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../firebase/firebase_service.dart';
import 'firebase_analytics_sink.dart';

/// Noms d'evenements analytics (zero-PII).
abstract final class AnalyticsEvents {
  static const String trailDownloaded = 'trail_downloaded';
  static const String trekStarted = 'trek_started';
  static const String trekCompleted = 'trek_completed';
  static const String shareCard = 'share_card';
  static const String diplomaGenerated = 'diploma_generated';

  /// Telemetrie regime GPS/batterie (F6A-04) — mesure terrain BAT-2.
  static const String gpsRegime = 'gps_regime';

  /// Stats de fin d'etape (F6B-03) — denivele/allure/pauses agreges, zero-PII.
  static const String trekStats = 'trek_stats';
}

/// UNE ETAPE NOMMEE SUR UN CHEMIN SURVEILLE (tache 637).
///
/// Type ferme, instances CONSTANTES : c'est ce qui rend l'absence de donnee
/// personnelle structurelle et non declarative. [AnalyticsService.marquerEtape]
/// n'accepte que ce type, donc rien qui vienne du randonneur ne peut partir par
/// ce tuyau.
///
/// LE CHEMIN SURVEILLE DE LA TACHE 637 est celui de la question de sauvegarde,
/// parce qu'il a plante a TOUS les lancements des builds 6 et 7 sans qu'aucun
/// rapport ne dise a quelle etape. Les quatre etapes decoupent exactement les
/// quatre endroits ou il pouvait s'arreter.
final class Etape {
  const Etape._(this.chemin, this.nom);

  /// Nom de la cle Crashlytics (le chemin surveille).
  final String chemin;

  /// Valeur de la cle (l'etape atteinte).
  final String nom;

  static const String _sauvegarde = 'consentement_sauvegarde';

  /// La garde a decide de poser la question (avant toute attente).
  static const Etape sauvegardeDemandee = Etape._(_sauvegarde, 'demandee');

  /// La lecture « la decision est-elle deja prise ? » a rendu sa reponse.
  static const Etape sauvegardeDecisionLue = Etape._(
    _sauvegarde,
    'decision_lue',
  );

  /// AUCUN contexte portant un `Navigator` : la question est abandonnee pour
  /// cette ouverture (elle sera reposee a la suivante). C'est l'etape qui
  /// manquait aux builds 6 et 7 — elle y plantait au lieu de se nommer.
  static const Etape sauvegardeSansNavigateur = Etape._(
    _sauvegarde,
    'sans_navigateur',
  );

  /// Le dialogue a ete ouvert.
  static const Etape sauvegardeDialogueOuvert = Etape._(
    _sauvegarde,
    'dialogue_ouvert',
  );

  /// Le dialogue s'est referme normalement.
  static const Etape sauvegardeDialogueFerme = Etape._(
    _sauvegarde,
    'dialogue_ferme',
  );

  /// La lecture de la decision a echoue (provider invalide pendant l'attente) :
  /// la question est abandonnee pour cette ouverture.
  static const Etape sauvegardeLecturePerdue = Etape._(
    _sauvegarde,
    'lecture_perdue',
  );
}

/// Puits analytics abstrait — decouple de Firebase pour la testabilite.
abstract interface class AnalyticsSink {
  Future<void> logEvent(String name, Map<String, Object?> params);
  Future<void> logScreenView(String screenName);
  Future<void> setCollectionEnabled(bool enabled);
}

/// Puits crash abstrait — decouple de Crashlytics pour la testabilite.
abstract interface class CrashSink {
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  });
  Future<void> setCollectionEnabled(bool enabled);

  /// MIETTE DE PISTE attachee au prochain rapport (tache 637).
  ///
  /// Un rapport de plantage dit OU ca casse ; il ne dit pas A QUELLE ETAPE le
  /// chemin en etait. Le defaut 637 a coûte deux builds precisement pour cette
  /// raison : la ligne incriminee n'etait qu'une reprise apres attente, et le `!`
  /// reel etait trois cadres plus bas, dans le framework, sous une assertion
  /// retiree en release.
  Future<void> log(String message);

  /// CLE DE CONTEXTE lue en tete du prochain rapport (tache 637). Jamais de
  /// donnee personnelle : des constantes du code, rien d'autre.
  Future<void> setCustomKey(String key, String value);
}

/// Puits analytics inerte (Firebase indisponible / mode degrade).
class NoOpAnalyticsSink implements AnalyticsSink {
  const NoOpAnalyticsSink();
  @override
  Future<void> logEvent(String name, Map<String, Object?> params) async {}
  @override
  Future<void> logScreenView(String screenName) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
}

/// Puits crash inerte (Firebase indisponible / mode degrade).
class NoOpCrashSink implements CrashSink {
  const NoOpCrashSink();
  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    required bool fatal,
  }) async {}
  @override
  Future<void> setCollectionEnabled(bool enabled) async {}
  @override
  Future<void> log(String message) async {}
  @override
  Future<void> setCustomKey(String key, String value) async {}
}

/// Service analytics ANONYME (E5.4).
///
/// Garanties :
/// - **Zero-PII strict** : aucun nom/email/uid/GPS en clair n'est jamais
///   transmis. Les identifiants (trailId, ...) sont hashes en SHA-256
///   ([anonymize]). L'API typee ne permet pas de passer de PII. Pas de
///   fingerprinting : les mesures (distance, duree) sont arrondies grossierement.
/// - **Mode degrade** : si Firebase est indisponible, le service est inerte
///   (no-op, zero crash) — voir [AnalyticsService.disabled] et le provider.
/// - **Opt-in** : la collecte est DESACTIVEE par defaut. Aucun evenement n'est
///   emis tant que [setConsent] n'a pas accorde le consentement.
class AnalyticsService {
  AnalyticsService({
    required AnalyticsSink analytics,
    required CrashSink crash,
    bool operational = true,
  }) : _analytics = analytics,
       _crash = crash,
       _operational = operational;

  /// Service inerte (Firebase indisponible) — toutes les operations no-op.
  factory AnalyticsService.disabled() => AnalyticsService(
    analytics: const NoOpAnalyticsSink(),
    crash: const NoOpCrashSink(),
    operational: false,
  );

  final AnalyticsSink _analytics;
  final CrashSink _crash;
  final bool _operational;

  /// Consentement (opt-in). Faux par defaut : aucune collecte avant accord.
  bool _consentGranted = false;

  /// Vrai si un backend reel est cable (Firebase disponible).
  bool get isOperational => _operational;

  /// Vrai si le consentement a ete accorde.
  bool get isConsentGranted => _consentGranted;

  /// Anonymise un identifiant en SHA-256 (hex) — jamais de valeur en clair.
  static String anonymize(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  /// Accorde/retire le consentement de MESURE D'USAGE (Analytics).
  ///
  /// TACHE 596 (C4) — CETTE METHODE ETEIGNAIT AUSSI LES RAPPORTS DE PLANTAGE.
  /// Elle appelait `_crash.setCollectionEnabled(granted)`, et le provider
  /// l'invoque avec `granted: false` DES SA CONSTRUCTION (opt-in strict). Le
  /// premier lecteur du provider coupait donc Crashlytics pour toute la
  /// session : meme Firebase allume, meme les filets d'erreur poses, chaque
  /// `recordError` serait parti a la poubelle. Un troisieme verrou, invisible,
  /// sur le meme defaut — et le plus vicieux, parce qu'il annulait le
  /// correctif des deux autres.
  ///
  /// Les deux collectes sont desormais SEPAREES : mesurer l'usage d'un
  /// randonneur et savoir que l'appli a plante chez lui ne sont pas la meme
  /// question, ne servent pas la meme finalite, et n'ont pas a partager le meme
  /// interrupteur. Voir [setCrashCollection].
  Future<void> setConsent({required bool granted}) async {
    _consentGranted = granted;
    await _analytics.setCollectionEnabled(granted);
  }

  /// Allume/eteint LA REMONTEE DES PLANTAGES, independamment de [setConsent].
  ///
  /// Conséquence a assumer cote magasins : des que cette collecte est active,
  /// la fiche Play « Data safety » doit declarer « Crash logs »
  /// (cf. docs/rgpd/data-safety.md).
  Future<void> setCrashCollection({required bool enabled}) =>
      _crash.setCollectionEnabled(enabled);

  /// Ecran consulte (nom logique d'ecran, jamais d'identifiant utilisateur).
  Future<void> logScreenView(String screenName) async {
    if (!_consentGranted) return;
    await _analytics.logScreenView(screenName);
  }

  Future<void> logTrailDownloaded({required String trailId}) =>
      _log(AnalyticsEvents.trailDownloaded, {'trail': anonymize(trailId)});

  Future<void> logTrekStarted({required String trailId}) =>
      _log(AnalyticsEvents.trekStarted, {'trail': anonymize(trailId)});

  Future<void> logTrekCompleted({
    required String trailId,
    required double distanceKm,
    required Duration duration,
  }) => _log(AnalyticsEvents.trekCompleted, {
    'trail': anonymize(trailId),
    // Valeurs grossieres (anti-fingerprinting) : km et minutes entieres.
    'distance_km': distanceKm.round(),
    'duration_min': duration.inMinutes,
  });

  Future<void> logShareCard({required String template}) =>
      _log(AnalyticsEvents.shareCard, {'template': template});

  Future<void> logDiplomaGenerated({required String trailId}) =>
      _log(AnalyticsEvents.diplomaGenerated, {'trail': anonymize(trailId)});

  /// Telemetrie du regime GPS/batterie (F6A-04) pour mesurer la conso sur le
  /// terrain (prereq BAT-2). Zero-PII : seul le nom du regime et un PALIER de
  /// batterie grossier (tranche de 10 %, anti-fingerprinting) sont transmis,
  /// jamais le niveau exact ni de position.
  Future<void> logGpsRegime({
    required String regime,
    required int batteryPct,
    required bool deferSync,
  }) => _log(AnalyticsEvents.gpsRegime, {
    'regime': regime,
    // Palier de 10 % (ex. 23 % -> 20) : grossier, non identifiant.
    'battery_bucket': (batteryPct ~/ 10) * 10,
    'defer_sync': deferSync,
  });

  /// Stats agregees de fin d'etape (F6B-03). Zero-PII : uniquement des mesures
  /// arrondies grossierement (km/m/minutes/bpm entiers), aucune position ni
  /// identifiant en clair (trailId hashe). Anti-fingerprinting via arrondis.
  Future<void> logTrekStats({
    required String trailId,
    required double distanceKm,
    required double elevationGainM,
    required Duration activeDuration,
    required int pauseCount,
    int? avgHeartRateBpm,
  }) => _log(AnalyticsEvents.trekStats, {
    'trail': anonymize(trailId),
    'distance_km': distanceKm.round(),
    'elevation_gain_m': elevationGainM.round(),
    'active_min': activeDuration.inMinutes,
    'pauses': pauseCount,
    if (avgHeartRateBpm != null)
      // Palier de 10 bpm (anti-fingerprinting).
      'hr_bucket': (avgHeartRateBpm ~/ 10) * 10,
  });

  /// Erreur non fatale (capturee/geree).
  ///
  /// TACHE 596 (C4) : ces deux methodes etaient gardees par le consentement
  /// ANALYTICS (`_consentGranted`), toujours faux — elles ne rapportaient donc
  /// jamais rien, meme Firebase allume. Une panne n'est pas une mesure
  /// d'usage : la remontee des plantages suit desormais [setCrashCollection]
  /// (et, en dernier ressort, l'interrupteur de Crashlytics lui-meme).
  Future<void> recordError(Object error, StackTrace? stack) async {
    if (!_operational) return;
    await _crash.recordError(error, stack, fatal: false);
  }

  /// Erreur fatale (crash).
  Future<void> recordFatal(Object error, StackTrace? stack) async {
    if (!_operational) return;
    await _crash.recordError(error, stack, fatal: true);
  }

  /// ETAPE FRANCHIE SUR UN CHEMIN SURVEILLE (tache 637) — pour que le PROCHAIN
  /// rapport de plantage dise ou le chemin en etait, et pas seulement ou il a
  /// casse.
  ///
  /// POURQUOI CETTE METHODE EXISTE. Le defaut 637 a survecu a deux publications
  /// parce que son rapport ne disait rien d'exploitable : « Null check operator
  /// used on a null value », une ligne qui n'etait qu'une reprise apres attente,
  /// et un `!` situe dans le framework sous une assertion retiree des builds de
  /// release. Une cle et deux miettes auraient nomme l'etape en une lecture.
  ///
  /// ZERO DONNEE PERSONNELLE, ET C'EST STRUCTUREL, pas une consigne : la
  /// signature n'accepte que [Etape], c'est-a-dire des constantes du code. Il
  /// n'y a aucun moyen de faire passer une valeur du randonneur par ici.
  ///
  /// SUIT [setCrashCollection], PAS [setConsent] : une miette de plantage n'est
  /// pas une mesure d'usage (meme separation qu'a la tache 596).
  Future<void> marquerEtape(Etape etape) async {
    if (!_operational) return;
    await _crash.setCustomKey(etape.chemin, etape.nom);
    await _crash.log('${etape.chemin}: ${etape.nom}');
  }

  Future<void> _log(String name, Map<String, Object?> params) async {
    if (!_consentGranted) return;
    await _analytics.logEvent(name, params);
  }
}

/// Provider du service analytics, gate sur la disponibilite Firebase.
///
/// Firebase indisponible -> service inerte (no-op, zero crash).
/// Firebase disponible -> backend reel, collecte DESACTIVEE par defaut
/// (opt-in : appeler [AnalyticsService.setConsent] apres consentement).
/// TACHE 637 (VOLET 2) — CE PROVIDER NE PEUT PLUS LEVER, ET C'EST ESSENTIEL.
///
/// `FirebaseAnalyticsSink()` et `FirebaseCrashSink()` touchent
/// `FirebaseAnalytics.instance` / `FirebaseCrashlytics.instance` DANS LEUR
/// CONSTRUCTEUR. Si Firebase se declare disponible mais que l'application native
/// n'est pas joignable (`[core/no-app]`, services Google Play absents ou trop
/// vieux), ce `create` levait — et `ref.read(analyticsServiceProvider)` levait
/// chez tous ses appelants.
///
/// LA CONSEQUENCE ETAIT GRAVE ET PARADOXALE : le service qui sert a SAVOIR que
/// l'application casse etait lui-meme capable de la casser. Il est lu sur le
/// chemin de la question de sauvegarde (tache 637, volet 1) et depuis la garde
/// d'amorce, c'est-a-dire aux deux endroits ou une exception coûte l'ecran entier.
///
/// UN JOURNAL QUI NE PEUT PAS S'OUVRIR NE DOIT RIEN COÛTER : on retombe sur le
/// service inerte, exactement comme en mode local.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final available = ref.watch(isFirebaseAvailableProvider);
  if (!available) {
    return AnalyticsService.disabled();
  }
  final AnalyticsService service;
  try {
    service = AnalyticsService(
      analytics: FirebaseAnalyticsSink(),
      crash: FirebaseCrashSink(),
    );
  } catch (_) {
    return AnalyticsService.disabled();
  }
  // Opt-in strict sur la MESURE D'USAGE : coupee tant que le consentement
  // n'est pas donne. TACHE 596 (C4) : cet appel eteignait aussi Crashlytics —
  // il ne touche plus que les evenements d'usage.
  unawaited(service.setConsent(granted: false));
  // LES PLANTAGES, EUX, REMONTENT. C'est toute la raison d'etre du correctif :
  // publier sans savoir que l'appli plante chez ses utilisateurs, c'est
  // publier a l'aveugle. Un rapport de plantage ne mesure pas un usage, il
  // signale une panne. A declarer en « Crash logs » cote magasins.
  unawaited(service.setCrashCollection(enabled: true));
  return service;
});
