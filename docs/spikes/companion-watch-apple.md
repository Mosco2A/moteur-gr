# Spike de chiffrage — App montre native Apple Watch (F6F-04)

> **Statut : SPIKE de chiffrage, PAS du code de production.**
> Livrable destiné à une décision de Christophe avant tout développement natif réel.
> Correctif F6F-04 du design D1 (Phase 6). Décision CP1 #2 : companion watch recadré à la
> baisse — ceinture BLE (F6F-02) + lecture Health (F6F-03) d'abord ; app montre native = 1
> seule plateforme à la fois, **non engagée** sans GO explicite de Christophe.

## 1. Contexte et périmètre

L'app montre native est l'option la plus coûteuse de la stratégie « capteurs ». Les quick-wins
déjà livrés (ceinture cardio BLE en Flutter pur, lecture de la montre de l'utilisateur via
HealthKit / Health Connect) couvrent l'essentiel du besoin FC/pas/calories **sans** seconde
codebase. Ce spike chiffre l'effort d'une app **Apple Watch native MVP** pour un trek premium
(base utilisateur la plus susceptible d'avoir une Apple Watch, audit A5-7).

**Hors périmètre (non engagé, V+1) :** Wear OS (Kotlin / Health Services) et Garmin
(Monkey C / Connect IQ, contrainte data field 5 min) — chacun serait une **codebase native
supplémentaire** (3 au total). Décision CP1 #2 : une plateforme à la fois.

## 2. Stack technique réelle

- **UI montre** : SwiftUI (watchOS) ou WatchKit.
- **Logique montre** : Swift (pas de Dart sur la montre — le moteur Flutter ne tourne pas sur
  watchOS).
- **Pont montre ↔ téléphone** : `WatchConnectivity` (`WCSession`) côté natif.
- **Pont Flutter ↔ iOS** : `MethodChannel` / `EventChannel` côté app iPhone + plugin type
  `watch_connectivity`.
- **Capteurs montre** : `CoreLocation` (GPS montre) + `HealthKit` (FC sur la montre).

L'app iPhone (Flutter) reste le maître ; la montre est un afficheur + capteur secondaire qui
synchronise au retour de portée.

## 3. Périmètre MVP minimal

1. Afficher l'étape / la navigation courante (prochain waypoint, distance, ETA) poussée
   depuis le téléphone.
2. Capter GPS + FC **sur la montre** quand le téléphone est en poche / hors de portée.
3. Synchroniser les points capturés vers le téléphone au retour de portée (`WCSession`
   `transferUserInfo` / file de transfert).

Pas de cartographie offline sur la montre, pas de saisie de signalement sur la montre au MVP.

## 4. Estimation effort (jours-homme)

- **L1 — Extension watchOS** (cible Xcode, signing, provisioning, squelette SwiftUI) :
  3 à 5 j-h.
- **L2 — Pont WatchConnectivity** (WCSession) + plugin Flutter↔iOS (MethodChannel, états de
  session, reachability) : 5 à 8 j-h.
- **L3 — Capture GPS + FC sur la montre** (CoreLocation watchOS + HealthKit) + modèle de
  données de transfert : 5 à 8 j-h.
- **L4 — Synchronisation montre→téléphone** (file de transfert, reprise au retour de portée,
  fusion avec la trace iPhone) : 4 à 6 j-h.
- **L5 — Tests sur device réel** (le simulateur watchOS est insuffisant pour GPS/HealthKit),
  réglages batterie, gestion déconnexion : 4 à 6 j-h.
- **L6 — Revue Apple** (App Store Connect : app watchOS distincte, fiches, captures,
  conformité HealthKit) : 2 à 3 j-h.

**Total : 23 à 36 j-h**, soit ≈ 5 à 7 semaines-homme pour un MVP Apple Watch seul.

## 5. Risques

- **2ᵉ codebase à maintenir** : Swift/SwiftUI en plus de Flutter — coût récurrent (montée de
  version watchOS, SDK iOS annuel).
- **Pas de Dart sur la montre** : aucune réutilisation du moteur Flutter ; toute logique
  affichée sur la montre est ré-implémentée.
- **Device réel obligatoire** : le simulateur watchOS ne fournit ni GPS réel ni HealthKit
  complet — il faut au moins une Apple Watch physique pour tester (et pour la revue).
- **Revue Apple** : une app watchOS est soumise séparément ; l'usage HealthKit déclenche des
  contrôles de confidentialité supplémentaires.
- **Batterie de la montre** : capter GPS+FC en continu vide la batterie rapidement —
  nécessite la même stratégie adaptative que côté téléphone (F6A-03/04), à reporter en Swift.
- **Effet multiplicateur** : engager Apple Watch crée une attente symétrique Wear OS / Garmin
  (2 codebases natives de plus).

## 6. Recommandation

**NE PAS développer l'app montre native maintenant.**

Justification :

1. Les quick-wins **déjà livrés** (F6F-02 ceinture BLE GATT + F6F-03 lecture HealthKit/Health
   Connect) couvrent le besoin FC/pas/calories **sans** seconde codebase ni revue Apple
   supplémentaire — l'utilisateur porte sa propre montre, StepWays lit ses données.
2. Le ROI d'une app watchOS MVP (23–36 j-h + maintenance récurrente) est faible tant que la
   base utilisateurs premium Apple Watch n'est pas mesurée et demandeuse.
3. Le moment opportun : **après** mise en marché et **mesure terrain** (BAT-2, F6A-04) auprès
   d'utilisateurs réclamant une expérience montre autonome — et alors **une seule
   plateforme**, avec GO explicite de Christophe.

**Décision requise de Christophe** avant tout développement natif réel. Wear OS et Garmin
restent **non engagés** (V+1).
