# ADR-002 : Slang plutot que intl pour l'internationalisation

## Statut

Accepte (historique -- l'app GR20 utilise intl/ARB, Slang est adopte pour le Moteur GR generique)

## Contexte

L'application GR20 utilise le systeme standard Flutter Localizations avec des fichiers ARB (Application Resource Bundle) et le package `intl`. Pour le Moteur GR, l'internationalisation a ete repensee pour supporter 5 langues (fr, en, de, it, es) avec un meilleur confort de developpement.

### intl/ARB -- utilisation actuelle GR20

- Systeme officiel Flutter (`flutter_localizations`)
- Fichiers `.arb` (JSON) dans `lib/l10n/`
- Generation via `flutter gen-l10n`
- 2 langues : fr (defaut) + en

### Slang -- choix pour le Moteur GR

- Package tiers type-safe pour i18n
- Fichiers YAML/JSON structures par namespace
- Generation via `build_runner`
- Support natif des plurals, genres, parametres types

## Decision

**Adopter Slang pour le Moteur GR generique** pour ses avantages en type-safety et en organisation par feature.

## Raisons

### 1. Type-safety

Avec intl, les cles de traduction sont des strings. Une faute de frappe compile mais plante a l'execution :

```dart
// intl -- pas d'erreur a la compilation, crash a l'execution si cle inexistante
AppLocalizations.of(context)!.stageGr20_1_name

// Slang -- erreur de compilation si la cle n'existe pas
t.trek.stages.stage1.name
```

### 2. Organisation par namespace

Slang permet d'organiser les traductions par feature/namespace dans des fichiers separes :

```
assets/i18n/
  fr/
    common.yaml
    trek.yaml
    planning.yaml
    auth.yaml
  en/
    common.yaml
    trek.yaml
    ...
```

Avec intl, tout est dans un seul fichier ARB par langue, ce qui devient difficile a maintenir avec 5 langues et des centaines de cles.

### 3. Hot reload

Slang genere du code Dart pur, ce qui permet le hot reload quand on modifie une traduction pendant le developpement. Avec intl, il faut souvent relancer `flutter gen-l10n` puis faire un hot restart.

### 4. Plurals et parametres types

Slang gere nativement les plurals, les genres et les parametres types sans syntax speciale ICU :

```yaml
# Slang -- syntaxe claire
trek:
  stages:
    remaining:
      one: "Il reste $count etape"
      other: "Il reste $count etapes"
    distance: "$km km parcourus sur $total km"
```

```dart
// Usage type-safe
t.trek.stages.remaining(count: 3)  // "Il reste 3 etapes"
t.trek.stages.distance(km: 45, total: 180)  // "45 km parcourus sur 180 km"
```

### 5. Support multi-sentier

Le Moteur GR doit supporter plusieurs sentiers avec des traductions specifiques a chacun. Slang permet des namespaces dynamiques par sentier, alors qu'intl/ARB necessite de tout mettre dans un fichier plat.

## Consequences

- Le Moteur GR utilise Slang pour toutes les traductions
- 5 langues supportees : fr, en, de, it, es
- Les fichiers de traduction sont dans `assets/i18n/{langue}/`
- Zero texte en dur dans le code -- tout passe par Slang
- L'app GR20 existante conserve intl/ARB (pas de migration retroactive)
- Les developpeurs doivent apprendre la syntaxe Slang (YAML + generation)
