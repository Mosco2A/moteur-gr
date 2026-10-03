import "dart:io";

import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:moteur_gr/core/data/daos/no_ads_dao.dart";
import "package:moteur_gr/core/data/daos/trek_entitlements_dao.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/data/revision_de_donnee.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/descente_des_droits.dart";
import "package:moteur_gr/core/services/droits_distants.dart";
import "package:moteur_gr/core/services/wallet_store.dart";

/// LA DESCENTE DES DROITS — LE SERVEUR FAIT FOI, MAIS N EFFACE PAS CE QU IL NE
/// SAIT PAS (tache 631).
///
/// CE QUE CES TESTS PROUVENT, ET POURQUOI CHACUN COMPTE :
///
///   1. LA REGLE DE RESOLUTION, cas par cas et SANS HORLOGE. Les deux compteurs
///      du compte-etapes ne font que MONTER (mesure faite dans
///      `wallet_store.dart` : `credit` n augmente que le gagne, `debit` que la
///      depense). Leur maximum est donc la fusion EXACTE, et elle ne demande
///      aucun horodatage — ce qui tombe bien, puisque le lot 610 interdit au
///      telephone de dater quoi que ce soit. Le cas qui compte vraiment : UNE
///      DEPENSE FAITE HORS LIGNE NE REVIENT JAMAIS.
///
///   2. L IDEMPOTENCE. Rejouer la descente ne doit rien changer. Une descente
///      qui recrediterait a chaque passe ferait du solde une fonction du nombre
///      de synchronisations.
///
///   3. LES TROIS SORTIES SANS EFFET : pas de Firebase, hors ligne, pas
///      d identifiant. Dans les trois cas la copie locale est INTACTE. C est le
///      cas nominal en montagne, et c est aussi l etat du telephone aujourd hui.
///
///   4. L ABONNEMENT, LE SEUL QUI PUISSE DESCENDRE, est arbitre par
///      l horodatage de serveur : une annonce plus ancienne que la derniere
///      appliquee est IGNOREE, une plus recente s applique, et une resiliation
///      RETIRE reellement l abonnement.
class _FirebaseAbsent implements FirebaseService {
  @override
  bool get isAvailable => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FirebasePresent implements FirebaseService {
  @override
  bool get isAvailable => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _Reseau implements ConnectivityMonitor {
  _Reseau({this.enLigne = true});
  final bool enLigne;

  @override
  Future<ConnectivityStatus> checkStatus() async => enLigne
      ? ConnectivityStatusValues.online
      : ConnectivityStatusValues.offline;

  @override
  Stream<ConnectivityStatus> get onStatusChange => const Stream.empty();

  @override
  Future<TypeDeLien> typeDeLien() async => TypesDeLien.wifi;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  verifierLesRegles();

  // ==========================================================================
  // LA REGLE DE RESOLUTION, en logique pure — aucun reseau, aucune base.
  // ==========================================================================
  group("631 — la regle de resolution", () {
    test("une depense faite HORS LIGNE ne revient pas, meme si le serveur "
        "annonce un solde plus vieux", () {
      // Le telephone avait 50 etapes gagnees, il en a depense 12 hors ligne.
      // Le serveur, lui, n a jamais vu cette depense : il annonce 50 / 0.
      final fusion = fusionnerSolde(
        gagneLocal: 50,
        depenseLocal: 12,
        distant: const SoldeDistant(cumulGagne: 50, cumulDepense: 0),
      );
      expect(fusion.cumulDepense, 12, reason: "la depense est PRESERVEE");
      expect(fusion.solde, 38, reason: "et surtout : elle n est pas rendue");
    });

    test("un credit pose au SERVEUR arrive, meme si le telephone a depense "
        "entre-temps", () {
      // Skynet credite 50 etapes au serveur (gagne 50). Pendant ce temps le
      // telephone a depense 12 de ses anciennes etapes.
      final fusion = fusionnerSolde(
        gagneLocal: 20,
        depenseLocal: 12,
        distant: const SoldeDistant(cumulGagne: 50, cumulDepense: 0),
      );
      expect(fusion.cumulGagne, 50);
      expect(fusion.cumulDepense, 12);
      expect(fusion.solde, 38, reason: "les deux mouvements se combinent");
    });

    test("la fusion est IDEMPOTENTE : la rejouer ne change rien", () {
      const distant = SoldeDistant(cumulGagne: 50, cumulDepense: 0);
      final une = fusionnerSolde(
        gagneLocal: 0,
        depenseLocal: 0,
        distant: distant,
      );
      final deux = fusionnerSolde(
        gagneLocal: une.cumulGagne,
        depenseLocal: une.cumulDepense,
        distant: distant,
      );
      expect(deux.cumulGagne, une.cumulGagne);
      expect(deux.cumulDepense, une.cumulDepense);
      expect(deux.solde, une.solde);
    });

    test(
      "un solde ne devient jamais negatif, meme sur un serveur incoherent",
      () {
        final fusion = fusionnerSolde(
          gagneLocal: 0,
          depenseLocal: 40,
          distant: const SoldeDistant(cumulGagne: 10, cumulDepense: 40),
        );
        expect(
          fusion.solde,
          0,
          reason: "un solde negatif bloquerait tout achat futur sans rien dire",
        );
      },
    );

    test("un droit de sentier est un LOQUET : une lecture en retard ne le "
        "retire pas", () {
      final fusion = mergeTrailEntitlement(
        possedeLocal: true,
        etapesAcquisesLocal: 12,
        complementConsommeLocal: 0,
        distant: const DroitDeSentierDistant(
          trailId: "mare-a-mare-centre",
          possede: false,
          etapesAcquises: 0,
          complementConsomme: 0,
        ),
      );
      expect(fusion.possede, isTrue);
      expect(
        fusion.etapesAcquises,
        12,
        reason: "les etapes acquises ne se repaient jamais (modele 2.5)",
      );
    });

    test(
      "un achat fait AILLEURS arrive sur un telephone qui ne le connait pas",
      () {
        final fusion = mergeTrailEntitlement(
          possedeLocal: false,
          etapesAcquisesLocal: 0,
          complementConsommeLocal: 0,
          distant: const DroitDeSentierDistant(
            trailId: "mare-a-mare-centre",
            possede: true,
            etapesAcquises: 12,
            complementConsomme: 0,
          ),
        );
        expect(fusion.possede, isTrue);
        expect(fusion.etapesAcquises, 12);
      },
    );

    test("un abonnement ACTIF sans echeance est REFUSE (jamais d abonnement "
        "a vie)", () {
      // Regle d or #99404, que le lot 594 a du restaurer.
      final lu = AbonnementDistant.lire({
        "active": true,
        "updated_at": "2026-09-29T12:00:00.000Z",
      });
      expect(lu, isNull);
    });

    test("un abonnement sans horodatage de serveur est REFUSE", () {
      final lu = AbonnementDistant.lire({
        "active": true,
        "expires_at": "2026-10-30T12:00:00.000Z",
      });
      expect(
        lu,
        isNull,
        reason:
            "sans instant de serveur, impossible de savoir si cette "
            "annonce est plus recente que ce qui est deja applique",
      );
    });

    test("une annonce d abonnement PLUS ANCIENNE que la derniere appliquee est "
        "ignoree", () {
      final deja = HorodatageServeur.annonceParLeServeur(
        "2026-09-29T12:00:00.000Z",
      )!;
      final vieille = AbonnementDistant.lire({
        "active": true,
        "expires_at": "2026-10-30T12:00:00.000Z",
        "updated_at": "2026-09-29T11:00:00.000Z",
      })!;
      expect(
        abonnementAApplique(horodatageApplique: deja, distant: vieille),
        isFalse,
      );
    });
  });

  // ==========================================================================
  // LES SORTIES SANS EFFET — la copie locale reste INTACTE.
  // ==========================================================================
  group("631 — hors ligne et sans Firebase, rien ne bouge", () {
    late AppDatabase db;
    late WalletStore compte;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
      compte = WalletStore(db: db, prefs: prefs);
      await compte.load();
      await compte.credit(7);
    });

    tearDown(() async {
      compte.dispose();
      await db.close();
    });

    DescenteDesDroits fabriquer({
      required FirebaseService firebase,
      bool enLigne = true,
      String? uid = "uid-de-christophe",
    }) {
      return DescenteDesDroits(
        stageCount: compte,
        entitlementsDao: TrekEntitlementsDao(db),
        noAdsDao: NoAdsDao(db),
        firebaseService: firebase,
        connectivityMonitor: _Reseau(enLigne: enLigne),
        identifiant: () async => uid,
        preferences: prefs,
      );
    }

    test(
      "Firebase absent : sans effet, et le solde local est intact",
      () async {
        final r = await fabriquer(firebase: _FirebaseAbsent()).executer();
        expect(r.appliquee, isFalse);
        expect(r.raison, "Firebase indisponible");
        expect(compte.balanceSteps, 7);
      },
    );

    test("hors ligne : sans effet, et le solde local est intact", () async {
      final r = await fabriquer(
        firebase: _FirebasePresent(),
        enLigne: false,
      ).executer();
      expect(r.appliquee, isFalse);
      expect(r.raison, "hors ligne");
      expect(compte.balanceSteps, 7);
    });

    test("aucun identifiant de compte : sans effet", () async {
      final r = await fabriquer(
        firebase: _FirebasePresent(),
        uid: null,
      ).executer();
      expect(r.appliquee, isFalse);
      expect(r.raison, "aucun identifiant de compte");
      expect(compte.balanceSteps, 7);
    });
  });

