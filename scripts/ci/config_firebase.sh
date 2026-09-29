#!/bin/sh
# ============================================================================
# LA CONFIGURATION FIREBASE ARRIVE A LA FABRICATION, ET JAMAIS PAR LE DEPOT
# (StepWays, tache 626)
# ============================================================================
#
# CE QUE CE SCRIPT REPARE, ET C EST MESURE. Le 28/09/2026 au soir, Firebase
# etait MUET sur les deux telephones, pour deux raisons differentes :
#
#   * ANDROID — `android/app/google-services.json` est exclu du depot
#     (.gitignore, decision de la tache 604) et AUCUNE chaine de fabrication ne
#     le fournissait. La tache 619 a rendu les greffons Gradle conditionnels
#     (`android/app/build.gradle.kts`) pour que le paquet se construise quand
#     meme : l APK sortait donc, et Firebase y dormait.
#   * IPHONE — `ios/Runner/GoogleService-Info.plist` n etait reference NULLE
#     PART dans `ios/Runner.xcodeproj/project.pbxproj` (mesure de la tache
#     618). Meme depose a la main, il n entrait pas dans le paquet, donc le SDK
#     ne le lisait pas.
#
# Consequence : rien de ce que le collecteur serveur publie ne pouvait arriver
# sur le telephone. Ce script est le premier des deux bouts du tuyau ; l autre
# est la reference iPhone ajoutee au projet Xcode par la meme tache.
#
# LA REGLE QUI COMMANDE TOUT. Aucune valeur de configuration n entre dans le
# depot. Un `google-services.json` n est pas un secret au sens d un mot de
# passe — il voyage dans chaque paquet distribue et se lit en decompressant
# l APK — mais il porte des cles d API, et la regle de Christophe est sans
# exception. Les deux fichiers arrivent donc ici, a la fabrication, depuis des
# variables d environnement encodees en base64, et les deux sont dans
# `.gitignore`.
#
# TROIS ACTIONS :
#
#   deposer <android|ios|tout> [exiger]
#       Ecrit le ou les fichiers de configuration depuis les variables
#       d environnement. A appeler AVANT `flutter build`, dans les chaines qui
#       doivent produire un paquet ou Firebase parle.
#
#       Avec `exiger`, l absence de configuration ARRETE la chaine au lieu de
#       prevenir. C est le bon reglage pour tout paquet qui part chez quelqu un
#       — magasin ou testeur TestFlight : un paquet livre avec Firebase muet est
#       un test pour rien, et personne ne s en apercoit avant de chercher le
#       catalogue sur le telephone. Sans `exiger`, la chaine continue et ecrit
#       dans son journal que Firebase sera muet : c est le bon reglage pour une
#       chaine qui compile toute branche, ou le paquet sert a autre chose.
#
#   garantir-ios
#       Garantit la seule chose dont Xcode a besoin : que le fichier EXISTE.
#       Appele par une phase du projet Xcode, avant la copie des ressources.
#       Sans lui, le projet reference un fichier absent et xcodebuild s arrete
#       sur « Build input file cannot be found » — ce qui casserait la chaine
#       `ios_compile` de la tache 618, qui compile sur TOUTE branche et n a
#       aucune raison de connaitre Firebase.
#
#   etat
#       Dit ce qui est present et ce qui manque. Ne modifie rien.
#
# VARIABLES LUES (leurs NOMS sont publics, leurs valeurs ne le sont jamais) :
#
#   STEPWAYS_GOOGLE_SERVICES_JSON        android/app/google-services.json,
#                                        encode en base64
#   STEPWAYS_GOOGLE_SERVICE_INFO_PLIST   ios/Runner/GoogleService-Info.plist,
#                                        encode en base64
#   STEPWAYS_FIREBASE_PROJECT_ID         identifiant du projet Firebase. C est
#                                        le commutateur du cote Dart
#                                        (`FirebaseConfig`, tache 596) : sans
#                                        lui l application ne demarre PAS
#                                        Firebase, meme avec les fichiers en
#                                        place. Il doit etre passe en
#                                        --dart-define a la commande de build.
#
# LE PIEGE QUE CE SCRIPT FERME AU PASSAGE. « Identifiant de projet fourni, mais
# fichier de configuration absent » est la combinaison la plus dangereuse : le
# code Dart appelle alors `Firebase.initializeApp()`, le SDK natif ne trouve pas
# ses options et leve une exception qui ne se rattrape pas depuis Dart. Le
# `try/catch` de `FirebaseService.initialize` ne protege de rien dans ce cas.
# Cette combinaison ARRETE donc la fabrication, ici, avec un message — plutot
# que de livrer a Christophe un paquet qui se ferme au demarrage.
# ============================================================================

