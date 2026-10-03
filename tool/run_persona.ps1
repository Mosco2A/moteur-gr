# RECETTE DE LANCEMENT D'UN RUN PERSONA — tache 547, campagne complete.
# Revue a la tache 665 : les captures n'ecrivent plus en retard, et le run le
# PROUVE au lieu de l'esperer.
#
# Applique A LA LETTRE la section 12 de integration_test/campagne_v2/CAMPAGNE_V2.md :
#   1. le fichier de log est CREE AVANT le demon de captures (le demon se place a
#      la fin du fichier a l'ouverture : si le test le recreait, le demon garderait
#      l'ancien descripteur et ne verrait plus rien) ;
#   2. la sortie du test est ecrite par REDIRECTION SYSTEME, jamais par un
#      pipeline PowerShell (voir « LE DEFAUT DE LA RECETTE » ci-dessous) ;
#   3. les trois demons hote sont lances DEPUIS POWERSHELL (Git Bash convertit
#      /sdcard/... et fait echouer le dump d'ecran EN SILENCE) ;
#   4. le jeu de permissions depend du scenario (-Perm avant-plan | complet) ;
#   5. LE RUN SE CONTROLE LUI-MEME : a la fin, `persona_shot_check.py` refuse le
#      run si un marqueur n'a pas sa capture, si deux captures d'ecrans
#      differents sont identiques, ou si une capture a ete lancee trop tard.
#
# LE DEFAUT DE LA RECETTE, ET CE QU'ON EN A FAIT (tache 665, memoire #101082).
# Au 645-05b, des captures persona montraient L'ECRAN SUIVANT celui demande, et
# un run a rendu 0 capture pour 65 marqueurs — sans qu'aucun garde-fou ne
# proteste. La recette rendait donc un jeu d'images d'apparence normale qui
# pouvait faire conclure de travers sur un produit sain.
# Trois choses ont ete corrigees, et une a ete dementie par la mesure :
#   * CAUSE MESUREE (la vraie) : le demon etait SEQUENTIEL — il lisait un
#     marqueur, faisait le `screencap`, et ne lisait le suivant qu'apres. Quand
#     un `adb exec-out screencap` coute plus que l'intervalle entre deux
#     marqueurs (kObserve 900 ms + kShotWait 700 ms = 1,6 s a l'epoque), le
#     retard s'ACCUMULE et la capture tombe sur l'ecran d'apres. Le demon lit et
#     capture maintenant dans des fils separes, et kShotWait est passe a
#     3000 ms (persona_harness.dart) : l'intervalle est le double du cout d'un
#     screencap.
#   * SILENCE : plus rien n'etait verifie. Le demon date desormais chaque
#     capture dans un manifeste (`_shots.jsonl`) et le controle de fin de run
#     lit ce manifeste. Un retard, un doublon, un marqueur sans image = run
#     rouge.
#   * TAMPON : la sortie passait par `| Out-File -Append`, c'est-a-dire par le
#     pipeline PowerShell. On la remplace par une redirection systeme
#     (`Start-Process -RedirectStandardOutput`), qui sort PowerShell du chemin
#     d'ecriture et donne en prime un code de retour fiable (`| Out-File`
#     ecrasait $LASTEXITCODE par celui de Out-File).
#     HONNETETE SUR CE POINT : le tampon du pipeline etait l'explication
#     avancee au 645-05b ; MESURE ICI, il ne se reproduit pas (latence
#     marqueur -> journal de 40 a 98 ms, pipeline comme redirection). La
#     redirection systeme est gardee parce qu'elle est plus courte et rend le
#     code de retour, pas parce qu'elle corrige le retard des captures.
#
# -Legacy REPRODUIT L'ANCIENNE RECETTE (pipeline + demon sequentiel) pour pouvoir
# remesurer le defaut a volonte. A n'utiliser que pour ca.
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
  [string]$Base = 'data/campagne_547',
  # 5. LES --dart-define DU RUN, PASSES AU TEST (tache 651).
  #
  # CE QUI MANQUAIT. La recette passait `flutter test` SANS aucun define : le
  # run tournait donc sans identite Firebase (« Descente des droits : sans
  # effet, Firebase indisponible ») et sans ad-units de test, alors que la
  # campagne, elle, se mesure avec. Un persona rejoue sans les defines ne
  # reproduit pas ce qu'on a mesure — et l'ecart ne se voit nulle part dans le
  # journal. On les rend donc explicites, avec le jeu de la campagne par
  # defaut.
  [string[]]$Defines = @(
    'STEPWAYS_FIREBASE_PROJECT_ID=stepways-app',
    'STEPWAYS_TEST_ADS=true'
  ),
  # Ouvriers de capture du demon. 1 = ancien comportement sequentiel.
  [int]$Workers = 2,
  # Budget de retard entre le marqueur et le depart du `screencap`. Au-dela, le
  # harnais a rendu la main (kShotWait = 3000 ms) et l'image ne prouve plus rien.
  [int]$MaxRetardMs = 2000,
  # Paires de captures legitimement identiques, declarees une par une.
  [string]$Tolerances = 'integration_test/campagne_v2/captures_doublons_tolerees.txt',
  # Reproduit l'ancienne recette (pipeline PowerShell + demon sequentiel).
  [switch]$Legacy
)

