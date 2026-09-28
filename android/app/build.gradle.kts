import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// TACHE 619 — LES GREFFONS FIREBASE NE SONT POSES QUE SI LEUR FICHIER EST LA.
//
// CE QUI SE PASSAIT AVANT, ET C EST MESURE. La tache 604 a pose
// `com.google.gms.google-services` en dur. Ce greffon REFUSE DE FONCTIONNER sans
// `android/app/google-services.json` : il arrete le build avec
// « File google-services.json is missing. The Google Services Plugin cannot
// function without it. » Or ce fichier est exclu du depot (.gitignore) et AUCUNE
// chaine ne le fournit — le fichier codemagic.yaml ne le mentionne nulle part.
// Donc, depuis la tache 604, PLUS AUCUN BUILD ANDROID NE PASSAIT : ni en local,
// ni sur le workflow `merge` qui compile pourtant un APK debug. Personne ne
// l avait vu parce que personne n avait recompile Android depuis.
//
// POURQUOI LE RENDRE CONDITIONNEL EST LE BON GESTE, ET PAS UN CONTOURNEMENT.
// Le cote Dart est DEJA conditionnel : `FirebaseService.initialize` ne part que
// si un identifiant de projet lui est donne (`FirebaseConfig.resoudre`, alimente
// par `--dart-define=STEPWAYS_FIREBASE_PROJECT_ID`). L application sait donc
// deja tourner sans Firebase — c est meme le cas nominal hors ligne. Le greffon
// Gradle etait la SEULE piece a exiger ce que le reste du programme traite
// comme facultatif.
//
// CE QUE CELA CHANGE POUR CHRISTOPHE. Avec `google-services.json` depose dans
// `android/app/`, rien ne bouge : les greffons sont poses et Firebase marche
// comme prevu. Sans lui, le paquet se construit quand meme et l application
// s installe — le catalogue distant est simplement muet, et le repli sur les
// sentiers compiles (acquis du lot 605) prend le relais.
val fichierGoogleServices = file("google-services.json")
if (fichierGoogleServices.exists()) {
    apply(plugin = "com.google.gms.google-services")
    apply(plugin = "com.google.firebase.crashlytics")
    logger.lifecycle("Firebase : google-services.json trouve, greffons poses.")
} else {
    logger.warn(
        "Firebase : google-services.json ABSENT — greffons NON poses. " +
            "Le paquet se construit et s installe, mais le catalogue distant " +
            "restera muet (repli sur les sentiers compiles). Deposer le fichier " +
            "dans android/app/ pour activer Firebase."
    )
}

// P1-3 audit #327 [B-2] — signature release hors depot.
// android/key.properties (NON versionne, exclu par android/.gitignore)
// attendu au format :
//   storeFile=<chemin absolu ou relatif a android/ du .keystore>
//   storePassword=<mot de passe du store>
//   keyAlias=<alias de la cle>
//   keyPassword=<mot de passe de la cle>
// AUCUN secret ni keystore ne vit dans le repo.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

android {
    namespace = "com.only1cent.stepways"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.only1cent.stepways"

        // ---------------------------------------------------------------
        // ADMOB — L'APP ID ARRIVE DU BUILD, JAMAIS DU DEPOT (tache 595, B3)
        // ---------------------------------------------------------------
        // LE DEFAUT REPARE : l'App ID etait ecrit EN DUR dans
        // AndroidManifest.xml, donc non injectable. Il n'existait AUCUN
        // manifestPlaceholder dans ce fichier — produire un APK de production
        // aurait exige de modifier un fichier versionne, avec une vraie cle
        // dedans. Les emplacements publicitaires (ad-units), eux, etaient deja
        // proprement injectes par `--dart-define` : l'App ID etait le seul
        // maillon non prevu.
        //
        // TROIS SOURCES, DANS CET ORDRE :
        //   1. propriete gradle  : -PADMOB_APP_ID_ANDROID=ca-app-pub-XXXX~YYYY
        //      (ou une ligne dans ~/.gradle/gradle.properties, HORS DEPOT) ;
        //   2. variable d'environnement ADMOB_APP_ID_ANDROID (CI/Codemagic) ;
        //   3. a defaut, l'App ID de TEST PUBLIC officiel de Google.
        //
        // POURQUOI UN DEFAUT DE TEST ET PAS UNE ERREUR DE BUILD. Parce qu'un
        // build sans identifiant DOIT rester possible et inoffensif : c'est le
        // cas de tous les APK de recette. Le defaut est public, documente par
        // Google et ne facture personne. Une valeur reelle, elle, n'entre
        // JAMAIS dans ce depot — c'est ce que verrouille le test
        // `test/comportement/pub_v1_595_test.dart` (B3).
        val admobAppId: String =
            (project.findProperty("ADMOB_APP_ID_ANDROID") as String?)
                ?.takeIf { it.isNotBlank() }
                ?: System.getenv("ADMOB_APP_ID_ANDROID")?.takeIf { it.isNotBlank() }
                ?: "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["admobAppId"] = admobAppId
        if (!admobAppId.startsWith("ca-app-pub-3940256099942544")) {
            logger.lifecycle("StepWays : App ID AdMob de PRODUCTION injecte.")
        } else {
            logger.lifecycle(
                "StepWays : App ID AdMob de TEST (aucun identifiant de " +
                    "production injecte). Pour un build vendable, fournir " +
                    "ADMOB_APP_ID_ANDROID."
            )
        }
        // P1-3 audit #327 : bornes SDK epinglees explicitement (plus de
        // dependance aux defauts flutter.*). minSdk 23 = socle commun des
        // plugins (geolocator, firebase) ; targetSdk 35 = exigence Play.
        minSdk = 26
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                // FALLBACK EXPLICITE ET TRACE (P1-3 audit #327) : sans
                // key.properties, le build release est signe avec les cles
                // DEBUG — utilisable pour `flutter run --release` en local,
                // JAMAIS publiable sur le Play Store.
                // TODO(wagon 3 — Christophe) : generer le keystore reel,
                // deposer android/key.properties (hors git) ; ce fallback
                // disparait alors automatiquement.
                logger.warn(
                    "AVERTISSEMENT StepWays : android/key.properties absent — " +
                        "build release signe avec les cles DEBUG (non publiable). " +
                        "Keystore reel = wagon 3."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
