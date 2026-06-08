# ADR-001 : Drift plutot que Hive pour le stockage local

## Statut

Accepte.

## Contexte

StepWays est un moteur de randonnee **offline-first** : la base locale est la
source de verite hors reseau (etapes, POIs, points GPS, progression, journal,
cache meteo). Le choix du moteur de stockage local conditionne la robustesse
des migrations et la richesse des requetes. Deux options principales ont ete
evaluees : **Hive** (cle-valeur) et **Drift** (ORM SQLite type-safe).

### Hive — option evaluee

- Stockage cle-valeur simple et rapide.
- Pas de schema relationnel, typage faible (`dynamic` + TypeAdapters generes).
- Pas de systeme de migration incrementale.
- Pas de requetes relationnelles : un besoin SQL impose une couche `sqflite`
  en parallele (double stockage).

### Drift — option retenue

- ORM SQLite type-safe pour Dart/Flutter.
- Schema defini en Dart, classes generees a la compilation (`build_runner`).
- Migrations incrementales versionnees.
- Requetes SQL complexes (jointures, filtres geo) avec typage compile-time.

## Decision

**Adopter Drift** comme unique moteur de stockage local de StepWays.

## Raisons

### 1. Typage fort a la compilation

Les tables sont des classes Dart ; les erreurs de schema sont detectees au
build, pas a l'execution.

```dart
class TrailStages extends Table {
  TextColumn get id => text()();
  TextColumn get itineraryId => text().references(TrailItineraries, #id)();
  IntColumn get stageNumber => integer()();
  RealColumn get distanceKm => real()();
  IntColumn get elevationGainM => integer()();
}
```

### 2. Migrations robustes

Le schema evolue souvent (nouvelles features : suivi, journal, diplome). Drift
gere les migrations incrementales versionnees, indispensables pour ne pas
perdre les donnees locales d'un utilisateur entre deux versions de l'app.

```dart
@override
MigrationStrategy get migration => MigrationStrategy(
  onUpgrade: (m, from, to) async {
    if (from < 13) await m.createTable(sessionTrackPoints);
    // ...
  },
);
```

### 3. Requetes relationnelles

Les besoins depassent le cle-valeur :
- POIs dans un rayon GPS, filtres par etape ;
- etapes par difficulte / duree ;
- agregats de trek (distance totale, denivele cumule) ;
- jointures etapes / POIs / progression.

Hive ne le permet pas sans `sqflite` en doublon. Drift couvre tout nativement.

### 4. Coherence du pipeline de generation

StepWays utilise deja `build_runner` (Freezed, json_serializable). Drift s'y
integre naturellement, alors que Hive imposerait ses propres TypeAdapters.

### 5. Seed generique

Le `TrailSeeder` insere un JSON de sentier dans les tables Drift dans l'ordre
des cles etrangeres. Le schema relationnel modelise proprement la hierarchie
`trail_meta -> itineraries -> stages -> accommodations -> pois`.

## Alternatives ecartees

- **Hive** : verbeux des qu'il faut du relationnel, pas de migrations, pas de
  requetes SQL — recale pour un moteur offline-first riche.
- **sqflite (brut)** : SQL non type, beaucoup de code manuel ; Drift apporte
  le typage et les migrations par-dessus SQLite.
- **Isar** : performant mais ecosysteme moins stable a l'epoque de la decision,
  et moins aligne avec le pipeline `build_runner` deja en place.

## Consequences

- StepWays utilise exclusivement Drift pour le stockage local.
- Les developpeurs maitrisent la syntaxe Drift (tables, DAOs, requetes).
- Toute evolution de schema s'accompagne d'une migration **testee**.
- La base SQLite locale n'est jamais nommee d'apres un sentier en dur.