set -eu

action="${1:-}"
cible="${2:-tout}"
exigence="${3:-}"

racine=$(cd "$(dirname "$0")/../.." && pwd)
fichier_android="$racine/android/app/google-services.json"
fichier_ios="$racine/ios/Runner/GoogleService-Info.plist"

# Le paquet reel des deux plateformes (tache 604, IRREVERSIBLE apres
# publication). Une configuration qui vise un autre paquet est refusee par
# Firebase au demarrage, en silence du point de vue de l utilisateur.
paquet_attendu="com.only1cent.stepways"

# La marque du fichier FACTICE ecrit par `garantir-ios`. Elle doit rester
# identique a celle que cherche l invariante Dart de la tache 626.
marque_factice="STEPWAYS_CONFIGURATION_FIREBASE_ABSENTE"

barre="============================================================"

# --- Decodage base64, portable Linux (Android) et macOS (iPhone) -------------
# GNU coreutils accepte `--decode` et `-d`, BSD/macOS `-D`. `--decode` existe
# sur les deux versions recentes, mais on ne SUPPOSE pas : on essaie.
decoder_base64() {
  if printf '' | base64 --decode >/dev/null 2>&1; then
    base64 --decode
  else
    base64 -D
  fi
}

# Une variable saisie dans une interface web traine souvent des retours a la
# ligne et des espaces. L alphabet base64 n en contient aucun : les retirer est
# sans risque, et sans cela le decodage echoue sur une valeur parfaitement
# valide.
ecrire_depuis_base64() {
  valeur="$1"
  destination="$2"
  mkdir -p "$(dirname "$destination")"

  # LE `if` N EST PAS DECORATIF. Avec `set -e`, l echec du decodage tue le
  # script AVANT le message qui explique quoi faire : mesure le 29/09 sur une
  # valeur volontairement invalide, seul « base64: invalid input » sortait. Sous
  # `if`, l echec est traite, pas fatal.
  #
  # ET LE FICHIER VIDE EST RETIRE. La redirection cree le fichier meme quand le
  # decodage echoue. Un `google-services.json` VIDE est pire qu absent : le
  # `file(...).exists()` de build.gradle.kts devient vrai, les greffons se
  # posent, et le build s arrete sur une erreur de Google Services qui ne
  # designe pas la vraie cause.
  if printf '%s' "$valeur" | tr -d '\r\n \t' | decoder_base64 \
      > "$destination" 2>/dev/null && [ -s "$destination" ]; then
    return 0
  fi

  rm -f "$destination"
  echo "$barre"
  echo "ARRET — le decodage base64 a echoue :"
  echo "  $destination"
  echo ""
  echo "La variable existe mais son contenu n est pas du base64 valide."
  echo "Recette de l encodage, a refaire sur le poste de Christophe :"
  echo "  macOS  : base64 -i <fichier> | tr -d '\\n'"
  echo "  Linux  : base64 -w0 <fichier>"
  echo ""
  echo "Coller la valeur obtenue TELLE QUELLE dans Codemagic, sans guillemets."
  echo "$barre"
  exit 1
}

