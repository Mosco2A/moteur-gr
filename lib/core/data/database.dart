import 'package:drift/drift.dart';

// Le convertisseur d horodatage est utilise par le code GENERE (`database.g.dart`
// est un `part` de ce fichier) : sans cet import, `HorodatageServeur` serait un
// type inconnu dans la partie generee.
import 'revision_de_donnee.dart';
import 'tables/stages_table.dart';
import 'tables/pois_table.dart';
import 'tables/user_progress_table.dart';
import 'tables/checklist_items_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/weather_cache_table.dart';
import 'tables/feedback_queue_table.dart';
import 'tables/trail_meta_table.dart';
import 'tables/trail_itineraries_table.dart';
import 'tables/trail_stages_table.dart';
import 'tables/trail_accommodations_table.dart';
import 'tables/trail_pois_table.dart';
import 'tables/trail_gpx_tracks_table.dart';
import 'tables/trail_gpx_points_table.dart';
import 'tables/trail_manifests_table.dart';
import 'tables/sync_queue_table.dart';
import 'tables/review_requests_table.dart';
import 'tables/health_info_table.dart';
import 'tables/follow_sessions_table.dart';
import 'tables/follower_slots_table.dart';
import 'tables/session_track_points_table.dart';
import 'tables/report_local_table.dart';
import 'tables/segments_table.dart';
import 'tables/kudos_feed_table.dart';
import 'tables/waypoints_table.dart';
import 'tables/trek_sessions_table.dart';
import 'tables/nuitee_selections_table.dart';
import 'tables/wallet_balance_table.dart';
import 'tables/trek_entitlements_table.dart';
import 'tables/no_ads_state_table.dart';
import 'tables/hiker_profile_table.dart';
import 'tables/past_hikes_table.dart';
import 'daos/stages_dao.dart';
import 'daos/pois_dao.dart';
import 'daos/progress_dao.dart';
import 'daos/checklist_dao.dart';
import 'daos/journal_dao.dart';
import 'daos/weather_cache_dao.dart';
import 'daos/feedback_queue_dao.dart';
import 'daos/trail_meta_dao.dart';
import 'daos/trail_itineraries_dao.dart';
import 'daos/trail_stages_dao.dart';
import 'daos/trail_accommodations_dao.dart';
import 'daos/trail_pois_dao.dart';
import 'daos/trail_gpx_tracks_dao.dart';
import 'daos/trail_gpx_points_dao.dart';
import 'daos/trail_manifests_dao.dart';
import 'daos/sync_queue_dao.dart';
import 'daos/review_requests_dao.dart';
import 'daos/health_info_dao.dart';
import 'daos/follow_sessions_dao.dart';
import 'daos/follower_slots_dao.dart';
import 'daos/session_track_points_dao.dart';
import 'daos/report_local_dao.dart';
import 'daos/segments_dao.dart';
import 'daos/kudos_feed_dao.dart';
import 'daos/waypoints_dao.dart';
import 'daos/trek_sessions_dao.dart';
import 'daos/nuitee_selections_dao.dart';
import 'daos/wallet_dao.dart';
import 'daos/trek_entitlements_dao.dart';
import 'daos/no_ads_dao.dart';
import 'daos/hiker_profile_dao.dart';
import 'daos/past_hikes_dao.dart';

part 'database.g.dart';

