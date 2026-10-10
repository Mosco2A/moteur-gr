import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/auth/data/firebase_auth_service.dart';
import 'package:moteur_gr/features/auth/data/local_auth_service.dart';
import 'package:moteur_gr/features/auth/domain/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// L IDENTITE SE DIT A QUI ARRIVE EN RETARD (tache 781).
///
/// LE DEFAUT MESURE, LE 10/10 SUR emulator-5560 (recette 778). L ecran « Mon
/// compte » est mort par ses DEUX portes — l icone de la barre du haut du
/// cockpit et l action de la barre du bas de « Mes treks ». Il affiche « Le
/// compte n a pas repondu » apres huit secondes, et « Reessayer » repart pour
/// le meme resultat.
///
/// ET POURTANT LE COMPTE EXISTE, mesure dans la meme recette : un seul compte
/// anonyme est cree au lancement (acquis de la tache 771), sa fiche technique
/// part au serveur, et l ecran Reglages affiche « Services en ligne actifs »
/// avec un identifiant EXACTEMENT EGAL a celui cree chez Firebase. L identite
/// est la, le reseau marche. C est l ECRAN qui ne la voit pas.
///
/// LA CAUSE. `authStateChanges` etait rendu par un `StreamController.broadcast`
/// nu, et un flux de diffusion NE REJOUE RIEN a qui s abonne apres coup. Au
/// lancement, personne n ecoute encore : le provider d identite n est construit
/// que lorsqu un ecran le demande. L identite s etablit donc AVANT le premier
/// abonne, l evenement tombe dans le vide, et l abonnement tardif de l ecran
/// n obtient plus jamais rien. Le `loading` de `currentUserProvider` ne se
/// termine pas, et le garde-fou de la tache 649 finit par dire l attente.
///
/// POURQUOI « REESSAYER » NE POUVAIT PAS MARCHER. Il invalide
/// `currentUserProvider`, donc il se reabonne — au MEME flux sans rejeu, qui
/// n a toujours rien a redire. Le bouton etait condamne par la meme cause.
///
/// CE QUE CES GARDES EXIGENT. Un flux d IDENTITE n est pas un flux
/// d evenements : il porte un ETAT, et un etat se rend a tout nouvel abonne.
/// Les deux implementations de [AuthService] doivent donc tenir le meme
/// contrat, et aucune ne doit pour autant inventer un etat avant qu il existe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // `LocalAuthService` lit les preferences : sans ce mock, l appel part en
    // `MissingPluginException` hors de tout porteur d erreur (lecon 561).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('un abonne tardif recoit l identite deja etablie', () {
    test('chemin Firebase — celui qui a echoue sur emulator-5560', () async {
      final auth = _AuthFaux();
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();

      // LE LANCEMENT. L identite s etablit alors que PERSONNE n ecoute, comme
      // au demarrage reel : `auth_provider` tire `garantirUneIdentite()` en
      // fire-and-forget bien avant qu un ecran ne demande l identite.
      final etablie = await service.garantirUneIdentite();
      await pumpEventQueue();
      expect(etablie, isNotNull, reason: 'le compte doit etre ouvert');

      // L ECRAN S OUVRE MAINTENANT, et c est tout le defaut : il arrive apres.
      AuthUser? recu;
      var emissions = 0;
      final abonnement = service.authStateChanges.listen((user) {
        recu = user;
        emissions++;
      });
      await pumpEventQueue();

      expect(
        emissions,
        greaterThan(0),
        reason:
            'ROUGE AVANT LE CORRECTIF : le flux ne rejoue rien a l abonne '
            'tardif, donc l ecran reste en chargement pour toujours',
      );
      expect(recu, isNotNull, reason: 'l identite etablie doit etre rendue');
      expect(recu!.uid, equals(etablie!.uid), reason: 'et c est la MEME');

      await abonnement.cancel();
      await _refermer(service, auth);
    });

    test('chemin local — meme contrat, sans Firebase', () async {
      final service = LocalAuthService();
      final etablie = await service.signInAnonymously();
      await pumpEventQueue();

      AuthUser? recu;
      final abonnement = service.authStateChanges.listen((user) => recu = user);
      await pumpEventQueue();

      expect(
        recu,
        isNotNull,
        reason:
            'ROUGE AVANT LE CORRECTIF : le repli local souffrait du meme flux '
            'sans rejeu que le chemin Firebase',
      );
      expect(recu!.uid, equals(etablie.uid));

      await abonnement.cancel();
      service.dispose();
    });

    test('deux ecrans abonnes tard recoivent chacun l identite', () async {
      // LA DIFFUSION RESTE UNE DIFFUSION. Rejouer l etat courant ne doit pas
      // couter le droit d avoir plusieurs lecteurs : « Mon compte », les
      // Reglages et les gardes de navigation lisent la meme identite.
      final service = LocalAuthService();
      await service.signInAnonymously();
      await pumpEventQueue();

      AuthUser? premier;
      AuthUser? second;
      final a = service.authStateChanges.listen((u) => premier = u);
      final b = service.authStateChanges.listen((u) => second = u);
      await pumpEventQueue();

      expect(premier, isNotNull);
      expect(second, isNotNull);
      expect(premier!.uid, equals(second!.uid));

      await a.cancel();
      await b.cancel();
      service.dispose();
    });

    test('les changements suivants arrivent toujours', () async {
      // NON-REGRESSION DE L ACQUIS. Le rejeu de l etat courant ne remplace pas
      // la suite : un pseudo choisi doit continuer de remonter a l ecran.
      final service = LocalAuthService();
      await service.signInAnonymously();
      await pumpEventQueue();

      final vus = <AuthUser?>[];
      final abonnement = service.authStateChanges.listen(vus.add);
      await pumpEventQueue();

      await service.updateDisplayName('Christophe');
      await pumpEventQueue();

      expect(
        vus.length,
        greaterThanOrEqualTo(2),
        reason: 'etat courant, puis changement',
      );
      expect(vus.last!.displayName, equals('Christophe'));

      await abonnement.cancel();
      service.dispose();
    });
  });

  group('aucune identite inventee avant qu elle existe', () {
    test('tant que rien n est etabli, le flux ne dit rien', () async {
      // LE PIEGE DU CORRECTIF, ET IL EST SERIEUX. Rejouer « l utilisateur
      // courant » sans distinguer « pas encore d identite » de « deconnecte »
      // ferait emettre un `null` premature. `isAuthenticatedProvider`
      // basculerait a faux au premier lancement hors ligne, et les gardes de
      // navigation prendraient cette ignorance pour une deconnexion. Avant
      // qu une identite soit etablie, le flux doit se TAIRE — c est l attente
      // bornee de la tache 649 qui tient ce cas, pas une fausse reponse.
      final auth = _AuthFaux();
      final service = FirebaseAuthService(firebaseAuth: auth)..initialize();

      var emissions = 0;
      final abonnement = service.authStateChanges.listen((_) => emissions++);
      await pumpEventQueue();

      expect(
        emissions,
        isZero,
        reason: 'aucun etat connu : rien ne doit etre affirme',
      );

      await abonnement.cancel();
      await _refermer(service, auth);
    });
  });
}

