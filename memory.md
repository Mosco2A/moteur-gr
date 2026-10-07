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
