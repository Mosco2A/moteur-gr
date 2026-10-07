# Memory — vulcain

_Notes locales de vulcain. La source de verite reste memory.db._

## 07/10 — lot coche de preparation calculee (branche claude/feat/coche-de-preparation-calculee)

- [debut] Tete d'integration verifiee : 52fb8ac2 (inchangee depuis 07/10 13:33). Branche neuve prise dessus, jamais main.
- [debut] memory.db et scripts/memory_helper.py ABSENTS du conteneur cloud : #101465, #101481, #101488 illisibles. Notes gravees ici, a reporter en base.
- [debut] Pas de SDK Flutter fourni : installe 3.47.6 stable hors depot. `pub get` reecrit pubspec.lock (paquets epingles par le SDK) : NON commite.
- [commentaires] hub_prepare_section.dart l.1 : « quatorze » -> « douze » (12 QuickAccessCard comptees). Le fichier est sous presentation/widgets/, pas presentation/.
- [commentaires] retained_plan_store.dart l.13-16 : « la base Drift tourne en memoire » corrige (fichier durable depuis la tache 613).
- [constat] Matiere de la coche : StepStatusIcon + QuickAccessCard.stepStatus, jamais passe. Aucun test ne cite StepStatusIcon a ce jour.
