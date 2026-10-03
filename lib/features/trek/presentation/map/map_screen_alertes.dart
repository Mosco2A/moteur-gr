/// L alerte de ravitaillement posee en haut de la carte.
///
/// Morceau de `map_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'map_screen.dart';

/// Bandeau « ravitaillement » de la carte (correctif L6-1).
///
/// CE QUI EXISTAIT DEJA, ET QUI N'EST PAS RECONSTRUIT ICI : le calcul de
/// l'ecart au prochain commerce ([TrailShops.gapAfter] / [TrailShops.isGapAlert]),
/// le catalogue du sentier ([trailShopsProvider]), les libelles traduits dans
/// les CINQ langues ([Translations] `shop.gapShort` / `shop.gapLong`) et la
/// detection de l'etape courante ([trackPositionProvider]). Ce qui manquait
/// etait le MONTAGE de l'alerte sur la carte : sa minuterie et son etat de
/// fermeture. C'est tout ce que porte ce widget.
///
/// COMPORTEMENT, aligne sur la reference terrain :
///  - rien hors trek : l'alerte parle au marcheur, pas au lecteur de carte ;
///  - rien tant que l'ecart ne depasse pas le seuil du sentier (cf.
///    [supplyGapAlertProvider]) ;
///  - la banniere s'efface SEULE au bout d'une minute, une seule minuterie
///    posee par apparition ;
///  - elle s'efface aussi a la demande (croix), et cette fermeture tient ;
///  - elle se REARME au changement d'etape : une nouvelle etape est une
///    nouvelle decision de ravitaillement, meme si la precedente avait ete
///    fermee a la main.
///
/// UN POINT OU STEPWAYS FAIT MIEUX QUE LA REFERENCE : chez GR20 le texte de ce
/// bandeau est ECRIT EN DUR dans l'ecran alors qu'une cle de traduction
/// existe. GR20 est bilingue et s'en accommode ; StepWays sert CINQ langues,
/// le texte en dur y est interdit. Le libelle vient donc de Slang, et le
/// nombre d'etapes y est injecte en parametre.
class _SupplyAlertBanner extends ConsumerStatefulWidget {
  const _SupplyAlertBanner();

  @override
  ConsumerState<_SupplyAlertBanner> createState() => _SupplyAlertBannerState();
}

class _SupplyAlertBannerState extends ConsumerState<_SupplyAlertBanner> {
  /// Duree d'affichage avant effacement automatique (parite reference).
  static const Duration _autoHideDelay = Duration(seconds: 60);

  Timer? _timer;

  /// Etape pour laquelle la minuterie courante a ete posee. Sert de memoire
  /// de rearmement : tant qu'elle ne change pas, on ne repose pas de
  /// minuterie et on ne rouvre pas une banniere fermee a la main.
  int? _armedForStage;

  /// Vrai quand la banniere est effacee (minuterie echue ou fermeture
  /// utilisateur) pour l'etape [_armedForStage].
  bool _hidden = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Remet l'alerte a zero pour [stageNumber] : une minuterie, une seule.
  void _armFor(int stageNumber) {
    _timer?.cancel();
    _armedForStage = stageNumber;
    _hidden = false;
    _timer = Timer(_autoHideDelay, () {
      if (mounted) setState(() => _hidden = true);
    });
  }

  void _disarm() {
    _timer?.cancel();
    _timer = null;
    _armedForStage = null;
    _hidden = false;
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(
      trekSessionManagerProvider.select((s) => s.status),
    );
    final trekActive =
        status == TrackingSessionStatus.recording ||
        status == TrackingSessionStatus.paused;
    final alert = ref.watch(supplyGapAlertProvider);

    if (!trekActive || alert == null) {
      // Plus rien a signaler : on desarme, sinon une minuterie continuerait
      // de courir pour une alerte disparue et la prochaine apparition sur la
      // meme etape naitrait deja effacee.
      _disarm();
      return const SizedBox.shrink();
    }

    if (_armedForStage != alert.stageNumber) {
      // Changement d'etape (ou premiere apparition) : minuterie et fermeture
      // repartent de zero. Pas de setState — on est deja dans le build de ce
      // bandeau, le rendu de ce tour tient compte de la remise a zero.
      _armFor(alert.stageNumber);
    }
    if (_hidden) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          AppTheme.spacingSm,
          AppTheme.spacingBase,
          0,
        ),
        child: Material(
          elevation: 2,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          color: theme.colorScheme.surface,
          child: Container(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingMd,
              AppTheme.spacingMd,
              AppTheme.spacingSm,
              AppTheme.spacingMd,
            ),
            decoration: BoxDecoration(
              color: AppTheme.orangeDifficile.withAlpha(20),
              border: Border.all(color: AppTheme.orangeDifficile.withAlpha(80)),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepIcon(
                  StepwaysIcons.danger,
                  color: AppTheme.orangeDifficile,
                  size: 20,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.shop.limitedTitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Libelle TRADUIT (jamais en dur) : le nombre d'etapes
                      // sans commerce est injecte en parametre.
                      Text(
                        t.shop.gapLong(n: alert.gap),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.orangeDifficile,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const StepIcon(StepwaysIcons.croix, size: 18),
                  color: AppTheme.orangeDifficile,
                  tooltip: t.map.supplyDismiss,
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _hidden = true),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
