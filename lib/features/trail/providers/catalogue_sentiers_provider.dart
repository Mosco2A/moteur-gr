import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../../core/config/sentier_distant.dart';
import '../../../core/config/trail_catalog.dart';
import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_data_source.dart';
import '../../../core/data/daos/trail_manifests_dao.dart';
import '../../../core/models/trail_manifest.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/services/manifest_service.dart';
import '../../../core/services/source_firestore_sentier.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// D OU VIENT LE CATALOGUE QUE LE RANDONNEUR A SOUS LES YEUX.
///
/// Les trois couches sont ORDONNEES, pas concurrentes. C est toute la reponse a
/// la question qui a bloque le lot precedent — « faut-il brancher le distant ou
/// garder le compile ? » — et la reponse est : les deux, dans cet ordre.
enum SourceDuCatalogue {
  /// La liste distante vient d etre lue. C est la SOURCE DE VERITE.
  distant,

  /// Le dernier catalogue distant RECU, relu en base. Sert hors ligne, et il est
  /// entier : un sentier que le binaire ne connait pas reste visible.
  dernierDistantRecu,

  /// Le catalogue COMPILE. SECOURS DE DERNIERE MAIN, pour la toute premiere
  /// ouverture sans reseau — jamais un ecran vide.
  compile,
}

/// Pourquoi la liste distante manque, quand elle manque.
enum EchecDuCatalogue {
  /// Hors ligne : la liste n a pas ete demandee. Ce n est PAS une panne.
  horsLigne,

  /// En ligne, mais la liste distante n a pas pu etre lue (404, espace de
  /// stockage non provisionne, panne, reseau capricieux).
  listeInjoignable,
}

/// Le catalogue tel qu il est affichable A CET INSTANT, et d ou il vient.
class CatalogueSentiers {
  const CatalogueSentiers({
    required this.sentiers,
    required this.source,
    this.echec,
    this.ignores = const [],
  });

  /// Les sentiers affichables. JAMAIS VIDE en pratique : le catalogue compile
  /// est le plancher.
  final List<TrailConfig> sentiers;

  /// Laquelle des trois couches a produit cette liste.
  final SourceDuCatalogue source;

  /// Pourquoi la liste distante manque, ou `null` si elle a bien ete lue.
  final EchecDuCatalogue? echec;

  /// Identifiants d entrees distantes ECARTEES faute de description.
  ///
  /// Une entree sans fiche et sans equivalent compile ne porte que du
  /// versionnement : il n y a ni nom, ni region, ni distance a afficher. On
  /// l ecarte, mais on la NOMME — un sentier silencieusement absent est
  /// indiagnosticable (lecon de la tache 604).
  final List<String> ignores;

  /// Vrai quand la liste affichee n est pas celle du serveur.
  bool get listeNonRafraichie => source != SourceDuCatalogue.distant;
}

/// LE CATALOGUE, LU AU RESEAU, AVEC SES DEUX SECOURS.
///
/// LE DEFAUT QUE CE PROVIDER FERME, ET C EST LE MUR N1 (tache 605). Tout le
/// chainage distant existait — `ManifestService`, `catalogStateProvider`,
/// `UpdateDownloader`, `TrailManifestsDao` — et PERSONNE NE L APPELAIT :
/// `catalogStateProvider` n apparaissait que dans sa propre definition et dans un
/// COMMENTAIRE de l ecran catalogue. L ecran lisait `availableTrailsProvider`,
/// c est-a-dire `TrailCatalog.all`, le catalogue COMPILE. Un sentier decrit a
/// distance ne pouvait donc arriver chez un randonneur que par une republication
/// au magasin — ce qui contredit le principe fondateur du produit, verbatim de
/// Christophe du 27/09 19:57 : « faire lire les donnees automatiquement a l appli
/// pour que ca affiche les nouveaux sentiers totalement decrits en base ».
///
/// POURQUOI L ETAT EST SYNCHRONE ET PAS UNE `AsyncNotifier`. Quatre endroits
/// lisent `availableTrailsProvider` de facon SYNCHRONE — l ecran catalogue,
/// l ecran de selection, les droits d acces et « Mes treks ». Les faire tous
/// basculer en asynchrone reviendrait a leur apprendre a attendre, donc a
/// afficher un sablier — ou pire un vide — la ou le catalogue compile est
/// disponible IMMEDIATEMENT. On garde donc la forme du patron GR20
/// (`RemoteDataService`, dont les accesseurs rendent `_distant ?? _compile`) :
/// [build] rend le secours TOUT DE SUITE, puis les couches superieures ecrasent
/// l etat des qu elles arrivent. Aucun ecran n attend, aucun ecran ne vide.
///
/// TOUT EST ENVELOPPE. Base indisponible, JSON illisible, reseau qui tombe : la
/// liste ne descend jamais en dessous du catalogue compile, et la cause est
/// journalisee. C est la regle « JAMAIS de crash » du patron GR20.
class CatalogueSentiersNotifier extends Notifier<CatalogueSentiers> {
  /// Adresse de la liste des sentiers disponibles.
  ///
  /// Lue depuis [TrailDataSource], seul endroit du moteur qui sait ou vivent les
  /// donnees (tache 604 : deux copies en dur d une adresse morte).
  static String get urlDeLaListe => TrailDataSource.urlManifeste;

