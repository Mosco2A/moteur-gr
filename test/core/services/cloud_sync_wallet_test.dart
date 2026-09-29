import "dart:io";

import "package:flutter_test/flutter_test.dart";

/// LE COMPTE NE PEUT PLUS MONTER — GARDE STRUCTURELLE (tache 635).
///
/// CE QUE CE FICHIER PROUVAIT AVANT, ET POURQUOI IL A CHANGE DE SUJET. Il
/// verifiait que `syncWallet` poussait un miroir NON NOMINATIF du compte-etapes
/// (`users/{uid}/wallet/current`) et des droits de sentier
/// (`users/{uid}/entitlements/{trailId}`). Ces deux ecritures n existent plus,
/// et ce n est pas un abandon : c est la decision d architecture de Christophe
/// du 29/09 13:43, gravee dans les regles par la tache 631 — le COMPTE fait foi
/// AU SERVEUR, le telephone n en a qu une copie, et `firestore.rules` repond
/// `allow write: if false` sur wallet, entitlements et subscription.
///
/// `syncWallet` ne pouvait donc plus produire QUE des refus, et elle n avait
/// aucun appelant. Elle a ete retiree plutot que laissee dormir : du code mort
/// qui ment est pire que pas de code — le premier qui la rebrancherait croirait
/// monter un solde et ne recolterait que des permissions refusees, en silence.
///
/// CE QUE CE FICHIER PROUVE MAINTENANT : qu aucun chemin de montee du compte
/// n a ete rouvert, ni dans le service, ni dans les regles. Un test et pas un
/// commentaire — une methode se remet en place en trois lignes, et c est le
/// modele economique qui se paie.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final service = File("lib/core/services/cloud_sync_service.dart");

  group("635 — le service de montee ne sait plus ecrire le compte", () {
    test("le fichier du service existe (sinon la garde ne garde rien)", () {
      expect(service.existsSync(), isTrue);
    });

    /// Les DECLARATIONS de tout ce qui savait ecrire le compte. On cherche la
    /// signature, pas le mot : les commentaires de ce service expliquent
    /// longuement pourquoi le compte ne monte plus, et ils doivent pouvoir le
    /// dire sans faire echouer la garde.
    const declarations = [
      "Future<CloudSyncResult> syncWallet(",
      "Map<String, dynamic> buildWalletPayload(",
      "Map<String, dynamic> buildEntitlementPayload(",
    ];

    for (final signature in declarations) {
      test("« $signature » n est plus declaree", () {
        expect(
          service.readAsStringSync(),
          isNot(contains(signature)),
          reason:
              "cette methode ecrivait le compte, que les regles refusent "
              "desormais au telephone (tache 631). La rouvrir, c est offrir a "
              "n importe quel telephone de se poser owned:true sur un sentier "
              "payant.",
        );
      });
    }

    test("aucun chemin Firestore du compte n est emprunte par le service", () {
      final source = service.readAsStringSync();
      for (final chemin in const [
        'collection("wallet")',
        'collection("entitlements")',
        'collection("subscription")',
      ]) {
        expect(
          source,
          isNot(contains(chemin)),
          reason:
              "$chemin est un chemin d ECRITURE vers le compte : le "
              "telephone ne doit jamais l emprunter.",
        );
      }
    });
  });

  group(
    "635 — les regles Firestore refusent toujours l ecriture du compte",
    () {
      // Meme garde structurelle que celle de la tache 631, gardee ici parce que
      // c est le fichier du compte : si quelqu un retirait
      // `allow write: if false`, la suppression de `syncWallet` ne protegerait
      // plus rien a elle seule.
      final fichier = File("firestore.rules");

      String bloc(String chemin) {
        final source = fichier.readAsStringSync();
        final debut = source.indexOf("match $chemin");
        if (debut < 0) return "";
        final suivant = source.indexOf("match ", debut + 6);
        return suivant < 0
            ? source.substring(debut)
            : source.substring(debut, suivant);
      }

      for (final chemin in const [
        "/wallet/{docId}",
        "/entitlements/{trailId}",
        "/subscription/{docId}",
      ]) {
        test("$chemin : ecriture refusee a tout client", () {
          expect(fichier.existsSync(), isTrue);
          expect(bloc(chemin), contains("allow write: if false;"));
        });
      }
    },
  );
}