  // ==========================================================================
  // L APPLICATION EN BASE — sans Firestore : on injecte ce que le serveur
  // aurait annonce, et on regarde ce qui est ECRIT.
  // ==========================================================================
  group("631 — ce que la descente ecrit dans la base locale", () {
    late AppDatabase db;
    late WalletStore compte;
    late SharedPreferences prefs;
    late DescenteDesDroits descente;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(NativeDatabase.memory());
      compte = WalletStore(db: db, prefs: prefs);
      await compte.load();
      descente = DescenteDesDroits(
        stageCount: compte,
        entitlementsDao: TrekEntitlementsDao(db),
        noAdsDao: NoAdsDao(db),
        firebaseService: _FirebasePresent(),
        connectivityMonitor: _Reseau(),
        identifiant: () async => "uid-de-christophe",
        preferences: prefs,
      );
    });

    tearDown(() async {
      compte.dispose();
      await db.close();
    });

    /// Ce que Skynet ecrira dans Firestore pour debloquer Christophe.
    DroitsDistants lExemple() => DroitsDistants(
      solde: const SoldeDistant(cumulGagne: 62, cumulDepense: 12),
      trails: const [
        DroitDeSentierDistant(
          trailId: "mare-a-mare-centre",
          possede: true,
          etapesAcquises: 12,
          complementConsomme: 0,
        ),
      ],
      subscription: AbonnementDistant(
        actif: true,
        echeance: DateTime.utc(2026, 10, 30),
        horodatage: HorodatageServeur.annonceParLeServeur(
          "2026-09-29T13:00:00.000Z",
        )!,
      ),
    );

