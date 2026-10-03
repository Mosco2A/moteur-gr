pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.12.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    // TACHE 604 — SANS CE GREFFON, LA CONFIGURATION FIREBASE N EST JAMAIS LUE.
    // `Firebase.initializeApp()` est appele SANS options
    // (lib/core/firebase/firebase_service.dart) : il attend donc les ressources
    // natives, produites au build par ce greffon depuis le fichier de
    // configuration pose dans android/app/. Absent, l init echouait a 100 % des
    // demarrages Android et l app repassait en mode local avec la raison
    // `echecInitialisation` — zero rapport de plantage, zero catalogue distant.
    id("com.google.gms.google-services") version "4.4.2" apply false
    id("com.google.firebase.crashlytics") version "3.0.2" apply false
}

include(":app")
