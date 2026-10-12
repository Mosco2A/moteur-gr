// TACHE 838, VOLET D2 — L'INTERSTITIEL EST-IL VRAIMENT BRANCHE ?
//
// POURQUOI CE FICHIER EXISTE A COTE DE CELUI DE LA CADENCE. Une regle juste et
// testee ne sert a rien si personne ne l'appelle : c'est exactement l'etat dans
// lequel ce lot a trouve l'interstitiel du depot — une mecanique complete,
// chargement et affichage compris, sans un seul appelant dans `lib/`. La tache
// 595 avait deja nomme cette forme pour la banniere : « un interrupteur sans
// ampoule ».
//
// CE FICHIER MESURE DONC LE FIL, PAS LA REGLE :
//   1. le porteur DEMANDE a chaque changement d'ecran, avec le BON chemin ;
//   2. il ne demande rien quand rien n'a change ;
//   3. il rend son enfant tel quel — il ne doit rien couter a l'arbre ;
//   4. et il est REELLEMENT POSE DANS `main.dart` (garde structurelle) : sans
//      cette derniere, les trois premieres mesureraient un widget que la
//      production n'utilise pas.
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/ads/presentation/porteur_d_interstitiel.dart';
import 'package:moteur_gr/features/ads/providers/interstitiel_providers.dart';

import '../../structurel/mesure_des_sources_645.dart';

/// CE QUI PREVIENT QU'ON A CHANGE D'ECRAN, pilote par le test.
///
/// En production c'est le delegue du routeur ; ici c'est un `Listenable` que le
/// test declenche quand il veut. C'est tout l'interet de l'injection : faire
/// arriver le randonneur ou l'on veut, sans monter un routeur.
class _Navigation extends ChangeNotifier {
  void aChange() => notifyListeners();
}

/// L'ESPION : il note ce qu'on lui demande, et ne montre jamais rien.
///
/// IL ECRIT DANS UNE LISTE QUI NE LUI APPARTIENT PAS, et c'est deliberé : la
/// surcharge d'un provider Riverpod est PARESSEUSE — l'espion n'est construit
/// qu'au premier `read`, c'est-a-dire a la premiere navigation. Une liste
/// portee par l'espion serait donc illisible avant elle, et le test ne pourrait
/// pas affirmer « rien n'a encore ete demande ». La liste vit donc dans le
/// test, et l'espion ne fait qu'y ajouter.
class _Espion extends Interstitiel {
  _Espion(super.ref, this.demandes);

  final List<String> demandes;

  @override
  Future<bool> siLHeureEstVenue(String chemin) async {
    demandes.add(chemin);
    return false;
  }
}

