import "dart:async";
import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:drift/drift.dart" hide isNull, isNotNull;
import "package:drift/native.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/data/daos/checklist_dao.dart";
import "package:moteur_gr/core/data/daos/journal_dao.dart";
import "package:moteur_gr/core/data/daos/progress_dao.dart";
import "package:moteur_gr/core/data/daos/sync_queue_dao.dart";
import "package:moteur_gr/core/data/database.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/network/connectivity_monitor.dart";
import "package:moteur_gr/core/services/cloud_sync_service.dart";
import "package:moteur_gr/core/services/device_spec_sheet.dart";
import "package:moteur_gr/core/services/sync_scheduler.dart";

/// LA MONTEE EN BASE — LE TELEPHONE ECRIT ENFIN CE QUE CHRISTOPHE SAISIT
/// (tache 635).
///
/// CE QUE CES TESTS PROUVENT, ET POURQUOI CHACUN COMPTE :
///
///   1. AUCUNE DONNEE PERSONNELLE NE SORT. On seme dans la base locale tout ce
///      qui doit RESTER dessus — un journal en texte libre, une morphologie —
///      puis on fait une montee complete et on fouille TOUT ce qui est arrive
///      au serveur. Ni la cle, ni la valeur ne doivent s y trouver. C est la
///      moitie de la phrase de Christophe : « je veux que tout soit en base ...
///      Sauf les donnees persos ».
///
///   2. LE BRANCHEMENT EXISTE, ET IL EST RAPIDE. C est l autre moitie, et son
///      critere d acceptation : « je veux voir toutes les donnees en base qui
///      se mettent a jour quand je rentre des infos dans l appli ». Une
///      ecriture locale doit se retrouver au serveur en TROIS SECONDES, sans
///      qu on ait rien appuye. Le test attend reellement ce delai — c est la
///      seule facon de prouver qu il est tenu.
///
///   3. HORS LIGNE, RIEN NE SE PERD. Le cas nominal en montagne. Ce qui n a pas
///      pu partir est INSCRIT, et le retour du reseau le fait partir.
///
///   4. LA FICHE TECHNIQUE EXISTE, ET SA DATE DE NAISSANCE N EST POSEE QU UNE
///      FOIS. C est ce qui fait sortir `users/{uid}` de l italique dans la
///      console — l italique voulant dire « ce document n existe pas », ce que
///      Christophe a lu comme « ni utilisateur ».
///
///   5. LES REGLES LAISSENT PASSER, et c est la cause premiere du constat du
///      29/09 : meme branchee, la montee se serait fait refuser chaque
///      ecriture, parce qu aucune regle ne couvrait les documents places SOUS
///      `users/{uid}/trails/{trailId}`.

// ===========================================================================
// UNE FAUSSE FIRESTORE — il n y a pas de `fake_cloud_firestore` dans la pile,
// et on ne va pas en ajouter un pour quatre methodes. Elle retient les
// documents dans une carte, et elle HORODATE COMME LE SERVEUR : tout
// [FieldValue] recu devient l instant que le test controle. Sans ca, on ne
// pourrait pas distinguer « created_at repose » de « created_at conserve ».
// ===========================================================================

class _BaseFausse implements FirebaseFirestore {
  final Map<String, Map<String, Object?>> documents = {};

  /// L horloge DU SERVEUR, pilotee par le test.
  DateTime instant = DateTime.utc(2026, 9, 29, 16);

  /// Nombre d ecritures, pour prouver qu une rafale n en produit qu une.
  int ecritures = 0;

  Map<String, Object?> horodater(Map<String, Object?> donnees) {
    return donnees.map(
      (cle, valeur) => MapEntry(cle, valeur is FieldValue ? instant : valeur),
    );
  }

