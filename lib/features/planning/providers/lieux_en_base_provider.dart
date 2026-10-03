/// Transport et ravitaillement viennent desormais de la BASE : leur contenu
/// vivait dans deux constantes Dart, donc les ecrans etaient vides en reel.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/data/daos/trail_itineraries_dao.dart';
import '../../../core/data/daos/trail_pois_dao.dart';
import '../../../core/data/daos/trail_stages_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/providers/database_provider.dart';
import '../domain/shop_info.dart';
import '../domain/transport_info.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// LE TRANSPORT ET LE RAVITAILLEMENT VIENNENT DE LA BASE (tache 641).
///
/// CE QUI ETAIT CASSE, ET C EST LA REPONSE AUX BUGS 12, 13 ET 17. Christophe a
/// trouve les deux ecrans vides — en demo puis, verification faite, en reel. La
/// mesure du 30/09 a montre que le contenu de ces deux rubriques n existait PAS
/// EN BASE : il vivait dans deux constantes Dart, `TransportCatalog` et
/// `ShopCatalog`, derriere un `switch (trailId) { case 'mare-a-mare-centre': ... }`.
/// Trois consequences mecaniques :
///
///  1. TOUT AUTRE SENTIER RENDAIT `null` — donc l ecran Transport annoncait
///     « Aucune information de transport pour ce sentier » et l ecran
///     Ravitaillement rendait un `SizedBox.shrink()`, c est-a-dire un ECRAN BLANC
///     sous un titre. C est le sentier de demonstration
///     (`mare-a-mare-centre-demo`, un identifiant DIFFERENT) qui tombait dans ce
///     cas, et c est exactement ce que Christophe a vu.
///  2. AUCUNE CORRECTION SANS REPUBLIER L APPLICATION. Un horaire d autocar corse
///     change quatre fois par an ; un gite ferme. Corriger demandait un passage
///     par le magasin.
///  3. « JE NE VEUX PAS QUE CE SOIT EN DUR MAIS DANS LA BASE » (Christophe,
///     29/09) etait litteralement viole par ces deux fichiers.
///
/// CE FICHIER LIT CES DEUX RUBRIQUES DANS `trail_pois`, ET IL DONNE A CETTE TABLE
/// SES PREMIERS LECTEURS. Deuxieme mesure du 30/09, et elle est genante : la table
/// `trail_pois` — celle que la descente par revision alimente, la seule qui
/// recoive les donnees publiees — etait ECRITE AU SEED ET JAMAIS RELUE. Aucun
/// lecteur dans `lib/` hors le seeder et la pose. Publier dans les sept familles
/// aurait donc rempli une table que personne ne regardait. Les deux ecrans vides
/// et la table sans lecteur se soignent ensemble.
///
/// LE TYPE PORTE LA FAMILLE, ET C EST UN CHOIX CONTRE UNE HUITIEME FAMILLE. On
/// pouvait ajouter `transports` et `shops` aux sept familles de sentier. Ce serait
/// deux tables Drift de plus, deux migrations, deux branches dans la pose, et
/// surtout une modification de `TrailChunks` — dont l ordre gouverne les
/// clefs etrangeres de toute la copie. On prefere des TYPES de point d interet
/// prefixes (`transport_bus`, `transport_ferry`, `shop_epicerie`...) : un lieu
/// physique rattache a une etape EST un point d interet, le schema n a pas besoin
/// de bouger, et les valeurs se lisent a l oeil dans la console Firestore.
///
/// LE CATALOGUE EN DUR RESTE, EN DERNIER RECOURS SEULEMENT. Tant qu un sentier
/// n est pas publie en base, son ancien contenu compile vaut mieux qu un ecran
/// vide. Mais la base GAGNE des qu elle repond : c est la regle « seule la copie
/// sur le tel ».
abstract final class LieuxEnBase {
  LieuxEnBase._();

  /// Prefixe des types de point d interet qui decrivent un TRANSPORT.
  static const String prefixeTransport = 'transport';

  /// Prefixe des types de point d interet qui decrivent un RAVITAILLEMENT.
  static const String prefixeRavitaillement = 'shop';

