// TACHE 623 — LE PROFIL DU RANDONNEUR MONTAIT DANS iCLOUD ALORS QUE CHRISTOPHE
// AVAIT INCLUS LE POIDS ET LA TAILLE DANS CE QUI NE SORT PAS DU TELEPHONE.
//
// ---------------------------------------------------------------------------
// LE DEFAUT ETAIT DEJA CHIFFRE DANS LE DEPOT, PAR LE LOT QUI L'AVAIT LAISSE
// ---------------------------------------------------------------------------
//
// `SauvegardeSysteme.trouUserDefaultsIos`, ecrit par la tache 617 : « sur iPhone,
// NSUserDefaults (SharedPreferences) ne peut PAS etre exclu de la sauvegarde
// iCloud : ce n'est pas un fichier de l'application mais un domaine de
// preferences du systeme. Le profil randonneur (age, taille, poids, randonnees
// passees, test de marche) [...] monte donc dans iCloud sur iPhone. [...] A
// FERMER en sortant ces cles vers un fichier, comme la tache 613 l'a fait pour
// la fiche medicale. »
//
// Et la regle de Christophe du 27/09, en majuscules, avec le poids et la taille
// nommes explicitement : « Les donnees medicales RESTENT sur le tel ».
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER PROUVE, ET DANS QUEL ORDRE D'IMPORTANCE
// ---------------------------------------------------------------------------
//
//  1. QUE LA MIGRATION NE PERD RIEN. C'est la condition de la consigne, et c'est
//     le seul endroit ou une erreur coute quelque chose au randonneur : il a
//     saisi son age, sa taille, son poids, ses cinq dernieres randonnees et son
//     test de marche. Un deplacement de stockage qui en perd une partie est pire
//     que le defaut qu'il corrige.
//
//  2. QUE L'EXCLUSION SURVIT A L'ECRITURE ATOMIQUE. C'est le piege que la tache
//     615 a trouve dans la 613, et il s'applique mot pour mot : l'attribut
//     appartient AU FICHIER, le renommage met en place un `.tmp` qui ne l'a
//     jamais porte. Une pose unique a la creation passe tous les tests de
//     comportement et ne se voit que dans une sauvegarde iCloud.
//
//  3. QUE LA GARDE DES LOTS 612/613/615 EST REUTILISEE, PAS REINVENTEE. Le meme
//     `ExclusionSauvegardeIcloud`, le meme dossier `medical/`, donc les memes deux
//     verrous Android (inclusion unique du lot 617 + exclusion explicite) sans
//     aucune declaration de plus a tenir a jour.
//
//  4. QUE PLUS AUCUN CODE DE PRODUCTION N'ECRIT LES CLES HERITEES. Sans cette
//     invariante, un ecran ajoute demain remettrait le poids dans les preferences
//     et personne ne le verrait.
//
//  5. QUE RIEN NE PASSE SUR LE CANAL HORS IPHONE. Meme garde que la tache 615,
//     et elle protege les 3539 tests verts du depot.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/presentation/hiker_profile_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';
import 'package:moteur_gr/core/services/exclusion_sauvegarde_icloud.dart';
import 'package:moteur_gr/core/services/sauvegarde_systeme.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/data/profil_randonneur_fichier.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/domain/past_hike.dart';
import 'package:moteur_gr/features/feasibility/domain/walk_test_result.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';

/// UN APPEL VU PAR LE NATIF, AVEC L'ETAT DU DISQUE A CET INSTANT.
///
/// MEME ESPION QUE LA TACHE 615, ET POUR LA MEME RAISON : c'est la lecture du
/// contenu AU MOMENT DE L'APPEL qui permet de prouver un ORDRE, et pas seulement
/// qu'un appel a eu lieu. Sans elle, une exclusion posee AVANT le renommage
/// passerait pour une exclusion posee APRES.
class _Appel {
  _Appel({
    required this.methode,
    required this.chemin,
    required this.contenuAuMomentDeLAppel,
  });

  final String methode;
  final String chemin;
  final String? contenuAuMomentDeLAppel;

  @override
  String toString() => '$methode($chemin)';
}

class _NatifEspion {
  final List<_Appel> appels = [];

