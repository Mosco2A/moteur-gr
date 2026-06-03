# Module Planning

> Répartition des étapes par jours, calcul des durées.

## Description

Le module planning permet au randonneur de répartir les étapes du sentier sur un nombre de jours choisi. Le calcul des durées utilise la formule de Munter (4 km/h en plat, -50%% par 1000m de D+). L'utilisateur peut réorganiser les étapes par drag-and-drop et visualiser les alertes quand une journée dépasse 8h de marche.

## Architecture

```
features/planning/
  domain/planning_calculator.dart     -- Calcul Munter, répartition
  models/day_plan.dart                -- Modèle Freezed DayPlan
  presentation/planning_screen.dart   -- Écran planning principal
  providers/planning_provider.dart    -- PlanningNotifier
  widgets/
    day_plan_card.dart                -- Card d'une journée
    duration_selector.dart            -- Sélecteur durée du trek
```

## Flux utilisateur

1. L'utilisateur choisit la durée de son trek (nombre de jours)
2. Le `PlanningCalculator` répartit automatiquement les étapes
3. Affichage en timeline avec badges de durée par jour
4. Alerte orange si une journée dépasse 8h de marche
5. L'utilisateur peut réorganiser par drag-and-drop
6. Recalcul automatique après chaque modification

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `planning_calculator.dart` | Formule Munter, répartition équilibrée |
| `day_plan.dart` | Modèle Freezed : étapes du jour, durée, D+, distance |
| `planning_screen.dart` | Écran principal avec timeline et drag-and-drop |
| `planning_provider.dart` | PlanningNotifier, état du planning courant |
| `day_plan_card.dart` | Card résumé d'une journée |

## API / Providers

- `planningProvider` -- `Notifier<PlanningState>` -- planning courant du sentier actif
  - Méthodes : `generatePlan(nbDays)`, `moveStageBetweenDays(from, to)`, `recalculate()`

### Formule de Munter

- Vitesse de base : 4 km/h en plat
- Pénalité dénivelé : -50%% par 1000m de D+
- Exemple : 12 km + 800m D+ = 12/4 + 0.8*0.5*3 = 3h + 1.2h = 4.2h

## Pièges connus

- **Rééquilibrage** -- Après un drag-and-drop, recalculer immédiatement les durées de TOUTES les journées (pas seulement les deux affectées).
- **Alerte 8h** -- Badge alerte orange si une journée dépasse 8h estimées. Ne pas bloquer, juste prévenir.
- **Minimum 1 étape par jour** -- Empêcher les journées vides dans le planning.
