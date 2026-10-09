/// LES DERNIERS CHIFFRES MESURES DE LA MARCHE — ILS SURVIVENT A SON DERNIER
/// PAS (tache 762).
///
/// ---------------------------------------------------------------------------
/// LE DEFAUT QUE CE FICHIER CORRIGE, ET SA CAUSE EXACTE
/// ---------------------------------------------------------------------------
///
/// Releve de la recette 753 (09/10 15:02), mot pour mot : « apres usage de la
/// fleche d'etape, les felicitations perdent trois de leurs quatre chiffres ».
/// Parcouru restait, D+, D- et Vitesse moyenne disparaissaient. Et, le meme
/// retour : « a la fermeture le bandeau RETOMBE SUR L'ETAPE 1 avec 11,8 km
/// restants et 0 pour cent ».
///
/// DEUX SYMPTOMES, UNE SEULE CAUSE, ET ELLE SE LIT DANS LE CODE. Le bouton de
/// saut d'etape note marchees TOUTES les etapes derriere lui
/// (`simulerLEtapeSuivante`). La porte du finisher
/// (`arrivalCompletionListenerProvider`) exige precisement cela : quand la
/// derniere arrivee survient, `plan.isFullyWalked(completedStages)` est donc
/// VRAI, `completeOnArrival` appelle `stop()`, et `_finalize` termine par
///
///     state = TrackingSessionState(status: stopped, ...)
///
/// — un etat SANS SESSION (le champ `session` y est nul, et son contrat le dit
/// : « null si idle/stopped »). A partir de cet instant :
///
///   * [liveTrekStatsProvider] sort immediatement sur `session == null` et rend
///     un [TrackSegmentStats] VIDE : `hasData` est faux, et les trois chiffres
///     mesures des felicitations disparaissent ;
///   * `ActiveStageBar` ne voit plus de trek actif et passe la main a la barre
///     du PROGRAMME, qui lit `currentStageNumberProvider` — la colonne
///     `currentStage` que PERSONNE n'ecrit (constat de la tache 747), donc
///     toujours 1. D'ou l'etape 1, les 11,8 km de la premiere etape, et 0 %.
///
/// EN MARCHE NATURELLE LE DEFAUT NE SE VOYAIT PAS, et c'est coherent : sans le
/// bouton de saut, les etapes intermediaires ne sont pas toutes notees, la
/// porte du finisher reste fermee, la session reste `recording` — et les
/// chiffres continuaient donc de s'afficher. Le bouton ne CREE pas le defaut,
/// il ouvre la porte qui le revele.
///
/// ---------------------------------------------------------------------------
/// CE QUE CE FICHIER MET A LA PLACE : UNE MEMOIRE, PAS UN SECOND CALCUL
/// ---------------------------------------------------------------------------
///
/// La fin d'une marche n'est pas le moment ou ses chiffres cessent d'avoir un
/// sens : c'est le moment ou ils comptent le plus. Ce notifier RETIENT la
/// derniere valeur MESURABLE de [liveTrekStatsProvider] et la garde apres la
/// fin de la session.
///
/// IL NE CALCULE RIEN. Pas de moteur de denivele, pas de relecture de la base,
/// pas de projection : il copie une valeur deja calculee par le seul moteur du
/// projet ([computeTrackStatsOnTrace], lot 671-06). Deux calculs donneraient
/// deux deniveles pour la meme journee ; une copie n'en donne qu'un.
///
/// POURQUOI RETENIR AU PASSAGE, ET NON FIGER DANS `_finalize`. Figer a la
/// finalisation aurait semble plus direct, et c'etait un piege mesurable :
/// [liveTrekStatsProvider] est asynchrone et se recalcule a chaque releve ; au
/// moment ou l'etat change, son recalcul est en vol. On aurait donc fige la
/// valeur d'AVANT le dernier pas — et en demonstration un pas vaut 670 m. En
/// retenant au passage, la valeur gardee est la derniere qui a reellement ete
/// mesuree, celle-la meme que la barre affichait.
///
/// POURQUOI LA SESSION EST RETENUE AVEC ELLE. Sans identifiant, cette memoire
/// serait un fantome : la randonnee SUIVANTE commencerait avec le denivele de
/// la precedente le temps de son premier releve. L'identifiant dit a quelle
/// marche ces chiffres appartiennent, et [_MarcheMesuree.pourLaSession] permet
/// de refuser ceux d'une autre.
///
/// ET ELLE NE SURVIT PAS A LA SORTIE DE DEMO : `arreterSimulationDemo` remet
/// l'etat du gestionnaire a `idle`, ce que ce notifier observe pour OUBLIER.
/// C'est la promesse de la demonstration — il ne reste rien — et elle vaut
/// aussi pour ce qui n'est qu'en memoire vive.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/geo/track_segment_stats.dart';
import 'live_trek_stats_provider.dart';
import 'tracking_providers.dart';

