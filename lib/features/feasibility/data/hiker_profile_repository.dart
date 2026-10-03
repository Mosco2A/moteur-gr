/// La source durable du profil, avec un identifiant LOCAL stable tant qu'aucun
/// compte n'est lie — meme convention que le portefeuille.
library;

import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/database.dart';
import '../../../core/data/daos/hiker_profile_dao.dart';
import '../../../core/data/daos/past_hikes_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/hiker_profile.dart';
import '../domain/past_hike.dart';
import '../domain/walk_test_result.dart';
import 'hiker_profile_file.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Identifiant utilisateur LOCAL du profil tant qu'aucun compte n'est lie.
///
/// Meme convention que le wallet L1 (`kWalletLocalUserId`) : cle locale stable
/// avant liaison de compte. La bascule vers le hash SHA-256 reel
/// (`anonymous_id_service`) et le miroir cloud non nominatif sont branches
/// cote sync (comme le wallet), hors du perimetre de cette couche.
const String kHikerLocalUserId = 'local';

/// Cle SharedPreferences HERITEE : fiche profil randonneur (JSON).
///
/// PLUS RIEN NE L'ECRIT DEPUIS LA TACHE 623. Elle subsiste pour DEUX raisons, et
/// aucune des deux n'est de la nostalgie : la migration doit savoir ou chercher
/// ce que les telephones portent deja, et l'effacement de l'article 17 doit
/// continuer de l'emporter. Voir [HikerProfileFile].
const String kHikerProfilePrefsKey = 'hiker.profile';

/// Cle SharedPreferences HERITEE : liste des randos passees (JSON list).
/// Voir [kHikerProfilePrefsKey].
const String kHikerPastHikesPrefsKey = 'hiker.pastHikes';

/// Cle SharedPreferences HERITEE : note d'experience globale (texte libre).
/// Voir [kHikerProfilePrefsKey].
const String kHikerExperienceNotePrefsKey = 'hiker.experienceNote';

/// Cle SharedPreferences HERITEE : dernier resultat du test 6 minutes (JSON).
/// Voir [kHikerProfilePrefsKey].
const String kWalkTestResultPrefsKey = 'hiker.walkTestResult';

/// Couche de persistance du profil randonneur (StepWays LOT 4, Ph1/Ph3).
///
/// ---------------------------------------------------------------------------
/// LA SOURCE DURABLE A QUITTE LES PREFERENCES (tache 623) — ET CE FICHIER
/// NOMMAIT LUI-MEME LE DEFAUT DEPUIS LA TACHE 613
/// ---------------------------------------------------------------------------
///
/// Ce qu'on lisait ici avant ce lot : « cette fiche (age, taille, poids) est
/// declaree au randonneur comme une donnee de sante, et SharedPreferences est
/// INCLUS dans la sauvegarde du telephone par Google ou Apple ». La tache 617 l'a
/// chiffre plus precisement encore (`SauvegardeSysteme.trouUserDefaultsIos`) :
/// sur iPhone, `NSUserDefaults` n'est PAS un fichier de l'application mais un
/// domaine de preferences du systeme, et `NSURLIsExcludedFromBackupKey` ne peut
/// donc pas s'y appliquer — ni globalement, ni cle par cle. Le poids et la taille
/// montaient dans iCloud, et AUCUNE declaration ne pouvait l'empecher.
///
/// Or la regle de Christophe du 27/09, en majuscules, inclut explicitement le
/// poids et la taille : « Les donnees medicales RESTENT sur le tel ».
///
/// LA SOURCE DURABLE EST DESORMAIS [HikerProfileFile] : un fichier, dans
/// le MEME dossier protege que la fiche medicale, avec la MEME exclusion iCloud du
/// lot 615 — reutilisee, pas reinventee. La migration des telephones existants est
/// faite par [migrerDepuisPreferences], une seule fois, sans rien perdre.
///
/// LE MIROIR DRIFT EST CONSERVE, ET C'EST LE MEME ARBITRAGE QUE LA TACHE 613 :
/// il est devenu redondant, pas faux, et on ne renverse pas deux montages de
/// persistance dans le lot qui vient d'en changer un. Point OUVERT, pas oubli.
/// A SAVOIR, ET C'EST MESURE : le miroir vit dans `stepways.sqlite`, que
/// `CopieSauvegardableBaseService` copie dans le dossier sauvegardable quand le
/// randonneur DECOCHE la case. La morphologie suit donc le regime de la BASE de ce
/// cote-la, pas celui du fichier protege — c'etait deja vrai avant ce lot et cela
/// n'a pas change.
///
/// CONFIDENTIALITE : donnee SENSIBLE (morpho) — jamais nominative. Le miroir
/// cloud anonyme (hash) + la restauration au changement de tel sont branches
/// cote CloudSyncService (hors de cette couche, comme le wallet). Ici :
/// uniquement la persistance locale durable + miroir Drift.
class HikerProfileRepository {
  HikerProfileRepository({
    required AppDatabase db,
    SharedPreferences? prefs,
    String userId = kHikerLocalUserId,
    HikerProfileFile? fichier,
  }) : _db = db,
       _prefs = prefs,
       _userId = userId,
       _fichier = fichier ?? HikerProfileFile();