$ErrorActionPreference = 'Continue'
$repo = Split-Path -Parent $PSScriptRoot
Set-Location $repo

$logDir = Join-Path $repo "$Base/logs"
$shotDir = Join-Path $repo "$Base/captures/$Tag"
New-Item -ItemType Directory -Force $logDir | Out-Null
New-Item -ItemType Directory -Force $shotDir | Out-Null

$log = Join-Path $logDir "$Tag.run.log"
$errLog = Join-Path $logDir "$Tag.run.err.log"
# 2. AJOUT, JAMAIS ECRASEMENT : si le fichier existe deja (re-run), on l'archive.
$horo = Get-Date -Format yyyyMMdd-HHmmss
if (Test-Path $log) { Move-Item $log "$log.$horo.bak" -Force }
if (Test-Path $errLog) { Move-Item $errLog "$errLog.$horo.bak" -Force }
# LES CAPTURES DU RUN PRECEDENT SONT ARCHIVEES AUSSI. Sinon le controle de fin
# de run compare des images d'avant avec les marqueurs d'aujourd'hui, et un
# marqueur sans capture passe au vert grace a une vieille image du meme nom.
$anciennes = @(Get-ChildItem $shotDir -Filter *.png -ErrorAction SilentlyContinue)
if ($anciennes.Count -gt 0) {
  $arch = Join-Path $logDir "captures_$Tag.$horo"
  New-Item -ItemType Directory -Force $arch | Out-Null
  $anciennes | Move-Item -Destination $arch -Force
  Write-Output "[$Tag] $($anciennes.Count) capture(s) du run precedent archivee(s) dans $arch"
}
# 1. LE LOG EXISTE AVANT LE DEMON.
New-Item -ItemType File $log | Out-Null

$pkg = 'com.only1cent.stepways'
$procs = @()