/// Les chiffres mesures d'UNE marche, avec l'identifiant de la marche mesuree.
class _MarcheMesuree {
  /// Associe des chiffres a la session qui les a produits.
  const _MarcheMesuree({required this.sessionId, required this.chiffres});

  /// La session qui a produit ces chiffres ; `null` quand la marche n'avait
  /// pas d'identifiant (cas d'une simulation sans session).
  final String? sessionId;

  /// Les chiffres eux-memes, tels que le moteur les a rendus.
  final TrackSegmentStats chiffres;

  /// Vrai quand ces chiffres sont bien ceux de [id].
  ///
  /// SERT A REFUSER CEUX D'UNE AUTRE MARCHE : un ecran qui lit cette memoire
  /// pendant une NOUVELLE randonnee, avant son premier releve, doit voir des
  /// tirets et non le denivele de la veille.
  bool pourLaSession(String? id) => sessionId == id;
}

/// Retient les derniers chiffres MESURES de la marche, et les oublie a `idle`.
class _DerniersChiffresMesuresNotifier extends Notifier<_MarcheMesuree?> {
  @override
  _MarcheMesuree? build() {
    // LA FIN DE LA MARCHE N'EFFACE RIEN, LE RETOUR A `idle` EFFACE TOUT. Entre
    // les deux il y a l'arrivee, et c'est exactement la fenetre ou ces chiffres
    // doivent rester lisibles.
    ref.listen(trekSessionManagerProvider.select((s) => s.status), (_, statut) {
      if (statut == TrackingSessionStatus.idle) state = null;
    });

    // ON NE RETIENT QUE CE QUI EST MESURABLE. Un [TrackSegmentStats] sous deux
    // releves ne porte aucun chiffre (`hasData` faux) : le retenir effacerait
    // la vraie mesure au profit du vide, ce qui est precisement le defaut a
    // corriger. Le vide de la finalisation passe donc sans rien ecraser.
    //
    // ET ON NE RETIENT RIEN PENDANT UN RECALCUL, CE QUI N'EST PAS UN DETAIL.
    // Un [FutureProvider] qui se recalcule emet un etat « en cours » qui PORTE
    // ENCORE LA VALEUR PRECEDENTE (`copyWithPrevious` de Riverpod) : lire
    // `.value` pendant ce temps rend les chiffres d'AVANT. Les retenir alors
    // les attribuerait a la session courante — et une randonnee qui demarre
    // afficherait le denivele de la precedente, le fantome meme que
    // l'identifiant de session est la pour empecher. On attend donc la donnee
    // reelle.
    ref.listen(liveTrekStatsProvider, (_, suivant) {
      final retenu = _aRetenir(suivant);
      if (retenu != null) state = retenu;
    });

    // ET LA VALEUR QUI EST DEJA LA, SANS ATTENDRE LA SUIVANTE. Un `listen` ne
    // rapporte que les CHANGEMENTS : si cette memoire naît apres que la mesure
    // a deja abouti — l'ecran de la carte ouvert en cours de randonnee, le cas
    // courant — elle resterait vide jusqu'au releve suivant, c'est-a-dire
    // jusqu'a trois minutes en profil batterie. On lit donc l'etat courant au
    // demarrage et on le RETOURNE : `ref.read` n'abonne a rien, et retourner
    // la valeur evite d'ecrire dans l'etat pendant sa propre construction, ce
    // que Riverpod interdit.
    return _aRetenir(ref.read(liveTrekStatsProvider));
  }

