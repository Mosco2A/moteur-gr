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
# CE QUI A ETE AJOUTE A LA TACHE 685, ET POURQUOI (kaizen #101252).
# Deux defauts de LA RECETTE ont encore fait perdre des runs les 04 et 05/10 :
#   * LA RECETTE ATTENDAIT LE DISQUE DE L'HOTE, PAS LA CHARGE DE L'APPAREIL.
#     Sur un emulateur encore occupe, un run S1 a rendu TROIS captures d'ecrans
#     DIFFERENTS au contenu IDENTIQUE (12c_faisabilite_verdict_reel =
#     13_retour_cockpit = 14_entrainement) : l'appareil servait une image
#     perimee, et le jeu de captures accusait le produit.
#     CE QU'ON FAIT : avant chaque run, on lit `/proc/loadavg` de l'emulateur
#     et on attend que la moyenne 1 min passe sous `-ChargeMax` (3 par defaut),
#     dans un budget de `-ChargeTimeoutS` (10 min). A l'abandon, la ligne le dit
#     FORT et le run part quand meme : la charge mesuree est ecrite dans la
#     ligne FIN, et le verdict de fin de run se lit avec elle.
#   * LA PARADE PRC-003 VIVAIT DANS UN PILOTE JETABLE. Le watchdog de la
#     machine (PRC-003) abat un processus `python|node` au hasard quand le
#     volume grossit de plus de 5 Go/h ; le premier build Gradle d'un arbre
#     neuf en fait 17. Il abat donc le demon de captures et jamais Gradle : un
#     run S1 perdu le 04/10, 0 capture pour 52 marqueurs (memoire #101219).
#     CE QU'ON FAIT : l'APK de debug est CONSTRUIT AVANT d'allumer le moindre
#     demon, et seulement s'il manque (les runs suivants ne paient rien).
#     L'ordre pre-build -> gate de charge -> demons est la parade elle-meme.
#
# -Legacy REPRODUIT L'ANCIENNE RECETTE (pipeline + demon sequentiel) pour pouvoir
# remesurer le defaut a volonte. A n'utiliser que pour ca.
#
# Usage :
#   powershell -File tool/run_persona.ps1 -Scenario integration_test/persona_s1_lea_test.dart `
#              -Tag S1 -Perm avant-plan [-Duree 1800] [-Serial emulator-5554] `
#              [-ChargeMax 3] [-ChargeTimeoutS 600] [-SansGateDeCharge] [-SansPreBuild]
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
  [switch]$DemonMortPourTest,
  # 9. GATE DE CHARGE DE L'EMULATEUR (tache 685). Moyenne 1 min de
  # /proc/loadavg a ne pas depasser avant de lancer le run, et budget d'attente.
  [double]$ChargeMax = 3.0,
  [int]$ChargeTimeoutS = 600,
  # N'attend pas la machine (enquete seulement : un run joue sur un emulateur
  # charge rend des captures qui ne prouvent rien).
  [switch]$SansGateDeCharge,
  # 10. PARADE PRC-003 (tache 685). Ne pre-construit pas l'APK (a n'utiliser
  # que si le build est deja chaud et qu'on veut gagner la verification).
  [switch]$SansPreBuild,
  # 11. BLUETOOTH DE L'IMAGE D'EMULATEUR (tache 685). Coupe par defaut : la
  # pile Bluetooth de l'image android-34 google_apis part en boucle de
  # plantage autour des bascules de mode avion. A ne garder allume que pour
  # une enquete sur cette pile.
  [switch]$SansCoupureBluetooth
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

