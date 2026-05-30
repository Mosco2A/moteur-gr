# ORCHESTRATION MOTEUR-GR
Source de verite du progres. Skynet lit ce fichier EN PREMIER a chaque session.
MAJ: 30/05/2026

## Plan
V8 (index #82300 en memory.db). 130 sous-etapes, 32h, 158 tests.
3 couches QA: par commit (dart analyze+tests) / par sous-etape (Artemis) / par phase (build complet).
Design pipeline autonome: #81424 (valide Chris 25/05).
Specs V8: #82290 framework + #82293-#82299 par phase.

## Etat audit 30/05
Phase 0: 0/6 FAIT — Riverpod 2.6 (plan demande 3), flutter_map 6.1 (plan demande 8), pas CI/CD, pas error handling
Phase 1: PARTIEL — 16 enums fermes (#81752), pattern Riverpod 2 (StateNotifierProvider), i18n Slang OK
Phase 2: 1/23 STRICT OK — chemins incorrects, classes renommees, signatures divergentes
Phase 3: commits presents, NON VALIDES (depend Phase 2)
Phase 4: commits presents, NON VALIDES (depend Phase 3)
Phase 5: A FAIRE

## Branches en attente
fix/phase2-batch1-corrections — 3 commits Vulcain (E2.1b, E2.1c, E2.5a) — NE PAS MERGER avant fin Phase 0+1

## Prochaine action
Phase 0 E0.1 — Migration Riverpod 2 vers 3 (spec V8 #82293)

## Derniere action
Audit complet Phases 0-2 termine 30/05. Plan V8 produit par Minerve (#82300).

## Regles
- Skynet ne code PAS — delegue a Vulcain (dev) / Artemis (QA)
- Prompts = copie exacte du plan V8, pas d'improvisation
- Lire fiche Moteur-GR #81413 AVANT chaque prompt agent
- QA par commit + par sous-etape + par phase
- Ce fichier = source de verite, mis a jour apres CHAQUE etape
- Rien hors plan — si pas dans les taches, demander a Chris
