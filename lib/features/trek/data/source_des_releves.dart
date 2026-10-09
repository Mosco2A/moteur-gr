/// LA SOURCE DES RELEVES DE MARCHE : la base en vrai, LA MEMOIRE EN DEMO
/// (tache 742).
///
/// LE DEFAUT QU'ELLE CORRIGE, MESURE (recette du build 12, tache 739). La barre
/// de la carte et le journal du jour lisent leurs chiffres sur les releves
/// persistes — `session_track_points` — par le DAO
/// [SessionTrackPointsDao]. En demo cette table reste VIDE, et c'est voulu
/// (tache 634 : « rien en base »). Les deux ecrans n'avaient donc rien a
/// mesurer : Parcouru « -- », Vit. moy. « -- », journal du jour vide. Ce
/// n'etait pas une erreur de calcul, c'etait une ABSENCE D'ENTREE.
///
/// CE QU'ELLE FAIT, ET CE QU'ELLE SE GARDE BIEN DE FAIRE. Elle choisit D'OU
/// VIENNENT LES RELEVES, et rien d'autre :
///   * hors demo, elle passe la lecture au DAO, mot pour mot, sans y toucher ;
///   * en demo, elle rend les releves que le marcheur simule tient en memoire
///     ([MarcheurSimule.releves]).
/// Elle ne calcule AUCUNE distance, AUCUN denivele, AUCUNE vitesse. Ses
/// appelants continuent d'appeler [computeTrackStatsOnTrace], le moteur unique
/// du lot 671-06 : MEME FONCTION DE STATISTIQUES, ENTREE DIFFERENTE. C'est
/// toute la frontiere de la tache 742 — un second cumul donnerait deux
/// deniveles differents pour la meme journee, et c'est precisement ce que le
/// lot 671-06 avait fini de supprimer.
///
/// POURQUOI UN OBJET ET PAS UN `if` DANS CHAQUE ECRAN. Trois lectures sont
/// concernees (les chiffres de la session, la trace du jour, le cumul depuis le
/// depart). Un `if (enDemo)` recopie trois fois, c'est trois endroits a tenir
/// d'accord et un quatrième qu'on oubliera. Ici la decision est prise UNE fois,
/// et les filtres de la memoire portent les MEMES predicats que les `where` du
/// DAO, ecrits a cote les uns des autres pour qu'un ecart se voie.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/session_track_points_dao.dart';
import '../../../core/data/database.dart' show SessionTrackPoint;
import '../../../core/providers/database_provider.dart';
import '../../../core/services/session_demo.dart';
import 'marcheur_simule_providers.dart';

/// D'OU VIENNENT LES RELEVES QUE LES CHIFFRES MESURENT.
class SourceDesReleves {
  /// [dao] est la source REELLE ; [relevesEnMemoire] celle de la demo, lue
  /// seulement quand [enDemo] est vrai.
  const SourceDesReleves({
    required SessionTrackPointsDao dao,
    required List<SessionTrackPoint> Function() relevesEnMemoire,
    required bool enDemo,
  }) : _dao = dao,
       _relevesEnMemoire = relevesEnMemoire,
       _enDemo = enDemo;

  final SessionTrackPointsDao _dao;
  final List<SessionTrackPoint> Function() _relevesEnMemoire;
  final bool _enDemo;

  /// Vrai quand les releves viennent de la memoire et non de la base.
  bool get enMemoire => _enDemo;

  /// LE FILTRE D'ORIGINE, en memoire : le jumeau exact de `_origin` du DAO.
  ///
  /// `gpsOnly` garde les releves reels — origine `gps` ou nulle — et ecarte les
  /// points estimes ; `withEstimated` garde tout. Le marcheur simule ne produit
  /// que des releves, donc les deux lectures lui rendent la meme chose
  /// aujourd'hui : le filtre est ecrit quand meme, parce qu'un lot qui
  /// ajouterait des points estimes a la simulation n'ait pas a y penser.
  static bool _origine(SessionTrackPoint p, TrackPointsRead read) =>
      switch (read) {
        TrackPointsRead.withEstimated => true,
        TrackPointsRead.gpsOnly =>
          p.source == null || p.source != TrackPointSource.estimated.stored,
      };

  /// Les releves d'UNE session, dans l'ordre d'enregistrement.
  ///
  /// C'est la lecture des chiffres de la randonnee EN COURS (la barre de la
  /// carte).
  Future<List<SessionTrackPoint>> parSession(
    String sessionId, {
    required TrackPointsRead read,
  }) async {
    if (!_enDemo) return _dao.getBySessionId(sessionId, read: read);
    return [
      for (final p in _relevesEnMemoire())
        if (p.sessionId == sessionId && _origine(p, read)) p,
    ];
  }

