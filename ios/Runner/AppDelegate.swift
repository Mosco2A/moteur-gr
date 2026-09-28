import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // ==========================================================================
  // L'EXCLUSION DE LA SAUVEGARDE iCLOUD (tache 615, GO-73)
  // ==========================================================================
  //
  // POURQUOI CE CODE EST ICI, ET PAS DANS UN FICHIER A LUI. Un nouveau fichier
  // Swift doit etre declare a la main dans quatre endroits de
  // `Runner.xcodeproj/project.pbxproj`, et cela ne se verifie qu'en compilant sur
  // un Mac. Un fichier oublie de la phase `Sources` ne compile pas, ne s'execute
  // pas, et NE DIT RIEN : le canal serait muet, la fiche medicale monterait dans
  // iCloud, et les tests Dart resteraient verts. `AppDelegate.swift` est deja
  // dans la phase `Sources` — l'invariante Dart de la tache 615 le verifie dans
  // le pbxproj pour que ce raisonnement reste vrai.
  //
  // CE QUE CE CANAL FAIT, ET POURQUOI IL N'Y A PAS D'AUTRE FACON. Sur iPhone,
  // `Library/Application Support/` est sauvegarde par defaut (documentation
  // Apple, « File System Basics ») et rien dans `Info.plist` ne permet d'en
  // exclure un dossier : il n'existe AUCUN equivalent declaratif d'Android
  // `android:dataExtractionRules`. L'exclusion est un attribut du fichier, pose a
  // l'execution avec `NSURLIsExcludedFromBackupKey` (en Swift :
  // `URLResourceValues.isExcludedFromBackup`).
  //
  // DEUX SENS, ET LE SECOND COMPTE AUTANT QUE LE PREMIER. `exclure` protege la
  // fiche medicale, qui ne doit JAMAIS monter (decision de Christophe du 28/09
  // 10:42). `inclure` RETIRE l'attribut de la copie que le randonneur a
  // explicitement acceptee de voir sauvegardee en decochant la case : une copie
  // qui porterait l'exclusion ne serait jamais sauvegardee, et decocher la case
  // n'aurait aucun effet.

  /// Nom du canal — LA MEME CHAINE QU'EN DART
  /// (`ExclusionSauvegardeIcloud.nomDuCanal`). Un canal dont les deux bouts ne
  /// portent pas le meme nom echoue EN SILENCE.
  private static let canalExclusionSauvegarde = "stepways/exclusion_sauvegarde_icloud"

  /// Le canal est retenu par l'AppDelegate : relache, son gestionnaire ne serait
  /// plus appele et le canal deviendrait muet sans rien dire.
  private var canalExclusion: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    brancherLExclusionDeSauvegarde(engineBridge)
  }

  /// Branche le canal de l'exclusion de sauvegarde iCloud.
  ///
  /// LE MESSAGER VIENT DE `applicationRegistrar`, ET CE CHOIX EST VERIFIE DANS LES
  /// EN-TETES DU MOTEUR. `FlutterImplicitEngineBridge` expose deux registres :
  /// `pluginRegistry`, qui VEND des registres de GREFFON — et dont
  /// `registrarForPlugin:` est declare `nullable`, donc a deballer —, et
  /// `applicationRegistrar`, declare `nonnull`, dont la documentation dit
  /// exactement a quoi il sert : « provides access to application-level services,
  /// such as the engine's FlutterBinaryMessenger ». Ce canal est un canal
  /// D'APPLICATION, pas un greffon : c'est le second. Aucun deballage, donc aucune
  /// branche ou le canal resterait muet.
  private func brancherLExclusionDeSauvegarde(_ engineBridge: FlutterImplicitEngineBridge) {
    let canal = FlutterMethodChannel(
      name: AppDelegate.canalExclusionSauvegarde,
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    canal.setMethodCallHandler { appel, reponse in
      AppDelegate.traiterLExclusion(appel, reponse)
    }
    canalExclusion = canal
  }

  /// Pose ou retire `NSURLIsExcludedFromBackupKey` sur un chemin du disque.
  ///
  /// AUCUN FAUX SUCCES : un chemin absent, un attribut refuse par le systeme ou
  /// une methode inconnue rendent une ERREUR, jamais `true`. Le Dart la
  /// journalise et rend `ResultatExclusionIcloud.echec` — une promesse de sante
  /// ne se declare pas tenue sur la foi d'un appel qui a echoue.
  /// Le resultat est pris SANS `@escaping`, et c'est deliberе : il est appele
  /// SYNCHRONEMENT, sur tous les chemins, avant le retour. Un `@escaping` ici
  /// ajouterait une hypothese sur la facon dont le bloc ObjC `FlutterResult` est
  /// importe en Swift, et ce fichier ne peut se compiler que sur un Mac — on ne
  /// pose donc aucune hypothese qu'on ne peut pas verifier ici.
  private static func traiterLExclusion(
    _ appel: FlutterMethodCall,
    _ reponse: FlutterResult
  ) {
    let exclure: Bool
    switch appel.method {
    case "exclure":
      exclure = true
    case "inclure":
      exclure = false
    default:
      reponse(FlutterMethodNotImplemented)
      return
    }

    guard let arguments = appel.arguments as? [String: Any],
          let chemin = arguments["chemin"] as? String,
          !chemin.isEmpty else {
      reponse(FlutterError(
        code: "chemin_absent",
        message: "l'argument « chemin » est obligatoire et non vide",
        details: nil
      ))
      return
    }

    guard FileManager.default.fileExists(atPath: chemin) else {
      // Le natif ne CREE rien : poser l'attribut sur un chemin absent le ferait
      // apparaitre, et un dossier `medical/` vide est une trace de passage la ou
      // le lot 612 a decide qu'on n'en laissait pas.
      reponse(FlutterError(
        code: "chemin_introuvable",
        message: "rien a ce chemin : l'attribut n'a PAS ete pose",
        details: chemin
      ))
      return
    }

    var url = URL(fileURLWithPath: chemin)
    do {
      var valeurs = URLResourceValues()
      valeurs.isExcludedFromBackup = exclure
      try url.setResourceValues(valeurs)
      reponse(true)
    } catch {
      reponse(FlutterError(
        code: "attribut_refuse",
        message: error.localizedDescription,
        details: chemin
      ))
    }
  }
}
