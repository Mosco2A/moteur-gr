# RECETTE DE LANCEMENT D'UN RUN PERSONA — tache 547, campagne complete.
#
# Applique A LA LETTRE la section 12 de integration_test/campagne_v2/CAMPAGNE_V2.md :
#   1. le fichier de log est CREE AVANT le demon de captures (le demon se place a
#      la fin du fichier a l'ouverture : si le test le recreait, le demon garderait
#      l'ancien descripteur et ne verrait plus rien) ;
#   2. la sortie du test est redirigee en AJOUT, jamais en ecrasement ;
#   3. les trois demons hote sont lances DEPUIS POWERSHELL (Git Bash convertit
#      /sdcard/... et fait echouer le dump d'ecran EN SILENCE) ;
#   4. le jeu de permissions depend du scenario (-Perm avant-plan | complet).
#
# Usage :
#   powershell -File tool/run_persona.ps1 -Scenario integration_test/persona_s1_lea_test.dart `
#              -Tag S1 -Perm avant-plan [-Duree 1800] [-Serial emulator-5554]
param(
  [Parameter(Mandatory = $true)][string]$Scenario,
  [Parameter(Mandatory = $true)][string]$Tag,
  [ValidateSet('avant-plan', 'complet')][string]$Perm = 'avant-plan',
  [int]$Duree = 1800,
  [string]$Serial = 'emulator-5554',
  [string]$Base = 'data/campagne_547'
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$logDir = Join-Path $repo "$Base/logs"
$shotDir = Join-Path $repo "$Base/captures/$Tag"
New-Item -ItemType Directory -Force $logDir | Out-Null
New-Item -ItemType Directory -Force $shotDir | Out-Null

$log = Join-Path $logDir "$Tag.run.log"
# 2. AJOUT, JAMAIS ECRASEMENT : si le fichier existe deja (re-run), on l'archive.
if (Test-Path $log) { Move-Item $log "$log.$(Get-Date -Format yyyyMMdd-HHmmss).bak" -Force }
# 1. LE LOG EXISTE AVANT LE DEMON.
New-Item -ItemType File $log | Out-Null

$pkg = 'com.only1cent.moteur_gr'
$procs = @()

function Start-Demon([string]$name, [string[]]$argv) {
  $out = Join-Path $logDir "$Tag.$name.log"
  $err = Join-Path $logDir "$Tag.$name.err.log"
  return Start-Process -FilePath 'python' -ArgumentList $argv -WorkingDirectory $repo `
    -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
}

Write-Output "[$Tag] demons hote (perm=$Perm, duree=$Duree s, captures=$shotDir)"
$procs += Start-Demon 'shot' @('tool/persona_shot_daemon.py', $Serial, $shotDir, '--logfile', $log)
$procs += Start-Demon 'dismiss' @('tool/persona_dialog_dismisser.py', $Serial, "$Duree")
$permArgs = @('tool/persona_perm_granter.py', $Serial, $pkg, "$Duree")
if ($Perm -eq 'avant-plan') { $permArgs += '--avant-plan' }
$procs += Start-Demon 'perm' $permArgs

Start-Sleep -Seconds 3
$debut = Get-Date
Write-Output "[$Tag] run : flutter test $Scenario -d $Serial (>> $log)"
& flutter test $Scenario -d $Serial --reporter expanded | Out-File -FilePath $log -Append -Encoding utf8
$code = $LASTEXITCODE
$duree = [int]((Get-Date) - $debut).TotalSeconds

Start-Sleep -Seconds 4
foreach ($p in $procs) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }

$shots = (Get-ChildItem $shotDir -Filter *.png -ErrorAction SilentlyContinue | Measure-Object).Count
$ok = (Select-String -Path $log -Pattern 'PERSONA_EXIGENCE\|.*\|OK\|' -AllMatches | Measure-Object).Count
$ko = (Select-String -Path $log -Pattern 'PERSONA_EXIGENCE\|.*\|ECHEC\|' -AllMatches | Measure-Object).Count
Write-Output "[$Tag] FIN exit=$code duree=${duree}s exigences_ok=$ok exigences_echec=$ko captures=$shots"
exit $code
