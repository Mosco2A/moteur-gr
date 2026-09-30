#!/bin/sh
# Gate de formatage — Moteur GR (StepWays). Tache 643, temps 1 de l'assainissement.
#
# Verifie que tout le code Dart ECRIT A LA MAIN est conforme a `dart format`.
# Ne reformate rien : il constate, et sort en erreur s'il reste du travail.
#
#   ./tool/gate_format.sh          -> 0 si tout est conforme, 1 sinon
#
# Perimetre : les memes dossiers que la passe de formatage de la tache 643,
# soit lib/ test/ integration_test/ tool/ test_driver/.
#
# EXCLUSIONS — les fichiers generes (*.g.dart, *.freezed.dart, dont
# lib/i18n/translations*.g.dart produits par `dart run slang`). Ils sont
# regeneres, jamais edites a la main : leur mise en page appartient au
# generateur, pas au depot. Mesure du 30/09/2026 : les 120 fichiers generes
# etaient deja conformes, les exclure ne cachait donc aucun ecart.
#
# Ce script NE TOUCHE AUCUNE REGLE D'ANALYSE : analysis_options.yaml est
# inchange, et `flutter analyze` reste la gate d'analyse, separee de celle-ci.

set -u

RACINE=$(cd "$(dirname "$0")/.." && pwd)
cd "$RACINE" || exit 1

LISTE=$(git ls-files '*.dart' | grep -vE '\.(g|freezed)\.dart$')

if [ -z "$LISTE" ]; then
  echo "gate_format : BLOQUE — aucun fichier Dart trouve depuis $RACINE."
  exit 1
fi

NB_TOTAL=$(printf '%s\n' "$LISTE" | wc -l | tr -d ' ')

# dart format est appele par paquets : la ligne de commande Windows plafonne
# vers 8 000 caracteres, et la liste complete la depasse largement.
SORTIE=$(printf '%s\n' "$LISTE" \
  | tr '\n' '\0' \
  | xargs -0 -n 80 dart format --output=none --set-exit-if-changed 2>&1)
CODE=$?

A_REFORMATER=$(printf '%s\n' "$SORTIE" | grep -c '^Changed ')

if [ "$CODE" -eq 0 ]; then
  echo "gate_format : OK — $NB_TOTAL fichiers Dart ecrits a la main, tous conformes a dart format."
  exit 0
fi

echo "gate_format : ECHEC — $A_REFORMATER fichier(s) sur $NB_TOTAL a reformater."
printf '%s\n' "$SORTIE" | grep '^Changed ' | sed 's/^Changed /  a reformater : /'
echo ""
echo "Pour corriger : dart format lib test integration_test tool test_driver"
exit 1
