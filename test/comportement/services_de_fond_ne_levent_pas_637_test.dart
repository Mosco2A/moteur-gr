// TACHE 637, VOLET 2 — UN SERVICE DE FOND NE PEUT PLUS EMPORTER L'ECRAN.
//
// CES DEUX MESURES SONT DANS LEUR PROPRE FICHIER, ET POUR UNE RAISON MESUREE :
// elles construisent de vrais providers (base locale, ordonnanceur), et l'etat
// qu'elles laissent derriere elles empechait le test de geste du meme fichier de
// monter le cockpit. `flutter test` isole les FICHIERS, pas les tests : deux
// fichiers, donc deux isolats, donc aucune contagion.
//
// CE QU'ELLES PROUVENT — la CAUSE de l'ecran noir de Christophe
// (DEM-260930-1103), prise a la source. Voir
// `mon_compte_menu_trek_637_test.dart` pour le recit complet et pour le geste.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/analytics/analytics_service.dart';
import 'package:moteur_gr/core/firebase/firebase_service.dart';
import 'package:moteur_gr/core/services/sync_scheduler.dart';
import 'package:moteur_gr/features/auth/providers/auth_provider.dart';
import 'package:moteur_gr/features/hub/presentation/hub_screen.dart';
import 'package:moteur_gr/features/safety/presentation/refus_sauvegarde_systeme_dialog.dart';

import '../structurel/parcours_reel.dart';

void main() {
  /// Les erreurs de rendu QUI COMPTENT.
  ///
  /// Deux exclusions, et toutes deux assumees :
  ///  * un debordement de texte n'est pas un ecran noir ;
  ///  * `FlutterBackgroundService` n'existe QUE sur Android et iOS. Demarrer un
  ///    trek reel sur la machine de test l'appelle forcement. C'est une limite de
  ///    l'environnement, pas un defaut — et c'est nomme ici plutot que tu.
  List<String> erreursQuiComptent(WidgetTester tester) => erreursDeRendu(tester)
      .where((e) => !estDebordement(e))
      .where((e) => !e.contains('FlutterBackgroundService'))
      .toList();

  group('637/2 — la cause : un service de fond ne peut plus lever', () {
    test('la MONTEE EN BASE ne leve plus quand l identite leve', () {
      // LA CAUSE EXACTE, PRISE A LA SOURCE. `authServiceProvider` construit
      // `FirebaseAuthService`, donc touche `FirebaseAuth.instance` : sur un
      // telephone dont les services Google Play sont absents ou trop vieux, cette
      // construction leve. Avant le correctif, la montee relevait, et
      // `BootstrapGate` avec elle.
      final conteneur = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith(
            (ref) => throw StateError('[core/no-app] No Firebase App'),
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      expect(
        () => conteneur.read(monteeEnBaseDemarreeProvider),
        returnsNormally,
        reason: 'une montee qui ne s arme pas coûte la montee, jamais l ecran',
      );
    });

    test('le JOURNAL des miettes ne leve plus, et retombe inerte', () {
      // LE TROU QUE LE VOLET 1 AVAIT OUVERT. `analyticsServiceProvider` construit
      // les puits Firebase, dont les constructeurs touchent
      // `FirebaseAnalytics.instance`. Il est lu sur le chemin de la question de
      // sauvegarde : il pouvait donc faire lever `poserSiNecessaire` depuis un
      // `addPostFrameCallback`, c'est-a-dire rejouer le plantage du volet 1.
      final conteneur = ProviderContainer(
        overrides: [
          firebaseServiceProvider.overrideWithValue(
            FirebaseService.testOnly(isAvailable: true),
          ),
        ],
      );
      addTearDown(conteneur.dispose);

      late final AnalyticsService service;
      expect(
        () => service = conteneur.read(analyticsServiceProvider),
        returnsNormally,
        reason: 'un traceur qui casse la trace est le defaut a ne pas revoir',
      );
      expect(
        service.isOperational,
        isFalse,
        reason: 'sans application native joignable, il retombe inerte',
      );
    });
  });

  group('637/2 — le filet : la garde qui enveloppe tout ne noircit plus', () {
    testWidgets('un armement de fond qui LEVE laisse l application vivre', (
      tester,
    ) async {
      // C'EST LE TEST QUI ETAIT ROUGE, et il vise la garantie STRUCTURELLE plutot
      // qu'un provider en particulier : on force l'un des cinq armements a lever,
      // tout le reste est reel. Avant le correctif, ce montage produisait
      //   « ProviderException … thrown building BootstrapGate(...) »
      // donc un `ErrorWidget` a la place de TOUTE l'application — le rectangle
      // noir de Christophe. Ce test protege aussi le prochain service qu'on
      // ajoutera a cette garde.
      RefusSauvegardeSystemeDialog.resetLock();
      await monterAppliReelle(
        tester,
        etat: EtatAppli.enRoute,
        avecEnveloppesDeMain: true,
        surcharges: [
          monteeEnBaseDemarreeProvider.overrideWith(
            (ref) => throw StateError('service de fond en panne'),
          ),
        ],
      );
      await allerA(tester, '/home');
      await stabiliser(tester, coups: 20);

      final cockpit = find.byType(HubScreen).evaluate().isNotEmpty;
      final erreurs = erreursQuiComptent(tester);
      await demonterAppli(tester);

      expect(
        erreurs.where((e) => e.contains('BootstrapGate')),
        isEmpty,
        reason:
            'ECRAN NOIR : une exception dans le build de la garde qui '
            'enveloppe tous les ecrans remplace l application entiere par un '
            'ErrorWidget — noir en release, et rejoue a chaque frame. '
            'Erreurs vues : $erreurs',
      );
      expect(
        cockpit,
        isTrue,
        reason:
            'ECRAN NOIR : l application doit se dessiner meme quand un '
            'service de fond ne peut pas s armer',
      );
    });
  });
}
