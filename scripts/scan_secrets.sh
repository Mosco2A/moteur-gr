#!/usr/bin/env bash
#
# scan_secrets.sh — Detection de donnees sensibles + verification .gitignore (E5.10b).
#
# Fait trois choses :
#   1. Scanne le code source (regex cles API / mots de passe / tokens / cles
#      privees) sur les fichiers SUIVIS par git, hors generes et fixtures.
#   2. Verifie que .gitignore exclut bien les fichiers sensibles attendus
#      (key.properties, *.keystore/*.jks, .env, google-services.json,
#      GoogleService-Info.plist).
#   3. Verifie (LECTURE SEULE) la presence de firestore.rules — deja posees
#      (P0-1), ce script ne les modifie JAMAIS.
#
# Verdict (code de sortie) :
#   0  -> rien de sensible detecte ET .gitignore complet.
#   1  -> au moins une fuite potentielle detectee, OU une entree .gitignore
#         manquante.
#   2  -> erreur d'execution.
#
# Note : les libelles de motifs sensibles sont assembles par fragments
# (KW(...)) pour ne pas faire apparaitre les mots-cles "en clair" dans ce
# fichier — sinon le scan se signalerait lui-meme.
#
# Usage :
#   bash scripts/scan_secrets.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

PY=""
if command -v python3 >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1; then
  PY="python"
else
  echo "ERREUR : 'python3'/'python' introuvable." >&2
  exit 2
fi

echo "=== Scan donnees sensibles StepWays (scan_secrets.sh) ==="
echo "Projet : $PROJECT_ROOT"
echo

FILES_LIST="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/stepways_files_$$.txt")"
trap 'rm -f "$FILES_LIST"' EXIT
if command -v git >/dev/null 2>&1 && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git ls-files >"$FILES_LIST"
else
  find . -type f \
    -not -path '*/.git/*' -not -path '*/build/*' -not -path '*/.dart_tool/*' \
    >"$FILES_LIST"
fi

"$PY" - "$FILES_LIST" <<'PYEOF'
import os, re, sys

files_list = sys.argv[1]
with open(files_list, "r", encoding="utf-8", errors="replace") as fh:
    files = [l.strip() for l in fh if l.strip()]

# Mots-cles sensibles assembles par fragments (evite de les ecrire en clair).
def KW(*parts):
    return "".join(parts)

K_PWD   = KW("pass", "word")
K_PWD2  = KW("pass", "wd")
K_SECR  = KW("sec", "ret")
K_APIK  = KW("api", "[_-]?", "key")
K_APIK2 = KW("api", "key")
K_ATOK  = KW("access", "[_-]?", "token")
K_AUTHT = KW("auth", "[_-]?", "token")
K_CSEC  = KW("client", "[_-]?", K_SECR)
K_PKEY  = KW("private", "[_-]?", "key")
K_BEAR  = KW("[Bb]", "earer")

# Generes, fixtures, scripts d'audit, docs, lockfiles, ce scan lui-meme.
EXCLUDE_PATH_RE = re.compile(
    r"(\.g\.dart$|\.freezed\.dart$|/i18n/translations.*\.dart$"
    r"|^test/|/test/|^scripts/scan_secrets\.sh$|^scripts/security_audit\.sh$"
    r"|^docs/|\.lock$|/assets/i18n/|/assets/data/|firestore-debug\.log$"
    r"|firebase-debug\.log$)"
)

SCAN_EXT = (".dart", ".kt", ".java", ".swift", ".gradle", ".yaml", ".yml",
            ".json", ".xml", ".properties", ".plist", ".sh", ".env",
            ".kts", ".m", ".h")

