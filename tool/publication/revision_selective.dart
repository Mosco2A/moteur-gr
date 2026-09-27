import 'dart:convert';

import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

/// LA REVISION SELECTIVE — LE COEUR DE L OUTIL, ET SON SEUL VRAI PIEGE.
///
/// CE QUE LE MODELE DE CHRISTOPHE EXIGE, verbatim du 27/09 20:43 : « On ne met
/// qu une info de version sur chaque donnee, l appli regarde juste quelles
/// donnees ne sont pas dans la derniere version et les telecharge ». Toute la
/// valeur de ce modele tient a UNE condition cote serveur : que la revision d un
/// enregistrement ne bouge QUE s il a reellement change.
///
/// SI L OUTIL REINCREMENTE TOUT, LE MODELE NE SERT A RIEN — ET C EST PIRE QUE DE
/// NE RIEN AVOIR FAIT. Un `rev` uniformement remis a la revision courante fait
/// redescendre les sept familles a chaque publication : chaque telephone
/// retelecharge tout le sentier pour une altitude corrigee, et les trois lots
/// 605-606-607 auraient produit un rechargement integral deguise en versionnage
/// unitaire. C est exactement le defaut que le lot 605 avait trouve dans
/// `_inferChangedTables`, qui rendait les sept tables EN DUR : il serait
/// simplement revenu de l autre bout de la chaine.
///
/// COMMENT ON DECIDE, EN TROIS QUESTIONS PAR ENREGISTREMENT.
///  1. Cet enregistrement existait-il a la publication precedente ? L identite
///     est `id` pour six familles, et `track_id` + `sequence_index` pour les
///     points de trace, qui n ont pas d identifiant propre (#R8).
///  2. Son CONTENU a-t-il change ? On compare une empreinte de contenu qui
///     EXCLUT `rev` et `supprime` — sinon la revision se comparerait a
///     elle-meme et tout changerait toujours.
///  3. Sinon : il garde la revision qu il avait. Litteralement : l ancien
///     numero est recopie.
///
/// ET LA QUATRIEME QUESTION, CELLE QU ON OUBLIE : qu est-ce qui a DISPARU ? Un
/// numero qui monte ne transmet pas une absence (#R7). Un enregistrement present
/// avant et absent maintenant devient un MARQUEUR DE SUPPRESSION a la nouvelle
/// revision — sans quoi un point d eau tari resterait a vie sur le telephone du
/// randonneur.
///
/// LES NOMBRES SONT COMPARES POUR LEUR VALEUR, PAS POUR LEUR ECRITURE. `14` et
/// `14.0` designent la meme distance : les distinguer ferait monter une revision
/// pour une virgule, et c est precisement le gaspillage que ce modele existe pour
/// supprimer.
abstract final class RevisionSelective {
  RevisionSelective._();

  /// Familles dont l identite est un simple `id`.
  static const List<String> famillesAIdentifiant = <String>[
    MorceauxDeSentier.fiche,
    MorceauxDeSentier.itineraires,
    MorceauxDeSentier.etapes,
    MorceauxDeSentier.hebergements,
    MorceauxDeSentier.pointsDInteret,
    MorceauxDeSentier.traces,
  ];

  /// Identite d un enregistrement dans sa [famille].
  ///
  /// Rend `null` quand l enregistrement ne porte pas de quoi s identifier : il
  /// n est alors pas publiable, et l appelant doit le DIRE plutot que de publier
  /// une donnee que personne ne pourra jamais corriger ni retirer.
  static String? identite(String famille, Map<String, dynamic> donnee) {
    if (famille == MorceauxDeSentier.pointsDeTrace) {
      final trace = donnee['track_id'];
      final rang = donnee['sequence_index'];
      if (trace is! String || trace.isEmpty || rang is! int) return null;
      return '$trace#$rang';
    }
    final id = donnee['id'];
    if (id is! String || id.isEmpty) return null;
    return id;
  }

