import "dart:io" show Platform;

import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart" as fb;
import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:package_info_plus/package_info_plus.dart";

import "../../i18n/translations.g.dart";
import "../firebase/firebase_service.dart";

/// CE QUE LA FICHE TECHNIQUE PORTE, ET RIEN D AUTRE — LISTE FERMEE (tache 635).
///
/// POURQUOI UNE LISTE FERMEE ET PAS UN INTERDIT NOMME. Meme raisonnement que le
/// coffre distant de la tache 612 : interdire le mot « email » n aurait rien
/// protege, le prochain champ se serait appele « contact » ou « adresse_v2 » et
/// serait passe. On n ecrit QUE ce qui est nomme ici, et tout le reste est
/// refuse avant le reseau. Ouvrir un champ exige d ecrire son nom dans cette
/// liste, donc de croiser la decision de Christophe du 29/09 : « Sauf les
/// donnees persos ».
///
/// CE QUI N Y EST PAS, ET NE DOIT JAMAIS Y ENTRER : nom, prenom, courriel,
/// telephone, adresse, fiche sante, contacts d urgence, journal, morphologie.
/// Une invariante (`test/comportement/montee_en_base_635_test.dart`) le verifie.
abstract final class ChampsDeLaFicheTechnique {
  /// Premiere venue de ce compte, posee UNE SEULE FOIS, par le serveur.
  static const String creeLe = "created_at";

  /// Derniere venue : rafraichie a chaque demarrage et retour au premier plan.
  static const String vuLe = "last_seen_at";

  /// Version publiee de l application (ex. « 1.4.2 »).
  static const String versionApplication = "app_version";

  /// Numero de fabrication (ex. « 7 »).
  static const String fabrication = "build";

  /// Systeme : « android », « ios », « macos »...
  static const String systeme = "platform";

  /// Version du systeme telle que le telephone la donne.
  static const String versionSysteme = "os_version";

  /// Langue AFFICHEE par l application (le choix du randonneur, pas le reglage
  /// du telephone) : c est celle qui explique ce qu il voit a l ecran.
  static const String langue = "language";

  /// Fuseau horaire, sous sa forme lisible + decalage UTC.
  static const String fuseau = "timezone";

  /// La liste fermee elle-meme. Tout ce qui n y est pas est retire avant envoi.
  static const Set<String> autorises = {
    creeLe,
    vuLe,
    versionApplication,
    fabrication,
    systeme,
    versionSysteme,
    langue,
    fuseau,
  };
}

/// CE QUE LE TELEPHONE SAIT DE LUI-MEME. Aucune donnee personnelle.
///
/// Valeurs SEPAREES de leur lecture (`PackageInfo`, `Platform`) pour que la
/// construction de la charge utile soit une fonction PURE, donc verifiable sans
/// telephone et sans reseau.
@immutable
class RenseignementsDuTelephone {
  const RenseignementsDuTelephone({
    required this.versionApplication,
    required this.fabrication,
    required this.systeme,
    required this.versionSysteme,
    required this.langue,
    required this.fuseau,
  });

  final String versionApplication;
  final String fabrication;
  final String systeme;
  final String versionSysteme;
  final String langue;
  final String fuseau;

  /// Lit les renseignements REELS du telephone. Ne leve pas : un renseignement
  /// illisible devient une chaine vide plutot que d empecher toute la fiche.
  static Future<RenseignementsDuTelephone> duTelephone({
    required String langue,
    DateTime? maintenant,
  }) async {
    var version = "";
    var fabrication = "";
    try {
      final paquet = await PackageInfo.fromPlatform();
      version = paquet.version;
      fabrication = paquet.buildNumber;
    } on Object {
      // Un paquet illisible (test, bureau) ne doit pas faire disparaitre la
      // fiche entiere : le reste des renseignements a toujours sa valeur.
    }

    var systeme = defaultTargetPlatform.name;
    var versionSysteme = "";
    try {
      systeme = Platform.operatingSystem;
      versionSysteme = Platform.operatingSystemVersion;
    } on Object {
      // Idem : sur une plateforme sans `dart:io` exploitable, on garde le nom
      // rendu par Flutter.
    }

    final instant = maintenant ?? DateTime.now();
    return RenseignementsDuTelephone(
      versionApplication: version,
      fabrication: fabrication,
      systeme: systeme,
      versionSysteme: versionSysteme,
      langue: langue,
      fuseau: decrireLeFuseau(instant),
    );
  }

