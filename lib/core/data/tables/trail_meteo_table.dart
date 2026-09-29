import 'package:drift/drift.dart';

import '../revision_de_donnee.dart';

/// LA METEO TELLE QUE LE SERVEUR L A FABRIQUEE — L APPLI NE FAIT QUE LA LIRE.
///
/// DECISION DE CHRISTOPHE DU 28/09, verbatim : « Ce n est pas l appli qui demande
/// la meteo mais notre serveur, les infos meteo sont mises sur firebase et quand
/// l appli voit qu il y a des donnees a jour elle les met a jour, comme pour le
/// reste. »
///
/// CETTE TABLE EST UNE HUITIEME FAMILLE DE DONNEES DE SENTIER, PAS UN CACHE, ET
/// LA DISTINCTION EST TOUT L OBJET DU LOT. La table qu elle remplace
/// (`weather_cache`) portait un `expiresAt` : elle decidait QUAND RAPPELER LE
/// FOURNISSEUR. Il n y a plus de fournisseur a rappeler cote telephone, donc plus
/// rien a expirer. Ce qui reste — et qui compte davantage — c est l AGE de ce
/// qu on affiche, et il se lit sur [produiteLe], pose par le serveur.
///
/// LES TROIS DATES SONT CELLES DE LA CONCEPTION 611 (#W11), ET ELLES NE DISENT PAS
/// LA MEME CHOSE :
///
///  * [produiteLe] — l heure du modele meteo (`meta.updated_at` chez MET Norway).
///    **C EST LA SEULE QU ON AFFICHE**, et c est la demande explicite de
///    Christophe : « la date affichee est celle de FABRICATION ». C est la seule
///    qui dise quand le monde a ete regarde.
///  * [collecteeLe] — l instant ou notre serveur a reussi son appel. Exploitation
///    seulement : un ecart de plusieurs heures avec [produiteLe] signale une
///    source qui radote, ce que l affichage ne doit pas faire croire au randonneur.
///  * [rev] — l horodatage de synchronisation, celui que le telephone compare a son
///    repere. Meme role et meme type que sur les sept autres familles.
///
/// POURQUOI LES JOURS SONT UN BLOC JSON ET NON UNE SECONDE TABLE. La conception
/// 611 tranche (#W10) : « une seule prevision courante par etape, pas
/// d historique », un enregistrement par couple (sentier, etape), **remplace** a
/// chaque collecte. Une table de jours imposerait un ordre de cles etrangeres, un
/// marqueur de suppression par jour et une purge — trois mecanismes pour une
/// donnee qui n est jamais corrigee jour par jour, seulement reecrite en entier.
/// Le bloc est la forme exacte que la presentation consomme deja
/// (`WeatherForecast.days`), donc il ne fabrique aucun troisieme format.
class TrailMeteo extends Table {
  /// Identite publiee de l enregistrement (`id` du JSON serveur).
  ///
  /// UNE IDENTITE PUBLIEE, PAS UNE CLE TECHNIQUE, et c est ce qui rend le marqueur
  /// de suppression (#R7 de la spec 605) applicable a cette famille comme aux six
  /// autres qui portent un `id`.
  TextColumn get id => text()();

  /// Sentier concerne.
  TextColumn get trailId => text()();

  /// Etape concernee, par son identite publiee (`trail_stages.id`).
  TextColumn get stageId => text()();

  /// Numero de l etape dans son itineraire.
  ///
  /// IL EST STOCKE BIEN QU IL SOIT DEDUCTIBLE DE [stageId], ET C EST DELIBERE.
  /// C est par (sentier, numero d etape) que toute la presentation meteo adresse un
  /// bulletin, depuis l ecran d etape jusqu a la tuile du HUB. Passer par une
  /// jointure sur les etapes rendrait la meteo indisponible exactement quand elle
  /// est utile : un sentier venu du seul distant, dont les etapes vivent dans
  /// `trail_stages` et non dans la table `stages` que la presentation lit encore
  /// (dette mesuree, deux tables d etapes coexistent dans ce depot).
  IntColumn get stageNumber => integer()();

  /// Point ou la prevision a ete demandee — l ARRIVEE de l etape.
  ///
  /// C est le point ou le randonneur dort (#I11 de la conception 611, et la
  /// decision de la tache 572). Conserve pour que l ecran puisse dire de QUEL lieu
  /// il parle, et pour qu un bulletin visiblement pose sur le mauvais point se
  /// voie au lieu de se deviner.
  RealColumn get latitude => real()();

  /// Longitude du point interroge.
  RealColumn get longitude => real()();

  /// Le fournisseur NOMME DANS LA DONNEE (#A3 de la conception 611).
  ///
  /// « Un seul fournisseur en service a la fois, le second est un repli, pas un
  /// complement. » Le nommer dans l enregistrement est ce qui rend un basculement
  /// VISIBLE : sans lui, les chiffres bougeraient sans raison apparente.
  TextColumn get source => text()();

  /// INSTANT DE FABRICATION PAR LE MODELE — LA DATE QUE L ECRAN AFFICHE.
  ///
  /// Le type l interdit d etre l horloge du telephone :
  /// [HorodatageServeur] ne se construit qu en LISANT une valeur venue du serveur
  /// (cf. `lib/core/data/revision_de_donnee.dart`). Une date de fabrication
  /// fabriquee par le telephone serait precisement le mensonge que ce lot ferme.
  IntColumn get produiteLe => integer().map(const HorodatageServeurConverter())();

  /// Instant de la collecte reussie cote serveur. Exploitation, jamais affiche.
  ///
  /// Nullable : un serveur qui ne le publie pas ne doit pas rendre la meteo
  /// illisible — c est [produiteLe] qui porte la verite utile au randonneur.
  IntColumn get collecteeLe =>
      integer().nullable().map(const HorodatageServeurConverter())();

  /// Les jours de prevision, dans la forme que la presentation consomme.
  TextColumn get joursJson => text()();

  /// HORODATAGE DE SYNCHRONISATION de cet enregistrement, pose par le SERVEUR.
  ///
  /// Nullable comme sur les sept autres familles : une donnee qui n en declare pas
  /// est rattachee a l instant courant du sentier (#R6 de la spec 605).
  IntColumn get rev =>
      integer().nullable().map(const HorodatageServeurConverter())();

  @override
  Set<Column> get primaryKey => {id};
}
