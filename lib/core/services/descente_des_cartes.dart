import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../config/trail_data_source.dart';
import '../data/daos/trail_manifests_dao.dart';
import '../data/database.dart';
import '../map/mbtiles_manager.dart';
import '../models/niveau_de_telechargement.dart';
import '../network/connectivity_monitor.dart';
import '../providers/database_provider.dart';
import 'monetization_service.dart';

final _log = Logger(printer: PrettyPrinter(methodCount: 0));

/// POURQUOI LES CARTES NE DESCENDENT PAS. Jamais un bouton grise sans mot.
///
/// Chaque cause est une PHRASE que l ecran doit pouvoir dire, et c est la regle du
/// depot depuis [RefusDeSuppression] (tache 606) : « un bouton indisponible doit
/// dire pourquoi ». Un refus muet est un geste mort.
enum RefusDeDescente {
  /// Le niveau demande ne porte pas les cartes : REGARDER ou PREPARER.
  ///
  /// CE N EST PAS UNE ERREUR, C EST LA DEMANDE DE CHRISTOPHE DU 27/09 : « Attention
  /// de ne pas telecharger les donnees inutile quand on prepare avec pub et quand on
  /// prepare en ayant achete le sentier ». Zero octet, et zero connexion ouverte.
  niveauInsuffisant,

  /// Le sentier n a aucune ligne dans la liste locale : rien n est connu de lui.
  sentierInconnu,

  /// La liste distante ne publie pas de carte pour ce sentier.
  ///
  /// Cas NORMAL d un sentier neuf dont les tuiles ne sont pas encore fabriquees. Le
  /// dire vaut mieux que de laisser croire que « realiser » rend le sentier
  /// marchable hors ligne : il rend sa TRACE disponible, pas son fond de carte.
  aucuneCartePubliee,

  /// Le droit de REALISER n est pas acquis.
  ///
  /// Modele economique §2 : la realisation est reservee au trek achete — et §2 bis :
  /// un sentier gratuit est un sentier dont le PRIX EST NUL, donc realisable sans
  /// rien acheter. Les deux cas sortent de la MEME source,
  /// `MonetizationService.canRealizeTrail`, et il n y a pas d exception a ajouter
  /// ici : un prix nul est une entree du modele, pas une exemption.
  droitDeRealiserManquant,

  /// La carte complete est deja sur le telephone. Rien a faire.
  dejaLa,

  /// Hors ligne : une carte ne se telecharge pas sans reseau.
  horsLigne,

  /// LE LIEN N EST PAS DU WIFI ET LE RANDONNEUR N A PAS CONFIRME.
  ///
  /// Consigne de Christophe : « Une descente de cartes peut faire des dizaines de
  /// megaoctets sur un partage de connexion : demande confirmation hors wifi ». Ce
  /// refus est donc une QUESTION, pas une porte fermee : l ecran affiche le poids,
  /// le randonneur decide, et le meme appel repart avec `confirmeHorsWifi: true`.
  confirmationHorsWifiRequise,
}

/// CE QU ON SAIT AVANT DE DESCENDRE : le poids, le lien, et le refus s il y en a.
///
/// Rendu par [DescenteDesCartes.examiner] pour que l ecran puisse annoncer « 260 Mo
/// sur votre forfait mobile, continuer ? » SANS avoir ouvert la moindre connexion.
class DecisionDeDescente {
  const DecisionDeDescente({
    required this.trailId,
    required this.octetsTotal,
    required this.octetsDejaLa,
    required this.lien,
    this.refus,
  });

  final String trailId;

  /// Poids total de la carte publiee, en octets. Zero si aucune carte publiee.
  final int octetsTotal;

  /// Octets deja descendus et reprenables (descente interrompue precedemment).
  final int octetsDejaLa;

  /// Par quel lien le telephone est connecte au moment de la question.
  final TypeDeLien lien;

  /// Pourquoi la descente ne partira pas, ou `null` si elle peut partir.
  final RefusDeDescente? refus;

  bool get autorisee => refus == null;

