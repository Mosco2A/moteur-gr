import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/packs/data/pack_download_service.dart';
import 'package:moteur_gr/features/packs/data/pack_storage.dart';
import 'package:moteur_gr/features/packs/domain/pack_catalog.dart';
import 'package:moteur_gr/features/packs/domain/sentier_pack.dart';
import 'package:moteur_gr/features/packs/presentation/pack_card.dart';
import 'package:moteur_gr/features/packs/presentation/pack_store_screen.dart';
import 'package:moteur_gr/features/packs/providers/pack_providers.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

/// Stockage en memoire pour piloter l'etat telecharge dans les tests UI.
class _MemStorage implements PackStorage {
  final Map<String, Map<String, Uint8List>> _packs = {};

  void seedPack(String packId, List<String> refs) {
    _packs[packId] = {
      for (final r in refs) r: Uint8List.fromList(utf8.encode('x'))
    };
  }

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
  Future<int> packSizeBytes(String packId) async =>
      (_packs[packId]?.values.fold<int>(0, (s, b) => s + b.length)) ?? 0;

  @override
  Future<bool> packExists(String packId) async =>
      (_packs[packId]?.isNotEmpty) ?? false;

  @override
  Future<int> deletePack(String packId) async {
    final freed = await packSizeBytes(packId);
    _packs.remove(packId);
    return freed;
  }
}

/// Source de fichiers qui sert un contenu deterministe (telechargement OK).
class _OkSource implements PackFileSource {
  @override
  Future<Uint8List> fetch(String ref) async =>
      Uint8List.fromList(utf8.encode('CONTENT::$ref'));
}

/// Source controlable : chaque fetch attend tant que la grille est fermee.
class _GatedSource implements PackFileSource {
  final List<Completer<void>> _gates = [];
  bool _open = false;

  /// Ouvre la grille DEFINITIVEMENT : les fetch en attente ET futurs passent.
  void releaseAll() {
    _open = true;
    for (final c in _gates) {
      if (!c.isCompleted) c.complete();
    }
  }

  @override
  Future<Uint8List> fetch(String ref) async {
    if (!_open) {
      final gate = Completer<void>();
      _gates.add(gate);
      await gate.future;
    }
    return Uint8List.fromList(utf8.encode('CONTENT::$ref'));
  }
}

