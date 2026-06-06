import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:moteur_gr/core/map/mbtiles_manager.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Fake path_provider qui retourne un dossier temporaire.
class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProvider(this.tempDir);
  final Directory tempDir;

  @override
  Future<String?> getApplicationDocumentsPath() async => tempDir.path;
}

void main() {
  late Directory tempDir;
  late FakePathProvider fakePathProvider;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('mbtiles_test_');
    fakePathProvider = FakePathProvider(tempDir);
    PathProviderPlatform.instance = fakePathProvider;
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('MBTilesManager', () {
    group('downloadMbtiles', () {
      test('telecharge et sauvegarde le fichier localement', () async {
        final fakeContent = Uint8List.fromList([0x53, 0x51, 0x4C, 0x69]);
        final mockClient = MockClient((request) async {
          return http.Response.bytes(fakeContent, 200);
        });
        final manager = MBTilesManager(httpClient: mockClient);

        await manager.downloadMbtiles('https://example.com/sentier-bleu.mbtiles', 'sentier-bleu');

        final path = await manager.getMbtilesPath('sentier-bleu');
        final file = File(path);
        expect(file.existsSync(), isTrue);
        expect(file.readAsBytesSync(), equals(fakeContent));
      });

      test('lance une exception si HTTP != 200', () async {
        final mockClient = MockClient((request) async {
          return http.Response('Not Found', 404);
        });
        final manager = MBTilesManager(httpClient: mockClient);

        expect(
          () => manager.downloadMbtiles('https://example.com/bad.mbtiles', 'bad'),
          throwsA(isA<HttpException>()),
        );
      });

      test('ecrase un fichier existant', () async {
        final content1 = Uint8List.fromList([1, 2, 3]);
        final content2 = Uint8List.fromList([4, 5, 6, 7]);
        final mockClient1 = MockClient((_) async => http.Response.bytes(content1, 200));
        final mockClient2 = MockClient((_) async => http.Response.bytes(content2, 200));

        final manager1 = MBTilesManager(httpClient: mockClient1);
        await manager1.downloadMbtiles('https://example.com/v1.mbtiles', 'trail1');

        final manager2 = MBTilesManager(httpClient: mockClient2);
        await manager2.downloadMbtiles('https://example.com/v2.mbtiles', 'trail1');

        final path = await manager2.getMbtilesPath('trail1');
        expect(File(path).readAsBytesSync(), equals(content2));
      });
    });

    group('deleteMbtiles', () {
      test('supprime le fichier existant', () async {
        final mockClient = MockClient((_) async => http.Response.bytes(Uint8List(4), 200));
        final manager = MBTilesManager(httpClient: mockClient);

        await manager.downloadMbtiles('https://example.com/t.mbtiles', 'trail_del');
        expect(await manager.hasMbtiles('trail_del'), isTrue);

        await manager.deleteMbtiles('trail_del');
        expect(await manager.hasMbtiles('trail_del'), isFalse);
      });

      test('ne leve pas d erreur si fichier absent', () async {
        final manager = MBTilesManager();

        // Ne devrait pas lever d'exception
        await manager.deleteMbtiles('inexistant');
      });
    });

    group('hasMbtiles', () {
      test('retourne false si pas de fichier', () async {
        final manager = MBTilesManager();
        expect(await manager.hasMbtiles('aucun'), isFalse);
      });

      test('retourne true apres telechargement', () async {
        final mockClient = MockClient((_) async => http.Response.bytes(Uint8List(8), 200));
        final manager = MBTilesManager(httpClient: mockClient);

        await manager.downloadMbtiles('https://example.com/x.mbtiles', 'existe');
        expect(await manager.hasMbtiles('existe'), isTrue);
      });
    });

    group('getMbtilesPath', () {
      test('retourne un chemin contenant le trailId', () async {
        final manager = MBTilesManager();
        final path = await manager.getMbtilesPath('mon_sentier');

        expect(path, contains('mbtiles'));
        expect(path, contains('mon_sentier'));
        expect(path, endsWith('.mbtiles'));
      });
    });

    group('listDownloaded', () {
      test('retourne une liste vide sans telechargements', () async {
        final manager = MBTilesManager();
        final list = await manager.listDownloaded();
        expect(list, isEmpty);
      });

      test('retourne les trailIds des fichiers telecharges', () async {
        final mockClient = MockClient((_) async => http.Response.bytes(Uint8List(4), 200));
        final manager = MBTilesManager(httpClient: mockClient);

        await manager.downloadMbtiles('https://example.com/a.mbtiles', 'sentier_a');
        await manager.downloadMbtiles('https://example.com/b.mbtiles', 'sentier_b');

        final list = await manager.listDownloaded();
        expect(list, containsAll(['sentier_a', 'sentier_b']));
        expect(list.length, 2);
      });

      test('ne liste plus un sentier supprime', () async {
        final mockClient = MockClient((_) async => http.Response.bytes(Uint8List(4), 200));
        final manager = MBTilesManager(httpClient: mockClient);

        await manager.downloadMbtiles('https://example.com/c.mbtiles', 'sentier_c');
        await manager.downloadMbtiles('https://example.com/d.mbtiles', 'sentier_d');
        await manager.deleteMbtiles('sentier_c');

        final list = await manager.listDownloaded();
        expect(list, contains('sentier_d'));
        expect(list, isNot(contains('sentier_c')));
      });
    });
  });
}