  /// CE QUI VA REELLEMENT VOYAGER, en octets. C est ce chiffre qu on annonce, pas
  /// le poids total : sur une reprise a 70 %, annoncer 260 Mo serait faux.
  int get octetsAPrendre {
    final reste = octetsTotal - octetsDejaLa;
    return reste > 0 ? reste : 0;
  }

  /// Le meme chiffre en megaoctets, tel qu on l affiche.
  double get megaoctetsAPrendre =>
      ProgressionDeCarte.enMegaoctets(octetsAPrendre);
}

/// CE QU UNE DEMANDE DE DESCENTE A DONNE : un refus, ou un transport et son sort.
class BilanDeDescente {
  const BilanDeDescente({
    required this.decision,
    this.carte,
  });

  /// Ce qui a ete decide avant de transporter (poids, lien, refus eventuel).
  final DecisionDeDescente decision;

  /// Le transport, ou `null` s il n a pas eu lieu (refus).
  final ResultatDeCarte? carte;

  bool get posee => carte?.reussie ?? false;
  bool get refusee => decision.refus != null;
  RefusDeDescente? get refus => decision.refus;
  EchecDeCarte? get echec => carte?.echec;
}

/// LA DESCENTE DES CARTES HORS LIGNE — SEUL CHEMIN, ET IL N EN EXISTAIT AUCUN.
///
/// LE CONSTAT DE LA TACHE 622, VERIFIE AVANT D ECRIRE UNE LIGNE.
/// `MBTilesManager.downloadMbtiles` existait et n avait AUCUN APPELANT de
/// production. Consequence : un randonneur qui preparait son sentier puis montait
/// SANS RESEAU n avait pas ses cartes — c est-a-dire le coeur du produit.
///
/// CE QUI RESSEMBLAIT A UN CHEMIN ET N EN ETAIT PAS. Le depot contient un second
/// telechargeur, `PackDownloadService`, dont le manifeste nomme explicitement des
/// « cartes mbtiles », avec un ecran route (`PackStoreScreen`) et un bouton. Il ne
/// descend rien, et ne le pourrait pas : sa source de fichiers est
/// `UnavailablePackFileSource`, qui LEVE a chaque appel (« source de pack non
/// connectee, pre-Phase 4 »), et son stockage ecrit sous `documents/packs/<packId>/`
/// alors que la carte lit `documents/mbtiles/<trailId>.mbtiles`. Meme branche a un
/// serveur, il remplirait un dossier que rien ne regarde. Ce n est donc PAS le
/// chemin existant qu il aurait fallu reutiliser — c est une facade, et elle est
/// signalee comme telle dans le bilan du lot.
///
/// POURQUOI LA DESCENTE N EST PAS DANS `DeltaUpdateService.synchroniser`, ALORS QUE
/// C EST LE CHEMIN UNIQUE DES DONNEES. Parce que la cadence l emprunte. Depuis la
/// tache 616 `OrdonnanceurDeSynchronisation` resynchronise chaque sentier telecharge
/// AU NIVEAU OU IL EST DEJA — donc au niveau « realiser » pour un sentier qu on
/// s apprete a marcher, toutes les quatre heures et a chaque retour de reseau. Mettre
/// les tuiles dans `synchroniser` ferait exactement ce que l ordonnanceur se
/// documente d interdire : « 260 Mo de tuiles arrivant tout seuls, toutes les quatre
/// heures ». Les cartes descendent donc sur un GESTE, jamais sur une horloge.
///
/// CE QUI RESTE UNIQUE, ET C EST L ESSENTIEL : la DECISION. Le niveau est le seul
/// juge de ce qui descend ([NiveauDeTelechargement.porteLesCartes]), le droit de
/// realiser a une seule source (`MonetizationService.canRealizeTrail`), l adresse a
/// une seule source (`TrailDataSource`), et le transport a un seul appelant — celui-
/// ci. C est la lecon de la tache 606, ou un geste « telecharger » avait pris un
/// second chemin qui ignorait tout le modele.
class DescenteDesCartes {
  DescenteDesCartes({
    required this.cartes,
    required this.dao,
    required this.monetization,
    required this.connectivityMonitor,
  });

