/// LA FIN D'UNE ETAPE SE DIT (tache 808).
///
/// RETOUR DE CHRISTOPHE DU 10/10, EN MODE DEMO, mot pour mot : « un petit
/// message quand tu finis une etape ca serait bien ».
///
/// CE QUI SE PASSAIT AVANT, ET QUI ETAIT LE DEFAUT : rien. Le marcheur
/// franchissait la borne, le nom changeait dans le bandeau du bas, et c'etait
/// tout. La seule chose qui marquait l'evenement etait la DISPARITION du nom
/// qu'on venait de meriter — le contraire d'une celebration.
///
/// ---------------------------------------------------------------------------
/// POURQUOI UNE BRIQUE DE PLUS, ALORS QUE DEUX « FELICITATIONS » EXISTENT DEJA
/// ---------------------------------------------------------------------------
///
/// Les deux ont ete lues avant d'ecrire une ligne, et aucune ne repond a cette
/// demande :
///
///   * [FelicitationsDeLaDemo] (`felicitations_de_la_demo.dart`) est la fin de
///     la DEMONSTRATION : un voile noir sur toute la carte, une carte de
///     chiffres, et un bouton « Fermer » qu'il faut appuyer. Elle BLOQUE, elle
///     attend un geste, elle ne sert qu'en demo et elle n'arrive qu'UNE fois,
///     au bout du sentier. Christophe demande l'inverse sur les six points :
///     court, non bloquant, qui part seul, en demo comme en vrai, a chacune
///     des six bornes.
///   * `TrekCongratulations` / `TrekCompletionKind` (`lib/domain/
///     trek_completion.dart`) ne sont pas une brique d'affichage du tout : un
///     objet de domaine SANS interface, qui repond a « le PARCOURS est-il fini
///     en entier ou en partie », pas a « une etape vient d'etre franchie ».
///     Son `TrekPlan.resolveArrival` n'a d'ailleurs AUCUN appelant dans
///     `lib/`. Lui ajouter un troisieme `kind` « etape » melangerait deux
///     questions dans un objet dont tout le fichier dit qu'il traite la FIN DE
///     TREK.
///
/// CE QUI EST REUTILISE, EN REVANCHE, C'EST LA FORME : `_SupplyAlertBanner`
/// (`map_overlays.dart`) est deja une banniere de carte qui se souvient de
/// l'etape pour laquelle elle s'est armee et qui s'efface seule au bout d'une
/// minuterie. Ce fichier reprend sa mecanique telle quelle — memoire d'etape,
/// minuterie unique annulee au `dispose` — et n'en invente pas une seconde.
///
/// ---------------------------------------------------------------------------
/// LE FRANCHISSEMENT SE LIT A L'ABSCISSE, PAS A LA GEOGRAPHIE
/// ---------------------------------------------------------------------------
///
/// Le depot porte DEUX detecteurs d'etape : l'abscisse sur la trace
/// ([jalonALAbscisse], tache 747) et le rayon geographique
/// (`arrivalEventsProvider`). Ce message lit L'ABSCISSE, et ce n'est pas un
/// detail : c'est elle qui change le nom dans le bandeau. Un message branche
/// sur l'autre detecteur se declencherait a un autre instant que le changement
/// de nom, et on aurait de nouveau deux verites pour un seul franchissement —
/// exactement ce que la tache 747 avait eu a defaire.
///
/// L'ABSCISSE EST MONOTONE PAR CONSTRUCTION, donc le numero ne peut que
/// croitre, et un message ne peut pas se declencher a reculons.
///
/// ---------------------------------------------------------------------------
/// LA DUREE, MESUREE ET NON CHOISIE AU HASARD
/// ---------------------------------------------------------------------------
///
/// En demonstration le temps est accelere soixante fois : a 4,0 km/h simules,
/// l'ecran avance de 66,7 m par seconde reelle. Les sept tranches du sentier
/// de demonstration mesurees sur la vraie trace (87,28 km, 3 590 points)
/// durent donc, a l'ecran : 4 min 59, 3 min 43, 3 min 25, 2 min 24, 2 min 01,
/// 2 min 28 et 2 min 46 — soit 21 min 49 pour le sentier entier, et
/// **2 min 01 pour la plus courte**.
///
/// [duree] vaut donc QUATRE SECONDES : 3,3 % de l'etape la plus courte, et
/// 24 secondes cumulees sur les 1 309 de la demonstration complete, soit
/// 1,8 % du temps d'ecran. Le message ne peut pas devenir le bandeau permanent
/// que Christophe redoute, meme a x60.
///
/// IL N'Y A PAS DE MINUTERIE DE `SnackBar` ICI, ET C'EST DELIBERE. Le depot a
/// deja paye cette lecon (`cadre_demo.dart`) : sur l'emulateur, un `SnackBar`
/// pose pendant une transition est reste affiche DEUX MINUTES, parce que
/// `ScaffoldMessenger` n'arme son minuteur qu'a la fin de son animation
/// d'entree. Une banniere qui porte SA PROPRE minuterie ne connait pas ce
/// piege.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/branding/stepways_icons.dart';
import '../../../../core/engine/trail_engine.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../i18n/translations.g.dart';
import '../../../map/map_facade.dart'
    show jalonALAbscisse, jalonsDesEtapesProvider, trackPositionProvider;
