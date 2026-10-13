# App Store — Notes pour la revue (App Review Notes — StepWays)

Relu et réécrit le 07/10/2026 (lot fiche magasin et préparation Apple), pour
coller à ce que l'application fait **aujourd'hui**.

## Ce qui va dans le formulaire App Store Connect

Section **« Informations pour la révision de l'app »** (App Review Information) :

| Champ | Valeur |
|---|---|
| Connexion requise (Sign-in required) | **NON — case décochée.** L'application s'ouvre sans compte : une identité anonyme est créée en arrière-plan, sans rien demander. |
| Nom d'utilisateur / mot de passe | **Vides.** Aucun identifiant n'existe ni n'est nécessaire. Ne jamais en écrire ici ni ailleurs. |
| Coordonnées (prénom, nom, téléphone, e-mail) | Celles de Christophe, saisies à la main dans le formulaire. Elles ne sont pas versionnées. |
| Notes | Le bloc en anglais ci-dessous, collé tel quel (moins de 4 000 caractères). |
| Pièce jointe | Facultative. Une vidéo d'écran de la démo (catalogue, puis démo, puis « Simulate the next stage ») aide le reviewer. Voir `screenshots_spec.md`. |

## Bloc à coller dans « Notes » (en anglais, la langue de la revue)

```text
StepWays is a long-distance hiking companion. It works without any account: no sign-in, no username, no password. An anonymous identity is created silently in the background.

HOW TO SEE A TRAIL WITHOUT WALKING IT (recommended path, about 2 minutes)
1. First launch: three onboarding pages (welcome, language, "Download your first trail"). Tap "Browse the catalogue".
2. At the top of the trail catalogue, tap the orange "Try the demo" button. The demo opens the full sample trail (7 stages, 84 km) with its map, stages, planning, points of interest, weather, checklist and emergency numbers. Nothing is purchased and nothing is saved.
3. Tap "Start the trek". In demo mode this starts a simulated hike: it uses no GPS and asks for no location permission.
4. Tap "Simulate the next stage" (on the home cockpit or in the map's top bar) to move forward stage by stage, or "Simulate the finish" to reach the end.
5. Leave the demo with "Exit" in the "DEMO MODE" banner. The demo can be reopened from "My account".
In demo mode the journal is read-only and no diploma is issued, by design.

REAL GPS TRACKING
Real tracking is for a purchased trail (in-app purchase, sandbox account in review). After purchase, "Start the trek" asks for location permission. In the Simulator, use Features > Location > Freeway Drive or a custom location: the position dot and the live statistics (distance, elevation gain, time, speed) update, and an off-trail alert appears more than 80 m from the track. The sample trail is in Corsica (France), so a position far away shows as off-trail. That is the expected behaviour.

PERMISSIONS AND WHY
- Location when in use: place the hiker on the trail and record the hike.
- Location in the background (UIBackgroundModes: location): keep recording with the screen off and the phone in the bag. It only runs during a hike started by the user. Positions stay on the device and are never sent to our servers.
- Motion & fitness: count steps during a hike (stride length and battery measurement). Explained before it is requested. The count stays on the device.
- Camera and photo library: add photos to the trail journal and to the personal emergency sheet. Photos stay on the device.
- Bluetooth and Health purpose strings are present because the libraries are linked, but this version exposes no Bluetooth or Health feature, so these prompts never appear.

NETWORK
The trail data (track, stages, points of interest, emergency numbers) is on the device. Without a network, the position, the track and the off-trail alerts keep working. The map background (OpenStreetMap tiles) and the weather need a network.

ADVERTISING
A banner and an optional rewarded ad (Google AdMob) appear in the free version. This version does not show the App Tracking Transparency prompt.

No hidden features. No user-generated content is publicly visible. Languages: French, English, German, Italian, Spanish.
```

## Pour Christophe : ce qui a changé par rapport à l'ancienne version, et pourquoi

- **Retiré : le partage de position avec les proches.** La fonction est
  éteinte. Les méthodes de partage n'ont aucun appelant, et la politique de
  confidentialité publiée le dit (§ 4.1). Le reviewer comparera les deux.
- **Retiré : « télécharger le sentier de démonstration ».** Il n'existe pas.
  Le vrai chemin passe par le bouton « Try the demo » du catalogue, puis par
  les boutons « Simulate the next stage » et « Simulate the finish ». C'est
  la réponse à la question « comment le reviewer voit un sentier sans aller
  marcher en Corse ».
- **Retiré : « iOS 26 SDK, Xcode 26+ »** dans la conformité. Le dépôt ne fixe
  pas la version de Xcode (Codemagic `xcode: latest`). La vérification est
  dans `docs/store/fiche-app-store-connect.md`.
- **Retiré : « Dark Mode et Dynamic Type ».** Le mode sombre existe, mais la
  prise en charge de Dynamic Type n'a pas été mesurée. On ne l'écrit pas.
- **Ajouté : la publicité AdMob, l'absence de fenêtre ATT, et les textes
  Bluetooth et Santé** qui existent sans fonction visible. Mieux vaut que le
  reviewer le lise ici que de le découvrir.
- **Le compte de démonstration vaut NON.** Aucun identifiant n'est écrit dans
  ce fichier, et aucun ne doit l'être.