# 11. LE BLUETOOTH DE L'IMAGE EST COUPE AVANT LE RUN (tache 685, kaizen
# #101252).
#
# CE QUI A ETE MESURE, LE 05/10, DANS LE LOGCAT DU RUN S4 (parcours hors-ligne
# d'Ines). La bascule en mode avion du scenario declenche une BOUCLE DE
# PLANTAGE de la pile Bluetooth de l'IMAGE D'EMULATEUR - pas de
# l'application :
#   07:48:32  bt_stack_manager_thread demarre
#   07:48:36  F/libc : Fatal signal 6 (SIGABRT) in tid bt_stack_manage,
#             pid droid.bluetooth (com.google.android.bluetooth)
#   07:48:59  E/ActivityManager : ANR in com.google.android.bluetooth
#   07:50:10  ANR in com.google.android.bluetooth (le second)
# 34 lignes bt_stack_manage et 8 reinitialisations de pile (event_init_stack)
# dans le seul run S4. L'ANR du service systeme etouffe l'application : le run
# S4 du 05/10 a rendu 0 marqueur et 0 capture.
#
# L'IMAGE EN CAUSE, NOMMEE : google/sdk_gphone64_x86_64/emu64xa:14/
# UE1A.230829.050/12077443:userdebug, c'est-a-dire
# system-images/android-34/google_apis/x86_64 - celle que portent TOUS les AVD
# de la machine (GR20_B12, GR20_Demo, GR20_Pixel6, GR20_V3_Recette, StepWays,
# DiagAlt_Pixel7). Aucun n'a `hw.bluetooth=no` dans son config.ini : la pile
# tourne donc par defaut.
#
# CE QU'ON FAIT, ET POURQUOI C'EST SANS RISQUE POUR LA MESURE. On eteint la
# pile avant le run (`svc bluetooth disable` + `settings put global
# bluetooth_on 0`), et on VERIFIE que le reglage est bien a 0. AUCUN scenario
# persona n'exerce le Bluetooth : la seule fonction qui s'en sert est la
# ceinture de frequence cardiaque (`HeartRateBleService`, phase 6), et elle
# n'est traversee par aucun des huit parcours ni par aucune route. Couper la
# pile ne peut donc rendre vert aucun chemin du produit - c'est du bruit
# d'image en moins, pas une garde desarmee. La garde de test le verifie.
#
# LA VRAIE CORRECTION EST DANS L'IMAGE, pas ici : voir la recette
# (integration_test/campagne_v2/CAMPAGNE_V2.md, section 12) pour l'image
# recommandee et le reglage `hw.bluetooth=no`.
# AUCUNE DE CES TROIS FONCTIONS NE REND DE VALEUR, ET C'EST VOLONTAIRE. Dans
# PowerShell, tout `Write-Output` d'une fonction PART DANS SA VALEUR DE RETOUR :
# une fonction qui ecrit six lignes et finit par `return $true` rend un TABLEAU
# de sept elements, et l'appelant qui ferait `| Out-Null` pour jeter le booleen
# jetterait les six lignes avec. Les fonctions de preparation ECRIVENT donc, et
# celle qui a un resultat a transmettre le depose dans des variables de script.
function Disable-BluetoothEmulateur([string]$serial, [string]$tag) {
  & adb -s $serial shell svc bluetooth disable 2>&1 | Out-Null
  & adb -s $serial shell settings put global bluetooth_on 0 2>&1 | Out-Null
  $etat = (@(& adb -s $serial shell settings get global bluetooth_on) -join '').Trim()
  if ($etat -eq '0') {
    Write-Output "[$tag] BLUETOOTH : pile ETEINTE avant le run (bluetooth_on=0) - la boucle SIGABRT bt_stack_manage de l image ne peut plus etouffer l application sur les bascules de mode avion"
  }
  else {
    Write-Output "[$tag] BLUETOOTH : extinction SANS EFFET (bluetooth_on='$etat') - si ce run bascule en mode avion, attendez-vous a des ANR de com.google.android.bluetooth et lisez le logcat avant d accuser le produit"
  }
}

