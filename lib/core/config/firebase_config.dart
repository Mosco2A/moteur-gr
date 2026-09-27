/// Point d'entree UNIQUE de la configuration Firebase (596 C4).
///
/// LE DEFAUT CORRIGE : `firebaseProjectId` n'etait renseigne dans AUCUNE
/// configuration de sentier — ni Mare a Mare Centre, ni Pyrenees, ni la config
/// de test. `FirebaseService.initialize` sortait donc a sa premiere ligne, et
/// `Firebase.initializeApp()` n'etait JAMAIS execute, a 100 % des demarrages.
/// Resultat mesure : zero rapport de plantage, zero statistique. L'appli
/// pouvait planter chez tous ses utilisateurs sans que personne ne le sache.
///
/// LE DEFAUT ETAIT QU'IL N'EXISTAIT AUCUN MOYEN DE RENSEIGNER LA VALEUR : pas
/// de variable de build, pas de fichier, rien. Elle est desormais injectee au
/// build, exactement comme les identifiants publicitaires ([AdConfig]) :
///
/// ```
/// flutter build apk --dart-define=STEPWAYS_FIREBASE_PROJECT_ID=<projet>
/// ```
///
/// REGLE ABSOLUE : AUCUNE valeur Firebase n'est ecrite dans le depot. Ni ici,
/// ni dans un `firebase_options.dart`, ni dans un `google-services.json`
/// versionne (les trois sont deja dans `.gitignore`). Un test de ce lot balaye
/// `lib/` et refuse toute cle en clair.
///
/// GARDE-FOU : variable absente => `projectId` nul => l'appli tourne en MODE
/// LOCAL, normalement, et le DIT dans ses journaux ([FirebaseService]). Elle ne
/// plante jamais au demarrage pour une configuration manquante.
abstract final class FirebaseConfig {
  /// Nom de la variable `--dart-define` attendue au build.
  ///
  /// Publie et stable : la CI comme Chris doivent pouvoir la passer sans avoir
  /// a deviner son nom ni a lire le code.
  static const String variableDeBuild = 'STEPWAYS_FIREBASE_PROJECT_ID';

  static const String _injecte =
      String.fromEnvironment(variableDeBuild);

  /// L'identifiant du projet Firebase, ou `null` si rien n'a ete injecte.
  static String? get projectId => _injecte.isEmpty ? null : _injecte;

  /// Vrai si une configuration Firebase a ete fournie au build.
  static bool get isConfigured => _injecte.isNotEmpty;

  /// Resout l'identifiant a utiliser au demarrage.
  ///
  /// L'injection de build PRIME sur la valeur portee par le sentier : c'est
  /// elle qui distingue un build de production d'un build local, alors que la
  /// configuration de sentier est une donnee versionnee (et donc vide, par
  /// construction, puisqu'aucune cle n'entre dans le depot).
  static String? resoudre({String? depuisLeSentier}) =>
      projectId ?? depuisLeSentier;
}
