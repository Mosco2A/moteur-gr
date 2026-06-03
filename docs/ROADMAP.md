# Moteur GR -- Roadmap Phases 6-8 + Securite

Roadmap issue des plans Minerve V3 (2026-06-03).
Estimations en jours-agent (Vulcain). Priorites: P0 = vitale, P1 = lancement, P2 = post-lancement, P3 = futur.

---

## Phase 6 -- Features (37.8j)

Objectif : enrichir l'experience terrain avec des fonctionnalites actives pendant la randonnee.

- #F6.1 Signalement type Waze (4.5j, P1) -- Signaler dangers, points d'eau, passages degrades. Votes fiabilite, TTL par type, store-and-forward offline.
- #F6.2 Companion Watch (7.5j, P1) -- Stats montres BLE (cardio, SpO2, altitude). Partage groupe chiffre AES-128. Donnees LOCAL ONLY.
- #F6.3 Variantes etapes (5j, P1) -- Variantes alpine/facile/echappatoire par etape. Comparatif + recalcul itineraire.
- #F6.4 Hebergements A/R (4j, P1) -- Catalogue refuges, bergeries, gites. Deeplinks reservation prestataire (pas d'intermediaire).
- #F6.5 Programme entrainement (4.5j, P2) -- 3 templates (8/12/16 semaines). Calendrier + rappels locaux. Module standalone.
- #F6.6 ETA temps reel (4j, P1) -- Heure d'arrivee estimee (Naismith + fatigue). Recalcul toutes les 5 min.
- #F6.7 Stats post-trek (3.8j, P2) -- Dashboard recap, export GPX, card partageable.
- #F6.8 Audit UX/UI (4.5j, P1) -- Revue Nielsen, accessibilite WCAG AA, tests gants/froid.

Risques phase 6 : BLE degrade en montagne (40-60m), AIPD RGPD obligatoire avant module capteurs, perte batterie au froid (20-40%), volume stockage offline sur 7-16 jours.

---

## Phase 7 -- Social & Gamification (27.3j)

Objectif : creer une dynamique communautaire motivante, anonymisee par defaut, 100% offline-capable.

- #F7.1 Kudos / encouragements (3.3j, P1) -- Envoi/reception kudos BLE peer-to-peer (<50m). Fonctionne sans reseau.
- #F7.2 Segments + Leaderboard (5.7j, P2) -- Chrono sur segments predefinis. Classement anonymise, anti-triche GPS.
- #F7.3 Badges / achievements (4j, P1) -- 30-50 badges au lancement (progression, terrain, meteo, social, perf). Deblocage 100% offline.
- #F7.4 Classement anonymise (2.5j, P1) -- Pseudos faune/flore corse ("Mouflon-247"). 3 niveaux visibilite. Sanitisation positions serveur.
- #F7.5 Defis saisonniers (4j, P2) -- Challenges communautaires, badge recompense, progression locale + globale.
- #F7.6 Fil social / feed (4.5j, P2) -- Feed communautaire (arrivees, badges, photos, signalements). Moderation auto NSFW.
- #F7.7 Partage in-app (3.3j, P1) -- Cards visuelles brandees, share natif, QR code invitation groupe.

Architecture sociale offline : 3 canaux -- BLE peer-to-peer (<50m), stockage Drift local, sync batch serveur a la reconnexion.

Risques phase 7 : moderation contenu, anti-triche GPS spoofing, masse critique adoption sociale, RGPD photos (visages = biometrie).

---

## Phase 8 -- Donnees & Communaute (26.5j)

Objectif : les randonneurs enrichissent le contenu pour les suivants. Dimension culturelle et narrative = differentiation.

- #F8.1 Waypoints communautaires (4.5j, P1) -- POI contribues (eau, vue, abri, culture). Validation communautaire, pre-cache offline.
- #F8.2 Packs sentiers / editorial (10j, P1) -- Guides narratifs par etape (1000-2000 mots), points culturels, audio guide mains libres.
- #F8.3 Town guides (5j, P1) -- Services villages (epicerie, pharmacie, transport, WiFi). MAJ communautaire.
- #F8.4 Sentiers hors Corse (7j, P3) -- Architecture extensible multi-sentiers. Candidats : Mare a Mare, GR10, TMB, GR34, Via Alpina.

