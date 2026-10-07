# Promesses retirées de la fiche magasin

Lot fiche magasin et préparation Apple, 07/10/2026.

Les textes `.txt` de ce dossier sont collés tels quels dans App Store Connect
et dans la Play Console. Ils ne peuvent donc porter aucun commentaire. Ce
fichier dit, pour chaque promesse retirée, **pourquoi** elle est partie et
**à quelle condition** la remettre. On ne remet une promesse qu'après avoir
vérifié la condition dans l'application installée, pas seulement dans le code.

Chaque retrait vaut pour les deux magasins et les cinq langues.

## 1. Partage de la progression avec les proches, en temps réel, par lien privé

- **Retiré** de la description, et avec lui la phrase « la position n'est
  partagée que lorsque vous l'activez, via un lien privé ». Cette phrase
  décrivait un réglage qui n'existe pas.
- **Pourquoi.** Les six méthodes de `FollowService` n'ont aucun appelant
  (`lib/features/group/services/follow_service.dart`, de `createSession` à
  `prepareShare`). L'écran de suivi n'est atteignable par aucun bouton. Aucune
  règle serveur ne le couvre. Enfin, la politique de confidentialité publiée
  écrit elle-même que la fonction est éteinte (§ 4.1). Une fiche qui contredit
  la politique publiée est la première chose que la revue d'Apple relève.
- **Retiré aussi** du texte d'autorisation de localisation en arrière-plan
  (`ios/Runner/Info.plist`), des notes au reviewer, des notes Play et des
  étiquettes de confidentialité.
- **Condition pour le remettre.** L'écran de partage est atteignable depuis
  l'application. Les règles Firestore des sessions de suivi sont déployées.
  La politique de confidentialité est republiée avec la fonction décrite comme
  active. L'expiration à 48 h est activée côté serveur.

## 2. Cartes téléchargeables par secteur, consultables sans connexion

- **Retiré** : « par secteur » et la promesse de carte hors ligne. Le
  sous-titre iOS ne dit plus « offline » à côté de « Carte », et la description
  courte Android ne dit plus « 100 % hors ligne ». La fiche dit désormais que
  le fond de carte se charge avec le réseau.
- **Pourquoi « par secteur ».** Depuis le lot 640, il n'y a qu'un seul fichier
  de carte par sentier (`documents/mbtiles/{trailId}.mbtiles`).
- **Pourquoi « hors ligne ».** La carte ne lit jamais le fichier téléchargé.
  `tileProviderForTrailProvider` (`lib/core/map/offline_tile_provider.dart`)
  n'a aucun appelant, et les quatre couches de tuiles pointent vers
  `tile.openstreetmap.org`. Sans réseau, la trace, les étapes et les points
  d'intérêt s'affichent, mais sur un fond vide.
- **Le correctif tient en une ligne, mais il n'est pas fait ici.** Il est dans
  la carte, qui appartient au lot 671-03. Dans
  `lib/features/trek/presentation/map/map_content.dart`, à la ligne 190,
  remplacer `tileProvider: inertTileProviderOrNull(),` par
  `tileProvider: inertTileProviderOrNull() ?? ref.watch(tileProviderForTrailProvider(widget.trailId)).value,`
  et ajouter l'import de `core/map/offline_tile_provider.dart`.
- **Condition pour le remettre.** Ce correctif est fusionné. En mode avion, le
  fond de carte d'un sentier téléchargé s'affiche sur un iPhone réel. On peut
  alors écrire : « Carte du sentier téléchargeable, consultable sans
  connexion », sans « par secteur ».

## 3. Profils altimétriques interactifs pour chaque étape

- **Retiré.** La fiche dit maintenant « dénivelé positif et négatif » de
  chaque étape.
- **Pourquoi.** La courbe est synthétique : montée, sommet, descente, tirés du
  dénivelé et de la distance (`BrandAltiMotif.synthetic`,
  `lib/shared/widgets/brand_alti_motif.dart`). Elle ne réagit pas au toucher.
  Le constructeur qui prendrait les vraies altitudes n'a aucun appelant.
- **Condition pour le remettre.** La courbe est tracée depuis les altitudes
  réelles de la trace. Le doigt sur la courbe montre l'altitude et la
  distance. Il faut aussi une trace assez fine : celle du sentier actuel a 53
  points pour 84 km.

## 4. Photos géolocalisées

- **Remplacé** par « photos classées par étape ».
- **Pourquoi.** La table `JournalEntries` n'a ni latitude ni longitude.
  Chaque photo est rattachée à une étape (`stageNumber`), pas à un point.
- **Condition pour le remettre.** Une colonne de position est ajoutée et
  remplie à la prise de vue, et la photo apparaît sur la carte.

## 5. Mode économie de batterie

- **Retiré.**
- **Pourquoi.** Il n'existe aucun réglage visible. La seule porte d'entrée est
  un appui long sur le numéro de version, qui ouvre l'écran technique
  « Mesure batterie ». Le plafond automatique sous 20 % de batterie n'a aucun
  consommateur.
- **Condition pour le remettre.** Une vingtaine de lignes suffisent : une
  tuile dans les Réglages qui expose le profil « Batterie d'abord » (un point
  toutes les 3 minutes), traduite dans les cinq langues. On peut alors écrire
  « Mode économie de batterie ».

## Retirés en plus des cinq, après remesure

- **« Trace GPX haute définition. »** Le fichier
  `assets/data/mare_a_mare_centre/track.gpx` porte 53 points pour 84 km, soit
  un point tous les 1,6 km. La fiche dit « la trace ». À remettre quand la
  trace aura au moins un point tous les 20 à 50 m.
- **« Interface lisible en plein soleil. »** Il n'existe aucun mode à fort
  contraste. Les seuls thèmes sont sombre, clair et système. La fiche dit
  « thème sombre ou clair ».
- **« Fonctionne 100 % hors ligne » et « entièrement hors ligne ».** C'est
  faux tant que le fond de carte vient du réseau (voir le point 2). La fiche
  dit ce qui marche vraiment sans réseau : la position, la trace et les
  alertes de sortie de sentier.
- **« Planning adapté à votre rythme. »** Les temps de marche ne dépendent pas
  du rythme du randonneur. La fiche dit « programme conseillé selon votre test
  de faisabilité ».
- **« Historique de vos randonnées passées. »** C'est seulement la section
  « Terminés » de « Mes treks ». La fiche le dit avec ces mots.