  void brancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          (appel) async {
            final chemin =
                (appel.arguments
                        as Map)[ExclusionSauvegardeIcloud.argumentChemin]
                    as String;
            String? contenu;
            try {
              final fichier = File(chemin);
              if (fichier.existsSync()) contenu = fichier.readAsStringSync();
            } on FileSystemException {
              contenu = null;
            }
            appels.add(
              _Appel(
                methode: appel.method,
                chemin: chemin.replaceAll(r'\', '/'),
                contenuAuMomentDeLAppel: contenu,
              ),
            );
            return true;
          },
        );
  }

  void debrancher() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel(ExclusionSauvegardeIcloud.nomDuCanal),
          null,
        );
  }

  void oublier() => appels.clear();

  List<_Appel> exclusionsDe(String chemin) => appels
      .where(
        (a) =>
            a.methode == ExclusionSauvegardeIcloud.methodeExclure &&
            a.chemin == chemin.replaceAll(r'\', '/'),
      )
      .toList();
}

String _n(String chemin) => chemin.replaceAll(r'\', '/');

/// Le code de `lib/`, commentaires retires — lecon du lot 612 : une garde qui
/// force a effacer l'histoire pour rester verte est une mauvaise garde, et ce lot
/// DOIT nommer les cles heritees dans ses commentaires.
String _codeSeul(String source) {
  final sansBlocs = source.replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '');
  return sansBlocs
      .split('\n')
      .where(
        (l) =>
            !l.trimLeft().startsWith('//') && !l.trimLeft().startsWith('///'),
      )
      .join('\n');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = await SharedPreferences.getInstance();
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => db.close());

  HikerProfileRepository depot({ProfilRandonneurFichier? fichier}) =>
      HikerProfileRepository(db: db, prefs: prefs, fichier: fichier);

  const gerard = HikerProfile(
    age: 72,
    heightCm: 172,
    weightKg: 88,
    sex: HikerSex.male,
    countryIso: 'FR',
  );

  // =========================================================================
  // 1. L'ENDROIT : LE MEME DOSSIER PROTEGE QUE LA FICHE MEDICALE
  // =========================================================================
  group('623 — le profil vit dans le MEME stockage protege que la fiche '
      'medicale', () {
    test(
      'le document est dans le dossier declare exclu, a cote de la fiche',
      () async {
        final profil = await ProfilRandonneurFichier().fichier();
        final fiche = await FicheMedicaleFichier().fichier();

        expect(
          _n(profil.parent.path),
          _n(fiche.parent.path),
          reason:
              'le MEME dossier, donc les MEMES deux verrous Android sans '
              'aucune declaration de plus a tenir a jour',
        );
        expect(
          _n(profil.path),
          endsWith(
            '/${SauvegardeSysteme.dossierExclu}/'
            '${ProfilRandonneurFichier.nomFichier}',
          ),
        );
      },
    );

    test('LE DEFAUT FERME : enregistrer un profil n ecrit PLUS AUCUNE cle de '
        'preferences', () async {
      await depot().saveProfile(gerard);
      await depot().savePastHikes([
        PastHike(date: DateTime.utc(2026, 5, 1), days: 3, totalDistanceKm: 42),
      ]);
      await depot().saveWalkTestResult(
        WalkTestResult(
          distanceMeters: 480,
          level: 'moyen',
          takenAt: DateTime.utc(2026, 5, 2),
        ),
      );

      expect(
        prefs.getString(kHikerProfilePrefsKey),
        isNull,
        reason:
            'c est TOUT le lot : sur iPhone cette cle ne peut pas etre '
            'exclue de la sauvegarde iCloud',
      );
      expect(prefs.getString(kHikerPastHikesPrefsKey), isNull);
      expect(prefs.getString(kWalkTestResultPrefsKey), isNull);
    });

    test('le document porte vraiment l age, la taille et le poids', () async {
      await depot().saveProfile(gerard);

      final f = await ProfilRandonneurFichier().fichier();
      final doc = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
      final p = doc[ProfilRandonneurFichier.clefProfil] as Map<String, dynamic>;
      expect(p['age'], 72);
      expect(p['heightCm'], 172);
      expect(p['weightKg'], 88);
    });

    test('ecrire puis relire avec une AUTRE instance rend la meme chose (la '
        'source est bien le disque, pas la memoire)', () async {
      await depot().saveProfile(gerard);
      final relu = await depot().getProfile();
      expect(relu.age, 72);
      expect(relu.heightCm, 172);
      expect(relu.weightKg, 88);
      expect(relu.countryIso, 'FR');
    });
  });

  // =========================================================================
  // 2. LA MIGRATION NE PERD RIEN — LE GROUPE QUI DONNE SON NOM AU LOT
  // =========================================================================
  group('623 — LA MIGRATION NE PERD RIEN, et elle vide les preferences', () {
    /// Un telephone tel qu'il se presente apres une mise a jour : les quatre
    /// cles heritees remplies, aucun fichier.
    Future<void> semerUnTelephoneExistant() async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kHikerProfilePrefsKey: json.encode(gerard.toJson()),
        kHikerPastHikesPrefsKey: json.encode([
          PastHike(
            date: DateTime.utc(2026, 5, 1),
            days: 3,
            totalDistanceKm: 42,
          ).toJson(),
          PastHike(
            date: DateTime.utc(2026, 7, 9),
            days: 1,
            totalDistanceKm: 18,
          ).toJson(),
        ]),
        kWalkTestResultPrefsKey: json.encode(
          WalkTestResult(
            distanceMeters: 480,
            level: 'moyen',
            takenAt: DateTime.utc(2026, 5, 2),
          ).toJson(),
        ),
        kHikerExperienceNotePrefsKey: 'genoux douloureux en descente',
      });
      prefs = await SharedPreferences.getInstance();
    }

    test(
      'LES QUATRE FAMILLES ARRIVENT ENTIERES, ET LES QUATRE CLES PARTENT',
      () async {
        await semerUnTelephoneExistant();

        final repo = depot();
        await repo.migrerDepuisPreferences();

        // Rien n a ete perdu.
        final profil = await repo.getProfile();
        expect(profil.age, 72);
        expect(profil.heightCm, 172);
        expect(profil.weightKg, 88);
        expect(profil.sex, HikerSex.male);
        expect(profil.countryIso, 'FR');

        final randos = await repo.loadPastHikes();
        expect(randos, hasLength(2));
        expect(
          randos.first.date,
          DateTime.utc(2026, 7, 9),
          reason: 'la plus recente d abord, comme avant la migration',
        );

        final test6 = await repo.getWalkTestResult();
        expect(test6, isNotNull);
        expect(test6!.distanceMeters, 480);
        expect(test6.level, 'moyen');

        final f = await ProfilRandonneurFichier().fichier();
        final doc = json.decode(f.readAsStringSync()) as Map<String, dynamic>;
        expect(
          doc[ProfilRandonneurFichier.clefNoteExperience],
          'genoux douloureux en descente',
          reason:
              'la note heritee n est plus ecrite par personne, mais des '
              'telephones la portent : la migration la TRANSPORTE au lieu de la '
              'jeter — « la migration ne perd rien »',
        );

        // Et le defaut est ferme : plus rien dans les preferences.
        expect(prefs.getString(kHikerProfilePrefsKey), isNull);
        expect(prefs.getString(kHikerPastHikesPrefsKey), isNull);
        expect(prefs.getString(kWalkTestResultPrefsKey), isNull);
        expect(prefs.getString(kHikerExperienceNotePrefsKey), isNull);
      },
    );

    test('elle est IDEMPOTENTE : la rejouer trois fois ne perd rien et ne '
        'reecrit rien', () async {
      await semerUnTelephoneExistant();
      final repo = depot();

      await repo.migrerDepuisPreferences();
      final f = await ProfilRandonneurFichier().fichier();
      final apresUne = f.readAsStringSync();

      await depot().migrerDepuisPreferences();
      await depot().migrerDepuisPreferences();

      expect(f.readAsStringSync(), apresUne);
      expect((await depot().getProfile()).weightKg, 88);
      expect(await depot().loadPastHikes(), hasLength(2));
    });

    test('LA PREMIERE LECTURE SUFFIT : un randonneur qui ne passe pas par '
        'l amorce est migre quand meme', () async {
      await semerUnTelephoneExistant();

      // Aucun appel explicite a la migration : on LIT, simplement.
      final profil = await depot().getProfile();

      expect(profil.weightKg, 88);
      expect(
        prefs.getString(kHikerProfilePrefsKey),
        isNull,
        reason:
            'la migration passe devant la premiere lecture de chaque '
            'instance — sinon le poids reste dans iCloud jusqu au prochain '
            'demarrage',
      );
    });

    test('LE FICHIER GAGNE, SECTION PAR SECTION — le cas d une migration '
        'interrompue', () async {
      // Le fichier porte deja un profil CORRIGE ; les preferences portent encore
      // l ancien profil ET des randonnees que la migration precedente n a pas eu
      // le temps de transporter.
      await depot().saveProfile(
        const HikerProfile(age: 40, heightCm: 175, weightKg: 70),
      );
      await prefs.setString(
        kHikerProfilePrefsKey,
        json.encode(gerard.toJson()),
      );
      await prefs.setString(
        kHikerPastHikesPrefsKey,
        json.encode([
          PastHike(
            date: DateTime.utc(2026, 5, 1),
            days: 3,
            totalDistanceKm: 42,
          ).toJson(),
        ]),
      );

      final repo = depot();
      await repo.migrerDepuisPreferences();

      final profil = await repo.getProfile();
      expect(
        profil.age,
        40,
        reason:
            'le fichier est la source depuis ce lot : la cle heritee n est '
            'plus ecrite, donc elle est forcement plus ancienne',
      );
      expect(
        await repo.loadPastHikes(),
        hasLength(1),
        reason:
            'la section que le fichier n avait PAS est transportee — c est '
            'pour cela que la fusion est faite section par section',
      );
      expect(prefs.getString(kHikerProfilePrefsKey), isNull);
      expect(prefs.getString(kHikerPastHikesPrefsKey), isNull);
    });

    test('une valeur heritee ILLISIBLE ne detruit pas les autres, et ne reste '
        'pas dans iCloud', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        kHikerProfilePrefsKey: '{ceci n est pas du JSON',
        kWalkTestResultPrefsKey: json.encode(
          WalkTestResult(
            distanceMeters: 512,
            level: 'bon',
            takenAt: DateTime.utc(2026, 6, 6),
          ).toJson(),
        ),
      });
      prefs = await SharedPreferences.getInstance();

      final repo = depot();
      await repo.migrerDepuisPreferences();

      expect(
        (await repo.getProfile()).isEmpty,
        isTrue,
        reason: 'un JSON casse etait DEJA repute vide avant ce lot',
      );
      expect(
        (await repo.getWalkTestResult())?.distanceMeters,
        512,
        reason: 'la section lisible passe quand meme',
      );
      expect(
        prefs.getString(kHikerProfilePrefsKey),
        isNull,
        reason:
            'la garder ne restituerait rien et la laisserait monter dans '
            'iCloud pour toujours',
      );
    });

    test(
      'sans aucune cle heritee, la migration ne cree RIEN sur le disque',
      () async {
        await depot().migrerDepuisPreferences();

        final f = await ProfilRandonneurFichier().fichier();
        expect(f.existsSync(), isFalse);
        expect(
          f.parent.existsSync(),
          isFalse,
          reason:
              'un dossier medical/ vide chez un randonneur qui n a jamais '
              'rien saisi est une trace de passage (decision du lot 612)',
        );
      },
    );
  });

  // =========================================================================
  // 3. L'EXCLUSION iCLOUD : LA GARDE DU LOT 615, REUTILISEE TELLE QUELLE
  // =========================================================================
  group('623 — l exclusion iCloud du lot 615 est REUTILISEE, et elle survit a '
      'l ecriture atomique', () {
    late _NatifEspion natif;
    late ProfilRandonneurFichier stockage;

    setUp(() {
      natif = _NatifEspion()..brancher();
      stockage = ProfilRandonneurFichier(
        exclusionIcloud: ExclusionSauvegardeIcloud(cibleIos: true),
      );
      addTearDown(natif.debrancher);
    });

    test('LE TEST QUI DONNE SON NOM AU LOT 615, APPLIQUE AU PROFIL : '
        'l exclusion est posee APRES le renommage', () async {
      final repo = depot(fichier: stockage);
      await repo.saveProfile(
        const HikerProfile(age: 40, heightCm: 175, weightKg: 70),
      );
      natif.oublier();

      // La CORRECTION : c est elle qui fait passer le renommage par-dessus un
      // fichier deja existant, donc c est elle qui perd l attribut.
      await repo.saveProfile(gerard);

      final f = await stockage.fichier();
      final poses = natif.exclusionsDe(f.path);
      expect(
        poses,
        isNotEmpty,
        reason:
            'sans pose sur le fichier FINAL, l attribut est perdu a '
            'chaque correction du poids',
      );
      expect(
        poses.last.contenuAuMomentDeLAppel,
        contains('"weightKg":88'),
        reason:
            'LA PREUVE DE L ORDRE : au moment de la derniere exclusion, le '
            'chemin portait DEJA le nouveau poids — donc la pose est APRES le '
            'renommage. Posee avant, ce test serait rouge alors qu un simple '
            'comptage d appels serait vert.',
      );
    });

    test(
      'dix corrections du poids donnent dix exclusions du document final',
      () async {
        final repo = depot(fichier: stockage);
        final f = await stockage.fichier();

        for (var i = 0; i < 10; i++) {
          await repo.saveProfile(gerard.copyWith(weightKg: 80 + i.toDouble()));
        }

        expect(
          natif.exclusionsDe(f.path),
          hasLength(10),
          reason:
              'une pose unique a la creation passerait tous les autres '
              'tests du depot et ne se verrait que dans iCloud',
        );
      },
    );

    test('le dossier ET le temporaire sont couverts, et le temporaire AVANT le '
        'renommage', () async {
      final repo = depot(fichier: stockage);
      await repo.saveProfile(gerard);

      final f = await stockage.fichier();
      final tmp = '${f.path}${ProfilRandonneurFichier.suffixeTemporaire}';

      expect(
        natif.exclusionsDe(f.parent.path),
        isNotEmpty,
        reason:
            'le dossier aussi : la page d Apple ne garantit PAS que '
            'l attribut d un dossier s applique a son contenu, donc on pose '
            'les deux',
      );
      final idxTmp = natif.appels.indexWhere((a) => a.chemin == _n(tmp));
      final idxFinal = natif.appels.lastIndexWhere(
        (a) => a.chemin == _n(f.path),
      );
      expect(
        idxTmp,
        greaterThanOrEqualTo(0),
        reason:
            'sans pose sur le temporaire, la morphologie existe sur le '
            'disque sans attribut pendant toute l ecriture',
      );
      expect(
        idxTmp,
        lessThan(idxFinal),
        reason:
            'temporaire AVANT le renommage, final APRES : chacune couvre '
            'l hypothese de l autre',
      );
    });

    test('garantirExclusion repose l attribut SANS RIEN ECRIRE, pour le '
        'telephone deja mis a jour', () async {
      final repo = depot(fichier: stockage);
      await repo.saveProfile(gerard);
      final f = await stockage.fichier();
      final avant = f.readAsStringSync();
      natif.oublier();

      await stockage.garantirExclusion();

      expect(natif.exclusionsDe(f.path), hasLength(1));
      expect(natif.exclusionsDe(f.parent.path), hasLength(1));
      expect(
        f.readAsStringSync(),
        avant,
        reason:
            'on remplit son profil UNE fois : la repose ne doit pas '
            'reecrire le document',
      );
    });

    test(
      'garantirExclusion ne CREE rien quand rien n a jamais ete saisi',
      () async {
        await stockage.garantirExclusion();

        expect(natif.appels, isEmpty);
        final f = await stockage.fichier();
        expect(f.parent.existsSync(), isFalse);
      },
    );
  });

  // =========================================================================
  // 4. LA GARDE QUI PROTEGE TOUTE LA SUITE (mesure du lot 612, reprise en 615)
  // =========================================================================
  group('623 — hors iPhone, enregistrer un profil n emet AUCUN appel de '
      'plateforme', () {
    test(
      'LA GARDE REELLE : par DEFAUT, une ecriture de profil ne touche pas au '
      'canal',
      () async {
        final natif = _NatifEspion()..brancher();
        addTearDown(natif.debrancher);

        // Stockage par defaut : `ExclusionSauvegardeIcloud()` resout `cibleIos`
        // sur `Platform.isIOS`, faux dans `flutter test`.
        await depot().saveProfile(gerard);

        expect(
          natif.appels,
          isEmpty,
          reason:
              'le lot 612 a mesure qu un appel a un canal sans '
              'interlocuteur rendait trois tests d ecran ROUGES : il ne rend '
              'jamais la main dans le temps feint d un test de widgets',
        );
      },
    );
  });

  // =========================================================================
  // 5. AUCUNE TRACE DE PASSAGE, ET L'EFFACEMENT EMPORTE TOUT
  // =========================================================================
  group('623 — effacement et trace de passage', () {
    test(
      'l effacement de l article 17 emporte le document ET son temporaire',
      () async {
        final repo = depot();
        await repo.saveProfile(gerard);
        final f = await ProfilRandonneurFichier().fichier();
        // Une ecriture interrompue a laisse un temporaire derriere elle.
        File(
          '${f.path}${ProfilRandonneurFichier.suffixeTemporaire}',
        ).writeAsStringSync('{"profil":{"weightKg":88}}');

        await repo.eraseAllPersonalData();

        expect(f.existsSync(), isFalse);
        expect(
          File(
            '${f.path}${ProfilRandonneurFichier.suffixeTemporaire}',
          ).existsSync(),
          isFalse,
          reason:
              'sinon la morphologie reste dans le .tmp, hors de portee du '
              'droit a l effacement',
        );
      },
    );

    test(
      'un contenu entierement vide EFFACE le document au lieu de l ecrire',
      () async {
        final stockage = ProfilRandonneurFichier();
        await stockage.ecrire(const ContenuProfilRandonneur(profil: gerard));
        final f = await stockage.fichier();
        expect(f.existsSync(), isTrue);

        await stockage.ecrire(ContenuProfilRandonneur.vide);

        expect(
          f.existsSync(),
          isFalse,
          reason:
              'un document de champs vides est une trace de passage la ou le '
              'randonneur a demande qu il n y en ait plus (lot 566, LOT O)',
        );
      },
    );

    test('un document illisible ne fait pas planter la lecture', () async {
      final stockage = ProfilRandonneurFichier();
      final f = await stockage.fichier();
      f.parent.createSync(recursive: true);
      f.writeAsStringSync('{ceci n est pas du JSON');

      final contenu = await stockage.lire();

      expect(contenu.profil, isNull);
      expect(
        contenu.randosPassees,
        isEmpty,
        reason:
            'un profil corrompu ne doit pas empecher l ecran de '
            's ouvrir',
      );
    });

    test('une SECTION illisible ne fait pas perdre les autres', () async {
      final stockage = ProfilRandonneurFichier();
      final f = await stockage.fichier();
      f.parent.createSync(recursive: true);
      f.writeAsStringSync(
        json.encode(<String, dynamic>{
          ProfilRandonneurFichier.clefProfil: 'pas un objet',
          ProfilRandonneurFichier.clefRandosPassees: [
            PastHike(date: DateTime.utc(2026, 5, 1), days: 3).toJson(),
          ],
        }),
      );

      final contenu = await stockage.lire();

      expect(contenu.profil, isNull);
      expect(
        contenu.randosPassees,
        hasLength(1),
        reason:
            'les randonnees du randonneur ne doivent pas partir parce que '
            'son poids etait devenu illisible',
      );
    });
  });

  // =========================================================================
  // 5 bis. LE CAS QUI ECHOUE DOIT ECHOUER PROPREMENT — MANDAT DE CHRISTOPHE
  // =========================================================================
  group('623 — quand l ecriture du fichier ECHOUE, le randonneur l apprend', () {
    /// Un stockage dont le dossier applicatif est INCREABLE : il pointe SOUS un
    /// fichier existant, ce qu aucun systeme n accepte comme repertoire parent.
    /// C est la facon la plus proche du reel de simuler un stockage sature ou des
    /// droits refuses, sans substituer aucune methode.
    ProfilRandonneurFichier stockageImpossible() {
      final obstacle = File(
        '${Directory.systemTemp.createTempSync('623').path}/pas-un-dossier',
      )..writeAsStringSync('je suis un fichier, pas un dossier');
      addTearDown(() {
        if (obstacle.existsSync()) obstacle.deleteSync();
      });
      return ProfilRandonneurFichier(
        dossierApplicatif: () async => Directory('${obstacle.path}/dedans'),
      );
    }

    testWidgets('LE FAUX SUCCES EST FERME : l ecran ne dit PAS « enregistree » '
        'et ne se referme pas', (tester) async {
      // CE QUE CE TEST ATTRAPE. `HikerProfileNotifier.save` enferme l ecriture
      // dans `AsyncValue.guard` : une exception ne remonte pas a l ecran, elle
      // devient un ETAT D ERREUR que personne ne regardait. Avant ce lot
      // l ecriture allait dans SharedPreferences et n echouait jamais ; elle va
      // maintenant dans un fichier, qui PEUT echouer. Sans le controle ajoute par
      // ce lot, l ecran affichait « Fiche enregistree » et se refermait sur une
      // ecriture qui n avait pas eu lieu.
      final stockage = stockageImpossible();
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            hikerProfileRepositoryProvider.overrideWithValue(
              depot(fichier: stockage),
            ),
          ],
          child: TranslationProvider(
            child: MaterialApp.router(
              routerConfig: GoRouter(
                initialLocation: '/home/profile',
                routes: [
                  GoRoute(
                    path: '/home',
                    builder: (_, __) => const Scaffold(body: SizedBox()),
                    routes: [
                      GoRoute(
                        path: 'profile',
                        builder: (_, __) => const HikerProfileScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tp = t.hikerProfile;
      await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldAge),
        '72',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldHeight),
        '172',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, tp.fieldWeight),
        '88',
      );
      await tester.pumpAndSettle();
      // Le consentement article 9 est ACCORDE : ce test porte sur l echec
      // d ecriture, pas sur le refus (qui a ses propres tests, tache 560).
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      await tester.tap(find.text(tp.save));
      await tester.pumpAndSettle();

      expect(
        find.text(tp.errorSaveFailed),
        findsOneWidget,
        reason:
            'le randonneur doit comprendre ce qui se passe : il remplit '
            'cette fiche « pour sa securite »',
      );
      expect(
        find.text(tp.saved),
        findsNothing,
        reason:
            'annoncer un enregistrement qui n a pas eu lieu est un FAUX '
            'SUCCES, la meme famille de defaut que le lien de suivi mort',
      );
      expect(
        find.byType(HikerProfileScreen),
        findsOneWidget,
        reason:
            'l ecran reste ouvert : sa saisie est encore la, il peut '
            'reessayer sans rien retaper',
      );
    });
  });

  // =========================================================================
  // 6. INVARIANTE : PLUS AUCUN CODE DE PRODUCTION N'ECRIT LES CLES HERITEES
  // =========================================================================
  group('623 — INVARIANTE : personne ne remet le profil dans les preferences', () {
    test('aucun fichier de lib/ n ECRIT les quatre cles heritees', () {
      // SANS CETTE GARDE, un ecran ajoute demain remettrait le poids dans les
      // preferences — d ou il monterait dans iCloud sur iPhone — et aucun test de
      // comportement ne le verrait.
      const cles = [
        'kHikerProfilePrefsKey',
        'kHikerPastHikesPrefsKey',
        'kWalkTestResultPrefsKey',
        'kHikerExperienceNotePrefsKey',
      ];
      final fautifs = <String>[];
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final code = _codeSeul(f.readAsStringSync());
        for (final cle in cles) {
          if (RegExp(
            'set(String|Int|Bool|Double|StringList)\\s*\\(\\s*$cle',
          ).hasMatch(code)) {
            fautifs.add('${f.path} ($cle)');
          }
        }
      }
      expect(
        fautifs,
        isEmpty,
        reason:
            'une ecriture de cle heritee est revenue : ${fautifs.join(", ")}',
      );
    });

    test('les quatre cles heritees ne sont plus nommees que par le depot du '
        'profil et la declaration de sauvegarde', () {
      // Elles doivent CONTINUER d exister — la migration doit savoir ou chercher
      // et l effacement de l article 17 doit les emporter — mais leur usage doit
      // rester confine, sinon « la source durable est le fichier » devient faux.
      final autorises = {
        'lib/features/feasibility/data/hiker_profile_repository.dart',
      };
      final trouves = <String>{};
      for (final f
          in Directory('lib')
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart'))) {
        final code = _codeSeul(f.readAsStringSync());
        if (code.contains('kHikerProfilePrefsKey') ||
            code.contains('kHikerPastHikesPrefsKey') ||
            code.contains('kWalkTestResultPrefsKey') ||
            code.contains('kHikerExperienceNotePrefsKey')) {
          trouves.add(_n(f.path));
        }
      }
      expect(
        trouves,
        autorises.map(_n).toSet(),
        reason:
            'la liste des fichiers qui connaissent les cles heritees doit '
            'etre DECIDEE, pas subie',
      );
    });
  });
}