    test("50 etapes, le sentier possede, l abonnement actif", () async {
      final r = await descente.appliquer(lExemple());

      expect(r.appliquee, isTrue);
      expect(compte.balanceSteps, 50, reason: "62 gagnees - 12 depensees");
      expect(r.sentiersMisAJour, contains("mare-a-mare-centre"));

      final droit = await TrekEntitlementsDao(
        db,
      ).getByTrailId("mare-a-mare-centre");
      expect(droit, isNotNull);
      expect(droit!.owned, isTrue);
      expect(droit.acquiredStages, 12);

      final abos = await NoAdsDao(db).getAll();
      expect(abos.where((a) => a.source == "subscription"), hasLength(1));
      expect(r.abonnementApplique, isTrue);
    });

    test("rejouee, elle n ecrit RIEN de plus", () async {
      await descente.appliquer(lExemple());
      final seconde = await descente.appliquer(lExemple());

      expect(seconde.appliquee, isFalse);
      expect(seconde.raison, "le telephone etait deja a jour");
      expect(compte.balanceSteps, 50);
      // ET SURTOUT : pas deux lignes d abonnement. Un abonnement est un ETAT,
      // pas une collection de lignes.
      final abos = await NoAdsDao(db).getAll();
      expect(abos.where((a) => a.source == "subscription"), hasLength(1));
    });

