# ORCHESTRATION MOTEUR-GR
Source de verite du progres. Skynet lit ce fichier EN PREMIER a chaque session.
MAJ: 30/05/2026 15:15

## Plan
V8 (index #82300 en memory.db). 130 sous-etapes, 32h, 158 tests.
3 couches QA: par commit (dart analyze+tests) / par sous-etape (Artemis) / par phase (build complet).
Design pipeline autonome: #81424 (valide Chris 25/05).
Specs V8: #82290 framework + #82293-#82299 par phase.

## Etat phases
Phase 0: 6/6 COMPLETE — mergee main 30/05 14:12. QA Artemis 6/6 PASS.
Phase 1: PARTIEL — 16 enums fermes (#81752), pattern Riverpod 2 (StateNotifierProvider), i18n Slang OK
Phase 2: 1/23 STRICT OK — chemins incorrects, classes renommees, signatures divergentes
Phase 3: commits presents, NON VALIDES (depend Phase 2)
Phase 4: commits presents, NON VALIDES (depend Phase 3)
Phase 5: A FAIRE

## Branches en attente
fix/phase2-batch1-corrections — 3 commits Vulcain (E2.1b, E2.1c, E2.5a) — A integrer dans Phase 2 refactoring

## Prochaine action
Phase 2 E2.3a — MapScreen orchestrateur (GO-81 scope)

## Derniere action
Phase 2 en cours 30/05 15:15. 7/32 sous-etapes mergees (E2.1a-c, E2.2a-b, E2.5a). Prochaine: E2.3a.

## Regles
- Skynet ne code PAS — delegue a Vulcain (dev) / Artemis (QA)
- Prompts = copie exacte du plan V8, pas d'improvisation
- Lire fiche Moteur-GR #81413 AVANT chaque prompt agent
- QA par commit + par sous-etape + par phase
- Ce fichier = source de verite, mis a jour apres CHAQUE etape
- Rien hors plan — si pas dans les taches, demander a Chris
