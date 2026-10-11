/// LA MATIERE FABRIQUEE DE LA DEMONSTRATION — plausible, tiree du sentier REEL,
/// et jamais ecrite.
///
/// TACHE 810. LA LOI, POSEE PAR CHRISTOPHE LE 11/10/2026 A 09:27, verbatim :
/// « tu rends accessible le faux journal er le faux recap oui . Demo = toutes
/// les fonctionalite visible mais bouchonnees ».
///
/// EN UNE PHRASE : EN DEMO, TOUT SE VOIT, RIEN NE S'ECRIT. Elle REMPLACE la
/// decision anterieure qui laissait le journal vide et le recapitulatif
/// verrouille en demonstration. Aucun ecran grise parce qu'il n'aurait rien a
/// montrer : un journal vide qu'on cache apprend moins qu'un journal rempli de
/// faux qui montre a quoi ca ressemble. C'est l'argument meme du bouton orange
/// — on VOIT tout, on n'ACQUIERT rien.
///
/// CE QUI ETAIT FERME, ET D'OU VENAIT LE VIDE. Une seule cause, mesuree :
/// en demonstration la session de trek n'est JAMAIS persistee
/// (`tracking_providers.dart`, `onSessionPersist` et `_persistSession`).
/// Faute de session, `latestTrekSessionProvider` rendait `null`, donc
/// `isRecapAvailableProvider` et `isDiplomaUnlockedProvider` rendaient `false`
/// — fail-closed, et ils ont raison de l'etre. Le recapitulatif affichait
/// « Disponible a la fin du trek » MEME APRES l'arrivee, le diplome restait
/// verrouille, et le carnet n'avait aucune page. Ce fichier rend la MATIERE que
/// cette session manquante aurait portee ; il ne touche ni au verrou, ni aux
/// droits, ni a une ecriture.
///
/// TROIS PROPRIETES, ET CHACUNE EST UNE PROMESSE TENUE.
///
/// 1. ELLE EST PURE, ET DONC DETERMINISTE. Aucun Flutter, aucun Riverpod,
///    aucune base, aucune horloge interne : tout entre par les parametres.
///    C'EST CE QUI PERMET A DEUX LECTEURS DE S'ACCORDER SANS SE PARLER. Le
///    carnet (feature `journal`) et le recapitulatif (feature `after`)
///    construisent CHACUN leur instance, sans fleche de l'un vers l'autre et
///    sans facade a creer : la matiere etant une FONCTION du sentier et du jour
///    civil d'arrivee, les deux instances sont identiques par construction. Le
///    jour d'arrivee est d'ailleurs ramene a minuit ici meme ([_jourDe]), pour
///    que deux appels a quelques secondes d'intervalle ne puissent pas produire
///    deux calendriers differents.
///
/// 2. ELLE EST PLAUSIBLE PARCE QU'ELLE EST VRAIE. Pas un chiffre en dur : les
///    etapes, leurs noms, leurs distances et leurs deniveles sont ceux du
///    sentier charge. Sur le Mare a Mare Centre, les sept etapes fabriquent
///    donc exactement les 87,3 km et les 4 274 m de denivele positif du
///    sentier — non pas parce qu'on les a recopies, mais parce qu'on les
///    additionne. Changer le sentier change la matiere ; aucun sentier n'est
///    nomme ici, et le moteur reste generique.
///
///    DEUX CHAMPS QUE LE MAPPEUR DU DEPOT NE RECOPIE PAS, ET IL FAUT LE DIRE
///    PLUTOT QUE DE LAISSER CROIRE LE CONTRAIRE. `domainStagesProvider`
///    (`features/trek/providers/gps_providers.dart`) construit ses [Stage] sans
///    reprendre deux champs que la donnee du sentier porte pourtant :
///      * `estimatedDurationSeconds` reste a zero. CE N'EST PAS GRAVE ICI, et
///        c'est mesure : [dureeDeLaJournee] retombe sur la regle de marche du
///        depot, qui rend pour ces etapes-la EXACTEMENT les durees que le
///        sentier declare (457 min pour 19,9 km et 1 058 m de D+, 175 min pour
///        11,1 km et 54 m). La duree fabriquee est donc celle du sentier, par
///        le calcul plutot que par la lecture ;
///      * `nameEn`/`nameDe`/`nameIt`/`nameEs` restent vides, donc
///        [Stage.nomLocalise] retombe sur le francais dans les cinq langues. Un
///        nom de lieu en francais vaut mieux qu'un nom vide, mais un visiteur
///        anglophone lira « Ghisonaccia - Catastaghju » la ou le sentier sait
///        dire « Ghisonaccia to Catastaghju ».
///    Les deux sont ANTERIEURS a ce lot et hors de son perimetre : ils sont
///    SIGNALES, pas corriges ici. Le jour ou ce mappeur reprendra ces champs,
///    la matiere s'enrichira sans qu'une ligne de ce fichier change.
///
/// 3. ELLE EST RECONNAISSABLE A L'OEIL ET A LA MACHINE. L'identifiant de la
///    session fabriquee est [idSessionFabriquee], et les entrees de carnet
///    portent des identifiants NEGATIFS ([idEntreeFabriquee]) — une cle Drift
///    auto-incrementee vaut toujours 1 ou plus, donc aucune confusion possible
///    avec une ligne reelle, et aucune collision. Rien de tout cela n'est
///    insere : ces identifiants existent pour qu'un test, un journal de bord ou
///    un relecteur puisse AFFIRMER qu'une donnee est fabriquee.
///
/// CE FICHIER N'ECRIT RIEN ET NE SAIT RIEN ECRIRE. Il ne connait ni la base, ni
/// les preferences, ni le systeme de fichiers. La barriere d'ecriture de la
/// demonstration reste ou elle est, dans les providers : elle est le dernier
/// rempart, et elle doit survivre a un ecran qui oublierait de griser.
library;

