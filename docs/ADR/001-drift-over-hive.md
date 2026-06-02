# ADR-001 : Drift plutot que Hive pour le stockage local

## Statut

Accepte (historique -- l'app GR20 utilise Hive, Drift est adopte pour le Moteur GR generique)

## Contexte

L'application GR20 originale utilise Hive comme base de donnees locale pour le cache et les preferences. Pour le Moteur GR (version generique multi-sentier), le choix du stockage local a ete reevalue.

### Hive -- utilisation actuelle GR20

- Stockage cle-valeur simple et rapide
- Pas de schema, pas de typage fort
- Utilise pour : cache preferences (`app_settings`), donnees trek temporaires
- Combine avec `sqflite` pour les track points GPS (besoin de requetes SQL)

### Drift -- choix pour le Moteur GR

- ORM SQLite type-safe pour Dart/Flutter
- Schema defini en Dart, genere par `build_runner`
- Migrations incrementales gerees automatiquement
- Requetes SQL complexes possibles avec typage compile-time

## Decision

**Adopter Drift pour le Moteur GR generique** tout en gardant Hive dans l'app GR20 existante (pas de migration retroactive).

## Raisons

### 1. Typage fort

Hive stocke des `dynamic` par defaut. Les TypeAdapters ajoutent du typage mais la verification est a l'execution. Drift genere des classes Dart typees a la compilation :

```dart
// Drift -- erreur de typage detectee a la compilation
class Stages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get distance => real()();
  IntColumn get elevationGain => integer()();
}
```

### 2. Migrations robustes

Hive n'a pas de systeme de migration. Changer la structure d'une box necessite de la vider et recreer. Drift supporte les migrations incrementales :

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 2) {
      await m.addColumn(stages, stages.difficulty);
    }
    if (from < 3) {
      await m.createTable(pois);
    }
  },
);
```

### 3. Requetes SQL complexes

Pour le Moteur GR, les besoins de requetes sont plus complexes que le simple cle-valeur :
- Chercher les POIs dans un rayon GPS
- Filtrer les etapes par difficulte et duree
- Agreger les statistiques de trek (distance totale, denivele cumule)
- Jointures entre etapes, POIs et donnees de progression

Hive ne supporte pas les requetes relationnelles. L'app GR20 contourne ce probleme en utilisant `sqflite` en parallele pour les track points, creant une double couche de stockage.

### 4. Coherence de la stack

Le Moteur GR utilise deja `build_runner` pour Freezed et Riverpod. Drift s'integre naturellement dans ce pipeline de generation de code, alors que Hive necessite ses propres TypeAdapters generes separement.

## Consequences

- Le Moteur GR utilise exclusivement Drift pour le stockage local
- L'app GR20 existante conserve Hive (pas de refactoring retroactif)
- Les developpeurs doivent connaitre la syntaxe Drift pour les tables et requetes
- Les migrations doivent etre testees a chaque changement de schema
- La base SQLite est stockee dans `moteur-gr.db` (jamais dans `gr20.db`)
