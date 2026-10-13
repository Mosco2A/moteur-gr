/// Les etapes nommees d'un chemin surveille, en type FERME et instances
/// CONSTANTES : c'est ce qui rend une mesure MANQUANTE detectable.
library;

import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../firebase/firebase_service.dart';
import 'firebase_analytics_sink.dart';
import 'screen_breadcrumb.dart';

/// LE JOURNAL LOCAL DU SERVICE D'OBSERVABILITE (lot 645-09).
///
/// Quand Firebase est joignable, il double la miette partie au nuage. Quand
/// il ne l'est pas — 100 pct du temps aujourd'hui — il est la SEULE trace qui
/// reste, et c'est par lui que la QA sur emulateur verifie que les miettes
/// passent (`adb logcat | grep screen:`). D'ou UNE LIGNE par miette et non un
/// cadre `PrettyPrinter` : un cadre est illisible en logcat pour vingt
/// caracteres utiles, et noie la sortie de `flutter test`.
final _localLog = Logger(printer: SimplePrinter(colors: false));

/// LES TROIS CLES DE CONTEXTE, ET IL N'Y EN AURA PAS UNE QUATRIEME
/// (lot 645-09).
///
/// CRASHLYTICS PLAFONNE A 64 PAIRES CLE-VALEUR, et au-dela il n'enregistre
/// plus rien — EN SILENCE. Avec 62 ecrans, « une cle par ecran » tenait du
/// pari : le 64e aurait fait disparaitre les autres sans un mot. La convention
/// retenue par Christophe inverse le probleme : TROIS cles dont la VALEUR
/// change, et une miette courte par entree d'ecran. (Source :
/// firebase.google.com/docs/crashlytics/flutter/customize-crash-reports,
/// consultee le 02/10/2026.)
abstract final class AnalyticsKeys {
  /// L'ecran courant — la valeur change a chaque entree d'ecran.
  static const String screen = 'screen';

  /// Le sentier actif, TOUJOURS anonymise avant d'etre pose.
  static const String trail = 'trail';

  /// L'etape en cours.
  static const String stage = 'stage';

  /// Les trois cles, pour la garde de plafond qui les compte.
  static const all = <String>[screen, trail, stage];
}

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
/// personnelle structurelle et non declarative. [AnalyticsService.markStep]
/// n'accepte que ce type, donc rien qui vienne du randonneur ne peut partir par
/// ce tuyau.
///
/// LE CHEMIN SURVEILLE DE LA TACHE 637 est celui de la question de sauvegarde,
/// parce qu'il a plante a TOUS les lancements des builds 6 et 7 sans qu'aucun
/// rapport ne dise a quelle etape. Les quatre etapes decoupent exactement les
/// quatre endroits ou il pouvait s'arreter.
final class AnalyticsStep {
  const AnalyticsStep._(this.chemin, this.nom);

  /// Nom de la cle Crashlytics (le chemin surveille).
  final String chemin;

  /// Valeur de la cle (l'etape atteinte).
  final String nom;

  static const String _sauvegarde = 'consentement_sauvegarde';

  /// La garde a decide de poser la question (avant toute attente).
  static const AnalyticsStep sauvegardeDemandee = AnalyticsStep._(
    _sauvegarde,
    'demandee',
  );

  /// La lecture « la decision est-elle deja prise ? » a rendu sa reponse.
  static const AnalyticsStep sauvegardeDecisionLue = AnalyticsStep._(
    _sauvegarde,
    'decision_lue',
  );

  /// AUCUN contexte portant un `Navigator` : la question est abandonnee pour
  /// cette ouverture (elle sera reposee a la suivante). C'est l'etape qui
  /// manquait aux builds 6 et 7 — elle y plantait au lieu de se nommer.
  static const AnalyticsStep sauvegardeSansNavigateur = AnalyticsStep._(
    _sauvegarde,
    'sans_navigateur',
  );

  /// Le dialogue a ete ouvert.
  static const AnalyticsStep sauvegardeDialogueOuvert = AnalyticsStep._(
    _sauvegarde,
    'dialogue_ouvert',
  );

  /// Le dialogue s'est referme normalement.
  static const AnalyticsStep sauvegardeDialogueFerme = AnalyticsStep._(
    _sauvegarde,
    'dialogue_ferme',
  );

