# Module Météo

> Prévisions Open-Meteo 7 jours, alertes météo.

## Description

Le module météo fournit les prévisions à 7 jours pour chaque étape du sentier via l'API Open-Meteo (gratuite, sans clé). Les données sont cachées localement avec un TTL de 6 heures. Des alertes orange/rouge sont affichées pour les conditions dangereuses.

## Architecture

```
core/data/
  tables/weather_cache_table.dart       -- Table Drift weather_cache (v5)
  daos/weather_cache_dao.dart           -- DAO cache météo
features/weather/
  data/weather_service.dart             -- Service API Open-Meteo
  models/
    weather_forecast.dart               -- Modèle prévision
    weather_alert.dart                  -- Modèle alerte
  presentation/weather_screen.dart      -- Écran météo principal
  providers/weather_provider.dart       -- WeatherNotifier
  widgets/
    day_forecast_card.dart              -- Card prévision journalière
    weather_alert_banner.dart           -- Bannière alerte météo
```

## Flux utilisateur

1. L'utilisateur consulte la météo depuis le menu ou la fiche étape
2. Le provider vérifie le cache local (TTL 6h)
3. Si cache expiré et réseau disponible, appel API Open-Meteo
4. Affichage des prévisions jour par jour (7 jours)
5. Alertes orange/rouge si conditions dangereuses (vent, pluie, orage)
6. Fallback sur le cache expiré si pas de réseau

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `weather_service.dart` | Appels API Open-Meteo, parsing réponse |
| `weather_cache_table.dart` | Table Drift, TTL 6h, migration v5 |
| `weather_cache_dao.dart` | CRUD cache + nettoyage entrées expirées |
| `weather_forecast.dart` | Modèle prévision (temp, vent, pluie, icône) |
| `weather_alert.dart` | Modèle alerte (seuils, niveau, message) |
| `weather_screen.dart` | Écran principal météo |

## API / Providers

- `weatherProvider(stageId)` -- `FamilyAsyncNotifier<WeatherForecast, String>` -- prévision par étape
  - Vérifie cache -> appel API si expiré -> stocke en cache -> retourne

### API Open-Meteo

- URL : `https://api.open-meteo.com/v1/forecast`
- Paramètres : latitude, longitude, daily (temp, precipitation, wind, weathercode)
- Gratuit, sans clé API, 10 000 appels/jour
- Format réponse : JSON

## Pièges connus

- **TTL 6h** -- Ne pas appeler l'API plus souvent. Vérifier le timestamp du cache AVANT l'appel.
- **Fallback offline** -- Si pas de réseau, afficher le dernier cache même expiré, avec mention "Données du JJ/MM à HH:MM".
- **Alertes orange/rouge** -- Définir des seuils clairs : orange = vent > 60 km/h ou pluie > 20mm. Rouge = vent > 90 km/h ou orage.
- **Coordonnées par étape** -- Utiliser le point médian de chaque étape pour l'appel météo (pas le départ).