/// Base de donnees locale du Moteur GR.
///
/// 17 tables : 7 existantes (Stages, Pois, UserProgressEntries,
/// ChecklistItems, JournalEntries, WeatherCache, FeedbackQueue)
/// + 7 Phase 4 (TrailMeta, TrailItineraries, TrailStages,
/// TrailAccommodations, TrailPois, TrailGpxTracks, TrailGpxPoints)
/// + 1 Phase 4 E4.3 (TrailManifests)
/// + 1 Phase 4 E4.4 (SyncQueue)
/// + 1 Phase 5 E5.17 (ReviewRequests)
/// + 1 Phase 5 E5.16 (HealthInfoEntries)
/// + 2 Phase 4 E4.10 (FollowSessions, FollowerSlots)
/// + 1 finitions V8 F3 (SessionTrackPoints ; granularite session/jour/etape
///   ajoutee par StepWays LOT L3-1, migration v26)
/// + 1 Phase 6 F6C-01 (ReportLocal, signalements offline-first)
/// + 2 Phase 7 F7A-01 (Segments, SegmentEffortLocal, social offline-first)
/// + 2 Phase 7 F7B-01 (KudosLocal, ActivityFeedCache, kudos + fil offline)
/// + 2 Phase 8 F8A-01 (Waypoint, WaypointComment, terrain FarOut-like offline)
/// + 3 StepWays LOT 1 wallet (WalletBalance, TrekEntitlements, NoAdsState,
///   socle compte-etapes/abo/sans-pub, migration v24).
/// Utilise Drift (ex-moor) pour le mapping SQLite.
@DriftDatabase(
  tables: [
    Stages,
    Pois,
    UserProgressEntries,
    ChecklistItems,
    JournalEntries,
    WeatherCache,
    FeedbackQueue,
    TrailMeta,
    TrailItineraries,
    TrailStages,
    TrailAccommodations,
    TrailPois,
    TrailGpxTracks,
    TrailGpxPoints,
    TrailManifests,
    SyncQueue,
    ReviewRequests,
    HealthInfoEntries,
    FollowSessions,
    FollowerSlots,
    SessionTrackPoints,
    ReportLocal,
    Segments,
    SegmentEffortLocal,
    KudosLocal,
    ActivityFeedCache,
    Waypoint,
    WaypointComment,
    TrekSessions,
    NuiteeSelections,
    WalletBalance,
    TrekEntitlements,
    NoAdsState,
    HikerProfile,
    PastHikeEntries,
    HikerExperienceNote,
  ],
  daos: [
    StagesDao,
    PoisDao,
    ProgressDao,
    ChecklistDao,
    JournalDao,
    WeatherCacheDao,
    FeedbackQueueDao,
    TrailMetaDao,
    TrailItinerariesDao,
    TrailStagesDao,
    TrailAccommodationsDao,
    TrailPoisDao,
    TrailGpxTracksDao,
    TrailGpxPointsDao,
    TrailManifestsDao,
    SyncQueueDao,
    ReviewRequestsDao,
    HealthInfoDao,
    FollowSessionsDao,
    FollowerSlotsDao,
    SessionTrackPointsDao,
    ReportLocalDao,
    SegmentsDao,
    KudosFeedDao,
    WaypointsDao,
    TrekSessionsDao,
    NuiteeSelectionsDao,
    WalletDao,
    TrekEntitlementsDao,
    NoAdsDao,
    HikerProfileDao,
    PastHikesDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 29;

  /// LA SEQUENCE DE MIGRATIONS N'AVAIT JAMAIS TOURNE SUR UN TELEPHONE (tache 613).
  ///
  /// Ces vingt-sept marches existaient et etaient testees une par une, mais la
  /// base etait ouverte EN MEMOIRE (`database_provider.dart`) : il n'y avait
  /// jamais de fichier a migrer. A chaque lancement, Drift creait une base neuve
  /// au schema courant et `onUpgrade` n'etait pas appele. Depuis la tache 613 la
  /// base vit dans un fichier : ces marches vont VRAIMENT s'executer, sur le
  /// telephone d'un randonneur, a la premiere mise a jour de l'application.
  ///
  /// D'OU LA REGLE POSEE ICI, ET ELLE VAUT POUR TOUTE MIGRATION FUTURE : tout
  /// ajout de colonne passe par [_ajouterColonneSiAbsente]. `ALTER TABLE ADD
  /// COLUMN` echoue sur une colonne deja presente, et UNE MIGRATION QUI ECHOUE
  /// EMPECHE LA BASE DE S'OUVRIR — l'application ne demarre plus, sans recours.
  /// Le cas n'est pas theorique : si l'application est tuee au milieu d'une
  /// marche, `user_version` reste en arriere et la marche se rejoue sur des
  /// colonnes deja posees. La v27 s'etait deja protegee ainsi ; les vingt-six
  /// autres ne l'etaient pas, et elles le sont depuis la tache 613.
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (migrator, from, to) async {
          // Migration v1 -> v2 : ajout colonne totalTimeMinutes
          if (from < 2) {
            await _ajouterColonneSiAbsente(
              migrator,
              userProgressEntries,
              userProgressEntries.totalTimeMinutes,
            );
          }
          // Migration v2 -> v3 : creation table journal_entries (E3.1)
          if (from < 3) {
            await migrator.createTable(journalEntries);
          }
          // Migration v3 -> v4 : creation table checklist_items (E3.2)
          if (from < 4) {
            await migrator.createTable(checklistItems);
          }
          // Migration v4 -> v5 : creation table weather_cache (E3.5a)
          if (from < 5) {
            await migrator.createTable(weatherCache);
          }
          // Migration v5 -> v6 : creation table feedback_queue (E3.10)
          if (from < 6) {
            await migrator.createTable(feedbackQueue);
          }
          // Migration v6 -> v7 : 7 tables donnees sentier (Phase 4 E4.2)
          if (from < 7) {
            await migrator.createTable(trailMeta);
            await migrator.createTable(trailItineraries);
            await migrator.createTable(trailStages);
            await migrator.createTable(trailAccommodations);
            await migrator.createTable(trailPois);
            await migrator.createTable(trailGpxTracks);
            await migrator.createTable(trailGpxPoints);
          }
          // Migration v7 -> v8 : table manifeste sentier (Phase 4 E4.3)
          if (from < 8) {
            await migrator.createTable(trailManifests);
          }
          // Migration v8 -> v9 : table sync_queue (Phase 4 E4.4)
          if (from < 9) {
            await migrator.createTable(syncQueue);
          }
          // Migration v9 -> v10 : table review_requests (Phase 5 E5.17)
          if (from < 10) {
            await migrator.createTable(reviewRequests);
          }
          // Migration v10 -> v11 : table health_info (Phase 5 E5.16)
          if (from < 11) {
            await migrator.createTable(healthInfoEntries);
          }
          // Migration v11 -> v12 : tables suivi trekkeur (Phase 4 E4.10)
          if (from < 12) {
            await migrator.createTable(followSessions);
            await migrator.createTable(followerSlots);
          }
          // Migration v12 -> v13 : table session_track_points
          // (trace GPS reelle du recap diplome, finitions V8 F3)
          if (from < 13) {
            await migrator.createTable(sessionTrackPoints);
          }
          // Migration v13 -> v14 : table report_local
          // (signalements terrain offline-first, Phase 6 F6C-01)
          if (from < 14) {
            await migrator.createTable(reportLocal);
          }
          // Migration v14 -> v15 : tables segments + efforts (Phase 7 F7A-01)
          // (segments comparables + file d'efforts offline-first)
          if (from < 15) {
            await migrator.createTable(segments);
            await migrator.createTable(segmentEffortLocal);
          }
          // Migration v15 -> v16 : tables kudos + fil d'activite (Phase 7 F7B-01)
          // (kudos offline-first + cache du fil avec moderationState DSA)
          if (from < 16) {
            await migrator.createTable(kudosLocal);
            await migrator.createTable(activityFeedCache);
          }
          // Migration v16 -> v17 : tables waypoint + commentaire (Phase 8 F8A-01)
          // (points terrain FarOut-like + commentaires offline-first, DSA)
          if (from < 17) {
            await migrator.createTable(waypoint);
            await migrator.createTable(waypointComment);
          }
          // Migration v17 -> v18 : table trek_sessions (PARITE GR20, LOT 2)
          // (persistance locale de la session + memoire du finisher :
          // completedStages/parcoursFullyWalked survivent au redemarrage)
          if (from < 18) {
            await migrator.createTable(trekSessions);
          }
          // Migration v18 -> v19 : colonne weightGrams sur checklist_items
          // (PARITE GR20 « Materiel & Sac » : poids par article + total).
          if (from < 19) {
            await _ajouterColonneSiAbsente(
              migrator,
              checklistItems,
              checklistItems.weightGrams,
            );
          }
          // Migration v19 -> v20 : parite GR20 « Materiel & Sac » — clone
          // integral (quantite par article, articles personnalises, liste de
          // courses, nom custom) sur checklist_items.
          if (from < 20) {
            await _ajouterColonneSiAbsente(
              migrator,
              checklistItems,
              checklistItems.quantity,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              checklistItems,
              checklistItems.isCustom,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              checklistItems,
              checklistItems.inShoppingList,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              checklistItems,
              checklistItems.customName,
            );
          }
          // Migration v20 -> v21 : parite GR20 « socle donnees » — colonne
          // estimatedDurationMinutes (nullable) sur stages. Champ riche par
          // etape (duree estimee) alimente par les donnees du sentier
          // (stages.json, backend P4), affiche sur Itineraire et Programme.
          if (from < 21) {
            await _ajouterColonneSiAbsente(
              migrator,
              stages,
              stages.estimatedDurationMinutes,
            );
          }
          // Migration v21 -> v22 : parite GR20 « Reserver vos nuits » — table
          // nuitee_selections (etat par nuit du PROGRAMME : type de nuitee +
          // reserve). Persistance 100 % locale (pas de Firebase avant Phase 4).
          if (from < 22) {
            await migrator.createTable(nuiteeSelections);
          }
          // Migration v22 -> v23 : parite GR20 « socle donnees » — colonnes
          // departureName / arrivalName (nullable) sur stages. Noms des points
          // de depart/arrivee par etape, alimentes par les donnees du sentier
          // (stages.json, backend P4), affiches sur la sous-ligne « Depart ->
          // Arrivee » de la fiche etape.
          if (from < 23) {
            await _ajouterColonneSiAbsente(
              migrator,
              stages,
              stages.departureName,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              stages,
              stages.arrivalName,
            );
          }
          // Migration v23 -> v24 : socle wallet StepWays (LOT 1, compte-etapes).
          // STRICTEMENT ADDITIF (createTable only) : 3 nouvelles tables, aucune
          // table/colonne existante touchee. Le legacy (2 cles prefs d'achats)
          // est migre en RUNTIME (couche WalletStore/MonetizationService), pas
          // ici en SQL.
          if (from < 24) {
            await migrator.createTable(walletBalance);
            await migrator.createTable(trekEntitlements);
            await migrator.createTable(noAdsState);
          }
          // Migration v24 -> v25 : socle faisabilite StepWays (LOT 4).
          // STRICTEMENT ADDITIF (createTable only) : 3 nouvelles tables
          // (profil randonneur SENSIBLE + randos passees + note d'experience
          // globale), aucune table/colonne existante touchee. Donnees local
          // durable (prefs) + miroir cloud anonyme (hash), zero nominatif.
          if (from < 25) {
            await migrator.createTable(hikerProfile);
            await migrator.createTable(pastHikeEntries);
            await migrator.createTable(hikerExperienceNote);
          }
          // Migration v25 -> v26 : socle de la trace GPS StepWays (LOT L3-1).
          // STRICTEMENT ADDITIF (addColumn only, 3 colonnes NULLABLES sur
          // session_track_points) : sessionId, dayIndex, stageId. Donne au
          // trace la granularite par session, par jour de marche et par
          // etape ; les points anterieurs restent lisibles (colonnes nulles).
          // C'est ce qui permet d'arreter d'EFFACER le trace precedent au
          // demarrage d'une nouvelle randonnee.
          if (from < 26) {
            await _ajouterColonneSiAbsente(
              migrator,
              sessionTrackPoints,
              sessionTrackPoints.sessionId,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              sessionTrackPoints,
              sessionTrackPoints.dayIndex,
            );
            await _ajouterColonneSiAbsente(
              migrator,
              sessionTrackPoints,
              sessionTrackPoints.stageId,
            );
          }
          // Migration v26 -> v27 : LE CATALOGUE DISTANT, ET LA REVISION PORTEE
          // PAR CHAQUE DONNEE (StepWays tache 605, MUR N1 — decisions de
          // Christophe des 27/09 19:57, 20:11 et 20:43).
          //
          // STRICTEMENT ADDITIVE, ET CE N EST PAS UN HASARD MAIS UN CHOIX :
          // 8 colonnes NULLABLES ajoutees, aucune colonne existante touchee,
          // supprimee ni reinterpretee. CETTE MIGRATION NE CASSE RIEN — une base
          // en v26 monte en place, toutes ses lignes restent lisibles, et un
          // sentier deja copie garde sa version locale.
          //
          //  * `trail_manifests.ficheJson` conserve le dernier catalogue distant
          //    RECU. Sans lui, un sentier que le binaire ne connait pas
          //    disparaitrait de l ecran du randonneur des qu il perd le reseau.
          //
          //  * `rev` sur les SEPT tables telechargeables porte la revision de
          //    chaque enregistrement. L application demande « tout ce qui porte
          //    un numero plus recent que le mien » : une seule question, et une
          //    altitude corrigee fait redescendre UNE etape, pas sept tables.
          //
          // CE QUI A ETE ECARTE, ET POURQUOI. Une premiere version de ce lot
          // creait une table `trail_piece_versions` (une version locale par
          // famille de donnees). Elle est abandonnee sur la simplification de
          // Christophe du 27/09 20:43 : la version vit DANS la donnee, et le
          // telephone n a besoin que d UNE valeur par sentier — la revision
          // jusqu ou il est a jour, soit `trail_manifests.localVersion`, qui
          // existe deja. Une table en moins, un concept en moins.
          //
          // `localVersion` CHANGE DE METIER SANS CHANGER DE FORME : il est le
          // REPERE DE REVISION du sentier (« je suis a jour jusqu a N »), et il
          // est desormais REELLEMENT REECRIT apres une copie reussie — ce qui
          // etait precisement le defaut mesure : personne ne l ecrivait, alors
          // que `needsUpdate` s en sert pour decider, donc chaque ouverture
          // retelechargeait tout.
          if (from < 27) {
            await _ajouterColonneSiAbsente(
                migrator, trailManifests, trailManifests.ficheJson);
            await _ajouterColonneSiAbsente(migrator, trailMeta, trailMeta.rev);
            await _ajouterColonneSiAbsente(
                migrator, trailItineraries, trailItineraries.rev);
            await _ajouterColonneSiAbsente(
                migrator, trailStages, trailStages.rev);
            await _ajouterColonneSiAbsente(
                migrator, trailAccommodations, trailAccommodations.rev);
            await _ajouterColonneSiAbsente(migrator, trailPois, trailPois.rev);
            await _ajouterColonneSiAbsente(
                migrator, trailGpxTracks, trailGpxTracks.rev);
            await _ajouterColonneSiAbsente(
                migrator, trailGpxPoints, trailGpxPoints.rev);
          }
          // LA v28 PORTE DEUX CHANGEMENTS, ET C EST VOULU (tache 616). Les lots
          // 610 et 613 ont ete construits en PARALLELE depuis la 607, et chacun a
          // pose « sa » v28 de son cote : la fiche medicale qui quitte la base
          // (613) et la revision qui passe du numero a l horodatage (610). Les
          // reunir sous DEUX numeros de schema successifs serait une reecriture de
          // l histoire de l un des deux ; les reunir sous le MEME numero est exact,
          // parce qu aucun des deux n a ete publie : aucun telephone au monde ne
          // porte une base en v28 partielle. Les deux marches sont independantes
          // (tables disjointes) et idempotentes, donc leur ordre ici n a pas
          // d effet.
          if (from < 28) {
            await _v28FicheMedicaleQuitteLaBase();
            await _v28RevisionDevientHorodatage();
          }
          // Migration v28 -> v29 : LE NIVEAU DESCENDU SE NOTE A COTE DU REPERE
          // (tache 616). Une seule colonne, `trail_manifests.niveauLocal`, posee
          // par la precaution habituelle du depot : `ALTER TABLE ADD COLUMN`
          // echoue sur une colonne deja presente, et une migration qui echoue
          // EMPECHE LA BASE DE S OUVRIR sur le telephone d un randonneur.
          //
          // ELLE RESTE NULLE SUR LES BASES EXISTANTES, ET C EST LE BON DEFAUT :
          // la v28 vient de remettre tous les reperes a « rien de copie », donc
          // aucun sentier ne pretend avoir un niveau. Un niveau nul face a un
          // repere nul est coherent — le premier telechargement ecrira les deux
          // dans la meme transaction.
          if (from < 29) {
            await _ajouterColonneSiAbsente(
                migrator, trailManifests, trailManifests.niveauLocal);
          }
        },
      );

  /// Migration v27 -> v28 : LA FICHE MEDICALE QUITTE LA BASE (tache 613).
  ///
  /// Elle a desormais son propre fichier, sous le dossier declare exclu de
  /// la sauvegarde du telephone (`FicheMedicaleFichier`). LA RAISON N'EST
  /// PAS COSMETIQUE : depuis la tache 613 la base est DURABLE, et pour que
  /// la progression et le journal survivent au changement de telephone —
  /// ce que le modele economique promet A VIE — ce fichier doit remonter
  /// dans la sauvegarde. Or un fichier de base ne s'exclut pas table par
  /// table. Tant que `health_info_entries` y vivait, il fallait choisir
  /// entre sauvegarder la progression et proteger la donnee de sante.
  ///
  /// CETTE MARCHE VIDE LA TABLE, ET C'EST UNE PRECAUTION, PAS UNE
  /// MIGRATION DE DONNEES. Il n'y a rien a transporter : la base n'ayant
  /// jamais eu de fichier, aucune fiche n'a jamais survecu a une
  /// fermeture. Mais si un binaire intermediaire avait ecrit une ligne
  /// ici, elle se retrouverait dans un fichier desormais sauvegarde. On ne
  /// laisse pas ce hasard decider : la table est videe, une fois, a la
  /// montee. Elle reste dans le schema (la retirer demanderait une
  /// regeneration du code pour un gain nul) et PLUS AUCUN CODE DE
  /// PRODUCTION NE L'ECRIT — l'invariante de la tache 613 le verifie.
  Future<void> _v28FicheMedicaleQuitteLaBase() async {
    await customStatement('DELETE FROM health_info_entries');
  }

  /// Migration v27 -> v28 : LA SYNCHRONISATION PASSE DU NUMERO A
  /// L HORODATAGE (StepWays tache 610 — decision de Christophe du
  /// 28/09 09:32, verbatim : « Pas besoin d une version mais d un
  /// timestamp de donnees »).
  ///
  /// ELLE NE TOUCHE AUCUNE STRUCTURE : ZERO `ALTER TABLE`. Les colonnes
  /// `rev`, `dataVersion` et `localVersion` posees par la v27 sont deja des
  /// `INTEGER` ; on y range desormais des MILLISECONDES DEPUIS L EPOCH au
  /// lieu d un compteur. Le type SQL ne bouge pas, donc rien ne peut echouer
  /// — et une migration qui echoue EMPECHE LA BASE DE S OUVRIR sur le
  /// telephone d un randonneur, sans recours.
  ///
  /// CE QU ELLE CASSE, ET C EST LE SEUL POINT : LES ANCIENNES VALEURS N ONT
  /// PLUS DE SENS. Un `localVersion` a 3 lu comme un instant designe le
  /// 1er janvier 1970. On ne le laisse PAS s interpreter tout seul : toutes
  /// les valeurs de l ancien modele sont remises a zero, explicitement.
  ///
  /// CONSEQUENCE POUR UN RANDONNEUR QUI A DEJA UN SENTIER SUR SON
  /// TELEPHONE : son repere retombe a « rien de copie », donc la prochaine
  /// synchronisation refait UNE copie complete de ce sentier — par le chemin
  /// normal, transactionnel, sans rien effacer d abord puisque la pose
  /// remplace enregistrement par enregistrement. Il paie un telechargement,
  /// UNE fois, et repart avec un repere juste. L ERREUR INVERSE ETAIT
  /// INACCEPTABLE : un repere conserve et mal interprete aurait pu se
  /// retrouver DANS LE FUTUR des donnees publiees, et le telephone aurait
  /// rate pour toujours tout ce qui arrive ensuite, en se croyant a jour.
  ///
  /// POURQUOI LA v28 EST REJOUABLE SANS DOMMAGE. Les tests de migration du
  /// depot rembobinent `user_version` sur une base creee au schema courant,
  /// puis rouvrent. Un `UPDATE` idempotent supporte ce traitement, la ou un
  /// `ALTER TABLE` echouerait — c est la fragilite que la v27 avait fait
  /// sortir, et cette migration ne la reveille pas.
  Future<void> _v28RevisionDevientHorodatage() async {
    await customStatement(
      'UPDATE trail_manifests SET data_version = 0, local_version = NULL',
    );
    await customStatement('UPDATE trail_meta SET data_version = 0');
    for (final table in const [
      'trail_meta',
      'trail_itineraries',
      'trail_stages',
      'trail_accommodations',
      'trail_pois',
      'trail_gpx_tracks',
      'trail_gpx_points',
    ]) {
      await customStatement('UPDATE $table SET rev = NULL');
    }
  }

  /// Ajoute une colonne SEULEMENT si la table ne la porte pas deja.
  ///
  /// POURQUOI CETTE PRECAUTION, ET ELLE N EST PAS COSMETIQUE. `ALTER TABLE ADD
  /// COLUMN` echoue sur une colonne existante (« duplicate column name »), et une
  /// migration qui echoue EMPECHE LA BASE DE S OUVRIR — l application ne demarre
  /// plus, sur le telephone d un randonneur, sans recours. Deux situations
  /// reelles y menent :
  ///
  ///  1. UNE MIGRATION INTERROMPUE. Si l application est tuee au milieu des huit
  ///     ajouts de la v27, `user_version` reste a 26 : la prochaine ouverture
  ///     rejoue la v27 et butte sur les colonnes deja posees.
  ///
  ///  2. UNE BASE AU SCHEMA COURANT REMBOBINEE. C est exactement ce que font les
  ///     tests de migration du depot (`migration_v23_to_v24_test` et suivants) :
  ///     ils creent la base au schema courant, ramenent `user_version` en
  ///     arriere, puis rouvrent. Les migrations precedentes ne s en apercevaient
  ///     pas parce qu elles creaient des TABLES (`createTable` est tolerant) ou
  ///     ne touchaient qu une table que le test recreait lui-meme dans sa forme
  ///     d origine. La v27 est la premiere a ajouter des colonnes a SEPT tables
  ///     que ces tests ne reconstruisent pas : elle a donc rendu visible une
  ///     fragilite qui existait deja.
  ///
  /// La verification passe par `PRAGMA table_info`, la seule source fiable de ce
  /// que la table porte VRAIMENT — et non de ce que le code croit qu elle porte.
  Future<void> _ajouterColonneSiAbsente(
    Migrator migrator,
    TableInfo<Table, dynamic> table,
    GeneratedColumn<Object> colonne,
  ) async {
    final infos =
        await customSelect('PRAGMA table_info(${table.actualTableName})').get();
    final presentes = infos.map((r) => r.read<String>('name')).toSet();
    if (presentes.contains(colonne.name)) return;
    await migrator.addColumn(table, colonne);
  }
}