  final AppDatabase _db;
  SharedPreferences? _prefs;
  final String _userId;

  /// LA SOURCE DURABLE (tache 623) : un fichier dans le dossier protege.
  final HikerProfileFile _fichier;

  /// Vrai des que la migration depuis les preferences a ete TENTEE pour cette
  /// instance. Elle est idempotente, mais la refaire a chaque lecture couterait
  /// quatre interrogations de preferences pour rien.
  bool _migrationTentee = false;

  HikerProfileDao get _profileDao => _db.hikerProfileDao;
  PastHikesDao get _pastHikesDao => _db.pastHikesDao;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  /// Le stockage protege, exposee pour l'amorce de l'application (qui doit
  /// reposer l'exclusion iCloud a chaque demarrage) et pour les tests.
  HikerProfileFile get fichier => _fichier;

  // --- Source durable : lecture / ecriture uniques ---------------------------

  /// L'UNIQUE CHEMIN DE LECTURE. Il fait passer la migration devant, une fois.
  Future<HikerProfileContent> _charger() async {
    if (!_migrationTentee) {
      await migrerDepuisPreferences();
    }
    return _fichier.lire();
  }

  /// L'UNIQUE CHEMIN D'ECRITURE.
  ///
  /// Pourquoi il est unique : la pose de l'exclusion iCloud vit DANS
  /// [HikerProfileFile.ecrire], et un second chemin d'ecriture serait un
  /// second endroit ou l'oublier. C'est exactement le defaut que la tache 615 a
  /// trouve dans l'ecriture atomique de la 613.
  Future<void> _enregistrer(HikerProfileContent contenu) =>
      _fichier.ecrire(contenu);

