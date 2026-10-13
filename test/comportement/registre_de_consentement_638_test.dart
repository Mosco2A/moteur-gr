import "dart:io";

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter_test/flutter_test.dart";
import "package:moteur_gr/core/firebase/firebase_service.dart";
import "package:moteur_gr/core/services/consent_service.dart";
import "package:moteur_gr/core/services/montee_des_consentements.dart";
import "package:shared_preferences/shared_preferences.dart";

/// LE CONSENTEMENT VIT EN BASE, HORODATE — LA DONNEE NON (tache 638).
///
/// DECISION DE CHRISTOPHE DU 30/09 12:32, verbatim : « Le consentement est dans
/// nos bases, horodate, c est les donnees qui n y sont pas ».
///
/// CE QUE CES TESTS PROUVENT :
///
///   1. CHAQUE DECISION MONTE, et elle monte HORODATEE PAR LE SERVEUR. Un
///      consentement qui ne vit que dans les preferences du telephone disparait
///      avec l application : ce n est pas un consentement recueilli, c est une
///      case cochee sur un appareil.
///
///   2. LA DONNEE PROTEGEE NE MONTE PAS AVEC. On seme une fiche de sante et une
///      morphologie reconnaissables, et on fouille tout ce qui arrive au
///      serveur : ni la cle, ni la valeur ne doivent s y trouver.
///
///   3. UNE DECISION NE SE REECRIT PAS A CHAQUE PASSE. `decided_at` est un
///      horodatage SERVEUR : le renvoyer a chaque reveil deplacerait la date du
///      consentement a chaque lancement de l application. C est le piege le
///      moins visible de ce lot, et celui qui ruinerait la preuve.
///
///   4. UNE FINALITE JAMAIS TRANCHEE N A PAS DE DOCUMENT. Ecrire
///      « granted: false » sans decision fabriquerait un refus qui n a pas eu
///      lieu.
///
///   5. LES REGLES LAISSENT PASSER, et pour le proprietaire seul.

// ===========================================================================
// UNE FAUSSE FIRESTORE — meme forme que celle de la tache 635 : il n y a pas de
// `fake_cloud_firestore` dans la pile et on n en ajoute pas un pour quatre
// methodes. Elle horodate comme le serveur : tout [FieldValue] recu devient
// l instant que le test controle, sans quoi on ne pourrait pas distinguer
// « decided_at conserve » de « decided_at repose ».
// ===========================================================================

class _BaseFausse implements FirebaseFirestore {
  final Map<String, Map<String, Object?>> documents = {};
  DateTime instant = DateTime.utc(2026, 9, 30, 12, 32);
  int ecritures = 0;

  /// Quand non nul, toute ecriture est refusee — comme une regle qui dit non.
  String? refus;

  Map<String, Object?> horodater(Map<String, Object?> donnees) => donnees.map(
    (cle, valeur) => MapEntry(cle, valeur is FieldValue ? instant : valeur),
  );

  String get toutLeContenu =>
      documents.entries.map((e) => "${e.key} => ${e.value}").join("\n");

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _CollectionFausse(this, path);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
    final refus = base.refus;
    if (refus != null) throw StateError(refus);
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

/// LES MOTS QUI NE DOIVENT JAMAIS APPARAITRE DANS LE REGISTRE — ni en cle, ni
/// en valeur. Liste large a dessein : on prefere un test qui rougit pour un
/// champ innocent a une donnee de sante qui passe.
const _clesInterdites = <String>[
  "blood_type",
  "bloodType",
  "allergies",
  "treatments",
  "doctor_contact",
  "insurance_number",
  "age",
  "height_cm",
  "weight_kg",
  "sex",
  "bmi",
  "imc",
  "name",
  "nom",
  "email",
  "phone",
  "telephone",
  "address",
  "content",
  "photo_path",
];

const _uid = "uid-authentification-de-test";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _BaseFausse serveur;
  late SharedPreferences prefs;
  late ConsentService consentement;