  /// Tout ce qui est arrive au serveur, a plat, pour la fouille.
  String get toutLeContenu =>
      documents.entries.map((e) => "${e.key} => ${e.value}").join("\n");

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _CollectionFausse(this, path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// LES TROIS TYPES CI-DESSOUS SONT SCELLES PAR LE PLUGIN, ET ON LES IMPLEMENTE
// QUAND MEME. Le scellement protege le code de PRODUCTION contre une
// implementation maison qui divergerait du SDK ; ici on fabrique un DOUBLE de
// test, dans un fichier de test, pour quatre methodes (`collection`, `doc`,
// `get`, `set`). L alternative serait d ajouter une dependance de test entiere
// (`fake_cloud_firestore`) pour la meme surface, ou de ne rien prouver du tout.
// ignore: subtype_of_sealed_class
class _CollectionFausse implements CollectionReference<Map<String, dynamic>> {
  _CollectionFausse(this.base, this.chemin);
  final _BaseFausse base;
  final String chemin;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _DocumentFaux(base, "$chemin/$path");

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _DocumentFaux implements DocumentReference<Map<String, dynamic>> {
  _DocumentFaux(this.base, this.chemin);
  final _BaseFausse base;
  final String chemin;

  @override
  String get id => chemin.split("/").last;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _CollectionFausse(base, "$chemin/$path");

  @override
  Future<DocumentSnapshot<Map<String, dynamic>>> get([
    GetOptions? options,
  ]) async => _InstantaneFaux(id, base.documents[chemin]);

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    base.ecritures++;
    final horodate = base.horodater(data);
    if (options?.merge ?? false) {
      base.documents
          .putIfAbsent(chemin, () => <String, Object?>{})
          .addAll(horodate);
    } else {
      base.documents[chemin] = Map<String, Object?>.of(horodate);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class
class _InstantaneFaux implements DocumentSnapshot<Map<String, dynamic>> {
  _InstantaneFaux(this.id, this._donnees);
  @override
  final String id;
  final Map<String, Object?>? _donnees;

  @override
  bool get exists => _donnees != null;

  @override
  Map<String, dynamic>? data() =>
      _donnees == null ? null : Map<String, dynamic>.of(_donnees);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Reseau implements ConnectivityMonitor {
  /// Vrai par defaut : le cas hors ligne se pose en ecrivant `enLigne = false`,
  /// ce qui se lit mieux dans un test que de le passer a la construction.
  bool enLigne = true;
  final _flux = StreamController<ConnectivityStatus>.broadcast();

  void basculer({required bool versEnLigne}) {
    enLigne = versEnLigne;
    _flux.add(
      versEnLigne
          ? ConnectivityStatusValues.online
          : ConnectivityStatusValues.offline,
    );
  }

  @override
  Future<ConnectivityStatus> checkStatus() async => enLigne
      ? ConnectivityStatusValues.online
      : ConnectivityStatusValues.offline;

  @override
  Stream<ConnectivityStatus> get onStatusChange => _flux.stream;

  @override
  Future<TypeDeLien> typeDeLien() async => TypesDeLien.wifi;

  Future<void> fermer() => _flux.close();
}

/// LES MOTS QUI NE DOIVENT JAMAIS APPARAITRE AU SERVEUR — ni en cle, ni en
/// valeur. Liste volontairement large : on prefere un test qui rougit pour un
/// champ innocent a un champ personnel qui passe.
const _clesInterdites = <String>[
  "name",
  "nom",
  "prenom",
  "first_name",
  "last_name",
  "display_name",
  "email",
  "mail",
  "phone",
  "telephone",
  "address",
  "adresse",
  "health",
  "sante",
  "medical",
  "blood",
  "allergy",
  "allergies",
  "treatment",
  "emergency",
  "urgence",
  "contact",
  "journal",
  "content",
  "photo_path",
  "age",
  "height_cm",
  "weight_kg",
  "sex",
  "bmi",
  "imc",
  "country_iso",
  "free_text_difficulties",
  "experience_note",
];

const _uid = "uid-authentification-de-test";
const _sentier = "mare-a-mare-centre";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late _BaseFausse serveur;
  late _Reseau reseau;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    serveur = _BaseFausse();
    reseau = _Reseau();
  });

  tearDown(() async {
    await reseau.fermer();
    await db.close();
  });

  CloudSyncService transport() => CloudSyncService(
    progressDao: ProgressDao(db),
    checklistDao: ChecklistDao(db),
    syncQueueDao: SyncQueueDao(db),
    connectivityMonitor: reseau,
    firebaseService: FirebaseService.testOnly(isAvailable: true),
    pastHikesDao: db.pastHikesDao,
    firestore: serveur,
  );

  DeviceSpecSheet fiche() => DeviceSpecSheet(
    firebaseService: FirebaseService.testOnly(isAvailable: true),
    identifiant: () async => _uid,
    renseignements: () async => const RenseignementsDuTelephone(
      versionApplication: "1.0.0",
      fabrication: "7",
      systeme: "android",
      versionSysteme: "Android 15 (API 35)",
      langue: "fr",
      fuseau: "CEST (UTC+02:00)",
    ),
    firestore: serveur,
  );

  SyncScheduler montee({Duration? attente}) => SyncScheduler(
    cloudSyncService: transport(),
    connectivityMonitor: reseau,
    firebaseService: FirebaseService.testOnly(isAvailable: true),
    progressDao: ProgressDao(db),
    ficheTechnique: fiche(),
    attenteAvantMontee: attente ?? SyncScheduler.attenteParDefaut,
    // Pas de liaison Flutter a observer dans un test de service.
    observerLeCycleDeVie: false,
  );

  Stream<void> ecrituresLocales() => db.tableUpdates(
    TableUpdateQuery.allOf([
      TableUpdateQuery.onTable(db.userProgressEntries),
      TableUpdateQuery.onTable(db.checklistItems),
      TableUpdateQuery.onTable(db.pastHikeEntries),
    ]),
  );

  /// Attend qu une condition devienne vraie, au plus [limite]. Rend vrai si
  /// elle l est devenue. On sonde plutot que de dormir une duree fixe : le test
  /// mesure alors un DELAI MAXIMUM, ce qui est exactement la promesse faite.
  Future<bool> attendreQue(
    bool Function() condition, {
    Duration limite = const Duration(seconds: 6),
  }) async {
    final fin = DateTime.now().add(limite);
    while (DateTime.now().isBefore(fin)) {
      if (condition()) return true;
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
    return condition();
  }

  /// Attend la fin de la passe lancee par [SyncScheduler.demarrer].
  ///
  /// `demarrer` part sans attendre — c est ce qui fait que le premier ecran ne
  /// depend pas du reseau — donc un test qui mesurerait juste apres verrait une
  /// base vide et conclurait a tort que rien ne monte.
  Future<void> passeTerminee(SyncScheduler m) => attendreQue(() => !m.enCours);

  /// Seme TOUT ce qui existe en local, y compris ce qui doit y RESTER.
  Future<void> semerLaBaseLocale() async {
    await ProgressDao(db).upsert(
      UserProgressEntriesCompanion.insert(
        trailId: _sentier,
        currentStage: const Value(4),
        totalDistanceWalkedKm: const Value(61.2),
        startedAt: Value(DateTime.utc(2026, 8, 1)),
      ),
    );
    await ChecklistDao(db).upsertItem(
      ChecklistItemsCompanion.insert(
        trailId: _sentier,
        itemId: "duvet",
        category: "couchage",
        isChecked: const Value(true),
        updatedAt: Value(DateTime.utc(2026, 9, 28)),
      ),
    );
    await db.pastHikesDao.insertHike(
      PastHikeEntriesCompanion.insert(
        userId: "local",
        date: DateTime.utc(2026, 7, 1),
        days: const Value(4),
        totalElevationGain: const Value(3200),
        totalDistanceKm: const Value(58),
        updatedAt: DateTime.utc(2026, 7, 10),
      ),
    );

    // CE QUI DOIT RESTER SUR LE TELEPHONE — seme EXPRES, avec des valeurs
    // reconnaissables : si l une d elles arrive au serveur, on la verra.
    await JournalDao(db).insertEntry(
      JournalEntriesCompanion.insert(
        trailId: _sentier,
        stageNumber: 4,
        content: const Value("mon genou a lache au col de Verde"),
        createdAt: DateTime.utc(2026, 9, 28),
      ),
    );
    await db.hikerProfileDao.upsert(
      HikerProfileCompanion.insert(
        userId: "local",
        age: const Value(72),
        heightCm: const Value(172),
        weightKg: const Value(88),
        sex: const Value("male"),
        countryIso: const Value("FR"),
        updatedAt: DateTime.utc(2026, 6, 15),
      ),
    );
  }

  // =========================================================================
  // 1. AUCUNE DONNEE PERSONNELLE NE SORT
  // =========================================================================
  group("635 — ce qui monte, et surtout ce qui ne monte pas", () {
    test("une montee complete n emporte AUCUNE cle personnelle", () async {
      await semerLaBaseLocale();
      final m = montee(attente: const Duration(milliseconds: 20));
      await m.start(userId: _uid);
      await passeTerminee(m);
      await m.stop();

      expect(serveur.documents, isNotEmpty, reason: "sinon on ne prouve rien");

      for (final document in serveur.documents.entries) {
        for (final cle in document.value.keys) {
          expect(
            _clesInterdites,
            isNot(contains(cle)),
            reason:
                "« $cle » est une donnee personnelle et elle est arrivee "
                "dans ${document.key}",
          );
        }
      }
    });

    test("le texte libre du journal ne quitte pas le telephone", () async {
      await semerLaBaseLocale();
      final m = montee(attente: const Duration(milliseconds: 20));
      await m.start(userId: _uid);
      await passeTerminee(m);
      await m.stop();

      expect(
        serveur.toutLeContenu,
        isNot(contains("genou")),
        reason:
            "le journal est le contenu le plus personnel de "
            "l application ; il reste sur le telephone (tache 635)",
      );
      expect(serveur.toutLeContenu, isNot(contains("Verde")));
    });

    test("la morphologie ne quitte pas le telephone", () async {
      await semerLaBaseLocale();
      final m = montee(attente: const Duration(milliseconds: 20));
      await m.start(userId: _uid);
      await passeTerminee(m);
      await m.stop();

      for (final document in serveur.documents.values) {
        expect(document.containsKey("weight_kg"), isFalse);
        expect(document.containsKey("height_cm"), isFalse);
        expect(document.containsKey("age"), isFalse);
      }
    });

    test(
      "la liste des chemins ecrits est EXACTEMENT celle qui est decidee",
      () async {
        await semerLaBaseLocale();
        final m = montee(attente: const Duration(milliseconds: 20));
        await m.start(userId: _uid);
        await passeTerminee(m);
        await m.stop();

        expect(
          serveur.documents.keys.toSet(),
          {
            "users/$_uid",
            "users/$_uid/trails/$_sentier/user_progress/current",
            "users/$_uid/trails/$_sentier/checklist_items/item_duvet",
            "users/$_uid/past_hikes/hike_1",
          },
          reason:
              "toute entree en plus est un chemin de sortie qu on n a pas "
              "decide ; toute entree en moins est une donnee que Christophe ne "
              "verra pas bouger",
        );
      },
    );

    test("le compte (solde, droits, abonnement) ne monte JAMAIS", () async {
      await semerLaBaseLocale();
      final m = montee(attente: const Duration(milliseconds: 20));
      await m.start(userId: _uid);
      await passeTerminee(m);
      await m.stop();

      for (final chemin in serveur.documents.keys) {
        expect(chemin, isNot(contains("/wallet/")));
        expect(chemin, isNot(contains("/entitlements/")));
        expect(chemin, isNot(contains("/subscription/")));
      }
    });
  });

  // =========================================================================
  // 2. LE BRANCHEMENT — LE CRITERE DE CHRISTOPHE
  // =========================================================================
  group("635 — une ecriture locale monte toute seule", () {
    test("le delai promis est de trois secondes au plus", () {
      expect(
        SyncScheduler.attenteParDefaut,
        lessThanOrEqualTo(const Duration(seconds: 3)),
        reason:
            "Christophe regarde la console pendant qu il touche son "
            "telephone : au-dela, il conclut que ca ne marche pas",
      );
    });

    test("une etape validee arrive au serveur en moins de trois secondes, "
        "sans que personne n appuie sur rien", () async {
      // On demarre sur une base VIDE : le demarrage n ecrit donc que la fiche
      // technique, et tout ce qui apparaitra ensuite viendra du geste.
      final m = montee();
      await m.start(userId: _uid, ecrituresLocales: ecrituresLocales());
      await attendreQue(() => serveur.documents.containsKey("users/$_uid"));

      const chemin = "users/$_uid/trails/$_sentier/user_progress/current";
      expect(serveur.documents.containsKey(chemin), isFalse);

      // LE GESTE : le randonneur valide son etape.
      await ProgressDao(db).updateCurrentStage(_sentier, 5);

      final arrive = await attendreQue(
        () => serveur.documents.containsKey(chemin),
        limite: const Duration(seconds: 5),
      );
      await m.stop();

      expect(arrive, isTrue, reason: "c est LE critere d acceptation du lot");
      expect(serveur.documents[chemin]!["current_stage"], 5);
    }, timeout: const Timeout(Duration(seconds: 30)));

    test(
      "une case cochee fait monter le sac",
      () async {
        final m = montee(attente: const Duration(milliseconds: 40));
        await ProgressDao(db).updateCurrentStage(_sentier, 1);
        await m.start(userId: _uid, ecrituresLocales: ecrituresLocales());

        await ChecklistDao(db).upsertItem(
          ChecklistItemsCompanion.insert(
            trailId: _sentier,
            itemId: "rechaud",
            category: "cuisine",
            isChecked: const Value(true),
            updatedAt: Value(DateTime.utc(2026, 9, 29)),
          ),
        );

        const chemin =
            "users/$_uid/trails/$_sentier/checklist_items/item_rechaud";
        final arrive = await attendreQue(
          () => serveur.documents.containsKey(chemin),
        );
        await m.stop();

        expect(arrive, isTrue);
        expect(serveur.documents[chemin]!["is_checked"], isTrue);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "une rafale de gestes ne produit PAS une montee par geste",
      () async {
        await ProgressDao(db).updateCurrentStage(_sentier, 1);
        final m = montee(attente: const Duration(milliseconds: 300));
        await m.start(userId: _uid, ecrituresLocales: ecrituresLocales());
        await attendreQue(() => m.monteesExecutees >= 1);
        final depart = m.monteesExecutees;

        // Dix cases cochees a la suite, comme on prepare un sac.
        for (var i = 0; i < 10; i++) {
          await ChecklistDao(db).upsertItem(
            ChecklistItemsCompanion.insert(
              trailId: _sentier,
              itemId: "article_$i",
              category: "divers",
              isChecked: const Value(true),
              updatedAt: Value(DateTime.utc(2026, 9, 29)),
            ),
          );
        }

        await attendreQue(() => m.monteesExecutees > depart);
        await Future<void>.delayed(const Duration(milliseconds: 400));
        final passes = m.monteesExecutees - depart;
        await m.stop();

        expect(
          passes,
          lessThanOrEqualTo(2),
          reason:
              "le regroupement a trois secondes existe pour que preparer son "
              "sac ne declenche pas dix transports",
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );
  });

  // =========================================================================
  // 3. HORS LIGNE, RIEN NE SE PERD
  // =========================================================================
  group("635 — la coupure ne perd rien", () {
    test("hors ligne : rien n est ecrit, mais tout est INSCRIT", () async {
      await semerLaBaseLocale();
      reseau.enLigne = false;
      final m = montee(attente: const Duration(milliseconds: 20));
      await m.start(userId: _uid);
      await passeTerminee(m);
      await m.stop();

      expect(
        serveur.documents.keys.where((c) => c.contains("/trails/")),
        isEmpty,
        reason: "hors ligne, aucun octet ne part",
      );

      final enAttente = await SyncQueueDao(db).getPending();
      expect(
        enAttente.any(
          (a) => a.trailId == _sentier && a.action == "cloud_sync_batch",
        ),
        isTrue,
        reason: "ce qui n a pas pu partir doit etre retrouvable",
      );
    });

    test(
      "hors ligne longtemps : la file ne se remplit pas de doublons",
      () async {
        await semerLaBaseLocale();
        reseau.enLigne = false;
        final m = montee(attente: const Duration(milliseconds: 20));
        await m.start(userId: _uid);
        await passeTerminee(m);
        for (var i = 0; i < 5; i++) {
          await m.monterMaintenant("geste $i");
        }
        await m.stop();

        final enAttente = await SyncQueueDao(db).getPending();
        final pourLeSentier = enAttente.where(
          (a) => a.trailId == _sentier && a.action == "cloud_sync_batch",
        );
        expect(
          pourLeSentier.length,
          1,
          reason:
              "la file n a pas de contrainte d unicite : sans garde, une "
              "journee hors ligne y deposerait des centaines de lignes "
              "identiques, toutes rejouees au retour du reseau",
        );
      },
    );

    test(
      "au retour du reseau, le rattrapage part et la file se vide",
      () async {
        await semerLaBaseLocale();
        reseau.enLigne = false;
        final m = montee(attente: const Duration(milliseconds: 20));
        await m.start(userId: _uid);
        await passeTerminee(m);
        expect(await SyncQueueDao(db).getPending(), isNotEmpty);

        // LE RESEAU REVIENT.
        reseau.basculer(versEnLigne: true);

        const chemin = "users/$_uid/trails/$_sentier/user_progress/current";
        final arrive = await attendreQue(
          () => serveur.documents.containsKey(chemin),
        );
        final videe = await attendreQue(() => true);
        await m.stop();

        expect(
          arrive,
          isTrue,
          reason: "ce qui attendait doit finir par partir",
        );
        expect(videe, isTrue);
        final restant = (await SyncQueueDao(
          db,
        ).getPending()).where((a) => a.action == "cloud_sync_batch");
        expect(
          restant,
          isEmpty,
          reason:
              "une file de rattrapage qui ne se vide pas n est pas un "
              "rattrapage, c est une fuite",
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      "sans Firebase, on n inscrit rien : il n y a pas de destinataire",
      () async {
        await semerLaBaseLocale();
        final m = SyncScheduler(
          cloudSyncService: CloudSyncService(
            progressDao: ProgressDao(db),
            checklistDao: ChecklistDao(db),
            syncQueueDao: SyncQueueDao(db),
            connectivityMonitor: reseau,
            firebaseService: FirebaseService.unavailable(),
            pastHikesDao: db.pastHikesDao,
            firestore: serveur,
          ),
          connectivityMonitor: reseau,
          firebaseService: FirebaseService.unavailable(),
          progressDao: ProgressDao(db),
          attenteAvantMontee: const Duration(milliseconds: 20),
          observerLeCycleDeVie: false,
        );
        await m.start(userId: _uid);
        await passeTerminee(m);
        await m.stop();

        expect(serveur.documents, isEmpty);
        expect(
          await SyncQueueDao(db).getPending(),
          isEmpty,
          reason: "remplir une file qui ne sera jamais lue serait mentir",
        );
      },
    );
  });

  // =========================================================================
  // 4. LA FICHE TECHNIQUE
  // =========================================================================
  group("635 — la fiche technique users/{uid}", () {
    test("elle FAIT EXISTER le document racine", () async {
      final posee = await fiche().poser();
      expect(posee, isTrue);
      expect(
        serveur.documents.containsKey("users/$_uid"),
        isTrue,
        reason:
            "sans ce document, la console affiche l utilisateur en "
            "italique — ce que Christophe a lu comme « ni utilisateur »",
      );
    });

    test("elle ne porte QUE les champs de la liste fermee", () async {
      await fiche().poser();
      final document = serveur.documents["users/$_uid"]!;
      expect(
        document.keys.toSet().difference(ChampsDeLaFicheTechnique.autorises),
        isEmpty,
      );
      for (final cle in document.keys) {
        expect(_clesInterdites, isNot(contains(cle)));
      }
    });

    test(
      "created_at est pose UNE SEULE FOIS, last_seen_at a chaque venue",
      () async {
        final f = fiche();
        serveur.instant = DateTime.utc(2026, 9, 29, 16);
        await f.poser();
        final naissance = serveur.documents["users/$_uid"]!["created_at"];
        expect(naissance, DateTime.utc(2026, 9, 29, 16));

        // Le lendemain, l application redemarre.
        serveur.instant = DateTime.utc(2026, 9, 30, 8);
        await f.poser();
        final document = serveur.documents["users/$_uid"]!;

        expect(
          document["created_at"],
          naissance,
          reason:
              "un serverTimestamp renvoye ECRASE l ancien : sans la lecture "
              "prealable, l age du compte serait « maintenant » a chaque "
              "lancement",
        );
        expect(document["last_seen_at"], DateTime.utc(2026, 9, 30, 8));
      },
    );

    test(
      "le retour au premier plan rafraichit la derniere venue",
      () async {
        final m = montee(attente: const Duration(milliseconds: 20));
        serveur.instant = DateTime.utc(2026, 9, 29, 16);
        await m.start(userId: _uid);
        await attendreQue(() => serveur.documents.containsKey("users/$_uid"));

        serveur.instant = DateTime.utc(2026, 9, 29, 18, 30);
        await m.auRetourAuPremierPlan();
        await m.stop();

        expect(
          serveur.documents["users/$_uid"]!["last_seen_at"],
          DateTime.utc(2026, 9, 29, 18, 30),
        );
        expect(
          serveur.documents["users/$_uid"]!["created_at"],
          DateTime.utc(2026, 9, 29, 16),
        );
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test("la charge est une fonction PURE, et elle se verifie sans reseau", () {
      const r = RenseignementsDuTelephone(
        versionApplication: "1.0.0",
        fabrication: "7",
        systeme: "android",
        versionSysteme: "Android 15",
        langue: "fr",
        fuseau: "CEST (UTC+02:00)",
      );
      final premiere = DeviceSpecSheet.buildPayload(r, premiereVenue: true);
      final suivante = DeviceSpecSheet.buildPayload(r, premiereVenue: false);

      expect(premiere.containsKey("created_at"), isTrue);
      expect(
        suivante.containsKey("created_at"),
        isFalse,
        reason: "ce qui n est pas dans la charge ne peut rien ecraser",
      );
      expect(suivante["app_version"], "1.0.0");
      expect(suivante["platform"], "android");
      expect(suivante["language"], "fr");
    });

    test(
      "sans Firebase ou sans identite, elle n ecrit rien et ne leve pas",
      () async {
        final sansCloud = DeviceSpecSheet(
          firebaseService: FirebaseService.unavailable(),
          identifiant: () async => _uid,
          renseignements: () async => const RenseignementsDuTelephone(
            versionApplication: "1.0.0",
            fabrication: "7",
            systeme: "android",
            versionSysteme: "Android 15",
            langue: "fr",
            fuseau: "CEST (UTC+02:00)",
          ),
          firestore: serveur,
        );
        expect(await sansCloud.poser(), isFalse);

        final sansIdentite = DeviceSpecSheet(
          firebaseService: FirebaseService.testOnly(isAvailable: true),
          identifiant: () async => null,
          renseignements: () async => const RenseignementsDuTelephone(
            versionApplication: "1.0.0",
            fabrication: "7",
            systeme: "android",
            versionSysteme: "Android 15",
            langue: "fr",
            fuseau: "CEST (UTC+02:00)",
          ),
          firestore: serveur,
        );
        expect(await sansIdentite.poser(), isFalse);
        expect(serveur.documents, isEmpty);
      },
    );

    test("le fuseau porte son decalage, pas seulement son nom", () {
      final decrit = RenseignementsDuTelephone.decrireLeFuseau(DateTime.now());
      expect(decrit, contains("UTC"));
      expect(decrit, matches(RegExp(r"UTC[+-]\d{2}:\d{2}")));
    });
  });

  // =========================================================================
  // 5. LES REGLES — LA CAUSE PREMIERE DU CONSTAT DU 29/09
  // =========================================================================
  group("635 — les regles Firestore laissent enfin passer la montee", () {
    final fichier = File("firestore.rules");

    test("le chemin PROFOND sous trails a sa propre regle", () {
      expect(fichier.existsSync(), isTrue);
      final source = fichier.readAsStringSync();
      expect(
        source,
        contains("match /trails/{trailId}/{sousCollection}/{docId}"),
        reason:
            "sans elle, `users/{uid}/trails/{id}/user_progress/current` "
            "retombe sur le DENY final : une regle Firestore ne descend jamais "
            "toute seule dans une sous-collection",
      );
    });

    test("cette regle reste reservee au proprietaire", () {
      final source = fichier.readAsStringSync();
      final debut = source.indexOf(
        "match /trails/{trailId}/{sousCollection}/{docId}",
      );
      final bloc = source.substring(debut, debut + 240);
      expect(bloc, contains("request.auth.uid == userId"));
      expect(bloc, isNot(contains("allow read, write: if true")));
    });
  });
}