  /// Champs de BOOKKEEPING DE VERSION, exclus de la comparaison de contenu.
  ///
  /// `rev` et `supprime` sont ce que l outil ecrit : les inclure ferait dependre
  /// la decision « a-t-il change ? » de sa propre sortie precedente, et TOUT
  /// changerait a chaque publication.
  ///
  /// `data_version` est le cas subtil, et il a ete MESURE avant d etre exclu.
  /// C est la revision courante du sentier recopiee dans `trail_meta` : elle
  /// monte donc a CHAQUE publication, par construction. Tant qu elle etait
  /// comparee, `trail_meta` descendait a chaque republication en plus de ce qui
  /// avait reellement change — deux enregistrements pour une altitude corrigee
  /// au lieu d un. Ce n est pas un doublon inoffensif qu on cache : c est un
  /// doublon dont AUCUNE decision ne depend (mesure : les lectures de
  /// `dataVersion` qui decident d une mise a jour viennent toutes de
  /// `trail_manifests`, jamais de `trail_meta`). Le repere qui fait foi est
  /// `trail_manifests.localVersion`, ecrit dans la transaction de la pose.
  static const List<String> champsDeBookkeeping = <String>[
    RevisionDeDonnee.champRevision,
    RevisionDeDonnee.champSupprime,
    'data_version',
  ];

  /// Empreinte du CONTENU d un enregistrement, hors bookkeeping de version.
  ///
  /// Les clefs sont triees pour qu un simple reordonnancement du fichier source
  /// ne fasse pas monter une revision.
  static String empreinteDeContenu(Map<String, dynamic> donnee) {
    final utiles = <String, dynamic>{
      for (final entree in donnee.entries)
        if (!champsDeBookkeeping.contains(entree.key))
          entree.key: entree.value,
    };
    return jsonEncode(_canonique(utiles));
  }

  /// Forme canonique d une valeur JSON : clefs triees, nombres par leur valeur.
  static Object? _canonique(Object? valeur) {
    if (valeur is Map) {
      final clefs = valeur.keys.map((k) => k.toString()).toList()..sort();
      return <String, Object?>{
        for (final clef in clefs) clef: _canonique(valeur[clef]),
      };
    }
    if (valeur is List) return valeur.map(_canonique).toList();
    if (valeur is num) {
      // `14` et `14.0` sont la meme distance. Un entier tenant dans un double
      // exact est ramene a sa forme entiere, le reste garde sa precision.
      final double d = valeur.toDouble();
      if (d == d.roundToDouble() && d.abs() < 1e15) return d.toInt();
      return d;
    }
    return valeur;
  }

