import 'dart:convert';
import 'dart:io';

import 'package:moteur_gr/core/data/empreinte_de_publication.dart';
import 'package:moteur_gr/core/data/revision_de_donnee.dart';
import 'package:moteur_gr/core/models/trail_manifest.dart';

import 'revision_selective.dart';
import 'source_de_sentier.dart';

/// LE PUBLICATEUR — CE QUI FABRIQUE LA LISTE ET LES FICHIERS DE DONNEES.
///
/// TROISIEME EXIGENCE DE CHRISTOPHE DU 27/09 20:11, verbatim : « il faut un
/// processus de creation d un nouveau sentier en base que l appli viendra ajouter
/// a son catalogue en lisant la liste des sentiers disponibles ». Les lots 605 et
/// 606 ont fait tout le cote APPLICATION : le catalogue vient du reseau, chaque
/// donnee porte sa revision, le transfert est unitaire, la carte lit la base.
/// RIEN ne fabriquait la liste ni les fichiers. L application savait lire ce que
/// personne ne savait ecrire.
///
/// CE QUE LE PUBLICATEUR PRODUIT, ET C EST EXACTEMENT LES DEUX OBJETS DU §1 DE LA
/// SPECIFICATION SERVEUR :
///  * `manifest.json` — la liste des sentiers disponibles, fiches comprises
///    (#O1, #M9) ;
///  * `<slug>/v<N>.json` — le fichier de donnees d un sentier, chaque
///    enregistrement portant sa revision (#O2, #R1).
///
/// ET IL RESPECTE L ORDRE DE DEPOT (#P1) EN L IMPOSANT : le fichier de donnees
/// est ecrit AVANT la liste. La liste est la seule chose que l application
/// interroge ; la publier en premier ouvre une fenetre ou un randonneur voit un
/// sentier et echoue a le telecharger.
/// L OUTIL EST L AUTORITE DE TEMPS, ET IL EST LA SEULE (tache 610).
///
/// Depuis la decision de Christophe du 28/09 09:32, la revision est un INSTANT. La
/// regle qui rend ce modele juste est qu UNE SEULE machine le pose : le serveur.
/// Cet outil EST le serveur du point de vue du modele — c est lui qui ecrit les
/// fichiers que tous les telephones compareront. Aucun telephone ne pose jamais
/// d horodatage ; le type `HorodatageServeur` le lui interdit a la compilation.
///
/// LE JOUR OU LA BASE SERVEUR EXISTERA, cet instant viendra de son horodatage
/// natif (`serverTimestamp()` chez Firestore, `now()` chez Postgres) et
/// [Publicateur] n aura plus a le poser lui-meme. Rien d autre ne changera : le
/// reste du mecanisme ne connait que « l instant annonce ».
class Publicateur {
  Publicateur({required this.sortie, DateTime? horloge})
    : _horloge = horloge ?? DateTime.now().toUtc();

  /// Nom de la liste publiee.
  static const String nomDeLaListe = 'manifest.json';

  /// Version de schema de la liste (2 depuis la tache 605 : la fiche y est).
  static const int versionDeSchema = 2;

  /// Dossier de depot — ce qui part sur le serveur, tel quel.
  final String sortie;

  final DateTime _horloge;

  /// Vrai si l horloge a du etre corrigee en avant pour rester monotone.
  bool _horlogeCorrigee = false;

  /// L INSTANT DE CETTE PUBLICATION, ET IL DOIT DEPASSER LE PRECEDENT.
  ///
  /// POURQUOI UNE GARDE SUR L HORLOGE DU SERVEUR LUI-MEME. Le modele exige que
  /// chaque publication porte un instant STRICTEMENT posterieur a la precedente :
  /// c est ce qui fait qu un telephone deja a jour prendra la suite. Une horloge
  /// serveur peut pourtant reculer — correction NTP, changement de machine — ou
  /// rendre deux fois la meme milliseconde sur deux publications rapprochees. Une
  /// publication portant un instant anterieur ou egal au precedent serait
  /// INVISIBLE pour tous les telephones deja a jour, definitivement, sans que rien
  /// ne le dise.
  ///
  /// On avance donc d une milliseconde plutot que de refuser le depot, et le fait
  /// est REMONTE dans [ResultatDePublication.horlogeCorrigee] — jamais avale.
  HorodatageServeur _instantApres(HorodatageServeur precedent) {
    final horloge = HorodatageServeur.poseeParLeServeur(_horloge);
    final retenu = horloge.auMoinsApres(precedent);
    if (retenu != horloge) _horlogeCorrigee = true;
    return retenu;
  }

