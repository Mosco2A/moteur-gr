/// LE BANC COMMUN des tests de la coche de preparation calculee : une base
/// Drift EN MEMOIRE, des preferences simulees, le sentier de test, et la
/// lecture d'une coche apres que ses sources ont rendu leur valeur.
///
/// Partage par `coche_rubriques_riches_test.dart` et
/// `coche_rubriques_pauvres_test.dart` : un seul banc, pour que les deux
/// fichiers mesurent la meme chose de la meme facon.
library;

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/test_trail_config.dart';
import 'package:moteur_gr/core/data/database.dart';
import 'package:moteur_gr/core/engine/trail_engine.dart';
import 'package:moteur_gr/core/providers/database_provider.dart';
import 'package:moteur_gr/features/feasibility/domain/hiker_profile.dart';
import 'package:moteur_gr/features/feasibility/providers/hiker_profile_provider.dart';
import 'package:moteur_gr/features/hub/providers/prepare_progress_providers.dart';
import 'package:moteur_gr/shared/widgets/step_status_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Le banc d'un fichier de tests : a construire dans `main()`, il pose ses
/// propres `setUp` / `tearDown`.
class BancDeCoche {
  BancDeCoche() {
    setUp(() {
      SharedPreferences.setMockInitialValues(const {});
      db = AppDatabase(NativeDatabase.memory());
    });
    tearDown(() => db.close());
  }

  /// Le sentier de test : celui que lisent aussi les providers « sentier
  /// actif » (duree retenue), pour que les deux cles se rejoignent.
  final String trailId = testTrailConfig.id;

  /// La base en memoire du test courant.
  late AppDatabase db;

  /// Un conteneur reel, base en memoire, sentier de test, et la fiche profil
  /// vide par defaut (le depot de profil lit un fichier protege).
  ProviderContainer conteneur({
    HikerProfile profil = HikerProfile.empty,
    List<Override> plus = const [],
  }) {
    final c = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        trailConfigProvider.overrideWithValue(testTrailConfig),
        hikerProfileProvider.overrideWith(() => _ProfilFige(profil)),
        ...plus,
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Lit la coche d'un sujet APRES que les sources asynchrones (preferences,
  /// flux Drift, disque) ont rendu leur premiere valeur.
  Future<PlanningStepStatus?> coche(
    ProviderContainer c,
    SujetDePreparation sujet,
  ) async {
    final cle = (trailId: trailId, sujet: sujet);
    final abonnement = c.listen(statutDePreparationProvider(cle), (_, _) {});
    addTearDown(abonnement.close);
    // Les lectures de base et de disque sont de VRAIES entrees-sorties : des
    // micro-taches ne suffisent pas a les voir finir (mesure : un test des
    // cartes rougissait une fois sur quatre). On attend donc leur futur.
    final enCours = switch (sujet) {
      SujetDePreparation.materiel => c.read(
        lignesDuSacProvider(trailId).future,
      ),
      SujetDePreparation.nuitees => c.read(
        nuitsReserveesProvider(trailId).future,
      ),
      SujetDePreparation.cartesHorsLigne => c.read(
        cartesSurLeTelephoneProvider(trailId).future,
      ),
      _ => Future<void>.value(),
    };
    await enCours;
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return c.read(statutDePreparationProvider(cle));
  }
}

/// La fiche profil, figee pour le test (le vrai depot lit un fichier protege).
class _ProfilFige extends HikerProfileNotifier {
  _ProfilFige(this._profil);

  final HikerProfile _profil;

  @override
  Future<HikerProfile> build() async => _profil;
}
