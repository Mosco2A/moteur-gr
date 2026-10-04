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
# CE QUI A ETE AJOUTE A LA TACHE 676, ET POURQUOI (memoire #101121).
# Le 04/10, deux defauts de LA RECETTE — pas du produit — ont fait conclure de
# travers sur un persona sain :
#   * PROFIL SALE. La recette ne remettait JAMAIS l'application a zero. Rejoue
#     apres S1 Lea, le scenario S2 Marc partait d'un profil deja rempli par Lea
#     et tombait a 2 exigences tenues sur 11, premier echec « carte Faisabilite
#     inatteignable ». Les 15/15 du 645-07 n'etaient donc reproductibles qu'avec
#     un nettoyage fait a la main, c'est-a-dire oubliable.
#     CE QU'ON FAIT : DESINSTALLATION du paquet avant le run (puis reinstallation
#     par `flutter test`, qui installe l'application de toute facon), et CONTROLE
#     que le paquet est bien absent de l'appareil. On desinstalle plutot que
#     `pm clear` parce que la desinstallation emporte AUSSI les dossiers
#     applicatifs du stockage externe (cartes hors ligne, fichiers partages) et
#     que son resultat se verifie d'une seule question, « le paquet est-il encore
#     la ? », qui ne peut pas mentir. `pm clear` reste en REPLI si la
#     desinstallation est impossible ; si aucun des deux n'aboutit, le run est
#     REFUSE — un persona joue sur un profil sale ne prouve rien.
#   * DEMON DE CAPTURES MORT EN SILENCE. Le demon imprimait « en ecoute » puis
#     mourait sans un octet d'erreur : le run allait au bout et rendait 18
#     marqueurs sur 65 sans image. Le controle de fin de run l'attrapait bien,
#     mais APRES dix minutes de persona.
#     CE QU'ON FAIT : une POIGNEE DE MAIN avant le premier marqueur du test. On
#     ecrit un marqueur de test dans le journal et on exige SON image (non vide)
#     dans le budget `-PoigneeTimeoutS`. Pas d'image, ou processus sorti = le run
#     echoue IMMEDIATEMENT, avec la queue du journal du demon. L'image de la
#     poignee de main et sa ligne de manifeste sont effacees ensuite : le
#     controle de fin de run ne voit que le run.
#     `-DemonMortPourTest` tue le demon juste apres son lancement pour reproduire
#     le mode d'echec a volonte (comme `-Legacy` pour la derive des captures).
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
  [switch]$Legacy,
  # 6. REMISE A ZERO DE L'APPLICATION (tache 676). Par defaut le run part d'un
  # profil vierge. L'option ne sert qu'a enquetter sur un etat deja installe.
  [switch]$SansRemiseAZero,
  # 7. POIGNEE DE MAIN AVEC LE DEMON DE CAPTURES (tache 676). Budget d'attente
  # de la premiere image avant de refuser le run.
  [int]$PoigneeTimeoutS = 30,
  # Tue le demon de captures juste apres son lancement : reproduit le mode
  # d'echec du 04/10 pour prouver que la poignee de main l'attrape.
  [switch]$DemonMortPourTest
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

# 6. L'APPLICATION REPART D'UN PROFIL VIERGE (tache 676, memoire #101121).
function Test-PaquetInstalle([string]$serial, [string]$paquet) {
  $lignes = @(& adb -s $serial shell pm list packages $paquet)
  foreach ($l in $lignes) { if ("$l".Trim() -eq "package:$paquet") { return $true } }
  return $false
}

if ($SansRemiseAZero) {
  Write-Output "[$Tag] ATTENTION : remise a zero DESACTIVEE (-SansRemiseAZero). Le profil peut etre celui laisse par un autre persona - un echec ne prouvera rien."
}
else {
  $installeAvant = Test-PaquetInstalle $Serial $pkg
  Write-Output "[$Tag] remise a zero : paquet $pkg installe avant le run = $installeAvant"
  if ($installeAvant) {
    & adb -s $Serial shell am force-stop $pkg | Out-Null
    $sortieDesinstall = @(& adb -s $Serial uninstall $pkg)
    Write-Output "[$Tag] desinstallation : $($sortieDesinstall -join ' ')"
  }
  if (Test-PaquetInstalle $Serial $pkg) {
    Write-Output "[$Tag] desinstallation sans effet - repli sur pm clear"
    $sortieClear = @(& adb -s $Serial shell pm clear $pkg)
    Write-Output "[$Tag] pm clear : $($sortieClear -join ' ')"
    $clearOk = $false
    foreach ($l in $sortieClear) { if ("$l".Trim() -eq 'Success') { $clearOk = $true } }
    if (-not $clearOk) {
      Write-Output "[$Tag] PROFIL NON VIERGE - ni la desinstallation ni pm clear n ont abouti. RUN REFUSE : un persona joue sur un profil sale ne prouve rien."
      exit 66
    }
    Write-Output "[$Tag] profil remis a zero par pm clear (le paquet reste installe, ses donnees sont effacees)"
  }
  else {
    Write-Output "[$Tag] profil vierge GARANTI : le paquet est absent de l appareil, flutter test va le reinstaller"
  }
}

