/// LA REVISION — UNE DATE, POSEE PAR LE SERVEUR, PORTEE PAR LA DONNEE ELLE-MEME.
///
/// DECISION DE CHRISTOPHE DU 28/09 09:32, verbatim : « le serveur a une seule
/// version de meteo par etapes et ce a 3 ou 5 jours. Avec une date de MAJ. Quand
/// l appli recupere du reseau (et ensuite toutes les 4 heures par exemple) elle
/// vient verifier toutes les donnees superieures a sa date de MAJ. Pas besoin
/// d une version mais d un timestamp de donnees. On regarde le dernier timestamp
/// de MAJ complet et on telecharge tout ce qui concerne ses sentiers qui ont une
/// date superieure a cette MAJ ».
///
/// CE QUI CHANGE PAR RAPPORT AUX LOTS 605-606-607, ET RIEN D AUTRE. Le mecanisme
/// est le meme : meme ordre des sources, meme copie atomique, meme marqueur de
/// suppression, meme chemin unique pour la premiere copie et la mise a jour.
/// SEUL LE TYPE DE LA COMPARAISON CHANGE — un compteur devient un instant.
///
/// POURQUOI UN INSTANT PLUTOT QU UN COMPTEUR, ET CE N EST PAS UNE PREFERENCE.
/// Depuis la decision du 28/09 09:20, le serveur collectera les sentiers, LA
/// METEO et LE RISQUE INCENDIE. Il y a donc PLUSIEURS PRODUCTEURS INDEPENDANTS.
/// Un compteur entier les aurait obliges a se coordonner sur un numero commun :
/// deux producteurs qui incrementent chacun de leur cote fabriquent soit un trou,
/// soit une collision, et la plus silencieuse des deux gagne. Avec le temps,
/// chacun pose sa date sans rien demander a personne — et la date sert DOUBLEMENT,
/// pour la fraicheur metier (« cette meteo date de 3 heures ») et pour la
/// synchronisation (« donne-moi ce qui est plus recent que mon repere »).
///
/// LE MODELE, EN TROIS PHRASES, INCHANGEES SAUF LEUR TYPE.
///  1. Chaque enregistrement telechargeable — une etape, un point d interet, un
///     hebergement, une trace, la fiche — porte [champRevision] : L INSTANT ou il
///     a ete modifie pour la derniere fois.
///  2. Le sentier porte l instant de sa derniere publication
///     (`TrailManifestEntry.dataVersion`), et le telephone retient UNE seule
///     valeur par sentier : le repere jusqu ou il est a jour
///     (`trail_manifests.localVersion`).
///  3. L application demande TOUT CE QUI PORTE UNE DATE PLUS RECENTE QUE SON
///     REPERE. Une seule question, quelle que soit la taille du changement.
///
/// LES SUPPRESSIONS, QU UNE DATE NE PEUT PAS DIRE SEULE. Comme un numero
/// croissant, un instant croissant ne transmet pas une ABSENCE : un point d eau
/// tari, un refuge ferme, un point d interet retire resteraient A VIE sur le
/// telephone du randonneur. D ou [champSupprime], inchange : la donnee redescend
/// avec sa date ET une marque qui dit « celle-la, retire-la ».
library;

import 'package:drift/drift.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

