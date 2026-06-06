import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/feature_flags.dart';
import 'package:moteur_gr/features/goodies/domain/models/goodie_product.dart';
import 'package:moteur_gr/features/goodies/domain/models/goodie_order.dart';
import 'package:moteur_gr/features/goodies/domain/models/personalization_data.dart';

/// Tests E3.14a : modeles goodies Freezed + feature flag OFF par defaut.
void main() {
  group('FeatureFlags.isGoodiesEnabled', () {
    setUp(() {
      FeatureFlags.clearOverrides();
    });

    test('retourne false par defaut pour tout sentier', () {
      expect(FeatureFlags.isGoodiesEnabled('sentier-bleu'), false);
      expect(FeatureFlags.isGoodiesEnabled('gr10'), false);
      expect(FeatureFlags.isGoodiesEnabled('tmb'), false);
    });

    test('retourne true apres activation explicite', () {
      FeatureFlags.setOverride('goodies', 'sentier-bleu', enabled: true);
      expect(FeatureFlags.isGoodiesEnabled('sentier-bleu'), true);
      // Les autres sentiers restent OFF
      expect(FeatureFlags.isGoodiesEnabled('gr10'), false);
    });

    test('clearOverrides remet tout a false', () {
      FeatureFlags.setOverride('goodies', 'sentier-bleu', enabled: true);
      FeatureFlags.clearOverrides();
      expect(FeatureFlags.isGoodiesEnabled('sentier-bleu'), false);
    });
  });

  group('GoodieProduct serialization roundtrip', () {
    test('toJson -> fromJson preserve tous les champs', () {
      const product = GoodieProduct(
        id: 'tshirt-bleu-001',
        name: 'tshirt_bleu_finisher',
        description: 'tshirt_bleu_finisher_desc',
        type: 'tshirt',
        price: 2990,
        image: 'assets/goodies/tshirt_bleu.png',
        personalizable: true,
        trailSpecific: true,
      );

      final jsonMap = product.toJson();
      final jsonString = json.encode(jsonMap);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final restored = GoodieProduct.fromJson(decoded);

      expect(restored.id, 'tshirt-bleu-001');
      expect(restored.name, 'tshirt_bleu_finisher');
      expect(restored.description, 'tshirt_bleu_finisher_desc');
      expect(restored.type, 'tshirt');
      expect(restored.price, 2990);
      expect(restored.image, 'assets/goodies/tshirt_bleu.png');
      expect(restored.personalizable, true);
      expect(restored.trailSpecific, true);
    });

    test('valeurs par defaut correctes', () {
      const product = GoodieProduct(
        id: 'patch-001',
        name: 'patch_generic',
        type: 'patch',
        price: 590,
      );

      expect(product.description, '');
      expect(product.image, isNull);
      expect(product.personalizable, false);
      expect(product.trailSpecific, false);
    });
  });

  group('GoodieOrder serialization roundtrip', () {
    test('toJson -> fromJson preserve tous les champs', () {
      final now = DateTime(2026, 6, 1, 10, 30);
      final order = GoodieOrder(
        id: 'order-001',
        productId: 'tshirt-bleu-001',
        trailId: 'sentier-bleu',
        quantity: 2,
        totalPrice: 5980,
        status: 'confirmed',
        createdAt: now,
        updatedAt: now,
      );

      final jsonMap = order.toJson();
      final jsonString = json.encode(jsonMap);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final restored = GoodieOrder.fromJson(decoded);

      expect(restored.id, 'order-001');
      expect(restored.productId, 'tshirt-bleu-001');
      expect(restored.trailId, 'sentier-bleu');
      expect(restored.quantity, 2);
      expect(restored.totalPrice, 5980);
      expect(restored.status, 'confirmed');
      expect(restored.createdAt, now);
      expect(restored.updatedAt, now);
    });

    test('valeurs par defaut correctes', () {
      final order = GoodieOrder(
        id: 'order-002',
        productId: 'mug-001',
        trailId: 'gr10',
        totalPrice: 1490,
        createdAt: DateTime(2026, 6, 1),
      );

      expect(order.quantity, 1);
      expect(order.status, 'pending');
      expect(order.updatedAt, isNull);
    });
  });

  group('PersonalizationData serialization roundtrip', () {
    test('toJson -> fromJson preserve tous les champs', () {
      const data = PersonalizationData(
        id: 'perso-001',
        orderId: 'order-001',
        customName: 'Christophe',
        trekDate: 'Juin 2026',
        stageName: 'Vizzavona',
        freeText: 'Mon premier grand sentier',
        customImagePath: '/photos/summit.jpg',
      );

      final jsonMap = data.toJson();
      final jsonString = json.encode(jsonMap);
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      final restored = PersonalizationData.fromJson(decoded);

      expect(restored.id, 'perso-001');
      expect(restored.orderId, 'order-001');
      expect(restored.customName, 'Christophe');
      expect(restored.trekDate, 'Juin 2026');
      expect(restored.stageName, 'Vizzavona');
      expect(restored.freeText, 'Mon premier grand sentier');
      expect(restored.customImagePath, '/photos/summit.jpg');
    });

    test('champs optionnels null par defaut', () {
      const data = PersonalizationData(
        id: 'perso-002',
        orderId: 'order-002',
      );

      expect(data.customName, isNull);
      expect(data.trekDate, isNull);
      expect(data.stageName, isNull);
      expect(data.freeText, isNull);
      expect(data.customImagePath, isNull);
    });
  });
}