// LA REGLE DE MARCHE DU DEPOT, ET NON UNE SECONDE (tache 810).
// `estimatedStageDurationMinutes` est la Naismith simplifiee que l'itineraire
// et le planning emploient deja (15 min par km a plat, 15 min par 100 m de
// montee). Le metier a le droit de lire le socle — c'est l'inverse qui est
// interdit (regle 11, plafond a zero).
import '../core/models/stage_duration.dart';
import 'stage.dart';
import 'trek_session.dart';

/// Une journee de la randonnee fabriquee : le jour civil, et l'etape marchee.
///
/// UNE JOURNEE = UNE ETAPE, et c'est le seul endroit du depot ou cette equation
/// est posee. Elle ne vaut QUE pour la matiere fabriquee : le modele reel
/// connait les journees de repos, les doubles etapes et les etapes a cheval sur
/// deux jours (cf. `AdventureDay`). On fabrique ici la randonnee la plus simple
/// qui soit — une etape par jour, dans l'ordre de marche — parce qu'une
/// demonstration doit etre LISIBLE avant d'etre exhaustive.
class JourneeFabriquee {
  /// Fabrique une journee de marche de la demonstration.
  const JourneeFabriquee({
    required this.numero,
    required this.jour,
    required this.etape,
    required this.depart,
    required this.arrivee,
  });

  /// Numero du jour de marche, 1 pour le jour du depart.
  final int numero;

  /// Journee civile (minuit local).
  final DateTime jour;

  /// L'etape REELLE marchee ce jour-la : son nom, ses chiffres, sa duree.
  final Stage etape;

  /// Heure de depart de la journee.
  final DateTime depart;

  /// Heure d'arrivee de la journee ([depart] + la duree estimee de l'etape).
  final DateTime arrivee;

  /// Duree marchee dans la journee.
  Duration get duree => arrivee.difference(depart);
}

/// La randonnee fabriquee de la demonstration : une session terminee, et ses
/// journees.
///
/// Construite par [MatiereDeDemo.pourSentier]. Hors demonstration, personne ne
/// l'instancie : les providers qui la lisent sortent AVANT, sur
/// `enDemoProvider`.
class MatiereDeDemo {
  const MatiereDeDemo._({required this.session, required this.journees});

  /// La session TERMINEE que la demonstration n'a pas ecrite.
  ///
  /// `status` termine et `parcoursFullyWalked` vrai : c'est ce couple qui ouvre
  /// le recapitulatif et le diplome, et qui les ouvre PAR LA MATIERE et non en
  /// desarmant leur verrou. Les deux gardes continuent de lire exactement ce
  /// qu'elles lisaient, et de rester fail-closed quand elles ne lisent rien.
  final TrekSession session;

  /// Les journees de marche, de la PREMIERE a la derniere.
  final List<JourneeFabriquee> journees;

  /// L'identifiant de la session fabriquee — reconnaissable, et jamais insere.
  static const String idSessionFabriquee = 'demo-aventure-fabriquee';

  /// L'heure a laquelle une journee de marche fabriquee commence.
  ///
  /// Un depart de randonneur, pas un depart de minuit : le recapitulatif et le
  /// carnet affichent des heures, elles doivent avoir l'air d'heures.
  static const Duration heureDeDepart = Duration(hours: 7, minutes: 30);

  /// Duree de marche d'une journee, en secondes.
  ///
  /// LA DUREE DECLAREE PAR L'ETAPE SI ELLE EXISTE, SINON LA REGLE DE MARCHE DU
  /// DEPOT. `Stage.estimatedDurationSeconds` vaut 0 par defaut, et il vaut
  /// TOUJOURS zero en pratique : `domainStagesProvider` ne recopie pas ce champ
  /// depuis la donnee du sentier (defaut anterieur a ce lot, signale et non
  /// corrige ici). Sans repli, une journee durerait zero minute et la vitesse
  /// moyenne du recapitulatif serait absurde — ou disparaitrait.
  ///
  /// LE REPLI N'EST PAS UNE CONSTANTE FORFAITAIRE, ET C'EST CE QUI REND LA
  /// MATIERE JUSTE. On appelle [estimatedStageDurationMinutes], la Naismith
  /// simplifiee que l'itineraire et le planning emploient deja. Elle calcule la
  /// duree depuis la distance et le denivele positif de l'etape, donc chaque
  /// journee a SA duree. Verifie sur le Mare a Mare Centre : la formule rend
  /// 457 minutes pour 19,9 km et 1 058 m de D+, 175 pour 11,1 km et 54 m — soit
  /// EXACTEMENT les durees que la donnee du sentier declare pour ces etapes.
  /// Les durees fabriquees sont donc celles du sentier, par le calcul.
  static Duration dureeDeLaJournee(Stage etape) {
    if (etape.estimatedDurationSeconds > 0) return etape.estimatedDuration;
    return Duration(
      minutes: estimatedStageDurationMinutes(
        distanceKm: etape.distance,
        elevationGainM: etape.elevationGain,
      ),
    );
  }