  /// Les releves d'une JOURNEE CALENDAIRE (minuit a minuit) du sentier.
  ///
  /// C'est la lecture du journal du jour : sa trace dessinee et ses chiffres.
  Future<List<SessionTrackPoint>> parJourCalendaire(
    String trailId,
    DateTime jour, {
    required TrackPointsRead read,
  }) async {
    if (!_enDemo) return _dao.getByCalendarDay(trailId, jour, read: read);
    final debut = DateTime(jour.year, jour.month, jour.day);
    final fin = debut.add(const Duration(days: 1));
    return [
      for (final p in _relevesEnMemoire())
        if (p.trailId == trailId &&
            !p.recordedAt.isBefore(debut) &&
            p.recordedAt.isBefore(fin) &&
            _origine(p, read))
          p,
    ];
  }

  /// Tous les releves du sentier, toutes sessions confondues.
  ///
  /// C'est la lecture du cumul depuis le depart, dans le journal.
  Future<List<SessionTrackPoint>> parSentier(
    String trailId, {
    required TrackPointsRead read,
  }) async {
    if (!_enDemo) return _dao.getByTrailId(trailId, read: read);
    return [
      for (final p in _relevesEnMemoire())
        if (p.trailId == trailId && _origine(p, read)) p,
    ];
  }

  /// LES JOURNEES CALENDAIRES que les releves en memoire couvrent, triees.
  ///
  /// POURQUOI LE JOURNAL EN A BESOIN. Ses journees viennent des ENTREES du
  /// carnet (`journalDaysProvider`), et une demo n'ecrit aucune entree : sans
  /// journee, aucune journee n'etait SELECTIONNEE, et la trace du jour comme
  /// les chiffres du jour rendaient le vide avant meme de chercher un releve.
  /// Une journee marchee est une journee du carnet, meme sans note : c'est
  /// aussi vrai en vrai, et en demo c'est la seule qu'il y ait.
  ///
  /// Vide hors demo : la base, elle, porte les entrees du carnet.
  List<DateTime> journeesEnMemoire() {
    if (!_enDemo) return const <DateTime>[];
    final jours = <DateTime>{
      for (final p in _relevesEnMemoire())
        DateTime(p.recordedAt.year, p.recordedAt.month, p.recordedAt.day),
    };
    return jours.toList()..sort();
  }
}

/// LA SOURCE DES RELEVES du moment : la base, ou la memoire pendant une demo.
///
/// Se recalcule a l'entree et a la sortie de demo (`enDemoProvider`), donc les
/// lectures qui en derivent repartent sur la bonne source sans que personne ait
/// a les invalider.
final sourceDesRelevesProvider = Provider<SourceDesReleves>((ref) {
  final marcheur = ref.watch(marcheurSimuleProvider);
  return SourceDesReleves(
    dao: ref.watch(databaseProvider).sessionTrackPointsDao,
    relevesEnMemoire: () => marcheur.releves,
    enDemo: ref.watch(enDemoProvider),
  );
});

/// LE SIGNAL DE CHANGEMENT DES RELEVES EN MEMOIRE : combien il y en a.
///
/// POURQUOI IL FAUT LE FABRIQUER. Une liste en memoire grossit SANS QUE
/// personne ne le sache : Riverpod ne recalcule une lecture que si l'une de ses
/// dependances change, et `sourceDesRelevesProvider` ne change pas quand le
/// marcheur ajoute un releve. Les chiffres de la carte s'en sortent seuls — ils
/// se recalculent au rythme de la position projetee, qui avance a chaque pas —
/// mais le journal du jour, lui, n'a aucune raison de se relire : il serait
/// reste sur la valeur du moment ou on l'a ouvert.
///
/// La base n'a pas ce probleme, et c'est pour cela que ce provider n'existait
/// pas : une ecriture Drift notifie ses lecteurs. La memoire, non. Ce provider
/// est donc le remplacant EXACT de cette notification, et rien de plus : il ne
/// porte aucun chiffre de randonnee, juste un compte qui monte.
///
/// Hors demo il n'emet jamais (le marcheur ne marche pas) : les lectures qui le
/// surveillent se comportent alors exactement comme avant.
final cadenceDesRelevesSimulesProvider = StreamProvider<int>((ref) {
  final marcheur = ref.watch(marcheurSimuleProvider);
  return marcheur.positions.map((_) => marcheur.releves.length);
});
