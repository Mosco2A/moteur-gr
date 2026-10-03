import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
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

/// UN PUITS D ECRITURE QUI SATURE — LE DISQUE PLEIN, MESURE ET PAS SUPPOSE.
///
/// « Ce qui se passe quand la place manque sur le telephone » est une question de la
/// consigne du lot 622. Un disque plein ne se provoque pas sur la machine d un
/// developpeur ; il se provoque ici, au bon endroit, avec le code d erreur du
/// systeme (`ENOSPC` = 28).
class _PuitsSature extends Fake implements IOSink {
  _PuitsSature(this.cible, {required this.octetsAvantSaturation});

  final File cible;
  final int octetsAvantSaturation;
  int _ecrits = 0;

  @override
  void add(List<int> data) {
    if (_ecrits + data.length > octetsAvantSaturation) {
      throw FileSystemException(
        'Impossible d ecrire',
        cible.path,
        const OSError('No space left on device', 28),
      );
    }
    _ecrits += data.length;
    cible.writeAsBytesSync(data, mode: FileMode.append, flush: true);
  }

  @override
  Future<void> flush() async {}

  @override
  Future<void> close() async {}
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

  /// Une carte factice de [octets] octets, et son empreinte reelle.
  ({Uint8List contenu, String empreinte}) map(int octets) {
    final contenu = Uint8List.fromList(
      List<int>.generate(octets, (i) => (i * 7 + 13) % 256),
    );
    return (contenu: contenu, empreinte: sha256.convert(contenu).toString());
  }

  /// Un serveur qui SAIT reprendre : il lit l en-tete `Range` et rend 206.
  ///
  /// [demandes] recoit une ligne par requete : c est ce qui permet d AFFIRMER
  /// qu une reprise n a pas retelecharge le debut du fichier.
  http.Client serveur(
    Uint8List contenu, {
    List<String?>? demandes,
    int? couperApres,
  }) {
    return MockClient((requete) async {
      final plage = requete.headers['Range'];
      demandes?.add(plage);
      var depuis = 0;
      if (plage != null) {
        depuis = int.parse(plage.replaceAll('bytes=', '').split('-').first);
      }
      var corps = Uint8List.sublistView(contenu, depuis);
      if (couperApres != null && corps.length > couperApres) {
        corps = Uint8List.sublistView(corps, 0, couperApres);
      }
      return http.Response.bytes(
        corps,
        plage == null ? HttpStatus.ok : HttpStatus.partialContent,
      );
    });
  }

