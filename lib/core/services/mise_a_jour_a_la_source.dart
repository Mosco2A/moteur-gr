/// Le premier repere de revision, celui qu'aucun geste ne posait : sans lui, la
/// cadence de quatre heures ne voyait jamais le sentier.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/remote_trail.dart';
import '../config/trail_data_source.dart';
import '../data/daos/trail_manifests_dao.dart';
import '../engine/trail_engine.dart';
import '../models/niveau_de_telechargement.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'delta_update_service.dart';
import 'firestore_trail_source.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// « JE VEUX QUE L APPLICATION VIENNE METTRE A JOUR SES DONNEES A CETTE SOURCE »
/// (Christophe, 30/09 11:54).
///
/// CE QUI MANQUAIT, ET C ETAIT UN VERROU STRUCTUREL, PAS UN OUBLI. Toute la
/// descente par revision existait depuis le lot 605 et la cadence de quatre
/// heures depuis le lot 616. Mais la cadence ne s occupe que des sentiers DEJA
/// TELECHARGES (`TrailManifestsDao.getTelecharges`, c est-a-dire dont le repere
/// local est non nul), et le seul geste capable de poser ce premier repere —
/// `CatalogNotifier.downloadTrail` — N AVAIT AUCUN APPELANT dans `lib/`. Mesure du
/// 30/09 : aucun sentier ne pouvait donc JAMAIS entrer dans le perimetre de la
/// cadence. La chaine complete etait inatteignable en production, et rien ne le
/// disait.
///
/// CE SERVICE EST LE DECLENCHEUR QUI MANQUAIT, AUX TROIS MOMENTS DEMANDES :
///
///  * AU DEMARRAGE — [auDemarrage] : la liste est relue en base, puis le sentier
///    actif est mis a jour. C est ce qui fait qu un randonneur qui ouvre
///    l application recoit une correction publiee la veille sans rien demander.
///  * A L OUVERTURE D UN SENTIER — [alOuvertureDuSentier] : le sentier qu on
///    regarde est celui qu on met a jour, tout de suite, et pas dans quatre
///    heures.
///  * SUR UN RAFRAICHISSEMENT MANUEL — [surDemandeDuRandonneur] : le meme travail,
///    declenche par un geste, et il rend son BILAN pour que l ecran puisse dire ce
///    qui est arrive.
///
/// LE NIVEAU DEMANDE EST « PREPARER », ET C EST UN CHOIX MESURE. Il porte les
/// six familles non volumineuses : la fiche, l itineraire, les etapes, les
/// hebergements, les points d interet et l entete de trace. Ce sont EXACTEMENT
/// les rubriques que Christophe a trouvees vides (bugs 12, 13, 15 et 17). Les
/// points de trace — le gros du volume — restent reserves a « realiser », donc au
/// geste explicite de telechargement : une ouverture de fiche ne doit pas faire
/// descendre des dizaines de milliers de points sur le forfait de quelqu un qui
/// regarde. Et le niveau ne BAISSE jamais : `DeltaUpdateService.synchroniser`
/// retient le plus haut des deux, donc un sentier deja realise reste realise.
///
/// RIEN N ATTEND, ET RIEN NE PLANTE. Tous les appels sont enveloppes : hors ligne,
/// Firebase absent, document illisible, la copie embarquee reste en place et la
/// cause est journalisee. C est la regle du patron GR20 et celle de la garantie
/// #C1 : quand la descente echoue, le repere local NE BOUGE PAS et le sentier
/// reste honnetement « a prendre ».
class MiseAJourALaSource {
  MiseAJourALaSource({
    required this.liste,
    required this.delta,
    required this.dao,
    required this.connectivityMonitor,
  });

  /// La liste des sentiers publies, lue dans `trails` (Firestore).
  final FirestoreTrailList liste;

  /// La descente par revision, qui pose les donnees.
  final DeltaUpdateService delta;

  /// La liste locale : c est elle qui porte le repere du telephone.
  final TrailManifestsDao dao;

  final ConnectivityMonitor connectivityMonitor;

  /// Le niveau demande par une mise a jour automatique.
  static const NiveauDeTelechargement niveauAutomatique =
      NiveauDeTelechargement.preparer;

  /// MISE A JOUR AU DEMARRAGE.
  ///
  /// [trailIdActif] est le sentier sur lequel l application s ouvre. Il est traite
  /// EN PREMIER, parce que c est celui que le randonneur va regarder ; les autres
  /// sentiers deja telechargés suivent.
  Future<BilanMiseAJour> auDemarrage(String trailIdActif) =>
      _passer('demarrage', trailIdActif);

