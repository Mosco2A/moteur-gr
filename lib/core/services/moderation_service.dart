// D4C-01 — Service de moderation hebergeur DSA (design D4 CORDO #86166).
//
// Implemente le mecanisme NOTICE-AND-ACTION du DSA (Reglement (UE) 2022/2065)
// pour le contenu communautaire de StepWays (signalements terrain, fil
// d'activite, waypoints/commentaires Phase 8). StepWays a le statut
// d'HEBERGEUR (pas editeur) : la moderation est A POSTERIORI (#86124 A4-7).
//
// Obligations couvertes (audit A4 #86124, validees Themis #86142) :
//   - art 16 (notice-and-action) : tout utilisateur peut SIGNALER un contenu
//     illicite ([reportContent]) ; la notification porte les mentions exigees
//     (motif, reference du contenu, contact du notifiant, declaration de bonne
//     foi) et est horodatee.
//   - art 17 (expose des motifs) : la decision d'un moderateur produit un
//     enregistrement de motivation destine a l'auteur du contenu restreint
//     (forme cote backend en D4C-02 ; ce service modelise la decision).
//
// Statuts du cycle de vie d'une notification ([ModerationStatus]) :
//   recue -> enTraitement -> traitee. Une notification traitee porte une
//   DECISION ([ModerationDecision] : garder / restreindre / retirer) qui
//   determine la transition du [moderationState] du contenu cible
//   (visible -> flagged -> removed), conformement aux regles Firestore et au
//   modele Phase 8 (champ texte 'visible'/'flagged'/'removed').
//
// PROTECTION DE LA DONNEE DU NOTIFIANT (#85383, lien consentement D4A /
// retention D4B) : le contact du notifiant (email) est une donnee personnelle.
// Ce service le valide et l'encapsule, mais ne le diffuse jamais cote lecture
// publique : seules les regles/role moderateur (D4C-02) y accedent. Aucune PII
// directe n'est jamais exposee dans le contenu modere lui-meme.
//
// API d'integration : ce service est appele par les boutons « Signaler » des
// features F6C-03 (signalement terrain), F7B-04 (fil), F8A-04 (waypoints).
// Riverpod 2.6, ZERO catch silencieux (les erreurs de validation/persistance
// remontent).

import 'dart:async';

/// Type de contenu communautaire pouvant faire l'objet d'un signalement.
///
/// La cle [collectionName] correspond a la collection Firestore portant le
/// [moderationState] du contenu (coherent avec firestore.rules et le modele
/// Phase 8). [storageKey] sert a serialiser le type de maniere stable (jamais
/// l'index de l'enum, pour resister a une reordonnance future).
enum ModeratedContentType {
  /// Signalement terrain type Waze (F6C-04, collection `trail_reports`).
  trailReport('trail_reports'),

  /// Activite du fil communautaire (F7B-03, collection `activities`).
  activity('activities'),

  /// Waypoint communautaire type FarOut (F8A-03, collection `waypoints`).
  waypoint('waypoints'),

  /// Commentaire de condition sur un waypoint (F8A-03,
  /// collection `waypoint_comments`).
  waypointComment('waypoint_comments');

  const ModeratedContentType(this.collectionName);

  /// Nom de la collection Firestore portant le contenu et son moderationState.
  final String collectionName;

  /// Cle de serialisation stable (le `name` de l'enum, pas son index).
  String get storageKey => name;

  /// Reconstruit le type depuis sa cle de serialisation.
  ///
  /// Leve un [ArgumentError] si la cle est inconnue (zero catch silencieux :
  /// un type non gere doit etre visible, pas masque).
  static ModeratedContentType fromStorageKey(String key) =>
      ModeratedContentType.values.firstWhere(
        (t) => t.storageKey == key,
        orElse: () =>
            throw ArgumentError.value(key, 'key', 'Type de contenu inconnu'),
      );
}