void main() {
  const trailId = 'mare_a_mare_centre';

  late _MemStorage storage;

  setUp(() {
    storage = _MemStorage();
  });

  // Riverpod 3 interdit desormais d'overrider deux fois le meme provider dans
  // un meme container (assertion "override a provider twice"). La source de
  // fichiers est donc parametrable ici (defaut _OkSource) plutot que d'etre
  // re-overridee par-dessus via `overrides` cote appelant. Zero changement de
  // comportement : la source effective reste celle voulue par le test.
  Widget wrap(
    Widget child, {
    List<Override> overrides = const [],
    PackFileSource? source,
  }) {
    return ProviderScope(
      overrides: [
        packStorageProvider.overrideWithValue(storage),
        packFileSourceProvider.overrideWithValue(source ?? _OkSource()),
        ...overrides,
      ],
      child: TranslationProvider(
        child: MaterialApp(home: child),
      ),
    );
  }

  // Variante avec Scaffold ancetre (pour les SnackBar de PackCard).
  Widget wrapCard(
    Widget child, {
    List<Override> overrides = const [],
    PackFileSource? source,
  }) {
    return ProviderScope(
      overrides: [
        packStorageProvider.overrideWithValue(storage),
        packFileSourceProvider.overrideWithValue(source ?? _OkSource()),
        ...overrides,
      ],
      child: TranslationProvider(
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    );
  }

  group('PackStoreScreen — liste a la carte (R2)', () {
    testWidgets('affiche 4 cartes Nord/Sud/Complet/MaM + note a la carte',
        (tester) async {
      await tester.pumpWidget(wrap(const PackStoreScreen(trailId: trailId)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pack-store-list')), findsOneWidget);
      // Bandeau « a la carte » (anti-abo) present.
      expect(find.byKey(const ValueKey('pack-alacarte-note')), findsOneWidget);

      // 4 packs distincts (pas un tout-abo) — scroll pour atteindre chacun.
      final scrollable = find.descendant(
        of: find.byKey(const ValueKey('pack-store-list')),
        matching: find.byType(Scrollable),
      );
      for (final type in PackCatalog.aLaCarteTypes) {
        final id = PackCatalog.packId(trailId, type);
        await tester.scrollUntilVisible(
          find.byKey(ValueKey('pack-card-$id')),
          200,
          scrollable: scrollable,
        );
        expect(find.byKey(ValueKey('pack-card-$id')), findsOneWidget);
      }
    });

    testWidgets('affiche le titre, la taille et la description localisee',
        (tester) async {
      await tester.pumpWidget(wrap(const PackStoreScreen(trailId: trailId)));
      await tester.pumpAndSettle();

      final t = TranslationProvider.of(
              tester.element(find.byType(PackStoreScreen)))
          .translations;
      expect(find.text(t.packs.types.complet.nom), findsOneWidget);
      // Taille du pack complet (340 Mo dans le catalogue fictif).
      final completManifest =
          PackCatalog.manifestFor(trailId, PackType.complet);
      expect(find.text(t.packs.size(mo: completManifest.tailleMo)),
          findsOneWidget);
    });

    testWidgets('aucun bouton acheter tant que la monetisation est OFF (R2)',
        (tester) async {
      await tester.pumpWidget(wrap(const PackStoreScreen(trailId: trailId)));
      await tester.pumpAndSettle();

      // purchaseEnabled=false par defaut -> pas d'achat impose, pas d'abo.
      expect(find.byKey(ValueKey('pack-buy-${PackCatalog.packId(trailId, PackType.nord)}')),
          findsNothing);
    });
  });

  group('PackCard — etats (non telecharge / telecharge / maj)', () {
    SentierPack packFor(String type) => SentierPack(
          id: PackCatalog.packId(trailId, type),
          nom: 'Pack $type',
          trailId: trailId,
          type: type,
          description: 'desc',
        );

    testWidgets('etat non telecharge -> bouton telecharger', (tester) async {
      final pack = packFor(PackType.nord);
      await tester.pumpWidget(wrap(
        PackCard(
          pack: pack,
          manifest: PackCatalog.manifestFor(trailId, PackType.nord),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('pack-download-${pack.id}')), findsOneWidget);
      expect(find.byKey(ValueKey('pack-delete-${pack.id}')), findsNothing);
    });

    testWidgets('etat telecharge -> chip telecharge + bouton supprimer',
        (tester) async {
      final pack = packFor(PackType.sud);
      final manifest = PackCatalog.manifestFor(trailId, PackType.sud);
      storage.seedPack(pack.id, manifest.allRefs); // deja telecharge

      await tester.pumpWidget(wrap(PackCard(pack: pack, manifest: manifest)));
      await tester.pumpAndSettle();

      final t = TranslationProvider.of(tester.element(find.byType(PackCard)))
          .translations;
      expect(find.text(t.packs.states.downloaded), findsOneWidget);
      expect(find.byKey(ValueKey('pack-delete-${pack.id}')), findsOneWidget);
    });

    testWidgets('etat mise a jour dispo -> chip update + bouton mettre a jour',
        (tester) async {
      final pack = packFor(PackType.complet);
      final manifest = PackCatalog.manifestFor(trailId, PackType.complet);
      storage.seedPack(pack.id, manifest.allRefs);

      await tester.pumpWidget(wrap(
        PackCard(pack: pack, manifest: manifest, updateAvailable: true),
      ));
      await tester.pumpAndSettle();

      final t = TranslationProvider.of(tester.element(find.byType(PackCard)))
          .translations;
      expect(find.text(t.packs.states.updateAvailable), findsOneWidget);
      // Bouton present (libelle « mettre a jour ») et action telechargement dispo.
      expect(find.byKey(ValueKey('pack-download-${pack.id}')), findsOneWidget);
      expect(find.text(t.packs.actions.update), findsOneWidget);
    });
  });

  group('PackCard — telechargement (progression) + suppression', () {
    testWidgets('telechargement affiche la progression puis l etat telecharge',
        (tester) async {
      final pack = SentierPack(
        id: PackCatalog.packId(trailId, PackType.mam),
        nom: 'Pack mam',
        trailId: trailId,
        type: PackType.mam,
        description: 'desc',
      );
      final manifest = PackCatalog.manifestFor(trailId, PackType.mam);
      final gated = _GatedSource();

      await tester.pumpWidget(wrapCard(
        PackCard(pack: pack, manifest: manifest),
        source: gated,
      ));
      await tester.pumpAndSettle();

      // Lance le telechargement (fetch bloque sur la grille -> reste en cours).
      await tester.tap(find.byKey(ValueKey('pack-download-${pack.id}')));
      await tester.pump(); // 1re frame : statut downloading
      await tester.pump();

      // La barre de progression apparait pendant le telechargement.
      expect(find.byKey(const ValueKey('pack-progress-bar')), findsOneWidget);

      // Debloque tous les fetch -> le telechargement se termine.
      gated.releaseAll();
      await tester.pumpAndSettle();

      // Apres succes : chip telecharge + bouton supprimer.
      final t = TranslationProvider.of(tester.element(find.byType(PackCard)))
          .translations;
      expect(find.text(t.packs.states.downloaded), findsOneWidget);
      expect(find.byKey(ValueKey('pack-delete-${pack.id}')), findsOneWidget);
      // Le pack est reellement stocke (lisible offline).
      expect(await storage.packExists(pack.id), isTrue);
    });

    testWidgets('suppression via dialog retire le pack et libere l espace',
        (tester) async {
      final pack = SentierPack(
        id: PackCatalog.packId(trailId, PackType.nord),
        nom: 'Pack nord',
        trailId: trailId,
        type: PackType.nord,
        description: 'desc',
      );
      final manifest = PackCatalog.manifestFor(trailId, PackType.nord);
      storage.seedPack(pack.id, manifest.allRefs);

      await tester.pumpWidget(wrapCard(PackCard(pack: pack, manifest: manifest)));
      await tester.pumpAndSettle();

      // Ouvre le dialog de suppression.
      await tester.tap(find.byKey(ValueKey('pack-delete-${pack.id}')));
      await tester.pumpAndSettle();
      // Confirme.
      await tester.tap(find.byKey(const ValueKey('pack-delete-confirm')));
      await tester.pumpAndSettle();

      // Pack supprime du stockage.
      expect(await storage.packExists(pack.id), isFalse);
      // Bouton telecharger de nouveau propose (etat non telecharge).
      expect(find.byKey(ValueKey('pack-download-${pack.id}')), findsOneWidget);
    });
  });
}
