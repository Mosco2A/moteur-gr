/// LES CARTES HORS LIGNE : UN SEUL GESTE, TOUT LE CIRCUIT (tache 640, bug 10).
///
/// RETOUR DE TEST DE CHRISTOPHE DU 30/09 10:17 (DEM-260930-1017), verbatim :
/// « Le telechargement doit telecharger les cartes pour le circuit propose. On ne
/// propose pas de demi-Mare a Mare, pas besoin de telecharger de demi-cartes ».
///
/// CE QU IL Y AVAIT A LA PLACE, ET POURQUOI CE N ETAIT PAS UN ECRAN DE CARTES.
/// La carte du HUB « Cartes hors ligne / Telecharger les cartes du sentier »
/// ouvrait le MAGASIN DE PACKS, qui proposait QUATRE packs a la carte — Nord,
/// Sud, Complet et le nom du sentier — c est-a-dire des demi-circuits. Le lot 634
/// avait deja montre que ces quatre noms etaient des noms de SENTIER ecrits en dur
/// dans les cinq fichiers de langue. Et le lot 622 avait deja etabli, dans son
/// bilan, que cet ecran ne telechargeait RIEN : sa source de fichiers levait a
/// chaque appel, et son stockage ecrivait sous `documents/packs/` alors que la
/// carte lit `documents/mbtiles/<trailId>.mbtiles`. Une facade, donc, branchee
/// sur la seule porte que Christophe pouvait pousser — d ou « telecharger les
/// cartes plante » (bug 9, DEM-260930-1016).
///
/// CE QUE CET ECRAN EST. La porte du SEUL telechargeur de cartes du depot,
/// [DescenteDesCartes] (lot 622), qui descend UN fichier pour TOUT le circuit :
/// celui que la carte ouvre vraiment. Il n y a donc plus rien a choisir — un
/// bouton, le poids annonce avant tout transfert, la progression, la reprise
/// apres coupure, l annulation, et la suppression pour liberer l espace.
///
/// LA REGLE PRODUIT QUI COMMANDE CETTE FORME : un sentier se vend et se prepare EN
/// ENTIER. Le fond de carte suit la meme regle, et pas seulement par symetrie —
/// un randonneur qui aurait telecharge « la moitie nord » decouvrirait le trou au
/// pire endroit, au milieu du circuit, sans reseau.
///
/// POURQUOI CE GESTE DEMANDE LE NIVEAU « REALISER ». Le niveau dit ce qui descend
/// ([NiveauDeTelechargement.porteLesCartes]), et les cartes ne descendent qu a
/// « realiser ». Cet ecran EST la demande explicite des cartes : il demande donc
/// ce niveau-la. Cela ne DONNE aucun droit — `MonetizationService.canRealizeTrail`
/// reste le seul juge, consulte par [DescenteDesCartes.examiner] avant qu un octet
/// ne voyage, et son refus s affiche ici comme une phrase.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/config/trail_catalog.dart';
import '../../../core/error/error_handler.dart';
import '../../../core/map/mbtiles_manager.dart';
import '../../../core/models/niveau_de_telechargement.dart';
import '../../../core/network/connectivity_monitor.dart';
import '../../../core/services/descente_des_cartes.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';

/// L ecran « Cartes hors ligne » d un circuit — un bouton, tout le circuit.
class CartesHorsLigneScreen extends ConsumerStatefulWidget {
  const CartesHorsLigneScreen({super.key, required this.trailId});

  /// Le circuit dont on telecharge les cartes (moteur generique, #84627).
  final String trailId;

  @override
  ConsumerState<CartesHorsLigneScreen> createState() =>
      _CartesHorsLigneScreenState();
}

class _CartesHorsLigneScreenState extends ConsumerState<CartesHorsLigneScreen> {
  /// CE QU ON SAIT AVANT DE TELECHARGER : poids, reprise, refus eventuel.
  ///
  /// Relu a l ouverture ET apres chaque geste, parce que chacun le change : un
  /// telechargement abouti fait passer a « deja la », une annulation laisse un
  /// partiel reprenable, une suppression ramene a zero.
  DecisionDeDescente? _examen;
  bool _examenEnCours = true;

  @override
  void initState() {
    super.initState();
    // Le premier examen part apres la construction : il lit la base et le type de
    // lien, et un `initState` n attend rien.
    WidgetsBinding.instance.addPostFrameCallback((_) => _examiner());
  }