/// L INSTANT ANNONCE PAR LE SERVEUR — ET LE PIEGE DES HORLOGES, FERME PAR LE
/// TYPE PLUTOT QUE PAR LA VIGILANCE.
///
/// LE PIEGE, TRANCHE PAR SKYNET LE 28/09 ET QU ON NE ROUVRE PAS. Un horodatage
/// se compare ENTRE MACHINES : il faut UNE SEULE autorite de temps. La regle est
/// absolue et elle a deux moities :
///
///  1. L horodatage est POSE PAR LE SERVEUR, jamais par le client — de preference
///     par l horodatage natif de sa base (`serverTimestamp()` chez Firestore,
///     `now()` chez Postgres), pour qu aucun processus de publication n ait a
///     etre d accord avec un autre sur l heure qu il est.
///  2. Le telephone retient LA DATE QUE LE SERVEUR LUI ANNONCE, JAMAIS SA PROPRE
///     HEURE LOCALE.
///
/// CE QUE LA SECONDE MOITIE EVITE, ET C EST UNE PERTE DEFINITIVE ET SILENCIEUSE.
/// Un telephone dont l horloge avance d une heure qui inscrirait `DateTime.now()`
/// comme repere se croirait a jour jusqu a une heure DANS LE FUTUR. Tout ce que le
/// serveur publie pendant cette heure porte une date INFERIEURE a son repere :
/// l application ne le demandera JAMAIS, et rien ne le lui dira — le sentier a
/// l air a jour, la donnee manque pour toujours. C est le pire defaut possible de
/// ce modele, parce qu il ne se voit pas.
///
/// D OU CE TYPE, ET SA SEULE PORTE D ENTREE. [HorodatageServeur] ne se construit
/// QUE par [annonceParLeServeur] — c est-a-dire en LISANT une valeur venue du
/// serveur. Il n existe aucun constructeur qui accepte l heure de l appareil.
/// `HorodatageServeur(DateTime.now())` N EXISTE PAS : ce n est pas une convention
/// qu on documente et qu un futur lot oubliera, c est une erreur de COMPILATION.
/// La seule exception est [poseeParLeServeur], reservee a l OUTIL DE PUBLICATION,
/// qui EST l autorite de temps ; un test verrouille qu aucun fichier de `lib/` ne
/// l appelle.
@immutable
final class HorodatageServeur implements Comparable<HorodatageServeur> {
  const HorodatageServeur._(this.millisecondesEpoch);

  /// L ORIGINE — LE TELEPHONE QUI N A RIEN.
  ///
  /// Le pendant exact de l ancienne « revision zero » : tout instant publie lui
  /// est posterieur, donc TOUT descend. C est ce qui fait que la premiere copie
  /// et la mise a jour restent LITTERALEMENT le meme chemin de code.
  static const HorodatageServeur origine = HorodatageServeur._(0);

  /// L instant, en millisecondes depuis l epoch, en UTC.
  ///
  /// LA MILLISECONDE N EST PAS UN DETAIL. La comparaison est STRICTE (`>`) : deux
  /// publications separees par moins d une unite de temps deviennent
  /// indiscernables, et la seconde serait ratee pour toujours. Une seconde entiere
  /// — la precision par defaut de `DateTime` dans SQLite chez Drift — est trop
  /// grossiere des lors que la meteo et le risque incendie ecriront en rafale.
  final int millisecondesEpoch;

  /// L instant en UTC. Toujours UTC : un instant n a pas de fuseau, seule son
  /// ECRITURE en a un, et deux ecritures differentes du meme instant doivent
  /// rester le meme repere.
  DateTime get date =>
      DateTime.fromMillisecondsSinceEpoch(millisecondesEpoch, isUtc: true);

  /// La forme publiee : ISO 8601, UTC, millisecondes, suffixe `Z`.
  ///
  /// C est ce qu un horodatage natif de base de donnees donne quand il passe en
  /// JSON, et c est lisible par un humain qui ouvre le fichier publie.
  String get iso8601 => '${date.toIso8601String().replaceFirst('Z', '')}Z';

  /// LA FORME QUI TIENT DANS UN NOM DE FICHIER.
  ///
  /// L ISO 8601 porte des `:`, qui sont INTERDITS dans un nom de fichier Windows
  /// et reserves dans une URL : le fichier de donnees publie ne peut donc pas
  /// s appeler par son instant ISO. Cette forme compacte garde les deux proprietes
  /// qui comptent — elle se TRIE dans l ordre chronologique, et elle se relit a
  /// l oeil (`20260928T093200123Z`).
  String get estampilleDeFichier => iso8601
      .replaceAll('-', '')
      .replaceAll(':', '')
      .replaceAll('.', '');