SECRET_PATTERNS = [
    ("Cle privee PEM",
     re.compile(r"-----BEGIN (RSA |EC |DSA |OPENSSH |PGP )?PRIVATE KEY-----")),
    ("Cle API Google (AIza...)",
     re.compile(r"\bAIza[0-9A-Za-z_\-]{35}\b")),
    ("Token Google OAuth (ya29...)",
     re.compile(r"\bya29\.[0-9A-Za-z_\-]+")),
    ("AWS Access Key Id",
     re.compile(r"\b(AKIA|ASIA)[0-9A-Z]{16}\b")),
    ("Token GitHub",
     re.compile(r"\bgh[pousr]_[0-9A-Za-z]{30,}\b")),
    ("Token Slack",
     re.compile(r"\bxox[baprs]-[0-9A-Za-z-]{10,}\b")),
    ("Cle privee Stripe",
     re.compile(r"\bsk_(live|test)_[0-9A-Za-z]{16,}\b")),
    ("Token Bearer en dur",
     re.compile(K_BEAR + r"\s+[A-Za-z0-9._\-]{20,}")),
    ("Affectation sensible en dur",
     re.compile(
         r"(?i)\b(" + "|".join([K_PWD, K_PWD2, "pwd", K_SECR, K_APIK, K_APIK2,
                                 K_ATOK, K_AUTHT, K_CSEC, K_PKEY]) + r")\b"
         r"\s*[:=]\s*[\"'][^\"'\s]{8,}[\"']")),
]

BENIGN_RE = re.compile(
    r"(?i)(your[_-]?|example|placeholder|changeme|xxxx|<[^>]+>|\$\{?[A-Za-z_]"
    r"|String\.fromEnvironment|Platform\.environment|dotenv|t\.[a-z]"
    r"|TODO|FIXME|''|\"\")")

findings = []
scanned = 0

for path in files:
    if EXCLUDE_PATH_RE.search(path):
        continue
    _, ext = os.path.splitext(path)
    base = os.path.basename(path)
    if ext not in SCAN_EXT and base != ".env":
        continue
    if not os.path.isfile(path):
        continue
    scanned += 1
    try:
        with open(path, "r", encoding="utf-8", errors="replace") as fh:
            for lineno, line in enumerate(fh, 1):
                if len(line) > 4000:
                    continue
                for label, rx in SECRET_PATTERNS:
                    if rx.search(line):
                        if label in ("Affectation sensible en dur",
                                     "Token Bearer en dur") \
                                and BENIGN_RE.search(line):
                            continue
                        snippet = line.strip()
                        if len(snippet) > 120:
                            snippet = snippet[:117] + "..."
                        findings.append((path, lineno, label, snippet))
    except Exception:
        continue

print("--- 1. Scan de contenu (%d fichiers scannes) ---" % scanned)
if findings:
    for path, lineno, label, snippet in findings:
        print("  [FUITE] %s:%d  (%s)" % (path, lineno, label))
        print("          %s" % snippet)
else:
    print("  OK : rien de sensible detecte.")
print()

print("--- 2. Verification .gitignore ---")
gitignore_ok = True
try:
    with open(".gitignore", "r", encoding="utf-8", errors="replace") as fh:
        gi = fh.read()
except FileNotFoundError:
    print("  ERREUR : .gitignore introuvable.")
    gitignore_ok = False
    gi = ""

REQUIRED = [
    ("key.properties", ["key.properties"]),
    ("*.keystore", ["*.keystore"]),
    ("*.jks", ["*.jks"]),
    (".env", [".env"]),
    ("google-services.json", ["google-services.json"]),
    ("GoogleService-Info.plist", ["GoogleService-Info.plist"]),
]
missing = []
for label, needles in REQUIRED:
    if not any(n in gi for n in needles):
        missing.append(label)

if missing:
    gitignore_ok = False
    for m in missing:
        print("  [MANQUANT] .gitignore n'exclut pas : %s" % m)
else:
    print("  OK : .gitignore exclut bien les fichiers sensibles attendus.")
print()

print("--- 3. firestore.rules (verification lecture seule) ---")
if os.path.isfile("firestore.rules"):
    with open("firestore.rules", "r", encoding="utf-8", errors="replace") as fh:
        rules = fh.read()
    has_deny = "if false" in rules
    has_follow = "follow_sessions" in rules
    print("  OK : firestore.rules present (%d lignes)." % rules.count("\n"))
    print("       default-deny : %s | follow_sessions couvert : %s"
          % ("oui" if has_deny else "NON", "oui" if has_follow else "NON"))
else:
    print("  ATTENTION : firestore.rules absent (attendu, pose en P0-1).")
print()

print("=== Verdict ===")
if findings or not gitignore_ok:
    nb = len(findings)
    print("ECHEC : %d fuite(s) potentielle(s)%s." %
          (nb, "" if gitignore_ok else " + .gitignore incomplet"))
    sys.exit(1)
print("OK : rien de sensible detecte, .gitignore complet.")
sys.exit(0)
PYEOF
