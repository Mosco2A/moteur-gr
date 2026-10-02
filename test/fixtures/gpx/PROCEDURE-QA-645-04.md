# QA locale 645-04 — import GPX reel sur emulateur

Ce dossier existe pour une seule chose : permettre a Skynet de rejouer **sur
l'appareil** ce que les concepts **C-1 (`gpx_parser`)** et **C-3
(`track_point`)** touchent. La session cloud n'a ni SDK Android ni emulateur :
elle prepare, elle ne constate pas.

- **Fichier d'essai** : `test/fixtures/gpx/essai_645_04.gpx`
  (36 points de trace en 3 segments, 2 `trk`, metadata `name`/`desc`/`author`,
  `<ele>` **et** `<time>` sur chaque point, 2 `wpt`). La trace suit le vrai
  Mare a Mare Centre, pour que les controles « hors zone » et « hors trace »
  de l'import passent au vert.
- **Garde de la fixture** : `test/features/after/fixture_gpx_essai_645_04_test.dart`
  verifie que le fichier porte bien ce que cette procedure annonce. S'il
  rougit, le defaut est dans la fixture, pas dans l'application.

## Important — les deux concepts ne passent PAS par la meme porte

La mesure a montre que l'ecran d'import et la trace de la carte ne lisent pas
le GPX par le meme chemin. Les rejouer tous les deux demande donc **deux
manipulations**, et pas une.

| Concept | Ce qui lit le GPX | Comment le declencher |
|---|---|---|
| **C-3** `track_point` | `GpxImportService` (`features/after/data/`), qui construit le `TrackPoint` du domaine trek — `elevation` + `timestamp` | l'ecran d'import GPX |
| **C-1** `gpx_parser` | `GpxParser.parseFromAsset` via `TraceDuSentier` (`core/geo/`) | l'affichage de la trace du sentier sur la carte |

## C-3 — import GPX reel par l'ecran d'import

1. `flutter run` sur l'emulateur, **persona S2 Marc** (randonneur equipe qui
   arrive avec une trace enregistree par une autre application : c'est
   exactement le cas d'usage de cet ecran ; S1 Lea part sans trace).
2. Deposer `essai_645_04.gpx` dans les telechargements de l'emulateur :
   `adb push test/fixtures/gpx/essai_645_04.gpx /sdcard/Download/`
3. **L'ecran d'import n'a plus de porte dans l'interface** — la carte
   « Import GPX » du HUB a ete retiree (cf. le commentaire de
   `lib/core/routing/app_router.dart` au-dessus de la route). La route, elle,
   est conservee. On y entre donc par le routeur :
   - route GoRouter : **`/trail/mare-a-mare-centre/import-gpx`**
     (nom : `trail-import-gpx`, ecran `GpxImportRouteScreen`) ;
   - en debug : `context.goNamed('trail-import-gpx', pathParameters: {'id': 'mare-a-mare-centre'})`,
     ou `adb shell am start -a android.intent.action.VIEW -d "<schema>://trail/mare-a-mare-centre/import-gpx"`
     si le deep-link est actif sur le build essaye.
4. Appuyer sur le choix de fichier, prendre `essai_645_04.gpx`.

**Resultat attendu** : import **valide**, 36 points, D+ > 0 et une duree non
nulle (les `<time>` sont lus), aucun motif d'invalidite. Sur le sentier
Mare a Mare Centre, l'avertissement « hors trace » ne doit PAS apparaitre, et
des etapes doivent etre detectees puisque la trace suit le vrai sentier. Un
import refuse pour « trop peu de points » signifierait que le fichier n'a pas
ete lu : revoir l'etape 2.

## C-1 — trace du sentier sur la carte

1. Meme build, **persona S1 Lea** suffit (elle ouvre la carte du sentier).
2. Ouvrir la carte du sentier Mare a Mare Centre.

**Resultat attendu** : la ligne du sentier s'affiche — c'est
`GpxParser.parseFromAsset('assets/data/mare_a_mare_centre/track.gpx')` qui
l'alimente, par `TraceDuSentier`. Une carte sans ligne, avec le fond de carte
present, est le symptome que la facade d'assets ne rend plus rien.

## Pourquoi cette QA reste utile alors que C-1 et C-3 sortent du lot

Les deux concepts n'ont **pas** ete resorbes : ils attendent un arbitrage de
Christophe (ARB-645-04-b et ARB-645-04-c dans
`docs/assainissement/644-03-decoupage-et-plan.md`). Cette procedure etablit
donc la **reference de comportement AVANT l'arbitrage** : c'est a elle qu'on
comparera apres, le jour ou le doublon sera tranche.