  /// L'identifiant fabrique de la n-ieme entree de carnet (toujours NEGATIF).
  ///
  /// [rang] commence a 1. Une cle Drift auto-incrementee vaut 1 ou plus : un
  /// identifiant negatif ne peut donc designer qu'une entree fabriquee, et il
  /// n'entrera jamais en collision avec une entree reelle du randonneur.
  static int idEntreeFabriquee(int rang) => -rang;

  /// Vrai quand il n'y a rien a montrer (sentier sans etape chargee).
  bool get estVide => journees.isEmpty;

  /// Le jour civil de la premiere journee de marche, ou `null` si vide.
  DateTime? get premierJour => journees.isEmpty ? null : journees.first.jour;

  /// Le jour civil de la derniere journee de marche, ou `null` si vide.
  DateTime? get dernierJour => journees.isEmpty ? null : journees.last.jour;

  /// Fabrique la randonnee de demonstration du sentier [trailId].
  ///
  /// [etapes] sont les etapes REELLES du sentier (ordre quelconque : elles sont
  /// remises dans l'ordre de marche ici, par `orderIndex`). [arriveeLe] est le
  /// jour ou la randonnee fabriquee s'acheve — en pratique aujourd'hui, ramene
  /// a minuit pour que la matiere soit stable sur toute la journee.
  ///
  /// LE CALENDRIER REMONTE DEPUIS L'ARRIVEE, et non l'inverse. Une aventure qui
  /// se termine aujourd'hui est une aventure qu'on vient de finir : c'est
  /// l'histoire qu'un recapitulatif raconte. Partir d'une date de depart fixe
  /// aurait donne, selon le jour ou la demonstration est ouverte, une randonnee
  /// finie il y a six mois — ou pas encore finie.
  ///
  /// Une liste d'etapes vide rend une matiere vide ([estVide]) : on ne fabrique
  /// pas une aventure sans sentier.
  factory MatiereDeDemo.pourSentier({
    required String trailId,
    required List<Stage> etapes,
    required DateTime arriveeLe,
  }) {
    final ordonnees = [...etapes]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    if (ordonnees.isEmpty) {
      return MatiereDeDemo._(
        session: TrekSession(
          id: idSessionFabriquee,
          trailId: trailId,
          startedAt: _jourDe(arriveeLe),
        ),
        journees: const <JourneeFabriquee>[],
      );
    }

    final dernier = _jourDe(arriveeLe);
    final premier = dernier.subtract(Duration(days: ordonnees.length - 1));

    final journees = <JourneeFabriquee>[];
    for (var i = 0; i < ordonnees.length; i++) {
      final etape = ordonnees[i];
      final jour = _jourDe(premier.add(Duration(days: i)));
      final depart = jour.add(heureDeDepart);
      final duree = dureeDeLaJournee(etape);
      journees.add(
        JourneeFabriquee(
          numero: i + 1,
          jour: jour,
          etape: etape,
          depart: depart,
          arrivee: depart.add(duree),
        ),
      );
    }

    return MatiereDeDemo._(
      session: TrekSession(
        id: idSessionFabriquee,
        trailId: trailId,
        startedAt: journees.first.depart,
        finishedAt: journees.last.arrivee,
        status: kTrekStatusTermine,
        // TOUTES les etapes du sentier, donc un finisher legitime au regard de
        // `TrekPlan.isFullyWalked` : le recapitulatif et le diplome s'ouvrent
        // sur la MEME regle que pour un vrai randonneur, appliquee a une
        // matiere fabriquee. Aucune exemption, aucun drapeau de faveur.
        completedStages: [for (final j in journees) j.etape.id],
        parcoursFullyWalked: true,
      ),
      journees: journees,
    );
  }

  /// Ramene un horodatage a sa journee civile (minuit local).
  static DateTime _jourDe(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

/// Le statut d'une session TERMINEE, tel que la base le stocke.
///
/// Repete ici, et c'est assume : `lib/domain/` ne connait pas
/// `lib/features/after/`, qui porte la constante lue par les providers
/// (`kTrekStatusCompleted`). Un import dans ce sens ferait du metier le client
/// d'une feature. Une garde de ce lot verifie que les deux valeurs restent
/// EGALES, pour que cette repetition ne puisse pas deriver en silence.
const String kTrekStatusTermine = 'completed';