  /// CET EXAMEN NE LEVE PAS NON PLUS, ET LE FILET EST ICI EXPRES.
  ///
  /// `DescenteDesCartes.examiner` rattrape desormais ses propres pannes (tache
  /// 640) — mais cet ecran ne doit pas DEPENDRE de cette promesse. Il est lance
  /// depuis un rappel de fin de trame et depuis la fin d un geste : deux endroits
  /// ou personne n attend le futur, donc deux endroits ou une exception devient
  /// une erreur asynchrone non traitee — un plantage. Le filet ci-dessous est
  /// celui du bug 9, pose au dernier etage.
  Future<void> _examiner() async {
    if (!mounted) return;
    setState(() => _examenEnCours = true);
    DecisionDeDescente examen;
    try {
      examen = await ref
          .read(descenteDesCartesProvider)
          .examiner(widget.trailId, niveau: NiveauDeTelechargement.realiser);
    } on Object catch (e, st) {
      ErrorHandler.log(
        e,
        stackTrace: st,
        context: 'CartesHorsLigneScreen.examiner(${widget.trailId})',
      );
      examen = DecisionDeDescente(
        trailId: widget.trailId,
        octetsTotal: 0,
        octetsDejaLa: 0,
        lien: TypesDeLien.aucun,
        refus: RefusDeDescente.stockageIndisponible,
      );
    }
    if (!mounted) return;
    setState(() {
      _examen = examen;
      _examenEnCours = false;
    });
  }

  /// LE GESTE. Il ne peut pas planter, et c est tout l objet du bug 9.
  ///
  /// `demarrer` rattrape desormais tout ce qui leve sous lui et rend un bilan ;
  /// le `try` ci-dessous est la ceinture par-dessus la bretelle, parce que ce
  /// bouton est justement l endroit ou une exception non rattrapee devenait une
  /// erreur asynchrone sans destinataire — donc un plantage.
  Future<void> _telecharger({bool confirmeHorsWifi = false}) async {
    final controleur = ref.read(
      controleurDesCartesProvider(widget.trailId).notifier,
    );
    BilanDeDescente? bilan;
    try {
      bilan = await controleur.demarrer(
        niveau: NiveauDeTelechargement.realiser,
        confirmeHorsWifi: confirmeHorsWifi,
      );
    } on Object {
      // Deja journalise et signale par le controleur : ici on ne fait que ne PAS
      // laisser une exception sortir d un geste d interface.
      bilan = null;
    }
    if (!mounted) return;

    // HORS WI-FI, LE REFUS EST UNE QUESTION, PAS UNE PORTE FERMEE (lot 622).
    if (bilan != null &&
        bilan.refus == RefusDeDescente.confirmationHorsWifiRequise) {
      final accepte = await _demanderHorsWifi(
        bilan.decision.megaoctetsAPrendre,
      );
      if (!mounted) return;
      if (accepte) {
        await _telecharger(confirmeHorsWifi: true);
        return;
      }
    }
    await _examiner();
  }