# 10. LA PARADE PRC-003 EST DANS LA RECETTE, PLUS DANS LA MEMOIRE DE QUI LANCE
# (tache 685, incident remonte par Artemis au 645-06b, memoire #101219).
#
# CE QUI S'EST PASSE. skynet_watchdog.py (regle PRC-003, _find_disk_hog) a TUE
# le demon de captures a 20:18:55 le 04/10 : run S1 perdu, 0 capture pour 52
# marqueurs, dix minutes jetees. CAUSE MESUREE : le PREMIER build Gradle d'un
# arbre neuf fait croitre l'occupation du volume de 17 Go/h, tres au-dessus du
# seuil critique de 5 Go/h - et le tueur ne regarde QUE python|node, donc il
# abat le demon de captures (python) et jamais Gradle (java).
#
# CE QU'ON FAIT, ET POURQUOI C'EST ICI ET PAS AILLEURS. On fait la grosse
# ecriture AVANT d'allumer le moindre demon : plus de processus python a abattre
# pendant la rafale d'E/S. Artemis l'a applique a la main (pilote jetable
# driver_679.ps1) ; une parade qui vit dans un script jetable est une parade
# oubliee au prochain run, donc elle est gravee ici.
#
# LE PRE-BUILD NE COUTE QUE LA PREMIERE FOIS : il est saute si l'APK de debug
# est deja la (arbre deja chauffe), ce qui est le cas de tous les runs suivants.
function Invoke-PreBuild([string]$repoPath, [string]$tag) {
  $apk = Join-Path $repoPath 'build/app/outputs/flutter-apk/app-debug.apk'
  if (Test-Path $apk) {
    Write-Output "[$tag] PRC-003 : APK de debug deja construit, pre-build saute (arbre chaud)"
    return
  }
  Write-Output "[$tag] PRC-003 : premier build de cet arbre - APK CONSTRUIT AVANT TOUT DEMON (le watchdog abat un python, jamais Gradle)"
  $t0 = Get-Date
  & flutter build apk --debug | Out-Null
  $code = $LASTEXITCODE
  $sec = [int]((Get-Date) - $t0).TotalSeconds
  if ($code -ne 0) {
    Write-Output "[$tag] PRC-003 : pre-build en ECHEC (code $code, ${sec}s) - on continue, flutter test reconstruira, mais la rafale d E/S tombera pendant les demons"
    return
  }
  Write-Output "[$tag] PRC-003 : pre-build termine en ${sec}s, demons encore eteints"
}