  /// MISE A JOUR A L OUVERTURE D UN SENTIER.
  Future<BilanMiseAJour> alOuvertureDuSentier(String trailId) =>
      _passer('ouverture', trailId, seulementCeSentier: true);

  /// MISE A JOUR DEMANDEE PAR LE RANDONNEUR.
  ///
  /// Le seul chemin qui ne verifie PAS l etat du reseau avant de demander : quand
  /// quelqu un appuie sur « rafraichir », il attend qu on essaie. L echec sera dit,
  /// il ne sera pas devine a l avance.
  Future<BilanMiseAJour> surDemandeDuRandonneur(String trailId) => _passer(
    'geste',
    trailId,
    seulementCeSentier: true,
    verifierLeReseau: false,
  );

  Future<BilanMiseAJour> _passer(
    String cause,
    String trailId, {
    bool seulementCeSentier = false,
    bool verifierLeReseau = true,
  }) async {
    if (verifierLeReseau) {
      try {
        final statut = await connectivityMonitor.checkStatus();
        if (statut == ConnectivityStatusValues.offline) {
          _log.d('[Source] $cause : hors ligne — la copie locale sert.');
          return const BilanMiseAJour.horsLigne();
        }
      } catch (e) {
        _log.w('[Source] $cause : etat du reseau indisponible ($e).');
        return const BilanMiseAJour.horsLigne();
      }
    }

    final aTraiter = <String>[trailId];
    if (!seulementCeSentier) {
      try {
        for (final locale in await dao.getTelecharges()) {
          if (!aTraiter.contains(locale.trailId)) aTraiter.add(locale.trailId);
        }
      } catch (e) {
        _log.w('[Source] $cause : liste locale illisible ($e).');
      }
    }

    var sentiersAJour = 0;
    var ecrits = 0;
    var supprimes = 0;
    final echecs = <String>[];

    for (final identifiant in aTraiter) {
      try {
        final resultat = await _unSentier(identifiant, cause: cause);
        if (resultat == null) continue;
        sentiersAJour++;
        ecrits += resultat.ecrits;
        supprimes += resultat.supprimes;
      } catch (e) {
        // UN SENTIER QUI ECHOUE N ARRETE PAS LES AUTRES, ET SON ECHEC EST NOMME.
        // La garantie #C1 vaut par sentier : sa transaction est annulee, son
        // repere n avance pas, il reste « a prendre » au prochain passage.
        _log.w('[Source] $cause : $identifiant non mis a jour ($e).');
        echecs.add(identifiant);
      }
    }

    return BilanMiseAJour(
      sentiersAJour: sentiersAJour,
      ecrits: ecrits,
      supprimes: supprimes,
      echecs: echecs,
    );
  }

  Future<({int ecrits, int supprimes})?> _unSentier(
    String trailId, {
    required String cause,
  }) async {
    final entree = await liste.lireUn(trailId);
    if (entree == null) {
      _log.d(
        '[Source] $cause : $trailId n est pas publie en base — la copie '
        'embarquee reste la seule source pour ce sentier.',
      );
      return null;
    }

    if (!entree.estActive) {
      _log.d(
        '[Source] $cause : $trailId est publie avec le statut '
        '« ${entree.status} » — rien a prendre.',
      );
      return null;
    }

    final locale = await delta.revisionLocale(trailId);
    if (!(entree.dataVersion > locale)) {
      _log.d(
        '[Source] $cause : $trailId deja a jour '
        '(${locale.iso8601} >= ${entree.dataVersion.iso8601}).',
      );
      return null;
    }

    _log.i(
      '[Source] $cause : $trailId ${locale.iso8601} -> '
      '${entree.dataVersion.iso8601} — on prend ce qui est plus recent.',
    );

    final resultat = await delta.synchroniser(
      trailId,
      // L ADRESSE NE SERT QU AU REPLI PAR FICHIER. Sur une source interrogeable
      // elle est ignoree (documente sur `SourceInterrogeable`) ; on la calcule
      // quand meme pour que les deux transports restent interchangeables sans
      // condition dans l appelant.
      TrailDataSource.urlDonneesSentier(entree.filePath),
      revisionCible: entree.dataVersion,
      empreinteAttendue: entree.hash.isEmpty ? null : entree.hash,
      niveau: niveauAutomatique,
      revisionLocaleConnue: locale,
    );

    _log.i(
      '[Source] $cause : $trailId — ${resultat.ecrits} ecriture(s), '
      '${resultat.supprimes} suppression(s), repere '
      '${resultat.revisionAtteinte.iso8601}.',
    );
    return (ecrits: resultat.ecrits, supprimes: resultat.supprimes);
  }
}