  setUp(() async {
    serveur = _BaseFausse();
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    consentement = ConsentService(prefs: prefs);
    await consentement.initialize();
  });

  tearDown(() => consentement.dispose());

  MonteeDesConsentements registre({FirebaseService? firebase}) =>
      MonteeDesConsentements(
        firebaseService:
            firebase ?? FirebaseService.testOnly(isAvailable: true),
        identifiant: () async => _uid,
        etats: () async => consentement.allStates(),
        preferences: prefs,
        firestore: serveur,
      );

  String cheminDe(ConsentPurpose purpose) =>
      "users/$_uid/consents/${purpose.name}";

  // =========================================================================
  // 1. CHAQUE DECISION MONTE, HORODATEE PAR LE SERVEUR
  // =========================================================================
  group("638 — chaque decision de consentement monte en base", () {
    test(
      "un accord monte avec sa date serveur, sa version et son declencheur",
      () async {
        await consentement.grant(
          ConsentPurpose.healthData,
          declencheur: ConsentTrigger.settings,
        );

        expect(await registre().monter(), 1);

        final document =
            serveur.documents[cheminDe(ConsentPurpose.healthData)]!;
        expect(document["granted"], isTrue);
        expect(document["decided_at"], DateTime.utc(2026, 9, 30, 12, 32));
        expect(document["updated_at"], DateTime.utc(2026, 9, 30, 12, 32));
        expect(
          document["version_du_texte"],
          ConsentService.currentPolicyVersion,
        );
        expect(document["declencheur"], "reglages");
      },
    );

    test(
      "un REFUS monte aussi : un refus est une decision, pas un silence",
      () async {
        await consentement.revoke(
          ConsentPurpose.socialSharing,
          declencheur: ConsentTrigger.settings,
        );

        expect(await registre().monter(), 1);
        final document =
            serveur.documents[cheminDe(ConsentPurpose.socialSharing)]!;
        expect(document["granted"], isFalse);
        expect(document["decided_at"], isNotNull);
      },
    );

    test("le document ne porte QUE les champs de la liste fermee", () async {
      await consentement.grant(ConsentPurpose.healthData);
      await registre().monter();

      final document = serveur.documents[cheminDe(ConsentPurpose.healthData)]!;
      expect(
        document.keys.toSet().difference(ConsentRegistryFields.autorises),
        isEmpty,
      );
    });

    test("l instant retenu par le telephone accompagne la date serveur", () {
      // POURQUOI CE CHAMP EXISTE : une decision prise hors reseau n arrive au
      // serveur que plus tard. Sans lui, le registre daterait le consentement du
      // jour de sa TRANSMISSION et non de sa PRISE.
      final etat = ConsentState(
        purpose: ConsentPurpose.healthData,
        granted: true,
        decidedAt: DateTime.utc(2026, 9, 25, 8, 30),
        policyVersion: 1,
        declencheur: ConsentTrigger.modificationDesDonnees,
      );
      final payload = MonteeDesConsentements.buildPayload(etat);
      expect(payload["decide_sur_le_telephone_le"], "2026-09-25T08:30:00.000Z");
      expect(payload["declencheur"], "modification_des_donnees");
    });

    test(
      "les quatre finalites tranchees montent chacune son document",
      () async {
        for (final purpose in ConsentPurpose.values) {
          await consentement.grant(purpose);
        }
        expect(await registre().monter(), ConsentPurpose.values.length);
        for (final purpose in ConsentPurpose.values) {
          expect(serveur.documents.containsKey(cheminDe(purpose)), isTrue);
        }
      },
    );
  });

