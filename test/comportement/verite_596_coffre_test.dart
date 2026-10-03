// LOT 596 (C2) — LE CODE DE RECONNEXION PROMET UN COFFRE JAMAIS REMPLI.
//
// L'ecran dit au randonneur, mot pour mot : « Ce code ouvre votre coffre
// (profil, fiche de renseignement et solde d'etapes) sur un autre telephone ».
// Et l'onboarding le pousse a le noter. Or LE COFFRE N'A JAMAIS ETE ALIMENTE :
//
//   * `AccountVaultService.exportWithCode` — AUCUN appelant en production ;
//   * `CloudSyncService.pushEncryptedBackup` — AUCUN appelant en production ;
//   * `VaultEnvelope.serialize()` — sa sortie n'est ecrite NULLE PART ;
//   * aucun ecran ne permet de SAISIR un code pour restaurer.
//
// TACHE 612 — UN QUATRIEME CHEMIN MORT FIGURAIT ICI ET IL N'EST PLUS MORT, IL
// EST SUPPRIME : `HealthBackupService.backupToCloud`, qui chiffrait la fiche
// medicale avec une clef derivee du code de reconnexion. Decision de Christophe
// du 28/09 10:42 : les donnees medicales ne sortent jamais du telephone. La
// fiche medicale ne fait donc plus partie du coffre, ni vide ni rempli, et le
// compte ci-dessous ne la cherche plus. Ce que le coffre contiendra le jour ou
// il sera alimente : le pseudonyme, l'avatar et le solde d'etapes. Rien de
// medical.
//
// Le code que le randonneur note est la cle d'un coffre vide. Pire : l'ecran
// l'affichait en le FABRIQUANT au passage (`getOrCreate`), donc en posant dans
// le coffre-fort du telephone un secret qui n'ouvre rien.
//
// MEME REGLE QUE LE RESTE DU LOT : ou la promesse est tenue, ou elle est
// retiree. Elle ne peut pas etre tenue en V1 — il n'existe aucun transport (pas
// de projet Firebase) ni aucun ecran de saisie. Elle est donc RETIREE, et
// l'etat reel est DECLARE a un seul endroit, verifie par une invariante.
//
// PERIMETRE RGPD DES LOTS J A O — INTOUCHE, ET VERIFIE ICI : l'effacement prime
// sur toute restauration, et sa garde passe DEVANT celle du consentement
// article 9 (un consentement se re-accorde, un effacement non). On ne contourne
// rien en remplissant le coffre : on ne le remplit pas.
//
// TESTS ECRITS ROUGES AVANT CORRECTION.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/coffre_de_reconnexion.dart';
import 'package:moteur_gr/features/settings/presentation/recovery_code_screen.dart';
import 'package:moteur_gr/i18n/translations.g.dart';

import '../structurel/parcours_reel.dart';

/// Lit tous les .dart de production.
List<File> _sourcesDeProduction() => Directory('lib')
    .listSync(recursive: true)
    .whereType<File>()
    .where((f) => f.path.endsWith('.dart'))
    .toList();