/// CE QU UNE MISE A JOUR A FAIT — de quoi le DIRE au randonneur.
///
/// Un rafraichissement manuel qui ne rend rien laisse l ecran muet : le
/// randonneur appuie, quelque chose se passe peut-etre, et il ne sait pas. Ce
/// bilan existe pour que l ecran puisse distinguer « rien de neuf » de « pas de
/// reseau » et de « ca a echoue ».
class BilanMiseAJour {
  const BilanMiseAJour({
    required this.sentiersAJour,
    required this.ecrits,
    required this.supprimes,
    this.echecs = const <String>[],
    this.horsLigne = false,
  });

  /// Hors ligne : la copie locale sert, et ce n est pas une panne.
  const BilanMiseAJour.horsLigne()
    : sentiersAJour = 0,
      ecrits = 0,
      supprimes = 0,
      echecs = const <String>[],
      horsLigne = true;

  /// Nombre de sentiers qui ont reellement pris quelque chose.
  final int sentiersAJour;

  /// Enregistrements ecrits sur le telephone.
  final int ecrits;

  /// Enregistrements retires par un marqueur de suppression.
  final int supprimes;

  /// Identifiants des sentiers dont la mise a jour a echoue.
  final List<String> echecs;

  /// Vrai quand rien n a ete demande parce qu il n y avait pas de reseau.
  final bool horsLigne;

  /// Vrai si quelque chose est arrive sur le telephone.
  bool get aPrisQuelqueChose => ecrits > 0 || supprimes > 0;
}

/// Le service de mise a jour a la source.
final miseAJourALaSourceProvider = Provider<MiseAJourALaSource>((ref) {
  final db = ref.watch(databaseProvider);
  return MiseAJourALaSource(
    liste: ref.watch(listeSentiersFirestoreProvider),
    delta: ref.watch(deltaUpdateServiceProvider),
    dao: TrailManifestsDao(db),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
});

/// LE DECLENCHEUR DU DEMARRAGE, ARME UNE SEULE FOIS.
///
/// Meme forme que `ordonnanceurDemarreProvider` (tache 616) : un provider qu un
/// widget haut place regarde, et qui part en arriere-plan. IL NE BLOQUE PAS LE
/// DEMARRAGE — la copie embarquee est deja en base a ce moment-la, donc l ecran
/// est plein ; la mise a jour l ameliore quand elle arrive.
final miseAJourAuDemarrageProvider = Provider<void>((ref) {
  final trailId = ref.watch(trailIdActifPourMiseAJourProvider);
  if (trailId == null || trailId.isEmpty) return;
  final service = ref.watch(miseAJourALaSourceProvider);
  unawaited(
    service.auDemarrage(trailId).catchError((Object e) {
      // AVALER ICI EST LE BON COMPORTEMENT, et c est le seul endroit ou ca l est :
      // un echec de mise a jour ne doit pas empecher l application de demarrer sur
      // sa copie locale. La cause est journalisee par le service lui-meme.
      _log.w('[Source] Mise a jour au demarrage abandonnee : $e');
      return const BilanMiseAJour.horsLigne();
    }),
  );
});

/// LE DECLENCHEUR DE L OUVERTURE D UN SENTIER.
///
/// Regarde par l ecran d accueil du sentier : ouvrir un sentier, c est demander ce
/// qui a change dessus. Sans cela il faudrait attendre la cadence de quatre
/// heures — donc voir des rubriques vides alors que la base est pleine, ce qui est
/// exactement ce que Christophe a constate le 30/09.
///
/// UN SEUL PASSAGE PAR SENTIER ET PAR VIE DE PROVIDER : la famille garde son etat
/// tant que l ecran est monte, donc rouvrir le meme ecran dans la meme session ne
/// redemande rien. Le geste manuel reste disponible pour forcer.
final miseAJourAlOuvertureProvider = Provider.family<void, String>((
  ref,
  trailId,
) {
  if (trailId.isEmpty) return;
  final service = ref.watch(miseAJourALaSourceProvider);
  unawaited(
    service.alOuvertureDuSentier(trailId).catchError((Object e) {
      _log.w('[Source] Mise a jour a l ouverture de $trailId abandonnee : $e');
      return const BilanMiseAJour.horsLigne();
    }),
  );
});

/// L identifiant du sentier actif, pour la mise a jour au demarrage.
///
/// C est un provider A PART, et pas une lecture directe de [trailConfigProvider]
/// dans [miseAJourAuDemarrageProvider], pour que les tests puissent nommer le
/// sentier sans demarrer tout le moteur de configuration — et parce que l identite
/// du sentier actif est la SEULE chose que la mise a jour au demarrage ait besoin
/// de savoir de lui.
final trailIdActifPourMiseAJourProvider = Provider<String?>(
  (ref) => ref.watch(trailConfigProvider.select((c) => c.id)),
);