  /// Vrai si [type] designe un transport.
  static bool estTransport(String type) =>
      type == prefixeTransport || type.startsWith('${prefixeTransport}_');

  /// Vrai si [type] designe un ravitaillement.
  static bool estRavitaillement(String type) =>
      type == prefixeRavitaillement ||
      type.startsWith('${prefixeRavitaillement}_');

  /// LE MODE DE TRANSPORT, LU DANS LE SUFFIXE DU TYPE.
  ///
  /// `transport_bus` -> [TransportModeKind.bus]. UN SUFFIXE INCONNU RETOMBE SUR
  /// [TransportModeKind.other] SANS ERREUR : le serveur peut publier un mode que
  /// cette version de l application ne connait pas, et une icone generique vaut
  /// mieux qu une exception dans l ecran d un randonneur.
  static TransportModeKind modeDe(String type) {
    final suffixe = type.contains('_') ? type.split('_').last : '';
    return switch (suffixe) {
      'bus' || 'autocar' || 'car' => TransportModeKind.bus,
      'train' => TransportModeKind.train,
      'ferry' || 'bateau' || 'navette_maritime' => TransportModeKind.ferry,
      'plane' || 'avion' => TransportModeKind.plane,
      'taxi' => TransportModeKind.taxi,
      'shuttle' || 'navette' => TransportModeKind.shuttle,
      'carrental' || 'location' => TransportModeKind.carRental,
      _ => TransportModeKind.other,
    };
  }

  /// LA FAMILLE DE COMMERCE, LUE DANS LE SUFFIXE DU TYPE.
  ///
  /// Meme tolerance que [modeDe] : un suffixe inconnu devient
  /// [ShopKind.epicerie], le repli que `Shop.fromJson` utilise deja.
  static ShopKind familleDe(String type) {
    final suffixe = type.contains('_') ? type.split('_').last : '';
    return switch (suffixe) {
      'bar' || 'restaurant' => ShopKind.bar,
      'pharmacie' || 'pharmacy' => ShopKind.pharmacie,
      'gaz' || 'gas' => ShopKind.gaz,
      _ => ShopKind.epicerie,
    };
  }
}

/// Un lieu du sentier, tel que la base le porte.
class LieuDeSentier {
  const LieuDeSentier({
    required this.poi,
    required this.stageNumber,
    required this.estPremiereEtape,
    required this.estDerniereEtape,
  });

  /// La ligne de `trail_pois`.
  final TrailPoi poi;

  /// Numero de l etape a laquelle ce lieu est rattache.
  final int stageNumber;

  /// Vrai si ce lieu est sur la premiere etape du sentier.
  final bool estPremiereEtape;

  /// Vrai si ce lieu est sur la derniere etape du sentier.
  final bool estDerniereEtape;
}

/// TOUS LES LIEUX DU SENTIER, LUS EN BASE, AVEC LEUR NUMERO D ETAPE.
///
/// Une seule lecture pour les deux rubriques : la jointure etape -> itineraire ->
/// sentier se fait UNE fois, pas deux.
final lieuxDuSentierEnBaseProvider =
    FutureProvider.family<List<LieuDeSentier>, String>((ref, trailId) async {
      final db = ref.watch(databaseProvider);
      final itineraires = await TrailItinerariesDao(db).getByTrailId(trailId);
      if (itineraires.isEmpty) return const <LieuDeSentier>[];

      final stages = <TrailStage>[];
      for (final itineraire in itineraires) {
        stages.addAll(await TrailStagesDao(db).getByItineraryId(itineraire.id));
      }
      if (stages.isEmpty) return const <LieuDeSentier>[];

      final numeros = stages.map((e) => e.stageNumber).toList()..sort();
      final premiere = numeros.first;
      final derniere = numeros.last;

      final poisDao = TrailPoisDao(db);
      final lieux = <LieuDeSentier>[];
      for (final etape in stages) {
        for (final poi in await poisDao.getByStageId(etape.id)) {
          lieux.add(
            LieuDeSentier(
              poi: poi,
              stageNumber: etape.stageNumber,
              estPremiereEtape: etape.stageNumber == premiere,
              estDerniereEtape: etape.stageNumber == derniere,
            ),
          );
        }
      }
      lieux.sort((a, b) => a.stageNumber.compareTo(b.stageNumber));
      return lieux;
    });