  /// PUBLIE OU REPUBLIE LE SENTIER DECRIT PAR [dossierSource].
  ///
  /// LE PIEGE DE CETTE METHODE, ET C EST TOUT L INTERET DU MODELE : a une
  /// republication, la revision ne monte que pour les enregistrements REELLEMENT
  /// modifies. Le calcul est dans [RevisionSelective] ; ici on se contente de ne
  /// jamais court-circuiter sa reponse — en particulier, quand elle dit « rien n a
  /// change », AUCUN fichier n est reecrit et `dataVersion` NE MONTE PAS.
  /// Incrementer pour rien ferait relire la liste a tous les telephones et,
  /// surtout, laisserait croire qu il y a quelque chose a prendre.
  ResultatDePublication publier(String dossierSource) {
    final source = SourceDeSentier.lire(dossierSource);
    final list = _lireLaListe();
    final precedente = list[source.trailId];

    final revisionPrecedente =
        precedente?.dataVersion ?? RevisionDeDonnee.revisionInitiale;

    if (source.listeSeulement) {
      return _publierLEntreeSeule(
        source,
        list: list,
        precedente: precedente,
        revision: revisionPrecedente == RevisionDeDonnee.revisionInitiale
            ? _instantApres(RevisionDeDonnee.revisionInitiale)
            : revisionPrecedente,
      );
    }

    final publicationPrecedente = _lirePublication(precedente);
    final nouvelleRevision = _instantApres(revisionPrecedente);

    final recalcul = RevisionSelective.calculer(
      donneesSource: _avecLeStatut(source),
      publicationPrecedente: publicationPrecedente,
      revisionPrecedente: revisionPrecedente,
      nouvelleRevision: nouvelleRevision,
    );

    if (!recalcul.aChange && precedente != null) {
      // RIEN N A BOUGE. On ne reecrit rien, et on ne monte pas la revision. La
      // fiche et le statut, eux, ne sont pas versionnes par `rev` : ils sont
      // relus a chaque lecture de liste, donc on les rafraichit si besoin.
      final entree = _entree(
        source,
        revision: revisionPrecedente,
        chemin: precedente.filePath,
        empreinte: precedente.hash,
        octets: precedente.fileSize,
        precedente: precedente,
      );
      final ficheChangee = entree != precedente;
      if (ficheChangee) {
        // ET `lastUpdated` N AVANCE PAS ICI, alors qu il avancait avant la tache
        // 610. C est le point : il designe le MEME instant que `dataVersion`, et
        // les DONNEES n ont pas change. Le faire avancer seul recreerait la
        // divergence que ce lot ferme — deux noms pour un fait, et le plus
        // silencieux qui gagne.
        list[source.trailId] = entree;
        _ecrireLaListe(list);
      }
      return ResultatDePublication(
        trailId: source.trailId,
        revision: revisionPrecedente,
        recalcul: recalcul,
        cheminDonnees: precedente.filePath,
        empreinte: precedente.hash,
        octets: precedente.fileSize,
        donneesReecrites: false,
        ficheRafraichie: ficheChangee,
        horlogeCorrigee: _horlogeCorrigee,
      );
    }

    // 1. LE FICHIER DE DONNEES D ABORD (#P1).
    // LE NOM DU FICHIER PORTE L INSTANT, PAS UN NUMERO — et sous une forme qui
    // tient dans un nom de fichier Windows et dans une URL (l ISO 8601 porte des
    // deux-points, interdits). Elle se trie dans l ordre chronologique, qui est
    // aussi l ordre des publications.
    final chemin =
        '${_dossierDe(source.trailId)}/'
        'v${nouvelleRevision.estampilleDeFichier}.json';
    final corps = _encoder(
      _ordonner(recalcul.donnees, revision: nouvelleRevision),
    );
    final octets = utf8.encode(corps);
    final fichier = File('$sortie/$chemin');
    fichier.parent.createSync(recursive: true);
    fichier.writeAsBytesSync(octets, flush: true);

    // 2. LA LISTE ENSUITE, avec l empreinte des octets REELLEMENT ecrits.
    final empreinte = EmpreinteDePublication.de(octets);
    list[source.trailId] = _entree(
      source,
      revision: nouvelleRevision,
      chemin: chemin,
      empreinte: empreinte,
      octets: octets.length,
      precedente: precedente,
    );
    _ecrireLaListe(list);

    return ResultatDePublication(
      trailId: source.trailId,
      revision: nouvelleRevision,
      recalcul: recalcul,
      cheminDonnees: chemin,
      empreinte: empreinte,
      octets: octets.length,
      donneesReecrites: true,
      ficheRafraichie: true,
      horlogeCorrigee: _horlogeCorrigee,
    );
  }

