// TACHE 561 (LOT J) — LE GARDE-FOU QUI REND L'OUBLI IMPOSSIBLE.
//
// Le defaut repare par le LOT J n'etait pas « une table manquante » : c'etait
// une LISTE RECOPIEE A LA MAIN, qu'on oublie fatalement de tenir a jour. Seize
// tables y figuraient, le schema en comptait trente-six, et parmi les absentes
// se trouvait `hiker_profile` — l'age, la taille et le poids, que l'application
// declare elle-meme au randonneur comme des donnees de sante (art. 9).
//
// Corriger la liste n'aurait rien empeche : la dix-septieme table aurait ete
// oubliee comme les huit precedentes. La liste des tables a effacer est donc
// DERIVEE du schema, et ce fichier exige que CHAQUE table du schema soit nommee
// dans exactement une categorie. Ajouter une table sans la classer fait tomber
// ce test — c'est ce qui remplace la bonne volonte du prochain developpeur.
//
// Ces tests ne lisent aucune donnee : ils portent sur la CLASSIFICATION.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/services/data_retention_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late DataRetentionService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues(<String, Object>{});
    service = DataRetentionService(
      database: db,
      prefs: await SharedPreferences.getInstance(),
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('classification des tables — exhaustive et disjointe', () {
    test('CHAQUE table du schema est classee', () {
      final schema = db.allTables.map((t) => t.actualTableName).toSet();
      final classified = <String>{
        ...DataRetentionService.referenceTableNames,
        ...DataRetentionService.retainedOnErasureTableNames,
        ...service.userTableNames,
      };

      expect(schema.difference(classified), isEmpty,
          reason: 'table du schema non classee : elle doit etre declaree '
              'REFERENCE, CONSERVEE avec sa raison, ou laissee au defaut '
              '(effacee)');
      expect(classified.difference(schema), isEmpty,
          reason: 'une categorie nomme une table absente du schema : faute de '
              'frappe, ou table supprimee sans nettoyer la liste');
    });

    test('les trois categories sont DISJOINTES', () {
      final user = service.userTableNames.toSet();
      expect(user.intersection(DataRetentionService.referenceTableNames),
          isEmpty);
      expect(
          user.intersection(
              DataRetentionService.retainedOnErasureTableNames),
          isEmpty);
      expect(
          DataRetentionService.referenceTableNames
              .intersection(DataRetentionService.retainedOnErasureTableNames),
          isEmpty);
    });

    test('une table NON classee tombe du cote EFFACE, pas du cote oublie', () {
      // Preuve arithmetique de la derivation : tout ce qui n'est pas une
      // exception explicite est efface. Le defaut protege la personne.
      expect(
        service.userTableNames.length,
        db.allTables.length -
            DataRetentionService.referenceTableNames.length -
            DataRetentionService.retainedOnErasureTableNames.length,
      );
    });

    test('les tables qui etaient OUBLIEES sont maintenant effacees', () {
      // Les huit absentes de la liste recopiee, nommement.
      for (final name in const <String>[
        'hiker_profile',
        'past_hike_entries',
        'hiker_experience_note',
        'trek_sessions',
        'nuitee_selections',
      ]) {
        expect(service.userTableNames, contains(name),
            reason: '$name portait de la donnee personnelle hors effacement');
      }
    });

    test('la donnee perso CONSERVEE est nommee, courte et justifiee', () {
      // Trois tables, et rien d'autre, ne survivent a l'effacement : l'etage
      // monetaire. La raison est ecrite dans le code a cote de la liste. Si
      // cette liste grandit, ce test le dit tout de suite.
      expect(DataRetentionService.retainedOnErasureTableNames, <String>{
        'wallet_balance',
        'trek_entitlements',
        'no_ads_state',
      });
    });
  });

  group('classification des cles de prefs', () {
    test('les cles conservees sont des REGLAGES, pas de la donnee perso', () {
      // Aucune cle conservee ne doit ressembler a de la donnee personnelle.
      for (final key in DataRetentionService.preservedPrefsKeys) {
        expect(key.startsWith('settings_'), isTrue,
            reason: '$key est conservee sans etre un reglage d affichage');
      }
    });

    test('aucune cle de consentement n est dans une liste de conservation', () {
      final retained = <String>{
        ...DataRetentionService.preservedPrefsKeys,
        ...DataRetentionService.retainedOnErasurePrefsKeys,
      };
      for (final key in retained) {
        expect(key.startsWith('consent_'), isFalse,
            reason: 'un consentement est un acte positif : il se re-demande '
                'apres un effacement, il ne survit pas');
      }
    });

    test('aucune cle de la fiche randonneur n est conservee', () {
      final retained = <String>{
        ...DataRetentionService.preservedPrefsKeys,
        ...DataRetentionService.retainedOnErasurePrefsKeys,
      };
      for (final key in retained) {
        expect(key.startsWith('hiker.'), isFalse,
            reason: 'donnee de sante (art. 9) : aucune exception possible');
      }
    });
  });
}