function Start-Demon([string]$name, [string[]]$argv) {
  $out = Join-Path $logDir "$Tag.$name.log"
  $err = Join-Path $logDir "$Tag.$name.err.log"
  return Start-Process -FilePath 'python' -ArgumentList $argv -WorkingDirectory $repo `
    -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
}

$manifeste = Join-Path $shotDir '_shots.jsonl'
$nbOuvriers = if ($Legacy) { 1 } else { $Workers }
Write-Output "[$Tag] demons hote (perm=$Perm, duree=$Duree s, captures=$shotDir, ouvriers=$nbOuvriers, legacy=$($Legacy.IsPresent))"
$procs += Start-Demon 'shot' @('tool/persona_shot_daemon.py', $Serial, $shotDir, '--logfile', $log, '--workers', "$nbOuvriers", '--manifest', $manifeste)
$procs += Start-Demon 'dismiss' @('tool/persona_dialog_dismisser.py', $Serial, "$Duree")
$permArgs = @('tool/persona_perm_granter.py', $Serial, $pkg, "$Duree")
if ($Perm -eq 'avant-plan') { $permArgs += '--avant-plan' }
$procs += Start-Demon 'perm' $permArgs

Start-Sleep -Seconds 3
$debut = Get-Date
$defArgs = @()
foreach ($d in $Defines) { if ($d) { $defArgs += "--dart-define=$d" } }

if ($Legacy) {
  # ANCIENNE RECETTE, gardee pour pouvoir remesurer le defaut.
  Write-Output "[$Tag] run LEGACY : flutter test $Scenario -d $Serial $($defArgs -join ' ') (| Out-File $log)"
  & flutter test $Scenario -d $Serial --reporter expanded @defArgs | Out-File -FilePath $log -Append -Encoding utf8
  $code = $LASTEXITCODE
}
else {
  # REDIRECTION SYSTEME : PowerShell n'est plus dans le chemin d'ecriture, et le
  # code de retour du test n'est plus ecrase par celui de Out-File.
  $flutter = (Get-Command flutter -ErrorAction Stop).Source
  $argv = @('test', $Scenario, '-d', $Serial, '--reporter', 'expanded') + $defArgs
  Write-Output "[$Tag] run : $flutter $($argv -join ' ') (> $log)"
  $test = Start-Process -FilePath $flutter -ArgumentList $argv -WorkingDirectory $repo `
    -RedirectStandardOutput $log -RedirectStandardError $errLog -PassThru -Wait -WindowStyle Hidden
  $code = $test.ExitCode
}
$duree = [int]((Get-Date) - $debut).TotalSeconds

Start-Sleep -Seconds 4
foreach ($p in $procs) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }

$shots = (Get-ChildItem $shotDir -Filter *.png -ErrorAction SilentlyContinue | Measure-Object).Count
$ok = (Select-String -Path $log -Pattern 'PERSONA_EXIGENCE\|.*\|OK\|' -AllMatches | Measure-Object).Count
$ko = (Select-String -Path $log -Pattern 'PERSONA_EXIGENCE\|.*\|ECHEC\|' -AllMatches | Measure-Object).Count
Write-Output "[$Tag] FIN exit=$code duree=${duree}s exigences_ok=$ok exigences_echec=$ko captures=$shots"

# 5. LE CONTROLE DE FIN DE RUN. Un jeu de captures qui ne tient pas debout fait
# ROUGIR LE RUN : c'est tout l'objet de la tache 665.
$checkJson = Join-Path $logDir "$Tag.captures.json"
$checkArgs = @('tool/persona_shot_check.py', '--log', $log, '--captures', $shotDir,
  '--manifeste', $manifeste, '--max-retard-ms', "$MaxRetardMs", '--json', $checkJson)
if ($Tolerances -and (Test-Path (Join-Path $repo $Tolerances))) {
  $checkArgs += @('--tolerances', (Join-Path $repo $Tolerances))
}
Write-Output "[$Tag] controle des captures :"
& python @checkArgs
$codeCheck = $LASTEXITCODE
if ($codeCheck -ne 0) {
  # ASCII SEUL DANS LES CHAINES DE CE FICHIER. Windows PowerShell 5.1 lit un
  # .ps1 UTF-8 sans BOM avec la page de code ANSI : le 3e octet d'un tiret cadratin
  # (0x94) y devient un guillemet courbe fermant, que PowerShell accepte comme
  # DELIMITEUR DE CHAINE. Un tiret cadratin dans une chaine casse donc le script
  # a l'analyse (il reste tolere dans les commentaires, comme a l'origine).
  Write-Output "[$Tag] CAPTURES REFUSEES - le run est declare ECHEC meme si le test est vert (detail : $checkJson)"
  if ($Legacy) {
    Write-Output "[$Tag] (mode -Legacy : refus signale, code du test conserve pour la mesure)"
  }
  else {
    if ($code -eq 0) { $code = 65 }
  }
}

exit $code