  /// La lecture de la decision a echoue (provider invalide pendant l'attente) :
  /// la question est abandonnee pour cette ouverture.
  static const AnalyticsStep sauvegardeLecturePerdue = AnalyticsStep._(
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

  /// L'empreinte du dernier contexte pose (`nom|sentier|etape`), qui rend
  /// [enterScreen] IDEMPOTENT : repasser par la ne coute pas un appel natif.
  String? _lastEntry;

  /// Le dernier ecran pose, pour ne compter qu'UNE miette par ecran meme
  /// quand le sentier ou l'etape changent sous lui.
  String? _lastScreenName;

  /// Les miettes d'ecran deja posees dans cette session.
  int _screenCrumbs = 0;

  /// LE PLAFOND DE MIETTES PAR SESSION : 256 miettes de ~20 octets tiennent
  /// dans 5 ko, loin des 64 ko ou Crashlytics efface le DEBUT de la session
  /// — l'amorce, l'endroit ou l'application plante le plus.
  static const int maxScreenCrumbsPerSession = 256;

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
  Future<void> markStep(AnalyticsStep step) async {
    if (!_operational) return;
    await _crash.setCustomKey(step.chemin, step.nom);
    await _crash.log('${step.chemin}: ${step.nom}');
  }

  /// ENTREE D'ECRAN — LE POINT D'ENTREE UNIQUE DE L'OBSERVABILITE DES ECRANS
  /// (lot 645-09).
  ///
  /// POURQUOI UN SEUL POINT D'ENTREE ET PAS 63 APPELS. Au 03/10/2026, AUCUN
  /// des 63 ecrans ne portait de miette : l'audit en annoncait 9, et les 9
  /// etaient un FAUX POSITIF de sa mesure (son marqueur `log(` est contenu
  /// dans `AlertDialog(`). Un rapport de plantage ne pouvait donc pas dire sur
  /// quel ecran etait le randonneur. Point 18 de l'inventaire 593 : « vendre
  /// une appli sans savoir qu'elle plante est un pari ».
  ///
  /// CE QUE CETTE METHODE POSE : la cle [AnalyticsKeys.screen] (et, quand
  /// l'ecran les connait, [AnalyticsKeys.trail] et [AnalyticsKeys.stage]),
  /// puis UNE miette courte `screen:<nom>`.
  ///
  /// UNE MIETTE PAR ENTREE, PAS PAR RECONSTRUCTION, et c'est ce qui tient le
  /// budget : un `build()` tourne des dizaines de fois par ecran, et une
  /// miette a chaque passage aurait noye les 64 ko d'une session en secondes.
  /// L'empreinte du dernier contexte pose est donc memorisee.
  ///
  /// CETTE DEDUPLICATION NE CONNAIT PAS LA PILE, ET N'A PAS A LA CONNAITRE :
  /// elle ne retient que la DERNIERE empreinte, si bien que deux ecrans qui
  /// parlent a tour de role passent tous les deux. C'est le raccord
  /// (`observeScreenEntry`) qui fait taire les ecrans caches sous la pile et
  /// `ScreenEntryObserver` qui fait reparler celui qui redevient visible
  /// (lot 645-09b).
  ///
  /// [trail] EST ANONYMISE comme partout ailleurs ici : c'est un identifiant,
  /// il part en SHA-256 et jamais en clair.
  ///
  /// CETTE METHODE N'ECHOUE PAS : un puits natif peut lever (Firebase absent,
  /// Google Play trop vieux), l'exception est avalee et journalisee en local.
  /// Un ecran ne doit JAMAIS casser parce qu'une miette n'a pas pu partir.
  Future<void> enterScreen(
    ScreenBreadcrumb screen, {
    String? trail,
    String? stage,
  }) async {
    final fingerprint = '${screen.name}|$trail|$stage';
    if (fingerprint == _lastEntry) return;
    final isNewScreen = screen.name != _lastScreenName;
    _lastEntry = fingerprint;
    _lastScreenName = screen.name;

    // LE JOURNAL LOCAL PART MEME INERTE : seule trace quand Firebase est
    // indisponible, et ce que la QA sur emulateur vient lire.
    if (isNewScreen) _localLog.t('screen:${screen.name}');
    if (!_operational) return;

    try {
      await _crash.setCustomKey(AnalyticsKeys.screen, screen.name);
      if (trail != null) {
        await _crash.setCustomKey(AnalyticsKeys.trail, anonymize(trail));
      }
      if (stage != null) {
        await _crash.setCustomKey(AnalyticsKeys.stage, _clamp(stage));
      }
      // PLAFOND STRUCTUREL : une navigation pathologique (deux ecrans qui
      // se relaient) ne doit pas manger les 64 ko et effacer l'amorce.
      if (isNewScreen && _screenCrumbs < maxScreenCrumbsPerSession) {
        _screenCrumbs++;
        await _crash.log('screen:${screen.name}');
      }
    } on Object catch (e) {
      _localLog.w('[observabilite] miette perdue (${screen.name}) : $e');
    }
  }

  /// Borne une valeur de cle : Crashlytics plafonne chaque paire a 1 ko.
  static String _clamp(String value) =>
      value.length <= 64 ? value : value.substring(0, 64);

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
