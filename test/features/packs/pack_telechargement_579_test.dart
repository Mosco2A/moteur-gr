// LOT X (tache 579) — LE TELECHARGEMENT D'UN PACK NE PEUT PLUS ECHOUER EN
// SILENCE.
//
// Le bouton « Telecharger » du store de packs ne produisait RIEN. Trois defauts
// empiles, et chacun suffisait a lui seul :
//
//   1. LE FLUX ECRASAIT L'ETAT « EN COURS ». Le controleur posait
//      `downloading` a l'appui ; le premier evenement du service est `pending`,
//      il arrivait juste apres et remettait la carte dans son etat d'avant.
//   2. LA LECTURE DU STOCKAGE ETAIT HORS DU FILET. `_storage.exists` etait
//      appele en dehors de tout `try` : quand le stockage local n'est pas
//      joignable, l'exception sortait du generateur comme ERREUR DE FLUX, alors
//      que la methode promet en toutes lettres de n'emettre « JAMAIS
//      d'exception ».
//   3. `listen` N'AVAIT PAS DE `onError`. Une erreur de flux ne changeait donc
//      aucun etat : elle finissait en erreur de zone, invisible.
//
// Ces tests se passent de widgets EXPRES : le chemin d'echec demande des
// entrees-sorties reelles, et le temps feint d'un test de widgets ne les fait
// jamais revenir. Ici, rien n'est feint que le stockage lui-meme.
library;

import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/packs/data/pack_download_service.dart';
import 'package:moteur_gr/features/packs/data/pack_storage.dart';
import 'package:moteur_gr/features/packs/domain/pack_catalog.dart';
import 'package:moteur_gr/features/packs/domain/pack_download_progress.dart';
import 'package:moteur_gr/features/packs/domain/pack_manifest.dart';
import 'package:moteur_gr/features/packs/providers/pack_providers.dart';

/// Stockage local INJOIGNABLE : chaque acces leve, comme le fait `path_provider`
/// quand le dossier de documents n'est pas disponible sur l'appareil.
class StockageEnPanne implements PackStorage {
  @override
  Future<bool> exists(String packId, String ref) async =>
      throw Exception('stockage local injoignable');

  @override
  Future<String> save(String packId, String ref, Uint8List bytes) async =>
      throw Exception('stockage local injoignable');

  @override
  Future<Uint8List?> read(String packId, String ref) async =>
      throw Exception('stockage local injoignable');

  @override
  Future<int> packSizeBytes(String packId) async =>
      throw Exception('stockage local injoignable');

  @override
  Future<bool> packExists(String packId) async =>
      throw Exception('stockage local injoignable');

  @override
  Future<int> deletePack(String packId) async =>
      throw Exception('stockage local injoignable');
}

/// Source de fichiers qui echoue toujours — l'etat REEL avant la Phase 4.
class SourceAbsente implements PackFileSource {
  @override
  Future<Uint8List> fetch(String ref) async =>
      throw Exception('source de pack non connectee');
}

/// Stockage en memoire qui marche (isole la panne de la source).
class StockageEnMemoire implements PackStorage {
  final Map<String, Map<String, Uint8List>> _packs = {};

  @override
  Future<String> save(String packId, String ref, Uint8List bytes) async {
    (_packs[packId] ??= {})[ref] = bytes;
    return 'mem://$packId/$ref';
  }

  @override
  Future<bool> exists(String packId, String ref) async =>
      _packs[packId]?.containsKey(ref) ?? false;

  @override
  Future<Uint8List?> read(String packId, String ref) async =>
      _packs[packId]?[ref];

  @override
  Future<int> packSizeBytes(String packId) async => 0;

  @override
  Future<bool> packExists(String packId) async =>
      (_packs[packId]?.isNotEmpty) ?? false;

  @override
  Future<int> deletePack(String packId) async {
    _packs.remove(packId);
    return 0;
  }
}

PackManifest get _manifeste =>
    PackCatalog.manifestFor('mare-a-mare-centre', 'nord');

