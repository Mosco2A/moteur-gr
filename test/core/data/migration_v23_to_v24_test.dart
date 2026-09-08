import 'dart:io';

// `hide` : drift exporte des matchers de requete `isNull`/`isNotNull` qui
// entrent en collision avec ceux de `flutter_test` (matcher). On masque ceux de
// drift ; le test n'utilise de drift que `Value` (pour les companions).
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';

/// Tests de MIGRATION Drift v23 -> v24 (StepWays LOT 1, socle wallet).
///
/// La v24 est STRICTEMENT ADDITIVE : elle cree 3 nouvelles tables via
/// `createTable` (`wallet_balance`, `trek_entitlements`, `no_ads_state`) et ne
/// touche a AUCUNE table ni colonne existante. On verifie ici la migration
/// REELLE (pas seulement le schema final) :
///   1. la version du schema a bien ete portee a 24 ;
///   2. en partant d'une base v23 (avec des donnees), la migration cree les 3
///      tables wallet ;
///   3. aucune perte : la donnee metier preexistante (une etape `stages`)
///      survit intacte a la migration ;
///   4. les 3 nouvelles tables sont utilisables (DAOs upsert/get) et portent
///      les valeurs par defaut attendues.
///
/// Methode : la migration Drift ne s'execute que lorsqu'une base persistee est
/// ouverte a une version INFERIEURE au `schemaVersion` courant. On simule donc
/// une base v23 sur un fichier temporaire (schema complet cree par Drift, puis
/// tables v24 supprimees + `user_version` ramene a 23), on y insere une etape,
/// on ferme, puis on rouvre : Drift detecte 23 < 24 et joue `onUpgrade`.
void main() {
  group('Drift migration v23 -> v24 (socle wallet StepWays)', () {
    test('la version du schema est au moins 24 (introduction des tables wallet)',
        () {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      // Les tables sont introduites en v24 ; le schema peut continuer d'evoluer.
      // On verifie le seuil d'introduction, sans figer une version exacte qui
      // casserait a chaque migration ulterieure.
      expect(db.schemaVersion, greaterThanOrEqualTo(24));
    });

    test(
        'migration reelle 23 -> 24 : cree les 3 tables wallet et preserve les '
        'donnees existantes', () async {
      final dir = await Directory.systemTemp.createTemp('gr_mig_v24_');
      addTearDown(() async {
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      });
      final file = File('${dir.path}/app.sqlite');

      // --- 1. Fabrique une base "v23" persistee -----------------------------
      // Drift cree le schema complet (courant), puis on retire les 3 tables
      // v24 et on ramene la version utilisateur a 23 pour rejouer la migration.
      final seedDb = AppDatabase(NativeDatabase(file));
      // Force la creation effective du schema (open paresseux).
      await seedDb.customStatement('SELECT 1');

      // Insere une etape AVANT migration (donnee metier a preserver).
      await seedDb.customStatement(
        "INSERT INTO stages (trail_id, stage_number, name, distance_km, "
        "elevation_gain_m, elevation_loss_m, start_lat, start_lng, end_lat, "
        "end_lng) VALUES ('gr20', 1, 'Calenzana - Ortu di u Piobbu', 10.5, "
        "1350, 100, 42.5, 8.85, 42.42, 8.9)",
      );

      // Retire les tables v24 et rembobine la version -> etat "v23".
      await seedDb.customStatement('DROP TABLE IF EXISTS no_ads_state');
      await seedDb.customStatement('DROP TABLE IF EXISTS trek_entitlements');
      await seedDb.customStatement('DROP TABLE IF EXISTS wallet_balance');
      await seedDb.customStatement('PRAGMA user_version = 23');
      await seedDb.close();

      // --- 2. Rouvre : Drift voit 23 < 24 -> joue onUpgrade -----------------
      final db = AppDatabase(NativeDatabase(file));
      addTearDown(db.close);

      // Les 3 tables wallet ont ete creees par la migration.
      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
          )
          .get();
      final tableNames = tables.map((r) => r.read<String>('name')).toList();

      expect(tableNames, contains('wallet_balance'),
          reason: 'Table wallet_balance creee en migration v24');
      expect(tableNames, contains('trek_entitlements'),
          reason: 'Table trek_entitlements creee en migration v24');
      expect(tableNames, contains('no_ads_state'),
          reason: 'Table no_ads_state creee en migration v24');

      // --- 3. Aucune perte : l'etape preexistante est intacte ---------------
      final stagesRows =
          await db.customSelect('SELECT * FROM stages').get();
      expect(stagesRows, hasLength(1),
          reason: 'La donnee metier v23 survit a la migration');
      expect(stagesRows.first.read<String>('trail_id'), 'gr20');
      expect(stagesRows.first.read<String>('name'),
          'Calenzana - Ortu di u Piobbu');
      expect(stagesRows.first.read<double>('distance_km'), 10.5);

      // La version a bien ete portee a la version courante (>= 24).
      final userVersion = await db
          .customSelect('PRAGMA user_version')
          .map((r) => r.read<int>('user_version'))
          .getSingle();
      expect(userVersion, greaterThanOrEqualTo(24));
    });

    test('les 3 nouvelles tables sont utilisables (DAOs + valeurs par defaut)',
        () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      // WalletBalance : upsert minimal -> defauts (0) appliques.
      await db.walletDao.upsert(
        WalletBalanceCompanion.insert(
          userId: 'user-hash-abc',
          updatedAt: DateTime(2026, 9, 8),
        ),
      );
      final wallet = await db.walletDao.getByUserId('user-hash-abc');
      expect(wallet, isNotNull);
      expect(wallet!.balanceSteps, 0);
      expect(wallet.lifetimeEarnedSteps, 0);
      expect(wallet.lifetimeSpentSteps, 0);

      // TrekEntitlements : upsert minimal -> owned=false, source='none'.
      await db.trekEntitlementsDao.upsert(
        TrekEntitlementsCompanion.insert(
          trailId: 'gr20',
          updatedAt: DateTime(2026, 9, 8),
        ),
      );
      final ent = await db.trekEntitlementsDao.getByTrailId('gr20');
      expect(ent, isNotNull);
      expect(ent!.owned, isFalse);
      expect(ent.acquiredStages, 0);
      expect(ent.totalStages, 0);
      expect(ent.consumedComplementSteps, 0);
      expect(ent.purchaseSource, 'none');
      expect(ent.purchasedAt, isNull);

      // NoAdsState : insert d'une source reward (scope 'global' par defaut).
      final startedAt = DateTime(2026, 9, 8, 12);
      await db.noAdsDao.insertState(
        NoAdsStateCompanion.insert(
          source: 'reward',
          startedAt: startedAt,
          updatedAt: startedAt,
          expiresAt: Value(startedAt.add(const Duration(hours: 24))),
        ),
      );
      final all = await db.noAdsDao.getAll();
      expect(all, hasLength(1));
      expect(all.first.source, 'reward');
      expect(all.first.scope, 'global');
      expect(all.first.expiresAt, startedAt.add(const Duration(hours: 24)));
    });
  });
}
