# Gate de formatage — Moteur GR (StepWays). Tache 643, temps 1 de l'assainissement.
#
# Meme gate que tool/gate_format.sh, pour un poste Windows sans Git Bash.
# Verifie que tout le code Dart ECRIT A LA MAIN est conforme a `dart format`.
# Ne reformate rien : il constate, et sort en erreur s'il reste du travail.
#
#   .\tool\gate_format.ps1        -> code de sortie 0 si conforme, 1 sinon
#
# Perimetre, exclusions et limites : voir l'en-tete de tool/gate_format.sh.
# Ce script NE TOUCHE AUCUNE REGLE D'ANALYSE : analysis_options.yaml est
# inchange, et `flutter analyze` reste la gate d'analyse, separee de celle-ci.

$ErrorActionPreference = 'Stop'

$racine = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $racine

$liste = @(git ls-files '*.dart' | Where-Object { $_ -notmatch '\.(g|freezed)\.dart$' })

if ($liste.Count -eq 0) {
    Write-Output "gate_format : BLOQUE - aucun fichier Dart trouve depuis $racine."
    exit 1
}

# dart format est appele par paquets : la ligne de commande Windows plafonne
# vers 8 000 caracteres, et la liste complete la depasse largement.
$aReformater = New-Object System.Collections.Generic.List[string]
$paquet = 80

for ($i = 0; $i -lt $liste.Count; $i += $paquet) {
    $fin = [Math]::Min($i + $paquet - 1, $liste.Count - 1)
    $lot = $liste[$i..$fin]
    $sortie = & dart format --output=none --set-exit-if-changed @lot 2>&1
    foreach ($ligne in $sortie) {
        if ("$ligne" -like 'Changed *') {
            $aReformater.Add(("$ligne" -replace '^Changed ', ''))
        }
    }
}

if ($aReformater.Count -eq 0) {
    Write-Output "gate_format : OK - $($liste.Count) fichiers Dart ecrits a la main, tous conformes a dart format."
    exit 0
}

Write-Output "gate_format : ECHEC - $($aReformater.Count) fichier(s) sur $($liste.Count) a reformater."
foreach ($fichier in $aReformater) {
    Write-Output "  a reformater : $fichier"
}
Write-Output ""
Write-Output "Pour corriger : dart format lib test integration_test tool test_driver"
exit 1
