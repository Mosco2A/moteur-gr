/// Liste FERMEE des champs du registre de consentement. Ce qui n'y entrera
/// jamais : la donnee de sante elle-meme, seulement l'etat du accord.
library;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart" as fb;
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:shared_preferences/shared_preferences.dart";

import "../firebase/firebase_service.dart";
import "../providers/service_providers.dart";
import "consent_service.dart";

/// LES SEULS CHAMPS QUE LE REGISTRE DE CONSENTEMENT PORTE — LISTE FERMEE.
///
/// Meme forme que la fiche technique (tache 635) et le coffre distant (tache
/// 612), et pour la meme raison : interdire le mot « sante » n'aurait rien
/// protege, le prochain champ se serait appele autrement. On n'ecrit QUE ce qui
/// est nomme ici, et tout le reste est retire avant d'atteindre le reseau.
///
/// CE QUI N'Y EST PAS, ET N'Y ENTRERA JAMAIS : la DONNEE elle-meme. Christophe,
/// verbatim le 30/09 12:32 : « Le consentement est dans nos bases, horodate,
/// c'est les donnees qui n'y sont pas ». Ce document dit QU'ON A DEMANDE, QUAND,
/// SOUS QUEL TEXTE et POURQUOI — jamais un groupe sanguin, une allergie, un
/// traitement, un age, un poids.
abstract final class ConsentRegistryFields {
  /// La decision : accorde ou refuse.
  static const String accorde = "granted";

  /// Instant de la decision, DATE PAR LE SERVEUR.
  static const String decideLe = "decided_at";

  /// Instant de l'ecriture, date par le serveur.
  static const String misAJourLe = "updated_at";

  /// Version du texte de politique en vigueur au moment du choix.
  static const String versionDuTexte = "version_du_texte";

  /// Ce qui a provoque la demande ([ConsentTrigger.code]).
  static const String declencheur = "declencheur";

  /// L'INSTANT QUE LE TELEPHONE A RETENU, ET POURQUOI IL EST LA.
  ///
  /// CE CHAMP EST UN AJOUT A LA LISTE DEMANDEE, ET C'EST DELIBERE. Le serveur
  /// date l'ECRITURE ; or une decision prise en montagne, hors reseau, n'arrive
  /// au serveur que des jours plus tard. Sans ce champ, le registre daterait le
  /// consentement du jour ou il a ete TRANSMIS et non du jour ou il a ete PRIS —
  /// une inexactitude materielle pour la preuve du consentement (RGPD art. 7-1).
  ///
  /// L'ARBITRE RESTE LE SERVEUR : le lot 610 interdit au telephone de dater quoi
  /// que ce soit qui fasse foi, parce que son horloge se regle. Celui-ci est donc
  /// une INDICATION, pas une preuve, et il est nomme comme tel.
  static const String decideSurLeTelephoneLe = "decide_sur_le_telephone_le";

  /// La liste fermee. Tout ce qui n'y est pas est retire avant envoi.
  static const Set<String> autorises = {
    accorde,
    decideLe,
    misAJourLe,
    versionDuTexte,
    declencheur,
    decideSurLeTelephoneLe,
  };
}