# ECRITURE PARTAGEE DANS LE JOURNAL (tache 676). Le demon de captures tient le
# journal OUVERT EN LECTURE pendant tout le run : `Add-Content` et
# `[IO.File]::WriteAllText` echouent alors avec « fichier en cours d'utilisation
# par un autre processus » (mesure du 04/10). On passe donc par un FileStream qui
# declare explicitement FileShare::ReadWrite, seul mode qui cohabite avec le
# lecteur Python.
function Add-Marqueur([string]$chemin, [string]$ligne) {
  try {
    $fs = [System.IO.File]::Open($chemin, [System.IO.FileMode]::Append, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
    $octets = [System.Text.Encoding]::UTF8.GetBytes($ligne + "`r`n")
    $fs.Write($octets, 0, $octets.Length)
    $fs.Flush()
    $fs.Close()
    return $true
  }
  catch { return $false }
}

function Set-TailleZero([string]$chemin) {
  try {
    $fs = [System.IO.File]::Open($chemin, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::Write, [System.IO.FileShare]::ReadWrite)
    $fs.SetLength(0)
    $fs.Close()
    return $true
  }
  catch { return $false }
}

function Start-Demon([string]$name, [string[]]$argv) {
  $out = Join-Path $logDir "$Tag.$name.log"
  $err = Join-Path $logDir "$Tag.$name.err.log"
  return Start-Process -FilePath 'python' -ArgumentList $argv -WorkingDirectory $repo `
    -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden
}

$manifeste = Join-Path $shotDir '_shots.jsonl'
$nbOuvriers = if ($Legacy) { 1 } else { $Workers }
Write-Output "[$Tag] demons hote (perm=$Perm, duree=$Duree s, captures=$shotDir, ouvriers=$nbOuvriers, legacy=$($Legacy.IsPresent))"
$procShot = Start-Demon 'shot' @('tool/persona_shot_daemon.py', $Serial, $shotDir, '--logfile', $log, '--workers', "$nbOuvriers", '--manifest', $manifeste)
$procs += $procShot
$procs += Start-Demon 'dismiss' @('tool/persona_dialog_dismisser.py', $Serial, "$Duree")
$permArgs = @('tool/persona_perm_granter.py', $Serial, $pkg, "$Duree")
if ($Perm -eq 'avant-plan') { $permArgs += '--avant-plan' }
$procs += Start-Demon 'perm' $permArgs

# 7. LE DEMON DE CAPTURES EST CONTROLE VIVANT AVANT LE PREMIER MARQUEUR DU TEST.
if ($DemonMortPourTest) {
  Write-Output "[$Tag] -DemonMortPourTest : le demon de captures est tue tout de suite (reproduction du mode d echec du 04/10)"
  if ($procShot -and -not $procShot.HasExited) { Stop-Process -Id $procShot.Id -Force -ErrorAction SilentlyContinue }
}

$shotLog = Join-Path $logDir "$Tag.shot.log"
$shotErr = Join-Path $logDir "$Tag.shot.err.log"
$poigneeNom = '_poignee_de_main'
$poigneePng = Join-Path $shotDir "$poigneeNom.png"
if (Test-Path $poigneePng) { Remove-Item $poigneePng -Force -ErrorAction SilentlyContinue }
Write-Output "[$Tag] poignee de main avec le demon de captures (budget $PoigneeTimeoutS s)"
$tPoignee = Get-Date
$poigneeOk = $false
$poigneeMort = $false
$tour = 0
$marqueurEcrit = $false
while (((Get-Date) - $tPoignee).TotalSeconds -lt $PoigneeTimeoutS) {
  if ($procShot -and $procShot.HasExited) { $poigneeMort = $true; break }
  if ((Test-Path $poigneePng) -and ((Get-Item $poigneePng).Length -gt 0)) { $poigneeOk = $true; break }
  # Le marqueur est REPOSE toutes les deux secondes : le demon ouvre le journal
  # et se place a la fin APRES avoir imprime « en ecoute », donc un marqueur
  # unique ecrit trop tot serait perdu sans que le demon soit en faute.
  if ($tour % 4 -eq 0) { if (Add-Marqueur $log "PERSONA_SHOT|$poigneeNom") { $marqueurEcrit = $true } }
  $tour++
  Start-Sleep -Milliseconds 500
}

if (-not $poigneeOk) {
  if ($poigneeMort) {
    Write-Output "[$Tag] DEMON DE CAPTURES HORS SERVICE - le processus est SORTI (mort avant le premier marqueur)"
  }
  elseif (-not $marqueurEcrit) {
    Write-Output "[$Tag] POIGNEE DE MAIN IMPOSSIBLE - le marqueur de test n a jamais pu etre ecrit dans $log (journal verrouille). Ce n est pas le demon : c est la recette."
  }
  else {
    Write-Output "[$Tag] DEMON DE CAPTURES HORS SERVICE - aucune image apres $PoigneeTimeoutS s (processus vivant mais muet, ou screencap casse sur $Serial)"
  }
  Write-Output "[$Tag] journal du demon ($shotLog) :"
  foreach ($l in @(Get-Content $shotLog -Tail 12 -ErrorAction SilentlyContinue)) { Write-Output "[$Tag]   | $l" }
  foreach ($l in @(Get-Content $shotErr -Tail 12 -ErrorAction SilentlyContinue)) { Write-Output "[$Tag]   ! $l" }
  Write-Output "[$Tag] RUN REFUSE AVANT LE PREMIER MARQUEUR : on ne joue pas dix minutes de persona pour finir avec des marqueurs sans image."
  foreach ($p in $procs) { if ($p -and -not $p.HasExited) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue } }
  exit 67
}

$octetsPoignee = (Get-Item $poigneePng).Length
$secPoignee = [int]((Get-Date) - $tPoignee).TotalSeconds
Write-Output "[$Tag] demon de captures VIVANT : image de poignee de main de $octetsPoignee octets obtenue en $secPoignee s"
# Les captures en vol se posent, PUIS on efface toute trace de la poignee de
# main : le manifeste et le journal ne doivent decrire que le run.
Start-Sleep -Milliseconds 1500
Remove-Item $poigneePng -Force -ErrorAction SilentlyContinue
$razManifeste = Set-TailleZero $manifeste
$razLog = Set-TailleZero $log
if (-not ($razManifeste -and $razLog)) {
  Write-Output "[$Tag] ATTENTION : trace de la poignee de main non effacee (manifeste=$razManifeste journal=$razLog) - le controle de fin de run va voir un marqueur $poigneeNom en plus"
}

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

# 8. ON ATTEND QUE LES CAPTURES SOIENT POSEES, ET ON CONTROLE LE DEMON UNE
# SECONDE FOIS (tache 676).
#
# CE QUI SE PASSAIT. La recette dormait 4 secondes puis tuait les demons. Deux
# consequences mesurees le 04/10 : (1) la sortie du test est TAMPONNEE (les
# derniers marqueurs n'arrivent dans le fichier qu'a la sortie du processus), si
# bien qu'un `Stop-Process` a l'aveugle peut tuer le demon avant qu'il les ait
# lus ; (2) un demon MORT EN COURS DE RUN ne se voyait qu'a la fin, dans le
# controle des captures, sous la forme « N marqueurs sans capture » — un
# symptome, pas une cause.
# CE QU'ON FAIT. On attend que CHAQUE marqueur du journal ait sa ligne de
# manifeste, dans un budget, et on dit explicitement si le demon est mort avant
# la fin. Le controle des captures reste le juge : on lui donne juste de quoi
# juger sur un run complet.
$drainBudgetS = 30
$tDrain = Get-Date
$marqueursVus = 0
$captureesVues = 0
while (((Get-Date) - $tDrain).TotalSeconds -lt $drainBudgetS) {
  $marqueursVus = @(Select-String -Path $log -Pattern 'PERSONA_SHOT\|([A-Za-z0-9_\-]+)' -AllMatches |
    ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique).Count
  $captureesVues = @(Get-Content $manifeste -ErrorAction SilentlyContinue |
    ForEach-Object { try { ($_ | ConvertFrom-Json).nom } catch { } } | Sort-Object -Unique).Count
  if ($marqueursVus -gt 0 -and $captureesVues -ge $marqueursVus) { break }
  if ($procShot -and $procShot.HasExited) { break }
  Start-Sleep -Milliseconds 500
}
$demonMortEnCours = ($procShot -and $procShot.HasExited)
if ($demonMortEnCours) {
  Write-Output "[$Tag] DEMON DE CAPTURES MORT AVANT LA FIN DU RUN (processus sorti) : $captureesVues capture(s) pour $marqueursVus marqueur(s). La poignee de main l avait trouve vivant au depart - il est tombe en route."
  foreach ($l in @(Get-Content $shotErr -Tail 12 -ErrorAction SilentlyContinue)) { Write-Output "[$Tag]   ! $l" }
}
elseif ($captureesVues -lt $marqueursVus) {
  Write-Output "[$Tag] ATTENTION : $captureesVues capture(s) pour $marqueursVus marqueur(s) apres $drainBudgetS s d attente - le demon est vivant mais en retard"
}
else {
  Write-Output "[$Tag] captures drainees : $captureesVues/$marqueursVus marqueur(s) en $([int]((Get-Date) - $tDrain).TotalSeconds) s"
}
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
# L'IMAGE DE LA POIGNEE DE MAIN EST REPRISE ICI AUSSI. Une capture encore en vol
# au moment du premier effacement la recreait apres coup, et le controle de fin
# de run la comptait alors comme une image sans marqueur (mesure du 04/10).
if (Test-Path $poigneePng) {
  Remove-Item $poigneePng -Force -ErrorAction SilentlyContinue
  Write-Output "[$Tag] image de poignee de main effacee apres le run (capture en vol au premier effacement)"
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
