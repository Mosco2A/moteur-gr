// D4A-01 — Service de consentement granulaire RGPD (design D4 CORDO #86166).
//
// Le consentement est gere PAR FINALITE (CNIL, reco mars 2025) : la
// navigation personnelle, le partage social, le signalement public et les
// donnees de SANTE sont des finalites distinctes, chacune avec son propre
// etat de consentement. Aucune finalite n'est groupee avec une autre.
//
// Proprietes RGPD garanties :
//   - EXPLICITE  : un consentement n'est accorde que par un acte positif
//     clair (appel a [grant]). L'etat par defaut est "non accorde".
//   - RETRACTABLE: [revoke] retire le consentement a tout moment.
//   - HORODATE   : chaque decision (grant/revoke) porte un timestamp.
//   - VERSIONNE  : chaque decision est rattachee a une version de politique.
//     Si la politique change ([currentPolicyVersion] augmente), les anciens
//     consentements deviennent caducs et doivent etre re-demandes.
//
// Donnees de SANTE (art 9 RGPD, categorie particuliere via F6F : FC/ceinture
// BLE, lecture Health) : finalite [ConsentPurpose.healthData], marquee
// "renforcee" ([ConsentPurpose.isReinforced]). Elle exige un consentement
// SEPARE et explicite, jamais groupe avec le reste (l'UI D4A-02 la presente
// isolement avec un avertissement renforce).
//
// Stockage LOCAL uniquement (SharedPreferences) : l'etat de consentement n'a
// pas besoin de serveur. L'app est anonyme-by-design (UID hache SHA-256, zero
// PII directe, #85383), ce qui simplifie la gestion du consentement.
//
// API d'integration pour D1/D2/D3 : les services geoloc / social / sante /
// signalement DOIVENT appeler [hasConsent] avant d'agir. Exemple :
//   if (!consent.hasConsent(ConsentPurpose.locationNavigation)) return;
// Ecouter [changes] permet de reagir en direct a un retrait de consentement.

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Finalites de traitement soumises a consentement granulaire (CNIL).
///
/// Chaque finalite est independante : accorder l'une n'accorde jamais une
/// autre. [healthData] relevant de l'article 9 RGPD (donnee sensible) est
/// marquee "renforcee" ([isReinforced]) — elle ne doit JAMAIS etre groupee
/// avec les autres finalites dans l'UI ni dans le stockage.
enum ConsentPurpose {
  /// Navigation personnelle (geoloc pour la carte / le suivi de l'etape).
  locationNavigation,

  /// Partage social (classements pseudonymes, fil communautaire, partage).
  socialSharing,

  /// Signalement public (contribution de signalements visibles par autrui).
  publicReporting,

  /// Donnees de SANTE (FC via ceinture BLE / lecture Health) — art 9 RGPD.
  ///
  /// Categorie particuliere : consentement explicite renforce, isole.
  healthData;

  /// Vrai si la finalite releve d'une categorie particuliere (art 9 RGPD)
  /// et exige un consentement renforce, separe et explicite.
  bool get isReinforced => this == ConsentPurpose.healthData;

  /// Cle de stockage stable pour cette finalite (jamais l'index de l'enum,
  /// pour resister a une reordonnance future de l'enum).
  String get storageKey => 'consent_$name';
}

/// Etat de consentement immuable pour une finalite donnee.
///
/// Contient la decision ([granted]), son horodatage ([decidedAt]) et la
/// version de politique en vigueur au moment de la decision
/// ([policyVersion]). Sert a determiner si une re-demande est necessaire
/// apres un changement de politique.
class ConsentState {
  const ConsentState({
    required this.purpose,
    required this.granted,
    required this.decidedAt,
    required this.policyVersion,
  });

  /// Etat initial : consentement NON accorde (acte positif requis).
  ///
  /// Aucune date ni version : aucune decision n'a encore ete prise.
  factory ConsentState.initial(ConsentPurpose purpose) => ConsentState(
        purpose: purpose,
        granted: false,
        decidedAt: null,
        policyVersion: null,
      );

  /// Reconstruit un etat depuis sa forme serialisee (JSON SharedPreferences).
  ///
  /// Leve une [FormatException] si le JSON est invalide — pas de catch
  /// silencieux : un etat corrompu doit etre visible, pas masque.
  factory ConsentState.fromJson(ConsentPurpose purpose, String raw) {
    final Map<String, dynamic> map = jsonDecode(raw) as Map<String, dynamic>;
    final int? decidedMs = map['decidedAt'] as int?;
    return ConsentState(
      purpose: purpose,
      granted: map['granted'] as bool? ?? false,
      decidedAt: decidedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(decidedMs),
      policyVersion: map['policyVersion'] as int?,
    );
  }

  /// Finalite concernee.
  final ConsentPurpose purpose;

  /// Vrai si le consentement est accorde pour cette finalite.
  final bool granted;

  /// Horodatage de la derniere decision (grant ou revoke). Null si aucune.
  final DateTime? decidedAt;

  /// Version de politique en vigueur au moment de la decision. Null si aucune.
  final int? policyVersion;

  /// Serialise l'etat pour le stockage local.
  String toJson() => jsonEncode(<String, dynamic>{
        'granted': granted,
        'decidedAt': decidedAt?.millisecondsSinceEpoch,
        'policyVersion': policyVersion,
      });