# --- Controles de coherence -------------------------------------------------
# Un fichier decode mais qui vise un AUTRE projet ou un AUTRE paquet est pire
# qu absent : la fabrication reussit, le paquet s installe, et Firebase refuse
# l application au demarrage sans que rien ne l explique.
verifier_contenu() {
  chemin="$1"
  quoi="$2"
  contenu=$(cat "$chemin")

  case "$contenu" in
    *"$paquet_attendu"*) ;;
    *)
      echo "$barre"
      echo "ARRET — $quoi ne vise pas le paquet de StepWays."
      echo ""
      echo "Attendu : $paquet_attendu"
      echo "Cette configuration a ete telechargee pour une AUTRE application"
      echo "du projet Firebase. Firebase refusera l application au demarrage."
      echo "$barre"
      exit 1
      ;;
  esac

  case "$contenu" in
    *gr20-app*)
      echo "$barre"
      echo "ARRET — $quoi designe le projet 'gr20-app'."
      echo ""
      echo "StepWays a un projet DEDIE, 'stepways-app'. Zero mutualisation de"
      echo "donnees, de comptes ou de quotas avec l ancienne application"
      echo "(#326 divorce). Reprendre la configuration depuis le bon projet."
      echo "$barre"
      exit 1
      ;;
  esac

  if [ -n "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
    case "$contenu" in
      *"$STEPWAYS_FIREBASE_PROJECT_ID"*) ;;
      *)
        echo "$barre"
        echo "ARRET — $quoi et STEPWAYS_FIREBASE_PROJECT_ID ne parlent pas du"
        echo "meme projet."
        echo ""
        echo "Le code Dart demarrera Firebase pour"
        echo "  '$STEPWAYS_FIREBASE_PROJECT_ID'"
        echo "alors que le fichier de configuration natif en designe un autre."
        echo "Le SDK echoue au demarrage, et l application retombe en mode"
        echo "local sans que personne ne sache pourquoi."
        echo "$barre"
        exit 1
        ;;
    esac
  fi
}

exiger_configuration() {
  quoi="$1"
  variable="$2"
  echo "$barre"
  echo "ARRET — STEPWAYS_FIREBASE_PROJECT_ID est fourni, mais $quoi manque."
  echo ""
  echo "C est la combinaison la plus dangereuse : le code Dart appellera"
  echo "Firebase.initializeApp(), le SDK natif ne trouvera pas ses options,"
  echo "et il leve une exception que le try/catch de FirebaseService NE"
  echo "RATTRAPE PAS — l application se ferme au demarrage."
  echo ""
  echo "Deux sorties, et les deux sont propres :"
  echo "  1. remplir la variable $variable"
  echo "     (groupe d environnement Codemagic 'stepways_firebase') ;"
  echo "  2. OU retirer STEPWAYS_FIREBASE_PROJECT_ID de cette chaine : le"
  echo "     paquet se construit, s installe, et tourne en mode local — le"
  echo "     catalogue distant est muet et le repli sur les sentiers"
  echo "     compiles prend le relais (acquis du lot 605)."
  echo "$barre"
  exit 1
}

# Le refus quand la chaine a declare qu un paquet muet n avait pas de sens.
exiger_tout() {
  quoi="$1"
  variable="$2"
  echo "$barre"
  echo "ARRET — cette chaine livre un paquet a quelqu un, et Firebase y serait"
  echo "MUET. Manque : $variable."
  echo ""
  echo "Un paquet depose sur un magasin ou chez un testeur avec Firebase muet"
  echo "est un test pour rien : le catalogue distant reste vide, et personne ne"
  echo "s en apercoit avant de chercher les sentiers sur le telephone."
  echo ""
  echo "Remplir le groupe d environnement Codemagic 'stepways_firebase' :"
  echo "  STEPWAYS_GOOGLE_SERVICES_JSON       ($quoi, Android)"
  echo "  STEPWAYS_GOOGLE_SERVICE_INFO_PLIST  (iPhone)"
  echo "  STEPWAYS_FIREBASE_PROJECT_ID        (le commutateur cote Dart)"
  echo ""
  echo "Le pas a pas est dans docs/firebase-setup.md, etape 2 ter."
  echo "$barre"
  exit 1
}

