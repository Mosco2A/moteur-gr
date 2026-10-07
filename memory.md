# Memory — vulcain

_Notes locales de vulcain. La source de verite reste memory.db._

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