  // =========================================================================
  // 2. LA DONNEE PROTEGEE NE MONTE PAS AVEC
  // =========================================================================
  group("638 — le consentement monte, la donnee reste sur le telephone", () {
    test("aucune cle de sante ni de morphologie dans le registre", () async {
      for (final purpose in ConsentPurpose.values) {
        await consentement.grant(purpose);
      }
      await registre().monter();

      expect(serveur.documents, isNotEmpty, reason: "sinon on ne prouve rien");
      for (final document in serveur.documents.entries) {
        for (final cle in document.value.keys) {
          expect(
            _clesInterdites,
            isNot(contains(cle)),
            reason:
                "« $cle » est une donnee protegee et elle est arrivee dans "
                "${document.key}",
          );
        }
      }
    });

    test("le service ne connait AUCUN chemin de donnee de sante", () {
      final source = File(
        "lib/core/services/montee_des_consentements.dart",
      ).readAsStringSync();
      for (final chemin in const [
        'collection("health',
        'collection("profile")',
        'doc("hiker")',
        "secure_backup",
      ]) {
        expect(
          source,
          isNot(contains(chemin)),
          reason:
              "le registre de consentement n a rien a faire de la donnee "
              "qu il protege",
        );
      }
    });

    test("seuls les chemins consents sont ecrits", () async {
      await consentement.grant(ConsentPurpose.healthData);
      await registre().monter();
      for (final chemin in serveur.documents.keys) {
        expect(chemin, startsWith("users/$_uid/consents/"));
      }
    });
  });

  // =========================================================================
  // 3. UNE DECISION NE SE REECRIT PAS A CHAQUE PASSE
  // =========================================================================
  group("638 — la date du consentement ne bouge pas toute seule", () {
    test("une seconde passe sans nouvelle decision n ecrit RIEN", () async {
      await consentement.grant(ConsentPurpose.healthData);
      final r = registre();
      expect(await r.monter(), 1);
      final ecrituresApresLaPremiere = serveur.ecritures;

      // Le lendemain, l application redemarre : la montee se reveille.
      serveur.instant = DateTime.utc(2026, 10, 1, 9);
      expect(await r.monter(), 0);

      expect(serveur.ecritures, ecrituresApresLaPremiere);
      expect(
        serveur.documents[cheminDe(ConsentPurpose.healthData)]!["decided_at"],
        DateTime.utc(2026, 9, 30, 12, 32),
        reason:
            "sinon la date du consentement serait celle du dernier "
            "lancement de l application, et la preuve ne vaudrait rien",
      );
    });

    test("une NOUVELLE decision repart, avec sa nouvelle date", () async {
      await consentement.grant(ConsentPurpose.healthData);
      final r = registre();
      await r.monter();

      serveur.instant = DateTime.utc(2026, 10, 1, 9);
      await consentement.revoke(ConsentPurpose.healthData);
      expect(await r.monter(), 1);

      final document = serveur.documents[cheminDe(ConsentPurpose.healthData)]!;
      expect(document["granted"], isFalse);
      expect(document["decided_at"], DateTime.utc(2026, 10, 1, 9));
    });

    test(
      "une ecriture REFUSEE ne marque rien comme monte : elle repart",
      () async {
        await consentement.grant(ConsentPurpose.healthData);
        serveur.refus = "permission-denied";
        final r = registre();
        expect(await r.monter(), 0);
        expect(serveur.documents, isEmpty);

        // La regle est deployee, ou le reseau revient.
        serveur.refus = null;
        expect(
          await r.monter(),
          1,
          reason:
              "une empreinte posee avant l ecriture ferait croire la decision "
              "enregistree, et elle ne repartirait jamais",
        );
      },
    );
  });