  Future<bool> _demanderHorsWifi(double megaoctets) async {
    final t = Translations.of(context);
    final reponse = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const ValueKey('cartes-hors-wifi'),
        title: Text(t.cartesHorsLigne.horsWifiTitre(mo: _mo(megaoctets))),
        content: Text(t.cartesHorsLigne.horsWifiCorps),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cartesHorsLigne.horsWifiAttendre),
          ),
          TextButton(
            key: const ValueKey('cartes-hors-wifi-continuer'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.cartesHorsLigne.horsWifiContinuer),
          ),
        ],
      ),
    );
    return reponse ?? false;
  }

  Future<void> _supprimer() async {
    final t = Translations.of(context);
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.cartesHorsLigne.supprimerTitre),
        content: Text(t.cartesHorsLigne.supprimerCorps),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.cartesHorsLigne.supprimerAnnuler),
          ),
          TextButton(
            key: const ValueKey('cartes-supprimer-confirmer'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.cartesHorsLigne.supprimerConfirmer),
          ),
        ],
      ),
    );
    if (confirme != true || !mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await ref
        .read(controleurDesCartesProvider(widget.trailId).notifier)
        .supprimer();
    if (!mounted) return;
    messenger?.showSnackBar(SnackBar(content: Text(t.cartesHorsLigne.libere)));
    await _examiner();
  }

  /// Le poids TEL QU ON LE DIT : un chiffre apres la virgule, jamais un octet.
  String _mo(double megaoctets) => megaoctets.toStringAsFixed(1);

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final etat = ref.watch(controleurDesCartesProvider(widget.trailId));
    final enDemo = ref.watch(enDemoProvider);
    final nomDuCircuit =
        TrailCatalog.byId(widget.trailId)?.displayName ?? widget.trailId;

    final examen = _examen;
    final bilan = etat.bilan;
    final dejaLa =
        examen?.refus == RefusDeDescente.dejaLa || (bilan?.posee ?? false);

    return Scaffold(
      appBar: AppBar(title: Text(t.cartesHorsLigne.title)),
      body: ListView(
        key: const ValueKey('cartes-hors-ligne'),
        padding: const EdgeInsets.all(AppTheme.spacingMd),
        children: [
          Text(nomDuCircuit, style: theme.textTheme.titleLarge),
          const SizedBox(height: AppTheme.spacingXs),
          Text(t.cartesHorsLigne.intro, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppTheme.spacingMd),
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_examenEnCours && examen == null)
                  const Center(
                    key: ValueKey('cartes-examen'),
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.spacingMd),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (etat.enCours)
                  ..._progression(t, theme, etat)
                else if (dejaLa)
                  ..._pretes(t, theme, examen, bilan, enDemo)
                else
                  ..._aTelecharger(t, theme, examen, bilan, enDemo),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // LA REGLE, ECRITE A L ECRAN : un seul geste, tout le circuit.
          Row(
            children: [
              const StepIcon(
                StepwaysIcons.info,
                size: 18,
                color: AppTheme.vertFacile,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.cartesHorsLigne.unSeulGeste,
                  key: const ValueKey('cartes-un-seul-geste'),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
          if (enDemo) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.cartesHorsLigne.demoIndisponible,
              key: const ValueKey('cartes-demo'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // --- LES TROIS ETATS DE L ECRAN -----------------------------------------

  List<Widget> _progression(
    Translations t,
    ThemeData theme,
    EtatDesCartes etat,
  ) {
    final p = etat.progression;
    final verification = p != null && p.fraction >= 1;
    final pourcent = ((p?.fraction ?? 0) * 100).round();
    return [
      Semantics(
        label: t.cartesHorsLigne.a11y.progression(pourcent: pourcent),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          child: LinearProgressIndicator(
            key: const ValueKey('cartes-progression'),
            value: p?.fraction,
            minHeight: 8,
            backgroundColor: AppTheme.grisGranite.withAlpha(60),
          ),
        ),
      ),
      const SizedBox(height: AppTheme.spacingXs),
      Text(
        verification
            ? t.cartesHorsLigne.verification
            : t.cartesHorsLigne.enCours(
                recus: _mo(
                  ProgressionDeCarte.enMegaoctets(p?.octetsRecus ?? 0),
                ),
                total: _mo(
                  ProgressionDeCarte.enMegaoctets(p?.octetsTotal ?? 0),
                ),
              ),
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppTheme.spacingSm),
      AppButton(
        key: const ValueKey('cartes-annuler'),
        variant: AppButtonVariant.outline,
        icon: StepwaysIcons.croix,
        label: t.cartesHorsLigne.annuler,
        onPressed: () => ref
            .read(controleurDesCartesProvider(widget.trailId).notifier)
            .annuler(),
      ),
    ];
  }

  List<Widget> _pretes(
    Translations t,
    ThemeData theme,
    DecisionDeDescente? examen,
    BilanDeDescente? bilan,
    bool enDemo,
  ) {
    final octets =
        examen?.octetsTotal ?? bilan?.carte?.octetsSurLeTelephone ?? 0;
    return [
      Row(
        children: [
          const StepIcon(
            StepwaysIcons.cocheCercle,
            size: 22,
            color: AppTheme.vertFacile,
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.cartesHorsLigne.pretes,
              key: const ValueKey('cartes-pretes'),
              style: theme.textTheme.titleMedium,
            ),
          ),
        ],
      ),
      const SizedBox(height: AppTheme.spacingXs),
      Text(
        t.cartesHorsLigne.pretesPoids(
          mo: _mo(ProgressionDeCarte.enMegaoctets(octets)),
        ),
        style: theme.textTheme.bodySmall,
      ),
      const SizedBox(height: AppTheme.spacingSm),
      AppButton(
        key: const ValueKey('cartes-supprimer'),
        variant: AppButtonVariant.outline,
        icon: StepwaysIcons.corbeille,
        label: t.cartesHorsLigne.supprimer,
        // EN DEMO, EFFACER DES FICHIERS DU TELEPHONE N A PAS SA PLACE : le bouton
        // est visiblement indisponible, jamais actif-et-inerte (regle du bug 14).
        onPressed: enDemo ? null : _supprimer,
      ),
    ];
  }

  List<Widget> _aTelecharger(
    Translations t,
    ThemeData theme,
    DecisionDeDescente? examen,
    BilanDeDescente? bilan,
    bool enDemo,
  ) {
    final cause = _cause(t, examen, bilan);
    final bloque = _bloqueDefinitivement(examen, bilan);
    final octetsTotal = examen?.octetsTotal ?? 0;
    final dejaLa = examen?.octetsDejaLa ?? 0;
    final aPrendre = examen?.octetsAPrendre ?? 0;

    return [
      if (octetsTotal > 0) ...[
        Text(
          t.cartesHorsLigne.poids(
            mo: _mo(ProgressionDeCarte.enMegaoctets(aPrendre)),
          ),
          key: const ValueKey('cartes-poids'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          t.cartesHorsLigne.poidsTotal(
            mo: _mo(ProgressionDeCarte.enMegaoctets(octetsTotal)),
          ),
          style: theme.textTheme.bodySmall,
        ),
      ],
      // LA REPRISE EST ANNONCEE, PARCE QUE C EST CE QUI CHANGE LA DECISION du
      // randonneur : « 180 Mo sur 260 deja la » ne se dit pas apres coup.
      if (dejaLa > 0) ...[
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          t.cartesHorsLigne.reprise(
            mo: _mo(ProgressionDeCarte.enMegaoctets(dejaLa)),
          ),
          key: const ValueKey('cartes-reprise'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.vertFacile,
          ),
        ),
      ],
      if (cause != null) ...[
        const SizedBox(height: AppTheme.spacingSm),
        Text(
          cause,
          key: const ValueKey('cartes-cause'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.rougeUrgence,
          ),
        ),
      ],
      if (!bloque) ...[
        const SizedBox(height: AppTheme.spacingSm),
        Semantics(
          button: true,
          label: t.cartesHorsLigne.a11y.bouton,
          child: AppButton(
            key: const ValueKey('cartes-telecharger'),
            icon: StepwaysIcons.telecharger,
            label: cause != null
                ? t.cartesHorsLigne.reessayer
                : (dejaLa > 0
                      ? t.cartesHorsLigne.reprendre
                      : t.cartesHorsLigne.telecharger),
            // EN DEMO, GRISE ET IL LE DIT (regle du bug 14) : la demo montre
            // l ecran, elle n ecrit pas 260 Mo sur le telephone de personne.
            onPressed: enDemo ? null : _telecharger,
          ),
        ),
      ],
    ];
  }

  /// LA CAUSE, EN UNE PHRASE. Un refus muet est un geste mort (lecon du lot 606).
  String? _cause(
    Translations t,
    DecisionDeDescente? examen,
    BilanDeDescente? bilan,
  ) {
    final echec = bilan?.echec;
    if (echec != null) {
      final e = t.cartesHorsLigne.echec;
      return switch (echec) {
        EchecDeCarte.reseau => e.reseau,
        EchecDeCarte.empreinteInvalide => e.empreinteInvalide,
        EchecDeCarte.tailleInattendue => e.tailleInattendue,
        EchecDeCarte.plusDePlace => e.plusDePlace,
        EchecDeCarte.ecritureImpossible => e.ecritureImpossible,
        EchecDeCarte.stockageIndisponible => e.stockageIndisponible,
        EchecDeCarte.annulee => e.annulee,
      };
    }
    // LE REFUS DU BILAN PASSE AVANT CELUI DE L EXAMEN : c est la reponse au
    // dernier geste du randonneur, pas l etat general de l ecran.
    final refus = bilan?.refus ?? examen?.refus;
    if (refus == null) return null;
    final r = t.cartesHorsLigne.refus;
    return switch (refus) {
      RefusDeDescente.niveauInsuffisant => r.niveauInsuffisant,
      RefusDeDescente.sentierInconnu => r.sentierInconnu,
      RefusDeDescente.aucuneCartePubliee => r.aucuneCartePubliee,
      RefusDeDescente.droitDeRealiserManquant => r.droitDeRealiserManquant,
      RefusDeDescente.horsLigne => r.horsLigne,
      RefusDeDescente.stockageIndisponible => r.stockageIndisponible,
      // « Deja la » est un etat, pas un refus a montrer ; « hors wifi » est une
      // question deja posee par une boite de dialogue.
      RefusDeDescente.dejaLa => null,
      RefusDeDescente.confirmationHorsWifiRequise => null,
    };
  }

  /// VRAI QUAND REESSAYER NE SERT A RIEN, et c est la seule raison de retirer le
  /// bouton : ni le droit d achat ni une carte non publiee ne changent en
  /// appuyant une seconde fois. Tout le reste est retentable.
  bool _bloqueDefinitivement(
    DecisionDeDescente? examen,
    BilanDeDescente? bilan,
  ) {
    final refus = bilan?.refus ?? examen?.refus;
    return refus == RefusDeDescente.aucuneCartePubliee ||
        refus == RefusDeDescente.droitDeRealiserManquant ||
        refus == RefusDeDescente.sentierInconnu;
  }
}