  /// Cet instant avance d au moins une milliseconde par rapport a [plancher].
  ///
  /// LE SEUL CAS OU L AUTORITE DE TEMPS DOIT ETRE CORRIGEE, ET IL EST REEL. Le
  /// modele exige que chaque publication porte un instant STRICTEMENT posterieur a
  /// la precedente : c est ce qui fait qu un telephone deja a jour prendra la
  /// suite. Or une horloge serveur peut RECULER — correction NTP, bascule de
  /// machine, deux publications dans la meme milliseconde. Une publication qui
  /// porterait une date anterieure a la precedente serait INVISIBLE pour tous les
  /// telephones deja a jour, pour toujours, sans que rien ne le dise.
  ///
  /// On avance donc au plus petit instant acceptable plutot que de refuser le
  /// depot : la monotonie est ce dont le modele a besoin, et l ecart introduit est
  /// d une milliseconde. Le fait est REMONTE a l appelant (cf.
  /// `ResultatDePublication.horlogeCorrigee`), jamais avale.
  HorodatageServeur auMoinsApres(HorodatageServeur plancher) =>
      this > plancher
          ? this
          : HorodatageServeur._(plancher.millisecondesEpoch + 1);

  /// LA SEULE PORTE D ENTREE : CE QUE LE SERVEUR A ANNONCE.
  ///
  /// Accepte les trois formes sous lesquelles un horodatage de serveur arrive :
  ///  * une chaine ISO 8601 (`"2026-09-28T09:32:00.000Z"`) — la forme publiee ;
  ///  * un entier, millisecondes depuis l epoch — la forme relue de la base ;
  ///  * un objet `{"seconds": …, "nanoseconds": …}` — la forme d un `Timestamp`
  ///    Firestore serialise, pour que brancher la console ne demande pas de
  ///    retoucher la lecture.
  ///
  /// Rend `null` quand la valeur est absente ou illisible. LE REFUS EST LE BON
  /// COMPORTEMENT, et il n a pas de repli : inventer une date pour une donnee qui
  /// n en declare pas de valide, c est exactement fabriquer un repere faux.
  /// L appelant decide alors d appliquer la regle #R6 (rattacher a l instant
  /// courant du sentier) ou de refuser.
  ///
  /// UNE CHAINE SANS FUSEAU EST LUE EN UTC, jamais en heure locale de l appareil :
  /// interpreter `"2026-09-28T09:32:00"` avec le fuseau du telephone ferait
  /// dependre le repere de l endroit ou se trouve le randonneur.
  static HorodatageServeur? annonceParLeServeur(Object? brut) {
    if (brut == null) return null;

    if (brut is int) {
      return brut < 0 ? null : HorodatageServeur._(brut);
    }
    if (brut is double) {
      if (brut.isNaN || brut.isInfinite || brut < 0) return null;
      return HorodatageServeur._(brut.round());
    }
    if (brut is Map) {
      // Forme `Timestamp` Firestore serialise.
      final secondes = brut['seconds'] ?? brut['_seconds'];
      if (secondes is! num) return null;
      final nanos = brut['nanoseconds'] ?? brut['_nanoseconds'];
      final millis = secondes.toInt() * 1000 +
          (nanos is num ? (nanos.toInt() ~/ 1000000) : 0);
      return millis < 0 ? null : HorodatageServeur._(millis);
    }
    if (brut is String) {
      final texte = brut.trim();
      if (texte.isEmpty) return null;
      final lu = DateTime.tryParse(_avecFuseau(texte));
      if (lu == null) return null;
      final millis = lu.toUtc().millisecondsSinceEpoch;
      return millis < 0 ? null : HorodatageServeur._(millis);
    }
    return null;
  }