void main() {
  late List<String> demandes;

  setUp(() => demandes = <String>[]);

  /// Monte le porteur avec l'espion en place.
  ///
  /// `List<Override>` vient de `flutter_riverpod/misc.dart` : l'export
  /// principal de Riverpod 3.3.2 ne porte pas ce type.
  Future<_Navigation> monter(
    WidgetTester tester, {
    required String Function() chemin,
  }) async {
    final navigation = _Navigation();
    addTearDown(navigation.dispose);
    final overrides = <Override>[
      interstitielProvider.overrideWith((ref) => _Espion(ref, demandes)),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PorteurDInterstitiel(
            navigation: navigation,
            chemin: chemin,
            child: const Text('ECRAN'),
          ),
        ),
      ),
    );
    return navigation;
  }

  group('838 D2 — le porteur demande a chaque changement d ecran', () {
    testWidgets('un changement d ecran = une demande, avec le bon chemin', (
      tester,
    ) async {
      var chemin = '/home';
      final navigation = await monter(tester, chemin: () => chemin);

      expect(
        demandes,
        isEmpty,
        reason: 'au montage, rien n a encore change d ecran',
      );

      chemin = '/catalog';
      navigation.aChange();
      // DEUX TOURS DE POMPE, ET C'EST LA FORME DU CORRECTIF QU'ON MESURE. Le
      // porteur ne demande rien PENDANT la frame : il attend qu'elle soit
      // passee (`addPostFrameCallback`), pour ne pas demander un rendu en
      // pleine phase de rendu. Le premier tour produit la frame, le second
      // laisse partir ce qu'elle a mis en file.
      await tester.pump();
      await tester.pump();

      expect(
        demandes,
        ['/catalog'],
        reason:
            'LE CHEMIN EST LU APRES LA NAVIGATION, PAS AVANT. Le routeur '
            'previent ses auditeurs puis met a jour sa configuration : une '
            'valeur capturee a la construction serait toujours celle de '
            'l ecran PRECEDENT, et l interstitiel se croirait ailleurs qu ou '
            'il est — y compris sur le chemin du secours',
      );
    });

    testWidgets('trois navigations, trois demandes', (tester) async {
      var chemin = '/home';
      final navigation = await monter(tester, chemin: () => chemin);

      for (final suivant in ['/catalog', '/my-treks', '/settings']) {
        chemin = suivant;
        navigation.aChange();
        await tester.pump();
        await tester.pump();
      }

      expect(demandes, ['/catalog', '/my-treks', '/settings']);
    });

    testWidgets('sans navigation, aucune demande', (tester) async {
      await monter(tester, chemin: () => '/home');
      await tester.pump(const Duration(hours: 2));

      expect(
        demandes,
        isEmpty,
        reason:
            'un interstitiel se decide a l ARRIVEE SUR UN ECRAN. Il ne doit '
            'pas pouvoir s ouvrir sur un ecran que le randonneur est en train '
            'de lire ou de remplir',
      );
    });

    testWidgets('le porteur rend son enfant tel quel', (tester) async {
      await monter(tester, chemin: () => '/home');

      expect(
        find.text('ECRAN'),
        findsOneWidget,
        reason:
            'hors cadence il est transparent : il n ajoute aucun noeud '
            'visible et ne deplace pas un pixel',
      );
    });

    testWidgets('demonte, il ne demande plus rien', (tester) async {
      final navigation = await monter(tester, chemin: () => '/home');
      await tester.pumpWidget(const SizedBox.shrink());

      navigation.aChange();
      await tester.pump();

      expect(
        demandes,
        isEmpty,
        reason:
            'un auditeur laisse derriere soi est une fuite, et ici ce serait '
            'une publicite demandee par un widget qui n existe plus',
      );
    });
  });

  // ===========================================================================
  // LA GARDE DE L'AMPOULE — le porteur est-il pose dans l'application ?
  // ===========================================================================
  group('838 D2 — l interstitiel n est pas un interrupteur sans ampoule', () {
    test('le porteur est POSE dans main.dart', () {
      final main = lireSource('lib/main.dart');

      expect(
        main.contains('PorteurDInterstitiel('),
        isTrue,
        reason:
            'LE PORTEUR N EST PLUS DANS L ARBRE DE L APPLICATION. C est le '
            'defaut exact que ce lot est venu fermer : avant lui, le depot '
            'portait une mecanique interstitielle complete que RIEN n appelait '
            'dans lib/. Des tests verts sur la cadence ne prouveraient alors '
            'qu une chose — que la regle est juste dans un fichier que '
            'personne n execute.',
      );
    });

    test('il recoit bien les deux faits du routeur', () {
      final main = lireSource('lib/main.dart');

      expect(
        main.contains('navigation: appRouter.routerDelegate'),
        isTrue,
        reason:
            'sans ce `Listenable`, le porteur n est jamais prevenu qu on a '
            'change d ecran : il est dans l arbre et il ne sert a rien',
      );
      expect(
        main.contains('chemin: cheminAffiche'),
        isTrue,
        reason:
            'sans le chemin courant, la garde « jamais sur le chemin du '
            'secours » ne peut pas s appliquer — elle ne saurait pas ou l on '
            'se trouve',
      );
    });
  });
}