    test("une depense faite ENTRE DEUX descentes n est pas annulee par la "
        "seconde", () async {
      await descente.appliquer(lExemple());
      expect(compte.balanceSteps, 50);

      // Le randonneur depense 20 etapes hors ligne.
      await compte.debit(20);
      expect(compte.balanceSteps, 30);

      // Le serveur, lui, annonce toujours la meme chose : il n a rien vu.
      final seconde = await descente.appliquer(lExemple());

      expect(
        compte.balanceSteps,
        30,
        reason:
            "LE CAS QUI COMPTE : le serveur ne rend pas les etapes "
            "depensees hors ligne",
      );
      expect(seconde.appliquee, isFalse);
    });

    test(
      "une resiliation annoncee par le serveur RETIRE l abonnement",
      () async {
        await descente.appliquer(lExemple());
        expect(await NoAdsDao(db).getAll(), isNotEmpty);

        final resiliation = DroitsDistants(
          subscription: AbonnementDistant(
            actif: false,
            echeance: null,
            horodatage: HorodatageServeur.annonceParLeServeur(
              "2026-09-29T14:00:00.000Z",
            )!,
          ),
        );
        final r = await descente.appliquer(resiliation);

        expect(r.appliquee, isTrue);
        expect(
          (await NoAdsDao(
            db,
          ).getAll()).where((a) => a.source == "subscription"),
          isEmpty,
          reason: "« jamais a vie, toujours lie a un etat actif » (#99404)",
        );
      },
    );

    test("une annonce d abonnement PERIMEE ne ressuscite pas un abonnement "
        "resilie", () async {
      await descente.appliquer(lExemple());
      await descente.appliquer(
        DroitsDistants(
          subscription: AbonnementDistant(
            actif: false,
            echeance: null,
            horodatage: HorodatageServeur.annonceParLeServeur(
              "2026-09-29T14:00:00.000Z",
            )!,
          ),
        ),
      );

      // Une annonce plus VIEILLE que la resiliation arrive en retard.
      final r = await descente.appliquer(lExemple());

      expect(r.appliquee, isFalse);
      expect(
        (await NoAdsDao(db).getAll()).where((a) => a.source == "subscription"),
        isEmpty,
      );
    });
  });
}

/// LE TELEPHONE NE PEUT PAS S ECRIRE SES PROPRES DROITS (tache 631).
///
/// GARDE STRUCTURELLE SUR `firestore.rules`. C est la regle qui tient tout le
/// modele economique : si un telephone pouvait poser `owned: true` sur un
/// sentier ou se donner mille etapes, il n y aurait plus rien a vendre. La
/// regle generique `users/{userId}/{subcollection}/{docId}` donnait justement
/// `read, write` sur TOUT, droits compris — c est ce que ce lot a ferme.
///
/// UN TEST ET PAS UN COMMENTAIRE : les regles se relisent rarement, et une
/// autorisation reouverte par megarde ne se voit nulle part avant qu on la
/// paie.
void verifierLesRegles() {
  group("631 — les regles Firestore : le compte est en LECTURE SEULE", () {
    final fichier = File("firestore.rules");

    /// Le bloc de regles d un chemin : de son `match` jusqu au `match` suivant.
    ///
    /// ON NE DECOUPE PAS SUR LA PREMIERE ACCOLADE FERMANTE — le chemin lui-meme
    /// en contient une (`{docId}`), et le bloc se reduirait a son titre. Le test
    /// passait alors pour de mauvaises raisons... ou echouait, ce qu il a fait.
    String bloc(String chemin) {
      final source = fichier.readAsStringSync();
      final debut = source.indexOf("match $chemin");
      if (debut < 0) return "";
      final suivant = source.indexOf("match ", debut + 6);
      return suivant < 0
          ? source.substring(debut)
          : source.substring(debut, suivant);
    }

    for (final chemin in const [
      "/wallet/{docId}",
      "/entitlements/{trailId}",
      "/subscription/{docId}",
    ]) {
      test("$chemin : lecture par le proprietaire, ecriture par PERSONNE", () {
        expect(fichier.existsSync(), isTrue);
        final regles = bloc(chemin);
        expect(
          regles,
          isNotEmpty,
          reason:
              "le chemin $chemin n a plus de regle propre : il retombe "
              "dans la regle generique, qui autorise l ECRITURE",
        );
        expect(
          regles,
          contains("allow write: if false;"),
          reason:
              "un telephone qui ecrit ses propres droits se sert "
              "lui-meme",
        );
        expect(
          regles,
          contains("request.auth.uid == userId"),
          reason: "on ne lit que SES droits, pas ceux d un autre",
        );
      });
    }
  });
}
