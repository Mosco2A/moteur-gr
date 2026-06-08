#!/usr/bin/env bash
#
# security_audit.sh — Audit des dependances (E5.10a, StepWays / moteur_gr).
#
# Objectif : reperer les dependances obsoletes / abandonnees / a risque sans
# JAMAIS forcer d'upgrade majeur risque (ex: Riverpod v3). Le script SIGNALE,
# il n'applique rien.
#
# Verdict (code de sortie) :
#   0  -> aucune dependance CRITIQUE.
#   1  -> au moins une dependance CRITIQUE detectee :
#         - dependance DIRECTE abandonnee (isDiscontinued), OU
#         - paquet vise par un avis de securite (isCurrentAffectedByAdvisory),
#           OU une version courante retiree (isCurrentRetracted).
#   2  -> erreur d'execution (dart/pub indisponible, parsing impossible).
#
# Les packages transitifs abandonnes (tires par une dependance, ex: `js` via
# Firebase web) et les retards de version MAJEURE sont rapportes en
# AVERTISSEMENT, pas en bloquant.
#
# Usage :
#   bash scripts/security_audit.sh
#
set -euo pipefail

# Se placer a la racine du projet (parent de scripts/).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Audit dependances StepWays (security_audit.sh) ==="
echo "Projet : $PROJECT_ROOT"
echo

# --- Pre-requis ---
if ! command -v dart >/dev/null 2>&1; then
  echo "ERREUR : 'dart' introuvable dans le PATH." >&2
  exit 2
fi

PY=""
if command -v python3 >/dev/null 2>&1; then
  PY="python3"
elif command -v python >/dev/null 2>&1; then
  PY="python"
else
  echo "ERREUR : 'python3'/'python' introuvable (parsing JSON)." >&2
  exit 2
fi

# --- Recuperer l'etat des dependances en JSON (dans un fichier temporaire) ---
# IMPORTANT : on ecrit le JSON dans un fichier et on le passe en ARGUMENT a
# Python. Le code Python vient d'un here-doc sur stdin : on ne peut donc PAS
# aussi piper le JSON sur stdin (le here-doc gagnerait).
TMP_JSON="$(mktemp 2>/dev/null || echo "${TMPDIR:-/tmp}/stepways_outdated_$$.json")"
trap 'rm -f "$TMP_JSON"' EXIT

if ! dart pub outdated --json >"$TMP_JSON" 2>/dev/null; then
  # pub outdated peut renvoyer un code non nul ; on tente quand meme de lire le JSON.
  :
fi

if [ ! -s "$TMP_JSON" ]; then
  echo "ERREUR : 'dart pub outdated --json' n'a produit aucun JSON." >&2
  exit 2
fi

# --- Analyse JSON (le chemin du JSON est passe en argv[1]) ---
"$PY" - "$TMP_JSON" <<'PYEOF'
import json, sys

path = sys.argv[1]
try:
    with open(path, "r", encoding="utf-8") as fh:
        data = json.load(fh)
except Exception as e:
    print("ERREUR : JSON pub outdated illisible : %s" % e, file=sys.stderr)
    sys.exit(2)

packages = data.get("packages", [])

def ver(p, key):
    v = p.get(key) or {}
    return v.get("version") if isinstance(v, dict) else None

def major(s):
    if not s:
        return None
    head = s.lstrip("^~>=< ").split(".")[0]
    try:
        return int(head)
    except ValueError:
        return None

direct_discontinued = []   # CRITIQUE
advisories = []            # CRITIQUE (avis securite / version retiree)
trans_discontinued = []    # avertissement
major_behind = []          # avertissement (info upgrade majeur dispo)

for p in packages:
    name = p.get("package", "?")
    kind = p.get("kind", "")  # direct / dev / transitive
    is_disc = bool(p.get("isDiscontinued"))
    advisory = bool(p.get("isCurrentAffectedByAdvisory"))
    retracted = bool(p.get("isCurrentRetracted"))
    cur = ver(p, "current")
    latest = ver(p, "latest")
    resolvable = ver(p, "resolvable")

    if advisory or retracted:
        flag = "avis de securite" if advisory else "version retiree"
        advisories.append((name, cur, flag, resolvable))

    if is_disc:
        if kind in ("direct", "dev"):
            direct_discontinued.append((name, cur, latest))
        else:
            trans_discontinued.append((name, cur, latest))

    # Retard de version MAJEURE sur une dependance directe (info, jamais bloquant).
    if kind in ("direct", "dev") and cur and latest:
        mc, ml = major(cur), major(latest)
        if mc is not None and ml is not None and ml > mc:
            major_behind.append((name, cur, latest, resolvable))

print("--- Dependances directes en retard de version MAJEURE (info) ---")
if major_behind:
    for name, cur, latest, resolvable in sorted(major_behind):
        note = ""
        if name == "flutter_riverpod":
            note = "  [Riverpod v3 = lot dedie futur, NE PAS forcer ici]"
        print("  - %-32s %s -> %s (resolvable: %s)%s"
              % (name, cur, latest, resolvable, note))
    print("  Note : upgrades majeurs NON appliques par ce script (risque).")
else:
    print("  (aucune)")
print()

print("--- Packages transitifs abandonnes (avertissement) ---")
if trans_discontinued:
    for name, cur, latest in sorted(trans_discontinued):
        print("  - %-32s %s (discontinued, tire par une dependance amont)"
              % (name, cur))
    print("  Note : non corrigeable sans mise a jour de la dependance parente.")
else:
    print("  (aucun)")
print()

print("--- CRITIQUE : avis de securite / versions retirees ---")
if advisories:
    for name, cur, flag, resolvable in sorted(advisories):
        print("  - %-32s %s (%s ; resolvable: %s)"
              % (name, cur, flag, resolvable))
else:
    print("  (aucun)")
print()

print("--- CRITIQUE : dependances DIRECTES abandonnees ---")
if direct_discontinued:
    for name, cur, latest in sorted(direct_discontinued):
        print("  - %-32s %s (DISCONTINUED — a remplacer)" % (name, cur))
else:
    print("  (aucune)")
print()

print("=== Verdict ===")
critical = len(direct_discontinued) + len(advisories)
if critical:
    print("CRITIQUE : %d probleme(s) bloquant(s) (avis securite/retire + "
          "directes abandonnees)." % critical)
    sys.exit(1)

print("OK : aucune dependance critique.")
if trans_discontinued or major_behind:
    print("Des avertissements existent (voir ci-dessus) — non bloquants.")
sys.exit(0)
PYEOF
