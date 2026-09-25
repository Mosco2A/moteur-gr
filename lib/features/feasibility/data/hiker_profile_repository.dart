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

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// Identifiant utilisateur LOCAL du profil tant qu'aucun compte n'est lie.
///
/// Meme convention que le wallet L1 (`kWalletLocalUserId`) : cle locale stable
/// avant liaison de compte. La bascule vers le hash SHA-256 reel
/// (`anonymous_id_service`) et le miroir cloud non nominatif sont branches
/// cote sync (comme le wallet), hors du perimetre de cette couche.
const String kHikerLocalUserId = 'local';

/// Cle SharedPreferences : fiche profil randonneur (JSON).
const String kHikerProfilePrefsKey = 'hiker.profile';

/// Cle SharedPreferences : liste des randos passees (JSON list).
const String kHikerPastHikesPrefsKey = 'hiker.pastHikes';

/// Cle SharedPreferences : note d'experience globale (texte libre).
const String kHikerExperienceNotePrefsKey = 'hiker.experienceNote';

/// Cle SharedPreferences : dernier resultat du test de marche 6 minutes (JSON).
const String kWalkTestResultPrefsKey = 'hiker.walkTestResult';

/// Couche de persistance DUALE du profil randonneur (StepWays LOT 4, Ph1/Ph3).
///
/// POURQUOI la double persistance : la base Drift tourne EN MEMOIRE
/// (`database_provider.dart` = `NativeDatabase.memory()`, VOLATILE) — un profil
/// stocke uniquement en Drift disparaitrait au redemarrage. La SOURCE DURABLE
/// est donc SharedPreferences (JSON) ; Drift ([HikerProfile], [PastHikes],
/// [HikerExperienceNote]) en est le MIROIR canonique, hydrate au boot depuis
/// les prefs par [load]. Meme patron que `WalletStore` (LOT 1).
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
  })  : _db = db,
        _prefs = prefs,
        _userId = userId;

  final AppDatabase _db;
  SharedPreferences? _prefs;
  final String _userId;

  HikerProfileDao get _profileDao => _db.hikerProfileDao;
  PastHikesDao get _pastHikesDao => _db.pastHikesDao;

  Future<SharedPreferences> get _preferences async =>
      _prefs ??= await SharedPreferences.getInstance();

  // --- Profil (fiche d'info) -----------------------------------------------

  /// Hydrate le profil depuis la SOURCE DURABLE (prefs) et met a jour le MIROIR
  /// Drift. Retourne le profil (vide si aucune fiche saisie).
  Future<HikerProfile> load() async {
    final prefs = await _preferences;
    final raw = prefs.getString(kHikerProfilePrefsKey);
    if (raw == null) return HikerProfile.empty;
    try {
      final profile =
          HikerProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
      await _mirrorProfileToDrift(profile);
      return profile;
    } catch (e) {
      _log.e('[HikerProfileRepository] Profil illisible: $e');
      return HikerProfile.empty;
    }
  }

  /// Relit le profil sans re-mirroring (raccourci lecture).
  Future<HikerProfile> getProfile() async {
    final prefs = await _preferences;
    final raw = prefs.getString(kHikerProfilePrefsKey);
    if (raw == null) return HikerProfile.empty;
    try {
      return HikerProfile.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return HikerProfile.empty;
    }
  }

  /// Sauvegarde le profil : prefs (source durable) ET Drift (miroir), avec
  /// `updatedAt` rafraichi. L'IMC n'est jamais persiste (getter calcule).
  Future<HikerProfile> saveProfile(HikerProfile profile) async {
    final stamped = profile.copyWith(updatedAt: DateTime.now());
    final prefs = await _preferences;
    await prefs.setString(kHikerProfilePrefsKey, json.encode(stamped.toJson()));
    await _mirrorProfileToDrift(stamped);
    _log.d('[HikerProfileRepository] Profil sauvegarde (IMC calcule local)');
    return stamped;
  }

  /// Supprime le profil (droit a l'effacement RGPD) : prefs ET Drift.
  ///
  /// PERIMETRE : la seule fiche d'info. Pour l'effacement TOTAL au titre de
  /// l'article 17 (randos, note d'experience et test de marche compris), c'est
  /// [eraseAllPersonalData] qu'il faut appeler.
  Future<void> deleteProfile() async {
    final prefs = await _preferences;
    await prefs.remove(kHikerProfilePrefsKey);
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
  /// CE QUI PART : les quatre cles de prefs (fiche, randos passees, note
  /// d'experience, resultat du test de marche 6 min) ET les trois tables Drift
  /// correspondantes pour cet utilisateur.
  ///
  /// A ne pas confondre avec [eraseMorphology] (retrait d'une CATEGORIE de
  /// donnees apres refus du consentement art. 9 : la fiche survit, videe de sa
  /// morphologie). Ici, plus rien ne survit.
  Future<void> eraseAllPersonalData() async {
    final prefs = await _preferences;
    // Etage 1 — source durable.
    await prefs.remove(kHikerProfilePrefsKey);
    await prefs.remove(kHikerPastHikesPrefsKey);
    await prefs.remove(kHikerExperienceNotePrefsKey);
    await prefs.remove(kWalkTestResultPrefsKey);
    // Etage 2 — miroir Drift.
    await _profileDao.deleteByUserId(_userId);
    await _pastHikesDao.deleteAllForUser(_userId);
    await _pastHikesDao.deleteNote(_userId);
    _log.d('[HikerProfileRepository] Fiche randonneur effacee (art. 17) : '
        'prefs ET miroir Drift');
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
  /// A ne pas confondre avec [deleteProfile] (effacement TOTAL, droit a
  /// l'effacement) : ici on retire une CATEGORIE de donnees, pas la fiche.
  Future<HikerProfile> eraseMorphology() async {
    final current = await getProfile();
    final erased = current.copyWith(
      age: 0,
      heightCm: 0,
      weightKg: 0,
      updatedAt: DateTime.now(),
    );
    final prefs = await _preferences;
    await prefs.setString(kHikerProfilePrefsKey, json.encode(erased.toJson()));
    await _mirrorProfileToDrift(erased);
    _log.d('[HikerProfileRepository] Morphologie effacee (consentement art. 9 '
        'refuse ou retire)');
    return erased;
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

  /// Charge les randos depuis les prefs (source durable) et met a jour Drift.
  /// Triees par date decroissante, plafonnees a [kMaxPastHikes].
  Future<List<PastHike>> loadPastHikes() async {
    final prefs = await _preferences;
    final raw = prefs.getString(kHikerPastHikesPrefsKey);
    if (raw == null) return const [];
    try {
      final list = (json.decode(raw) as List<dynamic>)
          .map((e) => PastHike.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final capped = list.take(kMaxPastHikes).toList();
      await _mirrorPastHikesToDrift(capped);
      return capped;
    } catch (e) {
      _log.e('[HikerProfileRepository] Randos illisibles: $e');
      return const [];
    }
  }

  /// Remplace la liste complete des randos (prefs + Drift), plafonnee a 5.
  ///
  /// L'ecran d'interview gere l'ajout/edition/suppression puis persiste la
  /// liste entiere — plus simple et sur que des ids Drift volatils.
  Future<List<PastHike>> savePastHikes(List<PastHike> hikes) async {
    final sorted = [...hikes]..sort((a, b) => b.date.compareTo(a.date));
    final capped = sorted.take(kMaxPastHikes).toList();
    final prefs = await _preferences;
    await prefs.setString(
      kHikerPastHikesPrefsKey,
      json.encode(capped.map((h) => h.toJson()).toList()),
    );
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

  // --- Note d'experience globale (texte libre) -----------------------------

  /// Relit la note d'experience globale (texte libre « difficultes »).
  Future<String> getExperienceNote() async {
    final prefs = await _preferences;
    return prefs.getString(kHikerExperienceNotePrefsKey) ?? '';
  }

  /// Sauvegarde la note d'experience globale (prefs + Drift). V1 : STOCKEE
  /// seulement (l'IA la lira en V2, envoi anonymise).
  Future<void> saveExperienceNote(String text) async {
    final prefs = await _preferences;
    await prefs.setString(kHikerExperienceNotePrefsKey, text);
    await _pastHikesDao.upsertNote(
      HikerExperienceNoteCompanion.insert(
        userId: _userId,
        freeTextDifficulties: Value(text),
        updatedAt: DateTime.now(),
      ),
    );
  }

  // --- Test de marche 6 minutes (dernier resultat date) --------------------

  /// Relit le dernier resultat du test 6 min, ou null si jamais fait
  /// (=> fallback auto-eval cote faisabilite).
  Future<WalkTestResult?> getWalkTestResult() async {
    final prefs = await _preferences;
    final raw = prefs.getString(kWalkTestResultPrefsKey);
    if (raw == null) return null;
    try {
      return WalkTestResult.fromJson(
          json.decode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.e('[HikerProfileRepository] Resultat test 6 min illisible: $e');
      return null;
    }
  }

  /// Enregistre le resultat du test 6 min (remplace le precedent : recurrent).
  Future<void> saveWalkTestResult(WalkTestResult result) async {
    final prefs = await _preferences;
    await prefs.setString(
        kWalkTestResultPrefsKey, json.encode(result.toJson()));
    _log.d('[HikerProfileRepository] Test 6 min: ${result.distanceMeters} m '
        '-> ${result.level}');
  }
}

/// Provider Riverpod du [HikerProfileRepository].
///
/// Branche sur la meme instance Drift que le reste de l'app
/// ([databaseProvider]). Convention identique au `walletStoreProvider`.
final hikerProfileRepositoryProvider =
    Provider<HikerProfileRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return HikerProfileRepository(db: db);
});