  group('MBTilesManager — le transport des cartes hors ligne (tache 622)', () {
    group('la carte descend, verifiee, sous son nom definitif', () {
      test('une carte complete et conforme est posee', () async {
        final c = map(4096);
        final manager = MBTilesManager(httpClient: serveur(c.contenu));

        final bilan = await manager.descendre(
          trailId: 'sentier-bleu',
          url: 'https://example.com/sentier-bleu.mbtiles',
          octetsAttendus: c.contenu.length,
          empreinteAttendue: c.empreinte,
        );

        expect(bilan.reussie, isTrue);
        expect(bilan.octetsTransferes, c.contenu.length);
        expect(bilan.octetsReprisDuDisque, 0);
        expect(await manager.hasMbtiles('sentier-bleu'), isTrue);
        expect(
          await File(await manager.getMbtilesPath('sentier-bleu')).length(),
          c.contenu.length,
        );
        // Aucun fichier en cours ne survit a une descente reussie.
        expect(
          File(await manager.cheminPartiel('sentier-bleu')).existsSync(),
          isFalse,
        );
      });

      test(
        'l empreinte est acceptee avec ou sans le prefixe sha256:',
        () async {
          final c = map(1024);
          final manager = MBTilesManager(httpClient: serveur(c.contenu));

          final bilan = await manager.descendre(
            trailId: 'prefixe',
            url: 'https://example.com/p.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: 'sha256:${c.empreinte.toUpperCase()}',
          );

          expect(bilan.reussie, isTrue);
        },
      );

      test(
        'la progression annonce le poids total, pas seulement le recu',
        () async {
          final c = map(2 * 1024 * 1024);
          final manager = MBTilesManager(httpClient: serveur(c.contenu));
          final points = <MapProgress>[];

          await manager.descendre(
            trailId: 'poids',
            url: 'https://example.com/poids.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
            progression: points.add,
          );

          expect(points, isNotEmpty);
          expect(points.last.octetsRecus, c.contenu.length);
          expect(points.last.octetsTotal, c.contenu.length);
          expect(points.last.fraction, 1.0);
          // 2 097 152 octets = 2,1 Mo tels qu on les annonce a un randonneur.
          expect(
            MapProgress.enMegaoctets(c.contenu.length),
            closeTo(2.097, 0.001),
          );
        },
      );
    });

    group('UNE CARTE A MOITIE ECRITE NE DOIT JAMAIS PORTER LE NOM DEFINITIF', () {
      test('une coupure en route laisse un .partiel, pas une carte', () async {
        final c = map(8192);
        // Le serveur ne rend que 3000 octets sur les 8192 annonces.
        final manager = MBTilesManager(
          httpClient: serveur(c.contenu, couperApres: 3000),
        );

        final bilan = await manager.descendre(
          trailId: 'coupe',
          url: 'https://example.com/coupe.mbtiles',
          octetsAttendus: c.contenu.length,
          empreinteAttendue: c.empreinte,
        );

        expect(bilan.reussie, isFalse);
        expect(bilan.echec, MapFailure.tailleInattendue);
        expect(await manager.hasMbtiles('coupe'), isFalse);
      });

      test(
        'une empreinte fausse DETRUIT le fichier en cours et ne pose rien',
        () async {
          final c = map(4096);
          final manager = MBTilesManager(httpClient: serveur(c.contenu));

          final bilan = await manager.descendre(
            trailId: 'menteur',
            url: 'https://example.com/m.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: 'a' * 64,
          );

          expect(bilan.echec, MapFailure.empreinteInvalide);
          expect(await manager.hasMbtiles('menteur'), isFalse);
          // DETRUIT, et pas conserve : reprendre sur un contenu faux ne pourrait
          // jamais produire la bonne empreinte.
          expect(
            File(await manager.cheminPartiel('menteur')).existsSync(),
            isFalse,
          );
        },
      );

      test('un code HTTP inattendu ne cree aucun fichier', () async {
        final manager = MBTilesManager(
          httpClient: MockClient((_) async => http.Response('absent', 404)),
        );

        final bilan = await manager.descendre(
          trailId: 'absent',
          url: 'https://example.com/absent.mbtiles',
          octetsAttendus: 1024,
          empreinteAttendue: 'b' * 64,
        );

        expect(bilan.echec, MapFailure.reseau);
        expect(await manager.hasMbtiles('absent'), isFalse);
      });
    });

    group('LA REPRISE : une coupure ne fait pas recommencer 260 Mo', () {
      test(
        'le second appel demande la suite et ne retelecharge pas le debut',
        () async {
          final c = map(10000);
          final demandes = <String?>[];

          // Premier essai : le serveur coupe a 4000 octets.
          final bilanCoupe =
              await MBTilesManager(
                httpClient: serveur(
                  c.contenu,
                  demandes: demandes,
                  couperApres: 4000,
                ),
              ).descendre(
                trailId: 'reprise',
                url: 'https://example.com/r.mbtiles',
                octetsAttendus: c.contenu.length,
                empreinteAttendue: c.empreinte,
              );
          expect(bilanCoupe.reussie, isFalse);

          // La taille inattendue detruit le partiel : on recommence proprement, mais
          // cette fois le serveur coupe APRES une ecriture reussie du debut.
          // On simule donc la vraie coupure reseau : un flux qui s arrete.
          final partiel = File(await MBTilesManager().cheminPartiel('reprise'));
          await partiel.writeAsBytes(
            Uint8List.sublistView(c.contenu, 0, 4000),
            flush: true,
          );

          demandes.clear();
          final reprise = MBTilesManager(
            httpClient: serveur(c.contenu, demandes: demandes),
          );
          final bilan = await reprise.descendre(
            trailId: 'reprise',
            url: 'https://example.com/r.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
          );

          expect(bilan.reussie, isTrue);
          expect(demandes.single, 'bytes=4000-');
          // LE CHIFFRE DU FORFAIT : 6000 octets ont voyage, pas 10 000.
          expect(bilan.octetsTransferes, 6000);
          expect(bilan.octetsReprisDuDisque, 4000);
          expect(bilan.estUneReprise, isTrue);
          expect(await reprise.hasMbtiles('reprise'), isTrue);
        },
      );

      test(
        'un fichier deja complet est verifie et pose SANS aucun transport',
        () async {
          final c = map(5000);
          final manager = MBTilesManager(
            httpClient: MockClient((_) async {
              fail('aucune requete ne doit partir : tout est deja la');
            }),
          );
          await File(
            await manager.cheminPartiel('deja'),
          ).writeAsBytes(c.contenu, flush: true);

          final bilan = await manager.descendre(
            trailId: 'deja',
            url: 'https://example.com/d.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
          );

          expect(bilan.reussie, isTrue);
          expect(bilan.octetsTransferes, 0);
          expect(bilan.octetsReprisDuDisque, c.contenu.length);
          expect(await manager.hasMbtiles('deja'), isTrue);
        },
      );

      test(
        'un fichier en cours plus GROS que la carte annoncee repart de zero',
        () async {
          final c = map(3000);
          final demandes = <String?>[];
          final manager = MBTilesManager(
            httpClient: serveur(c.contenu, demandes: demandes),
          );
          // Une carte republiee, plus petite que le fichier laisse par la descente
          // precedente : reprendre dessus produirait un contenu melange.
          await File(
            await manager.cheminPartiel('republie'),
          ).writeAsBytes(Uint8List(9000), flush: true);

          final bilan = await manager.descendre(
            trailId: 'republie',
            url: 'https://example.com/rep.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
          );

          expect(bilan.reussie, isTrue);
          expect(
            demandes.single,
            isNull,
            reason: 'aucun Range : on repart de zero',
          );
          expect(bilan.octetsReprisDuDisque, 0);
        },
      );
    });

    group('LE MOYEN D ANNULER', () {
      test(
        'annuler arrete le transport, conserve le deja-la, et ne pose rien',
        () async {
          final c = map(3 * 1024 * 1024);
          final jeton = AnnulationDeDescente();
          final manager = MBTilesManager(
            httpClient: MockClient.streaming((_, __) async {
              // Un flux en morceaux, comme une vraie liaison.
              Stream<List<int>> morceaux() async* {
                for (var i = 0; i < c.contenu.length; i += 256 * 1024) {
                  final fin = (i + 256 * 1024).clamp(0, c.contenu.length);
                  yield Uint8List.sublistView(c.contenu, i, fin);
                  await Future<void>.delayed(Duration.zero);
                }
              }

              return http.StreamedResponse(morceaux(), HttpStatus.ok);
            }),
          );

          final bilan = await manager.descendre(
            trailId: 'annule',
            url: 'https://example.com/a.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
            annulation: jeton,
            // Le randonneur appuie sur « annuler » des qu il voit la progression.
            progression: (_) => jeton.cancel(),
          );

          expect(bilan.echec, MapFailure.annulee);
          expect(await manager.hasMbtiles('annule'), isFalse);
          // ANNULER NE PUNIT PAS : ce qui est descendu reste, pour la reprise.
          expect(bilan.octetsSurLeTelephone, greaterThan(0));
          expect(
            File(await manager.cheminPartiel('annule')).existsSync(),
            isTrue,
          );
        },
      );

      test('un jeton deja annule empeche toute requete', () async {
        final jeton = AnnulationDeDescente()..cancel();
        final manager = MBTilesManager(
          httpClient: MockClient((_) async => fail('aucune requete attendue')),
        );

        final bilan = await manager.descendre(
          trailId: 'jamais',
          url: 'https://example.com/j.mbtiles',
          octetsAttendus: 1024,
          empreinteAttendue: 'c' * 64,
          annulation: jeton,
        );

        expect(bilan.echec, MapFailure.annulee);
      });
    });

    group('QUAND LA PLACE MANQUE SUR LE TELEPHONE', () {
      test('le disque plein est NOMME, la carte n est pas posee, et le deja-la '
          'reste pour reprendre apres liberation', () async {
        final c = map(20000);
        late File partiel;
        final manager = MBTilesManager(
          // Un flux en morceaux de 4 000 octets, comme une vraie liaison : c est ce
          // qui permet a la saturation de tomber EN COURS d ecriture, et donc de
          // verifier ce qui reste sur le telephone.
          httpClient: MockClient.streaming((_, __) async {
            Stream<List<int>> morceaux() async* {
              for (var i = 0; i < c.contenu.length; i += 4000) {
                final fin = (i + 4000).clamp(0, c.contenu.length);
                yield Uint8List.sublistView(c.contenu, i, fin);
              }
            }

            return http.StreamedResponse(morceaux(), HttpStatus.ok);
          }),
          ouvrirEnEcriture: (fichier, {required enAjout}) {
            partiel = fichier;
            return _PuitsSature(fichier, octetsAvantSaturation: 8000);
          },
        );

        final bilan = await manager.descendre(
          trailId: 'plein',
          url: 'https://example.com/pl.mbtiles',
          octetsAttendus: c.contenu.length,
          empreinteAttendue: c.empreinte,
        );

        expect(bilan.echec, MapFailure.plusDePlace);
        expect(await manager.hasMbtiles('plein'), isFalse);
        expect(partiel.path, endsWith(MBTilesManager.suffixePartiel));
        // Ce qui avait pu s ecrire est conserve : liberer de la place puis
        // reprendre ne doit pas coûter un second transport complet.
        expect(bilan.octetsSurLeTelephone, greaterThan(0));
        expect(bilan.octetsSurLeTelephone, lessThan(c.contenu.length));
      });
    });

    group('deleteMbtiles', () {
      test('supprime la carte ET le fichier en cours', () async {
        final c = map(4096);
        final manager = MBTilesManager(httpClient: serveur(c.contenu));
        await manager.descendre(
          trailId: 'trail_del',
          url: 'https://example.com/t.mbtiles',
          octetsAttendus: c.contenu.length,
          empreinteAttendue: c.empreinte,
        );
        expect(await manager.hasMbtiles('trail_del'), isTrue);

        await File(
          await manager.cheminPartiel('trail_del'),
        ).writeAsBytes(Uint8List(10), flush: true);

        await manager.deleteMbtiles('trail_del');
        expect(await manager.hasMbtiles('trail_del'), isFalse);
        expect(
          File(await manager.cheminPartiel('trail_del')).existsSync(),
          isFalse,
        );
      });

      test('ne leve pas d erreur si fichier absent', () async {
        final manager = MBTilesManager();
        await manager.deleteMbtiles('inexistant');
      });
    });

    group('hasMbtiles', () {
      test('retourne false si pas de fichier', () async {
        final manager = MBTilesManager();
        expect(await manager.hasMbtiles('aucun'), isFalse);
      });

      test('retourne FALSE sur une descente seulement commencee', () async {
        final manager = MBTilesManager();
        await File(
          await manager.cheminPartiel('en_cours'),
        ).writeAsBytes(Uint8List(1000), flush: true);

        // C EST LA GARDE QUI EMPECHE LA CARTE D OUVRIR UNE BASE TRONQUEE.
        expect(await manager.hasMbtiles('en_cours'), isFalse);
        expect(await manager.listDownloaded(), isEmpty);
        expect(await manager.octetsDejaDescendus('en_cours'), 1000);
      });

      test('retourne true apres telechargement', () async {
        final c = map(8);
        final manager = MBTilesManager(httpClient: serveur(c.contenu));

        await manager.descendre(
          trailId: 'existe',
          url: 'https://example.com/x.mbtiles',
          octetsAttendus: c.contenu.length,
          empreinteAttendue: c.empreinte,
        );
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
        final c = map(4096);
        final manager = MBTilesManager(httpClient: serveur(c.contenu));

        for (final id in ['sentier_a', 'sentier_b']) {
          await manager.descendre(
            trailId: id,
            url: 'https://example.com/$id.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
          );
        }

        final list = await manager.listDownloaded();
        expect(list, containsAll(['sentier_a', 'sentier_b']));
        expect(list.length, 2);
      });

      test('ne liste plus un sentier supprime', () async {
        final c = map(4096);
        final manager = MBTilesManager(httpClient: serveur(c.contenu));

        for (final id in ['sentier_c', 'sentier_d']) {
          await manager.descendre(
            trailId: id,
            url: 'https://example.com/$id.mbtiles',
            octetsAttendus: c.contenu.length,
            empreinteAttendue: c.empreinte,
          );
        }
        await manager.deleteMbtiles('sentier_c');

        final list = await manager.listDownloaded();
        expect(list, contains('sentier_d'));
        expect(list, isNot(contains('sentier_c')));
      });
    });
  });
}