void main() {
  group('LOT X — le telechargement dit ce qui se passe', () {
    test(
        'un stockage local injoignable devient un EVENEMENT d erreur, pas une '
        'exception de flux', () async {
      final service = PackDownloadService(
        fileSource: SourceAbsente(),
        storage: StockageEnPanne(),
      );

      final evenements = <PackDownloadProgress>[];
      // `toList()` releverait l'erreur de flux : c'est justement ce qu'on
      // interdit. On ecoute donc en notant separement une eventuelle erreur.
      Object? erreurDeFlux;
      await service.downloadPack(_manifeste).listen(
        evenements.add,
        onError: (Object e) => erreurDeFlux = e,
      ).asFuture<void>().catchError((Object e) => erreurDeFlux = e);

      expect(erreurDeFlux, isNull,
          reason: 'la methode promet de n emettre JAMAIS d exception : elle '
              'sortait pourtant par `_storage.exists`, hors de tout filet');
      expect(evenements.last.status, PackDownloadStatus.error,
          reason: 'l echec doit arriver a l UI comme un ETAT lisible');
      expect(evenements.last.error, isNotNull);
    });

    test('le controleur passe en erreur quand le flux echoue', () async {
      final conteneur = ProviderContainer(
        overrides: [
          packStorageProvider.overrideWithValue(StockageEnPanne()),
          packFileSourceProvider.overrideWithValue(SourceAbsente()),
        ],
      );
      addTearDown(conteneur.dispose);

      final packId = _manifeste.packId;
      final notifieur =
          conteneur.read(packDownloadControllerProvider(packId).notifier);
      await notifieur.download(_manifeste);
      // Laisse le flux se derouler jusqu'au bout.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final etat = conteneur.read(packDownloadControllerProvider(packId));
      expect(etat.isError, isTrue,
          reason: 'sans `onError` sur `listen`, une erreur de flux ne changeait '
              'AUCUN etat : la carte restait comme avant l appui');
      expect(etat.error, isNotNull);
    });

    test(
        'la source absente donne un etat d erreur apres les tentatives bornees',
        () async {
      final conteneur = ProviderContainer(
        overrides: [
          packStorageProvider.overrideWithValue(StockageEnMemoire()),
          packFileSourceProvider.overrideWithValue(SourceAbsente()),
        ],
      );
      addTearDown(conteneur.dispose);

      final packId = _manifeste.packId;
      final notifieur =
          conteneur.read(packDownloadControllerProvider(packId).notifier);
      await notifieur.download(_manifeste);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final etat = conteneur.read(packDownloadControllerProvider(packId));
      expect(etat.isError, isTrue,
          reason: 'la source n est pas connectee avant la Phase 4 : l ecran '
              'doit finir sur un etat d erreur, jamais sur un ecran inchange');
    });

    test(
        'le premier evenement du flux n annule plus l etat « en cours » pose a '
        'l appui', () async {
      final conteneur = ProviderContainer(
        overrides: [
          packStorageProvider.overrideWithValue(StockageEnMemoire()),
          packFileSourceProvider.overrideWithValue(SourceAbsente()),
        ],
      );
      addTearDown(conteneur.dispose);

      final packId = _manifeste.packId;
      final vus = <String>[];
      // On n'ecoute QUE les changements : l'etat initial est `pending` par
      // construction (rien n'est demande), ce n'est pas lui qu'on surveille.
      conteneur.listen(
        packDownloadControllerProvider(packId),
        (avant, apres) => vus.add(apres.status),
      );

      final notifieur =
          conteneur.read(packDownloadControllerProvider(packId).notifier);
      await notifieur.download(_manifeste);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final debut = vus.indexOf(PackDownloadStatus.downloading);
      expect(debut, isNonNegative,
          reason: 'l appui doit poser un etat « en cours »');
      expect(vus.skip(debut).contains(PackDownloadStatus.pending), isFalse,
          reason: 'une fois « en cours » pose, l ecran n a plus le droit de '
              'revenir a « en file » : c est exactement son etat d avant '
              'l appui, et c est ce qui faisait passer le bouton pour mort');
      expect(vus.last, PackDownloadStatus.error,
          reason: 'la sequence doit se terminer sur un etat lisible');
    });
  });
}
