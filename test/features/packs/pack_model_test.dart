import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/packs/domain/pack_catalog.dart';
import 'package:moteur_gr/features/packs/domain/pack_manifest.dart';
import 'package:moteur_gr/features/packs/domain/sentier_pack.dart';

/// Tests F8B-01 : modeles Freezed SentierPack + PackManifest (a la carte R2).
///
/// Couvre : serialisation JSON aller-retour du manifeste (tout l'offline) et du
/// pack, listing des packs disponibles A LA CARTE (Nord/Sud/Complet/MaM, pas de
/// tout-abo), et les helpers de manifeste (allRefs / totalFileRefs).
void main() {
  group('PackType — types a la carte (R2)', () {
    test('expose exactement Nord/Sud/Complet/MaM', () {
      expect(PackType.values,
          [PackType.nord, PackType.sud, PackType.complet, PackType.mam]);
    });

    test('fromString retombe sur le fallback pour un type inconnu', () {
      expect(PackType.fromString('inexistant'), PackType.fallback);
      expect(PackType.fromString(PackType.nord), PackType.nord);
    });
  });

  group('SentierPack — serialisation + a la carte', () {
    const pack = SentierPack(
      id: 'mam_complet',
      nom: 'Mare a Mare Complet',
      trailId: 'mare_a_mare_centre',
      type: PackType.complet,
      description: 'Tout le sentier, hors-ligne.',
    );

    test('serialisation JSON aller-retour preserve les champs', () {
      final json = pack.toJson();
      final restored = SentierPack.fromJson(json);
      expect(restored, pack);
      expect(json['type'], PackType.complet);
      expect(json['trailId'], 'mare_a_mare_centre');
    });

    test('isComplet vrai uniquement pour le pack Complet', () {
      expect(pack.isComplet, isTrue);
      expect(pack.copyWith(type: PackType.nord).isComplet, isFalse);
    });
  });

  group('PackManifest — decrit tout l offline (R3)', () {
    const manifest = PackManifest(
      packId: 'mam_complet',
      mbtilesRefs: ['a.mbtiles', 'b.mbtiles'],
      gpxRefs: ['t.gpx'],
      poiRefs: ['poi.json'],
      townGuideRefs: ['guides.json'],
      waypointsSnapshotRef: 'wp.json',
      tailleMo: 340,
      checksum: 'sha256:deadbeef',
    );

    test('serialisation JSON aller-retour preserve cartes/gpx/poi/guides/wp', () {
      final json = manifest.toJson();
      final restored = PackManifest.fromJson(json);
      expect(restored, manifest);
      // Le manifeste decrit TOUT le contenu offline.
      expect(json['mbtilesRefs'], ['a.mbtiles', 'b.mbtiles']);
      expect(json['gpxRefs'], ['t.gpx']);
      expect(json['poiRefs'], ['poi.json']);
      expect(json['townGuideRefs'], ['guides.json']);
      expect(json['waypointsSnapshotRef'], 'wp.json');
      expect(json['tailleMo'], 340);
      expect(json['checksum'], 'sha256:deadbeef');
    });

    test('checksum optionnel : null par defaut (avant backend)', () {
      const m = PackManifest(
        packId: 'mam_nord',
        waypointsSnapshotRef: 'wp.json',
        tailleMo: 180,
      );
      expect(m.checksum, isNull);
      expect(m.mbtilesRefs, isEmpty); // listes par defaut vides
      expect(PackManifest.fromJson(m.toJson()), m);
    });

    test('totalFileRefs compte les fichiers hors snapshot', () {
      // 2 mbtiles + 1 gpx + 1 poi + 1 guide = 5
      expect(manifest.totalFileRefs, 5);
    });

    test('allRefs agrege toutes les references, snapshot inclus', () {
      expect(manifest.allRefs, [
        'a.mbtiles',
        'b.mbtiles',
        't.gpx',
        'poi.json',
        'guides.json',
        'wp.json',
      ]);
      // snapshot toujours en dernier
      expect(manifest.allRefs.last, 'wp.json');
    });
  });

  group('PackCatalog — listing a la carte (pas de tout-abo, R2)', () {
    PackLabels resolver(String type) =>
        PackLabels(nom: 'Pack $type', description: 'Desc $type');

    test('liste 4 packs distincts Nord/Sud/Complet/MaM pour un sentier', () {
      final packs = PackCatalog.availablePacks(
        'mare_a_mare_centre',
        labelResolver: resolver,
      );
      expect(packs, hasLength(4));
      expect(
        packs.map((p) => p.type).toList(),
        [PackType.nord, PackType.sud, PackType.complet, PackType.mam],
      );
      // Chaque pack est rattache au meme sentier mais reste une unite distincte.
      expect(packs.every((p) => p.trailId == 'mare_a_mare_centre'), isTrue);
      expect(packs.map((p) => p.id).toSet(), hasLength(4));
      expect(packs.first.id, 'mare_a_mare_centre_nord');
    });

    test('les libelles sont injectes par le resolver (Slang cote UI)', () {
      final packs = PackCatalog.availablePacks(
        'mare_a_mare_centre',
        labelResolver: resolver,
      );
      expect(packs.first.nom, 'Pack nord');
      expect(packs.first.description, 'Desc nord');
    });

    test('manifestFor : Complet agrege Nord + Sud', () {
      final complet =
          PackCatalog.manifestFor('mare_a_mare_centre', PackType.complet);
      expect(complet.mbtilesRefs, hasLength(2));
      expect(complet.gpxRefs, hasLength(2));
      expect(complet.tailleMo, greaterThan(0));
      expect(complet.packId, 'mare_a_mare_centre_complet');
    });

    test('manifestFor : chaque pack decrit son contenu offline complet', () {
      for (final type in PackCatalog.aLaCarteTypes) {
        final m = PackCatalog.manifestFor('mare_a_mare_centre', type);
        expect(m.mbtilesRefs, isNotEmpty, reason: 'cartes manquantes pour $type');
        expect(m.gpxRefs, isNotEmpty, reason: 'gpx manquant pour $type');
        expect(m.poiRefs, isNotEmpty, reason: 'poi manquant pour $type');
        expect(m.townGuideRefs, isNotEmpty,
            reason: 'guides manquants pour $type');
        expect(m.waypointsSnapshotRef, isNotEmpty);
        expect(m.tailleMo, greaterThan(0));
      }
    });
  });
}