  /// UNE ENTREE DE LISTE SANS FICHIER DE DONNEES — LE RETRAIT QUI SE DIT (#M10).
  ///
  /// Un sentier COMPILE absent de la liste est CONSERVE au catalogue : c est une
  /// decision assumee du lot 605 (une liste partielle ne doit pas faire
  /// disparaitre des sentiers qui fonctionnent). Le retrait passe donc par une
  /// entree explicite de statut `draft` ou `archived` — et rien, jusqu ici, ne
  /// savait la fabriquer.
  ResultatDePublication _publierLEntreeSeule(
    SourceDeSentier source, {
    required Map<String, TrailManifestEntry> list,
    required TrailManifestEntry? precedente,
    required HorodatageServeur revision,
  }) {
    final entree = _entree(
      source,
      revision: revision,
      chemin: precedente?.filePath ?? '',
      empreinte: precedente?.hash ?? '',
      octets: precedente?.fileSize ?? 0,
      precedente: precedente,
    );
    list[source.trailId] = entree;
    _ecrireLaListe(list);

    return ResultatDePublication(
      trailId: source.trailId,
      revision: revision,
      recalcul: const Recalcul(
        donnees: {},
        modifies: [],
        ajoutes: [],
        retires: [],
        marqueursConserves: [],
        marqueursPurges: [],
      ),
      cheminDonnees: entree.filePath,
      empreinte: entree.hash,
      octets: entree.fileSize,
      donneesReecrites: false,
      ficheRafraichie: true,
      listeSeulement: true,
      horlogeCorrigee: _horlogeCorrigee,
    );
  }

  /// VERIFIE CE QUI EST DEPOSE — LA MOITIE OUTIL DE #X6.
  ///
  /// L autre moitie est dans l application (`SourceFichierEntier` refuse un
  /// fichier dont l empreinte ne correspond pas). Ici on attrape le probleme
  /// AVANT le depot, ou il ne coute rien : un fichier tronque a l ecriture, une
  /// empreinte laissee derriere apres une modification a la main, une entree qui
  /// pointe sur un fichier absent, une revision de liste inferieure a celle que
  /// portent ses propres enregistrements.
  List<String> verifier() {
    final anomalies = <String>[];
    final list = _lireLaListe();

    if (list.isEmpty) {
      anomalies.add('$sortie/$nomDeLaListe : aucune entree.');
      return anomalies;
    }

    for (final entree in list.values) {
      if (entree.fiche == null) {
        anomalies.add(
          '${entree.trailId} : entree sans fiche — elle ne peut que versionner '
          'un sentier deja compile, et sera ECARTEE si le binaire ne le connait '
          'pas (#M9).',
        );
      }
      anomalies.addAll(_verifierLaDateAnnoncee(entree));
      if (entree.filePath.isEmpty) {
        if (entree.status == 'active') {
          anomalies.add(
            '${entree.trailId} : « active » sans fichier de donnees — une carte '
            'au catalogue que personne ne peut telecharger.',
          );
        }
        continue;
      }

      final fichier = File('$sortie/${entree.filePath}');
      if (!fichier.existsSync()) {
        anomalies.add(
          '${entree.trailId} : la liste pointe sur « ${entree.filePath} », '
          'absent du depot. Un randonneur verrait le sentier et echouerait a le '
          'telecharger (#P1).',
        );
        continue;
      }

      final octets = fichier.readAsBytesSync();
      if (!EmpreinteDePublication.correspond(octets, entree.hash)) {
        anomalies.add(
          '${entree.trailId} : EMPREINTE NON CONFORME sur '
          '« ${entree.filePath} ». Annoncee « ${entree.hash} », calculee '
          '« ${EmpreinteDePublication.de(octets)} ». L application REFUSERA la '
          'copie — et c est ce qu on veut : un fichier tronque mais '
          'syntaxiquement valide ne doit pas partir en montagne.',
        );
      }
      if (octets.length != entree.fileSize) {
        anomalies.add(
          '${entree.trailId} : taille annoncee ${entree.fileSize} octet(s) pour '
          '${octets.length} reellement deposes. C est ce chiffre qu on annonce '
          'au randonneur qui paie son forfait (#M5).',
        );
      }

      anomalies.addAll(_verifierLesRevisions(entree, octets));
    }

    return anomalies;
  }

