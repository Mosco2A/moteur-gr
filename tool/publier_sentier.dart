// Un outil en ligne de commande PARLE sur la sortie standard : c est son
// interface. `avoid_print` vise le code applicatif, ou un print echappe au
// journal et au RGPD ; ici il n y a ni ecran ni utilisateur, seulement un
// terminal et Christophe devant.
// ignore_for_file: avoid_print

import 'dart:io';

import 'publication/publicateur.dart';
import 'publication/revision_selective.dart';
import 'publication/source_de_sentier.dart';

/// PUBLIER UN SENTIER — L OUTIL QUI MANQUAIT (tache 607).
///
/// TROISIEME EXIGENCE DE CHRISTOPHE DU 27/09 20:11, verbatim : « il faut un
/// processus de creation d un nouveau sentier en base que l appli viendra ajouter
/// a son catalogue en lisant la liste des sentiers disponibles ». Les lots 605 et
/// 606 ont livre tout le cote application. Il manquait le cote amont : rien ne
/// fabriquait la liste ni les fichiers de donnees, donc Christophe ne pouvait PAS
/// ajouter un sentier.
///
/// COMMENT ON S EN SERT.
///
/// ```
/// dart run tool/publier_sentier.dart publier  publication/sources/gr-monts-dore
/// dart run tool/publier_sentier.dart publier  --tout
/// dart run tool/publier_sentier.dart verifier
/// ```
///
/// Options : `--sortie <dossier>` (defaut `publication/publie`), `--sources
/// <dossier>` (defaut `publication/sources`, avec `--tout`).
///
/// CE QUE L OUTIL FAIT, ET CE QU IL NE FAIT PAS. Il ecrit deux choses dans le
/// dossier de sortie : le fichier de donnees d un sentier
/// (`<slug>/v<N>.json`), puis la liste (`manifest.json`) — dans cet ordre, parce
/// que l ordre compte (#P1). Il NE DEPOSE RIEN : le dossier de sortie est ce
/// qu on copie tel quel dans l espace de stockage, quand il existera. Le depot
/// reste mecanique, comme la specification le voulait.
///
/// LA SEULE CHOSE QU IL FAUT VRAIMENT COMPRENDRE : A UNE REPUBLICATION, LA
/// REVISION NE MONTE QUE POUR CE QUI A REELLEMENT CHANGE. Corrigez une altitude,
/// republiez : UN enregistrement change de numero, et un telephone deja a jour ne
/// prend que celui-la. Un outil qui reincrementerait tout rendrait le modele de
/// revision inutile — chaque telephone retelechargerait le sentier entier pour
/// une virgule.
Future<void> main(List<String> arguments) async {
  final commande = arguments.isEmpty ? '' : arguments.first;
  final options = _Options.depuis(arguments.skip(1).toList());

  switch (commande) {
    case 'publier':
      exitCode = _publier(options);
    case 'verifier':
      exitCode = _verifier(options);
    default:
      _usage();
      exitCode = 64; // EX_USAGE
  }
}

int _publier(_Options options) {
  final dossiers = options.tout
      ? _sourcesDe(options.sources)
      : options.positionnels;

  if (dossiers.isEmpty) {
    print(options.tout
        ? 'Aucune source dans « ${options.sources} ».'
        : 'Indiquez le dossier source du sentier, ou --tout.');
    return 64;
  }

  final publicateur = Publicateur(sortie: options.sortie);
  var echecs = 0;

  for (final dossier in dossiers) {
    try {
      final resultat = publicateur.publier(dossier);
      _direLaPublication(dossier, resultat);
    } on SourceInvalide catch (e) {
      print('REFUS — $dossier');
      print('  $e');
      echecs++;
    } on EnregistrementSansIdentite catch (e) {
      print('REFUS — $dossier');
      print('  $e');
      echecs++;
    } on IdentiteEnDouble catch (e) {
      print('REFUS — $dossier');
      print('  $e');
      echecs++;
    }
  }

  if (echecs > 0) {
    print('');
    print('$echecs sentier(s) REFUSE(S) : rien n a ete ecrit pour ceux-la.');
    return 1;
  }

  print('');
  print('Depot pret dans « ${options.sortie} ». Ordre de copie : les fichiers '
      'de donnees D ABORD, « ${Publicateur.nomDeLaListe} » ENSUITE (#P1).');
  return 0;
}

