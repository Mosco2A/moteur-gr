# Rapport — lot fiche magasin et préparation Apple (StepWays)

> Branche `claude/chore/fiche-magasin-et-apple`, prise sur
> `claude/integration/671-batterie-dabord`.
> Ce rapport s'écrit au fil du lot et il est poussé à chaque étape, pour
> survivre aux coupures de réseau.

## Point de départ

- **Tête d'intégration vérifiée au départ : `52fb8ac2`**
  (« docs(671-02): la ligne du lot au journal, le socle podometre »).
  Elle n'a pas bougé depuis la mesure du 07/10 à 13:33.
- `main` n'est pas touchée.
- La base de mémoire (`data/memory.db` et `scripts/memory_helper.py`) n'existe
  pas dans ce conteneur. Les mémoires #101492, #101493, #101486, #101502 et
  #101503 n'ont donc **pas pu être lues**. Chaque chiffre de ce rapport a été
  remesuré dans le dépôt. Là où une mémoire était seule à porter un fait
  (l'historique réel des builds, par exemple), le rapport le dit.
- Hors périmètre, non touchés : `lib/features/trek`, `lib/features/map`,
  `lib/core/geo`.

## Étape 1 — Le nom : « The Ways » devient « StepWays »

- 26 fichiers sous `assets/store` portaient « The Ways » : les deux magasins,
  les cinq langues, les titres, les descriptions et les notes. Les 26 sont
  corrigés. Il reste **0** occurrence dans tout le dépôt.
- Graphie retenue : `StepWays`, celle de `CFBundleDisplayName`, de
  `android:label` et des documents `docs/store/data-safety*.md`. Ni
  `CFBundleDisplayName` ni `android:label` n'ont été touchés.
- Les titres, mesurés langue par langue (limite de 30 caractères chez Apple,
  30 chez Google). « StepWays » fait 8 caractères et « The Ways » en faisait 9,
  donc chaque titre perd un caractère.

| Langue | Titre | Caractères |
|---|---|---|
| fr | StepWays - Rando hors ligne | 27 |
| en | StepWays - Offline hiking | 25 |
| de | StepWays - Offline-Wandern | 26 |
| it | StepWays - Trekking offline | 27 |
| es | StepWays - Senderismo offline | 29 |

Le titre français fait 27 caractères, et non 28 comme annoncé. Il passe.