/// LE TRANSPORT DU SENTIER, CONSTRUIT DEPUIS LA BASE.
///
/// [nomDepart] et [nomArrivee] sont les endpoints resolus par
/// `transportEndpointsProvider` : le modele `TrailTransport` les indexe par NOM,
/// et l ecran demande `forEndpoint(nom, role)`. On produit donc les QUATRE
/// combinaisons (chaque endpoint en « rejoindre » et en « repartir »), comme le
/// faisait le catalogue en dur, parce que le sentier se marche dans les deux sens.
///
/// LES LIEUX DES ETAPES INTERMEDIAIRES FIGURENT DANS LES DEUX ONGLETS, et ce n est
/// pas un doublon paresseux : la ligne d autocar C6 qui passe a Cozzano, Guitera et
/// Sainte-Marie-Sicche est la SEULE facon d abandonner ou de rejoindre le sentier
/// en cours de route. Elle est utile a l aller comme au retour, et la cacher dans
/// un seul onglet la rendrait introuvable la moitie du temps.
///
/// RETOURNE `null` QUAND LA BASE NE DIT RIEN — jamais un objet vide. C est ce qui
/// permet a l appelant de retomber sur le catalogue compile au lieu d afficher un
/// ecran vide.
TrailTransport? transportDepuisLesLieux(
  String trailId,
  List<LieuDeSentier> lieux, {
  required String nomDepart,
  required String nomArrivee,
}) {
  final transports = lieux
      .where((l) => LieuxEnBase.estTransport(l.poi.type))
      .toList();
  if (transports.isEmpty) return null;

  List<TransportSection> sectionsPour({required bool cotedepart}) {
    final retenus = transports.where((l) {
      if (l.estPremiereEtape && l.estDerniereEtape) return true;
      return cotedepart ? l.estPremiereEtape : l.estDerniereEtape;
    }).toList();
    final intermediaires = transports
        .where((l) => !l.estPremiereEtape && !l.estDerniereEtape)
        .toList();

    final sections = <TransportSection>[];
    if (retenus.isNotEmpty) {
      sections.add(
        TransportSection(
          title: cotedepart ? nomDepart : nomArrivee,
          mode: LieuxEnBase.modeDe(retenus.first.poi.type),
          options: retenus.map(_option).toList(),
        ),
      );
    }
    if (intermediaires.isNotEmpty) {
      // GROUPE PAR ETAPE : « Etape 2 », « Etape 3 »… Le titre de section est une
      // DONNEE dans ce modele (il varie par lieu), donc il ne peut pas etre une
      // clef i18n fixe ; on prend le nom du lieu tel que la base l ecrit, qui est
      // deja dans la langue de la donnee.
      final parEtape = <int, List<LieuDeSentier>>{};
      for (final l in intermediaires) {
        parEtape.putIfAbsent(l.stageNumber, () => <LieuDeSentier>[]).add(l);
      }
      final numeros = parEtape.keys.toList()..sort();
      for (final numero in numeros) {
        final groupe = parEtape[numero]!;
        sections.add(
          TransportSection(
            title: groupe.first.poi.nameFr,
            mode: LieuxEnBase.modeDe(groupe.first.poi.type),
            options: groupe.map(_option).toList(),
          ),
        );
      }
    }
    return sections;
  }

  final sectionsDepart = sectionsPour(cotedepart: true);
  final sectionsArrivee = sectionsPour(cotedepart: false);

  return TrailTransport(
    trailId: trailId,
    endpoints: [
      if (sectionsDepart.isNotEmpty)
        EndpointTransport(
          endpointName: nomDepart,
          role: TransportRole.arrival,
          intro: '',
          sections: sectionsDepart,
        ),
      if (sectionsArrivee.isNotEmpty)
        EndpointTransport(
          endpointName: nomArrivee,
          role: TransportRole.departure,
          intro: '',
          sections: sectionsArrivee,
        ),
      // LE SENTIER SE MARCHE DANS LES DEUX SENS : le depart devient une arrivee.
      if (sectionsDepart.isNotEmpty)
        EndpointTransport(
          endpointName: nomDepart,
          role: TransportRole.departure,
          intro: '',
          sections: sectionsDepart,
        ),
      if (sectionsArrivee.isNotEmpty)
        EndpointTransport(
          endpointName: nomArrivee,
          role: TransportRole.arrival,
          intro: '',
          sections: sectionsArrivee,
        ),
    ],
  );
}

