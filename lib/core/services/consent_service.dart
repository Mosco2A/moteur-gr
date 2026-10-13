/// Consentement RGPD accorde FINALITE PAR FINALITE, jamais groupe : rien n'est
/// accorde sans un acte positif, et tout se retire (reco CNIL 2025).
library;

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

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ardoise_de_demo.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

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

  /// PUBLICITE PERSONNALISEE (tache 595, B4).
  ///
  /// LE DEFAUT REPARE : le consentement publicitaire vivait A COTE de ce
  /// dispositif. L'appli avait un consentement granulaire complet — horodate,
  /// versionne, retractable, avec refus global et effacement de l'article 9 —
  /// et la publicite, elle, n'etait gouvernee que par le CMP de Google, dans
  /// un formulaire natif qui ne parle a aucun ecran de l'application. Deux
  /// dispositifs pour une seule promesse (« gerez ici chaque autorisation »)
  /// : le randonneur ne pouvait pas revoir son choix publicitaire la ou on lui
  /// disait de le faire.
  ///
  /// CE QUE CETTE FINALITE GOUVERNE : le CIBLAGE, pas l'affichage. Le modele
  /// economique dit « gratuit = avec publicite » — c'est la contrepartie du
  /// niveau gratuit, pas un traitement soumis a consentement. Ce que le
  /// randonneur tranche ici, c'est si ses donnees de ciblage quittent
  /// l'appareil : refusee, la demande part `nonPersonalizedAds`, la banniere
  /// reste. C'est exactement la question que pose le CMP, posee au meme
  /// endroit que toutes les autres.
  ///
  /// PAS RENFORCEE : ce n'est pas une donnee de l'article 9. Seule la sante
  /// l'est, et son isolement ne doit pas etre dilue par voisinage.
  advertising,

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

/// CE QUI A PROVOQUE LA DEMANDE DE CONSENTEMENT (DEM du 30/09 12:33).
///
/// POURQUOI LE DECLENCHEUR EST UNE DONNEE ET PAS UN COMMENTAIRE. Christophe :
/// « en cas de modification des donnees, on redemande le consentement ». Un
/// registre de consentement qui dit « accorde le 30/09 » sans dire POURQUOI on
/// a demande ce jour-la ne prouve rien : on ne peut pas distinguer un premier
/// accord d'une re-confirmation apres modification des donnees, ni savoir si la
/// re-demande a bien eu lieu. Le declencheur monte donc en base avec la
/// decision.
enum ConsentTrigger {
  /// Aucune decision anterieure : c'est la premiere fois qu'on demande.
  premiereDemande("premiere_demande"),

  /// LES DONNEES COUVERTES PAR LA FINALITE ONT ETE MODIFIEES. C'est le cas
  /// ajoute par la decision du 30/09 : la fiche de sante ou la morphologie
  /// vient de changer, donc on re-demande.
  modificationDesDonnees("modification_des_donnees"),

  /// Le texte de la politique a evolue : les accords anterieurs sont caducs.
  evolutionDePolitique("evolution_de_politique"),

  /// Le randonneur a lui-meme ouvert l'ecran Confidentialite et tranche.
  settings("reglages"),

  /// Origine non renseignee. Vaut pour les decisions ANTERIEURES a ce lot, qui
  /// existent deja sur le telephone de Christophe : on ne va pas leur inventer
  /// un declencheur qu'on ne connait pas.
  inconnu("inconnu");

  const ConsentTrigger(this.code);

  /// La forme stockee et publiee. Stable : c'est elle qui vit en base, jamais
  /// l'index de l'enum.
  final String code;

  /// Relit un code stocke. Un code inconnu devient [inconnu] plutot que de
  /// faire echouer la lecture de tout l'etat de consentement.
  static ConsentTrigger depuisLeCode(String? code) {
    for (final d in ConsentTrigger.values) {
      if (d.code == code) return d;
    }
    return ConsentTrigger.inconnu;
  }
}