  /// Ce qu'il y a a retenir dans [mesure], ou `null` s'il n'y a rien.
  ///
  /// RIEN A RETENIR DANS TROIS CAS, et chacun compte :
  ///   * UN RECALCUL EN COURS. Un [FutureProvider] qui se recalcule emet un
  ///     etat « en cours » qui PORTE ENCORE LA VALEUR PRECEDENTE
  ///     (`copyWithPrevious` de Riverpod) : lire `.value` pendant ce temps rend
  ///     les chiffres d'AVANT. Les retenir les attribuerait a la session
  ///     courante — et une randonnee qui demarre afficherait le denivele de la
  ///     precedente, le fantome meme que l'identifiant de session est la pour
  ///     empecher.
  ///   * UNE ERREUR. On garde la derniere mesure valable plutot que de la
  ///     remplacer par rien.
  ///   * MOINS DE DEUX RELEVES (`hasData` faux). C'est le VIDE que la
  ///     finalisation de la session produit, et le retenir effacerait la vraie
  ///     mesure au profit de rien : c'est precisement le defaut a corriger.
  _MarcheMesuree? _aRetenir(AsyncValue<TrackSegmentStats> mesure) {
    if (mesure.isLoading || mesure.hasError) return null;
    final chiffres = mesure.value;
    if (chiffres == null || !chiffres.hasData) return null;
    return _MarcheMesuree(
      sessionId: ref.read(trekSessionManagerProvider).session?.id,
      chiffres: chiffres,
    );
  }
}

/// LES DERNIERS CHIFFRES MESURES DE LA MARCHE, lisibles apres son dernier pas.
final _derniersChiffresMesuresProvider =
    NotifierProvider<_DerniersChiffresMesuresNotifier, _MarcheMesuree?>(
      _DerniersChiffresMesuresNotifier.new,
    );

/// LES CHIFFRES A AFFICHER MAINTENANT : ceux de la marche en cours, ou ceux
/// qu'elle a laisses en finissant.
///
/// UN SEUL POINT DE LECTURE POUR LA BARRE ET POUR LES FELICITATIONS, et c'est
/// le but : les deux montraient les memes chiffres, et ils ont cesse de les
/// montrer ENSEMBLE a la meme seconde. Un seul point de lecture ne peut pas
/// desynchroniser deux ecrans.
///
/// IL NE LIT PAS LA MESURE EN VOL DIRECTEMENT, ET C'EST VOLONTAIRE. La lire
/// aurait semble plus court, et c'etait un deuxieme chemin sans garde : pendant
/// un recalcul, `liveTrekStatsProvider.value` porte encore les chiffres
/// PRECEDENTS, sans rien qui dise a quelle marche ils appartiennent. Tout passe
/// donc par la memoire, qui elle porte l'identifiant — UN seul chemin, UNE
/// seule verification. La memoire est nourrie par cette meme mesure a chaque
/// emission : elle n'est jamais en retard sur elle.
///
/// `null` quand il n'y a rien de mesurable : avant le premier releve, et pour
/// une marche dont ces chiffres ne sont pas ceux (voir
/// [_MarcheMesuree.pourLaSession]).
final chiffresDeLaMarcheProvider = Provider<TrackSegmentStats?>((ref) {
  final retenus = ref.watch(_derniersChiffresMesuresProvider);
  if (retenus == null) return null;

  // LA MARCHE ACHEVEE N'A PLUS DE SESSION, et c'est ce qui rend cette lecture
  // sure : quand le gestionnaire est a `stopped`, son champ `session` est nul
  // par contrat, donc les chiffres retenus — qui portent l'identifiant de la
  // marche finie — ne peuvent correspondre qu'a ELLE. Pendant une NOUVELLE
  // marche, la comparaison echoue et on rend `null` plutot que le denivele de
  // la precedente.
  final statut = ref.watch(trekSessionManagerProvider.select((s) => s.status));
  if (statut == TrackingSessionStatus.stopped) return retenus.chiffres;

  final sessionId = ref.watch(
    trekSessionManagerProvider.select((s) => s.session?.id),
  );
  return retenus.pourLaSession(sessionId) ? retenus.chiffres : null;
});