  /// RESERVE A L OUTIL DE PUBLICATION — L AUTORITE DE TEMPS, ET ELLE EST UNIQUE.
  ///
  /// L outil de publication EST le serveur du point de vue de ce modele : c est
  /// lui qui pose l instant que tous les telephones compareront. Il est donc le
  /// SEUL a avoir le droit de transformer une horloge en horodatage.
  ///
  /// AUCUN FICHIER DE `lib/` NE DOIT APPELER CECI, et ce n est pas une consigne :
  /// `test/comportement/horloge_du_telephone_610_test.dart` verifie la source du
  /// depot et echoue si un fichier de l application s en sert. Le jour ou la base
  /// serveur existe, cette pose sera remplacee par son horodatage natif
  /// (`serverTimestamp()`), et ce point d entree disparaitra.
  static HorodatageServeur poseeParLeServeur(DateTime horloge) =>
      HorodatageServeur._(horloge.toUtc().millisecondsSinceEpoch);

  /// UNE ECRITURE SANS FUSEAU EST LUE EN UTC, JAMAIS EN HEURE DE L APPAREIL.
  ///
  /// `DateTime.parse("2026-09-28T09:32:00")` rend un instant LOCAL : le meme
  /// fichier publie donnerait alors des reperes differents a Paris et a Tokyo, et
  /// la synchronisation dependrait de l endroit ou se trouve le randonneur. Une
  /// date seule (`"2026-09-28"`) devient minuit UTC pour la meme raison.
  static String _avecFuseau(String texte) {
    if (texte.length <= 10) return '${texte}T00:00:00Z';
    if (texte.endsWith('Z') || texte.endsWith('z')) return texte;
    // Un decalage `+02:00` / `-05:00` en fin de chaine, apres l heure.
    final apresLaDate = texte.substring(10);
    final porteUnDecalage = apresLaDate.contains('+') ||
        apresLaDate.lastIndexOf('-') > apresLaDate.indexOf(':');
    return porteUnDecalage ? texte : '${texte}Z';
  }

  bool operator >(HorodatageServeur autre) =>
      millisecondesEpoch > autre.millisecondesEpoch;
  bool operator >=(HorodatageServeur autre) =>
      millisecondesEpoch >= autre.millisecondesEpoch;
  bool operator <(HorodatageServeur autre) =>
      millisecondesEpoch < autre.millisecondesEpoch;
  bool operator <=(HorodatageServeur autre) =>
      millisecondesEpoch <= autre.millisecondesEpoch;

  @override
  int compareTo(HorodatageServeur autre) =>
      millisecondesEpoch.compareTo(autre.millisecondesEpoch);

  @override
  bool operator ==(Object other) =>
      other is HorodatageServeur &&
      other.millisecondesEpoch == millisecondesEpoch;

  @override
  int get hashCode => millisecondesEpoch.hashCode;

  @override
  String toString() =>
      this == origine ? 'HorodatageServeur.origine' : iso8601;
}

/// LECTURE ET ECRITURE DE L HORODATAGE DANS LA BASE LOCALE.
///
/// LE STOCKAGE RESTE UN ENTIER, ET C EST UN CHOIX MESURE, PAS UNE COMMODITE.
/// Les colonnes `rev`, `dataVersion` et `localVersion` posees par la migration
/// v27 sont deja des `INTEGER` : y ranger des millisecondes depuis l epoch ne
/// CHANGE PAS LE TYPE SQL. La migration v28 n a donc AUCUN `ALTER TABLE` a
/// faire — elle ne fait que remettre a zero des valeurs devenues intelligibles
/// autrement. Une migration qui echoue EMPECHE LA BASE DE S OUVRIR sur le
/// telephone d un randonneur, sans recours : la meilleure migration de schema est
/// celle qui n existe pas.
///
/// LES DEUX AUTRES FORMES ONT ETE ECARTEES, ET POUR DES RAISONS NOMMEES.
/// Une colonne TEXTE ISO 8601 aurait impose une reconstruction de table sur sept
/// tables, et fait dependre l ORDRE d une comparaison de chaines : `"…:00Z"` et
/// `"…:00.000Z"` designent le meme instant et ne se comparent pas pareil — une
/// erreur de normalisation aurait casse la synchronisation en silence. Le
/// `DateTimeColumn` de Drift, lui, stocke par defaut des SECONDES : deux
/// publications dans la meme seconde deviennent indiscernables, et la seconde est
/// ratee pour toujours par une comparaison stricte.
class HorodatageServeurConverter
    extends TypeConverter<HorodatageServeur, int> {
  const HorodatageServeurConverter();

  @override
  HorodatageServeur fromSql(int fromDb) => HorodatageServeur._(fromDb);

  @override
  int toSql(HorodatageServeur value) => value.millisecondesEpoch;
}