/// Etat de moderation d'un CONTENU (modele Phase 8, champ texte Firestore).
///
/// Reprend les valeurs exactes du champ `moderationState` deja en place
/// (waypoints / activities / trail_reports / waypoint_comments) afin de ne
/// JAMAIS casser le modele existant : la serialisation [wireValue] produit les
/// chaines 'visible' / 'flagged' / 'removed' attendues par les regles.
enum ContentModerationState {
  /// Contenu visible publiquement (etat initial, publication immediate).
  visible('visible'),

  /// Contenu signale, en cours d'examen (toujours visible par defaut).
  flagged('flagged'),

  /// Contenu retire (invisible en lecture publique).
  removed('removed');

  const ContentModerationState(this.wireValue);

  /// Valeur stockee dans Firestore / Drift (compatibilite modele Phase 8).
  final String wireValue;

  /// Reconstruit l'etat depuis sa valeur stockee.
  ///
  /// Leve un [ArgumentError] si la valeur est inconnue (etat corrompu visible,
  /// pas masque).
  static ContentModerationState fromWire(String value) =>
      ContentModerationState.values.firstWhere(
        (s) => s.wireValue == value,
        orElse: () => throw ArgumentError.value(
          value,
          'value',
          'moderationState inconnu',
        ),
      );
}

/// Cycle de vie d'une NOTIFICATION de moderation (art 16).
enum ModerationStatus {
  /// Notification recue, pas encore prise en charge (etat initial).
  recue('recue'),

  /// Notification en cours de traitement par un moderateur.
  enTraitement('en_traitement'),

  /// Notification traitee (une [ModerationDecision] a ete rendue).
  traitee('traitee');

  const ModerationStatus(this.wireValue);

  /// Valeur stockee (champ `status` de reports_moderation, cf. D4C-02).
  final String wireValue;

  /// Reconstruit le statut depuis sa valeur stockee.
  static ModerationStatus fromWire(String value) =>
      ModerationStatus.values.firstWhere(
        (s) => s.wireValue == value,
        orElse: () =>
            throw ArgumentError.value(value, 'value', 'status inconnu'),
      );
}

/// Decision rendue par un moderateur a l'issue de l'examen d'une notification.
///
/// Determine la transition du [ContentModerationState] du contenu cible
/// (moderation A POSTERIORI, statut hebergeur).
enum ModerationDecision {
  /// On garde le contenu : il redevient/reste `visible`.
  keep(ContentModerationState.visible),

  /// On restreint le contenu sans le retirer : il passe `flagged`.
  restrict(ContentModerationState.flagged),

  /// On retire le contenu : il passe `removed`.
  remove(ContentModerationState.removed);

  const ModerationDecision(this.resultingState);

  /// Etat de moderation resultant pour le contenu cible apres cette decision.
  final ContentModerationState resultingState;
}

/// Notification de moderation NOTICE-AND-ACTION (DSA art 16), immuable.
///
/// Porte les mentions exigees par l'art 16 : explication suffisamment etayee
/// ([motif]), localisation electronique precise du contenu ([contentType] +
/// [contentRef]), nom/email du notifiant ([notifierContact]) et declaration de
/// bonne foi ([bonneFoi]). Horodatee ([createdAt]). Le suivi du traitement est
/// porte par [status] et, une fois traitee, par [decision].
class ModerationReport {
  ModerationReport({
    required this.id,
    required this.contentType,
    required this.contentRef,
    required this.motif,
    required this.notifierContact,
    required this.bonneFoi,
    required this.createdAt,
    this.status = ModerationStatus.recue,
    this.decision,
  });

  /// Identifiant de la notification (doc id reports_moderation).
  final String id;

  /// Type du contenu signale (determine la collection cible).
  final ModeratedContentType contentType;

  /// Reference du contenu signale (doc id dans sa collection).
  final String contentRef;

  /// Motif du signalement (explication etayee, art 16).
  final String motif;

  /// Contact du notifiant (email) — DONNEE PERSONNELLE, jamais exposee
  /// publiquement (acces reserve moderateur en D4C-02).
  final String notifierContact;