  /// MIGRE LES QUATRE CLES HERITEES VERS LE FICHIER PROTEGE, PUIS LES RETIRE.
  ///
  /// IDEMPOTENTE ET CONVERGENTE : sans cle heritee elle ne fait rien. Elle est
  /// appelee par l'amorce de l'application ET, par prudence, devant la premiere
  /// lecture de chaque instance — un randonneur qui ne passerait pas par l'amorce
  /// ne doit pas rester avec son poids dans iCloud.
  ///
  /// LE FICHIER GAGNE, SECTION PAR SECTION. Si le fichier porte deja un profil,
  /// c'est lui qui est le plus recent (la cle heritee n'est plus ecrite depuis ce
  /// lot) : la cle est alors seulement retiree. Mais la fusion est faite SECTION
  /// PAR SECTION, parce qu'une migration interrompue peut avoir transporte les
  /// randonnees sans le test de marche — et « la migration ne perd rien » est la
  /// consigne de ce lot.
  ///
  /// UNE VALEUR HERITEE ILLISIBLE EST RETIREE QUAND MEME, ET C'EST UN CHOIX. Elle
  /// est DEJA perdue du point de vue de l'application ([getProfile] rendait une
  /// fiche vide sur un JSON casse, bien avant ce lot) : la garder ne restituerait
  /// rien et la laisserait monter dans iCloud pour toujours. L'incident est
  /// journalise, pas tu.
  ///
  /// NE LEVE JAMAIS : elle passe devant chaque lecture du profil et devant
  /// l'amorce. Un defaut de migration ne doit pas empecher l'ecran de s'ouvrir.
  Future<void> migrerDepuisPreferences() async {
    _migrationTentee = true;
    try {
      final prefs = await _preferences;
      final brutProfil = prefs.getString(kHikerProfilePrefsKey);
      final brutRandos = prefs.getString(kHikerPastHikesPrefsKey);
      final brutTest = prefs.getString(kWalkTestResultPrefsKey);
      final brutNote = prefs.getString(kHikerExperienceNotePrefsKey);

      if (brutProfil == null &&
          brutRandos == null &&
          brutTest == null &&
          brutNote == null) {
        return;
      }

      var contenu = await _fichier.lire();

      if (contenu.profil == null && brutProfil != null) {
        try {
          contenu = contenu.copyWith(
            profil: HikerProfile.fromJson(
              json.decode(brutProfil) as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          _log.e(
            '[HikerProfileRepository] Profil herite illisible, retire '
            'sans etre transporte: $e',
          );
        }
      }

      if (contenu.randosPassees.isEmpty && brutRandos != null) {
        try {
          final list =
              (json.decode(brutRandos) as List<dynamic>)
                  .whereType<Map<String, dynamic>>()
                  .map(PastHike.fromJson)
                  .toList()
                ..sort((a, b) => b.date.compareTo(a.date));
          contenu = contenu.copyWith(
            randosPassees: list.take(kMaxPastHikes).toList(),
          );
        } catch (e) {
          _log.e(
            '[HikerProfileRepository] Randos heritees illisibles, '
            'retirees sans etre transportees: $e',
          );
        }
      }

      if (contenu.testDeMarche == null && brutTest != null) {
        try {
          contenu = contenu.copyWith(
            testDeMarche: WalkTestResult.fromJson(
              json.decode(brutTest) as Map<String, dynamic>,
            ),
          );
        } catch (e) {
          _log.e(
            '[HikerProfileRepository] Test de marche herite illisible, '
            'retire sans etre transporte: $e',
          );
        }
      }

      if (contenu.noteExperienceHeritee == null &&
          brutNote != null &&
          brutNote.isNotEmpty) {
        contenu = contenu.copyWith(noteExperienceHeritee: brutNote);
      }

      await _enregistrer(contenu);

      // LES CLES PARTENT APRES L'ECRITURE, JAMAIS AVANT : une coupure de courant
      // entre les deux doit laisser la donnee dans les preferences, pas nulle
      // part. La migration se rejouera au demarrage suivant.
      await prefs.remove(kHikerProfilePrefsKey);
      await prefs.remove(kHikerPastHikesPrefsKey);
      await prefs.remove(kWalkTestResultPrefsKey);
      await prefs.remove(kHikerExperienceNotePrefsKey);

      _log.i(
        '[HikerProfileRepository] Profil migre des preferences vers le '
        'stockage protege (age/taille/poids hors sauvegarde iCloud)',
      );
    } catch (e) {
      _log.e(
        '[HikerProfileRepository] Migration impossible ($e) — les cles '
        'heritees restent en place, la migration se rejouera',
      );
    }
  }

  // --- Profil (fiche d'info) -----------------------------------------------

  /// Hydrate le profil depuis la SOURCE DURABLE (le fichier protege) et met a
  /// jour le MIROIR Drift. Retourne le profil (vide si aucune fiche saisie).
  Future<HikerProfile> load() async {
    final contenu = await _charger();
    final profile = contenu.profil;
    if (profile == null) return HikerProfile.empty;
    await _mirrorProfileToDrift(profile);
    return profile;
  }

  /// Relit le profil sans re-mirroring (raccourci lecture).
  Future<HikerProfile> getProfile() async {
    final contenu = await _charger();
    return contenu.profil ?? HikerProfile.empty;
  }

  /// Sauvegarde le profil : le fichier protege (source durable) ET Drift
  /// (miroir), avec `updatedAt` rafraichi. L'IMC n'est jamais persiste (getter
  /// calcule).
  Future<HikerProfile> saveProfile(HikerProfile profile) async {
    final stamped = profile.copyWith(updatedAt: DateTime.now());
    final contenu = await _charger();
    await _enregistrer(contenu.copyWith(profil: stamped));
    await _mirrorProfileToDrift(stamped);
    _log.d('[HikerProfileRepository] Profil sauvegarde (IMC calcule local)');
    return stamped;
  }

  /// Supprime le profil (droit a l'effacement RGPD) : fichier protege ET Drift.
  ///
  /// PERIMETRE : la seule fiche d'info. Pour l'effacement TOTAL au titre de
  /// l'article 17 (randos, note d'experience et test de marche compris), c'est
  /// [eraseAllPersonalData] qu'il faut appeler.
  Future<void> deleteProfile() async {
    final contenu = await _charger();
    await _enregistrer(contenu.copyWith(effacerProfil: true));
    await _profileDao.deleteByUserId(_userId);
  }

  /// EFFACE TOUTE LA FICHE RANDONNEUR — droit a l'effacement, article 17.
  ///
  /// POURQUOI CETTE METHODE EXISTE (tache 561, J1). `DataRetentionService` se
  /// presente comme un effacement COMPLET, mais sa liste de tables etait
  /// recopiee a la main et la fiche randonneur n'y figurait pas : un effacement
  /// au titre du droit a l'oubli laissait l'age, la taille et le poids sur
  /// l'appareil — la donnee que l'application declare elle-meme au randonneur
  /// comme relevant de la sante, dans les cinq langues.
  ///
  /// POURQUOI ICI, ET PAS DANS LE SERVICE DE RETENTION. Cette fiche est stockee
  /// sur DEUX etages (prefs durables + miroir Drift) et cette couche est la
  /// seule a connaitre les deux. Vider le seul miroir Drift n'effacerait rien
  /// durablement : [load] le re-hydrate depuis les prefs au demarrage suivant.
  /// Un second chemin d'effacement ecrit ailleurs divergerait le jour ou une
  /// cle s'ajoute — il n'y a donc qu'un chemin, et c'est celui-ci.
  ///
  /// CE QUI PART : le fichier protege ENTIER (fiche, randos passees, note
  /// d'experience heritee, resultat du test de marche 6 min), les quatre cles de
  /// prefs heritees ET les trois tables Drift correspondantes pour cet
  /// utilisateur.
  ///
  /// LES CLES DE PREFS PARTENT ENCORE, ALORS QUE PLUS RIEN NE LES ECRIT (tache
  /// 623). Meme raisonnement que la tache 570 pour la note de difficultes : la
  /// migration les retire au premier demarrage, mais un effacement demande AVANT
  /// ce demarrage — ou apres une migration interrompue — doit les emporter. La
  /// porte de sortie ferme apres tout le monde.
  ///
  /// A ne pas confondre avec [eraseMorphology] (retrait d'une CATEGORIE de
  /// donnees apres refus du consentement art. 9 : la fiche survit, videe de sa
  /// morphologie). Ici, plus rien ne survit.
  Future<void> eraseAllPersonalData() async {
    // Etage 1 — la source durable : le fichier protege part en entier.
    await _fichier.effacer();
    // Etage 1 bis — les cles heritees, pour les telephones pas encore migres.
    final prefs = await _preferences;
    await prefs.remove(kHikerProfilePrefsKey);
    await prefs.remove(kHikerPastHikesPrefsKey);
    await prefs.remove(kHikerExperienceNotePrefsKey);
    await prefs.remove(kWalkTestResultPrefsKey);
    // Etage 2 — miroir Drift.
    await _profileDao.deleteByUserId(_userId);
    await _pastHikesDao.deleteAllForUser(_userId);
    await _pastHikesDao.deleteNote(_userId);
    _log.d(
      '[HikerProfileRepository] Fiche randonneur effacee (art. 17) : '
      'fichier protege, cles heritees ET miroir Drift',
    );
  }

  /// EFFACE LA MORPHOLOGIE — age, taille, poids — des deux etages de stockage
  /// (prefs durables ET miroir Drift), et retourne ce qui reste.
  ///
  /// POURQUOI CETTE METHODE EXISTE (tache 560, N1). Un consentement article 9
  /// refuse ou retire ne doit pas seulement faire CESSER l'ecriture : il doit
  /// faire DISPARAITRE ce qui a deja ete ecrit. La campagne personas 559 a
  /// mesure l'inverse : consentement laisse refuse, « Enregistrer » touche, et
  /// apres redemarrage 72 ans / 172 cm / 88 kg relus a l'ecran. Cesser d'ecrire
  /// aurait laisse ces trois valeurs sur l'appareil.
  ///
  /// CE QUI EST EFFACE, ET POURQUOI EXACTEMENT CES TROIS CHAMPS. Le perimetre
  /// est celui que l'application DECLARE elle-meme au randonneur, mot pour mot
  /// (`hikerProfile.consentBody`, cinq langues) : « Age, taille et poids sont
  /// des donnees de sante ». Le sexe declare et le pays ne relevent pas de
  /// l'article 9 et ne sont pas couverts par cette bascule : ils survivent, et
  /// une fiche reduite a ces deux champs est [HikerProfile.isEmpty] — la
  /// faisabilite retombe donc proprement sur son fallback, comme si rien
  /// n'avait jamais ete saisi.
  ///
  /// LA QUATRIEME MESURE (tache 562, K2a). Le RESULTAT DU TEST DE MARCHE 6 MIN
  /// part aussi, et il ne figure pourtant pas dans le texte affiche. Une
  /// distance parcourue en six minutes est une MESURE DE CAPACITE PHYSIQUE : elle
  /// releve de l'article 9 au meme titre que le poids, et elle en dit davantage.
  /// Le perimetre suit donc la NATURE de la donnee, pas la liste des trois
  /// champs du formulaire de saisie — sinon la prochaine mesure ajoutee a la
  /// fiche survivra elle aussi au refus, exactement comme celle-ci l'a fait.
  ///
  /// UN REFUS NE LAISSE AUCUNE TRACE DE PASSAGE (tache 566, LOT O). Cette
  /// methode ECRIVAIT un profil a zero, horodate, meme quand il n'y avait rien a
  /// effacer. Une lecture directe du fichier de preferences de l'appareil l'a
  /// mesure : apres un refus, `hiker.profile` existait, avec
  /// `{"age":0,"heightCm":0,"weightKg":0.0,...,"updatedAt":"..."}` — a l'endroit
  /// exact ou l'ecran venait de promettre « Sans votre accord, rien n'est
  /// enregistre ». Aucune donnee de sante n'y survivait, mais une cle creee et
  /// horodatee reste une trace du geste. La promesse est juste : c'est au code de
  /// la tenir. S'il ne reste rien qui echappe a l'article 9, la cle est
  /// SUPPRIMEE — des deux etages — au lieu d'etre reecrite a zero.
  ///
  /// A ne pas confondre avec [deleteProfile] (effacement TOTAL, droit a
  /// l'effacement) : ici on retire une CATEGORIE de donnees, pas la fiche.
  Future<HikerProfile> eraseMorphology() async {
    final contenu = await _charger();
    final current = contenu.profil ?? HikerProfile.empty;
    final erased = current.copyWith(
      age: 0,
      heightCm: 0,
      weightKg: 0,
      updatedAt: DateTime.now(),
    );

    // RESTE-T-IL QUELQUE CHOSE QUI N'EST PAS DE L'ARTICLE 9 ? Le sexe declare et
    // le pays n'en relevent pas et le randonneur ne les a pas refuses : les
    // emporter depasserait ce qu'il a exprime. La fiche reste donc, privee de sa
    // morphologie. S'il n'y a rien d'autre, il n'y a plus de fiche du tout.
    final resteDuNonArticle9 =
        (erased.sex?.isNotEmpty ?? false) || erased.countryIso.isNotEmpty;

    // LA MESURE DU TEST DE MARCHE PART DANS LE MEME GESTE, ET C'EST LE MEME
    // FICHIER : une distance parcourue en six minutes est une mesure de capacite
    // physique, donc de l'article 9 au meme titre que le poids (tache 562, K2a).
    // Un seul enregistrement atomique au lieu de deux ecritures : il n'existe
    // aucun instant ou la morphologie est partie et pas le test.
    await _enregistrer(
      contenu.copyWith(
        profil: resteDuNonArticle9 ? erased : null,
        effacerProfil: !resteDuNonArticle9,
        effacerTestDeMarche: true,
      ),
    );

    if (resteDuNonArticle9) {
      await _mirrorProfileToDrift(erased);
    } else {
      // Le miroir Drift part avec la source : une ligne a zero y serait la meme
      // trace de passage, a un autre etage — et [load] la re-ecrirait au boot.
      await _profileDao.deleteByUserId(_userId);
    }
    _log.d(
      '[HikerProfileRepository] Morphologie ET test de marche effaces '
      '(consentement art. 9 refuse ou retire) — fiche '
      '${resteDuNonArticle9 ? "conservee sans morphologie" : "supprimee"}',
    );
    return resteDuNonArticle9 ? erased : HikerProfile.empty;
  }

  Future<void> _mirrorProfileToDrift(HikerProfile profile) async {
    await _profileDao.upsert(
      HikerProfileCompanion.insert(
        userId: _userId,
        age: Value(profile.age),
        heightCm: Value(profile.heightCm),
        weightKg: Value(profile.weightKg),
        sex: Value(profile.sex),
        countryIso: Value(profile.countryIso),
        updatedAt: profile.updatedAt ?? DateTime.now(),
      ),
    );
  }

  // --- Randos passees (max 5) ----------------------------------------------

  /// Charge les randos depuis la source durable (le fichier protege) et met a
  /// jour Drift. Triees par date decroissante, plafonnees a [kMaxPastHikes].
  Future<List<PastHike>> loadPastHikes() async {
    final contenu = await _charger();
    if (contenu.randosPassees.isEmpty) return const [];
    final list = [...contenu.randosPassees]
      ..sort((a, b) => b.date.compareTo(a.date));
    final capped = list.take(kMaxPastHikes).toList();
    await _mirrorPastHikesToDrift(capped);
    return capped;
  }

  /// Remplace la liste complete des randos (fichier protege + Drift), plafonnee
  /// a 5.
  ///
  /// L'ecran d'interview gere l'ajout/edition/suppression puis persiste la
  /// liste entiere — plus simple et sur que des ids Drift volatils.
  Future<List<PastHike>> savePastHikes(List<PastHike> hikes) async {
    final sorted = [...hikes]..sort((a, b) => b.date.compareTo(a.date));
    final capped = sorted.take(kMaxPastHikes).toList();
    final contenu = await _charger();
    await _enregistrer(contenu.copyWith(randosPassees: capped));
    await _mirrorPastHikesToDrift(capped);
    _log.d('[HikerProfileRepository] ${capped.length} rando(s) sauvegardee(s)');
    return capped;
  }

  Future<void> _mirrorPastHikesToDrift(List<PastHike> hikes) async {
    await _pastHikesDao.deleteAllForUser(_userId);
    final now = DateTime.now();
    for (final h in hikes) {
      await _pastHikesDao.insertHike(
        PastHikeEntriesCompanion.insert(
          userId: _userId,
          date: h.date,
          days: Value(h.days),
          avgWalkHoursPerDay: Value(h.avgWalkHoursPerDay),
          totalElevationGain: Value(h.totalElevationGain),
          totalDistanceKm: Value(h.totalDistanceKm),
          updatedAt: now,
        ),
      );
    }
  }

  // --- Note d'experience globale (texte libre) : PLUS D'ECRITURE ------------
  //
  // TACHE 570, S2 — `getExperienceNote` et `saveExperienceNote` sont retirees.
  // Ce couple ecrivait le texte libre « difficultes » sur DEUX etages (prefs
  // durables + miroir Drift), d'ou il partait au cloud et revenait a la
  // restauration — pour n'etre jamais relu par aucune regle metier. Plus rien
  // n'ecrit donc dans `hiker.experienceNote` ni dans la table de notes.
  //
  // CE QUI SUBSISTE, ET POURQUOI. La cle de prefs
  // ([kHikerExperienceNotePrefsKey]) et l'effacement de la table restent, tous
  // deux dans [eraseAllPersonalData] SEULEMENT : des telephones portent deja
  // cette note, et arreter de collecter ne les nettoie pas. Retirer la ligne
  // d'effacement en meme temps que la collecte laisserait ces textes sur
  // l'appareil pour toujours, hors de portee du droit a l'oubli — c'est
  // exactement le defaut que la tache 561 avait eu a corriger. La porte de
  // sortie ferme donc apres tout le monde.

  // --- Test de marche 6 minutes (dernier resultat date) --------------------

  /// Relit le dernier resultat du test 6 min, ou null si jamais fait
  /// (=> fallback auto-eval cote faisabilite).
  Future<WalkTestResult?> getWalkTestResult() async {
    final contenu = await _charger();
    return contenu.testDeMarche;
  }

  /// Enregistre le resultat du test 6 min (remplace le precedent : recurrent).
  ///
  /// IL VA DANS LE MEME FICHIER PROTEGE QUE LA MORPHOLOGIE (tache 623), et pour
  /// la meme raison qu'il part avec elle au refus de consentement : une distance
  /// parcourue en six minutes est une MESURE DE CAPACITE PHYSIQUE, donc de
  /// l'article 9 — elle en dit meme davantage que le poids (tache 562, K2a).
  Future<void> saveWalkTestResult(WalkTestResult result) async {
    final contenu = await _charger();
    await _enregistrer(contenu.copyWith(testDeMarche: result));
    _log.d(
      '[HikerProfileRepository] Test 6 min: ${result.distanceMeters} m '
      '-> ${result.level}',
    );
  }
}

/// Provider Riverpod du [HikerProfileRepository].
///
/// Branche sur la meme instance Drift que le reste de l'app
/// ([databaseProvider]). Convention identique au `walletStoreProvider`.
final hikerProfileRepositoryProvider = Provider<HikerProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HikerProfileRepository(db: db);
});