void _direLaPublication(String dossier, ResultatDePublication r) {
  if (r.listeSeulement) {
    print('${r.trailId} — entree de liste SEULE, aucun fichier de donnees.');
    print('  Le sentier est retire du catalogue tant que son statut n est pas '
        '« active » (#M6), meme s il est compile dans l application.');
    return;
  }

  if (!r.donneesReecrites) {
    print('${r.trailId} — RIEN A PUBLIER : aucune donnee n a change.');
    print('  Revision maintenue a ${r.revision}. Incrementer pour rien ferait '
        'relire la liste a tous les telephones sans rien a prendre.');
    if (r.ficheRafraichie) {
      print('  (fiche ou statut rafraichis dans la liste, sans toucher aux '
          'donnees ni a la revision)');
    }
    return;
  }

  final rc = r.recalcul;
  print('${r.trailId} — revision ${r.revision}, ${r.octets} octets');
  print('  ${r.cheminDonnees}  sha256 ${r.empreinte}');
  print('  ${rc.nombreTouches} enregistrement(s) a la revision ${r.revision} : '
      '${rc.modifies.length} modifie(s), ${rc.ajoutes.length} ajoute(s), '
      '${rc.retires.length} retire(s).');
  if (rc.modifies.isNotEmpty) print('  modifies : ${_extrait(rc.modifies)}');
  if (rc.retires.isNotEmpty) {
    print('  retires (marqueurs) : ${_extrait(rc.retires)}');
  }
  if (rc.marqueursConserves.isNotEmpty) {
    print('  ${rc.marqueursConserves.length} marqueur(s) conserve(s) dans la '
        'fenetre de retention.');
  }
  if (rc.marqueursPurges.isNotEmpty) {
    print('  ${rc.marqueursPurges.length} marqueur(s) purge(s) — au-dela de la '
        'fenetre, un telephone aussi en retard releve de la COPIE COMPLETE.');
  }
}

int _verifier(_Options options) {
  final anomalies = Publicateur(sortie: options.sortie).verifier();
  if (anomalies.isEmpty) {
    print('« ${options.sortie} » : liste et fichiers de donnees CONFORMES — '
        'empreintes, tailles et revisions se correspondent.');
    return 0;
  }
  print('« ${options.sortie} » : ${anomalies.length} anomalie(s).');
  for (final anomalie in anomalies) {
    print('  - $anomalie');
  }
  return 1;
}

List<String> _sourcesDe(String racine) {
  final dossier = Directory(racine);
  if (!dossier.existsSync()) return const [];
  return dossier
      .listSync()
      .whereType<Directory>()
      .map((d) => d.path.replaceAll(r'\', '/'))
      .where((d) => File('$d/${SourceDeSentier.nomDuFichier}').existsSync())
      .toList()
    ..sort();
}

String _extrait(List<String> valeurs) {
  if (valeurs.length <= 6) return valeurs.join(', ');
  return '${valeurs.take(6).join(', ')}… (+${valeurs.length - 6})';
}

void _usage() {
  print('publier_sentier — fabrique la liste des sentiers disponibles et les '
      'fichiers de donnees que l application sait lire.');
  print('');
  print('  dart run tool/publier_sentier.dart publier <dossier-source>');
  print('  dart run tool/publier_sentier.dart publier --tout');
  print('  dart run tool/publier_sentier.dart verifier');
  print('');
  print('  --sortie  <dossier>  depot a copier sur le serveur '
      '(defaut publication/publie)');
  print('  --sources <dossier>  racine des sources avec --tout '
      '(defaut publication/sources)');
}

class _Options {
  _Options({
    required this.sortie,
    required this.sources,
    required this.tout,
    required this.positionnels,
  });

  static _Options depuis(List<String> arguments) {
    var sortie = 'publication/publie';
    var sources = 'publication/sources';
    var tout = false;
    final positionnels = <String>[];

    for (var i = 0; i < arguments.length; i++) {
      final argument = arguments[i];
      switch (argument) {
        case '--tout':
          tout = true;
        case '--sortie':
          sortie = _valeur(arguments, ++i, '--sortie');
        case '--sources':
          sources = _valeur(arguments, ++i, '--sources');
        default:
          if (argument.startsWith('--sortie=')) {
            sortie = argument.split('=').last;
          } else if (argument.startsWith('--sources=')) {
            sources = argument.split('=').last;
          } else {
            positionnels.add(argument.replaceAll(r'\', '/'));
          }
      }
    }

    return _Options(
      sortie: sortie,
      sources: sources,
      tout: tout,
      positionnels: positionnels,
    );
  }

  static String _valeur(List<String> arguments, int index, String nom) {
    if (index >= arguments.length) {
      throw ArgumentError('$nom attend un dossier.');
    }
    return arguments[index].replaceAll(r'\', '/');
  }

  final String sortie;
  final String sources;
  final bool tout;
  final List<String> positionnels;
}