  /// Declaration de bonne foi du notifiant (art 16).
  final bool bonneFoi;

  /// Horodatage de reception de la notification.
  final DateTime createdAt;

  /// Statut courant du traitement (recue / en_traitement / traitee).
  final ModerationStatus status;

  /// Decision rendue (presente uniquement quand [status] == traitee).
  final ModerationDecision? decision;

  /// Copie avec un statut/decision mis a jour (immutabilite preservee).
  ModerationReport copyWith({
    ModerationStatus? status,
    ModerationDecision? decision,
  }) =>
      ModerationReport(
        id: id,
        contentType: contentType,
        contentRef: contentRef,
        motif: motif,
        notifierContact: notifierContact,
        bonneFoi: bonneFoi,
        createdAt: createdAt,
        status: status ?? this.status,
        decision: decision ?? this.decision,
      );

  /// Serialise la notification pour la persistance (collection
  /// reports_moderation, cf. regles D4C-02). Le schema des cles est borne par
  /// les regles Firestore a la creation.
  Map<String, dynamic> toMap() => <String, dynamic>{
        'contentType': contentType.storageKey,
        'contentRef': contentRef,
        'motif': motif,
        'notifierContact': notifierContact,
        'bonneFoi': bonneFoi,
        'createdAt': createdAt,
        'status': status.wireValue,
        if (decision != null) 'decision': decision!.name,
      };
}

/// Contrat de persistance des notifications de moderation.
///
/// Abstrait le backend (Firestore en prod via D4C-02 ; un faux en test) pour
/// garder [ModerationService] testable sans dependance reseau. Une
/// implementation Firestore reelle ecrit dans la collection
/// reports_moderation et met a jour le moderationState du contenu cible.
abstract class ModerationStore {
  /// Persiste une nouvelle notification de moderation (art 16).
  Future<void> saveReport(ModerationReport report);

  /// Met a jour le statut/decision d'une notification existante.
  Future<void> updateReport(ModerationReport report);

  /// Applique la transition de moderationState au contenu cible (a posteriori).
  ///
  /// Effectue cote backend en prod (Cloud Function D4C-02 avec privileges
  /// moderateur) ; modelise ici la consequence d'une decision.
  Future<void> applyContentState(
    ModeratedContentType contentType,
    String contentRef,
    ContentModerationState state,
  );
}

/// Exception levee quand une notification de moderation est invalide (art 16).
///
/// Remontee a l'appelant (UI D4C-03) pour afficher un message clair : aucune
/// notification incomplete ne doit etre creee silencieusement.
class InvalidModerationReport implements Exception {
  const InvalidModerationReport(this.message);

  /// Description du champ manquant/invalide (art 16).
  final String message;

  @override
  String toString() => 'InvalidModerationReport: $message';
}

/// Service de moderation hebergeur DSA — notice-and-action art 16 (D4C-01).
///
/// Cree des notifications de moderation valides, suit leur traitement, et
/// modelise la transition de moderationState du contenu cible apres decision
/// d'un moderateur (moderation A POSTERIORI, statut hebergeur).
class ModerationService {
  ModerationService({
    required ModerationStore store,
    String Function()? idGenerator,
    DateTime Function()? now,
  })  : _store = store,
        _idGenerator = idGenerator ?? _defaultIdGenerator,
        _now = now ?? DateTime.now;

  /// Backend de persistance (Firestore en prod, faux en test).
  final ModerationStore _store;

  /// Generateur d'identifiant de notification (injectable en test).
  final String Function() _idGenerator;

  /// Horloge (injectable en test pour un horodatage deterministe).
  final DateTime Function() _now;

  /// Diffuse chaque notification creee/mise a jour (suivi UI/analytics).
  final StreamController<ModerationReport> _controller =
      StreamController<ModerationReport>.broadcast();

  /// Flux des notifications de moderation (creation et changements d'etat).
  Stream<ModerationReport> get reports => _controller.stream;

