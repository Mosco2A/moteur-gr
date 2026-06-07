import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
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
    namespace = "com.only1cent.moteur_gr"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.only1cent.moteur_gr"
        // P1-3 audit #327 : bornes SDK epinglees explicitement (plus de
        // dependance aux defauts flutter.*). minSdk 23 = socle commun des
        // plugins (geolocator, firebase) ; targetSdk 35 = exigence Play.
        minSdk = 23
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

flutter {
    source = "../.."
}
