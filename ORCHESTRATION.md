# ORCHESTRATION MOTEUR-GR
Source de verite du progres. Skynet lit ce fichier EN PREMIER a chaque session.
MAJ: 08/06/2026 par Vulcain (lot E5 CONSOLIDATION polish UX + docs + securite — COMPLETE, branche claude/feat/E5-consolidation-polish-docs-security, EN ATTENTE gate Artemis + GO)

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
Phase 3: commits presents, NON VALIDES (depend Phase 2). Gate Artemis #85352 VERTE.
Phase 4: serie coarse E4.1-E4.12 sur main, gate Artemis #85353 VERTE.
  Bloc dormant E4.10-E4.17 (suivi/auth/sync/monetisation, reserve R-P4.3
  de la gate #85353) REINTEGRE 06/06 par Vulcain — voir section dediee.
  Branche claude/feat/E4.10-17-reintegration, PAS DE MERGE (GO requis).
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

## Lot E5 SOCLES — perf/a11y/analytics (reintegration PROPRE, 07/06, Vulcain)
Source : inventaire #85410-#85412 + plan V10 #83558-#83559. METHODE : reecriture
propre depuis le plan, AUCUN cherry-pick des 17 branches stranded (pre-decontamination
+ pre-Freezed v3). Branche NEUVE claude/feat/E5-socles-perf-a11y-analytics depuis
main (4153dc5). Stack reelle respectee : Riverpod 2.6.1, Freezed 3.2.5, Slang 4.15,
flutter_map 8.2, geolocator 11. applicationId/namespace com.only1cent.moteur_gr.
1 commit conventionnel par sous-lot, identite Vulcain.

- E5.2a perf carte (3b2a8c8) COMPLETE : nouveau marker_cluster.dart (clustering par
  grille spatiale O(n), seuil 50, ClusteredMarkerLayer bulles+tap) ; Douglas-Peucker
  DYNAMIQUE (dynamicEpsilonForZoom continu par niveau, remplace les paliers discrets
  de simplified_track_provider) ; RepaintBoundary sur les layers statiques (trace +
  marqueurs) de map_screen ET trail_map_screen ; POIs clusterises en couche dediee,
  position user isolee en couche dynamique. Test benchmark : 100 marqueurs clusterises
  < 16 ms + correction algo + integration flutter_map (13 tests).
- E5.2b perf GPS (7b5e996) COMPLETE : gps_service desiredAccuracy ADAPTATIVE (high en
  mouvement / low au repos) via classifyMovement (fonction pure, hysteresis 0.4/1.0 m/s)
  + re-souscription au changement de regime ; distanceFilter 10 m et handleError
  conserves ; injection testable du constructeur intacte ; demarre au repos (batterie,
  compat stream finis). LazyNetworkImage (shared/widgets) : CachedNetworkImage +
  placeholder statique + fallback, null/vide-safe (dep deja presente) ; cable en photo
  optionnelle du POI sheet. Tests : classifieur hysteresis + switch end-to-end
  mouvement/repos + primitive lazy (10+8 tests).
- E5.3 a11y (92c1845) COMPLETE — E5.3a+E5.3b reunis (overlap fichiers map_controls/
  catalogue/detail inseparable) :
  * E5.3a contraste+labels : main avait 0 Semantics. Section i18n a11y (5 langues) ;
    Semantics ajoutes (controles carte tooltips Slang, bouton retour, marqueurs
    etape/POI/position button|image+label, bulle cluster, tuiles stats suivi) ;
    ExcludeSemantics sur les decors. WcagContrast (core/a11y) : luminance+ratio+seuils
    AA/AA-large/non-text. AppTheme.grisTexteSecondaire (token texte secondaire conforme
    AA sur fond SOMBRE ; grisGranite ~2.6:1 echoue mais conserve pour fonds clairs type
    share card). Test audit : valeurs WCAG de reference + audit theme sombre + labels
    5 langues (10 tests).
  * E5.3b nav+texte : FocusTraversalGroup + OrderedTraversalPolicy + NumericFocusOrder
    sur les controles carte (ordre zoom+ -> zoom- -> centrer) ; support textScale 2x
    sans overflow (catalogue infos secondaires en Wrap + titre borne + badge Flexible/
    ellipsis ; en-tete detail chips en Wrap). Tests focus + overflow 2x (5 tests).
- E5.4 analytics ANONYME (3a55c98) COMPLETE : deps firebase_analytics ^11.6.0 +
  firebase_crashlytics ^4.3.10 (compat firebase_core 3.x). AnalyticsService
  (core/analytics) : logScreenView + 5 events (trail_downloaded/trek_started/
  trek_completed/share_card/diploma_generated) + Crashlytics fatals+non-fatals.
  ZERO-PII STRICT : aucun nom/email/uid/GPS en clair, tout identifiant = SHA-256
  (crypto), pas de fingerprinting (distance/duree arrondies), API typee inviolable.
  Gating isFirebaseAvailableProvider : indisponible => no-op zero crash. OPT-IN :
  collecte coupee par defaut (setAnalyticsCollectionEnabled(false)), rien emis tant
  que setConsent(granted:true) non appele. Puits abstraits + NoOp + impl Firebase
  isolee (testabilite). Tests (suivent degraded_mode_test) : no-op si indisponible,
  event correct si dispo, assert zero-PII sur les 5 events, opt-in, SHA-256 (8 tests).

PREUVES 07/06 (transcript Vulcain, affichees) : flutter analyze = "No issues found!"
(projet entier, 53 s) ; flutter test = 1012 PASS / 0 FAIL / 0 SKIP (base 962 + 50
nouveaux tests des 3 sous-lots, AUCUN test supprime ni skippe) ; grep -riE
fralimonti|gr20|corse|mare.a.mare sur les 37 fichiers touches = 1 seul hit JUSTIFIE
(pubspec.yaml ligne asset assets/data/mare_a_mare_centre/ = sentier reel parametrique
pre-existant, valide gate #85353, simplement decale par l'ajout des deps Firebase ;
0 hit dans tout le code lib/test/i18n ecrit). 4 commits conventionnels 3b2a8c8..3a55c98.
PAS DE MERGE MAIN sans GO.

GATE QA ARTEMIS 08/06 (#85426) — VERDICT : GATE VERTE (PASS). Preuves RE-EXECUTEES
independamment (pas sur parole du dev) : flutter analyze projet entier = "No issues
found!" (124.6 s, exit 0) ; flutter test = 1012 PASS / 0 FAIL / 0 SKIP (compteur final
"+1012: All tests passed!", aucun marqueur de fail -N ni de skip ~N, exit 0) ; test
files 166->173 = +7 fichiers AJOUTES (aucun test supprime ni skippe), 50 nouveaux tests
comptes (a11y 10 + analytics 8 + catalog 2 + gps 10 + map_controls 3 + cluster 13 +
lazy 4) ; grep fralimonti|gr20|corse|mare.a.mare sur les 38 fichiers touches = 0 hit
code, 1 hit justifie pubspec asset mare_a_mare_centre. Controles cibles OK : zero-PII
strict (5 events SHA-256, anti-fingerprint, test _assertNoPii cles+email+GPS), opt-in
par defaut (consentement coupe, early-return), no-op total si Firebase indispo (zero
crash), 13 Semantics reels + focus ordonne [1,2,3] + WcagContrast WCAG 2.x + textScale
2x sans overflow, stack Riverpod 2.6/Freezed 3.2.5/Slang 4.15, applicationId
com.only1cent.moteur_gr. Reserves NON BLOQUANTES (dette deja tracee ci-dessous) : R1
cablage call-sites + ecran consentement RGPD (wagon 3), R2 contraste residuel boutons
suivi (refonte ColorScheme), R3 analytics inerte tant que flutterfire configure non fait.
EN ATTENTE GO CHRIS POUR MERGE MAIN (Artemis ne merge pas).

RESTE / DETTE TRACEE (hors run, non bloquant) :
- E5.4 ne produit RIEN tant que wagon 3 (Christophe) n'a pas fait flutterfire configure
  (DefaultFirebaseOptions branche dans firebase_service) ET le setup natif Crashlytics
  (gradle/pod + symbolication). Cablage des call-sites (ref.read(analyticsServiceProvider)
  .logXxx aux moments cles : download, start/stop trek, share, diplome) + ecran de
  consentement RGPD relie a setConsent : infra prete, integration UI a faire.
- a11y contraste residuel (audit honnete) : corrige la ou localise (token
  grisTexteSecondaire pour le suivi). RESTE en dette theme : boutons d'action suivi
  (texte blanc sur vert/orange clairs ~2.4:1) et certains textes secondaires grisGranite
  sur fonds sombres < 4.5:1 — refonte au niveau ColorScheme (couleurs difficulte/statut
  assombries ou texte fonce) a planifier, non couverte par ce lot.
- macos/Flutter/GeneratedPluginRegistrant.swift : diff genere pendant (deja "diff
  pendant" avant ce lot + plugins firebase macos) NON commite — cible mobile, hors scope.

## Lot E5 CONSOLIDATION — polish UX + docs + securite (08/06, Vulcain)
Source : plan V10 #83558 (E5.5) + #83559 (E5.9/E5.10) + inventaire #85410-85412.
METHODE : ecriture propre depuis le plan (zero cherry-pick stranded). Branche NEUVE
claude/feat/E5-consolidation-polish-docs-security depuis main 0a21c63 (socles deja
fusionnes). Stack reelle confirmee : Riverpod 2.6.1 (providers manuels, PAS de
generator/v3), Freezed 3.2.5, Slang 4.15 (CLI dart run slang, 1 JSON/langue),
Drift 2.31, flutter_map 8.2. applicationId com.only1cent.moteur_gr. Contamination
lib/scripts = 0, docs = 0 hors mentions parametriques justifiees (mare-a-mare).

E5.5a (polish animations) — commit e4e8003 :
- Hero transition liste->detail d'etape : widget partage StageNumberBadge
  (lib/shared/widgets/) enveloppe d'un Hero (tag stable stage-number-N,
  flightShuttleBuilder Material). Utilise dans StageListTile ET l'en-tete de
  StageDetailScreen (trail) -> le numero "vole" de la carte vers le titre.
- Micro-interactions haptiques : helper AppHaptics (lib/core/ui/app_haptics.dart,
  heavy/medium/light). Cable sur SOS/appel urgence (heavy), partage carte (medium),
  generation diplome PDF (medium), boutons de suivi Demarrer/Pause/Stop/Reprendre
  (light).
- Tests : stage_number_badge_hero_test (Hero present + 2 Hero en vol pendant la
  transition) + app_haptics_test (canal plateforme HapticFeedback.* par niveau).

E5.5b (dark mode + design system + contraste) — commits e4e8003 + 37f9dac :
- Theme CLAIR ajoute : AppTheme.buildLightTheme(...) (pendant de buildDarkTheme,
  memes couleurs injectees TrailConfig). main.dart cable theme: (clair) +
  darkTheme: + themeMode: ThemeMode.dark (sombre par defaut, bascule sans casse).
- RESERVE R2 (gate socles) RESORBEE — c'etait la dette tracee lignes 149-153 :
  * boutons d'action suivi : Colors.green/Colors.orange (texte blanc ~2.2-2.8:1,
    ECHEC AA) -> tokens AppTheme.actionStart (#2E7D32, blanc 5.1:1) /
    actionPause (#BF360C, blanc 5.6:1). Stop = rougeUrgence (blanc 4.98:1, deja OK).
  * grisGranite sur fonds sombres (~2.7:1) : tous les usages de TEXTE/ICONE
    secondaire sur surface sombre migres vers grisTexteSecondaire (#B0B0B0, 7.7:1) —
    ~20 occurrences (poi_popup, poi_tile, empty_state, paywall, no_data, follow_web,
    group, member_position_card, stage_progress_bar, cloud_unavailable_notice,
    diploma, download_progress_indicator, tracking_overlay, stage_detail trail+trek,
    trail_catalog_card, bottom nav unselected). Les usages de grisGranite RESTANTS
    sont des couleurs d'ELEMENT UI (badge statut, niveau difficulte, barre, toggle
    desactive) >=3:1 OK (WCAG 1.4.11), + grisGranite reste le token des fonds CLAIRS
    (share card, 6.2:1). grisTexteSecondaire jamais sur clair (2.2:1, teste).
- Tests : a11y_audit_test etendu (boutons action AA, bottom nav unselected AA,
  theme clair texte principal AA, grisGranite OK clair / grisTexteSecondaire KO clair)
  + theme_switch_test (les 2 themes construisent + TrailDetailScreen/StageDetailScreen
  s'affichent sans exception en clair ET sombre).
ETAT R2 : la dette contraste tracee par la gate socles est CLOSE (boutons + textes
secondaires). Reste un theme clair fonctionnel et teste, sombre toujours par defaut.

E5.9 (documentation) — commit ba9f720 (reecriture PROPRE, decontamination) :
- docs/README.md : architecture, stack REELLE (Riverpod 2.6 providers manuels,
  Slang CLI 1 JSON/langue, Drift, structure lib/core+features reelle), lancement.
- docs/ADD_TRAIL.md : guide complet ajout sentier (TrailConfig, JSON seed
  trail_meta/itineraries/stages/pois multilingue inline, GPX, MBTiles, Slang
  dart run slang, pubspec, manifest, checklist). Decrit le pipeline TrailSeeder reel.
- docs/CONTRIBUTING.md : conventions (providers manuels, Slang CLI, Freezed,
  Firebase optionnel, a11y), Conventional Commits, branches, tests (flutter_test +
  ProviderContainer, PAS mocktail/patrol), gates.
- docs/ADR/ : 001 Drift over Hive + 002 Slang over intl + 003 RENOMME
  003-riverpod-over-bloc.md (etait 003-riverpod3...). ADR 003 dit Riverpod **2.6**
  providers manuels, v3 = lot dedie futur (option A) — PLUS de claim "v3 native
  persistence/retry". Decontamination des 3 ADR : suppression du cadrage "GR20
  utilise X" (StepWays independant), correction Slang (1 JSON/langue via CLI, pas
  YAML par namespace ni build_runner). 0 test (docs).
EXACTITUDE : les anciens docs etaient contamines (Riverpod 3 + riverpod_generator,
structure app/lib, Hive/intl en "actuel GR20", versions fausses) — entierement
reecrits pour refleter l'etat REEL de main.

E5.10 (securite tooling) — commit 939958c :
- E5.10a scripts/security_audit.sh : dart pub outdated --json, distingue direct/
  transitif, flag CRITIQUE = direct discontinued OU isCurrentAffectedByAdvisory/
  isCurrentRetracted ; rapporte retards majeurs en INFO (NE force AUCUN upgrade,
  note explicite Riverpod v3). EXIT 0 confirme (aucun critique ; js transitif
  discontinued = avertissement, ~22 deps en retard majeur = info).
- E5.10b scripts/scan_secrets.sh : scan contenu (regex cle PEM/AIza/ya29/AWS/
  GitHub/Slack/Stripe/bearer + affectation sensible, garde-fou anti-faux-positif)
  sur 370 fichiers suivis (hors generes/fixtures/docs) = 0 secret ; verifie
  .gitignore (key.properties, *.keystore, *.jks, .env, google-services.json,
  GoogleService-Info.plist) = complet ; firestore.rules LECTURE SEULE (161 lignes,
  default-deny + follow_sessions confirmes, JAMAIS reecrites). EXIT 0 confirme.
- .gitignore DURCI : ajout section secrets (les 6 patterns ci-dessus + *.pem/p12/p8/
  mobileprovision + lib/firebase_options.dart). E5.6 CI/CD = deja couvert main
  (remediation P1-5), NON refait. firestore.rules = deja P0-1, NON reecrites.

PREUVES (08/06) : flutter analyze = No issues found (0). flutter test = 1028/1028
PASS (baseline 1012 + 16 nouveaux tests E5.5, 0 supprime/skippe). security_audit.sh
EXIT 0, scan_secrets.sh EXIT 0 (sorties affichees). grep contamination
fralimonti/gr20/corse/mare-a-mare sur fichiers touches = 0 hors parametrique
(2 mentions justifiees dans docs). 4 commits (e4e8003, 37f9dac, ba9f720, 939958c)
sur claude/feat/E5-consolidation-polish-docs-security, pousses. PAS DE MERGE MAIN.
EN ATTENTE gate Artemis + GO Chris.

RESTE / NON FAIT (hors scope de ce lot) :
- E5.7/E5.8/E5.1b (suite Phase 5 plan V10) — non traites ici.
- E5.4 analytics reste inerte tant que wagon 3 (flutterfire configure) non fait.
- Pipeline phases 6-8 (#83884) a derouler ulterieurement.

## Phase 4 — bloc E4.10-E4.17 REINTEGRE (06/06, Vulcain)
Contexte : la serie granulaire E4.10->E4.17 vivait sur la branche
claude/feat/E4.15-auth-anonymized (4206ca1->6187a68), jamais mergee,
ecrite AVANT decontamination GR20 / Freezed v3 / Slang v4 / bottom nav
(decouverte Artemis, gate #85353 reserve R-P4.3). Specs : V7 #81796 +
#81793, V8 #82298 ; decisions #81753 (3 canaux), #81759 (2 suiveurs
gratuits), #81774 (freemium a la carte), #81775 (zero compte, ID anonymise).
Methode : branche NEUVE claude/feat/E4.10-17-reintegration depuis main
(422a94c), reprise LOT PAR LOT avec readaptation (AUCUN merge brut).
Serie granulaire E4.10-17 REINTEGREE — commits (identite Vulcain) :
- b5ea79a E4.10  modeles suivi Freezed v3 + tables Drift v12 (@DataClassName
  *Row, collision evitee) + ShareLinkType enum->String 3 canaux + no_data
  redirection + i18n t.noData (5 langues)
- 122485d E4.11  FollowService (session, 2 gratuits #81759, position
  Firestore, liens 3 canaux #81753 via FollowLinksConfig injectee — zero
  marque en dur) + providers
- 24f3f53 E4.11b-c update_checker (manifest local vs Firestore) +
  update_downloader (REUTILISE DeltaUpdateService du main, URL delta
  parametrique, notification i18n t.updates)
- 7ce3349 E4.12a-b FollowWebScreen (route /follow/:code hors shell +
  exclusion guard, i18n t.follow, centre carte neutre) + web/follow/
  index.html neutralise + GroupSyncService (batch 1h / push refuge wifi /
  rattrapage, mode String extensible)
- f8f2c65 E4.13  AdService AdMob (shouldShowAd index 2+, ID de TEST
  officiel uniquement — sandbox)
- 4eeac78 E4.14  IapService pass suivi web 1 EUR (testMode stub, lien
  permanent ?pass=1 via config injectee)
- 92b5c34 E4.15  Auth Apple/Google anonymisee : AnonymousIdService SHA-256
  sale deterministe + FirebaseAuthService zero PII (#81775) — durci :
  scopes Apple email/name supprimes (minimisation) ; authServiceProvider
  bascule Firebase/local
- 548537f E4.16  BackgroundSyncService 30 min (REUTILISE CloudSyncService
  du main) + RestoreService LWW (progression/journal/checklist, codes
  erreur neutres)
- fb125c0 E4.17  Monetisation freemium : MonetizationService (gratuit =
  prep+pub+demo / premium par trek = complet sans pub, prix = etapes x
  1 EUR, achats PERSISTES SharedPreferences) + FeatureFlags.isPremiumEnabled
  + PaywallSheet + PurchaseGateWidget i18n — STUB, aucun paiement reel
Preuves 06/06 (transcript Vulcain) : flutter analyze = No issues found! ;
flutter test = 937 PASS / 0 FAIL / 0 SKIP (base 881 + 56 nouveaux, aucun
test supprime ; 2 tests existants realignes legitimement : no_data_screen_test
-> cles Slang, app_router_test -> 12 routes niveau 1 avec /follow/:code).
Grep gr20/corse/corsica/pghm/mare-a-mare sur les fichiers du bloc = 0
(seul hit : ligne pubspec pre-existante de main, asset sentier reel
Mare a Mare = parametrique valide gate #85353).
Adaptations transverses : tests de la vieille branche deplaces/fixtures
neutralisees (volcans/sentier-bleu), textes 100% Slang 5 langues,
fake DocumentSnapshot (classe sealed) remplace par maps simples.
La branche claude/feat/E4.15-auth-anonymized est OBSOLETE (contenu
reintegre, ne plus cherry-picker dessus). PAS DE MERGE MAIN sans GO.

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

## Lot finitions V8 (tache #324, reserves gates #85352/#85353/#85359) — COMPLETE 06/06
Branche claude/fix/finitions-v8 (depuis main f97d1f2), commits identite Vulcain,
1 commit par fix. PAS DE MERGE MAIN sans GO.
- F1 65574f4 : AccommodationType enum -> String parametrique (#81752).
  fromDb supprime (il ECRASAIT toute valeur inconnue en refuge) : la valeur
  DB/JSON est preservee telle quelle ; typedef + AccommodationTypeValues
  (idiome ShareLinkType) ; mapping label/icone centralise
  (accommodation_type_ui.dart) avec fallback generique a l'AFFICHAGE
  uniquement (icone holiday_village + libelle = valeur brute) ; labels i18n
  Slang 5 langues (accommodation.types.*) ; Freezed/Drift/tests adaptes
  (+6 tests contrat preservation/fallback).
- F2 2270d84 : questions faisabilite indexees par trailId. Resolution
  <TrailConfig.seedAssetsBase>/feasibility_questions.json -> fallback
  fichier commun assets/data/ -> template hardcode ; FeasibilityState porte
  les questions chargees (le provider utilisait la constante hardcodee,
  le JSON n'etait jamais lu) ; +3 tests (commun, fallback, priorite sentier).
- F3 5fd1779 : recap diplome branche sur le trace GPS REEL de la session.
  Constat : aucun canal n'existait (TrekRecorder/TrekStats jamais alimentes
  hors tests, onSessionPersist no-op, zero persistence des points) ; le
  pipeline reel est TrackingNotifier/TrackingEngine qui JETAIT les points au
  stop. Livre bout-en-bout : table session_track_points (migration Drift
  v12->v13) + DAO, persistence au fil de l'eau pendant l'enregistrement
  (robuste a un arret brutal, trace remplace au start suivant),
  sessionTraceProvider, rendu SessionTracePainter (CustomPaint offline,
  zero tuile reseau), fallback recapNoMap conserve si aucun trace ;
  +7 tests (DAO round-trip/isolation/clear, section, painter).
- F4 ec7818b : code mort supprime — lib/features/after/presentation/
  diploma_screen.dart (DiplomaAfterScreen, doublon orphelin : zero import,
  zero route, zero test). Tests orphelins supprimes avec lui : AUCUN
  (liste vide — aucun test ne le referencait). Residus in_app_review E5.17 :
  service + provider + test sont REFERENCES par l'ecran diplome route
  (features/diploma) -> vivants, conserves ; les seuls usages non references
  etaient dans l'orphelin supprime.
- F5 3d28028 : firestore.indexes.json cree — index composite
  follow_sessions(shareCode ASC, isActive ASC) requis par la requete de
  follow_web_screen ; l'orderBy(timestamp desc) sur la subcollection
  positions est couvert par l'index single-field automatique. Les autres
  acces Firestore du bloc cloud/suivi sont par chemin direct (zero index
  composite supplementaire).
- F6 14cbade : IapService garde-fou anti-paiement-reel — testMode TRUE par
  defaut + kill-switch compile-time kIapRealModeEnabled=false documente
  (procedure d'activation en 3 etapes dans la doc du flag) ; verrou central
  _stubbed : meme une instance testMode:false ne peut PAS atteindre le
  store tant que le kill-switch est off. AUCUN produit store reel cree.
  +3 tests (kill-switch off, defaut testMode, verrou testMode:false).
- F7 bca6e55 : purge dette PII AuthUser — champs email/photoUrl SUPPRIMES
  du modele (zero PII garanti a la compilation, #81775), propagation
  residuelle retiree de LocalAuthService. local_auth_service N'EST PAS
  supprime : c'est le fallback offline officiel d'authServiceProvider
  (Firebase indisponible), teste — neutralise (zero PII possible) et
  documente comme tel. 2 tests realignes sur le contrat structurel (l'un
  peuplait email='jean@example.com' dans le modele — dette reelle).
- Decontamination fixtures tests legacy b8b17cc : 36 fichiers de test
  purges de gr20/GR20/Corse (regle #81434) -> sentier-bleu/Sentier Bleu/
  Region Test. Exceptions parametriques conservees : donnees reelles du
  sentier Mare a Mare (assets/data/mare_a_mare_centre*, tips,
  checklist_template overrides) + leurs 2 tests dedies
  (mare_a_mare_data_test, trail_seeder_test).
- Chore 3b02ddd : regeneration GeneratedPluginRegistrant.swift (macos),
  plugins IAP/webview du bloc E4 merge — fichier genere tracke, diff
  pendant depuis le merge.
RE-SCOPE nommage seeder : la reserve "renommer le seeder par-sentier"
  etait DEJA realisee par la decontamination #320 (TrailSeeder generique,
  seed par TrailConfig.seedAssetsBase) ; mare_a_mare_prod_seeder.dart
  n'existe QUE sur la vieille branche E4.15 jamais mergee. Aucun seeder
  nomme par sentier sur main — point clos sans travail supplementaire.
PREUVES 06/06 (transcript Vulcain, affichees) :
  flutter analyze = "No issues found!" ; flutter test = 956 PASS / 0 FAIL /
  0 SKIP (base 937 + 19 nouveaux tests F1/F2/F3/F6 ; AUCUN test supprime ni
  skippe — F4 n'avait aucun test orphelin ; 2 tests realignes F7 documentes
  ci-dessus). Grep gr20/pghm sur lib+android+ios+macos+web+test+assets = 0 ;
  corse/mare-a-mare = uniquement assets parametriques du sentier reel et
  leurs 2 tests de donnees (valide gate #85353).

## Menage repo (lot finitions, 06/06)
- Fichiers de travail untracked SUPPRIMES (apres verification : sorties
  analyze/test des gates deja documentees en base/orchestration, scripts
  one-shot deja appliques) : _artemis_*.txt/.bat, _gate*_*.txt,
  _melos_*.txt, _gen_bottom_sheet.py, _patch1.py.
- data/ (logs agent + ref-gr20 R1.1-R1.11 + staging/trail_variantes.dart)
  et docs/rgpd/ (AIPD-capteurs-sante.docx) : contenu UNIQUE -> DEPLACES
  hors repo vers C:/Users/Christophe/Claude/projets/interne/
  Moteur-GR-archives/2026-06-06/ (rien de supprime).
- Worktree .claude/worktrees/vulcain-E4.1b retire (git worktree remove ;
  seules modifs = fichiers generes plugin registrant). La branche
  claude/feat/phase4-E4.1b existe toujours.
- Branche claude/test/E0-pipeline-check SUPPRIMEE local+remote (1 commit
  de commentaire trivial, preuve pipeline tache #320 devenue inutile).
- Branche claude/feat/E4.15-auth-anonymized : NON SUPPRIMEE — deltas
  uniques constates (voir Branches en attente).

## Lot remediation P0+P1 audit #327 (tache #328) — COMPLETE 07/06
Audit independant Athena #85381-#85384 (GO-53) : produit solide en
logique metier mais NON DEPLOYABLE (regles Firestore absentes pour
follow_sessions, manifestes natifs vides, RGPD inexistant, release
signee debug, CI sans release). Remediation par Vulcain, branche NEUVE
claude/fix/remediation-p0p1-audit327 depuis main (ca16f2f), 1 commit
par item, AUCUN cherry-pick de branche pre-decontamination.
- P0-1 91c8863 : regles Firestore follow_sessions + sous-collections
  followers/positions. Session privee owner-only strict (create borne
  au schema exact, TTL <= 48h + 1h tolerance, update limite a isActive) ;
  lecture positions par suiveur ANONYME uniquement si session valide
  (get() serveur isActive + expiresAtTs) ; miroir public minimal
  follow_sessions_public (shareCode/isActive/expiresAtTs, JAMAIS
  trekkerUserId) pour la resolution shareCode->sessionId ; deny
  explicite du reste ; trails/users intacts. FollowService = double
  ecriture + champ Timestamp expiresAtTs (les regles ne parsent pas
  l ISO-8601) + rollback ; FollowWebScreen lit le miroir + rejette les
  sessions expirees ; index composite bascule sur follow_sessions_public.
- P0-2 20e24c1 : tests des regles sous EMULATEUR — package Node dedie
  firestore-tests/ (@firebase/rules-unit-testing 4 + firebase 11 +
  node:test), firebase.json racine (projet demo-stepways hors ligne).
  45 cas : matrice complete trekker OK / etranger KO / anonyme valide
  OK / expiree KO / inactive KO / shareCode faux KO / trekkerUserId
  verifie ABSENT du miroir / payloads bornes / parcours complet sans
  seed admin / trails + users + catch-all deny. EXECUTION REELLE :
  45/45 PASS (emulateur Firestore 1.19.8, firebase-tools 13.x car JDK
  17 machine). Integres au pr_gate CI (P1-5).
- P0-3 b34944a : docs/rgpd/ — politique de confidentialite FR + EN,
  registre des traitements art.30 (7 traitements), data-safety.md =
  mapping exact Play Data Safety + App Privacy/ATT Apple. Fidele au
  code main : photos/sante/contacts = LOCAL-ONLY jamais transmis,
  AdMob sandbox test, IAP verrouille, PAS d analytics/Crashlytics
  (non merges), OSM/Open-Meteo IP transitoire, anonymisation
  compile-time valorisee (#81775). Placeholders [ENTITE]/[ADRESSE]/
  [CONTACT-EMAIL] — rien d invente juridiquement. Constat trace :
  firebase_storage dependance INUTILISEE dans lib/ (retirer ou cabler).
- P1-1 c4d51ef : AndroidManifest reecrit — ACCESS_FINE/COARSE/
  BACKGROUND_LOCATION, FOREGROUND_SERVICE(+_LOCATION), POST_
  NOTIFICATIONS, INTERNET + service geolocator redeclare
  foregroundServiceType=location (Android 14+) ; label "StepWays" ;
  package com.only1cent.moteur_gr partout ; widget E5.19b conserve.
- P1-2 b99660d : Info.plist iOS — NSLocationWhenInUse + Always,
  NSCamera, NSPhotoLibrary (textes FR niveau store, photos "restent
  sur votre telephone"), UIBackgroundModes location,
  CFBundleDisplayName StepWays.
- P1-3 c054fb9 : build.gradle.kts — minSdk 23 / targetSdk 35 epingles ;
  signingConfig release via android/key.properties (NON versionne,
  .gitignore ok) avec FALLBACK EXPLICITE TRACE vers debug (logger.warn)
  + TODO wagon 3 ; zero secret, zero keystore genere. Preuve gradle :
  :app:signingReport EXIT=0, fallback verifie.
- P1-4 5385ace : mode degrade sans Firebase durci — widget
  CloudUnavailableNotice (i18n t.cloud.* 5 langues), GroupScreen sans
  formulaire mort, ProfileScreen sans spinner infini + tuile Google
  remplacee par la notice, FollowWebScreen badge hors-ligne sur erreur
  de flux, SettingsScreen section Cloud (etat local/actif visible).
  docs/firebase-setup.md = procedure flutterfire configure wagon 3
  (projet DEDIE StepWays, JAMAIS gr20-app, region eur3, TTL 48h,
  deploy rules+indexes). +6 tests degraded_mode.
- P1-5 3afd6c3 : codemagic.yaml — workflows android_release (AAB) +
  ios_release (IPA) sur tag v*, signature 100% par groupes d env
  Codemagic, secrets absents = ARRET PROPRE message explicite (jamais
  d echec silencieux ni d artefact debug presente comme release) ;
  pr_gate enrichi du step tests de regles Firestore ; pr_gate/merge
  existants intacts ; REECRITURE complete (zero merge E5.6b contamine).
PREUVES 07/06 (transcript Vulcain, affichees) : flutter analyze =
"No issues found!" ; flutter test = 962 PASS / 0 FAIL / 0 SKIP (base
956 + 6 nouveaux P1-4, AUCUN test supprime ni skippe) ; tests regles
emulateur 45/45 PASS reels ; grep fralimonti|gr20|corse|mare-a-mare
sur les 35 fichiers touches = 1 seul hit JUSTIFIE (la ligne
d INTERDICTION "JAMAIS le projet gr20-app" de docs/firebase-setup.md,
exigee par la tache = garde anti-contamination, pas une contamination).
PAS DE MERGE MAIN sans GO.
RESTE WAGON 3 (Christophe, HORS run) : keystore reel + key.properties ;
flutterfire configure projet stepways dedie + branchement
DefaultFirebaseOptions (firebase_service.dart) + firebaseProjectId
TrailConfig ; groupes d env Codemagic stepways_android_signing /
stepways_ios_signing ; politique TTL Firestore follow_sessions(_public) ;
build device reel Android+iOS (P1-6 audit) ; ATT + CMP avant ads
reelles ; saisie Data Safety / App Privacy dans les consoles
(docs/rgpd/data-safety.md). DETTE TRACEE : collection groups sans
regles (deny — feature groupe inerte en prod, a traiter a l activation) ;
firebase_storage inutilise ; sel anonymisation fixe (P2-6 audit).

## Branches en attente
claude/feat/E5-socles-perf-a11y-analytics — lot E5 SOCLES (perf carte/GPS,
  a11y WCAG, analytics anonyme) COMPLETE 07/06 : 4 commits 3b2a8c8..3a55c98
  depuis main 4153dc5, reecriture propre (zero cherry-pick des 17 stranded).
  Preuves analyze 0 / test 1012-0-0 / grep touches = 1 hit parametrique justifie.
  GATE QA ARTEMIS VERTE 08/06 (#85426) — preuves re-executees independamment
  (analyze 0 issue / test 1012-0-0 / +7 fichiers tests aucun supprime / grep 0 hit
  code). Attend GO Chris. PAS DE MERGE sans GO. Reste wagon 3 Firebase (analytics
  inerte tant que non configure) + dette contraste theme.
claude/fix/remediation-p0p1-audit327 — lot remediation P0+P1 audit #327
  (tache #328) COMPLETE 07/06 : 8 commits 91c8863..3afd6c3 (+ resync
  orchestration), preuves analyze 0 / test 962-0 / regles emulateur
  45-0 affichees. Attend QA Artemis + GO Chris. PAS DE MERGE sans GO.
claude/fix/finitions-v8 — lot finitions V8 #324 COMPLETE (commits ci-dessus),
  preuves analyze 0 / test 956-0 affichees. Attend QA Artemis + GO Chris.
  PAS DE MERGE sans GO.
claude/feat/E4.10-17-reintegration — bloc E4.10-E4.17 reintegre (9 commits
  b5ea79a..fb125c0 + resync orchestration), preuves analyze 0 / test 937-0
  affichees. Attend QA Artemis + GO Chris. PAS DE MERGE sans GO.
claude/feat/E4.15-auth-anonymized — CONSERVEE (correction 06/06 du statut
  "obsolete") : verification git cherry/diff AVANT suppression = 28 commits
  non merges, 30 fichiers sans equivalent sur main, dont des DELTAS UNIQUES
  jamais portes par la serie coarse ni la reintegration :
  E4.4b verification hash SHA-256 des telechargements (download_verifier
  + test ; le trail_download_service de main n'a AUCUNE verification
  d'integrite), E4.5a-d fiche detail catalogue / trail_switcher / filtres
  TrailFilter+filter_bar / deep_link_handler + .well-known (App Links /
  Universal Links absents de main), E4.8b sync photos dediee,
  docs/firestore_schema.md. NE PLUS cherry-picker brut (pre-Freezed v3 /
  pre-decontamination) mais REPRENDRE ces lots comme E4.10-17 (readaptation)
  avant toute suppression de la branche.
claude/feat/E2.10-upgrade-deps — constat git 06/06 : DEJA MERGEE sur main
  (422a94c). Statut GO/QA a confirmer par Skynet/Chris.
claude/fix/E5-decontamination-gr20 — reprise Phase 5 ; constat git 06/06 :
  DEJA MERGEE sur main (90e75c2) ainsi que la reparation des 7 tests (c5e1981
  inclut ebde305). Statut GO/QA a confirmer par Skynet/Chris.

## Prochaine action
0bis. QA gate Artemis sur claude/feat/E5-socles-perf-a11y-analytics (lot E5
   SOCLES : E5.2 perf carte/GPS, E5.3 a11y WCAG, E5.4 analytics anonyme zero-PII ;
   preuves analyze 0 / test 1012-0-0 / grep 1 hit parametrique dans le transcript)
   + GO Chris. Verifier specifiquement : zero-PII des events (SHA-256), opt-in par
   defaut, no-op si Firebase indisponible, Semantics + contraste + textScale 2x.
0. QA gate Artemis sur claude/fix/remediation-p0p1-audit327 (lot
   remediation audit #327, tache #328 : P0-1..P1-5, preuves analyze 0 /
   test 962-0 / regles emulateur 45-0 / greps dans le transcript) +
   GO Chris. Puis wagon 3 Christophe (keystore, Firebase reel, build
   device — liste detaillee dans la section du lot).
1. QA gate Artemis sur claude/fix/finitions-v8 (lot finitions #324 :
   F1-F8, preuves analyze 0 / test 956-0 / greps dans le transcript).
2. QA gate Artemis sur claude/feat/E4.10-17-reintegration (bloc E4.10-E4.17,
   conditions de la tache : 3 canaux, RGPD #81775, sync/restore, freemium
   sandbox, 937 tests, grep 0).
3. GO Chris pour merges. La branche claude/feat/E4.15-auth-anonymized reste
   CONSERVEE tant que ses deltas uniques (E4.4b hash, E4.5a-d catalogue/
   deep links, E4.8b photos, doc schema) ne sont pas reintegres — decision
   de reprise a planifier.
4. QA gate Artemis Phase 2 (toujours en attente) — NB : E2.10-upgrade-deps
   constatee deja mergee sur main (422a94c).

## Derniere action
07/06 (lot E5 SOCLES) : reintegration PROPRE perf/a11y/analytics par Vulcain sur
claude/feat/E5-socles-perf-a11y-analytics (branche neuve depuis main 4153dc5, zero
cherry-pick des 17 stranded) — E5.2a clustering marqueurs + Douglas-Peucker dynamique
+ RepaintBoundary (3b2a8c8), E5.2b GPS precision adaptative mouvement/repos + images
lazy (7b5e996), E5.3 a11y WCAG AA : Semantics + labels Slang 5 langues + WcagContrast
+ focus ordonne + textScale 2x (92c1845), E5.4 analytics ANONYME zero-PII opt-in mode
degrade no-op (3a55c98). Preuves : analyze 0 issue, 1012/1012 PASS (0 skip, base 962
+ 50 nouveaux), grep fichiers touches = 1 hit parametrique justifie (mare_a_mare_centre
pubspec pre-existant). Voir section "Lot E5 SOCLES". RESTE wagon 3 Firebase + dette
contraste theme (traces).
07/06 (remediation audit #327) : lot P0+P1 tache #328 COMPLETE par
Vulcain sur claude/fix/remediation-p0p1-audit327 — P0-1 regles
Firestore follow_sessions + miroir public minimal sans trekkerUserId,
P0-2 45 tests de regles sous emulateur REELS (45/45 PASS) integres au
pr_gate, P0-3 dossier RGPD complet (politique FR/EN, registre art.30,
mapping stores/ATT), P1-1 AndroidManifest permissions + service
location, P1-2 Info.plist cles d usage + background location, P1-3
gradle minSdk23/targetSdk35 + signing key.properties fallback trace,
P1-4 mode degrade sans Firebase (UI explicite, 6 tests) + doc setup
wagon 3, P1-5 workflows release AAB/IPA signature conditionnelle arret
propre. Preuves : analyze 0 issue, 962/962 PASS, emulateur 45/45,
grep fichiers touches = 1 hit justifie (ligne d interdiction gr20-app).
Voir section "Lot remediation P0+P1 audit #327".
06/06 (finitions V8) : lot finitions tache #324 COMPLETE par Vulcain sur
claude/fix/finitions-v8 — F1 type String hebergements (#81752, valeur
inconnue preservee), F2 questions faisabilite par trailId, F3 trace GPS
reelle du diplome (canal bout-en-bout cree : table v13 + persistence +
rendu), F4 code mort (DiplomaAfterScreen, zero test orphelin), F5
firestore.indexes.json, F6 kill-switch IAP anti-paiement-reel, F7 zero PII
AuthUser compile-time, decontamination 36 fixtures tests legacy + menage
repo (fichiers de travail purges, uniques archives hors repo,
E0-pipeline-check supprimee, E4.15-auth-anonymized CONSERVEE pour deltas
uniques documentes). Preuves : analyze 0 issue, 956/956 PASS, greps OK.
06/06 (Phase 4) : REINTEGRATION du bloc dormant E4.10-E4.17 par Vulcain —
9 lots readaptes depuis la branche obsolete claude/feat/E4.15-auth-anonymized
vers claude/feat/E4.10-17-reintegration (Freezed v3, Slang v4 5 langues,
String extensibles, liens/URLs parametriques, zero GR20/marque en dur,
achats stub sandbox). Preuves : analyze 0 issue, test 937/937 PASS, grep
bloc 0. Voir section "Phase 4 — bloc E4.10-E4.17 REINTEGRE".
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