  /// `lastUpdated` ET `dataVersion` DESIGNENT LE MEME INSTANT — ON LE VERIFIE.
  ///
  /// Depuis la tache 610 ces deux champs disent la meme chose. L outil les ecrit
  /// depuis la MEME valeur ([_entree]), donc ils ne peuvent pas diverger par son
  /// fait ; mais un fichier de liste modifie a la main, ou produit par un autre
  /// outil, le pourrait. Et une divergence serait du mauvais cote : un humain
  /// lirait `lastUpdated`, l application deciderait sur `dataVersion`.
  List<String> _verifierLaDateAnnoncee(TrailManifestEntry entree) {
    if (entree.lastUpdated == entree.dataVersion.iso8601) return const [];
    return [
      '${entree.trailId} : « lastUpdated » annonce « ${entree.lastUpdated} » et '
          '« dataVersion » l instant « ${entree.dataVersion.iso8601} ». Depuis la '
          'tache 610 ces deux champs designent le MEME instant : deux valeurs, '
          'c est deux autorites, et celle qui decide (dataVersion) n est pas celle '
          'qu un humain lit.',
    ];
  }

  List<String> _verifierLesRevisions(
    TrailManifestEntry entree,
    List<int> octets,
  ) {
    final anomalies = <String>[];
    final Map<String, dynamic> donnees;
    try {
      donnees = jsonDecode(utf8.decode(octets)) as Map<String, dynamic>;
    } catch (e) {
      return ['${entree.trailId} : « ${entree.filePath} » illisible : $e'];
    }

    var maximum = RevisionDeDonnee.revisionInitiale;
    var sansRevision = 0;
    for (final famille in TrailChunks.tous) {
      final brut = donnees[famille];
      final tous = <Map<String, dynamic>>[
        if (brut is Map) Map<String, dynamic>.from(brut),
        if (brut is List)
          ...brut.whereType<Map>().map((e) => Map<String, dynamic>.from(e)),
      ];
      for (final donnee in tous) {
        if (donnee[RevisionDeDonnee.champRevision] == null) {
          sansRevision++;
          continue;
        }
        final rev = RevisionDeDonnee.revisionDe(
          donnee,
          defaut: RevisionDeDonnee.revisionInitiale,
        );
        if (rev > maximum) maximum = rev;
        if (rev > entree.dataVersion) {
          anomalies.add(
            '${entree.trailId} : un enregistrement de « $famille » porte la '
            'date ${rev.iso8601} alors que la liste annonce '
            '${entree.dataVersion.iso8601}. Un telephone deja a jour ne le '
            'prendrait JAMAIS.',
          );
        }
      }
    }

    if (sansRevision > 0) {
      anomalies.add(
        '${entree.trailId} : $sansRevision enregistrement(s) sans « rev ». Ils '
        'sont rattaches a l instant courant du sentier (#R6), donc ils '
        'REDESCENDENT a chaque publication.',
      );
    }
    if (maximum > RevisionDeDonnee.revisionInitiale &&
        maximum != entree.dataVersion) {
      anomalies.add(
        '${entree.trailId} : la liste annonce l instant '
        '${entree.dataVersion.iso8601} et le plus recent instant publie est '
        '${maximum.iso8601}. L instant courant d un sentier est celui de sa '
        'derniere modification (#M2).',
      );
    }

    return anomalies;
  }

  // -------------------------------------------------------------------------
  // LECTURE / ECRITURE
  // -------------------------------------------------------------------------