annoncer_muet() {
  echo "$barre"
  echo "AVERTISSEMENT — les fichiers de configuration sont en place mais"
  echo "STEPWAYS_FIREBASE_PROJECT_ID est ABSENT."
  echo ""
  echo "Le paquet produit sera parfaitement utilisable, et Firebase y sera"
  echo "MUET : FirebaseConfig.resoudre() rend null, donc"
  echo "Firebase.initializeApp() n est jamais appele (tache 596)."
  echo ""
  echo "Pour un paquet ou Firebase parle, passer la variable a la chaine ET"
  echo "l ajouter a la commande de build :"
  echo "  --dart-define=STEPWAYS_FIREBASE_PROJECT_ID=\$STEPWAYS_FIREBASE_PROJECT_ID"
  echo "$barre"
}

# --- Action : deposer -------------------------------------------------------
deposer() {
  plateforme="$1"
  exige="$2"
  fait=0

  if [ "$exige" = "exiger" ] && [ -z "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
    exiger_tout "google-services.json" "STEPWAYS_FIREBASE_PROJECT_ID"
  fi

  if [ "$plateforme" = "android" ] || [ "$plateforme" = "tout" ]; then
    if [ -n "${STEPWAYS_GOOGLE_SERVICES_JSON:-}" ]; then
      ecrire_depuis_base64 "$STEPWAYS_GOOGLE_SERVICES_JSON" "$fichier_android"
      verifier_contenu "$fichier_android" "google-services.json"
      echo "Android : google-services.json ecrit dans android/app/."
      echo "          Les greffons Gradle se poseront (build.gradle.kts, 619)."
      fait=1
    elif [ -n "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
      exiger_configuration "google-services.json (Android)" \
        "STEPWAYS_GOOGLE_SERVICES_JSON"
    else
      echo "Android : aucune configuration Firebase fournie — les greffons ne"
      echo "          seront PAS poses et le catalogue distant restera muet."
    fi
  fi

  if [ "$plateforme" = "ios" ] || [ "$plateforme" = "tout" ]; then
    if [ -n "${STEPWAYS_GOOGLE_SERVICE_INFO_PLIST:-}" ]; then
      ecrire_depuis_base64 "$STEPWAYS_GOOGLE_SERVICE_INFO_PLIST" "$fichier_ios"
      verifier_contenu "$fichier_ios" "GoogleService-Info.plist"
      echo "iPhone  : GoogleService-Info.plist ecrit dans ios/Runner/."
      echo "          Le projet Xcode le copie dans le paquet (tache 626)."
      fait=1
    elif [ -n "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
      exiger_configuration "GoogleService-Info.plist (iPhone)" \
        "STEPWAYS_GOOGLE_SERVICE_INFO_PLIST"
    else
      echo "iPhone  : aucune configuration Firebase fournie — un fichier"
      echo "          FACTICE sera ecrit par la phase Xcode pour que la"
      echo "          compilation passe, et Firebase restera muet."
    fi
  fi

  if [ "$fait" = "1" ] && [ -z "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
    annoncer_muet
  fi
}

# --- Action : garantir-ios --------------------------------------------------
# LE POINT DELICAT, ET LA RAISON D ETRE DE CETTE ACTION. Le projet Xcode
# reference desormais GoogleService-Info.plist dans sa phase de copie des
# ressources — c est la SEULE facon que le SDK Firebase le trouve dans le
# paquet. Mais le fichier est hors depot : sur un clone neuf il n existe pas, et
# xcodebuild s arrete alors sur « Build input file cannot be found ». Le message
# d Xcode dit lui-meme la solution : declarer le fichier comme SORTIE d une
# phase de script. C est exactement ce que fait la phase qui appelle ceci.
#
# On n ecrit donc pas une fausse configuration : on ecrit un fichier
# VOLONTAIREMENT INUTILISABLE par Firebase, marque comme tel. Le comportement
# obtenu est le meme qu aujourd hui (Firebase muet, application utilisable),
# mais la compilation passe. Une configuration factice VRAISEMBLABLE serait
# bien pire : l application croirait parler a un projet et ne parlerait a rien.
garantir_ios() {
  if [ -f "$fichier_ios" ]; then
    echo "Firebase iPhone : GoogleService-Info.plist present — rien a faire."
    return 0
  fi

  mkdir -p "$(dirname "$fichier_ios")"
  cat > "$fichier_ios" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>$marque_factice</key>
	<true/>
	<key>STEPWAYS_LISEZ_MOI</key>
	<string>Fichier FACTICE ecrit par scripts/ci/config_firebase.sh (tache 626) parce que la configuration Firebase reelle etait absente. Il ne porte AUCUNE cle : Firebase ne peut pas demarrer avec lui, et c est voulu. Pour brancher Firebase, deposer le vrai GoogleService-Info.plist a cet emplacement (il est exclu du depot) ou fournir la variable STEPWAYS_GOOGLE_SERVICE_INFO_PLIST a la chaine de fabrication.</string>
</dict>
</plist>
PLIST

  echo "warning: Firebase iPhone MUET — GoogleService-Info.plist absent, un"
  echo "warning: fichier factice a ete ecrit pour que la compilation passe."
  echo "warning: Voir docs/firebase-setup.md (tache 626)."
}

# --- Action : etat ----------------------------------------------------------
etat() {
  echo "$barre"
  echo "ETAT DE LA CONFIGURATION FIREBASE — $racine"
  echo "$barre"

  if [ -f "$fichier_android" ]; then
    echo "android/app/google-services.json      : PRESENT"
  else
    echo "android/app/google-services.json      : absent (Firebase muet)"
  fi

  if [ -f "$fichier_ios" ]; then
    if grep -q "$marque_factice" "$fichier_ios"; then
      echo "ios/Runner/GoogleService-Info.plist   : FACTICE (Firebase muet)"
    else
      echo "ios/Runner/GoogleService-Info.plist   : PRESENT"
    fi
  else
    echo "ios/Runner/GoogleService-Info.plist   : absent (Firebase muet)"
  fi

  if [ -n "${STEPWAYS_FIREBASE_PROJECT_ID:-}" ]; then
    echo "STEPWAYS_FIREBASE_PROJECT_ID          : fourni"
  else
    echo "STEPWAYS_FIREBASE_PROJECT_ID          : absent (mode local assume)"
  fi
  echo "$barre"
}

case "$action" in
  deposer)
    case "$exigence" in
      ''|exiger) ;;
      *)
        echo "ARRET — troisieme argument inconnu : '$exigence'."
        echo "Attendu : rien, ou 'exiger'."
        exit 1
        ;;
    esac
    case "$cible" in
      android|ios|tout) deposer "$cible" "$exigence" ;;
      *)
        echo "ARRET — cible inconnue : '$cible'. Attendu : android, ios, tout."
        exit 1
        ;;
    esac
    ;;
  garantir-ios) garantir_ios ;;
  etat) etat ;;
  *)
    echo "Usage : scripts/ci/config_firebase.sh <action> [cible] [exiger]"
    echo ""
    echo "  deposer <android|ios|tout> [exiger]"
    echo "                               ecrit la configuration depuis les"
    echo "                               variables d environnement ; 'exiger'"
    echo "                               ARRETE au lieu de prevenir quand elle"
    echo "                               manque"
    echo "  garantir-ios                 garantit que le plist iPhone existe"
    echo "  etat                         dit ce qui est present"
    exit 1
    ;;
esac