/// LE REGISTRE DE CONSENTEMENT VIT EN BASE, ET IL N'Y VIVAIT PAS (tache 638).
///
/// DECISION DE CHRISTOPHE DU 30/09 12:32, verbatim : « Le consentement est dans
/// nos bases, horodate, c'est les donnees qui n'y sont pas ».
///
/// LE DEFAUT MESURE. `ConsentService` horodate chaque decision depuis le lot
/// D4A-01 — et l'enregistre dans les `SharedPreferences` du telephone, nulle
/// part ailleurs. Consequence : effacer l'application effacait la PREUVE du
/// consentement, et la montee du lot 635 ne poussait aucun consentement (elle
/// portait la progression, le sac et les randos passees). Un consentement qu'on
/// ne peut pas produire n'est pas un consentement recueilli : c'est une case
/// cochee sur un appareil.
///
/// CE QUI MONTE : `users/{uid}/consents/{finalite}`, un document par finalite
/// ayant recu une decision, avec [ConsentRegistryFields.autorises] et
/// rien d'autre. Une finalite jamais tranchee n'a pas de document — l'absence de
/// decision est une information, et l'inventer serait un faux.
///
/// CE QUI NE MONTE PAS : la donnee protegee. La fiche medicale reste sur le
/// telephone (liste fermee de la tache 612, intacte), la morphologie aussi
/// (tache 635). Ce service ne connait AUCUN champ de sante, et une invariante le
/// verifie.
///
/// UNE DECISION NE SE REECRIT PAS A CHAQUE PASSE, et c'est le point delicat.
/// `decided_at` est un horodatage SERVEUR : le renvoyer a chaque reveil de la
/// montee deplacerait la date du consentement a chaque lancement de
/// l'application. Le service retient donc, en local, l'EMPREINTE de la derniere
/// decision reellement poussee et ne repousse que ce qui a bouge.
///
/// ELLE NE LEVE JAMAIS. Sans Firebase, sans reseau, sans identite : rien n'est
/// ecrit, l'empreinte n'est pas mise a jour, et la decision partira au prochain
/// passage. Une montee de registre qui empecherait de marcher serait pire que
/// pas de registre.
class MonteeDesConsentements {
  MonteeDesConsentements({
    required this.firebaseService,
    required this.identifiant,
    required this.etats,
    required this.preferences,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  /// Firebase est-il seulement la ?
  final FirebaseService firebaseService;

  /// QUI ECRIT — l'identifiant d'AUTHENTIFICATION, jamais le hash anonymise :
  /// `firestore.rules` n'autorise `users/{userId}` que si
  /// `request.auth.uid == userId`.
  final Future<String?> Function() identifiant;

  /// L'etat de consentement de toutes les finalites, lu au moment de monter.
  final Future<Map<ConsentPurpose, ConsentState>> Function() etats;

  /// Ou l'on retient l'empreinte de ce qui a deja ete pousse.
  final SharedPreferences preferences;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _base => _firestore ?? FirebaseFirestore.instance;

  /// Cle de l'empreinte de la derniere decision poussee pour [purpose].
  static String cleDEmpreinte(ConsentPurpose purpose) =>
      'consent_montee_${purpose.name}';

  /// L'EMPREINTE D'UNE DECISION — ce qui permet de savoir si elle a change.
  ///
  /// Tout ce qui, en changeant, doit produire une nouvelle ecriture : la
  /// decision, son instant, la version du texte, le declencheur et la revision
  /// des donnees. Fonction pure.
  @visibleForTesting
  static String empreinte(ConsentState etat) => [
    etat.granted,
    etat.decidedAt?.millisecondsSinceEpoch,
    etat.policyVersion,
    etat.declencheur.code,
    etat.revisionDesDonnees,
  ].join("|");

  /// LA CHARGE UTILE, FONCTION PURE — c'est elle que les tests interrogent.
  ///
  /// Le filtre final sur [ConsentRegistryFields.autorises] est une
  /// ceinture en plus des bretelles : il rend structurellement impossible qu'un
  /// champ ajoute ici un jour parte sans avoir ete nomme dans la liste fermee.
  @visibleForTesting
  static Map<String, Object?> buildPayload(ConsentState etat) {
    final payload = <String, Object?>{
      ConsentRegistryFields.accorde: etat.granted,
      ConsentRegistryFields.decideLe: FieldValue.serverTimestamp(),
      ConsentRegistryFields.misAJourLe: FieldValue.serverTimestamp(),
      ConsentRegistryFields.versionDuTexte: etat.policyVersion,
      ConsentRegistryFields.declencheur: etat.declencheur.code,
      ConsentRegistryFields.decideSurLeTelephoneLe: etat.decidedAt
          ?.toUtc()
          .toIso8601String(),
    };
    payload.removeWhere(
      (cle, _) => !ConsentRegistryFields.autorises.contains(cle),
    );
    return payload;
  }

  /// MONTE LES DECISIONS QUI ONT BOUGE. Rend le nombre de documents ecrits.
  ///
  /// Ne leve jamais : un registre qui ne peut pas partir aujourd'hui partira
  /// demain, et l'application continue entre-temps.
  Future<int> monter() async {
    if (!firebaseService.isAvailable) return 0;

    final String? uid;
    try {
      uid = await identifiant();
    } on Object {
      return 0;
    }
    if (uid == null || uid.isEmpty) return 0;

    final Map<ConsentPurpose, ConsentState> tous;
    try {
      tous = await etats();
    } on Object catch (e) {
      debugPrint("[RegistreConsentement] etats illisibles : $e");
      return 0;
    }

    var ecrits = 0;
    final racine = _base.collection("users").doc(uid).collection("consents");

    for (final entree in tous.entries) {
      final etat = entree.value;

      // UNE FINALITE JAMAIS TRANCHEE N'A PAS DE DOCUMENT. L'absence de decision
      // est une information ; ecrire « granted: false » sans decision en
      // fabriquerait une qui n'a pas eu lieu.
      if (etat.decidedAt == null) continue;

      final signature = empreinte(etat);
      if (preferences.getString(cleDEmpreinte(entree.key)) == signature) {
        continue; // deja pousse, a l'identique
      }

      try {
        await racine.doc(entree.key.name).set(buildPayload(etat));
        // L'EMPREINTE NE SE POSE QU'APRES UNE ECRITURE REUSSIE. Posee avant, un
        // refus de regle ou une coupure ferait croire la decision enregistree et
        // elle ne repartirait jamais.
        await preferences.setString(cleDEmpreinte(entree.key), signature);
        ecrits++;
      } on Object catch (e) {
        debugPrint("[RegistreConsentement] ${entree.key.name} : $e");
      }
    }

    if (ecrits > 0) {
      debugPrint("[RegistreConsentement] $ecrits decision(s) montee(s)");
    }
    return ecrits;
  }
}

/// Provider du registre de consentement (tache 638).
///
/// ASYNCHRONE parce qu'il lui faut les preferences, et qu'elles le sont. Lu au
/// premier reveil de la montee, pas a sa creation.
final monteeDesConsentementsProvider = FutureProvider<MonteeDesConsentements>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return MonteeDesConsentements(
    firebaseService: ref.watch(firebaseServiceProvider),
    identifiant: () async => fb.FirebaseAuth.instance.currentUser?.uid,
    etats: () async {
      final service = await ref.read(consentServiceReadyProvider.future);
      return service.allStates();
    },
    preferences: prefs,
  );
});
