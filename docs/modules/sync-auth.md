# Module Sync + Auth

> Authentification anonyme/Google/Apple, synchronisation cloud.

## Description

Le module gère deux responsabilités transversales :

**Authentification** : anonyme automatique au premier lancement + Google Sign-In silencieux optionnel + Apple Sign-In sur iOS. Pas d'email+password. `linkWithCredential` pour upgrader un compte anonyme.

**Synchronisation** : sync bidirectionnelle Drift <-> Firestore en mode last-write-wins, par batch de 20 via la table `sync_queue`. Suivi entre trekkeurs (2 suiveurs max gratuits, mode 1h + mode refuge).

## Architecture

```
core/
  services/
    cloud_sync_service.dart             -- Service sync Drift <-> Firestore
    sync_scheduler.dart                 -- Planificateur sync (batch 20)
  data/
    tables/sync_queue_table.dart        -- Table Drift sync_queue (v8)
    daos/sync_queue_dao.dart            -- DAO file sync
features/auth/
  domain/auth_service.dart              -- Interface abstraite auth
  data/
    firebase_auth_service.dart          -- Implémentation Firebase Auth
    local_auth_service.dart             -- Implémentation locale (test)
  presentation/profile_screen.dart      -- Écran profil
  providers/auth_provider.dart          -- AuthNotifier
features/group/
  models/group_member.dart              -- Modèle membre groupe
  services/group_tracking_service.dart  -- Service suivi position
  providers/group_provider.dart         -- GroupNotifier
  presentation/group_screen.dart        -- Écran groupe/suivi
  widgets/member_position_card.dart     -- Card position membre
```

## Flux utilisateur -- Auth

1. Premier lancement : création automatique d'un compte anonyme Firebase
2. L'utilisateur peut optionnellement lier un compte Google (silencieux)
3. Sur iOS : Apple Sign-In disponible
4. `linkWithCredential` upgrade le compte anonyme sans perdre les données
5. Déconnexion : retour au mode anonyme (pas de suppression données locales)

## Flux utilisateur -- Sync

1. Le randonneur modifie des données localement (journal, progression...)
2. La modification est enregistrée dans `sync_queue`
3. Quand le réseau est disponible, le `SyncScheduler` envoie par batch de 20
4. Conflit : last-write-wins (le plus récent gagne)
5. Suivi : push complet de la position au refuge, mode 1h sinon

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `cloud_sync_service.dart` | Sync bidirectionnelle, last-write-wins |
| `sync_scheduler.dart` | Batch 20, réseau-aware |
| `sync_queue_table.dart` | Table Drift, migration v8 |
| `auth_service.dart` | Interface abstraite (Firebase ou local) |
| `firebase_auth_service.dart` | Impl Firebase : anonyme + Google + Apple |
| `group_tracking_service.dart` | Partage position entre trekkeurs |

## API / Providers

- `authProvider` -- `Notifier<AuthState>` -- état authentification
  - Méthodes : `signInAnonymously()`, `linkWithGoogle()`, `linkWithApple()`, `signOut()`
- `syncProvider` -- `AsyncNotifier<SyncState>` -- état sync
  - Méthodes : `syncNow()`, `getPendingCount()`, `clearQueue()`
- `groupProvider` -- `AsyncNotifier<GroupState>` -- suivi groupe
  - Décision Chris #81460 : 2 suiveurs max gratuits

### Firestore -- 7 collections

- `users/` -- profil utilisateur
- `trails/` -- métadonnées sentiers (source catalogue)
- `user_trails/` -- données utilisateur par sentier (progression, journal)
- `sync_events/` -- événements sync
- `groups/` -- groupes de trekkeurs
- `positions/` -- positions partagées (TTL auto)
- `feedback/` -- retours utilisateurs

## Pièges connus

- **Anonyme auto** -- Le compte anonyme est créé AVANT toute interaction UI. Ne pas demander à l'utilisateur.
- **linkWithCredential** -- CRITIQUE. Si l'utilisateur a un compte anonyme avec des données, le link doit CONSERVER les données. Tester ce scénario.
- **Apple Sign-In iOS** -- Obligatoire pour la publication App Store si Google Sign-In est proposé.
- **Batch 20** -- Ne pas dépasser 20 items par batch pour éviter les timeouts Firestore.
- **Last-write-wins** -- Pas de merge sophistiqué. Le plus récent gagne. Acceptable pour une app solo/petit groupe.
- **Suivi 2 suiveurs** -- Décision Chris #81460. Mode 1h (push toutes les heures) + mode refuge (push complet au refuge).
