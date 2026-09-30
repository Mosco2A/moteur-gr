import 'dart:convert';
import 'dart:io';

import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';
import 'package:moteur_gr/features/trek/data/gpx_parser.dart';

/// LA SOURCE D UN SENTIER — CE QUE CHRISTOPHE ECRIT, ET RIEN DE PLUS.
///
/// LE CHOIX QUI GOUVERNE CE FICHIER : LA SOURCE EST LE SCHEMA PUBLIE, MOINS LE
/// BOOKKEEPING DE VERSION. Pas de troisieme format, pas de couche de traduction.
/// Vous ecrivez les sept familles telles que l application les lit ; l outil
/// ajoute les revisions, les marqueurs de suppression, l empreinte, la taille et
/// l entree de liste. Le partage des roles est donc net : VOUS ECRIVEZ LES
/// DONNEES, L OUTIL ECRIT LES REVISIONS.
///
/// POURQUOI PAS UN FORMAT PLUS AGREABLE. Parce que le depot vient de payer le
/// prix d un format de plus. Le piege #Z01 du MODOP 603 — « les deux fichiers du
/// Mare a Mare se contredisent » — est exactement cela : deux ecritures du meme
/// sentier qui divergent. Et la MESURE de la tache 607 est pire que le piege ne
/// le disait : `assets/data/mare_a_mare_centre.json` est en camelCase
/// (`trailId`, `nameFr`, `distanceKm`), lu par `TrailSeeder` ; le fichier PUBLIE
/// est en snake_case (`trail_id`, `name_fr`, `distance_km`), lu par
/// `DeltaUpdateService`. La specification serveur affirmait que « le meme fichier
/// sert aux deux usages » : c est FAUX, mesure a l appui. Un troisieme format
/// aurait ajoute une troisieme divergence.
///
/// LA SOURCE REFUSE DE PORTER UN `rev`. Si la source portait des revisions, deux
/// autorites decideraient du meme numero, et la plus silencieuse gagnerait.
class SourceDeSentier {
  SourceDeSentier._({
    required this.trailId,
    required this.statut,
    required this.fiche,
    required this.donnees,
    required this.listeSeulement,
  });

  /// Nom du fichier de source attendu dans le dossier d un sentier.
  static const String nomDuFichier = 'sentier.json';

  /// Identifiant du sentier — la clef, des deux cotes (#M1).
  final String trailId;

  /// `active`, `draft` ou `archived` (#M6).
  final String statut;

  /// La fiche d affichage, sans laquelle un sentier neuf est invisible (#M9).
  final TrailManifestFiche fiche;

  /// Les familles de donnees, SANS `rev` : la forme du fichier publie.
  final Map<String, dynamic> donnees;

  /// Vrai quand cette source ne publie QUE son entree de liste, sans fichier de
  /// donnees.
  ///
  /// C est le mode qui manquait pour appliquer #M6 et #M10 : retirer du
  /// catalogue un sentier COMPILE se fait en publiant son entree avec un statut
  /// autre que `active`, jamais par omission. Un tel sentier n a rien a
  /// telecharger — et l outil refuse ce mode avec `status: active`, parce qu une
  /// carte au catalogue qu on ne peut pas telecharger est un mensonge.
  final bool listeSeulement;

  /// Lit et VALIDE la source du dossier [dossier].
  ///
  /// Toute incoherence est une exception, jamais un avertissement : la
  /// specification est explicite (#C4) — un champ obligatoire manquant fait
  /// echouer TOUTE la synchronisation du sentier sur le telephone. Autant que
  /// cela echoue ici, ou quelqu un le lit.
  static SourceDeSentier lire(String dossier) {
    final fichier = File('$dossier/$nomDuFichier');
    if (!fichier.existsSync()) {
      throw SourceInvalide(
        'Aucun « $nomDuFichier » dans $dossier. La source d un sentier est un '
        'dossier contenant ce fichier, et facultativement la trace GPX qu il '
        'designe.',
      );
    }

    final Map<String, dynamic> brut;
    try {
      brut = jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
    } catch (e) {
      throw SourceInvalide('« ${fichier.path} » n est pas un objet JSON : $e');
    }

    final meta = _objet(brut, MorceauxDeSentier.fiche);
    final trailId = _texteObligatoire(meta, 'id', 'trail_meta');
    final statut = (brut['status'] as String?) ?? 'active';
    if (!const ['active', 'draft', 'archived'].contains(statut)) {
      throw SourceInvalide(
        'Statut « $statut » inconnu. Seuls `active`, `draft` et `archived` ont '
        'un sens pour l application (#M6).',
      );
    }
    final listeSeulement = brut['liste_seulement'] == true;
    if (listeSeulement && statut == 'active') {
      throw SourceInvalide(
        'Le sentier $trailId se declare « liste_seulement » ET « active » : il '
        'apparaitrait au catalogue sans qu aucune donnee soit telechargeable. '
        'Une entree sans fichier de donnees sert a RETIRER un sentier du '
        'catalogue (#M6), pas a l y mettre.',
      );
    }

    final fiche = _lireFiche(brut, trailId: trailId);
    final donnees = listeSeulement
        ? <String, dynamic>{}
        : _lireDonnees(brut, dossier: dossier, trailId: trailId);

    if (!listeSeulement) {
      _verifierCoherence(donnees, fiche: fiche, trailId: trailId);
    }

    return SourceDeSentier._(
      trailId: trailId,
      statut: statut,
      fiche: fiche,
      donnees: donnees,
      listeSeulement: listeSeulement,
    );
  }

