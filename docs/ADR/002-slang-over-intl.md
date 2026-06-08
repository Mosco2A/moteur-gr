# ADR-002 : Slang plutot que intl/ARB pour l'internationalisation

## Statut

Accepte.

## Contexte

StepWays vise 5 langues des le depart (fr, en, de, it, es) et impose **zero
texte en dur** cote interface. Le choix du systeme d'i18n a ete evalue entre
le standard Flutter (`flutter_localizations` + ARB + `intl`) et **Slang**
(generation de code type-safe).

### intl / ARB — option evaluee

- Systeme officiel Flutter (`flutter gen-l10n`).
- Fichiers `.arb` (JSON) par langue, cles accedees par chaine.
- Pas de verification de cle a la compilation (faute de frappe = crash runtime).
- Pluriels/genres via syntaxe ICU dans la chaine.

### Slang — option retenue

- Generation de code Dart type-safe a partir de fichiers de traduction.
- Acces aux cles **verifie a la compilation** (`t.<namespace>.<cle>`).
- Pluriels, parametres types, namespaces sans syntaxe ICU lourde.
- Fallback automatique vers la langue de base.

## Decision

**Adopter Slang** pour toute l'internationalisation de StepWays.

## Organisation reelle des traductions

> Important : contrairement a une organisation "un dossier par langue / un
> fichier par namespace", StepWays utilise **un seul fichier JSON par langue**,
> avec les namespaces **a l'interieur** du JSON.

```
assets/i18n/
  fr.i18n.json   # langue de base
  en.i18n.json
  de.i18n.json
  it.i18n.json
  es.i18n.json
```

Configuration : `slang.yaml` (base_locale = `fr`, `input_file_pattern =
.i18n.json`, sortie dans `lib/i18n/`).

Regeneration via la **CLI Slang**, pas `build_runner` :

```bash
dart run slang
```

`slang_build_runner` est volontairement **desactive** dans `build.yaml` :
incompatibilite avec la version de `build_runner` utilisee et risque de
generer un doublon. Le code genere (`lib/i18n/translations.g.dart` +
un fichier par langue) ne doit pas etre edite a la main.

## Raisons

### 1. Type-safety

Avec intl, une cle inexistante compile mais plante a l'execution. Avec Slang,
la cle est un membre Dart : l'erreur est detectee au build.

```dart
// intl : crash runtime si la cle n'existe pas
AppLocalizations.of(context)!.stageName;

// Slang : erreur de COMPILATION si la cle n'existe pas
t.trek.stage.name;
```

### 2. Namespaces lisibles

Les cles sont organisees par namespace (feature) dans le JSON, et exposees en
arborescence type-safe (`t.share.title`, `t.a11y.zoomIn`, `t.cloud.localModeTitle`).

### 3. Pluriels et parametres types

```dart
t.a11y.stageMarker(number: 3);     // "Etape 3"
t.a11y.markerCluster(count: 12);   // "12 points"
```

### 4. Hot reload

Slang genere du Dart pur : un changement de traduction est pris via hot reload
apres regeneration, sans dependre du pipeline ARB.

### 5. Couverture multilingue verifiable

5 langues, fallback sur la base (fr). Des tests verifient que les cles
sensibles (a11y notamment) sont non vides dans **chaque** langue.

## Alternatives ecartees

- **intl / ARB** : cles non typees (crash runtime), tooling ICU lourd,
  organisation peu pratique a 5 langues.
- **easy_localization** : runtime (cles en chaines), pas de type-safety.

## Consequences

- StepWays utilise Slang pour toutes les chaines d'interface.
- 5 langues : fr (base), en, de, it, es ; toute cle existe dans les 5.
- Sources = 1 JSON par langue dans `assets/i18n/` ; regeneration `dart run slang`.
- Zero texte en dur dans le code.
- Les libelles de **donnees** (etapes, POIs) restent multilingues inline dans
  le JSON de seed du sentier (champs `nameFr/En/De/It/Es`), pas dans Slang.