/// LECTURE ET ECRITURE DE L HORODATAGE DANS LE JSON PUBLIE.
///
/// A l ecriture, TOUJOURS la forme ISO 8601 UTC : c est ce qu un horodatage natif
/// de base de donnees donne, et c est lisible par un humain. A la lecture, les
/// trois formes acceptees par [HorodatageServeur.annonceParLeServeur].
///
/// Une valeur illisible devient [HorodatageServeur.origine] plutot qu une
/// exception : une entree de liste mal formee ne doit pas rendre TOUT le catalogue
/// illisible. Consequence, et elle est du bon cote : le sentier est vu comme
/// jamais publie, donc jamais pris pour plus recent que le repere du telephone.
class HorodatageServeurJson
    extends JsonConverter<HorodatageServeur, Object?> {
  const HorodatageServeurJson();

  @override
  HorodatageServeur fromJson(Object? json) =>
      HorodatageServeur.annonceParLeServeur(json) ?? HorodatageServeur.origine;

  @override
  Object toJson(HorodatageServeur object) => object.iso8601;
}

/// LES REGLES DU MODELE, ET ELLES SONT LES MEMES QU AUX LOTS 605-607.
///
/// Seul le type de la comparaison a change. Le fichier a garde son nom pour que
/// l histoire des trois lots reste lisible : c est toujours « la revision portee
/// par la donnee », elle se dit simplement en dates.
abstract final class RevisionDeDonnee {
  RevisionDeDonnee._();

  /// Nom du champ d horodatage dans les donnees publiees.
  ///
  /// LE NOM NE CHANGE PAS, ET C EST DELIBERE. La consigne du lot est explicite :
  /// meme mecanisme, SEUL LE TYPE DE LA COMPARAISON CHANGE. Renommer le champ
  /// aurait mele a une bascule de type une bascule de vocabulaire, et rendu
  /// illisible ce que la migration casse reellement.
  static const String champRevision = 'rev';

  /// Nom du marqueur de suppression dans les donnees publiees.
  static const String champSupprime = 'supprime';

  /// Le repere de la premiere ouverture : rien n est copie, tout est plus recent.
  static const HorodatageServeur revisionInitiale = HorodatageServeur.origine;