  final MBTilesManager cartes;
  final TrailManifestsDao dao;
  final MonetizationService monetization;
  final ConnectivityMonitor connectivityMonitor;

  /// EXAMINE SANS RIEN TRANSPORTER : est-ce permis, et qu est-ce que ca coute ?
  ///
  /// AUCUNE CONNEXION VERS LE FICHIER DE TUILES N EST OUVERTE ICI, et c est
  /// verifiable : le seul appel reseau est la lecture du TYPE de lien, qui est une
  /// question au systeme, pas un transfert. Un ecran peut donc afficher « 260 Mo »
  /// et un bouton sans avoir consomme un octet du forfait.
  ///
  /// L ORDRE DES QUESTIONS N EST PAS INDIFFERENT. Le niveau d abord (il repond sans
  /// rien lire), puis ce que le serveur publie, puis le DROIT, et le reseau EN
  /// DERNIER. Demander a un randonneur de confirmer 260 Mo sur son forfait avant de
  /// decouvrir qu il n a pas le droit de realiser le sentier serait une question
  /// posee pour rien.
  Future<DecisionDeDescente> examiner(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
  }) async {
    if (!niveau.porteLesCartes) {
      // ZERO OCTET, ET ZERO QUESTION AU SYSTEME. On ne lit meme pas le type de lien
      // : « regarder » et « preparer » ne descendent pas de carte, point.
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: 0,
        octetsDejaLa: 0,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.niveauInsuffisant,
      );
    }

    final ligne = await dao.getByTrailId(trailId);
    if (ligne == null) {
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: 0,
        octetsDejaLa: 0,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.sentierInconnu,
      );
    }

    if (!_tuilesPubliees(ligne)) {
      _log.d(
        '[Cartes] $trailId : aucune carte hors ligne publiee '
        '(chemin=${ligne.tilesPath}, taille=${ligne.tilesSize}, '
        'empreinte=${ligne.tilesHash == null ? "absente" : "presente"}).',
      );
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: 0,
        octetsDejaLa: 0,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.aucuneCartePubliee,
      );
    }

    final total = ligne.tilesSize!;

    if (!await monetization.canRealizeTrail(trailId)) {
      _log.d(
        '[Cartes] $trailId : descente refusee, le droit de realiser n est pas '
        'acquis. Le modele lie realiser a avoir paye (§2), sauf le sentier gratuit '
        'dont le prix est nul (§2 bis) — et les deux se lisent au meme endroit.',
      );
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: total,
        octetsDejaLa: 0,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.droitDeRealiserManquant,
      );
    }

    if (await cartes.hasMbtiles(trailId)) {
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: total,
        octetsDejaLa: total,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.dejaLa,
      );
    }

    final dejaLa = await cartes.octetsDejaDescendus(trailId);
    final lien = await connectivityMonitor.typeDeLien();

    if (lien == TypesDeLien.aucun) {
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: total,
        octetsDejaLa: dejaLa,
        lien: lien,
        refus: RefusDeDescente.horsLigne,
      );
    }

    if (!TypesDeLien.sansSupplement(lien) && !confirmeHorsWifi) {
      _log.d(
        '[Cartes] $trailId : ${ProgressionDeCarte.enMegaoctets(total - dejaLa)
            .toStringAsFixed(1)} Mo a prendre sur un lien « $lien » — '
        'confirmation demandee avant tout transfert.',
      );
      return DecisionDeDescente(
        trailId: trailId,
        octetsTotal: total,
        octetsDejaLa: dejaLa,
        lien: lien,
        refus: RefusDeDescente.confirmationHorsWifiRequise,
      );
    }

    return DecisionDeDescente(
      trailId: trailId,
      octetsTotal: total,
      octetsDejaLa: dejaLa,
      lien: lien,
    );
  }

  /// DESCEND LA CARTE DE [trailId], SI ET SEULEMENT SI [examiner] LE PERMET.
  ///
  /// LA DECISION EST REPRISE ICI, JAMAIS RECUE DE L APPELANT. Un ecran qui aurait
  /// examine puis appele est un ecran qui pourrait se tromper, ou etre remplace par
  /// un raccourci, un test, un geste futur. C est la difference que la tache 606 a
  /// nommee entre une regle et une decoration : « un bouton masque protege le
  /// randonneur qui regarde l ecran, une garde dans le service protege ses donnees
  /// quel que soit l appelant ».
  ///
  /// [confirmeHorsWifi] est la REPONSE du randonneur a la question posee par
  /// [RefusDeDescente.confirmationHorsWifiRequise] — pas un moyen de la sauter. Elle
  /// ne leve aucune autre garde : ni le niveau, ni le droit, ni le hors-ligne.
  Future<BilanDeDescente> descendre(
    String trailId, {
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
    void Function(ProgressionDeCarte)? progression,
    AnnulationDeDescente? annulation,
  }) async {
    final decision = await examiner(
      trailId,
      niveau: niveau,
      confirmeHorsWifi: confirmeHorsWifi,
    );
    if (!decision.autorisee) {
      return BilanDeDescente(decision: decision);
    }

    final ligne = await dao.getByTrailId(trailId);
    // La ligne existait a l examen ; si elle a disparu entre-temps, on ne devine
    // rien — on refuse comme a l examen.
    if (ligne == null || !_tuilesPubliees(ligne)) {
      return BilanDeDescente(
        decision: DecisionDeDescente(
          trailId: trailId,
          octetsTotal: decision.octetsTotal,
          octetsDejaLa: decision.octetsDejaLa,
          lien: decision.lien,
          refus: RefusDeDescente.aucuneCartePubliee,
        ),
      );
    }

    _log.d(
      '[Cartes] $trailId : descente de '
      '${decision.megaoctetsAPrendre.toStringAsFixed(1)} Mo '
      '(total ${ProgressionDeCarte.enMegaoctets(decision.octetsTotal)
          .toStringAsFixed(1)} Mo, '
      '${ProgressionDeCarte.enMegaoctets(decision.octetsDejaLa)
          .toStringAsFixed(1)} Mo deja la) sur lien « ${decision.lien} ».',
    );

    final resultat = await cartes.descendre(
      trailId: trailId,
      url: TrailDataSource.urlDonneesSentier(ligne.tilesPath!),
      octetsAttendus: ligne.tilesSize!,
      empreinteAttendue: ligne.tilesHash!,
      progression: progression,
      annulation: annulation,
    );

    return BilanDeDescente(decision: decision, carte: resultat);
  }

  /// Les trois champs de tuiles vont ensemble ou pas du tout (cf.
  /// `TrailManifestEntry.aDesTuilesPubliees`) : un descripteur incomplet est traite
  /// comme « aucune carte publiee », jamais descendu a moitie.
  static bool _tuilesPubliees(TrailManifest ligne) =>
      (ligne.tilesPath?.isNotEmpty ?? false) &&
      (ligne.tilesSize ?? 0) > 0 &&
      (ligne.tilesHash?.isNotEmpty ?? false);
}