import '../../../trail/trail_facade.dart' show stagesProvider;

/// Le petit mot de fin d'etape, pose en haut de la carte.
///
/// INVISIBLE tant qu'aucune borne n'est franchie, et de nouveau invisible
/// [duree] plus tard, sans qu'on ait rien a toucher.
class FelicitationsDEtape extends ConsumerStatefulWidget {
  /// Cree la banniere de fin d'etape.
  const FelicitationsDEtape({super.key});

  /// COMBIEN DE TEMPS LE MESSAGE RESTE. Voir l'en-tete du fichier : quatre
  /// secondes, soit 3,3 % de l'etape la plus courte du sentier de
  /// demonstration a vitesse acceleree.
  static const Duration duree = Duration(seconds: 4);

  @override
  ConsumerState<FelicitationsDEtape> createState() =>
      _FelicitationsDEtapeState();
}

class _FelicitationsDEtapeState extends ConsumerState<FelicitationsDEtape> {
  /// LE NUMERO D'ETAPE DEJA VU, memoire du front montant.
  ///
  /// `null` tant qu'aucune etape n'a ete observee : le PREMIER numero vu ne
  /// declenche donc rien. C'est ce qui empeche un message a l'ouverture de
  /// l'ecran, ou au retour sur la carte au milieu d'une marche — on n'a rien
  /// franchi, on arrive.
  int? _dernierNumero;

  /// Le nom de l'etape ACHEVEE, tant que le message est affiche.
  String? _etapeAchevee;

  Timer? _minuteur;

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  /// Montre le message pour [nom] et arme son effacement.
  ///
  /// UNE SEULE MINUTERIE A LA FOIS : un second franchissement pendant qu'un
  /// message est affiche REMPLACE le premier et repart de zero, il ne
  /// s'empile pas derriere. En demonstration acceleree, deux bornes peuvent
  /// tomber coup sur coup.
  void _celebrer(String nom) {
    _minuteur?.cancel();
    setState(() => _etapeAchevee = nom);
    _minuteur = Timer(FelicitationsDEtape.duree, () {
      if (mounted) setState(() => _etapeAchevee = null);
    });
  }

  /// Le nom de l'etape [numero], ou son repli parlant si la base n'a pas
  /// encore rendu les etapes.
  String _nomDeLEtape(int numero, String trailId) {
    final etapes = ref.read(stagesProvider(trailId)).value;
    final modele = (etapes ?? const [])
        .where((s) => s.stageNumber == numero)
        .firstOrNull;
    return modele?.name ?? t.a11y.stageMarker(number: numero);
  }

  @override
  Widget build(BuildContext context) {
    final trailId = ref.watch(trailConfigProvider.select((c) => c.id));
    final jalons = ref.watch(jalonsDesEtapesProvider(trailId));
    final abscisseM = ref
        .watch(trackPositionProvider)
        .value
        ?.distanceFromStartM;
    final numero = abscisseM == null
        ? null
        : jalonALAbscisse(jalons, abscisseM)?.numero;

    if (numero != null && numero != _dernierNumero) {
      final precedent = _dernierNumero;
      _dernierNumero = numero;
      // LE MESSAGE NOMME L'ETAPE QU'ON VIENT DE FINIR, pas celle qui commence
      // — c'est precisement l'information que le bandeau efface a l'instant
      // ou elle est meritee.
      if (precedent != null && numero > precedent) {
        final nom = _nomDeLEtape(precedent, trailId);
        // Hors phase de build : on ne pose pas d'etat pendant qu'on dessine.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _celebrer(nom);
        });
      }
    }

    final nom = _etapeAchevee;
    if (nom == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingBase,
          vertical: AppTheme.spacingSm,
        ),
        child: Material(
          key: const ValueKey('felicitations-etape'),
          elevation: 2,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.phaseHike.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.phaseHike.withAlpha(80)),
            ),
            child: Row(
              children: [
                const StepIcon(
                  StepwaysIcons.cocheCercle,
                  size: 28,
                  color: AppTheme.phaseHike,
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        t.map.etapeFinie,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(nom, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
