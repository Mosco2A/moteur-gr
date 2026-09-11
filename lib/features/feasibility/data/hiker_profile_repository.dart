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
  Future<void> deleteProfile() async {
    final prefs = await _preferences;
    await prefs.remove(kHikerProfilePrefsKey);
    await _profileDao.deleteByUserId(_userId);
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