  // -------------------------------------------------------------------------
  // LA FICHE
  // -------------------------------------------------------------------------

  static TrailManifestFiche _lireFiche(
    Map<String, dynamic> brut, {
    required String trailId,
  }) {
    final fiche = brut['fiche'];
    if (fiche is! Map<String, dynamic>) {
      throw SourceInvalide(
        'Le sentier $trailId ne porte pas de « fiche ». SANS FICHE, UN SENTIER '
        'NEUF EST INVISIBLE (#M9) : la carte du catalogue affiche un nom, une '
        'region, une distance et un denivele, et une liste distante qui ne les '
        'porte pas ne peut que versionner un sentier deja compile.',
      );
    }
    for (final obligatoire in const [
      'name',
      'displayName',
      'tagline',
      'region',
      'country',
      'totalStages',
      'totalDistanceKm',
      'totalElevationGain',
    ]) {
      if (fiche[obligatoire] == null) {
        throw SourceInvalide(
          'fiche de $trailId : « $obligatoire » manquant. Sans lui la carte du '
          'catalogue mentirait (#F1 a #F8).',
        );
      }
    }
    try {
      return TrailManifestFiche.fromJson(fiche);
    } catch (e) {
      throw SourceInvalide('fiche de $trailId illisible : $e');
    }
  }

  // -------------------------------------------------------------------------
  // LES DONNEES
  // -------------------------------------------------------------------------

  static Map<String, dynamic> _lireDonnees(
    Map<String, dynamic> brut, {
    required String dossier,
    required String trailId,
  }) {
    final donnees = <String, dynamic>{};

    for (final famille in MorceauxDeSentier.tous) {
      final valeur = brut[famille];
      if (valeur == null) continue;
      donnees[famille] = valeur is Map
          ? Map<String, dynamic>.from(valeur)
          : (valeur as List)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
    }

    final depuisGpx = brut['trace_depuis_gpx'];
    if (depuisGpx is Map<String, dynamic>) {
      _ajouterLaTraceDepuisGpx(
        donnees,
        declaration: depuisGpx,
        dossier: dossier,
        trailId: trailId,
      );
    }

    _refuserLesRevisions(donnees);
    _verifierLesChamps(donnees, trailId: trailId);
    _verifierLesRattachements(donnees, trailId: trailId);
    return donnees;
  }