  /// COMBIEN DE TEMPS LE SERVEUR GARDE LES MARQUEURS DE SUPPRESSION — ET DONC
  /// JUSQU A QUEL RETARD UN TELEPHONE PEUT ENCORE RATTRAPER PAR MORCEAUX.
  ///
  /// LA REGLE EST CELLE DU LOT 607, SON UNITE A CHANGE AVEC LE MODELE. Elle valait
  /// « dix revisions » quand la revision etait un compteur ; elle vaut quatre-vingt
  /// dix jours maintenant qu elle est une date. La demonstration, elle, est
  /// identique — et c est ce qui compte.
  ///
  /// DEMONSTRATION. Un telephone dont le repere vaut L, face a un sentier publie a
  /// l instant N, a besoin de TOUS les marqueurs d instant compris dans `]L, N]`.
  /// Le serveur conserve ceux d instant `> N - fenetre`. Les deux ensembles
  /// coincident si et seulement si `N - L <= fenetre`. Au-dela, des suppressions
  /// ont ete purgees sans avoir jamais ete transmises : une mise a jour par
  /// morceaux laisserait DEFINITIVEMENT un point d eau tari sur le telephone. D ou
  /// la copie complete, qui est la seule reponse correcte.
  ///
  /// LES DEUX COTES LISENT CETTE MEME VALEUR, et ce n est pas une commodite : deux
  /// constantes independantes donneraient un decalage silencieux, et du mauvais
  /// cote — l application se croirait a jour.
  ///
  /// POURQUOI QUATRE-VINGT-DIX JOURS. Un randonneur qui ouvre l application au
  /// moins une fois par trimestre rattrape toujours par morceaux ; au-dela, la
  /// copie complete coute un telechargement et garantit la justesse. C est une
  /// valeur que Christophe peut tourner : l augmenter alourdit les fichiers
  /// publies, la reduire fait recopier plus souvent. Elle ne change RIEN au reste
  /// du mecanisme.
  static const Duration fenetreDeRetention = Duration(days: 90);

  /// Vrai si le retard du telephone depasse la fenetre de retention serveur.
  ///
  /// Un telephone qui n a RIEN ([HorodatageServeur.origine]) ne releve pas de ce
  /// cas : il prend deja tout, par le chemin normal.
  static bool exigeUneCopieComplete({
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionCible,
  }) {
    if (revisionLocale <= revisionInitiale) return false;
    return revisionCible.millisecondesEpoch - revisionLocale.millisecondesEpoch >
        fenetreDeRetention.inMilliseconds;
  }

  /// Vrai si un marqueur d instant [rev] doit encore etre publie quand le sentier
  /// est publie a l instant [revisionCourante].
  ///
  /// C est la moitie SERVEUR de la meme regle, et elle vit ici pour que l outil de
  /// publication et l application ne puissent pas diverger.
  static bool marqueurAConserver({
    required HorodatageServeur rev,
    required HorodatageServeur revisionCourante,
  }) {
    return rev.millisecondesEpoch >
        revisionCourante.millisecondesEpoch - fenetreDeRetention.inMilliseconds;
  }

  /// Horodatage porte par [donnee], ou [defaut] si elle n en declare pas de
  /// lisible.
  ///
  /// UNE DONNEE SANS HORODATAGE EST RATTACHEE A L INSTANT COURANT DU SENTIER, et
  /// ce choix est deliberе (#R6) : les quatre sentiers embarques n ont pas de
  /// champ `rev`. Les ignorer rendrait un sentier existant intelligible mais non
  /// copiable ; les traiter comme « toujours a jour » les rendrait incorrigibles.
  /// Les rattacher a l instant courant donne le comportement attendu : a la
  /// premiere copie tout descend, et une republication les fait redescendre.
  static HorodatageServeur revisionDe(
    Map<String, dynamic> donnee, {
    required HorodatageServeur defaut,
  }) {
    return HorodatageServeur.annonceParLeServeur(donnee[champRevision]) ??
        defaut;
  }

  /// Vrai si [donnee] est un marqueur de suppression.
  static bool estSupprimee(Map<String, dynamic> donnee) =>
      donnee[champSupprime] == true;

  /// Vrai si [donnee] doit descendre sur le telephone.
  ///
  /// C est LA question, et il n y en a pas d autre : « ta date est-elle plus
  /// recente que mon repere ? ».
  static bool aPrendre(
    Map<String, dynamic> donnee, {
    required HorodatageServeur revisionLocale,
    required HorodatageServeur revisionDuSentier,
  }) {
    return revisionDe(donnee, defaut: revisionDuSentier) > revisionLocale;
  }
}
