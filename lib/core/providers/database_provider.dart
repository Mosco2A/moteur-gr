/// LA BASE DE STEPWAYS VIT DANS UN FICHIER (tache 613, GO-72 de Christophe).
///
/// ---------------------------------------------------------------------------
/// CE QUI ETAIT LA AVANT, ET CE QUE CA COUTAIT
/// ---------------------------------------------------------------------------
///
/// Ce fichier ouvrait la base avec `NativeDatabase.memory()`. Pas dans un test :
/// ICI, dans `lib/`, donc sur le telephone du randonneur. La base vivait dans la
/// memoire vive du processus et disparaissait avec lui. Un randonneur remplissait
/// sa fiche medicale, marchait ses etapes, ecrivait son journal, telechargeait
/// son sentier — il fermait l'application et tout etait parti.
///
/// LA NUANCE QUI COMPTE, ET IL NE FAUT PAS LA PERDRE : les achats faits au
/// magasin n'etaient PAS perdus. La transaction vit chez Google ou chez Apple, et
/// la restauration des achats la ramene. Ce qui disparaissait, c'etait NOTRE
/// comptabilite a nous — le solde d'etapes de la cagnotte — et surtout tout ce
/// que le randonneur avait FAIT. Il ne perdait pas son argent : il perdait sa
/// randonnee.
///
/// LE COMMENTAIRE QUI ETAIT ICI DISAIT L'INVERSE DU CODE. Il disait « en mode
/// test, overrider ce provider avec une DB in-memory » alors que la base ETAIT en
/// memoire en production. C'est le motif des commentaires menteurs : la phrase
/// decrivait l'intention de quelqu'un, pas ce que la machine faisait.
///
/// ---------------------------------------------------------------------------
/// POURQUOI [LazyDatabase], ET CE N'EST PAS UN DETAIL DE STYLE
/// ---------------------------------------------------------------------------
///
/// Resoudre le repertoire de documents est asynchrone (canal de methode vers la
/// plateforme) alors qu'un `Provider` Riverpod est synchrone. [LazyDatabase]
/// resout cette tension : le chemin n'est cherche qu'a la PREMIERE requete.
///
/// Effet de bord voulu et mesure : un test de widgets qui construit un ecran sans
/// jamais interroger la base ne declenche aucun appel a `path_provider` et reste
/// donc vert sans rien surcharger. Seuls les tests qui LISENT VRAIMENT la base
/// doivent surcharger [databaseProvider] — ce que 59 fichiers de tests faisaient
/// deja, et c'est precisement pour cela que le defaut a survecu des mois : tout
/// le monde travaillait sur une base substituee, personne sur la vraie.
///
/// ---------------------------------------------------------------------------
/// POURQUOI SQLITE RESTE SUR L'ISOLAT COURANT, ET C'EST UNE MESURE
/// ---------------------------------------------------------------------------
///
/// Drift propose `NativeDatabase.createInBackground`, qui fait tourner SQLite
/// dans un isolat dedie — recommande pour ne pas geler l'interface pendant une
/// grosse ecriture. CE N'EST PAS CE QUI EST UTILISE ICI, ET LA RAISON EST
/// MESUREE : avec l'isolat d'arriere-plan, CINQ tests d'ecrans restaient bloques
/// sur leur etat de chargement (« Reessayer » jamais rendu, « PARTAGER AVEC LE
/// GROUPE » introuvable). `pumpAndSettle` avance des frames jusqu'a ce que plus
/// rien ne soit programme ; il n'attend pas un travail qui se fait DANS UN AUTRE
/// ISOLAT. L'ecran n'avait donc jamais sa donnee.
///
/// C'est un artefact de test, pas un defaut de production — mais l'arbitrage lui
/// est reel : ce lot existe PARCE QUE personne n'exercait le vrai provider. Un
/// executeur que les tests d'ecrans ne peuvent pas suivre nous ramenerait a la
/// situation d'avant, ou tout le monde surcharge la base et ou plus personne ne
/// regarde la vraie.
///
/// LE COUT EST NOMME, PAS IGNORE. La plus grosse ecriture est le semeur du
/// sentier embarque (7 etapes, 20 points d'interet, 53 points de trace pour
/// `mare-a-mare-centre`), et elle se fait derriere l'ecran de chargement du
/// demarrage. Passer a l'isolat d'arriere-plan reste souhaitable le jour ou un
/// sentier tres long rendra l'ecriture visible : cela demande un harnais de test
/// capable d'attendre un autre isolat. POINT OUVERT, ecrit ici pour ne pas etre
/// redecouvert.
///
/// ---------------------------------------------------------------------------
/// CE QUI N'EST DELIBEREMENT PAS ACTIVE : LE JOURNAL WAL
/// ---------------------------------------------------------------------------
///
/// SQLite reste en mode `delete` (le defaut). Le mode WAL laisserait en
/// permanence un `-wal` et un `-shm` a cote du fichier ; la sauvegarde du
/// telephone emporterait le `.sqlite` sans forcement emporter un `-wal` coherent
/// avec lui, et le randonneur restaurerait une base en retard sur elle-meme. Ce
/// fichier est justement celui qu'on veut voir remonter intact sur le nouveau
/// telephone (voir [SauvegardeSysteme]) : on prefere la simplicite d'un fichier
/// unique a un gain d'ecriture concurrente dont une application de randonnee
/// mono-utilisateur n'a pas l'usage.
library;

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../data/database.dart';

/// Nom du fichier de la base, dans le repertoire de documents de l'application.
///
/// Sur Android : `app_flutter/stepways.sqlite` (domaine `root` des regles de
/// sauvegarde — PAS le domaine `database`, qui designe
/// `/data/data/<paquet>/databases/` la ou Android range les bases ouvertes par
/// son propre `SQLiteOpenHelper`, et ou Flutter n'ecrit jamais). Sur iPhone :
/// `Documents/stepways.sqlite`.
const String kFichierBaseStepWays = 'stepways.sqlite';

/// Ouvre la base SUR UN FICHIER, durablement.
///
/// AUCUNE PORTE DEROBEE POUR LES TESTS, ET C'EST VOULU. Une version precedente
/// de cette fonction acceptait un repertoire injectable. Elle a ete retiree :
/// personne ne s'en servait, et surtout un test qui passe par une porte a lui ne
/// prouve rien du chemin reel. Les tests de persistance simulent LE TELEPHONE
/// (le canal de methode de `path_provider`, voir `flutter_test_config.dart`), si
/// bien que cette fonction s'execute chez eux EXACTEMENT comme en production.
QueryExecutor ouvrirBaseDurable() {
  return LazyDatabase(() async {
    final base = await getApplicationDocumentsDirectory();
    if (!base.existsSync()) base.createSync(recursive: true);
    return NativeDatabase(File('${base.path}/$kFichierBaseStepWays'));
  });
}

/// Provider singleton de la base Drift — UNE instance pour toute l'application,
/// posee sur un FICHIER (voir l'en-tete de ce fichier).
///
/// Les tests qui interrogent la base la surchargent (`overrideWithValue`) avec
/// `AppDatabase(NativeDatabase.memory())` : c'est LE test qui est en memoire,
/// jamais la production.
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(ouvrirBaseDurable());
  ref.onDispose(() => db.close());
  return db;
});