  /// LA TRACE VIENT D UN .GPX, ET ELLE EST LUE PAR LE PARSEUR DE L APPLICATION.
  ///
  /// C est volontairement le MEME code (`GpxParser` de `features/trek/data`, pur
  /// Dart) que celui qui lit les traces embarquees. Un parseur de plus dans
  /// l outil aurait pu produire une trace legerement differente de celle que
  /// l application lit du meme fichier — et cette classe d ecart est exactement
  /// ce que le lot 606 a passe sa soiree a defaire (trois lecteurs de trace
  /// concurrents, dont un qui perdait 5 points sur 53).
  static void _ajouterLaTraceDepuisGpx(
    Map<String, dynamic> donnees, {
    required Map<String, dynamic> declaration,
    required String dossier,
    required String trailId,
  }) {
    if (donnees.containsKey(MorceauxDeSentier.pointsDeTrace)) {
      throw SourceInvalide(
        '$trailId declare a la fois « trace_depuis_gpx » et « gpx_points ». '
        'Deux sources pour la meme trace divergeront : choisissez.',
      );
    }

    final nomFichier = _texteObligatoire(
      declaration,
      'fichier',
      'trace_depuis_gpx',
    );
    final traceId = _texteObligatoire(declaration, 'id', 'trace_depuis_gpx');
    final itineraireId = _texteObligatoire(
      declaration,
      'itinerary_id',
      'trace_depuis_gpx',
    );

    final fichier = File('$dossier/$nomFichier');
    if (!fichier.existsSync()) {
      throw SourceInvalide(
        '$trailId : la trace « ${fichier.path} » n existe pas. Publier une '
        'entete de trace sans ses points donnerait une carte vide (#F15).',
      );
    }

    final points = GpxParser.parse(fichier.readAsStringSync()).allTrackPoints;
    if (points.length < 2) {
      throw SourceInvalide(
        '$trailId : « $nomFichier » ne contient ${points.length} point(s) de '
        'trace. Une trace de moins de deux points ne dessine rien.',
      );
    }

    donnees[MorceauxDeSentier.traces] = <Map<String, dynamic>>[
      <String, dynamic>{
        'id': traceId,
        'itinerary_id': itineraireId,
        'name': declaration['name'] ?? traceId,
        if (declaration['source_url'] != null)
          'source_url': declaration['source_url'],
      },
    ];
    donnees[MorceauxDeSentier.pointsDeTrace] = <Map<String, dynamic>>[
      for (var i = 0; i < points.length; i++)
        <String, dynamic>{
          'track_id': traceId,
          'sequence_index': i,
          'lat': points[i].lat,
          'lng': points[i].lng,
          'elevation': points[i].altitude,
        },
    ];
  }

  static void _refuserLesRevisions(Map<String, dynamic> donnees) {
    for (final famille in donnees.keys) {
      for (final donnee in _liste(donnees[famille])) {
        if (donnee.containsKey(RevisionDeDonnee.champRevision) ||
            donnee.containsKey(RevisionDeDonnee.champSupprime)) {
          throw SourceInvalide(
            'Famille « $famille » : un enregistrement porte '
            '« ${RevisionDeDonnee.champRevision} » ou '
            '« ${RevisionDeDonnee.champSupprime} ». LA SOURCE NE PORTE PAS LES '
            'REVISIONS — c est l outil qui les calcule, en comparant a la '
            'publication precedente. Deux autorites sur le meme numero, et la '
            'plus silencieuse gagne.',
          );
        }
      }
    }
  }

  /// Les champs obligatoires de chaque famille (#S1 a #S7), LES CINQ LANGUES
  /// COMPRISES (#S9 — c est le piege #A13 du MODOP 603, et il n a pas change).
  static void _verifierLesChamps(
    Map<String, dynamic> donnees, {
    required String trailId,
  }) {
    const langues = ['name_fr', 'name_en', 'name_de', 'name_it', 'name_es'];
    const obligatoires = <String, List<String>>{
      MorceauxDeSentier.fiche: ['id', 'code'],
      MorceauxDeSentier.itineraires: [
        'id',
        'trail_id',
        'code',
        ...langues,
        'distance_km',
        'elevation_gain',
        'stage_count',
      ],
      MorceauxDeSentier.etapes: [
        'id',
        'itinerary_id',
        'stage_number',
        ...langues,
        'start_lat',
        'start_lng',
        'end_lat',
        'end_lng',
        'distance_km',
        'elevation_gain',
        'elevation_loss',
        'duration_minutes',
        'difficulty',
      ],
      MorceauxDeSentier.hebergements: [
        'id',
        'stage_id',
        ...langues,
        'type',
        'lat',
        'lng',
      ],
      MorceauxDeSentier.pointsDInteret: [
        'id',
        'stage_id',
        ...langues,
        'type',
        'lat',
        'lng',
      ],
      MorceauxDeSentier.traces: ['id', 'itinerary_id', 'name'],
      MorceauxDeSentier.pointsDeTrace: [
        'track_id',
        'sequence_index',
        'lat',
        'lng',
        'elevation',
      ],
    };

    for (final famille in donnees.keys) {
      for (final donnee in _liste(donnees[famille])) {
        for (final champ in obligatoires[famille] ?? const <String>[]) {
          if (donnee[champ] == null) {
            throw SourceInvalide(
              '$trailId, famille « $famille » : « $champ » manquant sur '
              '${_designer(famille, donnee)}. Un champ obligatoire absent fait '
              'echouer TOUTE la copie du sentier sur le telephone (#C4).',
            );
          }
        }
        _verifierLesCoordonnees(famille, donnee, trailId: trailId);
      }
    }
  }