/// Compte les appels de [methode] hors des fichiers de la chaine du coffre.
///
/// Les fichiers exclus sont ceux qui s'appellent ENTRE EUX sans que personne ne
/// les appelle : `backupToCloud` appelle bien `exportWithCode`, mais
/// `backupToCloud` lui-meme n'a aucun appelant. Une chaine morte reste morte,
/// quelle que soit sa longueur — seul un appel venu du RESTE de l'appli
/// alimente reellement le coffre.
int _appelantsHorsChaine(String methode) {
  const chaineDuCoffre = [
    'features/auth/data/account_vault_service.dart',
    'core/services/cloud_sync_service.dart',
    'core/services/secure_vault_service.dart',
  ];
  var appels = 0;
  for (final f in _sourcesDeProduction()) {
    final chemin = f.path.replaceAll(r'\', '/');
    if (chaineDuCoffre.any(chemin.endsWith)) continue;
    if (f.readAsStringSync().contains('$methode(')) appels++;
  }
  return appels;
}

/// Textes francais attendus a l'ecran (l'appli reelle demarre en fr).
final _tr = AppLocale.fr.buildSync();

void main() {
  group('LOT 596 C2 — l etat du coffre est DECLARE, et la declaration est '
      'verifiee sur le code', () {
    test('aujourd hui le coffre n est pas alimente', () {
      expect(
        ReconnectionVault.alimente,
        isFalse,
        reason:
            'si quelqu un a branche un ecrivain, il doit basculer cette '
            'declaration — et l invariante ci-dessous l y oblige',
      );
    });

    test('INVARIANTE : « alimente » et le code reel disent la MEME chose', () {
      // `backupToCloud` ne figure plus dans ce compte : la methode n'existe
      // plus (tache 612). La chercher aurait donne un zero rassurant qui ne
      // mesurait rien.
      final ecrivains =
          _appelantsHorsChaine('exportWithCode') +
          _appelantsHorsChaine('pushEncryptedBackup');

      if (ReconnectionVault.alimente) {
        expect(
          ecrivains,
          greaterThan(0),
          reason:
              'le coffre est declare alimente mais AUCUN code de '
              'production n y ecrit : la promesse serait de nouveau creuse',
        );
      } else {
        expect(
          ecrivains,
          0,
          reason:
              'du code alimente desormais le coffre : basculez '
              'ReconnectionVault.alimente a vrai et retablissez la '
              'promesse a l ecran',
        );
      }
    });

    test(
      'la declaration NOMME ce qui manque, pour que ce soit actionnable',
      () {
        expect(ReconnectionVault.ecrivainAttendu, isNotEmpty);
        expect(ReconnectionVault.transportAttendu, isNotEmpty);
        expect(ReconnectionVault.ecranDeSaisieAttendu, isNotEmpty);
      },
    );
  });

  group('LOT 596 C2 — l ecran ne promet plus un coffre vide', () {
    testWidgets(
      '/recovery-code — l ecran DIT qu il n y a rien a rouvrir, et ne '
      'promet plus',
      (tester) async {
        // L'APPLICATION REELLE, par sa vraie route (socle du LOT V) : un test
        // qui instancie l'ecran ne prouverait pas qu'on peut y arriver.
        await monterAppliReelle(tester, depart: '/recovery-code');

        expect(
          find.byType(RecoveryCodeScreen),
          findsOneWidget,
          reason:
              'la porte du LOT Q doit rester : on retire la promesse, '
              'pas l ecran',
        );

        final textes = textesVisibles(tester);
        expect(
          textes,
          contains(_tr.recovery.noVaultTitle),
          reason: 'l ecran doit dire l etat reel au lieu de promettre',
        );
        expect(
          textes,
          isNot(contains(_tr.recovery.intro)),
          reason:
              'la promesse « ce code ouvre votre coffre sur un autre '
              'telephone » ne doit plus etre affichee : elle est fausse',
        );
        expect(
          textes,
          isNot(contains(_tr.recovery.warning)),
          reason: 'inutile d avertir sur la perte d un code qui n ouvre rien',
        );

        await demonterAppli(tester);
        erreursDeRendu(tester);
      },
    );

    testWidgets(
      '/recovery-code — AUCUN code de 4x4 n est affiche ni fabrique',
      (tester) async {
        await monterAppliReelle(tester, depart: '/recovery-code');

        // Le code a la forme XXXX-XXXX-XXXX-XXXX. Aucun texte a l'ecran ne doit
        // y ressembler : l'ecran le FABRIQUAIT (getOrCreate) rien qu'en
        // s'affichant, posant dans le coffre-fort du telephone un secret qui
        // n'ouvre rien — et qu'il faudrait ensuite effacer avec les autres.
        final motif = RegExp(r'^[A-Z0-9]{4}(-[A-Z0-9]{4}){3}$');
        final codes = textesVisibles(tester).where(motif.hasMatch).toList();
        expect(
          codes,
          isEmpty,
          reason:
              'un code de reconnexion est affiche alors qu il n ouvre '
              'rien : ${codes.join(", ")}',
        );

        await demonterAppli(tester);
        erreursDeRendu(tester);
      },
    );
  });
}