  @override
  CatalogueSentiers build() {
    // COUCHE 3 D ABORD, PARCE QU ELLE EST LA SEULE DISPONIBLE SANS ATTENDRE.
    // Ce n est pas un choix par defaut : c est le secours, et il est rendu en
    // premier pour qu aucun ecran ne soit vide le temps d une lecture.
    _rafraichir();
    return const CatalogueSentiers(
      sentiers: TrailCatalog.all,
      source: SourceDuCatalogue.compile,
    );
  }

  /// Relit le catalogue : dernier distant recu, puis distant.
  Future<void> rafraichir() => _rafraichir();

  Future<void> _rafraichir() async {
    // COUCHE 2 — le dernier catalogue distant recu. Relu AVANT toute tentative
    // reseau : hors ligne comme en ligne, c est ce que le randonneur avait, et il
    // doit rester entier.
    final recu = await _lireLeDernierRecu();
    if (!ref.mounted) return;
    if (recu != null && recu.sentiers.isNotEmpty) {
      state = recu;
    }

    // COUCHE 1 — la liste distante, source de verite.
    final ConnectivityStatus statut;
    try {
      statut = await ref.read(connectivityMonitorProvider).checkStatus();
    } catch (e) {
      _log.w('[Catalogue] Etat du reseau indisponible: $e');
      return;
    }
    if (!ref.mounted) return;

    if (statut == ConnectivityStatusValues.offline) {
      // HORS LIGNE : on ne demande RIEN et on ne perd RIEN. La cause est nommee
      // pour que l ecran puisse dire « liste non rafraichie » sans se presenter
      // comme une panne.
      state = CatalogueSentiers(
        sentiers: state.sentiers,
        source: state.source,
        echec: EchecDuCatalogue.horsLigne,
        ignores: state.ignores,
      );
      return;
    }

    // COUCHE 1 — LA BASE D ABORD, LE FICHIER EN REPLI (tache 641).
    //
    // « Je ne vois toujours pas les donnees Mare a Mare dans Firebase, ni demo,
    // ni normal, rien, d ou viennent les infos de l application » (Christophe,
    // 30/09 11:52). La reponse mesuree etait : de la constante compilee, parce que
    // la liste distante vivait dans un FICHIER de Firebase Storage que personne
    // n avait jamais deposé — mesure du meme jour : HTTP 403.
    //
    // La liste se lit donc desormais dans la COLLECTION `trails` de Firestore,
    // celle que Christophe voit dans sa console et que `tool/publier_en_base.py`
    // alimente. Le fichier reste le repli : mode local sans Firebase, ou projet
    // sans identifiant injecte au build.
    TrailManifest? liste;
    try {
      liste = await ref.read(listeSentiersFirestoreProvider).lire();
    } catch (e) {
      _log.w('[Catalogue] Lecture de la liste en base impossible: $e');
      liste = null;
    }
    if (!ref.mounted) return;

    if (liste == null || liste.trails.isEmpty) {
      try {
        liste = await ref
            .read(manifestServiceProvider)
            .fetchManifest(urlDeLaListe);
        if (liste != null) {
          _log.w(
            '[Catalogue] Liste lue depuis le FICHIER ($urlDeLaListe) et non '
            'depuis la base. C est le repli : la base fait foi des que la '
            'collection « trails » est publiee.',
          );
        }
      } catch (e) {
        _log.w('[Catalogue] Lecture de la liste distante impossible: $e');
        liste = null;
      }
    }
    if (!ref.mounted) return;

    if (liste == null) {
      _log.w(
        '[Catalogue] Liste des sentiers injoignable ($urlDeLaListe) — on garde '
        '${state.sentiers.length} sentier(s) de la source ${state.source.name}. '
        'La liste n est PAS a jour.',
      );
      state = CatalogueSentiers(
        sentiers: state.sentiers,
        source: state.source,
        echec: EchecDuCatalogue.listeInjoignable,
        ignores: state.ignores,
      );
      return;
    }

    final fusion = _fusionner(liste.trails);
    if (!ref.mounted) return;
    state = CatalogueSentiers(
      sentiers: fusion.sentiers,
      source: SourceDuCatalogue.distant,
      ignores: fusion.ignores,
    );

    // Conserver ce qui vient d etre recu, POUR LA PROCHAINE FOIS SANS RESEAU.
    // Sans cette ecriture la couche 2 serait toujours vide et le randonneur
    // perdrait, au premier redemarrage hors ligne, tout sentier que le binaire ne
    // connait pas.
    await _conserver(liste.trails);
  }