  /// UNE ENTREE DE LISTE — ET `lastUpdated` N EST PLUS UN PARAMETRE.
  ///
  /// Depuis la tache 610, `dataVersion` EST la date de derniere mise a jour :
  /// laisser un second champ la redire, renseigne independamment, c etait deux
  /// autorites sur un meme fait — et sur les deux, la plus silencieuse gagne.
  /// `lastUpdated` est donc DERIVE de la revision, ici, a un seul endroit. Il reste
  /// publie parce qu il est lisible et que le retirer de la liste depasserait
  /// « seul le type de la comparaison change » ; mais il ne peut plus diverger, et
  /// [verifier] refuse un depot ou il l aurait fait.
  /// L ENTREE DE LISTE D UN SENTIER, ET ELLE NE DOIT RIEN PERDRE EN CHEMIN.
  ///
  /// [precedente] EST L ENTREE QUE CET APPEL REMPLACE, ET C EST TOUT L OBJET DU
  /// PARAMETRE (tache 761). Trois champs de l entree ne viennent PAS de la
  /// source du sentier : `tilesPath`, `tilesSize` et `tilesHash`, l adresse de
  /// la carte hors ligne, que `tool/cartes_hors_ligne/publier.py` ecrit
  /// directement dans la liste. Les reconstruire depuis la seule source les
  /// laissait donc nuls, et `_ecrireLaListe` les faisait disparaitre :
  /// republier les DONNEES d un sentier effacait l adresse de sa CARTE, sans
  /// un mot.
  ///
  /// C EST EXACTEMENT LE PIEGE QUE L INTEGRATION 647 A FERME DANS L AUTRE
  /// OUTIL, et il etait reste ouvert dans celui-ci. La garde
  /// `pousser_ne_perd_pas_les_cartes_647_test` tient le troisieme maillon — le
  /// manifeste declare vraiment la carte du Mare a Mare Centre — et c est elle
  /// qui a rougi quand la tache 761 a republie le sentier pour y poser la vraie
  /// trace. Deux outils qui ecrivent le meme document doivent chacun preserver
  /// ce que l autre y pose ; sinon le dernier a parler gagne, et personne ne
  /// l apprend avant que la carte ne manque sur un telephone.
  TrailManifestEntry _entree(
    SourceDeSentier source, {
    required HorodatageServeur revision,
    required String chemin,
    required String empreinte,
    required int octets,
    TrailManifestEntry? precedente,
  }) {
    return TrailManifestEntry(
      trailId: source.trailId,
      dataVersion: revision,
      hash: empreinte,
      filePath: chemin,
      fileSize: octets,
      status: source.statut,
      lastUpdated: revision.iso8601,
      fiche: source.fiche,
      tilesPath: precedente?.tilesPath,
      tilesSize: precedente?.tilesSize,
      tilesHash: precedente?.tilesHash,
    );
  }

  Map<String, TrailManifestEntry> _lireLaListe() {
    final fichier = File('$sortie/$nomDeLaListe');
    if (!fichier.existsSync()) return <String, TrailManifestEntry>{};
    final brut = jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
    final manifeste = TrailManifest.fromJson(brut);
    return <String, TrailManifestEntry>{
      for (final entree in manifeste.trails) entree.trailId: entree,
    };
  }

  void _ecrireLaListe(Map<String, TrailManifestEntry> list) {
    final ordonnees = list.keys.toList()..sort();
    final contenu = <String, dynamic>{
      'schemaVersion': versionDeSchema,
      'trails': [for (final id in ordonnees) _sansNul(list[id]!.toJson())],
    };
    final fichier = File('$sortie/$nomDeLaListe');
    fichier.parent.createSync(recursive: true);
    fichier.writeAsBytesSync(utf8.encode(_encoder(contenu)), flush: true);
  }

  Map<String, dynamic>? _lirePublication(TrailManifestEntry? precedente) {
    if (precedente == null || precedente.filePath.isEmpty) return null;
    final fichier = File('$sortie/${precedente.filePath}');
    if (!fichier.existsSync()) return null;
    return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
  }