  /// Vrai si cet etat est EFFECTIF pour [currentPolicyVersion].
  ///
  /// Un consentement accorde sous une version de politique anterieure n'est
  /// plus valable apres une evolution de politique : il doit etre re-demande.
  /// Un consentement non accorde reste non accorde (rien a re-demander).
  bool isEffectiveFor(int currentPolicyVersion) {
    if (!granted) return false;
    return policyVersion == currentPolicyVersion;
  }
}

/// Service de consentement granulaire par finalite (D4A-01).
///
/// Stockage local (SharedPreferences), un enregistrement JSON par finalite.
/// Expose [hasConsent], [grant], [revoke] et un [changes] Stream pour reagir
/// en direct. Aucun catch silencieux : les erreurs de stockage/format
/// remontent.
class ConsentService {
  ConsentService({
    SharedPreferences? prefs,
    int policyVersion = currentPolicyVersion,
  })  : _prefs = prefs,
        _policyVersion = policyVersion;

  /// Version courante de la politique de consentement.
  ///
  /// A INCREMENTER a chaque evolution materielle des finalites / de la
  /// politique de confidentialite (D4D-01) : tous les consentements
  /// anterieurs deviennent alors caducs et seront re-demandes par l'UI.
  static const int currentPolicyVersion = 1;

  /// Instance SharedPreferences (injectee en test, ou chargee a la demande).
  SharedPreferences? _prefs;

  /// Version de politique appliquee par cette instance (injectable en test).
  final int _policyVersion;

  /// Diffuse la finalite dont l'etat vient de changer (grant/revoke).
  final StreamController<ConsentPurpose> _controller =
      StreamController<ConsentPurpose>.broadcast();

  /// Flux des changements de consentement (finalite modifiee).
  ///
  /// Les services geoloc/social/sante peuvent l'ecouter pour stopper
  /// immediatement un traitement si l'utilisateur retire son consentement.
  Stream<ConsentPurpose> get changes => _controller.stream;

  /// Version de politique en vigueur pour cette instance.
  int get policyVersion => _policyVersion;

  /// Initialise le service (charge SharedPreferences si non injecte).
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Lit l'etat de consentement brut (sans tenir compte de la version).
  ///
  /// Retourne [ConsentState.initial] si aucune decision n'a ete enregistree.
  /// Ne masque pas une corruption : une [FormatException] de
  /// [ConsentState.fromJson] remonte (zero catch silencieux).
  ConsentState stateOf(ConsentPurpose purpose) {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'ConsentService non initialise : appeler initialize() d\'abord.',
      );
    }
    final raw = prefs.getString(purpose.storageKey);
    if (raw == null) return ConsentState.initial(purpose);
    return ConsentState.fromJson(purpose, raw);
  }

  /// Vrai si le consentement est accorde ET valide pour la version courante.
  ///
  /// C'est la methode que les services DOIVENT appeler avant de traiter une
  /// donnee. Un consentement accorde sous une politique anterieure renvoie
  /// `false` (re-demande necessaire) — la securite prime.
  bool hasConsent(ConsentPurpose purpose) =>
      stateOf(purpose).isEffectiveFor(_policyVersion);

  /// Vrai si une (re)demande de consentement est necessaire pour [purpose].
  ///
  /// Cas : jamais decide, ou consentement accorde sous une version de
  /// politique anterieure (caduc). Un refus explicite sous la version
  /// courante n'est PAS re-demande (l'utilisateur a tranche).
  bool needsPrompt(ConsentPurpose purpose) {
    final state = stateOf(purpose);
    if (state.decidedAt == null) return true; // jamais decide
    if (state.granted && state.policyVersion != _policyVersion) {
      return true; // accord caduc apres evolution de politique
    }
    return false;
  }

  /// Accorde le consentement pour [purpose] (acte positif explicite).
  ///
  /// Horodate la decision et la rattache a la version de politique courante.
  /// Emet l'evenement sur [changes].
  Future<void> grant(ConsentPurpose purpose) =>
      _record(purpose, granted: true);

  /// Retire le consentement pour [purpose] (retractable a tout moment).
  ///
  /// Horodate la decision. Emet l'evenement sur [changes].
  Future<void> revoke(ConsentPurpose purpose) =>
      _record(purpose, granted: false);

  /// Enregistre une decision de consentement et notifie les ecouteurs.
  Future<void> _record(ConsentPurpose purpose, {required bool granted}) async {
    await initialize();
    final state = ConsentState(
      purpose: purpose,
      granted: granted,
      decidedAt: DateTime.now(),
      policyVersion: _policyVersion,
    );
    await _prefs!.setString(purpose.storageKey, state.toJson());
    _controller.add(purpose);
  }

  /// Etat de consentement de TOUTES les finalites (lecture seule).
  ///
  /// Utile pour l'ecran de reglages (D4A-02) qui liste chaque finalite.
  Map<ConsentPurpose, ConsentState> allStates() => <ConsentPurpose, ConsentState>{
        for (final purpose in ConsentPurpose.values) purpose: stateOf(purpose),
      };

  /// Libere le StreamController. A appeler quand le service est detruit.
  void dispose() {
    _controller.close();
  }
}