  /// CALCULE LA PUBLICATION SUIVANTE A PARTIR DE LA PRECEDENTE.
  ///
  /// [donneesSource] est le contenu voulu, SANS `rev` : sept familles au plus,
  /// exactement la forme du fichier publie. [publicationPrecedente] est le
  /// fichier deja publie (ou `null` a la premiere publication).
  ///
  /// Rend la publication a deposer et le detail de ce qui a bouge. Quand RIEN n a
  /// bouge, [Recalcul.aChange] est faux et la revision ne doit PAS etre
  /// incrementee : publier une revision vide ferait retelecharger la liste a
  /// tous les telephones pour rien.
  static Recalcul calculer({
    required Map<String, dynamic> donneesSource,
    required Map<String, dynamic>? publicationPrecedente,
    required int revisionPrecedente,
    required int nouvelleRevision,
  }) {
    final avant = _indexer(publicationPrecedente);
    final resultat = <String, dynamic>{};
    final modifies = <String>[];
    final ajoutes = <String>[];
    final retires = <String>[];
    final marqueursConserves = <String>[];
    final marqueursPurges = <String>[];

    for (final famille in MorceauxDeSentier.tous) {
      final source = _enregistrements(donneesSource[famille]);
      final precedents = avant[famille] ?? const <String, Map<String, dynamic>>{};
      final vus = <String>{};
      final sortie = <Map<String, dynamic>>[];

      for (final donnee in source) {
        final cle = identite(famille, donnee);
        if (cle == null) {
          throw EnregistrementSansIdentite(famille: famille, donnee: donnee);
        }
        if (!vus.add(cle)) {
          throw IdentiteEnDouble(famille: famille, identite: cle);
        }

        final ancien = precedents[cle];
        final ancienEstUnMarqueur =
            ancien != null && RevisionDeDonnee.estSupprimee(ancien);

        if (ancien == null || ancienEstUnMarqueur) {
          // Nouveau, ou ressuscite apres une suppression : dans les deux cas le
          // telephone ne l a pas, il prend la nouvelle revision.
          sortie.add(_avecRevision(donnee, nouvelleRevision));
          ajoutes.add('$famille/$cle');
          continue;
        }

        if (empreinteDeContenu(ancien) == empreinteDeContenu(donnee)) {
          // INCHANGE : il GARDE son numero. C est toute la difference entre un
          // versionnage unitaire et un rechargement integral deguise.
          final rev = RevisionDeDonnee.revisionDe(
            ancien,
            defaut: revisionPrecedente,
          );
          sortie.add(_avecRevision(donnee, rev));
          continue;
        }

        sortie.add(_avecRevision(donnee, nouvelleRevision));
        modifies.add('$famille/$cle');
      }

      // CE QUI A DISPARU — la question qu on oublie, et sans laquelle la
      // correction ne marche que dans un sens.
      for (final entree in precedents.entries) {
        if (vus.contains(entree.key)) continue;

        if (RevisionDeDonnee.estSupprimee(entree.value)) {
          // Marqueur deja publie : on le garde tant que la fenetre de retention
          // le couvre, on le purge au-dela (#X5).
          final rev = RevisionDeDonnee.revisionDe(
            entree.value,
            defaut: revisionPrecedente,
          );
          if (RevisionDeDonnee.marqueurAConserver(
            rev: rev,
            revisionCourante: nouvelleRevision,
          )) {
            sortie.add(entree.value);
            marqueursConserves.add('$famille/${entree.key}');
          } else {
            marqueursPurges.add('$famille/${entree.key}');
          }
          continue;
        }

        sortie.add(_marqueur(famille, entree.value, nouvelleRevision));
        retires.add('$famille/${entree.key}');
      }

      if (sortie.isEmpty) continue;
      resultat[famille] = famille == MorceauxDeSentier.fiche
          ? sortie.first
          : sortie;
    }

    return Recalcul(
      donnees: resultat,
      modifies: modifies,
      ajoutes: ajoutes,
      retires: retires,
      marqueursConserves: marqueursConserves,
      marqueursPurges: marqueursPurges,
    );
  }

  /// L enregistrement avec sa revision, `rev` en dernier pour la lisibilite.
  static Map<String, dynamic> _avecRevision(
    Map<String, dynamic> donnee,
    int rev,
  ) {
    return <String, dynamic>{
      for (final e in donnee.entries)
        if (e.key != RevisionDeDonnee.champRevision) e.key: e.value,
      RevisionDeDonnee.champRevision: rev,
    };
  }

  /// UN MARQUEUR NE PORTE QUE SON IDENTITE (#R7).
  ///
  /// La donnee n existe plus : la republier en entier serait a la fois inutile et
  /// trompeur. Les points de trace font exception parce que leur identite EST le
  /// couple trace + rang (#R8).
  static Map<String, dynamic> _marqueur(
    String famille,
    Map<String, dynamic> ancien,
    int rev,
  ) {
    if (famille == MorceauxDeSentier.pointsDeTrace) {
      return <String, dynamic>{
        'track_id': ancien['track_id'],
        'sequence_index': ancien['sequence_index'],
        RevisionDeDonnee.champRevision: rev,
        RevisionDeDonnee.champSupprime: true,
      };
    }
    return <String, dynamic>{
      'id': ancien['id'],
      RevisionDeDonnee.champRevision: rev,
      RevisionDeDonnee.champSupprime: true,
    };
  }