  /// « CEST (UTC+02:00) » — le nom que donne le systeme, ET le decalage, parce
  /// que le nom seul n est pas comparable d un telephone a l autre.
  static String decrireLeFuseau(DateTime instant) {
    final decalage = instant.timeZoneOffset;
    final signe = decalage.isNegative ? "-" : "+";
    final heures = decalage.inHours.abs().toString().padLeft(2, "0");
    final minutes = (decalage.inMinutes.abs() % 60).toString().padLeft(2, "0");
    return "${instant.timeZoneName} (UTC$signe$heures:$minutes)";
  }
}

/// LA FICHE TECHNIQUE DU TELEPHONE — LE DOCUMENT `users/{uid}` QUI N EXISTAIT
/// PAS (tache 635).
///
/// LE DEFAUT MESURE. La console Firestore affichait l utilisateur EN ITALIQUE et
/// Christophe l a dit mot pour mot le 29/09 : « donnees dans la base ni
/// utilisateur ni sentier ????? ». L italique de la console veut dire exactement
/// ceci : le document racine `users/{uid}` N EXISTE PAS, il n est qu un chemin
/// deduit de ses sous-collections. Aucun code, nulle part, ne l ecrivait — la
/// descente des droits (tache 631) ne fait que LIRE, et la montee n etait
/// branchee nulle part.
///
/// CE QU ELLE POSE, ET CE QU ELLE NE POSERA JAMAIS. Uniquement
/// [ChampsDeLaFicheTechnique.autorises] : de quoi reconnaitre un telephone, sa
/// version d application et son systeme quand il faudra diagnostiquer quelque
/// chose. JAMAIS un nom, un prenom, un courriel, un numero, une adresse, ni quoi
/// que ce soit venu de la fiche sante. Decision de Christophe, verbatim : « Sauf
/// les donnees persos ».
///
/// `created_at` EST POSE UNE SEULE FOIS, ET C EST LE SERVEUR QUI LE DATE. Le lot
/// 610 interdit au telephone de dater quoi que ce soit (son horloge est
/// reglable, donc elle ne prouve rien) : on ecrit [FieldValue.serverTimestamp].
/// Et pour qu il ne soit pose qu une fois, on LIT d abord le document : s il
/// porte deja sa date de naissance, on ne la renvoie pas. Un simple `merge`
/// n aurait pas suffi — un `serverTimestamp` renvoye ECRASE l ancien, et l age
/// du compte serait devenu « maintenant » a chaque lancement.
///
/// ELLE NE LEVE JAMAIS. Sans Firebase, sans reseau, sans identite, elle rend
/// `false` et n ecrit rien. Une fiche technique qui empecherait de marcher
/// serait pire que pas de fiche du tout.
class FicheTechniqueDuTelephone {
  FicheTechniqueDuTelephone({
    required this.firebaseService,
    required this.identifiant,
    required this.renseignements,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore;

  /// Firebase est-il seulement la ?
  final FirebaseService firebaseService;

  /// QUI ECRIT — l identifiant d AUTHENTIFICATION, jamais le hash.
  ///
  /// `firestore.rules` n autorise `users/{userId}` que si
  /// `request.auth.uid == userId` : tout autre identifiant se ferait refuser.
  /// Pour un compte anonyme, ce numero ne designe personne.
  final Future<String?> Function() identifiant;

  /// Les renseignements du telephone, injectes pour rester verifiables.
  final Future<RenseignementsDuTelephone> Function() renseignements;

  final FirebaseFirestore? _firestore;

  FirebaseFirestore get _base => _firestore ?? FirebaseFirestore.instance;

  /// LA CHARGE UTILE, FONCTION PURE — c est elle que les tests interrogent.
  ///
  /// [premiereVenue] vrai => la date de naissance est posee. Faux => elle n est
  /// meme pas dans la charge, donc rien ne peut l ecraser.
  ///
  /// Le filtre final sur [ChampsDeLaFicheTechnique.autorises] est une ceinture
  /// en plus des bretelles : il rend structurellement impossible qu un champ
  /// ajoute ici un jour parte sans avoir ete nomme dans la liste fermee.
  @visibleForTesting
  static Map<String, Object?> construireLaCharge(
    RenseignementsDuTelephone r, {
    required bool premiereVenue,
  }) {
    final charge = <String, Object?>{
      ChampsDeLaFicheTechnique.vuLe: FieldValue.serverTimestamp(),
      ChampsDeLaFicheTechnique.versionApplication: r.versionApplication,
      ChampsDeLaFicheTechnique.fabrication: r.fabrication,
      ChampsDeLaFicheTechnique.systeme: r.systeme,
      ChampsDeLaFicheTechnique.versionSysteme: r.versionSysteme,
      ChampsDeLaFicheTechnique.langue: r.langue,
      ChampsDeLaFicheTechnique.fuseau: r.fuseau,
      if (premiereVenue)
        ChampsDeLaFicheTechnique.creeLe: FieldValue.serverTimestamp(),
    };
    charge.removeWhere(
      (cle, _) => !ChampsDeLaFicheTechnique.autorises.contains(cle),
    );
    return charge;
  }

  /// POSE OU RAFRAICHIT LA FICHE. Rend vrai si quelque chose a ete ecrit.
  ///
  /// Toujours en `merge` : la fiche technique ne doit jamais effacer ce que
  /// d autres chemins (le serveur, une version future) auraient depose sur le
  /// meme document.
  Future<bool> poser() async {
    if (!firebaseService.isAvailable) return false;

    final String? uid;
    try {
      uid = await identifiant();
    } on Object {
      return false;
    }
    if (uid == null || uid.isEmpty) return false;

    try {
      final document = _base.collection("users").doc(uid);

      // LA LECTURE QUI EVITE D EFFACER L AGE DU COMPTE. Elle coute une lecture
      // de document par demarrage — une misere — et c est le seul moyen de
      // n ecrire `created_at` qu une fois.
      var premiereVenue = true;
      try {
        final connu = await document.get();
        premiereVenue =
            !connu.exists ||
            connu.data()?[ChampsDeLaFicheTechnique.creeLe] == null;
      } on Object {
        // Lecture refusee ou coupee : on ne pose PAS la date de naissance. On
        // prefere une fiche sans age a un age remis a zero.
        premiereVenue = false;
      }

      final r = await renseignements();
      await document.set(
        construireLaCharge(r, premiereVenue: premiereVenue),
        SetOptions(merge: true),
      );
      return true;
    } on Object catch (e) {
      debugPrint("[FicheTechnique] ecriture impossible : $e");
      return false;
    }
  }
}

/// Provider de la fiche technique.
///
/// L IDENTIFIANT EST CELUI DE L AUTHENTIFICATION, ET C EST LA SEULE VALEUR
/// POSSIBLE — meme raison que pour `descenteDesDroitsProvider` :
/// `firestore.rules` n autorise `users/{userId}` que si
/// `request.auth.uid == userId`, donc un document range sous le hash anonymise
/// serait refuse.
///
/// LA LANGUE EST LUE AU MOMENT DE POSER LA FICHE, pas a la construction du
/// service : le randonneur peut en changer sans redemarrer, et c est la langue
/// qu il voit qui a une valeur de diagnostic.
final ficheTechniqueDuTelephoneProvider = Provider<FicheTechniqueDuTelephone>((
  ref,
) {
  return FicheTechniqueDuTelephone(
    firebaseService: ref.watch(firebaseServiceProvider),
    identifiant: () async => fb.FirebaseAuth.instance.currentUser?.uid,
    renseignements: () => RenseignementsDuTelephone.duTelephone(
      langue: LocaleSettings.currentLocale.languageCode,
    ),
  );
});