TransportOption _option(LieuDeSentier lieu) {
  final poi = lieu.poi;
  return TransportOption(
    mode: LieuxEnBase.modeDe(poi.type),
    title: poi.nameFr,
    description: poi.descriptionFr ?? '',
    contact: poi.phone ?? '',
    contactLabel: poi.nameFr,
    url: poi.website,
    address: poi.address,
    // ZERO N EST PAS UNE COORDONNEE : la colonne n est pas nullable, donc un lieu
    // sans point connu y arrive a `0,0`, au large du Ghana. On le rend `null`
    // plutot que de fabriquer un lien de carte vers la haute mer.
    lat: (poi.lat == 0 && poi.lng == 0) ? null : poi.lat,
    lng: (poi.lat == 0 && poi.lng == 0) ? null : poi.lng,
  );
}

/// LE RAVITAILLEMENT DU SENTIER, CONSTRUIT DEPUIS LA BASE.
///
/// Retourne `null` quand la base ne porte aucun commerce — jamais un
/// `TrailShops` vide, pour que l appelant puisse retomber sur le catalogue
/// compile plutot que de montrer l ecran blanc du bug 17.
TrailShops? ravitaillementDepuisLesLieux(
  String trailId,
  List<LieuDeSentier> lieux,
) {
  final commerces = lieux
      .where((l) => LieuxEnBase.estRavitaillement(l.poi.type))
      .toList();
  if (commerces.isEmpty) return null;

  return TrailShops(
    trailId: trailId,
    shops: commerces
        .map(
          (l) => Shop(
            name: l.poi.nameFr,
            type: LieuxEnBase.familleDe(l.poi.type),
            stageNumber: l.stageNumber,
            openingHours: l.poi.descriptionFr ?? '',
            latitude: (l.poi.lat == 0 && l.poi.lng == 0) ? null : l.poi.lat,
            longitude: (l.poi.lat == 0 && l.poi.lng == 0) ? null : l.poi.lng,
            phone: l.poi.phone ?? '',
            website: l.poi.website,
            address: l.poi.address,
          ),
        )
        .toList(),
  );
}

/// LE TRANSPORT EFFECTIF : LA BASE D ABORD, LE COMPILE EN SECOURS.
///
/// Rend `null` quand ni l une ni l autre ne dit rien — l ecran enonce alors un
/// fait (« Aucune information de transport pour ce sentier ») au lieu de montrer
/// deux onglets vides.
final transportEnBaseProvider =
    Provider.family<
      TrailTransport?,
      ({String trailId, String depart, String arrivee})
    >((ref, parametres) {
      final lieux = ref.watch(lieuxDuSentierEnBaseProvider(parametres.trailId));
      final enBase = lieux.maybeWhen(
        data: (l) => transportDepuisLesLieux(
          parametres.trailId,
          l,
          nomDepart: parametres.depart,
          nomArrivee: parametres.arrivee,
        ),
        orElse: () => null,
      );
      if (enBase != null) {
        _log.d(
          '[Lieux] Transport de ${parametres.trailId} lu EN BASE '
          '(${enBase.endpoints.length} endpoint(s)).',
        );
        return enBase;
      }
      return null;
    });

/// LE RAVITAILLEMENT EFFECTIF : LA BASE D ABORD.
final ravitaillementEnBaseProvider = Provider.family<TrailShops?, String>((
  ref,
  trailId,
) {
  final lieux = ref.watch(lieuxDuSentierEnBaseProvider(trailId));
  final enBase = lieux.maybeWhen(
    data: (l) => ravitaillementDepuisLesLieux(trailId, l),
    orElse: () => null,
  );
  if (enBase != null) {
    _log.d(
      '[Lieux] Ravitaillement de $trailId lu EN BASE '
      '(${enBase.shops.length} commerce(s)).',
    );
  }
  return enBase;
});
