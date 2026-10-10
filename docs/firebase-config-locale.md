# Une compilation LOCALE qui fait parler Firebase (tache 770)

Codemagic fournit la configuration Firebase par variables d environnement. Une
compilation sur le poste de Christophe, elle, ne fournissait rien : le paquet
sortait, s installait, et Firebase y etait MUET — le journal de l appareil disait
« Default FirebaseApp failed to initialize because no default options were found »
puis « Missing google_app_id », et aucune connexion anonyme n etait meme tentee.
La cause n est pas un defaut de l application : `android/app/google-services.json`
est hors depot (`.gitignore`, tache 604) et le greffon Gradle est conditionnel
(`android/app/build.gradle.kts`, tache 619). La configuration doit donc arriver
A LA FABRICATION.

## La source durable est le coffre

Les deux fichiers sont ranges dans KeePass, encodes en base64, et c est la SEULE
source a utiliser. Ils ont longtemps ne survivre que dans d anciens worktrees :
ce sont des restes, et quelqu un les supprimera un jour.

| Entree du coffre                                   | Alimente la variable                 | Fichier produit                      |
| -------------------------------------------------- | ------------------------------------ | ------------------------------------ |
| `stepways/firebase/GOOGLE_SERVICES_JSON_B64`       | `STEPWAYS_GOOGLE_SERVICES_JSON`      | `android/app/google-services.json`   |
| `stepways/firebase/GOOGLE_SERVICE_INFO_PLIST_B64`  | `STEPWAYS_GOOGLE_SERVICE_INFO_PLIST` | `ios/Runner/GoogleService-Info.plist` |

Lecture : `gerer_secret("lire", "<agent>", chemin="<entree>")`. La valeur ne doit
JAMAIS passer par une ligne de commande visible — on la met dans l environnement
du sous-processus, jamais dans un `export` affiche ni dans un fichier du depot.

## La recette, dans cet ordre

1. **Deposer**, par le script du depot et jamais par une copie a la main :
   `scripts/ci/config_firebase.sh deposer android` (`ios`, ou `tout`), avec les
   variables ci-dessus dans l environnement. Le script decode, puis REFUSE une
   configuration qui ne vise pas `com.only1cent.stepways` ou qui designe
   l ancien projet `gr20-app`.
2. **Ajouter le commutateur Dart** `STEPWAYS_FIREBASE_PROJECT_ID=stepways-app`.
   Sans lui, `FirebaseConfig.resoudre()` rend `null`, `Firebase.initializeApp()`
   n est jamais appele (tache 596) et Firebase reste muet MEME avec les fichiers
   en place. Le fournir au depot arme en plus un controle de coherence entre le
   fichier et le projet vise.
3. **Compiler** en passant ce meme identifiant en `--dart-define`.
   `gerer_qa("compiler")` le fait par defaut :
   `python scripts/skynet_cli.py qa compiler --projet-path <worktree> --agent <agent>`.

## Verifier, plutot que croire

- `git check-ignore -v android/app/google-services.json` doit citer une regle du
  `.gitignore`, et `git status` doit rester propre. Les fichiers de configuration
  ne sont JAMAIS commites.
- Le greffon a tourne si `build/app/generated/res/processReleaseGoogleServices/values/values.xml`
  existe et porte `google_app_id` — c est precisement la clef dont l absence
  donnait l erreur du depart. Gradle ecrit sous `build/app/`, pas sous
  `android/app/build/`. A noter : `gerer_qa("compiler")` capture la sortie de
  Flutter et ne la rend QUE si la compilation echoue, donc la ligne
  « Firebase : google-services.json trouve, greffons poses. » de `build.gradle.kts`
  est invisible quand tout va bien. Ce fichier genere est la preuve utilisable.
- Sur l appareil, le journal doit dire « FirebaseApp initialization successful »
  puis `FirebaseAuth` doit annoncer un utilisateur.

## Prerequis

`scripts/ci/config_firebase.sh` vient de la tache 626 et n est pas encore sur
`main`. La recette suppose une branche qui le porte.