  static void _verifierLesCoordonnees(
    String famille,
    Map<String, dynamic> donnee, {
    required String trailId,
  }) {
    const paires = <String, List<List<String>>>{
      MorceauxDeSentier.etapes: [
        ['start_lat', 'start_lng'],
        ['end_lat', 'end_lng'],
      ],
      MorceauxDeSentier.hebergements: [
        ['lat', 'lng'],
      ],
      MorceauxDeSentier.pointsDInteret: [
        ['lat', 'lng'],
      ],
      MorceauxDeSentier.pointsDeTrace: [
        ['lat', 'lng'],
      ],
    };
    for (final paire in paires[famille] ?? const <List<String>>[]) {
      final lat = (donnee[paire[0]] as num?)?.toDouble();
      final lng = (donnee[paire[1]] as num?)?.toDouble();
      if (lat == null || lng == null) continue;
      if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
        throw SourceInvalide(
          '$trailId, famille « $famille » : coordonnees hors du monde sur '
          '${_designer(famille, donnee)} ($lat, $lng). Une latitude et une '
          'longitude inversees mettent le randonneur dans la mer.',
        );
      }
    }
  }

  /// LES RATTACHEMENTS — LA VERIFICATION QUI EVITE UNE CARTE MUETTE.
  ///
  /// #S8 et #F15 le disent tous les deux : l ordre des familles suit les clefs
  /// etrangeres, et « une trace rattachee a un itineraire que le fichier ne
  /// publie pas est INVISIBLE ». Rien, cote application, ne peut rattraper cela :
  /// la pose reussit, la revision locale avance, et la carte reste vide. C est
  /// donc ici que ca se joue.
  static void _verifierLesRattachements(
    Map<String, dynamic> donnees, {
    required String trailId,
  }) {
    final meta = _liste(donnees[MorceauxDeSentier.fiche]).firstOrNull;
    if (meta == null) {
      throw SourceInvalide('$trailId : « trail_meta » manquant.');
    }
    if (meta['id'] != trailId) {
      throw SourceInvalide(
        '$trailId : « trail_meta.id » vaut « ${meta['id']} ». '
        'L identifiant est LA clef (#M1) : il doit etre le meme partout.',
      );
    }

    final itineraires = _identites(donnees, MorceauxDeSentier.itineraires);
    final etapes = _identites(donnees, MorceauxDeSentier.etapes);
    final traces = _identites(donnees, MorceauxDeSentier.traces);

    if (itineraires.isEmpty) {
      throw SourceInvalide(
        '$trailId : aucun itineraire. Les etapes s y rattachent, et la trace '
        'aussi : sans itineraire publie, rien n est visible (#S8).',
      );
    }

    _exigerLeParent(
      donnees,
      MorceauxDeSentier.itineraires,
      'trail_id',
      {trailId},
      'le sentier lui-meme',
      trailId,
    );
    _exigerLeParent(
      donnees,
      MorceauxDeSentier.etapes,
      'itinerary_id',
      itineraires,
      'un itineraire publie',
      trailId,
    );
    _exigerLeParent(
      donnees,
      MorceauxDeSentier.hebergements,
      'stage_id',
      etapes,
      'une etape publiee',
      trailId,
    );
    _exigerLeParent(
      donnees,
      MorceauxDeSentier.pointsDInteret,
      'stage_id',
      etapes,
      'une etape publiee',
      trailId,
    );
    _exigerLeParent(
      donnees,
      MorceauxDeSentier.traces,
      'itinerary_id',
      itineraires,
      'un itineraire publie',
      trailId,
    );
    _exigerLeParent(
      donnees,
      MorceauxDeSentier.pointsDeTrace,
      'track_id',
      traces,
      'une entete de trace publiee',
      trailId,
    );

    // #F15 : publier l entete sans les points, ou l inverse, donne une carte
    // vide alors que tout le reste du sentier fonctionne.
    final aDesTraces = traces.isNotEmpty;
    final aDesPoints = _liste(
      donnees[MorceauxDeSentier.pointsDeTrace],
    ).isNotEmpty;
    if (aDesTraces != aDesPoints) {
      throw SourceInvalide(
        '$trailId : « gpx_tracks » et « gpx_points » vont ensemble. Publier '
        'l un sans l autre donne un sentier complet dont LA TRACE NE S AFFICHE '
        'PAS, et rien cote application ne peut le rattraper (#F15).',
      );
    }
    if (!aDesTraces) {
      throw SourceInvalide(
        '$trailId : aucune trace. Depuis la tache 606 la carte lit la base : '
        'publier « gpx_tracks » ET « gpx_points » est ce qui rend un sentier '
        'MARCHABLE, et c est obligatoire (#F15).',
      );
    }
  }

  static void _exigerLeParent(
    Map<String, dynamic> donnees,
    String famille,
    String champ,
    Set<String> parentsPublies,
    String quoi,
    String trailId,
  ) {
    for (final donnee in _liste(donnees[famille])) {
      final parent = donnee[champ];
      if (parent is String && parentsPublies.contains(parent)) continue;
      throw SourceInvalide(
        '$trailId, famille « $famille » : ${_designer(famille, donnee)} se '
        'rattache a « $parent », qui n est pas $quoi. La copie posera cette '
        'donnee sans que rien ne l affiche (#S8).',
      );
    }
  }

  /// LA FICHE DOIT DIRE LA VERITE SUR LES DONNEES QU ELLE ACCOMPAGNE.
  ///
  /// La carte du catalogue est ce sur quoi le randonneur decide d acheter. Une
  /// fiche qui annonce douze etapes pour un fichier qui en publie six n est pas
  /// une imprecision : c est le piege #Z01 — deux ecritures du meme sentier qui
  /// se contredisent — reconstitue a l interieur d une seule publication.
  static void _verifierCoherence(
    Map<String, dynamic> donnees, {
    required TrailManifestFiche fiche,
    required String trailId,
  }) {
    final etapes = _liste(donnees[MorceauxDeSentier.etapes]);
    if (fiche.totalStages != etapes.length) {
      throw SourceInvalide(
        '$trailId : la fiche annonce ${fiche.totalStages} etape(s) et le '
        'fichier en publie ${etapes.length}. La carte du catalogue est ce sur '
        'quoi le randonneur decide : elle ne peut pas annoncer autre chose que '
        'ce qu il recevra.',
      );
    }
    for (final itineraire in _liste(donnees[MorceauxDeSentier.itineraires])) {
      final annonce = itineraire['stage_count'] as int?;
      final reelles = etapes
          .where((e) => e['itinerary_id'] == itineraire['id'])
          .length;
      if (annonce != null && annonce != reelles) {
        throw SourceInvalide(
          '$trailId, itineraire « ${itineraire['id']} » : « stage_count » vaut '
          '$annonce pour $reelles etape(s) publiee(s).',
        );
      }
    }
  }

  // -------------------------------------------------------------------------
  // OUTILS
  // -------------------------------------------------------------------------

  static Map<String, dynamic> _objet(Map<String, dynamic> brut, String clef) {
    final valeur = brut[clef];
    if (valeur is! Map<String, dynamic>) {
      throw SourceInvalide('« $clef » manquant ou n est pas un objet.');
    }
    return valeur;
  }

  static String _texteObligatoire(
    Map<String, dynamic> objet,
    String clef,
    String ou,
  ) {
    final valeur = objet[clef];
    if (valeur is! String || valeur.isEmpty) {
      throw SourceInvalide('$ou : « $clef » manquant ou vide.');
    }
    return valeur;
  }

  static List<Map<String, dynamic>> _liste(dynamic brut) => [
    if (brut is Map) Map<String, dynamic>.from(brut),
    if (brut is List)
      ...brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
  ];

  static Set<String> _identites(Map<String, dynamic> donnees, String famille) =>
      {
        for (final d in _liste(donnees[famille]))
          if (d['id'] is String) d['id'] as String,
      };

  static String _designer(String famille, Map<String, dynamic> donnee) {
    if (famille == MorceauxDeSentier.pointsDeTrace) {
      return 'le point ${donnee['sequence_index']} de « ${donnee['track_id']} »';
    }
    return '« ${donnee['id']} »';
  }
}

/// Une source qui ne peut pas etre publiee, et POURQUOI.
class SourceInvalide implements Exception {
  const SourceInvalide(this.motif);
  final String motif;
  @override
  String toString() => motif;
}