  /// LE STATUT ENTRE DANS LA COMPARAISON, LA REVISION N Y ENTRE PAS.
  ///
  /// `trail_meta.status` fait partie du CONTENU du sentier : passer de `active` a
  /// `archived` doit descendre sur les telephones, donc doit faire monter la
  /// revision de cet enregistrement. Il est donc injecte AVANT le calcul, sinon
  /// la source (qui ne le porte pas) et la publication precedente (qui le porte)
  /// differeraient a chaque fois pour rien.
  ///
  /// `data_version`, a l inverse, est du bookkeeping : il est ecrit a la
  /// publication et exclu de la comparaison
  /// ([RevisionSelective.champsDeBookkeeping]).
  Map<String, dynamic> _avecLeStatut(SourceDeSentier source) {
    final donnees = <String, dynamic>{...source.donnees};
    final meta = <String, dynamic>{
      ...?(donnees[TrailChunks.fiche] as Map<String, dynamic>?),
    };
    meta['status'] = source.statut;
    donnees[TrailChunks.fiche] = meta;
    return donnees;
  }

  /// Le fichier publie, familles DANS L ORDRE DES CLEFS ETRANGERES.
  ///
  /// L application n en depend plus depuis la tache 606 (`TrailChunks.tous`
  /// impose l ordre a la pose), mais un humain relit ces fichiers : les familles
  /// dans l ordre ou elles s appliquent se lisent, celles dans l ordre
  /// alphabetique se dechiffrent.
  Map<String, dynamic> _ordonner(
    Map<String, dynamic> donnees, {
    required HorodatageServeur revision,
  }) {
    final meta = <String, dynamic>{
      ...?(donnees[TrailChunks.fiche] as Map<String, dynamic>?),
    };
    // La revision courante du sentier, recopiee dans le fichier de donnees :
    // `TrailSeeder` et la pose la lisent. `rev`, lui, vient du calcul selectif et
    // n est PAS ecrase ici — c est tout l interet du lot.
    meta['data_version'] = revision.iso8601;

    return <String, dynamic>{
      TrailChunks.fiche: meta,
      for (final famille in TrailChunks.tous)
        if (famille != TrailChunks.fiche && donnees[famille] != null)
          famille: donnees[famille],
    };
  }

  String _encoder(Object contenu) =>
      '${const JsonEncoder.withIndent('  ').convert(contenu)}\n';

  Map<String, dynamic> _sansNul(Map<String, dynamic> objet) {
    final propre = <String, dynamic>{};
    for (final entree in objet.entries) {
      final valeur = entree.value;
      if (valeur == null) continue;
      propre[entree.key] = valeur is Map<String, dynamic>
          ? _sansNul(valeur)
          : valeur is List
          ? valeur
                .map((e) => e is Map<String, dynamic> ? _sansNul(e) : e)
                .toList()
          : valeur;
    }
    return propre;
  }

  static String _dossierDe(String trailId) => trailId.replaceAll('-', '_');
}

/// CE QU UNE PUBLICATION A FAIT — de quoi le dire a Christophe en trois lignes.
class ResultatDePublication {
  const ResultatDePublication({
    required this.trailId,
    required this.revision,
    required this.recalcul,
    required this.cheminDonnees,
    required this.empreinte,
    required this.octets,
    required this.donneesReecrites,
    required this.ficheRafraichie,
    this.listeSeulement = false,
    this.horlogeCorrigee = false,
  });

  final String trailId;

  /// L INSTANT de cette publication (tache 610).
  final HorodatageServeur revision;
  final Recalcul recalcul;
  final String cheminDonnees;
  final String empreinte;
  final int octets;

  /// Faux quand rien n avait change : aucun fichier reecrit, revision inchangee.
  final bool donneesReecrites;

  /// Vrai quand l entree de liste a ete reecrite (fiche, statut ou revision).
  final bool ficheRafraichie;

  /// Vrai pour une entree de liste sans fichier de donnees (#M6, #M10).
  final bool listeSeulement;

  /// VRAI QUAND L HORLOGE DU SERVEUR A DU ETRE CORRIGEE EN AVANT.
  ///
  /// L instant retenu n est alors pas exactement celui de l horloge : il a ete
  /// avance d une milliseconde pour rester strictement posterieur a la publication
  /// precedente. Ce n est pas grave en soi, mais ca DOIT se dire — une horloge qui
  /// recule sur le serveur de publication est un probleme d infrastructure, et tout
  /// le modele repose sur elle.
  final bool horlogeCorrigee;
}