  /// Relit le dernier catalogue distant recu depuis la base locale.
  Future<CatalogueSentiers?> _lireLeDernierRecu() async {
    try {
      final dao = TrailManifestsDao(ref.read(databaseProvider));
      final lignes = await dao.getAll();
      if (lignes.isEmpty) return null;

      final entrees = <TrailManifestEntry>[];
      for (final ligne in lignes) {
        entrees.add(TrailManifestEntry(
          trailId: ligne.trailId,
          dataVersion: ligne.dataVersion,
          hash: ligne.hash,
          filePath: ligne.filePath,
          fileSize: ligne.fileSize,
          status: ligne.status,
          lastUpdated: ligne.lastUpdated,
          fiche: ManifestService.ficheDepuisJson(ligne.ficheJson),
        ));
      }

      final fusion = _fusionner(entrees);
      return CatalogueSentiers(
        sentiers: fusion.sentiers,
        source: SourceDuCatalogue.dernierDistantRecu,
        ignores: fusion.ignores,
      );
    } catch (e) {
      _log.w('[Catalogue] Dernier catalogue recu illisible: $e');
      return null;
    }
  }

  /// Ecrit en base la liste recue, FICHES COMPRISES.
  ///
  /// C est ce qui alimente la couche 2 : sans cette ecriture, le randonneur
  /// perdrait au premier redemarrage hors ligne tout sentier que le binaire ne
  /// connait pas.
  ///
  /// N ECRIT AUCUNE REVISION LOCALE, et c est volontaire : lire la liste AJOUTE
  /// AU CATALOGUE, cela ne met rien sur le telephone (precision de Christophe du
  /// 27/09 20:41). `localVersion` reste donc intact — il n est inscrit que par une
  /// copie reellement effectuee.
  Future<void> _conserver(List<TrailManifestEntry> entrees) async {
    try {
      final service = ref.read(manifestServiceProvider);
      for (final entree in entrees) {
        await service.saveLocalManifest(entree);
      }
    } catch (e) {
      // Ne JAMAIS faire echouer l affichage a cause de l ecriture du cache : le
      // randonneur a sa liste, elle est juste moins durable.
      _log.w('[Catalogue] Conservation du catalogue recu impossible: $e');
    }
  }

  /// LA FUSION — ET LA REGLE DE MEMBRES DU CATALOGUE.
  ///
  /// L identifiant est la cle. Pour chaque entree distante on cherche son
  /// equivalent compile et on fusionne ([EntreeManifesteEnSentier.versSentier]) :
  /// le distant gagne sur les donnees, le compile apporte ses assets.
  ///
  /// UN SENTIER COMPILE ABSENT DE LA LISTE DISTANTE EST CONSERVE, et c est une
  /// decision qu il faut assumer explicitement. « Le distant est la source de
  /// verite » pourrait se lire « la liste distante remplace la liste compilee » —
  /// mais alors une liste distante partielle, ou deposee avant que tous les
  /// sentiers y figurent, ferait DISPARAITRE des sentiers dont les donnees sont
  /// dans le binaire et qui fonctionnent. C est exactement la regression que le
  /// lot precedent a refusee, et elle serait ici invisible.
  ///
  /// LE RETRAIT RESTE POSSIBLE, ET IL EST EXPLICITE : une entree distante de
  /// statut autre que `active` (`draft`, `archived`) retire le sentier du
  /// catalogue, meme s il est compile. Christophe retire donc un sentier en le
  /// DISANT dans la liste, jamais par omission.
  _Fusion _fusionner(List<TrailManifestEntry> entrees) {
    final compiles = <String, TrailConfig>{
      for (final c in TrailCatalog.all) c.id: c,
    };

    final sentiers = <TrailConfig>[];
    final ignores = <String>[];
    final vus = <String>{};

    for (final entree in entrees) {
      vus.add(entree.trailId);

      if (!entree.estActive) {
        _log.d(
          '[Catalogue] ${entree.trailId} retire du catalogue : statut '
          '« ${entree.status} » declare par la liste distante.',
        );
        continue;
      }

      final fusionne = entree.versSentier(compile: compiles[entree.trailId]);
      if (fusionne == null) {
        ignores.add(entree.trailId);
        _log.w(
          '[Catalogue] ${entree.trailId} ecarte : la liste distante ne porte '
          'aucune fiche et le binaire ne connait pas ce sentier — il n y a ni '
          'nom ni statistique a afficher. Le processus de creation cote serveur '
          'doit publier une fiche (cf. data/apport_stepways/).',
        );
        continue;
      }
      sentiers.add(fusionne);
    }

    // Les sentiers compiles dont la liste distante ne parle pas, dans l ordre du
    // catalogue embarque.
    for (final compile in TrailCatalog.all) {
      if (!vus.contains(compile.id)) sentiers.add(compile);
    }

    return _Fusion(sentiers: sentiers, ignores: ignores);
  }
}

class _Fusion {
  const _Fusion({required this.sentiers, required this.ignores});
  final List<TrailConfig> sentiers;
  final List<String> ignores;
}

/// Provider du catalogue effectif (distant > dernier recu > compile).
final catalogueSentiersProvider =
    NotifierProvider<CatalogueSentiersNotifier, CatalogueSentiers>(
  CatalogueSentiersNotifier.new,
);