/// REFERME SANS LAISSER D ERREUR ORPHELINE (lecon de la tache 561, J3). Une
/// emission qui retombe apres la fin du test serait imputee au test suivant.
Future<void> _refermer(FirebaseAuthService service, _AuthFaux auth) async {
  await pumpEventQueue();
  await auth.fermer();
  service.dispose();
}

// ===========================================================================
// LES DOUBLES. Ni `mockito` ni `firebase_auth_mocks` ne sont dans la pile, et
// on n en ajoute pas pour trois methodes : meme choix et meme forme qu aux
// taches 635 et 771 (`implements` + `noSuchMethod`).
// ===========================================================================

class _UtilisateurFaux implements fb.User {
  _UtilisateurFaux(this.uid);

  @override
  final String uid;

  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _IdentificationFausse implements fb.UserCredential {
  _IdentificationFausse(this.user);

  @override
  final fb.User? user;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// UN FAUX SDK D AUTHENTIFICATION QUI PREND DU TEMPS. Le defaut ne vit que
/// parce que l identite arrive AVANT l abonne : une connexion instantanee
/// reproduirait quand meme l ordre, mais ce delai le rend explicite.
class _AuthFaux implements fb.FirebaseAuth {
  final Duration delai = const Duration(milliseconds: 20);

  fb.User? _courant;
  final _flux = StreamController<fb.User?>.broadcast();

  Future<void> fermer() => _flux.close();

  @override
  fb.User? get currentUser => _courant;

  @override
  Stream<fb.User?> authStateChanges() => _flux.stream;

  @override
  Future<fb.UserCredential> signInAnonymously() async {
    await Future<void>.delayed(delai);
    final utilisateur = _UtilisateurFaux('compte-unique');
    _courant = utilisateur;
    if (!_flux.isClosed) _flux.add(utilisateur);
    return _IdentificationFausse(utilisateur);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