/// Etat de consentement immuable pour une finalite donnee.
///
/// Contient la decision ([granted]), son horodatage ([decidedAt]), la version
/// de politique en vigueur au moment de la decision ([policyVersion]), le
/// [declencheur] de la demande et la [revisionDesDonnees] couverte au moment du
/// choix. Sert a determiner si une re-demande est necessaire — apres un
/// changement de politique, ou apres une modification des donnees.
class ConsentState {
  const ConsentState({
    required this.purpose,
    required this.granted,
    required this.decidedAt,
    required this.policyVersion,
    this.declencheur = ConsentTrigger.inconnu,
    this.revisionDesDonnees = 0,
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
  /// TOLERANTE AUX DECISIONS DEJA PRISES (tache 638). Les deux champs ajoutes
  /// par ce lot — [declencheur] et [revisionDesDonnees] — sont ABSENTS des
  /// enregistrements presents sur les telephones deja installes, celui de
  /// Christophe compris. Les exiger aurait rendu illisible chaque consentement
  /// deja donne, donc fait re-demander tout le monde pour une raison purement
  /// technique. Absents => « inconnu » et revision 0.
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
      declencheur: ConsentTrigger.depuisLeCode(map['declencheur'] as String?),
      revisionDesDonnees: map['revisionDesDonnees'] as int? ?? 0,
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

  /// Ce qui avait provoque la demande (tache 638).
  final ConsentTrigger declencheur;

  /// LA REVISION DES DONNEES COUVERTES, AU MOMENT DU CHOIX (tache 638).
  ///
  /// C'est le pendant exact de [policyVersion], mais du cote des DONNEES au lieu
  /// du cote du TEXTE. Un compteur qui monte d'un cran a chaque modification des
  /// donnees que cette finalite protege. Quand il ne correspond plus au compteur
  /// courant, le consentement porte sur des donnees qui ne sont plus celles
  /// d'aujourd'hui : il se re-demande. C'est la mecanique demandee par Christophe
  /// le 30/09 (« en cas de modification des donnees, on redemande le
  /// consentement »), et c'est aussi ce qui garantit qu'on ne re-demande PAS en
  /// boucle : afficher un ecran ne modifie aucune donnee, donc ne bouge pas ce
  /// compteur.
  final int revisionDesDonnees;

  /// Serialise l'etat pour le stockage local.
  String toJson() => jsonEncode(<String, dynamic>{
    'granted': granted,
    'decidedAt': decidedAt?.millisecondsSinceEpoch,
    'policyVersion': policyVersion,
    'declencheur': declencheur.code,
    'revisionDesDonnees': revisionDesDonnees,
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
    bool Function()? enDemo,
    int Function()? generationDeDemo,
  }) : _prefs = prefs,
       _policyVersion = policyVersion,
       _enDemo = enDemo,
       _ardoise = ArdoiseDeDemo(generation: generationDeDemo);

  /// LA BARRIERE DE LA DEMO (tache 760) : une FONCTION, pour que l'instance et
  /// son flux diffuse survivent a la bascule — raisonnement entier dans
  /// `ardoise_de_demo.dart`. `null` = jamais en demo, d'origine inchange.
  final bool Function()? _enDemo;

  /// Vrai pendant une demo volontaire.
  bool get enDemo => _enDemo?.call() ?? false;

  /// Ce qu'une demo decide reste ICI, en memoire, et part avec elle.
  final ArdoiseDeDemo _ardoise;

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
    // EN DEMO, L'ARDOISE PASSE DEVANT (tache 760).
    final raw = enDemo
        ? _ardoise.texte(purpose.storageKey) ??
              prefs.getString(purpose.storageKey)
        : prefs.getString(purpose.storageKey);
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

  /// Cle du compteur de revisions des donnees couvertes par [purpose].
  static String cleDeRevision(ConsentPurpose purpose) =>
      'consent_revision_${purpose.name}';

  /// LA REVISION COURANTE DES DONNEES couvertes par [purpose] (tache 638).
  ///
  /// Monte d'un cran a chaque appel de [noterUneModificationDesDonnees]. Zero
  /// tant qu'aucune modification n'a ete enregistree.
  int revisionDesDonnees(ConsentPurpose purpose) {
    final prefs = _prefs;
    if (prefs == null) {
      throw StateError(
        'ConsentService non initialise : appeler initialize() d\'abord.',
      );
    }
    // EN DEMO, L'ARDOISE PASSE DEVANT (tache 760).
    final surArdoise = enDemo ? _ardoise.entier(cleDeRevision(purpose)) : null;
    if (surArdoise != null) return surArdoise;
    return prefs.getInt(cleDeRevision(purpose)) ?? 0;
  }

  /// LES DONNEES COUVERTES PAR [purpose] VIENNENT D'ETRE MODIFIEES (tache 638).
  ///
  /// DECISION DE CHRISTOPHE DU 30/09 12:33, verbatim : « en cas de modification
  /// des donnees, on redemande le consentement ». Cette methode est le SEUL
  /// endroit qui declenche une re-demande cote donnees : elle s'appelle depuis
  /// les ecrans qui ECRIVENT (la fiche de sante, la morphologie), jamais depuis
  /// ceux qui affichent. C'est ce qui garantit « une fois par modification,
  /// jamais au simple affichage » : un affichage n'ecrit rien, donc n'appelle
  /// rien.
  ///
  /// ELLE N'EMET PAS SUR [changes]. Le flux porte les DECISIONS de consentement,
  /// et noter une modification n'en est pas une — c'est ce qui rend une decision
  /// NECESSAIRE. Les ecrans qui veulent savoir s'il faut re-demander lisent
  /// [needsPrompt].
  Future<int> noterUneModificationDesDonnees(ConsentPurpose purpose) async {
    await initialize();
    final suivante = revisionDesDonnees(purpose) + 1;
    // EN DEMO IL MONTE SUR L'ARDOISE (760) : MONOTONE, il montait pour de bon.
    if (enDemo) {
      _ardoise.poser(cleDeRevision(purpose), suivante);
      return suivante;
    }
    await _prefs!.setInt(cleDeRevision(purpose), suivante);
    return suivante;
  }

  /// Vrai si une (re)demande de consentement est necessaire pour [purpose].
  ///
  /// Trois cas, et le troisieme est celui du 30/09 :
  ///  1. jamais decide ;
  ///  2. consentement accorde sous une version de politique anterieure (caduc) ;
  ///  3. LES DONNEES COUVERTES ONT CHANGE depuis la decision.
  ///
  /// Un refus explicite sous la version courante n'est PAS re-demande tant que
  /// les donnees ne bougent pas (l'utilisateur a tranche). Mais un refus suivi
  /// d'une MODIFICATION des donnees l'est : c'est le cas ou quelqu'un a refuse,
  /// puis a quand meme rempli ou change sa fiche — il faut lui reposer la
  /// question sur ce qu'il vient d'ecrire.
  bool needsPrompt(ConsentPurpose purpose) {
    final state = stateOf(purpose);
    if (state.decidedAt == null) return true; // jamais decide
    if (state.granted && state.policyVersion != _policyVersion) {
      return true; // accord caduc apres evolution de politique
    }
    if (state.revisionDesDonnees != revisionDesDonnees(purpose)) {
      return true; // les donnees couvertes ont change depuis le choix
    }
    return false;
  }

  /// Accorde le consentement pour [purpose] (acte positif explicite).
  ///
  /// Horodate la decision, la rattache a la version de politique courante, a la
  /// revision courante des donnees et au [declencheur] de la demande. Emet
  /// l'evenement sur [changes].
  Future<void> grant(
    ConsentPurpose purpose, {
    ConsentTrigger declencheur = ConsentTrigger.inconnu,
  }) => _record(purpose, granted: true, declencheur: declencheur);

  /// Retire le consentement pour [purpose] (retractable a tout moment).
  ///
  /// Horodate la decision. Emet l'evenement sur [changes].
  Future<void> revoke(
    ConsentPurpose purpose, {
    ConsentTrigger declencheur = ConsentTrigger.inconnu,
  }) => _record(purpose, granted: false, declencheur: declencheur);

  /// Enregistre une decision de consentement et notifie les ecouteurs.
  ///
  /// LA DECISION CAPTURE LA REVISION COURANTE DES DONNEES, et c'est ce qui ferme
  /// la boucle : re-demander apres une modification pose une decision qui porte
  /// la NOUVELLE revision, donc [needsPrompt] retombe a faux tout de suite. Sans
  /// cette capture, l'application re-demanderait a chaque ouverture jusqu'a la
  /// modification suivante.
  Future<void> _record(
    ConsentPurpose purpose, {
    required bool granted,
    ConsentTrigger declencheur = ConsentTrigger.inconnu,
  }) async {
    await initialize();
    final state = ConsentState(
      purpose: purpose,
      granted: granted,
      decidedAt: DateTime.now(),
      policyVersion: _policyVersion,
      declencheur: declencheur,
      revisionDesDonnees: revisionDesDonnees(purpose),
    );
    // EN DEMO, LA DECISION VA SUR L'ARDOISE (760), mais elle est DIFFUSEE.
    if (enDemo) {
      _ardoise.poser(purpose.storageKey, state.toJson());
    } else {
      await _prefs!.setString(purpose.storageKey, state.toJson());
    }
    _controller.add(purpose);
  }

  /// Etat de consentement de TOUTES les finalites (lecture seule).
  ///
  /// Utile pour l'ecran de reglages (D4A-02) qui liste chaque finalite.
  Map<ConsentPurpose, ConsentState> allStates() =>
      <ConsentPurpose, ConsentState>{
        for (final purpose in ConsentPurpose.values) purpose: stateOf(purpose),
      };

  /// Libere le StreamController. A appeler quand le service est detruit.
  void dispose() {
    _controller.close();
  }
}

/// Signature d'une verification de consentement UTILISABLE DEPUIS UN SERVICE.
///
/// POURQUOI CE TYPE EXISTE (tache 561, J2). Un service qui traite de la donnee
/// sensible ne peut pas se contenter d'un commentaire demandant a l'appelant de
/// verifier le consentement : il doit pouvoir le verifier LUI-MEME. Ce type
/// permet de poser la garde DANS la methode tout en restant testable (on injecte
/// une verification deterministe en test, jamais un faux stockage).
typedef ConsentCheck = Future<bool> Function(ConsentPurpose purpose);

/// Verification de consentement PAR DEFAUT : lit l'etat REEL du stockage local.
///
/// C'est l'implementation branchee par defaut dans les services qui traitent de
/// la donnee sensible ([ConsentCheck]). Elle relit les prefs a CHAQUE appel,
/// volontairement : un consentement retire doit produire un refus tout de suite,
/// sans dependre d'une instance mise en cache au demarrage (#100482, LOT I : un
/// consentement revoque puis ignore est exactement le defaut qu'on repare ici).
///
/// FERMEE PAR DEFAUT : si l'etat est illisible (prefs indisponibles, JSON
/// corrompu), la fonction retourne `false` — refus. Un doute sur le
/// consentement se tranche par le refus, jamais par le traitement. L'echec est
/// journalise pour rester visible (ce n'est pas un catch silencieux : la
/// decision prise est explicite et tracee).
Future<bool> consentFromLocalStore(ConsentPurpose purpose) async {
  ConsentService? service;
  try {
    service = ConsentService();
    await service.initialize();
    return service.hasConsent(purpose);
  } catch (e) {
    _log.e('[Consent] Etat de "${purpose.name}" illisible ($e) -> REFUS');
    return false;
  } finally {
    service?.dispose();
  }
}