  // =========================================================================
  // 4. PAS DE DECISION INVENTEE, PAS D ECRITURE SANS DESTINATAIRE
  // =========================================================================
  group("638 — ce qui n a pas ete tranche ne s ecrit pas", () {
    test("aucune finalite tranchee -> aucun document", () async {
      expect(await registre().monter(), 0);
      expect(serveur.documents, isEmpty);
    });

    test("une seule finalite tranchee -> un seul document", () async {
      await consentement.grant(ConsentPurpose.locationNavigation);
      expect(await registre().monter(), 1);
      expect(serveur.documents.keys, [
        cheminDe(ConsentPurpose.locationNavigation),
      ]);
    });

    test("sans Firebase, rien n est ecrit et rien ne leve", () async {
      await consentement.grant(ConsentPurpose.healthData);
      final r = registre(firebase: FirebaseService.unavailable());
      expect(await r.monter(), 0);
      expect(serveur.documents, isEmpty);
    });

    test("sans identite, rien n est ecrit et rien ne leve", () async {
      await consentement.grant(ConsentPurpose.healthData);
      final r = MonteeDesConsentements(
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        identifiant: () async => null,
        etats: () async => consentement.allStates(),
        preferences: prefs,
        firestore: serveur,
      );
      expect(await r.monter(), 0);
      expect(serveur.documents, isEmpty);
    });

    test("une identite illisible ne fait pas lever la montee", () async {
      await consentement.grant(ConsentPurpose.healthData);
      final r = MonteeDesConsentements(
        firebaseService: FirebaseService.testOnly(isAvailable: true),
        identifiant: () async => throw StateError("Firebase non initialise"),
        etats: () async => consentement.allStates(),
        preferences: prefs,
        firestore: serveur,
      );
      expect(await r.monter(), 0);
    });
  });