  /// Cree une notification NOTICE-AND-ACTION (DSA art 16).
  ///
  /// Valide les mentions obligatoires (motif non vide, reference du contenu,
  /// contact du notifiant plausible, declaration de bonne foi a vrai), cree la
  /// notification horodatee au statut `recue`, la persiste et la diffuse.
  ///
  /// Leve [InvalidModerationReport] si une mention obligatoire manque (zero
  /// catch silencieux : l'UI doit savoir pourquoi le signalement est refuse).
  Future<ModerationReport> reportContent({
    required ModeratedContentType contentType,
    required String contentRef,
    required String motif,
    required String notifierContact,
    required bool bonneFoi,
  }) async {
    final trimmedRef = contentRef.trim();
    final trimmedMotif = motif.trim();
    final trimmedContact = notifierContact.trim();

    if (trimmedRef.isEmpty) {
      throw const InvalidModerationReport('contentRef manquant');
    }
    if (trimmedMotif.isEmpty) {
      throw const InvalidModerationReport('motif manquant (art 16)');
    }
    if (!_looksLikeEmail(trimmedContact)) {
      throw const InvalidModerationReport(
        'contact du notifiant invalide (art 16)',
      );
    }
    if (!bonneFoi) {
      throw const InvalidModerationReport(
        'declaration de bonne foi requise (art 16)',
      );
    }

    final report = ModerationReport(
      id: _idGenerator(),
      contentType: contentType,
      contentRef: trimmedRef,
      motif: trimmedMotif,
      notifierContact: trimmedContact,
      bonneFoi: bonneFoi,
      createdAt: _now(),
    );

    await _store.saveReport(report);
    _controller.add(report);
    return report;
  }

  /// Marque une notification comme prise en charge (`en_traitement`).
  ///
  /// Etape de suivi cote moderateur (l'autorisation reelle est portee par les
  /// regles/role moderateur D4C-02). Diffuse l'etat mis a jour.
  Future<ModerationReport> markInProgress(ModerationReport report) async {
    final updated = report.copyWith(status: ModerationStatus.enTraitement);
    await _store.updateReport(updated);
    _controller.add(updated);
    return updated;
  }

  /// Rend une DECISION de moderation et applique ses consequences (art 16/17).
  ///
  /// Passe la notification au statut `traitee` avec sa [decision], puis fait
  /// transiter le moderationState du contenu cible (moderation A POSTERIORI) :
  ///   keep -> visible, restrict -> flagged, remove -> removed.
  /// L'expose des motifs (art 17) est forme cote backend (D4C-02) a partir de
  /// cette decision ; ce service en porte le declencheur.
  Future<ModerationReport> decide(
    ModerationReport report,
    ModerationDecision decision,
  ) async {
    final resolved = report.copyWith(
      status: ModerationStatus.traitee,
      decision: decision,
    );
    await _store.updateReport(resolved);
    await _store.applyContentState(
      resolved.contentType,
      resolved.contentRef,
      decision.resultingState,
    );
    _controller.add(resolved);
    return resolved;
  }

  /// Identifiant par defaut : horodatage + compteur (suffisant cote client ;
  /// en prod le doc id reel est attribue par Firestore via D4C-02).
  static String _defaultIdGenerator() =>
      'report_${DateTime.now().microsecondsSinceEpoch}';

  /// Validation minimale d'un email (presence d'un `@` encadre de caracteres).
  ///
  /// Volontairement simple : la validation forte releve du formulaire UI
  /// (D4C-03) ; ici on refuse seulement les contacts manifestement vides ou
  /// malformes pour garantir une notification art 16 exploitable.
  static bool _looksLikeEmail(String value) {
    final at = value.indexOf('@');
    if (at <= 0 || at == value.length - 1) return false;
    final domain = value.substring(at + 1);
    return domain.contains('.') && !domain.endsWith('.');
  }

  /// Libere le StreamController. A appeler quand le service est detruit.
  void dispose() {
    _controller.close();
  }
}
