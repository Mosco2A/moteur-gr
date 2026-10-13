import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:moteur_gr/core/analytics/screen_breadcrumb.dart';
import 'package:moteur_gr/core/routing/app_router.dart';
import 'package:moteur_gr/features/booking/booking_facade.dart';

/// P3 (#101255 point 3, defaut #101094 point 3) — LA ROUTE `/booking` DORMANTE
/// EST RETIREE, ET LE DOMAINE `booking` RESTE ENTIER.
///
/// CE QUE LA ROUTE ETAIT. Une ebauche de l'etape E5.13 : un ecran qui disait
/// « reservez par les fiches etapes », derriere un drapeau
/// `FeatureFlags.isBookingEnabled` ferme par defaut et jamais ouvert pour aucun
/// sentier. AUCUNE porte de l'application n'y menait (le registre des routes
/// dormantes le disait : « Rien a montrer, donc rien a ouvrir »), aucune donnee
/// ne l'alimentait, aucun test ne la traversait. Prise de force par une URL,
/// elle redirigeait vers le catalogue — un chemin qui ne menait nulle part et
/// qui comptait pourtant comme un ecran dans la mesure d'observabilite.
///
/// POURQUOI ON LA RETIRE AU LIEU DE LA GARDER DORMANTE. Une route dormante est
/// une promesse en attente, et le depot en porte plusieurs qui attendent
/// vraiment quelque chose. Celle-ci n'attendait rien : ni service, ni donnee,
/// ni decision. La regle du code mort du lot 645-02 et le « propre et aux
/// normes » de Christophe disent la meme chose — ce qui n'existe pas ne
/// s'affiche pas, et ce que personne ne peut atteindre ne se garde pas.
///
/// CE QUE CETTE GARDE EMPECHE. Qu'elle revienne par recopie, et qu'on emporte
/// le domaine avec elle : `NuiteeType` est lu par le planning a travers la
/// facade de `booking`, et l'assistant « Nuitees » comme les hebergements
/// peripheriques restent atteignables. On retire un chemin mort, pas une
/// feature.
void main() {
  group('P3 — la route /booking n existe plus', () {
    test('aucune route racine ne porte le chemin /booking', () {
      final chemins = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();
      expect(chemins, isNotEmpty, reason: 'routeur non lu');
      expect(chemins, isNot(contains('/booking')));
    });

    test('aucune route racine ne porte le nom booking', () {
      final noms = appRouter.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.name)
          .toList();
      expect(noms, isNot(contains('booking')));
    });

    test('l ecran inatteignable n est plus dans le depot', () {
      expect(
        File(
          'lib/features/booking/presentation/booking_screen.dart',
        ).existsSync(),
        isFalse,
      );
    });

    test('plus aucune miette d observabilite ne nomme booking', () {
      // Les 62 ecrans portent 62 miettes (voir
      // `test/structurel/observabilite_des_ecrans_645_test.dart`) : celle de
      // l'ecran retire partirait sinon emettre le nom d'un ecran que personne
      // ne peut plus voir.
      expect(
        ScreenBreadcrumb.all.map((m) => m.name),
        isNot(contains('booking')),
      );
    });
  });

  group('P3 — le domaine booking, lui, est intact', () {
    test('la facade expose toujours NuiteeType, que le planning lit', () {
      expect(NuiteeType.values, isNotEmpty);
      // `NuiteeTypeUi` est l'habillage que la facade exporte avec lui.
      for (final type in NuiteeType.values) {
        expect(type.name, isNotEmpty);
      }
    });

    test('les ecrans vivants de booking sont toujours la', () {
      for (final chemin in [
        'lib/features/booking/presentation/nuitees_screen.dart',
        'lib/features/booking/presentation/hebergements_peripheriques_screen.dart',
        'lib/features/booking/domain/models/nuitee_type.dart',
      ]) {
        expect(
          File(chemin).existsSync(),
          isTrue,
          reason: '$chemin ne doit PAS partir avec la route dormante',
        );
      }
    });
  });
}