  // =========================================================================
  // 4 bis. LA RE-DEMANDE APRES MODIFICATION DES DONNEES (DEM 30/09 12:33)
  // =========================================================================
  group("638 — une modification des donnees redemande le consentement", () {
    test(
      "apres un accord, rien n est redemande tant que rien ne change",
      () async {
        await consentement.grant(
          ConsentPurpose.healthData,
          declencheur: ConsentTrigger.settings,
        );
        expect(consentement.needsPrompt(ConsentPurpose.healthData), isFalse);
      },
    );

    test("LIRE l etat ne redemande rien — un affichage n est pas une "
        "modification", () async {
      await consentement.grant(ConsentPurpose.healthData);
      // Ce que fait un ecran qui affiche : il lit, plusieurs fois.
      for (var i = 0; i < 5; i++) {
        consentement.hasConsent(ConsentPurpose.healthData);
        consentement.stateOf(ConsentPurpose.healthData);
        consentement.allStates();
        expect(
          consentement.needsPrompt(ConsentPurpose.healthData),
          isFalse,
          reason:
              "« jamais au simple affichage » : un ecran qui regarde ne "
              "doit pas declencher de question",
        );
      }
    });

    test(
      "MODIFIER les donnees redemande — c est la decision du 30/09",
      () async {
        await consentement.grant(ConsentPurpose.healthData);
        expect(consentement.needsPrompt(ConsentPurpose.healthData), isFalse);

        // Le randonneur ajoute un traitement dans sa fiche.
        await consentement.noterUneModificationDesDonnees(
          ConsentPurpose.healthData,
        );

        expect(
          consentement.needsPrompt(ConsentPurpose.healthData),
          isTrue,
          reason:
              "un consentement donne il y a six mois porte sur ce qu il y "
              "avait dans la fiche il y a six mois",
        );
      },
    );

    test(
      "UNE FOIS par modification : repondre suffit, on ne boucle pas",
      () async {
        await consentement.grant(ConsentPurpose.healthData);
        await consentement.noterUneModificationDesDonnees(
          ConsentPurpose.healthData,
        );
        expect(consentement.needsPrompt(ConsentPurpose.healthData), isTrue);

        // La question est posee, le randonneur repond.
        await consentement.grant(
          ConsentPurpose.healthData,
          declencheur: ConsentTrigger.modificationDesDonnees,
        );

        expect(
          consentement.needsPrompt(ConsentPurpose.healthData),
          isFalse,
          reason:
              "la decision capture la NOUVELLE revision ; sans cela "
              "l application reposerait la question a chaque ouverture",
        );
      },
    );

    test(
      "un REFUS suivi d une modification est re-demande lui aussi",
      () async {
        await consentement.revoke(ConsentPurpose.healthData);
        expect(
          consentement.needsPrompt(ConsentPurpose.healthData),
          isFalse,
          reason: "un refus est une decision : on ne harcele pas",
        );

        await consentement.noterUneModificationDesDonnees(
          ConsentPurpose.healthData,
        );
        expect(
          consentement.needsPrompt(ConsentPurpose.healthData),
          isTrue,
          reason:
              "quelqu un a refuse, puis a quand meme rempli sa fiche : il "
              "faut lui reposer la question sur ce qu il vient d ecrire",
        );
      },
    );

    test(
      "la modification d une finalite ne redemande pas les autres",
      () async {
        for (final purpose in ConsentPurpose.values) {
          await consentement.grant(purpose);
        }
        await consentement.noterUneModificationDesDonnees(
          ConsentPurpose.healthData,
        );

        expect(consentement.needsPrompt(ConsentPurpose.healthData), isTrue);
        for (final purpose in ConsentPurpose.values) {
          if (purpose == ConsentPurpose.healthData) continue;
          expect(
            consentement.needsPrompt(purpose),
            isFalse,
            reason:
                "les finalites sont independantes (art. 9 : consentement "
                "SEPARE, jamais groupe)",
          );
        }
      },
    );

    test("la re-demande monte en base avec son declencheur", () async {
      await consentement.grant(
        ConsentPurpose.healthData,
        declencheur: ConsentTrigger.settings,
      );
      final r = registre();
      await r.monter();
      expect(
        serveur.documents[cheminDe(ConsentPurpose.healthData)]!["declencheur"],
        "reglages",
      );

      // La fiche change, on redemande, le randonneur re-accorde.
      await consentement.noterUneModificationDesDonnees(
        ConsentPurpose.healthData,
      );
      serveur.instant = DateTime.utc(2026, 10, 2, 14);
      await consentement.grant(
        ConsentPurpose.healthData,
        declencheur: ConsentTrigger.modificationDesDonnees,
      );

      expect(await r.monter(), 1, reason: "la decision a change, elle repart");
      final document = serveur.documents[cheminDe(ConsentPurpose.healthData)]!;
      expect(document["declencheur"], "modification_des_donnees");
      expect(document["decided_at"], DateTime.utc(2026, 10, 2, 14));
    });

    test(
      "une decision ANTERIEURE a ce lot n est pas re-demandee pour rien",
      () async {
        // Le telephone de Christophe porte deja des consentements, ecrits sans
        // les deux champs ajoutes par ce lot. Les relire ne doit pas produire une
        // re-demande pour une raison purement technique.
        SharedPreferences.setMockInitialValues(<String, Object>{
          'consent_healthData':
              '{"granted":true,"decidedAt":1759000000000,"policyVersion":1}',
        });
        final anciennes = await SharedPreferences.getInstance();
        final service = ConsentService(prefs: anciennes);
        await service.initialize();

        final etat = service.stateOf(ConsentPurpose.healthData);
        expect(etat.granted, isTrue);
        expect(etat.declencheur, ConsentTrigger.inconnu);
        expect(etat.revisionDesDonnees, 0);
        expect(
          service.needsPrompt(ConsentPurpose.healthData),
          isFalse,
          reason:
              "exiger les nouveaux champs aurait fait re-demander tout le "
              "monde pour une raison purement technique",
        );
        service.dispose();
      },
    );
  });

  // =========================================================================
  // 5. LES REGLES
  // =========================================================================
  group("638 — les regles Firestore du registre", () {
    final fichier = File("firestore.rules");

    test("le chemin consents a sa propre regle", () {
      expect(fichier.existsSync(), isTrue);
      expect(
        fichier.readAsStringSync(),
        contains("match /consents/{finalite}"),
        reason:
            "declaree noir sur blanc plutot que laissee a la regle "
            "generique : elle se relit et se verifie",
      );
    });

    test("elle est reservee au proprietaire", () {
      final source = fichier.readAsStringSync();
      final debut = source.indexOf("match /consents/{finalite}");
      final bloc = source.substring(debut, debut + 200);
      expect(bloc, contains("request.auth.uid == userId"));
      expect(bloc, isNot(contains("if true")));
    });
  });
}
