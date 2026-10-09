/// LA FICHE MEDICALE D'UNE DEMO VIT EN MEMOIRE, ET ELLE MEURT AVEC ELLE
/// (tache 760).
///
/// ---------------------------------------------------------------------------
/// POURQUOI CE FICHIER EXISTE ALORS QUE LA TACHE 760 PARLAIT DU PROFIL
/// ---------------------------------------------------------------------------
///
/// Le releve de la recette 753 nommait le profil et les randonnees passees. En
/// recensant TOUT ce que la demo peut ecrire, un troisieme formulaire est
/// apparu, et c'est le plus sensible des trois : `/health`, la FICHE MEDICALE,
/// est atteignable en demo depuis la section « Preparer », SANS etre grisee, et
/// un balayage de `lib/features/safety/` ne trouve AUCUNE lecture de
/// [enDemoProvider] : ni dans l'ecran, ni dans le depot, ni dans le fichier.
///
/// Autrement dit : groupe sanguin, allergies, traitements, personne a prevenir
/// et PHOTO DE LA CARTE VITALE pouvaient etre saisis pendant une demonstration
/// et restaient sur le telephone apres la sortie — au moment meme ou
/// l'application promettait que « rien n'est enregistre ».
///
/// ---------------------------------------------------------------------------
/// MEME CHOIX QUE POUR LE PROFIL, ET POUR UNE RAISON DE PLUS
/// ---------------------------------------------------------------------------
///
/// La saisie de la demo vit EN MEMOIRE, elle ne va pas dans un espace a part
/// sur le disque. Le raisonnement entier est dans `profil_volatil_demo.dart`
/// (un arret force ne nettoie pas un espace a part, la memoire part avec le
/// processus). Il vaut ici a plus forte raison : la fiche medicale a son propre
/// dossier exclu de la sauvegarde parce que la tache 613 a juge qu'elle ne
/// devait PAS remonter dans iCloud. Ecrire une fiche de demonstration dans ce
/// dossier, meme pour la reprendre ensuite, serait ecrire une donnee de sante
/// inventee a l'endroit le plus protege de l'application.
///
/// ELLE PART VIDE, ET ELLE NE LIT PAS LE REEL. Meme choix que pour le profil :
/// une demo part vierge, elle montre le parcours de A a Z, et elle ne touche
/// pas — meme pas en lecture — a une donnee de sante. Les DEUX PHOTOS (carte
/// vitale, mutuelle) suivent la meme regle : [saveCard] et [eraseCard] ne
/// touchent plus au disque.
library;

import 'dart:io';

import '../domain/models/health_info.dart';
import 'health_info_file.dart';

/// La fiche medicale pendant une demo : VIDE au depart, tenue EN MEMOIRE, et
/// jetee avec la demo.
class FicheVolatileDeDemo extends HealthInfoFile {
  /// Construit le magasin volatil d'UNE demo.
  FicheVolatileDeDemo();

  /// La fiche de la demo, vide tant que rien n'a ete saisi.
  HealthInfo _cache = const HealthInfo();

  /// Lit la fiche de la demo : la memoire, et rien d'autre.
  @override
  Future<HealthInfo> lire() async => _cache;

  /// N'ECRIT RIEN SUR LE DISQUE. La saisie de la demo reste en memoire.
  @override
  Future<void> ecrire(HealthInfo info) async {
    _cache = info;
  }

  /// N'EFFACE RIEN SUR LE DISQUE : une demo ne supprime pas la vraie fiche
  /// medicale du randonneur. Elle ne vide que la sienne.
  @override
  Future<void> effacer() async {
    _cache = const HealthInfo();
  }

  /// N'ENREGISTRE AUCUNE PHOTO (tache 760).
  ///
  /// C'est l'ecriture la plus lourde de cet ecran — une image de carte vitale
  /// dans le dossier protege — et c'etait la seule qui n'avait aucune garde.
  @override
  Future<void> saveCard(String nom, List<int> octets) async {}

  /// N'EFFACE AUCUNE PHOTO REELLE : effacer est encore une ecriture.
  @override
  Future<void> eraseCard(String nom) async {}

  /// RIEN A PROTEGER : aucun fichier n'est ecrit pendant une demo.
  @override
  Future<void> garantirExclusion() async {}

  /// LEVE TOUJOURS, ET C'EST UNE BARRIERE (meme raison que
  /// `ProfilVolatilDeDemo.fichier`) : un futur chemin d'ecriture doit tomber
  /// dans les tests, pas ecrire en silence sur le telephone de Christophe.
  ///
  /// `cardFile` n'est pas redefini : il ne fait que CALCULER un chemin, et la
  /// fiche de la demo etant vide, elle ne porte aucun nom de photo a ouvrir.
  @override
  Future<File> fichier() async {
    throw UnsupportedError(
      'FicheVolatileDeDemo: aucune fiche n est ouverte pendant une demo '
      '(tache 760). La demo ne lit et n ecrit qu en memoire.',
    );
  }
}
