# ORCHESTRATION MOTEUR-GR
Source de verite du progres. Skynet lit ce fichier EN PREMIER a chaque session.
MAJ: 06/06/2026 par Vulcain (tache #320 — decontamination Phase 5)

## Plan
V8 (index #82300 en memory.db). 130 sous-etapes, 32h, 158 tests.
3 couches QA: par commit (dart analyze+tests) / par sous-etape (Artemis) / par phase (build complet).
Design pipeline autonome: #81424 (valide Chris 25/05).
Specs V8: #82290 framework + #82293-#82299 par phase.

## Etat phases
Phase 0: 6/6 COMPLETE — mergee main 30/05 14:12. QA Artemis 6/6 PASS.
Phase 1: 3/3 COMPLETE — Riverpod 2→3, 14 enums→String, ref.watch select fix. Mergee 30/05.
Phase 2: 32/32 COMPLETE — merges 30/05 23:10. QA gate Artemis en attente.
Phase 3: commits presents, NON VALIDES (depend Phase 2)
Phase 4: commits presents, NON VALIDES (depend Phase 3)
Phase 5: lots E5.x MERGES SUR MAIN (historique : commits faits par Skynet,
  faute de process #85294/#85296) puis AUDIT Artemis #85296-#85298 :
  R1.8 CONFORME / R1.9 ECART MINEUR / R1.10 A REFAIRE / R1.11 A REFAIRE
  + contamination GR20 shippee (PGHM, "Secours GR20", trail_accommodations).
  → DECONTAMINATION + REPRISE faites par Vulcain 06/06 (tache #320),
    branche claude/fix/E5-decontamination-gr20, EN ATTENTE QA Artemis + GO Chris.
    PAS DE MERGE MAIN sans GO.

## Reprise Phase 5 — contenu branche claude/fix/E5-decontamination-gr20 (06/06)
- P0 contamination : "Secours GR20" → trailName injecte (TrailConfig) ;
  PGHM Corse hardcode supprime → TrailConfig.emergencyNumbers (par sentier, 112 universel) ;
  trail_accommodations.dart + trail_refuges.dart (donnees GR20 en masse) SUPPRIMES du moteur ;
  refuge_detail_screen reecrit sur canal DB generique (TrailDataProvider.getAccommodations par trailId) ;
  seeder renomme TrailSeeder (generique, JSON assets par sentier) ;
  SeedDataLoader parametre par TrailConfig (seedAssetsBase/tipAssetPaths, zero sentier en dur) ;
  booking_data_service : Hive (stack GR20) → SharedPreferences ;
  assets tips/checklist purges (contenu Corse → generique) ;
  bug unicode notif lockscreen corrige. Grep gr20/corse/pghm/mare-a-mare sur lib+android+ios+assets : 0.
- P1 R1.10 : widget Android REELLEMENT cable (layout widget_trek_progress.xml,
  config widget_trek_info.xml, RemoteViews, receiver declare AndroidManifest) ;
  widget iOS : target Xcode TrekWidgetExtension (pbxproj), @main WidgetBundle,
  App Group + entitlements, couleur fond parametree par theme (plus de #2D5016).
- P2 tests : VRAIS tests R1.8/R1.9/R1.10/R1.11 (SharedPreferences.setMockInitialValues,
  services instancies, round-trip ecrit→lu, notif sante + GPS MAJ, contrat cles Dart↔natif,
  declaration manifest/pbxproj verifiee). Fixtures 100% neutres (Sentier des Volcans fictif).
  + reparation des tests legacy casses par la migration enum→String de Phase 1
  (cloud_sync, delta_update, manifest, sync_scheduler, trail_download, offline_map,
  track_position, tracking, catalog, trail_catalog_card, booking, checklist,
  download_reminder, background_gps, seed_data_loader).
- P3 framework : EmergencyContact + HealthInfo migres Freezed (#82290) ;
  StageAccommodation (nouveau modele Freezed) ; services branches providers
  (emergencyContactsServiceProvider via TrailConfig, lockscreenWidgetServiceProvider,
  demoModeServiceProvider, widgetDataServiceProvider) ; TrekRecorder.onFlush
  → WidgetDataService (MAJ widget a chaque flush, E5.19a).
- Reparations annexes : table HealthInfoEntries enregistree en base (migration v11,
  E5.16 inacheve) ; in_app_review version corrigee (^2.0.12, ^6 n'existait pas) ;
  melos installe en dev_dependency (scripts melos.yaml desormais executables) ;
  exclusions analyzer (data/, build/, .claude/).
- QA : melos run analyze = No issues found (exit 0). melos run test = voir gate.

## Branches en attente
claude/fix/E5-decontamination-gr20 — reprise Phase 5 complete, attend QA Artemis + GO Chris.

## Prochaine action
1. QA gate Artemis sur claude/fix/E5-decontamination-gr20 (re-audit R1.9/R1.10/R1.11).
2. GO Chris pour merge main.
3. Puis reprendre le fil normal : Phase 2bis (upgrade deps freezed v3 + slang v4,
   specs V9 #82574-82591) → QA gate Phase 2 → Phase 3.

## Derniere action
06/06 : Decontamination GR20 + reprise R1.9/R1.10/R1.11 par Vulcain (tache #320).
Audit de reference : #85296-#85298 (Artemis, tache #319).

## Regles
- Skynet ne code PAS — delegue a Vulcain (dev) / Artemis (QA)
- Prompts = copie exacte du plan V8, pas d'improvisation
- Lire fiche Moteur-GR #81413 AVANT chaque prompt agent
- QA par commit + par sous-etape + par phase
- Ce fichier = source de verite, mis a jour apres CHAQUE etape
- Rien hors plan — si pas dans les taches, demander a Chris
- Commits agents : identite git de l'agent executant (Vulcain pour le dev), JAMAIS Skynet
