// LOT 645-08, PREALABLE P1 — L'AMORCAGE PORTE SES DEUX TRAVAUX, ET UNE GARDE LE
// DIT.
//
// ---------------------------------------------------------------------------
// CE QUI N'ETAIT GARDE PAR RIEN
// ---------------------------------------------------------------------------
//
// Le lot 645-05 (cas K1) a inverse l'amorcage : `app_bootstrap_provider.dart`,
// dans le socle, importait l'ECRAN de la fiche sante pour y prendre
// `ficheMedicaleFichierProvider`. Depuis, le socle ne declare plus qu'un
// BESOIN — `tachesDAmorcageProvider`, dont le defaut est une liste VIDE — et
// c'est `main.dart`, au-dessus des deux couches, qui noue les deux en
// surchargeant ce provider avec deux travaux, dans cet ordre :
//
//   1. tache 615 — l'exclusion iCloud de la fiche medicale, reposee a chaque
//      demarrage pour le randonneur qui avait rempli sa fiche avant le lot ;
//   2. tache 623 — la migration du profil du randonneur hors des preferences,
//      suivie de la pose de l'exclusion sur le fichier qui le remplace.
//
// Le defaut vide est ce qui rend l'amorcage testable sans monter une feature.
// C'est AUSSI ce qui rend la surcharge silencieuse : si elle disparaissait, si
// un travail etait retire, ou si les deux etaient intervertis, l'amorcage
// continuerait a rendre la main sans se plaindre — la liste vide s'execute tres
// bien. Rien dans `test/` ne rougissait. Regle maison #100350 : un garde qui
// echoue en silence est pire que pas de garde.
//
// ---------------------------------------------------------------------------
// CE QUE CE FICHIER PROUVE
// ---------------------------------------------------------------------------
//
//  1. Que le defaut du provider est bien VIDE (le socle ne cable rien tout
//     seul) : si quelqu'un y remettait un travail en dur, la feature
//     reviendrait dans le socle par la porte de derriere.
//  2. Que le cablage de `main.dart` porte EXACTEMENT DEUX travaux.
//  3. Que le PREMIER est l'exclusion iCloud de la fiche medicale, et RIEN
//     d'autre.
//  4. Que le SECOND est la migration du profil PUIS la pose de l'exclusion sur
//     son fichier — dans cet ordre-la, qui n'est pas indifferent : l'ecriture
//     atomique de la migration remplace le fichier, et un fichier remplace ne
//     porte plus l'attribut de celui qu'il remplace.
//
// COMMENT L'ORDRE EST MESURE. Deux travaux sont deux fermetures anonymes : on
// ne peut pas les distinguer par leur nom. On les distingue donc par leur
// EFFET — chaque dependance est remplacee par un espion qui inscrit son passage
// dans un journal commun, et c'est l'ordre du journal qui est affirme. Aucune
// ecriture disque, aucun canal natif : les espions court-circuitent les deux.

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/providers/taches_d_amorcage.dart';
import 'package:moteur_gr/features/feasibility/data/hiker_profile_repository.dart';
import 'package:moteur_gr/features/feasibility/data/profil_randonneur_fichier.dart';
import 'package:moteur_gr/features/safety/data/fiche_medicale_fichier.dart';
import 'package:moteur_gr/features/safety/presentation/health_info_screen.dart'
    show ficheMedicaleFichierProvider;
import 'package:moteur_gr/main.dart' show tachesDAmorcageDeLApplication;

/// Le journal commun aux trois espions : un travail passe, une ligne.
late List<String> journal;

/// La fiche medicale, sans disque ni canal natif : seule la pose de l'exclusion
/// nous interesse ici.
class _FicheMedicaleEspionne extends FicheMedicaleFichier {
  @override
  Future<void> garantirExclusion() async {
    journal.add('fiche medicale : exclusion iCloud');
  }
}

/// Le fichier du profil, meme principe.
class _ProfilFichierEspion extends ProfilRandonneurFichier {
  @override
  Future<void> garantirExclusion() async {
    journal.add('profil : exclusion iCloud');
  }
}

/// Le depot du profil : on n'observe que la migration, et on rend le fichier
/// espion pour voir la pose de l'exclusion qui doit la suivre.
class _ProfilEspion extends HikerProfileRepository {
  _ProfilEspion({required super.db, required _ProfilFichierEspion fichier})
    : _fichierEspion = fichier,
      super(fichier: fichier);

  final _ProfilFichierEspion _fichierEspion;

  @override
  ProfilRandonneurFichier get fichier => _fichierEspion;

  @override
  Future<void> migrerDepuisPreferences() async {
    journal.add('profil : migration hors des preferences');
  }
}

void main() {
  late AppDatabase db;

  setUp(() {
    journal = <String>[];
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('le defaut du provider est vide : le socle ne cable aucune feature', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(tachesDAmorcageProvider), isEmpty);
  });

  test(
    'le cablage de main.dart porte exactement deux travaux, dans l ordre : '
    'exclusion de la fiche medicale (615) puis migration du profil (623)',
    () async {
      final container = ProviderContainer(
        overrides: [
          ficheMedicaleFichierProvider.overrideWithValue(
            _FicheMedicaleEspionne(),
          ),
          hikerProfileRepositoryProvider.overrideWithValue(
            _ProfilEspion(db: db, fichier: _ProfilFichierEspion()),
          ),
          // LA SURCHARGE EST CELLE DE `main.dart`, PAS UNE COPIE : c'est la
          // fonction elle-meme qui est montee, donc la garde suit le cablage
          // reel si quelqu'un le change.
          tachesDAmorcageProvider.overrideWith(tachesDAmorcageDeLApplication),
        ],
      );
      addTearDown(container.dispose);

      final taches = container.read(tachesDAmorcageProvider);
      expect(
        taches,
        hasLength(2),
        reason: 'main.dart doit poser les taches 615 et 623, et elles seules',
      );

      await taches[0]();
      expect(journal, <String>['fiche medicale : exclusion iCloud']);

      await taches[1]();
      expect(journal, <String>[
        'fiche medicale : exclusion iCloud',
        'profil : migration hors des preferences',
        'profil : exclusion iCloud',
      ]);
    },
  );
}
