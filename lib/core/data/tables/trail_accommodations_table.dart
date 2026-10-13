/// Refuges, gites et hotels rattaches a une etape, avec leurs noms aplatis en
/// cinq langues.
library;

import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// Table des hebergements par etape (Phase 4 Drift v7).
///
/// Refuges, gites, hotels rattaches a une etape.
/// Noms i18n aplatis : nameFr, nameEn, nameDe, nameIt, nameEs.
class TrailAccommodations extends Table {
  /// Identifiant unique (UUID Firestore)
  TextColumn get id => text()();

  /// Reference vers trail_stages.id
  TextColumn get stageId => text()();

  /// Nom en francais
  TextColumn get nameFr => text()();

  /// Nom en anglais
  TextColumn get nameEn => text()();

  /// Nom en allemand
  TextColumn get nameDe => text()();

  /// Nom en italien
  TextColumn get nameIt => text()();

  /// Nom en espagnol
  TextColumn get nameEs => text()();

  /// Type d'hebergement (refuge, gite, hotel, camping, bivouac)
  TextColumn get type => text()();

  /// Latitude
  RealColumn get lat => real()();

  /// Longitude
  RealColumn get lng => real()();

  /// Telephone (nullable)
  TextColumn get phone => text().nullable()();

  /// Email (nullable)
  TextColumn get email => text().nullable()();

  /// Site web (nullable)
  TextColumn get website => text().nullable()();

  /// Capacite d'accueil (nullable)
  IntColumn get capacity => integer().nullable()();

  /// Fourchette de prix (nullable, ex: '30-50EUR')
  TextColumn get priceRange => text().nullable()();

  /// URL de reservation (nullable)
  TextColumn get bookingUrl => text().nullable()();

  /// ADRESSE POSTALE (nullable, tache 641).
  ///
  /// DEMANDE DE CHRISTOPHE DU 30/09 10:23, verbatim : « hebergement il doit
  /// avoir une adresse et un point GPS qui link sur Maps » (bug 15). La table
  /// portait deja `lat` et `lng` ; elle n avait AUCUN champ d adresse, et les
  /// onze hebergements du Mare a Mare n avaient ni telephone, ni site, ni
  /// adresse — tous nuls dans l asset embarque.
  ///
  /// POURQUOI L ADRESSE EN PLUS DU POINT GPS, alors qu on a deja des coordonnees.
  /// Parce que les deux ne repondent pas a la meme question. Le point GPS dit ou
  /// c est ; l adresse est ce qu on donne a un taxi, ce qu on ecrit dans un
  /// courriel de reservation, et ce que l application de cartes sait geocoder
  /// quand les coordonnees ne designent que le CENTRE DU VILLAGE — ce qui est le
  /// cas de la plupart des gites du Mare a Mare, et c est dit dans la donnee
  /// plutot que masque par une fausse precision.
  ///
  /// NULLABLE, ET CE N EST PAS UN PIS-ALLER : « pas d adresse connue » est un
  /// etat REEL et frequent pour un refuge de montagne. Le lien vers les cartes
  /// se construit alors sur les coordonnees seules, et l ecran n affiche aucune
  /// ligne vide.
  TextColumn get address => text().nullable()();

  /// HORODATAGE de cet enregistrement : L INSTANT ou il a ete modifie pour la
  /// derniere fois, pose par le SERVEUR (StepWays taches 605 puis 610).
  ///
  /// Nullable : les lignes anterieures a la migration v27, celles que la v28 a
  /// remises a zero, et les donnees embarquees qui ne declarent pas d instant.
  ///
  /// STOCKE EN MILLISECONDES DEPUIS L EPOCH, DANS LA MEME COLONNE `INTEGER`
  /// QU AVANT : la bascule du compteur vers la date ne demande AUCUN
  /// `ALTER TABLE`. Le modele complet — et pourquoi le telephone ne doit jamais
  /// y ecrire sa propre horloge — est dans
  /// `lib/core/data/revision_de_donnee.dart`.
  IntColumn get rev =>
      integer().nullable().map(const HorodatageServeurConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