  static Map<String, Map<String, Map<String, dynamic>>> _indexer(
    Map<String, dynamic>? publication,
  ) {
    final index = <String, Map<String, Map<String, dynamic>>>{};
    if (publication == null) return index;
    for (final famille in MorceauxDeSentier.tous) {
      final parIdentite = <String, Map<String, dynamic>>{};
      for (final donnee in _enregistrements(publication[famille])) {
        final cle = identite(famille, donnee);
        if (cle != null) parIdentite[cle] = donnee;
      }
      if (parIdentite.isNotEmpty) index[famille] = parIdentite;
    }
    return index;
  }

  static List<Map<String, dynamic>> _enregistrements(dynamic brut) => [
        if (brut is Map) Map<String, dynamic>.from(brut),
        if (brut is List)
          ...brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      ];
}

/// CE QUE LA PUBLICATION SUIVANTE CONTIENT, ET CE QUI A REELLEMENT BOUGE.
class Recalcul {
  const Recalcul({
    required this.donnees,
    required this.modifies,
    required this.ajoutes,
    required this.retires,
    required this.marqueursConserves,
    required this.marqueursPurges,
  });

  /// Les familles a publier, chaque enregistrement portant sa revision.
  final Map<String, dynamic> donnees;

  /// Identites dont le CONTENU a change : ce sont elles, et elles seules, qui
  /// prennent la nouvelle revision.
  final List<String> modifies;

  /// Identites nouvelles (ou revenues apres une suppression).
  final List<String> ajoutes;

  /// Identites disparues, publiees en marqueur de suppression.
  final List<String> retires;

  /// Marqueurs deja publies, conserves parce que la fenetre les couvre encore.
  final List<String> marqueursConserves;

  /// Marqueurs abandonnes : au-dela de la fenetre, un telephone aussi en retard
  /// releve de la copie complete, pas du rattrapage par morceaux.
  final List<String> marqueursPurges;

  /// Nombre d enregistrements qui portent la nouvelle revision.
  int get nombreTouches => modifies.length + ajoutes.length + retires.length;

  /// Vrai si cette publication apporte quelque chose.
  ///
  /// Quand elle n apporte rien, la revision ne doit PAS monter : incrementer
  /// pour rien ferait relire la liste a tous les telephones sans qu aucun n ait
  /// quoi que ce soit a prendre.
  bool get aChange => nombreTouches > 0;
}

/// Un enregistrement sans identite ne peut etre ni corrige ni retire : refus.
class EnregistrementSansIdentite implements Exception {
  const EnregistrementSansIdentite({required this.famille, required this.donnee});

  final String famille;
  final Map<String, dynamic> donnee;

  @override
  String toString() {
    final attendu = famille == MorceauxDeSentier.pointsDeTrace
        ? '`track_id` et `sequence_index` (un point de trace n a pas '
            'd identifiant propre, #R8)'
        : 'un `id` non vide';
    return 'Famille « $famille » : un enregistrement ne porte pas $attendu. '
        'Il serait publie sans identite, donc impossible a corriger et '
        'impossible a retirer par la suite. Enregistrement : $donnee';
  }
}

/// Deux enregistrements de meme identite : la revision de l un ecraserait
/// l autre sur le telephone, en silence.
class IdentiteEnDouble implements Exception {
  const IdentiteEnDouble({required this.famille, required this.identite});

  final String famille;
  final String identite;

  @override
  String toString() =>
      'Famille « $famille » : l identite « $identite » apparait deux fois. '
      'Sur le telephone, la seconde ecraserait la premiere sans que rien ne le '
      'dise — et leurs revisions divergeraient a la publication suivante.';
}