/// Provider du service de descente des cartes hors ligne.
final descenteDesCartesProvider = Provider<DescenteDesCartes>((ref) {
  final db = ref.watch(databaseProvider);
  return DescenteDesCartes(
    cartes: ref.watch(mbtilesManagerProvider),
    dao: TrailManifestsDao(db),
    monetization: ref.watch(monetizationServiceProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
});

/// CE QUE L ECRAN MONTRE PENDANT UNE DESCENTE DE CARTE.
///
/// Les trois choses demandees par Christophe, et rien de plus : ce qui descend
/// ([progression]), pourquoi ca s est arrete ([bilan]), et si c est en cours — le
/// moyen d annuler est la methode du controleur.
class EtatDesCartes {
  const EtatDesCartes({this.progression, this.bilan, this.enCours = false});

  /// Ou en est le transport, ou `null` si rien n a encore ete recu.
  final ProgressionDeCarte? progression;

  /// Le dernier bilan connu (refus, echec ou carte posee). Null = jamais demande.
  final BilanDeDescente? bilan;

  /// Vrai tant que le transport n a pas rendu son bilan.
  final bool enCours;

  /// Avancement affichable dans [0..1].
  double get fraction => progression?.fraction ?? 0;
}

/// LE CONTROLEUR D UNE DESCENTE DE CARTE, PAR SENTIER — ET SON BOUTON ANNULER.
///
/// POURQUOI LE JETON D ANNULATION VIT ICI, ET PAS DANS UN PROVIDER A LUI. Un jeton
/// range dans un provider serait mis en cache avec son drapeau : une fois annule, il
/// annulerait INSTANTANEMENT toutes les descentes suivantes du meme sentier, et ce
/// defaut ne se verrait qu au deuxieme essai du randonneur. Le controleur en fabrique
/// donc un NEUF a chaque depart, et c est lui qui detient le seul moyen de le lever.
class ControleurDesCartes extends Notifier<EtatDesCartes> {
  ControleurDesCartes(this.trailId);

  /// Le sentier dont ce controleur descend la carte.
  final String trailId;

  AnnulationDeDescente? _jeton;

  @override
  EtatDesCartes build() => const EtatDesCartes();

  /// Vrai si une descente est en cours et peut etre annulee.
  bool get annulable => state.enCours && _jeton != null;

  /// DEMANDE LA DESCENTE. Rend le bilan, et le publie dans l etat.
  ///
  /// Un second appel pendant qu une descente tourne est IGNORE et rend le bilan
  /// courant : deux transports concurrents sur le meme fichier `.partiel`
  /// s ecriraient l un par-dessus l autre, et l empreinte finale serait fausse sans
  /// qu on sache pourquoi. C est le meme verrou que celui de l ordonnanceur (tache
  /// 620), pose AVANT le premier `await`.
  Future<BilanDeDescente> demarrer({
    required NiveauDeTelechargement niveau,
    bool confirmeHorsWifi = false,
  }) async {
    if (state.enCours) {
      _log.d('[Cartes] $trailId : descente deja en cours — appel ignore.');
      return state.bilan ??
          BilanDeDescente(
            decision: DecisionDeDescente(
              trailId: trailId,
              octetsTotal: 0,
              octetsDejaLa: 0,
              lien: TypesDeLien.aucun,
              refus: RefusDeDescente.dejaLa,
            ),
          );
    }

    final jeton = AnnulationDeDescente();
    _jeton = jeton;
    state = EtatDesCartes(bilan: state.bilan, enCours: true);

    try {
      final bilan = await ref.read(descenteDesCartesProvider).descendre(
            trailId,
            niveau: niveau,
            confirmeHorsWifi: confirmeHorsWifi,
            annulation: jeton,
            progression: (p) {
              if (!ref.mounted) return;
              state = EtatDesCartes(progression: p, enCours: true);
            },
          );
      if (ref.mounted) {
        state = EtatDesCartes(progression: state.progression, bilan: bilan);
      }
      return bilan;
    } finally {
      _jeton = null;
      // L ETAT NE RESTE JAMAIS « EN COURS » APRES UNE EXCEPTION. Un ecran bloque
      // sur une barre qui n avance plus est pire qu un message d erreur : le
      // randonneur attend un transport qui n existe plus.
      if (ref.mounted && state.enCours) {
        state = EtatDesCartes(progression: state.progression, bilan: state.bilan);
      }
    }
  }

  /// ANNULE LA DESCENTE EN COURS. Sans effet s il n y en a pas.
  ///
  /// Le fichier deja descendu est CONSERVE (cf. [EchecDeCarte.annulee]) : annuler ne
  /// punit pas, la reprise repartira d ou on s est arrete.
  void annuler() {
    _jeton?.annuler();
    _log.d('[Cartes] $trailId : annulation demandee par le randonneur.');
  }
}

/// Controleur de descente par sentier.
final controleurDesCartesProvider =
    NotifierProvider.family<ControleurDesCartes, EtatDesCartes, String>(
  ControleurDesCartes.new,
);
