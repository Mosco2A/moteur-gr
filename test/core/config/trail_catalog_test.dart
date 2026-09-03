import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';

/// Tests F8D-01 : catalogue multi-sentiers + selection (moteur generique #84627).
///
/// Couvre : presence d'au moins 2 sentiers de regions differentes (dont un
/// premier HORS Corse), lookup byId / resolveOrDefault, ZERO hardcode Corse/MaM,
/// et le pilotage de la config active par la selection ([trailConfigProvider]).
void main() {
  group('TrailCatalog — multi-sentiers (#84627)', () {
    test('contient au moins 2 sentiers de regions differentes', () {
      expect(TrailCatalog.all.length, greaterThanOrEqualTo(2));
      final regions = TrailCatalog.all.map((c) => c.region).toSet();
      expect(regions.length, greaterThanOrEqualTo(2),
          reason: 'les sentiers doivent couvrir des regions distinctes');
    });

    test('ids uniques et non vides', () {
      final ids = TrailCatalog.ids;
      expect(ids, everyElement(isNotEmpty));
      expect(ids.toSet().length, ids.length, reason: 'ids dupliques');
    });

    test('expose un premier sentier HORS Corse en donnees', () {
      // Le sentier Pyrenees prouve la genericite (1er hors Corse, F8D-01).
      expect(TrailCatalog.contains(pyreneesTrailConfig.id), isTrue);
      final pyr = TrailCatalog.byId(pyreneesTrailConfig.id)!;
      expect(pyr.region, equals('Pyrenees'));
      expect(pyr.totalStages, greaterThan(0));
      expect(pyr.gpxAssetPath, endsWith('.gpx'));
    });

    test('les sentiers AUTRES que la demo restent neutres (genericite #84627)', () {
      // PARITE GR20 — LOT 1 (#99423) : la demo StepWays est desormais un
      // sentier REEL (Mare a Mare Centre, Corse), en tete du catalogue -> il a
      // le DROIT de nommer sa vraie region/localite (c'est une DONNEE). La
      // genericite du moteur (#84627) se prouve autrement : les AUTRES sentiers
      // du catalogue restent neutres (aucune localite Corse cablee), et surtout
      // le MOTEUR ne hardcode rien (cf. test dedie plus bas). On borne donc
      // l'interdiction aux sentiers != demo par defaut.
      const interdits = ['corse', 'corsica', 'mare a mare', 'mare-a-mare', 'mam'];
      final autres = TrailCatalog.all
          .where((c) => c.id != TrailCatalog.defaultTrail.id);
      for (final c in autres) {
        final blob = [
          c.id,
          c.name,
          c.displayName,
          c.tagline,
          c.region,
          c.country,
        ].join(' ').toLowerCase();
        for (final mot in interdits) {
          expect(blob.contains(mot), isFalse,
              reason: 'config ${c.id} contient "$mot" (hardcode Corse interdit '
                  'hors sentier de demo)');
        }
      }
    });

    test('byId retrouve une config connue, null sinon', () {
      expect(TrailCatalog.byId(testTrailConfig.id), isNotNull);
      expect(TrailCatalog.byId('sentier-inexistant'), isNull);
    });

    test('resolveOrDefault retombe sur le defaut si id invalide/null', () {
      expect(TrailCatalog.resolveOrDefault(null).id,
          TrailCatalog.defaultTrail.id);
      expect(TrailCatalog.resolveOrDefault('zzz').id,
          TrailCatalog.defaultTrail.id);
      expect(TrailCatalog.resolveOrDefault(pyreneesTrailConfig.id).id,
          pyreneesTrailConfig.id);
    });

    test('defaultTrail est le premier du catalogue', () {
      expect(TrailCatalog.defaultTrail.id, TrailCatalog.all.first.id);
    });
  });

  group('PARITE GR20 — LOT 1 : la demo demarre sur Mare a Mare Centre', () {
    test('le catalogue contient le sentier Mare a Mare Centre', () {
      expect(TrailCatalog.contains('mare-a-mare-centre'), isTrue);
    });

    test('defaultTrail = mare-a-mare-centre (l\'app demarre dessus)', () {
      // Critere de « fait » (#99423) : au lancement, l'app ouvre le HUB Mare a
      // Mare Centre -> le sentier par defaut du catalogue DOIT etre celui-ci.
      expect(TrailCatalog.defaultTrail.id, 'mare-a-mare-centre');
    });

    test('la config par defaut porte 7 etapes en Corse (donnees seed)', () {
      final demo = TrailCatalog.defaultTrail;
      expect(demo.totalStages, 7);
      expect(demo.region, 'Corse');
      // seedAssetsBase pointe sur le DOSSIER de donnees reelles (mam-c-*),
      // jamais le fichier test-only mare_a_mare_centre.json (mam-ew-*).
      expect(demo.seedAssetsBase, 'assets/data/mare_a_mare_centre');
    });

    test('sans selection, trailConfigProvider = mare-a-mare-centre', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trailConfigProvider).id, 'mare-a-mare-centre');
    });
  });

  group('Selection -> config active (trailConfigProvider)', () {
    test('par defaut, la config active = sentier par defaut du catalogue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(trailConfigProvider).id,
          TrailCatalog.defaultTrail.id);
    });

    test('changer la selection bascule la config active (F8D-02)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Bascule vers le sentier Pyrenees (1er hors Corse).
      container.read(selectedTrailIdProvider.notifier).state =
          pyreneesTrailConfig.id;

      final active = container.read(trailConfigProvider);
      expect(active.id, pyreneesTrailConfig.id);
      expect(active.region, 'Pyrenees');
      // trailIdProvider / trailNameProvider suivent la bascule.
      expect(container.read(trailIdProvider), pyreneesTrailConfig.id);
      expect(container.read(trailNameProvider),
          pyreneesTrailConfig.displayName);
    });

    test('une selection invalide retombe sur le defaut (robustesse)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedTrailIdProvider.notifier).state = 'obsolete';
      expect(container.read(trailConfigProvider).id,
          TrailCatalog.defaultTrail.id);
    });

    test('override de trailConfigProvider prime sur la selection', () {
      final container = ProviderContainer(
        overrides: [
          trailConfigProvider.overrideWithValue(pyreneesTrailConfig),
        ],
      );
      addTearDown(container.dispose);

      // Meme si la selection pointe ailleurs, l'override gagne (mono-sentier).
      container.read(selectedTrailIdProvider.notifier).state =
          testTrailConfig.id;
      expect(container.read(trailConfigProvider).id, pyreneesTrailConfig.id);
    });

    test('availableTrailsProvider expose tout le catalogue', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(availableTrailsProvider).map((c) => c.id),
        containsAll(TrailCatalog.ids),
      );
    });
  });
}
