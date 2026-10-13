import java.io.File
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

// TACHE 629 — LA CLE DE PUBLICATION N EST POSEE QUE SI ELLE EST REELLEMENT LA.
//
// Meme forme que les greffons Firebase ci-dessus (tache 619, ligne 36) : si la
// piece existe, on la pose ; sinon on previent et on continue. Un agent ou une
// machine sans le coffre doit pouvoir compiler un APK de test comme avant.
//
// FORMAT ATTENDU de android/key.properties (fichier NON versionne, exclu par le
// .gitignore racine ET par android/.gitignore — verifie, pas suppose, tache 629) :
//   storePassword=VOIR KEEPASS — jamais en clair, ni ici ni dans le depot
//   keyPassword=VOIR KEEPASS — jamais en clair, ni ici ni dans le depot
//   storeFile=<chemin absolu, ou relatif au dossier android/, du magasin>
//   keyAlias=<alias de la cle>
// Le magasin lui-meme ne vit pas non plus dans le depot. Ce fichier n est que le
// rendu local, regenerable, de ce que le coffre contient.
//
// CE QUE LE LOT 629 A CORRIGE, ET CE N EST PAS COSMETIQUE. L ancien test se
// resumait a `keystorePropertiesFile.exists()`. Il suffisait donc qu un
// key.properties soit present pour que le build s engage sur le chemin
// « signature de publication » — meme si le fichier etait incomplet, meme si le
// magasin qu il designe n existait pas sur cette machine. Dans ces deux cas le
// build ne retombait PAS sur les cles de debug : il ECHOUAIT, sur une erreur
// Gradle obscure (NullPointerException sur la propriete absente, ou « Keystore
// file not found »). C est exactement le scenario d un key.properties recopie
// d une machine a l autre sans le magasin, ou d une chaine CI a qui l on injecte
// le fichier mais pas le binaire.
//
// LES TROIS CONDITIONS, desormais toutes verifiees avant de poser la cle :
//   1. android/key.properties existe ;
//   2. les quatre proprietes attendues y sont et ne sont pas vides ;
//   3. le magasin designe par storeFile existe vraiment sur le disque.
// Si l une manque, on previent avec la raison PRECISE et on repart sur les cles
// de debug — comportement d avant, jamais un echec de build.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

val magasinRelease: File? = run {
    if (!keystorePropertiesFile.exists()) {
        logger.warn(
            "Signature : android/key.properties ABSENT — build release signe avec " +
                "les cles DEBUG. Bon pour du test local, REFUSE au depot sur la " +
                "Play Console."
        )
        return@run null
    }
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }

    val manquantes = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        .filter { (keystoreProperties[it] as String?).isNullOrBlank() }
    if (manquantes.isNotEmpty()) {
        logger.warn(
            "Signature : android/key.properties present mais INCOMPLET (manque : " +
                manquantes.joinToString(", ") + ") — repli sur les cles DEBUG."
        )
        return@run null
    }

    val chemin = (keystoreProperties["storeFile"] as String).trim()
    val brut = File(chemin)
    val magasin = if (brut.isAbsolute) brut else rootProject.file(chemin)
    if (!magasin.isFile) {
        logger.warn(
            "Signature : android/key.properties designe un magasin INTROUVABLE (" +
                magasin.absolutePath + ") — repli sur les cles DEBUG. Le fichier a " +
                "probablement ete recopie sans le magasin qui va avec."
        )
        return@run null
    }

    logger.lifecycle(
        "Signature : magasin de publication trouve (" + magasin.name + ") — le " +
            "paquet sera signe avec la cle d importation StepWays."
    )
    magasin
}
val hasReleaseKeystore = magasinRelease != null

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
        // dependance aux defauts flutter.*). minSdk 26 = socle commun des
        // plugins (geolocator, firebase). L ancien commentaire annoncait
        // « minSdk 23 » alors que le code dit 26 depuis toujours : corrige.
        //
        // TACHE 629 — targetSdk 35 -> 36, ET CE N EST PAS UN CONFORT.
        // La Play Console a REFUSE le bundle en version code 3, verbatim :
        // « Your app currently targets API level 35 and must target at least
        //   API level 36 to ensure it is built on the latest APIs optimized for
        //   security and performance. »
        // L ancien commentaire « targetSdk 35 = exigence Play » etait vrai quand
        // le lot 619 l a ecrit ; Google a releve la barre depuis. Il est corrige
        // plutot que laisse en place : un commentaire faux coute plus cher qu un
        // commentaire absent.
        //
        // compileSdk n a PAS besoin d etre epingle : mesure faite dans le SDK
        // Flutter 3.41.5 (FlutterExtension.kt L23 et L34), `compileSdkVersion`
        // vaut deja 36 — et `targetSdkVersion` aussi. La ligne compileSdk plus
        // haut suit donc deja Android 16 sans qu on y touche.
        //
        // CE QUE CIBLER 36 CHANGE POUR STEPWAYS — verifie dans la doc Android,
        // pas devine (developer.android.com/about/versions/16/behavior-changes-16) :
        //   - Localisation en arriere-plan et services de premier plan : AUCUN
        //     changement documente pour targetSdk 36. L enregistrement de trace
        //     ecran eteint n est pas touche. C est le point qui comptait.
        //   - Orientation / redimensionnement ignores sur les ecrans >= 600dp :
        //     sans effet ici. StepWays ne verrouille aucune orientation, ni au
        //     manifeste (`android:screenOrientation` absent) ni cote Dart
        //     (`SystemChrome.setPreferredOrientations` jamais appele) — verifie.
        //   - Bord a bord (edge-to-edge) rendu obligatoire : « For apps
        //     targeting Android 16 (API level 36),
        //     R.attr#windowOptOutEdgeToEdgeEnforcement is deprecated and
        //     disabled, and your app can't opt-out of going edge-to-edge. »
        //     StepWays n a jamais demande cette derogation : rien ne casse au
        //     build. C est un point a REGARDER A L ECRAN sur le telephone (du
        //     contenu qui passerait sous les barres systeme). SafeArea est
        //     utilise dans 38 fichiers de lib/, donc le terrain est prepare.
        //   - `scheduleAtFixedRate` ne rejoue plus qu une seule execution
        //     manquee au lieu de toutes : aucun appel de ce type cote StepWays.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                // Magasin deja resolu et VERIFIE existant plus haut (tache 629) :
                // on ne le re-resout pas ici, sinon un chemin relatif serait
                // rapporte a android/app/ au lieu de android/.
                storeFile = magasinRelease
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
                // FALLBACK EXPLICITE ET TRACE (P1-3 audit #327, elargi en 629) :
                // faute de cle de publication utilisable, le build release est
                // signe avec les cles DEBUG — utilisable pour
                // `flutter run --release` en local, JAMAIS deposable sur la Play
                // Console (elle refuse un bundle signe en debug).
                //
                // La cle d importation StepWays EXISTE depuis la tache 629 : si ce
                // message apparait, ce n est plus « la cle reste a fabriquer »,
                // c est que cette machine ne la voit pas. La raison precise a deja
                // ete journalisee plus haut (fichier absent, incomplet, ou magasin
                // introuvable). Regenerer android/key.properties depuis le coffre.
                logger.warn(
                    "AVERTISSEMENT StepWays : aucune cle de publication utilisable " +
                        "— build release signe avec les cles DEBUG (NON deposable " +
                        "sur la Play Console). Voir la raison precise ci-dessus."
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
