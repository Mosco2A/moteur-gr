# Module Journal

> Notes et photos de trek, jour par jour.

## Description

Le journal permet au randonneur de consigner ses impressions et prendre des photos pendant le trek. Chaque entrée est liée à une étape et une date. Les photos sont compressées à 500 Ko et limitées à 3 par jour. La sync se fait en batch vers Firestore.

## Architecture

```
core/data/
  tables/journal_entries_table.dart     -- Table Drift journal_entries (v3)
  daos/journal_dao.dart                 -- DAO CRUD entrées journal
features/journal/
  presentation/journal_screen.dart      -- Écran journal principal
  providers/journal_provider.dart       -- JournalNotifier
  widgets/
    add_note_dialog.dart                -- Dialog ajout note
    journal_entry_card.dart             -- Card entrée journal
features/share/
  domain/share_card_generator.dart      -- Générateur share cards (E3.6)
  presentation/share_card_screen.dart   -- Écran partage
```

## Flux utilisateur

1. L'utilisateur ouvre le journal depuis le menu de navigation
2. Affichage des entrées par jour / étape
3. Bouton "+" pour ajouter une note (texte + photos optionnelles)
4. Compression automatique des photos à 500 Ko
5. Limité à 3 photos par jour
6. Sync batch vers Firestore quand réseau disponible
7. Option partage via share card (E3.6)

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `journal_entries_table.dart` | Table Drift, migration v3 |
| `journal_dao.dart` | CRUD entrées journal |
| `journal_screen.dart` | Écran principal, liste par jour |
| `journal_provider.dart` | JournalNotifier, état journal |
| `add_note_dialog.dart` | Dialog saisie texte + sélection photos |
| `journal_entry_card.dart` | Card affichage entrée |

## API / Providers

- `journalProvider` -- `AsyncNotifier<List<JournalEntry>>` -- entrées du sentier actif
  - Méthodes : `addEntry(text, photos)`, `deleteEntry(id)`, `getByStage(stageId)`, `getByDate(date)`

## Pièges connus

- **3 photos/jour max** -- Décision Chris #81462. Vérifier le compteur AVANT la prise de photo.
- **Compression 500 Ko** -- Compression JPEG avec qualité ajustée pour tenir dans 500 Ko. Ne pas dépasser.
- **Sync batch** -- Les photos sont syncées en batch (pas une par une) pour économiser la bande passante.
- **Offline** -- Le journal doit fonctionner 100%% offline. La sync se fait quand le réseau revient.