Strategie contenu : town guides (utilitaire) > waypoints (crowdsource) > pack editorial (differenciant) > extensibilite (post-launch).

Risques phase 8 : qualite contenu editorial (redacteur specialise), maintenance horaires saisonniers, waypoints spam, over-engineering extensibilite.

---

## Securite innovante (18.5j)

Objectif : filet de securite passif. L'app informe, l'humain decide. JAMAIS d'appel secours automatique.

- #S1 Heure max d'arrivee (6.5j, P0, VITALE) -- Timer local, escalade etats, SMS/push/email contacts si pas de confirmation.
- #S2 Dead man switch (3.8j, P1, HAUTE) -- Check-in periodique. Detection mouvement accelerometre. Escalade 3 niveaux.
- #S3 Alerte contacts proches (4.7j, P0, VITALE) -- Bouton manuel "Alerter mes proches" (2 taps). Mode balise. Integration Garmin inReach BLE.
- #S4 Roaming / optimisation (3.5j, P2, MOYENNE) -- Carte couverture operateurs, mode avion intelligent, sync opportuniste, guide multi-SIM.

Disclaimers obligatoires : l'app n'est PAS un dispositif de secours, ne contacte jamais les services de secours, depend du reseau et de la batterie.

4 couches complementaires : prevention (ETA + heure max) > detection (dead man switch) > alerte (contacts proches) > optimisation (roaming).

---

## Decisions architecturales cles

- #D01 Offline-first -- Toute feature fonctionne sans reseau. Store-and-forward, pre-cache, BLE peer-to-peer. Source: B2-2 (60% GR20 zone blanche).
- #D02 Sante LOCAL ONLY -- Donnees cardio, SpO2, capteurs stockees Drift uniquement. JAMAIS cloud. Source: decision Chris, B2-BIS #RGPD-05.
- #D03 Logistique = deeplinks -- Pas d'intermediaire, pas de paiement in-app. Liens directs vers prestataires. Source: decision Chris.
- #D04 Pas de secours auto -- L'app n'appelle JAMAIS les secours. Alerte contacts proches uniquement. Source: decision Chris, art. 223-6.
- #D05 Avatars, pas photos (V1) -- Pseudos faune/flore corse. 3 niveaux visibilite. Photos opt-in explicite. Source: B2-4, B2-BIS minimisation.
- #D06 Consentement granulaire -- Opt-in par finalite (perso / groupe / securite). Retrait simple. Horodatage conserve. Source: B2-4 art. 6.1.a, art. 9.

---

## Dependances entre phases

```
Phase 4 (GPS)
  |
  v
Phase 5 (Carte offline, traces GPX)
  |
  +---> Phase 6 Features
  |       |
  |       +---> #F6.1 Signalements -----> #F8.1 Waypoints communautaires
  |       +---> #F6.2 Companion Watch --> #F7.1 Kudos (BLE manager)
  |       +---> #F6.6 ETA -------------> #S1 Heure max (timer + ETA)
  |       +---> #F6.7 Stats -----------> #F7.3 Badges, #F7.5 Defis
  |       |
  |       v
  +---> Phase 7 Social
  |       |
  |       +---> #F7.4 Pseudos ---------> #F8.1 Waypoints, #F7.6 Feed
  |       +---> #F7.2 Leaderboard -----> #F7.5 Defis
  |       |
  |       v
  +---> Phase 8 Communaute
  |       |
  |       +---> #F8.4 Extensibilite (depend de TOUTES les features Phase 6-7)
  |
  +---> Securite (#S1-#S4)
          |
          +---> #S1 Heure max (depend de #F6.6 ETA)
          +---> #S2 Dead man switch (depend de #S1 alert_sender)
          +---> #S3 Alerte contacts (depend de #F6.2 BLE, #S1 contacts)
```

---

## Totaux

- #T01 Phase 6 Features : 37.8j (8 features)
- #T02 Phase 7 Social : 27.3j (7 features)
- #T03 Phase 8 Communaute : 26.5j (4 features)
- #T04 Securite : 18.5j (4 features)
- #T05 TOTAL : 110.1j (23 features)

Source : plans Minerve V3, 2026-06-03. Audits B2-1 a B2-6, B2-BIS, B3.