# 9. LE RUN ATTEND QUE LA MACHINE SOIT CALME (tache 685, kaizen #101252).
#
# CE QUE LA MESURE A MONTRE, ET CE QU'ELLE A COUTE. La recette attendait la
# VITESSE DU DISQUE de l'hote (parade PRC-003) mais jamais la CHARGE DE
# L'APPAREIL. Le 05/10, sur un emulateur encore occupe, un run S1 a rendu trois
# captures d'ecrans DIFFERENTS au contenu IDENTIQUE (12c_faisabilite_verdict_reel
# = 13_retour_cockpit = 14_entrainement, dix secondes et un appui entre les
# deux) : l'appareil servait une image perimee. Lu sans cette cause, ce jeu de
# captures accuse le produit. Artemis a fait lire /proc/loadavg a la main et a
# refuse de demarrer au-dessus de 3 ; c'est grave ici.
#
# POURQUOI 3. /proc/loadavg rend le nombre moyen de taches pretes a tourner. Le
# noyau de l'emulateur voit 4 processeurs : au-dela de 3, la file d'attente est
# du meme ordre que le nombre de coeurs, et un `screencap` (327 ms en median,
# 764 ms en pointe) part en retard. En dessous, les mesures du 05/10 tiennent
# (S1 61/2 et S3 17/1 des deux cotes DES QUE la machine est calme).
#
# A L'ABANDON, ON LE DIT FORT ET ON JOUE QUAND MEME. Refuser le run bloquerait
# la campagne sur une machine durablement chargee ; le taire rendrait un rapport
# illisible. La ligne d'abandon est donc explicite, et la charge mesuree est
# ecrite dans le journal du run : le verdict de fin de run se lit avec elle.
function Wait-ChargeCalme([string]$serial, [double]$seuil, [int]$budgetS, [string]$tag) {
  $script:ChargeMesuree = -1.0
  $script:ChargeCalme = $false
  $script:ChargeAbandon = $false
  $script:ChargeLisible = $false
  $t0 = Get-Date
  $derniere = -1.0
  $tours = 0
  while (((Get-Date) - $t0).TotalSeconds -lt $budgetS) {
    $brut = (@(& adb -s $serial shell cat /proc/loadavg) -join ' ').Trim()
    $bouts = $brut -split '\s+'
    if ($bouts.Count -lt 3) {
      Write-Output "[$tag] CHARGE : /proc/loadavg illisible sur $serial (lu : '$brut') - gate de charge SAUTEE, le run part sans cette garantie"
      return
    }
    $derniere = [double]::Parse($bouts[0], [Globalization.CultureInfo]::InvariantCulture)
    if ($derniere -lt $seuil) {
      $sec = [int]((Get-Date) - $t0).TotalSeconds
      Write-Output "[$tag] CHARGE : emulateur CALME (1 min = $derniere < $seuil) apres ${sec}s d attente - loadavg complet : $brut"
      $script:ChargeMesuree = $derniere
      $script:ChargeCalme = $true
      $script:ChargeLisible = $true
      return
    }
    if ($tours % 6 -eq 0) {
      $sec = [int]((Get-Date) - $t0).TotalSeconds
      Write-Output "[$tag] CHARGE : emulateur OCCUPE (1 min = $derniere, seuil $seuil) - attente ${sec}s / ${budgetS}s"
    }
    $tours++
    Start-Sleep -Seconds 5
  }
  Write-Output "[$tag] CHARGE : ABANDON DE L ATTENTE - la moyenne 1 min est restee a $derniere (seuil $seuil) pendant $budgetS s. LE RUN PART QUAND MEME, et ce qu il rendra doit se lire avec ce chiffre : sur emulateur charge, un screencap part en retard et deux ecrans differents peuvent rendre la meme image."
  $script:ChargeMesuree = $derniere
  $script:ChargeAbandon = $true
  $script:ChargeLisible = $true
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

# ---------------------------------------------------------------------------
# L'ORDRE DES QUATRE ETAPES SUIVANTES N'EST PAS UN GOUT, C'EST LA PARADE.
#   0. BLUETOOTH  : la pile de l image est eteinte avant que l application
#                   demarre, donc avant toute bascule de mode avion ;
#   1. PRE-BUILD  : la rafale d E/S de Gradle passe AVANT qu un demon existe
#                   (PRC-003 abat un python au hasard, jamais Gradle) ;
#   2. GATE DE CHARGE : on attend que l emulateur ait digere, sinon un
#                   screencap part en retard et rend l image d un autre ecran ;
#   3. DEMONS     : allumes en dernier, sur une machine calme.
# Inverser 1 et 3 coute un run entier (mesure du 04/10, memoire #101219).
# ---------------------------------------------------------------------------
if ($SansCoupureBluetooth) {
  Write-Output "[$Tag] BLUETOOTH : coupure DESACTIVEE (-SansCoupureBluetooth) - sur un parcours qui bascule en mode avion, l image part en boucle de plantage et le run peut rendre 0 capture"
}
else {
  Disable-BluetoothEmulateur $Serial $Tag
}

if ($SansPreBuild) {
  Write-Output "[$Tag] PRC-003 : pre-build DESACTIVE (-SansPreBuild) - si cet arbre est neuf, le watchdog peut abattre le demon de captures pendant le build"
}
else {
  Invoke-PreBuild $repo $Tag
}

$ChargeMesuree = -1.0
$ChargeCalme = $false
$ChargeAbandon = $false
$ChargeLisible = $false
if ($SansGateDeCharge) {
  Write-Output "[$Tag] CHARGE : gate DESACTIVEE (-SansGateDeCharge) - les doublons de captures de ce run ne prouveront rien sur le produit"
}
else {
  Wait-ChargeCalme $Serial $ChargeMax $ChargeTimeoutS $Tag
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
$chargeDite = if ($ChargeLisible) { "$ChargeMesuree" } else { 'non_mesuree' }
$chargeVerdict = if ($ChargeAbandon) { 'ABANDON' } elseif ($ChargeCalme) { 'calme' } else { 'non_attendue' }
Write-Output "[$Tag] FIN exit=$code duree=${duree}s exigences_ok=$ok exigences_echec=$ko captures=$shots charge_1min=$chargeDite gate_charge=$chargeVerdict"

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
