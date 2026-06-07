# Tests des regles Firestore — StepWays

Suite de tests des regles de securite (`../firestore.rules`) basee sur
`@firebase/rules-unit-testing` + emulateur Firestore (P0-2 audit #327).

## Prerequis

- Node.js >= 20
- Java : `firebase-tools` >= 14 exige Java >= 21 ; avec un JDK 17
  (cas de la machine de dev), utiliser `firebase-tools` 13.x via npx
  comme ci-dessous (zero installation globale).

## Execution

Depuis la **racine du repo** (la ou vit `firebase.json`) :

```bash
npm --prefix firestore-tests install
npx -y firebase-tools@13.35.1 emulators:exec --only firestore --project demo-stepways "npm --prefix firestore-tests test"
```

(Avec un JDK >= 21, le `firebase` global fonctionne aussi :
`firebase emulators:exec --only firestore --project demo-stepways "npm --prefix firestore-tests test"`.)

Le projet `demo-stepways` est un identifiant **demo-** : l emulateur
fonctionne entierement hors ligne, aucune ressource cloud reelle n est
touchee, aucune credential n est requise.

## Couverture

- `trails` : lecture publique, ecriture refusee (claim admin requis sur
  les sous-collections, document racine verrouille).
- `users` : owner only (document + sous-collections).
- `follow_sessions` : matrice complete — trekker ecrit OK / etranger KO /
  anonyme KO ; payload borne (schema exact, TTL <= 48h + tolerance) ;
  lecture positions par suiveur anonyme OK session valide, KO session
  expiree ou inactive ; shareCode faux = resolution impossible ;
  `trekkerUserId` jamais expose au suiveur (miroir public minimal
  `follow_sessions_public`) ; followers owner-only ; positions immuables.
- Catch-all deny (ex. collection `groups`, sans regles a ce jour).

Ces tests NE PASSENT PAS par `flutter test` : ils vivent dans un package
Node dedie et doivent etre lances via l emulateur comme ci-dessus.
