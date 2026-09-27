import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/config/sentier_distant.dart';
import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

import '../../tool/publication/publicateur.dart';
import '../../tool/publication/revision_selective.dart';
import '../../tool/publication/source_de_sentier.dart';

/// TACHE 607 — L OUTIL QUI FABRIQUE LA LISTE ET LES FICHIERS DE DONNEES.
///
/// TROISIEME EXIGENCE DE CHRISTOPHE DU 27/09 20:11, verbatim : « il faut un
/// processus de creation d un nouveau sentier en base que l appli viendra ajouter
/// a son catalogue en lisant la liste des sentiers disponibles ». Les lots 605 et
/// 606 avaient livre tout le cote application ; RIEN ne fabriquait la liste ni les
/// fichiers. L application savait lire ce que personne ne savait ecrire.
///
/// CE QUE CE FICHIER VERROUILLE EN PREMIER, PARCE QUE C EST LE PIEGE DU LOT : A
/// UNE REPUBLICATION, LA REVISION NE MONTE QUE POUR CE QUI A REELLEMENT CHANGE.
/// Un outil qui reincrementerait tout rendrait le modele de revision de
/// Christophe inutile — chaque telephone retelechargerait le sentier entier pour
/// une altitude corrigee, et les trois lots 605-606-607 auraient produit un
/// rechargement integral deguise en versionnage unitaire.
void main() {
  late Directory bac;
  late String source;
  late String publie;

  setUp(() {
    bac = Directory.systemTemp.createTempSync('publication607');
    source = '${bac.path.replaceAll(r'\', '/')}/source';
    publie = '${bac.path.replaceAll(r'\', '/')}/publie';
    Directory(source).createSync(recursive: true);
    _copierLeMateriel(source);
  });
  tearDown(() => bac.deleteSync(recursive: true));

  Publicateur outil() => Publicateur(
        sortie: publie,
        horloge: DateTime.utc(2026, 9, 28, 0, 30),
      );

  Map<String, dynamic> lireSource() =>
      jsonDecode(File('$source/${SourceDeSentier.nomDuFichier}').readAsStringSync())
          as Map<String, dynamic>;

  void ecrireSource(Map<String, dynamic> contenu) => File(
        '$source/${SourceDeSentier.nomDuFichier}',
      ).writeAsStringSync(jsonEncode(contenu));

  Map<String, dynamic> lirePublication(int revision) => jsonDecode(
        File('$publie/gr_monts_dore/v$revision.json').readAsStringSync(),
      ) as Map<String, dynamic>;

  TrailManifestEntry lireLEntree() {
    final brut = jsonDecode(
      File('$publie/${Publicateur.nomDeLaListe}').readAsStringSync(),
    ) as Map<String, dynamic>;
    return TrailManifest.fromJson(brut).trails.single;
  }

  int revisionDe(Map<String, dynamic> publication, String famille, String id) {
    final brut = publication[famille];
    final donnee = brut is List
        ? brut.cast<Map<String, dynamic>>().firstWhere((e) => e['id'] == id)
        : brut as Map<String, dynamic>;
    return donnee[RevisionDeDonnee.champRevision] as int;
  }

  // =========================================================================
  // 1. LE PIEGE DU LOT : LA REVISION SELECTIVE
  // =========================================================================
  group('607 — republier n incremente QUE le modifie', () {
    test('LA PREUVE EXIGEE : une altitude corrigee dans les sources, on '
        'republie, UN SEUL enregistrement change de revision', () async {
      final premiere = outil().publier(source);
      expect(premiere.revision, 1);
      expect(premiere.recalcul.nombreTouches, 19,
          reason: '1 fiche + 1 itineraire + 2 etapes + 2 hebergements + 2 POI '
              '+ 1 entete de trace + 10 points : a la premiere publication tout '
              'est neuf');

      // On corrige UNE altitude, comme le §3.1 de la specification le decrit.
      final contenu = lireSource();
      (contenu['stages'] as List)[0]['elevation_gain'] = 915;
      ecrireSource(contenu);

      final seconde = outil().publier(source);

      expect(seconde.revision, 2);
      expect(seconde.recalcul.nombreTouches, 1,
          reason: 'C EST TOUT L INTERET DU MODELE DE CHRISTOPHE. Si l outil '
              'reincrementait tout, chaque telephone retelechargerait les 19 '
              'enregistrements pour une altitude — et le versionnage unitaire '
              'des lots 605 et 606 ne servirait plus a rien.');
      expect(seconde.recalcul.modifies, ['stages/montsdore-s1']);

      final v2 = lirePublication(2);
      expect(revisionDe(v2, 'stages', 'montsdore-s1'), 2);
      expect(revisionDe(v2, 'stages', 'montsdore-s2'), 1,
          reason: 'l autre etape n a pas bouge : elle GARDE son numero');
      expect(revisionDe(v2, 'itineraries', 'montsdore-i1'), 1);
      expect(revisionDe(v2, 'pois', 'montsdore-p1'), 1);
      expect(revisionDe(v2, 'gpx_tracks', 'montsdore-t1'), 1);
      expect(
        (v2['gpx_points'] as List)
            .cast<Map<String, dynamic>>()
            .map((p) => p[RevisionDeDonnee.champRevision]),
        everyElement(1),
        reason: 'les points de trace sont le gros du volume : ce sont eux qu il '
            'ne faut surtout pas faire redescendre pour une etape corrigee',
      );
    });

    test('LA FICHE DU SENTIER NE SE REINCREMENTE PAS TOUTE SEULE — '
        '`data_version` est du bookkeeping, pas du contenu', () async {
      outil().publier(source);
      final contenu = lireSource();
      (contenu['stages'] as List)[0]['elevation_gain'] = 915;
      ecrireSource(contenu);
      outil().publier(source);

      final v2 = lirePublication(2);
      final meta = v2['trail_meta'] as Map<String, dynamic>;
      expect(meta['data_version'], 2,
          reason: 'la revision courante du sentier suit : le semeur et la pose '
              'la lisent');
      expect(meta[RevisionDeDonnee.champRevision], 1,
          reason: 'MESURE FAITE PENDANT LE LOT : tant que `data_version` entrait '
              'dans la comparaison de contenu, `trail_meta` descendait a CHAQUE '
              'republication — deux enregistrements pour une altitude corrigee '
              'au lieu d un. Aucune decision ne lit `trail_meta.data_version` '
              '(le repere qui fait foi est `trail_manifests.localVersion`), '
              'donc c est bien du bookkeeping.');
    });

    test('LE STATUT, LUI, EST DU CONTENU : le passer a `archived` fait monter '
        'la revision de la fiche', () async {
      outil().publier(source);
      final contenu = lireSource()..['status'] = 'archived';
      ecrireSource(contenu);

      final seconde = outil().publier(source);

      expect(seconde.recalcul.modifies, ['trail_meta/gr-monts-dore']);
      expect(revisionDe(lirePublication(2), 'trail_meta', 'gr-monts-dore'), 2,
          reason: 'un sentier retire doit le DIRE aux telephones deja a jour');
    });

    test('RIEN N A CHANGE : aucun fichier reecrit, et la revision NE MONTE PAS',
        () async {
      outil().publier(source);
      final resultat = outil().publier(source);

      expect(resultat.donneesReecrites, isFalse);
      expect(resultat.revision, 1);
      expect(resultat.recalcul.aChange, isFalse);
      expect(File('$publie/gr_monts_dore/v2.json').existsSync(), isFalse,
          reason: 'incrementer pour rien ferait relire la liste a tous les '
              'telephones, pour n avoir rien a prendre');
      expect(lireLEntree().dataVersion, 1);
    });

    test('UN REORDONNANCEMENT DU FICHIER SOURCE NE FAIT MONTER AUCUNE '
        'REVISION — les clefs sont comparees triees', () async {
      outil().publier(source);

      final contenu = lireSource();
      final etapes = (contenu['stages'] as List).cast<Map<String, dynamic>>();
      // Meme donnee, clefs dans l autre sens, et un entier ecrit en decimal.
      contenu['stages'] = [
        for (final etape in etapes)
          <String, dynamic>{
            for (final clef in etape.keys.toList().reversed)
              clef: clef == 'elevation_gain'
                  ? (etape[clef] as int).toDouble()
                  : etape[clef],
          }
      ];
      ecrireSource(contenu);

      final resultat = outil().publier(source);
      expect(resultat.recalcul.aChange, isFalse,
          reason: '`820` et `820.0` designent le meme denivele : les distinguer '
              'ferait monter une revision pour une virgule, exactement le '
              'gaspillage que ce modele existe pour supprimer');
    });

    test('LE MEME SOURCE PRODUIT LES MEMES OCTETS — la publication est '
        'reproductible, donc son empreinte aussi', () async {
      final premier = outil().publier(source);
      final octets = File('$publie/${premier.cheminDonnees}').readAsBytesSync();

      final ailleurs = '${bac.path.replaceAll(r'\', '/')}/publie2';
      final second = Publicateur(
        sortie: ailleurs,
        horloge: DateTime.utc(2026, 9, 28, 0, 30),
      ).publier(source);

      expect(second.empreinte, premier.empreinte);
      expect(File('$ailleurs/${second.cheminDonnees}').readAsBytesSync(),
          octets);
    });
  });

  // =========================================================================
  // 2. LES SUPPRESSIONS ET LA FENETRE DE RETENTION (#X5)
  // =========================================================================
  group('607 — ce qui disparait, et jusqu a quand on le dit', () {
    test('UN POI RETIRE DES SOURCES DEVIENT UN MARQUEUR DE SUPPRESSION — un '
        'numero qui monte ne transmet pas une absence', () async {
      outil().publier(source);

      final contenu = lireSource();
      (contenu['pois'] as List).removeWhere((p) => p['id'] == 'montsdore-p1');
      ecrireSource(contenu);

      final resultat = outil().publier(source);

      expect(resultat.recalcul.retires, ['pois/montsdore-p1']);
      final marqueur = (lirePublication(2)['pois'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((p) => p['id'] == 'montsdore-p1');
      expect(marqueur[RevisionDeDonnee.champSupprime], isTrue);
      expect(marqueur[RevisionDeDonnee.champRevision], 2);
      expect(marqueur.keys, containsAll(['id', 'rev', 'supprime']));
      expect(marqueur.containsKey('name_fr'), isFalse,
          reason: 'un marqueur ne porte que son identite (#R7) : la donnee '
              'n existe plus, la republier en entier serait trompeur');
    });

    test('UN POINT DE TRACE RETIRE PORTE `track_id` ET `sequence_index` — il n a '
        'pas d identifiant propre (#R8)', () async {
      outil().publier(source);

      final contenu = lireSource();
      // La trace vient du GPX : on la remplace par une trace plus courte.
      contenu.remove('trace_depuis_gpx');
      contenu['gpx_tracks'] = [
        {
          'id': 'montsdore-t1',
          'itinerary_id': 'montsdore-i1',
          'name': 'Tour des Monts Dore (fictif)',
        }
      ];
      contenu['gpx_points'] = [
        for (var i = 0; i < 8; i++)
          {
            'track_id': 'montsdore-t1',
            'sequence_index': i,
            'lat': _traceDeReference[i][0],
            'lng': _traceDeReference[i][1],
            'elevation': _traceDeReference[i][2],
          }
      ];
      ecrireSource(contenu);

      final resultat = outil().publier(source);

      expect(resultat.recalcul.retires,
          ['gpx_points/montsdore-t1#8', 'gpx_points/montsdore-t1#9']);
      final marqueurs = (lirePublication(2)['gpx_points'] as List)
          .cast<Map<String, dynamic>>()
          .where((p) => p[RevisionDeDonnee.champSupprime] == true)
          .toList();
      expect(marqueurs, hasLength(2));
      expect(marqueurs.first['track_id'], 'montsdore-t1');
      expect(marqueurs.first['sequence_index'], 8);
      expect(marqueurs.first.containsKey('id'), isFalse);
    });

    test('LA FENETRE DE RETENTION : un marqueur est conserve dix revisions puis '
        'PURGE — et c est le meme nombre que celui sur lequel l application '
        'exige une copie complete', () async {
      outil().publier(source);

      // Revision 2 : le POI disparait, son marqueur apparait.
      final sansPoi = lireSource();
      (sansPoi['pois'] as List).removeWhere((p) => p['id'] == 'montsdore-p1');
      ecrireSource(sansPoi);
      outil().publier(source);

      // Revisions 3 a 12 : une modification par revision, ailleurs.
      for (var i = 3; i <= 12; i++) {
        final contenu = lireSource();
        (contenu['stages'] as List)[0]['elevation_gain'] = 800 + i;
        ecrireSource(contenu);
        final resultat = outil().publier(source);
        expect(resultat.revision, i);

        final marqueurs = (lirePublication(i)['pois'] as List)
            .cast<Map<String, dynamic>>()
            .where((p) => p[RevisionDeDonnee.champSupprime] == true);

        if (i - 2 < RevisionDeDonnee.fenetreDeRetention) {
          expect(marqueurs, hasLength(1),
              reason: 'revision $i : le marqueur de la revision 2 est encore '
                  'dans la fenetre de ${RevisionDeDonnee.fenetreDeRetention}, '
                  'donc un telephone reste a la revision 1 le recevra');
        } else {
          expect(marqueurs, isEmpty,
              reason: 'revision $i : le marqueur de la revision 2 sort de la '
                  'fenetre. Un telephone encore a la revision 1 a desormais un '
                  'retard de ${i - 1} revisions : il releve de la COPIE '
                  'COMPLETE, pas du rattrapage par morceaux.');
          expect(
            RevisionDeDonnee.exigeUneCopieComplete(
              revisionLocale: 1,
              revisionCible: i,
            ),
            isTrue,
            reason: 'LES DEUX MOITIES DE LA REGLE SE REJOIGNENT : l outil purge '
                'exactement quand l application bascule en copie complete. Deux '
                'constantes independantes auraient donne un decalage '
                'silencieux, et du mauvais cote.',
          );
        }
      }
    });

    test('UN ENREGISTREMENT QUI REVIENT APRES SA SUPPRESSION REPREND LA '
        'NOUVELLE REVISION — le telephone ne l a plus', () async {
      outil().publier(source);
      final complet = lireSource();

      final sansPoi = lireSource();
      (sansPoi['pois'] as List).removeWhere((p) => p['id'] == 'montsdore-p1');
      ecrireSource(sansPoi);
      outil().publier(source);

      ecrireSource(complet);
      final resultat = outil().publier(source);

      expect(resultat.recalcul.ajoutes, ['pois/montsdore-p1']);
      expect(revisionDe(lirePublication(3), 'pois', 'montsdore-p1'), 3);
    });
  });

  // =========================================================================
  // 3. L INTEGRITE, COTE OUTIL (#X6)
  // =========================================================================
  group('607 — l empreinte et la taille sont CALCULEES, puis VERIFIABLES', () {
    test('L ENTREE DE LISTE PORTE L EMPREINTE DES OCTETS REELLEMENT ECRITS, et '
        'la taille annoncee est la vraie', () async {
      final resultat = outil().publier(source);
      final octets = File('$publie/${resultat.cheminDonnees}').readAsBytesSync();
      final entree = lireLEntree();

      expect(entree.hash, EmpreinteDePublication.de(octets));
      expect(entree.hash, hasLength(EmpreinteDePublication.longueurHex));
      expect(entree.fileSize, octets.length);
      expect(entree.dataVersion, 1);
      expect(entree.filePath, 'gr_monts_dore/v1.json');
      expect(entree.fiche, isNotNull,
          reason: 'SANS FICHE, UN SENTIER NEUF EST INVISIBLE (#M9) : c etait le '
              'mur du lot 605');
      expect(entree.fiche!.displayName, 'Tour des Monts Dore');
    });

    test('UN FICHIER TRONQUE APRES PUBLICATION EST DETECTE PAR `verifier` — '
        'avant le depot, ou il ne coute rien', () async {
      final resultat = outil().publier(source);
      expect(outil().verifier(), isEmpty);

      final fichier = File('$publie/${resultat.cheminDonnees}');
      final complet = fichier.readAsStringSync();
      // Un fichier coupe qui reste du JSON valide : on retire un point de trace.
      final ampute = jsonDecode(complet) as Map<String, dynamic>;
      (ampute['gpx_points'] as List).removeLast();
      fichier.writeAsStringSync(jsonEncode(ampute));

      final anomalies = outil().verifier();
      expect(anomalies, isNotEmpty);
      expect(anomalies.join('\n'), contains('EMPREINTE NON CONFORME'));
    });

    test('UNE ENTREE QUI POINTE SUR UN FICHIER ABSENT EST DETECTEE (#P1)',
        () async {
      final resultat = outil().publier(source);
      File('$publie/${resultat.cheminDonnees}').deleteSync();

      expect(outil().verifier().join('\n'), contains('absent du depot'));
    });

    test('`verifier` REFUSE une liste dont la revision est inferieure a celle '
        'des enregistrements qu elle publie', () async {
      final resultat = outil().publier(source);
      final fichier = File('$publie/${resultat.cheminDonnees}');
      final donnees = jsonDecode(fichier.readAsStringSync())
          as Map<String, dynamic>;
      (donnees['stages'] as List)[0][RevisionDeDonnee.champRevision] = 9;
      final corps = jsonEncode(donnees);
      fichier.writeAsStringSync(corps);

      // On remet une empreinte coherente : c est l incoherence de REVISION qu on
      // veut voir, pas celle de l empreinte.
      final liste = File('$publie/${Publicateur.nomDeLaListe}');
      final brut = jsonDecode(liste.readAsStringSync()) as Map<String, dynamic>;
      (brut['trails'] as List)[0]['hash'] =
          EmpreinteDePublication.duTexte(corps);
      (brut['trails'] as List)[0]['fileSize'] = utf8.encode(corps).length;
      liste.writeAsStringSync(jsonEncode(brut));

      final anomalies = outil().verifier().join('\n');
      expect(anomalies, contains('revision 9'));
      expect(anomalies, contains('ne le prendrait JAMAIS'));
    });
  });

  // =========================================================================
  // 4. CE QUE L OUTIL REFUSE DE PUBLIER
  // =========================================================================
  group('607 — l outil refuse ce qui casserait la copie sur le telephone', () {
    void refuse(void Function(Map<String, dynamic> contenu) abimer, Matcher motif) {
      final contenu = lireSource();
      abimer(contenu);
      ecrireSource(contenu);
      expect(
        () => outil().publier(source),
        throwsA(isA<Exception>().having((e) => e.toString(), 'motif', motif)),
      );
      expect(Directory(publie).existsSync(), isFalse,
          reason: 'un refus n ecrit RIEN : ni fichier de donnees, ni liste');
    }

    test('une trace rattachee a un itineraire non publie — la carte serait '
        'MUETTE et rien cote application ne peut le rattraper (#S8)', () {
      refuse(
        (c) => (c['trace_depuis_gpx'] as Map)['itinerary_id'] = 'inexistant',
        contains('n est pas un itineraire publie'),
      );
    });

    test('une etape sans les CINQ langues (#S9, piege #A13 du MODOP 603)', () {
      refuse(
        (c) => (c['stages'] as List)[0].remove('name_es'),
        contains('name_es'),
      );
    });

    test('une fiche qui annonce plus d etapes que le fichier n en publie — la '
        'carte du catalogue est ce sur quoi le randonneur decide', () {
      refuse(
        (c) => (c['fiche'] as Map)['totalStages'] = 12,
        contains('la fiche annonce 12 etape(s)'),
      );
    });

    test('un sentier sans fiche : il serait INVISIBLE au catalogue (#M9)', () {
      refuse((c) => c.remove('fiche'), contains('INVISIBLE'));
    });

    test('une source qui porte elle-meme des revisions : deux autorites sur le '
        'meme numero, et la plus silencieuse gagne', () {
      refuse(
        (c) => (c['stages'] as List)[0][RevisionDeDonnee.champRevision] = 7,
        contains('LA SOURCE NE PORTE PAS LES REVISIONS'),
      );
    });

    test('des coordonnees inversees qui mettent le randonneur dans la mer', () {
      refuse(
        (c) => (c['stages'] as List)[0]['start_lat'] = 182.0,
        contains('hors du monde'),
      );
    });

    test('deux enregistrements de meme identite', () {
      refuse(
        (c) => (c['pois'] as List).add(
          Map<String, dynamic>.from((c['pois'] as List)[0] as Map),
        ),
        contains('apparait deux fois'),
      );
    });

    test('une entree de liste seule declaree `active` : une carte au catalogue '
        'que personne ne peut telecharger', () {
      refuse(
        (c) => c['liste_seulement'] = true,
        contains('apparaitrait au catalogue'),
      );
    });

    test('un sentier sans trace : depuis la tache 606 c est ce qui le rend '
        'MARCHABLE, et c est obligatoire (#F15)', () {
      refuse(
        (c) => c.remove('trace_depuis_gpx'),
        contains('aucune trace'),
      );
    });
  });

  // =========================================================================
  // 5. LE RETRAIT QUI SE DIT (#M6, #M10) — LE CAS DU SENTIER DES PYRENEES
  // =========================================================================
  group('607 — retirer du catalogue un sentier COMPILE, sans republier '
      'l application', () {
    test('une entree de liste SEULE, en `draft`, sans fichier de donnees', () {
      final pyrenees = '${bac.path.replaceAll(r'\', '/')}/pyrenees';
      Directory(pyrenees).createSync(recursive: true);
      File('$pyrenees/${SourceDeSentier.nomDuFichier}').writeAsStringSync(
        jsonEncode(_sourceDesPyrenees),
      );

      final resultat = Publicateur(
        sortie: publie,
        horloge: DateTime.utc(2026, 9, 28),
      ).publier(pyrenees);

      expect(resultat.listeSeulement, isTrue);
      expect(resultat.donneesReecrites, isFalse);

      final entree = lireLEntree();
      expect(entree.status, 'draft');
      expect(entree.estActive, isFalse,
          reason: 'UN SENTIER COMPILE ABSENT DE LA LISTE EST CONSERVE au '
              'catalogue (#M10) : le retrait doit se DIRE. C est ce que rien ne '
              'savait fabriquer avant ce lot, et c est ce qui sort du catalogue '
              'un sentier qui n a pas de donnees.');
      expect(entree.filePath, isEmpty);
      expect(entree.fiche, isNotNull,
          reason: 'la fiche reste, pour le jour ou le statut repasse a active');
    });

    test('la source des Pyrenees DU DEPOT est valide et produit bien un '
        'retrait — ce n est pas une source inventee pour le test', () {
      final resultat = Publicateur(
        sortie: publie,
        horloge: DateTime.utc(2026, 9, 28),
      ).publier('publication/sources/gr-pyrenees');

      expect(resultat.trailId, 'gr-pyrenees');
      expect(resultat.listeSeulement, isTrue);
      expect(lireLEntree().status, 'draft');
    });
  });

  // =========================================================================
  // 6. L IDENTITE ET L EMPREINTE DE CONTENU, EN DIRECT
  // =========================================================================
  group('607 — identite et empreinte de contenu', () {
    test('l identite d un point de trace est le couple trace + rang', () {
      expect(
        RevisionSelective.identite(MorceauxDeSentier.pointsDeTrace, const {
          'track_id': 't1',
          'sequence_index': 3,
        }),
        't1#3',
      );
      expect(
        RevisionSelective.identite(
            MorceauxDeSentier.pointsDeTrace, const {'track_id': 't1'}),
        isNull,
        reason: 'sans rang, deux points du meme trace seraient indiscernables',
      );
    });

    test('l empreinte de contenu ignore `rev` et `supprime`, sinon la decision '
        'dependrait de sa propre sortie', () {
      const nue = {'id': 'a', 'lat': 1.0};
      expect(
        RevisionSelective.empreinteDeContenu(nue),
        RevisionSelective.empreinteDeContenu(
          {...nue, 'rev': 7, 'supprime': false},
        ),
      );
    });
  });
}

// ---------------------------------------------------------------------------
// LE MATERIEL — UN SENTIER INVENTE DE ZERO
// ---------------------------------------------------------------------------

/// Copie le materiel de test dans un bac a sable jetable.
///
/// Il vit sous `test/fixtures/publication/`, JAMAIS sous
/// `publication/sources/` : une donnee inventee ne doit pas pouvoir etre
/// deposee par megarde sur le serveur.
void _copierLeMateriel(String vers) {
  const depuis = 'test/fixtures/publication/gr-monts-dore';
  for (final nom in const ['sentier.json', 'trace.gpx']) {
    File('$depuis/$nom').copySync('$vers/$nom');
  }
}

/// Les dix points du GPX de reference, pour reconstruire une trace plus courte.
const List<List<double>> _traceDeReference = <List<double>>[
  [45.53, 2.8, 1050.0],
  [45.534, 2.807, 1180.0],
  [45.5385, 2.8135, 1340.0],
  [45.542, 2.819, 1520.0],
  [45.546, 2.824, 1685.0],
  [45.5505, 2.8295, 1820.0],
  [45.555, 2.836, 1730.0],
  [45.56, 2.843, 1595.0],
  [45.5655, 2.85, 1410.0],
  [45.571, 2.8575, 1260.0],
];

const Map<String, dynamic> _sourceDesPyrenees = <String, dynamic>{
  'status': 'draft',
  'liste_seulement': true,
  'trail_meta': {'id': 'gr-pyrenees', 'code': 'PYRENEES'},
  'fiche': {
    'name': 'GR Pyrenees',
    'displayName': 'Traversee des Pyrenees',
    'tagline': 'D un versant a l autre de la chaine',
    'region': 'Pyrenees',
    'country': 'France',
    'totalStages': 12,
    'totalDistanceKm': 248.0,
    'totalElevationGain': 16800,
  },
};
