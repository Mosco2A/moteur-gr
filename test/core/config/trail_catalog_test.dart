import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/mare_a_mare_trail_config.dart';
import 'package:moteur_gr/core/config/pyrenees_trail_config.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/config/trail_catalog.dart';
import 'package:moteur_gr/core/config/trail_selection.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';

/// Tests F8D-01 : catalogue multi-sentiers + selection (moteur generique #84627).
///
/// Couvre : presence d'au moins 2 sentiers de regions differentes (dont un
/// HORS Corse pour prouver la genericite), lookup byId / resolveOrDefault, et le
/// pilotage de la config active par la selection ([trailConfigProvider]).
///
/// MAJ GO-62 (19/06/2026) : Mare a Mare Centre est desormais le PREMIER sentier
/// du catalogue (= sentier par defaut, demande explicite de Christophe). Le
/// moteur RESTE generique : Mare a Mare est une DONNEE ([TrailConfig]) au meme
/// titre que les autres, pas une localite cablee dans la LOGIQUE du moteur.
/// L'ancien garde-fou « aucune config ne nomme la Corse » (#84627 / F8D-01) est
/// donc remplace par un garde-fou cible : Mare a Mare est le SEUL sentier
/// autorise a referencer la Corse ; les autres configs restent neutres.
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

    test('expose au moins un sentier HORS Corse en donnees (genericite)', () {
      // Le sentier Pyrenees prouve la genericite : le moteur charge un sentier
      // hors Corse par la meme config que n'importe quel autre (F8D-01).
      expect(TrailCatalog.contains(pyreneesTrailConfig.id), isTrue);
      final pyr = TrailCatalog.byId(pyreneesTrailConfig.id)!;
      expect(pyr.region, equals('Pyrenees'));
      expect(pyr.totalStages, greaterThan(0));
      expect(pyr.gpxAssetPath, endsWith('.gpx'));
    });

    test('SEUL Mare a Mare reference la Corse ; les autres restent neutres '
        '(GO-62)', () {
      // Garde-fou cible (remplace l'ancien « aucune Corse nulle part », #84627) :
      // depuis GO-62, Mare a Mare est un sentier nomme du catalogue. La regle de
      // genericite demeure pour TOUTES les AUTRES configs : aucune ne doit cabler
      // une localite Corse (elles restent des donnees demo neutres).
      const interdits = ['corse', 'corsica', 'mare a mare', 'mare-a-mare', 'mam'];
      for (final c in TrailCatalog.all) {
        if (c.id == mareAMareTrailConfig.id) continue; // sentier cible autorise
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
                  'hors sentier Mare a Mare)');
        }
      }
    });

    test('Mare a Mare est le sentier par defaut et est centre sur la Corse '
        '(GO-62)', () {
      // Demande explicite de Christophe : a l'ouverture, le sentier propose et
      // centre est Mare a Mare (Corse), pas le Volcans fictif ni les Pyrenees.
      final def = TrailCatalog.defaultTrail;
      expect(def.id, mareAMareTrailConfig.id);
      expect(def.region, equals('Corse'));
      expect(def.totalStages, equals(7));
      expect(def.totalDistanceKm, equals(84.0));
      // Le trace utilise pour centrer la carte vit aux cotes des donnees du
      // sentier (assets/data/mare_a_mare_centre/) et est bien un .gpx.
      expect(def.gpxAssetPath, equals('assets/data/mare_a_mare_centre/track.gpx'));
      expect(def.gpxAssetPath, endsWith('.gpx'));
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
