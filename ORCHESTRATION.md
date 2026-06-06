# ORCHESTRATION MOTEUR-GR
Source de verite du progres. Skynet lit ce fichier EN PREMIER a chaque session.
MAJ: 06/06/2026 par Vulcain (Phase 2bis E2.10 upgrade deps — COMPLETE + preuves)

## Plan
V8 (index #82300 en memory.db). 130 sous-etapes, 32h, 158 tests.
3 couches QA: par commit (dart analyze+tests) / par sous-etape (Artemis) / par phase (build complet).
Design pipeline autonome: #81424 (valide Chris 25/05).
Specs V8: #82290 framework + #82293-#82299 par phase.

## Etat phases
Phase 0: 6/6 COMPLETE — mergee main 30/05 14:12. QA Artemis 6/6 PASS.
Phase 1: 3/3 COMPLETE — Riverpod 2→3, 14 enums→String, ref.watch select fix. Mergee 30/05.
Phase 2: 32/32 COMPLETE — merges 30/05 23:10. QA gate Artemis en attente.
Phase 2bis (E2.10 upgrade deps): 7/7 COMPLETE 06/06 — voir section dediee.
  freezed 3.2.5 + freezed_annotation 3.1.0 + slang/slang_flutter/slang_build_runner
  4.15.0. Preuves 06/06 : pub get OK, build_runner EXIT=0, analyze 0 issue,
  test 881/881 PASS. Branche claude/feat/E2.10-upgrade-deps, PAS DE MERGE (GO requis).
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
- QA : melos run analyze = No issues found (exit 0).
  melos run test = GREEN — 874 PASS / 0 FAIL (exit 0).
  Les 7 tests rouges de la sauvegarde 82e7c48 sont repares (tache GO-21, voir
  "Derniere action") : 1 correctif code de prod (trek_stats.eta) + 6 tests
  realignes sur le comportement legitime (aucun test skippe/desactive/supprime).

## Phase 2bis — E2.10 upgrade deps (specs V9 #82574-#82591) — COMPLETE 06/06
Historique : les 7 sous-etapes E2.10a-g avaient ete executees par une session
precedente et etaient DEJA dans l historique de main (entre Phase 2 et Phase 3),
sans que ce fichier soit mis a jour. Commits (identite Skynet — faute process,
regle "identite agent executant" non respectee, constat trace) :
- 635bc13 E2.10a chore(deps): upgrade freezed to v3
- bd46a8a E2.10b fix(models): corriger mixin DeltaUpdate tronque
- 82d6eab E2.10c chore(deps): upgrade slang to v4
- 9fa6f1b E2.10d chore(deps): pub get apres upgrade freezed+slang
- 7666c99 E2.10e chore(codegen): regenerer fichiers apres upgrade freezed v3 + slang v4
- bee60da E2.10f fix(models): abstract classes + slang v4 regen + test fixes
- 36fa45c E2.10g chore(i18n): nettoyer doublon strings.g.dart (INCOMPLET : imports
  migres + test ajoute, mais lib/gen/strings*.g.dart jamais supprimes)
Achevement par Vulcain 06/06, branche claude/feat/E2.10-upgrade-deps :
- bda2435 chore(i18n): E2.10g — supprimer le doublon lib/gen et fiabiliser la
  generation slang. Cause racine : slang_build_runner ne lit pas slang.yaml
  (defauts en/lib/gen a chaque build) ; de plus PostProcessBuilder incompatible
  build_runner 2.15 sur sortie importee (InvalidOutputException, pas de fix amont).
  => slang_build_runner desactive (build.yaml, documente), generation i18n par
  `dart run slang` (config unique slang.yaml, base fr). lib/gen supprime.
Preuves 06/06 (transcript Vulcain) : flutter pub get sans conflit ;
dart run build_runner build EXIT=0 (966 outputs, freezed/json/drift regeneres) ;
dart run slang OK (1695 strings, 5 locales, base fr) ; flutter analyze
"No issues found!" ; flutter test 881/881 "All tests passed!" (0 skip, 0 supprime).
Branche claude/feat/E2.10-upgrade-deps = main + bda2435 + MAJ orchestration.
PAS DE MERGE MAIN sans GO Chris.

## Branches en attente
claude/feat/E2.10-upgrade-deps — achevement Phase 2bis (E2.10g + orchestration),
  attend QA Artemis + GO Chris.
claude/fix/E5-decontamination-gr20 — reprise Phase 5 ; constat git 06/06 :
  DEJA MERGEE sur main (90e75c2) ainsi que la reparation des 7 tests (c5e1981
  inclut ebde305). Statut GO/QA a confirmer par Skynet/Chris.

## Prochaine action
1. QA gate Artemis sur claude/feat/E2.10-upgrade-deps (Phase 2bis E2.10,
   gates #82590/#82591 — corriger le chemin GR20 -> Moteur-GR signale #82599).
2. GO Chris pour merge de claude/feat/E2.10-upgrade-deps.
3. QA gate Artemis Phase 2 (toujours en attente) → Phase 3.

## Derniere action
06/06 (Phase 2bis) : achevement E2.10 par Vulcain — doublon i18n lib/gen reellement
supprime (cause racine slang_build_runner documentee dans build.yaml), regen
complete, preuves pub get / build_runner / analyze / test 881 PASS affichees,
ORCHESTRATION resynchronise (la Phase 2bis etait faite mais jamais reportee ici).
06/06 : Decontamination GR20 + reprise R1.9/R1.10/R1.11 par Vulcain (tache #320).
Audit de reference : #85296-#85298 (Artemis, tache #319).
06/06 (GO-21) : reparation des 7 tests rouges de la sauvegarde 82e7c48 par Vulcain.
Cause racine et correctif de chacun :
1-2. app_router_test : assertions obsoletes (4 routes attendues) — le routeur a
     legitimement 13 routes de 1er niveau depuis les features E5.x. Tests realignes
     (13 routes, chemins + noms exacts). La decontamination n'avait touche que des
     commentaires de app_router.dart (PGHM → secours regionaux).
3.   tip_card_json (scope neige) : la decontamination a volontairement passe les
     fiches neige de scope "gr20" a "all" (generique, cible par altitude >= 1500 m).
     Test realigne sur le nouveau contrat (scope = all).
4.   trek_stats (pauseCount) : fixture incoherente — points espaces de 10 min alors
     que le seuil de pause est 5 min, d'ou 5 pauses au lieu d'1. Fixture refaite
     (segments 250 m / 4 min actifs, un seul gap de 40 min) + assertions recalculees.
     Le code de prod (seuil 5 min documente) etait correct.
5.   trek_stats (ETA distance depassee) : VRAI BUG DE PROD. Le getter eta retournait
     null quand la vitesse moyenne valait 0, AVANT de tester la distance restante.
     Corrige : si distance totale atteinte/depassee -> Duration.zero d'abord.
6.   booking_deeplinks ("Site web") : le libelle apparait 2x par design (ligne
     "Informations pratiques" + bouton CTA "Reserver"). Assertion -> findsNWidgets(2).
7.   stage_detail_screen ("Col de Vergio") : le nom apparait 2x par design (titre
     AppBar + en-tete du corps). Assertion -> findsNWidgets(2).
Resultat : melos run test 874/0, melos run analyze 0 issue. Aucun test desactive.

## Regles
- Skynet ne code PAS — delegue a Vulcain (dev) / Artemis (QA)
- Prompts = copie exacte du plan V8, pas d'improvisation
- Lire fiche Moteur-GR #81413 AVANT chaque prompt agent
- QA par commit + par sous-etape + par phase
- Ce fichier = source de verite, mis a jour apres CHAQUE etape
- Rien hors plan — si pas dans les taches, demander a Chris
- Commits agents : identite git de l'agent executant (Vulcain pour le dev), JAMAIS Skynet
