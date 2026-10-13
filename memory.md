# Memory — vulcain

_Notes locales de vulcain. La source de verite reste memory.db._

## 07/10 — lot coche de preparation calculee (branche claude/feat/coche-de-preparation-calculee)

- [debut] Tete d'integration verifiee : 52fb8ac2 (inchangee depuis 07/10 13:33). Branche neuve prise dessus, jamais main.
- [debut] memory.db et scripts/memory_helper.py ABSENTS du conteneur cloud : #101465, #101481, #101488 illisibles. Notes gravees ici, a reporter en base.
- [debut] Pas de SDK Flutter fourni : installe 3.47.6 stable hors depot. `pub get` reecrit pubspec.lock (paquets epingles par le SDK) : NON commite.
- [commentaires] hub_prepare_section.dart l.1 : « quatorze » -> « douze » (12 QuickAccessCard comptees). Le fichier est sous presentation/widgets/, pas presentation/.
- [commentaires] retained_plan_store.dart l.13-16 : « la base Drift tourne en memoire » corrige (fichier durable depuis la tache 613).
- [constat] Matiere de la coche : StepStatusIcon + QuickAccessCard.stepStatus, jamais passe. Aucun test ne cite StepStatusIcon a ce jour.
- [base] Suite sur 52fb8ac2 + Flutter 3.47.6 : 41 echecs DEJA LA avant toute modification (4264 verts, 4 sautes), dans feasibility, safety (fiche medicale), personas « le maladroit » et tout_ecran_a_une_route (/health, /hiker-profile) : assertion « ListTile background color or ink splashes may be invisible » propre au SDK recent. Hors terrain, non corriges. `dart analyze lib/ test/` : 0 erreur, 0 avertissement.
- [regles] Programme : complet = ecran ouvert (exactement la porte de demarrage) ; entame = duree retenue sans ouverture ; rien sinon. Itineraire et Calendrier : deux etats. Cartes : `{id}.mbtiles` / `.partiel` via core/map. Faisabilite : fiche profil vide / partielle / complete.
- [calculateur] lib/features/hub/providers/prepare_progress_providers.dart : enum SujetDePreparation (12 sujets), statutDePreparationProvider((trailId, sujet)) -> PlanningStepStatus? (null = pas de coche). Sac et nuitees lus en lecture ponctuelle (getByTrailId existant), RELUS AU RETOUR de leur ecran — la premiere version en flux Drift laissait un minuteur en suspens et cassait 10 tests du cockpit, abandonnee et DAO remis a l'identique —, jamais via checklistProvider (amorce 84 lignes a la lecture) ni nuiteeSelectionsProvider (charge sans filet, suit le sentier actif).
- [tests] test/features/hub/providers/coche_de_preparation_calculee_test.dart : 51 tests, sources reelles fabriquees (prefs simulees, Drift memoire, dossier temporaire). Mutation de 3 regles -> 11 rouges : ils mordent.
- [facades] +defaultChecklistTemplate (checklist), +trainingPlanProvider (training), +buildNuiteeSlots (booking) : la regle de compte des nuits n'est pas recopiee.
- [fin] Suite complete finale : 4318 verts, 4 sautes, 41 echecs = EXACTEMENT les 41 de la base (assertion ListTile SDK 3.47) ; la_doc_ne_mente_pas repasse au vert. dart analyze lib/ test/ : 0 erreur, 0 avertissement ; +3 infos de longueur sur des lignes d import de tests (inevitables, comme leurs voisins).
- [code mort] Mesure reelle : 139 avant ET apres le lot (le plafond disait 144). La coche n'a JAMAIS ete dans la liste : quick_access_card.dart la cite depuis 645-05c, la garde la comptait vivante sans affichage. Plafond resserre a 139. statutMateriel cite par un test pur.
- [tests] Decoupe en banc (coche_de_preparation_banc.dart) + coche_rubriques_riches_test.dart + coche_rubriques_pauvres_test.dart : 53 tests, stables 3/3 et 8/8 (l'aide de test attend le futur des lectures disque/base).
- [facades] LUE PAR mis a jour : booking 4/4, checklist 2/2, feasibility 11/6, planning 11/7, training 2/2, notifications 14/8, safety 8/4.

## 2026-10-07 — lot chaine Apple modele GR20 (branche claude/chore/chaine-apple-modele-gr20)
- Tete d integration verifiee : 52fb8ac2 (claude/integration/671-batterie-dabord), conforme.
- memory.db ABSENTE de ce conteneur (pas de data/, pas de scripts/memory_helper.py) :
  memoires #101487 #101503 #101507-#101514 NON LUES, notes gravees ici a la place.
- Depot GR20 inaccessible (hors perimetre de la session) : modele pris de la consigne.
- MESURE (codemagic-cli-tools 0.69.1, fetch_signing_files_action.py ~l.80) :
  fetch-signing-files leve « Cannot save Signing Certificates without certificate
  private key » sans --certificate-key. Avec une clef neuve + --create il creerait
  un SECOND certificat de distribution. => chemin abandonne, ios_signing par noms.
- Doc Codemagic (codemagic-docs master c6130937) : l interface ne CREE pas de
  profil, elle televerse ou recupere (Fetch profiles) ; une extension exige son
  propre profil ; ios_signing.provisioning_profiles accepte environment_variable.
- Xcode 26.4 present chez Codemagic (specs-macos/xcode-26-4), mais 27.0 et 27.1
  aussi : `latest` n est pas un compilateur fixe.
- TRANCHE : ios_signing par noms (modele GR20), PAS fetch-signing-files.
  Profils attendus : stepways_appstore_profile, stepways_trekwidget_appstore_profile ;
  certificat : GR20 Distribution ; integration : Only1Cent (ios_testflight seule).
- Depot TestFlight = etape `app-store-connect publish --testflight
  --altool-additional-arguments='--use-old-altool'` ; plus de bloc publishing.
- Xcode 26.4 epingle sur ios_compile, ios_release, ios_testflight.
- DECOUVERTE : `dart analyze --no-fatal-infos` sort en 64 (« Cannot negate
  option ») sur TOUT Dart >= 2.19 (source dartdev, negatable: false). Corrige
  dans les deux chaines Apple (flutter analyze --no-fatal-infos). RESTE dans
  pr_gate, merge, android_test, android_release : a corriger, hors lot.
- Doc : docs/ci/signature_ios_modele_gr20.md. Tests : 621 reecrit, nouveau
  codemagic_signature_ios_modele_gr20_test.dart.
- SUITE sous Flutter 3.47.6 (stable du jour, celui de `flutter: stable`) :
  base 52fb8ac2 = +4265 ~4 -41 ; branche = +4282 ~4 -41 ; les 41 echecs ont
  les MEMES noms (11 fichiers feasibility/safety/personas/structurel). Cause vue :
  assertion Flutter neuve « ListTile ... wrapped in a DecoratedBox that has a
  background color ». Consequence : l etape de tests BLOQUANTE des chaines
  tomberait chez Codemagic tant que flutter n est pas epingle ou le code corrige.
